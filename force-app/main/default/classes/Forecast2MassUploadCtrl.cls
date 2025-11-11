/**
 * Forecast 2.0 Mass Upload Controller
 * Handles bulk CSV uploads with proper bulkification and error handling
 */
public with sharing class Forecast2MassUploadCtrl {

    /**
     * Wrapper class for upload results
     */
    public class UploadResult {
        @AuraEnabled public Integer totalRows { get; set; }
        @AuraEnabled public Integer successRows { get; set; }
        @AuraEnabled public Integer errorRows { get; set; }
        @AuraEnabled public List<String> errors { get; set; }
        @AuraEnabled public String message { get; set; }
        @AuraEnabled public Boolean success { get; set; }

        public UploadResult() {
            this.totalRows = 0;
            this.successRows = 0;
            this.errorRows = 0;
            this.errors = new List<String>();
            this.success = false;
        }
    }

    /**
     * Wrapper for CSV row data
     */
    public class CSVRow {
        @AuraEnabled public String AccountId { get; set; }
        @AuraEnabled public String ProductId { get; set; }
        @AuraEnabled public String Month { get; set; }
        @AuraEnabled public String Quantity { get; set; }
        @AuraEnabled public String UnitPrice { get; set; }
        @AuraEnabled public String Direct { get; set; }
        @AuraEnabled public String Local { get; set; }
        @AuraEnabled public String Warehouse { get; set; }
        @AuraEnabled public Integer rowNumber { get; set; }
    }

    /**
     * Validate CSV headers
     */
    @AuraEnabled
    public static Map<String, Object> validateCSV(String csvContent) {
        Map<String, Object> result = new Map<String, Object>();

        try {
            if (String.isBlank(csvContent)) {
                result.put('valid', false);
                result.put('error', 'CSV content is empty');
                return result;
            }

            List<String> lines = csvContent.split('\n');
            if (lines.size() < 2) {
                result.put('valid', false);
                result.put('error', 'CSV must contain headers and at least one data row');
                return result;
            }

            String headerLine = lines[0].trim();
            List<String> headers = headerLine.split(',');
            Set<String> headerSet = new Set<String>();
            for (String header : headers) {
                headerSet.add(header.trim().toLowerCase());
            }

            // Required columns
            List<String> requiredColumns = new List<String>{
                'accountid', 'productid', 'month', 'quantity'
            };

            List<String> missingColumns = new List<String>();
            for (String required : requiredColumns) {
                if (!headerSet.contains(required.toLowerCase())) {
                    missingColumns.add(required);
                }
            }

            if (!missingColumns.isEmpty()) {
                result.put('valid', false);
                result.put('error', 'Missing required columns: ' + String.join(missingColumns, ', '));
                return result;
            }

            result.put('valid', true);
            result.put('rowCount', lines.size() - 1);
            result.put('headers', headers);

        } catch (Exception e) {
            result.put('valid', false);
            result.put('error', e.getMessage());
        }

        return result;
    }

    /**
     * Process mass upload CSV
     * Supports batching for large files
     */
    @AuraEnabled
    public static UploadResult processMassUpload(String csvContent) {
        UploadResult result = new UploadResult();

        try {
            if (String.isBlank(csvContent)) {
                result.message = 'CSV content is empty';
                return result;
            }

            // Parse CSV
            List<CSVRow> csvRows = parseCSV(csvContent);
            result.totalRows = csvRows.size();

            if (csvRows.isEmpty()) {
                result.message = 'No valid data rows found in CSV';
                return result;
            }

            // Group by Account for processing
            Map<Id, List<CSVRow>> rowsByAccount = new Map<Id, List<CSVRow>>();
            Set<Id> accountIds = new Set<Id>();
            Set<Id> productIds = new Set<Id>();
            Set<String> warehouseNames = new Set<String>();

            for (CSVRow row : csvRows) {
                try {
                    // Validate IDs
                    if (!isValidId(row.AccountId, '001')) {
                        result.errors.add('Row ' + row.rowNumber + ': Invalid Account ID - ' + row.AccountId);
                        result.errorRows++;
                        continue;
                    }
                    if (!isValidId(row.ProductId, '01t')) {
                        result.errors.add('Row ' + row.rowNumber + ': Invalid Product ID - ' + row.ProductId);
                        result.errorRows++;
                        continue;
                    }

                    accountIds.add(row.AccountId);
                    productIds.add(row.ProductId);

                    if (String.isNotBlank(row.Warehouse)) {
                        warehouseNames.add(row.Warehouse);
                    }

                    if (!rowsByAccount.containsKey(row.AccountId)) {
                        rowsByAccount.put(row.AccountId, new List<CSVRow>());
                    }
                    rowsByAccount.get(row.AccountId).add(row);

                } catch (Exception e) {
                    result.errors.add('Row ' + row.rowNumber + ': ' + e.getMessage());
                    result.errorRows++;
                }
            }

            // Validate accounts exist
            Map<Id, Account> accountMap = new Map<Id, Account>(
                [SELECT Id, Name FROM Account WHERE Id IN :accountIds]
            );

            // Validate products exist
            Map<Id, Product2> productMap = new Map<Id, Product2>(
                [SELECT Id, Name FROM Product2 WHERE Id IN :productIds]
            );

            // Get warehouse mapping
            Map<String, Id> warehouseMap = new Map<String, Id>();
            for (Warehouse__c wh : [SELECT Id, Name FROM Warehouse__c WHERE Name IN :warehouseNames]) {
                warehouseMap.put(wh.Name, wh.Id);
            }

            // Process each account
            for (Id accountId : rowsByAccount.keySet()) {
                if (!accountMap.containsKey(accountId)) {
                    for (CSVRow row : rowsByAccount.get(accountId)) {
                        result.errors.add('Row ' + row.rowNumber + ': Account not found - ' + accountId);
                        result.errorRows++;
                    }
                    continue;
                }

                try {
                    Integer processedRows = processAccountRows(
                        accountId,
                        rowsByAccount.get(accountId),
                        productMap,
                        warehouseMap,
                        result
                    );
                    result.successRows += processedRows;
                } catch (Exception e) {
                    for (CSVRow row : rowsByAccount.get(accountId)) {
                        result.errors.add('Row ' + row.rowNumber + ': ' + e.getMessage());
                        result.errorRows++;
                    }
                }
            }

            result.success = result.successRows > 0;
            if (result.success) {
                result.message = 'Successfully processed ' + result.successRows + ' of ' + result.totalRows + ' rows';
            } else {
                result.message = 'Failed to process any rows. Check errors for details.';
            }

        } catch (Exception e) {
            result.message = 'Unexpected error: ' + e.getMessage();
            result.errors.add(e.getMessage() + ' | ' + e.getStackTraceString());
        }

        return result;
    }

    /**
     * Process rows for a single account
     */
    private static Integer processAccountRows(
        Id accountId,
        List<CSVRow> rows,
        Map<Id, Product2> productMap,
        Map<String, Id> warehouseMap,
        UploadResult result
    ) {
        Integer processedCount = 0;

        // Group by product and fulfillment type
        Map<String, List<CSVRow>> rowsByProduct = new Map<String, List<CSVRow>>();
        Set<Id> productIds = new Set<Id>();

        for (CSVRow row : rows) {
            if (!productMap.containsKey(row.ProductId)) {
                result.errors.add('Row ' + row.rowNumber + ': Product not found - ' + row.ProductId);
                continue;
            }

            String isDirect = String.isNotBlank(row.Direct) ? row.Direct.toLowerCase() : 'false';
            String isLocal = String.isNotBlank(row.Local) ? row.Local.toLowerCase() : 'false';

            String key = row.ProductId + ';' + isLocal + ';' + isDirect;

            if (!rowsByProduct.containsKey(key)) {
                rowsByProduct.put(key, new List<CSVRow>());
            }
            rowsByProduct.get(key).add(row);
            productIds.add(row.ProductId);
        }

        // Get existing forecast products
        Map<String, Forecast_Product__c> existingForecastProducts = new Map<String, Forecast_Product__c>();
        for (Forecast_Product__c fp : [
            SELECT Id, Product__c, Account__c, Local_Enabled__c, Direct_Enabled__c,
                   External_Id__c, Price__c, Local_Warehouse__c
            FROM Forecast_Product__c
            WHERE Account__c = :accountId
            AND Product__c IN :productIds
        ]) {
            String key = fp.Product__c + ';' + fp.Local_Enabled__c + ';' + fp.Direct_Enabled__c;
            existingForecastProducts.put(key, fp);
        }

        // Prepare forecast products for upsert
        List<Forecast_Product__c> forecastProductsToUpsert = new List<Forecast_Product__c>();
        Map<String, Forecast_Product__c> forecastProductMap = new Map<String, Forecast_Product__c>();

        for (String key : rowsByProduct.keySet()) {
            List<String> keyParts = key.split(';');
            Id productId = keyParts[0];
            Boolean isLocal = Boolean.valueOf(keyParts[1]);
            Boolean isDirect = Boolean.valueOf(keyParts[2]);

            CSVRow firstRow = rowsByProduct.get(key)[0];

            Forecast_Product__c fp;
            if (existingForecastProducts.containsKey(key)) {
                fp = existingForecastProducts.get(key);
            } else {
                fp = new Forecast_Product__c();
                fp.Account__c = accountId;
                fp.Product__c = productId;
                fp.External_Id__c = accountId + '-' + productId + '-' + (isDirect ? '0' : '1');
            }

            fp.Local_Enabled__c = isLocal;
            fp.Direct_Enabled__c = isDirect;

            if (String.isNotBlank(firstRow.UnitPrice)) {
                fp.Price__c = Decimal.valueOf(firstRow.UnitPrice);
            }

            if (String.isNotBlank(firstRow.Warehouse) && warehouseMap.containsKey(firstRow.Warehouse)) {
                fp.Local_Warehouse__c = warehouseMap.get(firstRow.Warehouse);
            }

            forecastProductsToUpsert.add(fp);
            forecastProductMap.put(key, fp);
        }

        // Upsert forecast products
        if (!forecastProductsToUpsert.isEmpty()) {
            upsert forecastProductsToUpsert External_Id__c;
        }

        // Process months and quantities
        processMonthsAndQuantities(accountId, rowsByProduct, forecastProductMap, result);

        processedCount = rows.size();
        return processedCount;
    }

    /**
     * Process months and quantities for forecast items
     */
    private static void processMonthsAndQuantities(
        Id accountId,
        Map<String, List<CSVRow>> rowsByProduct,
        Map<String, Forecast_Product__c> forecastProductMap,
        UploadResult result
    ) {
        // Get existing forecast months
        Set<Id> forecastProductIds = new Set<Id>();
        for (Forecast_Product__c fp : forecastProductMap.values()) {
            forecastProductIds.add(fp.Id);
        }

        Map<Id, Map<String, Forecast_Month__c>> existingMonths = new Map<Id, Map<String, Forecast_Month__c>>();
        for (Forecast_Month__c fm : [
            SELECT Id, Forecast_Product__c, Month__c, External_Id__c
            FROM Forecast_Month__c
            WHERE Forecast_Product__c IN :forecastProductIds
        ]) {
            if (!existingMonths.containsKey(fm.Forecast_Product__c)) {
                existingMonths.put(fm.Forecast_Product__c, new Map<String, Forecast_Month__c>());
            }
            String monthKey = fm.Month__c.month() + '-' + fm.Month__c.year();
            existingMonths.get(fm.Forecast_Product__c).put(monthKey, fm);
        }

        // Prepare forecast months
        List<Forecast_Month__c> monthsToUpsert = new List<Forecast_Month__c>();
        Map<String, Forecast_Month__c> monthMap = new Map<String, Forecast_Month__c>();

        for (String productKey : rowsByProduct.keySet()) {
            Forecast_Product__c fp = forecastProductMap.get(productKey);

            for (CSVRow row : rowsByProduct.get(productKey)) {
                try {
                    Date monthDate = parseDate(row.Month);
                    String monthKey = monthDate.month() + '-' + monthDate.year();
                    String fullKey = fp.Id + '-' + monthKey;

                    Forecast_Month__c fm;
                    if (existingMonths.containsKey(fp.Id) && existingMonths.get(fp.Id).containsKey(monthKey)) {
                        fm = existingMonths.get(fp.Id).get(monthKey);
                    } else {
                        fm = new Forecast_Month__c();
                        fm.Forecast_Product__c = fp.Id;
                        fm.Month__c = monthDate;
                        fm.External_Id__c = accountId + '-' + fp.Product__c + '-' +
                                          ForecastUtil.getMonthUniqueId(monthDate) + '-' +
                                          (fp.Direct_Enabled__c ? '0' : '1');
                    }

                    if (!monthMap.containsKey(fullKey)) {
                        monthsToUpsert.add(fm);
                        monthMap.put(fullKey, fm);
                    }

                } catch (Exception e) {
                    result.errors.add('Row ' + row.rowNumber + ': Error parsing month - ' + e.getMessage());
                }
            }
        }

        // Upsert months
        if (!monthsToUpsert.isEmpty()) {
            upsert monthsToUpsert External_Id__c;
        }

        // Create/update forecast items
        createForecastItems(rowsByProduct, forecastProductMap, monthMap, result);
    }

    /**
     * Create forecast items (base quantities)
     */
    private static void createForecastItems(
        Map<String, List<CSVRow>> rowsByProduct,
        Map<String, Forecast_Product__c> forecastProductMap,
        Map<String, Forecast_Month__c> monthMap,
        UploadResult result
    ) {
        List<Forecast_Item__c> itemsToUpsert = new List<Forecast_Item__c>();

        for (String productKey : rowsByProduct.keySet()) {
            Forecast_Product__c fp = forecastProductMap.get(productKey);

            for (CSVRow row : rowsByProduct.get(productKey)) {
                try {
                    Date monthDate = parseDate(row.Month);
                    String monthKey = monthDate.month() + '-' + monthDate.year();
                    String fullKey = fp.Id + '-' + monthKey;

                    if (!monthMap.containsKey(fullKey)) {
                        result.errors.add('Row ' + row.rowNumber + ': Month not found for product');
                        continue;
                    }

                    Forecast_Month__c fm = monthMap.get(fullKey);

                    Forecast_Item__c item = new Forecast_Item__c();
                    item.Forecast__c = fm.Id;
                    item.Item_Type__c = 'Base';
                    item.Quantity__c = Decimal.valueOf(row.Quantity);
                    item.External_Id__c = fm.External_Id__c + '-Base';

                    itemsToUpsert.add(item);

                } catch (Exception e) {
                    result.errors.add('Row ' + row.rowNumber + ': Error creating forecast item - ' + e.getMessage());
                }
            }
        }

        if (!itemsToUpsert.isEmpty()) {
            upsert itemsToUpsert External_Id__c;
        }
    }

    /**
     * Parse CSV content into structured rows
     */
    private static List<CSVRow> parseCSV(String csvContent) {
        List<CSVRow> rows = new List<CSVRow>();
        List<String> lines = csvContent.split('\n');

        if (lines.size() < 2) {
            return rows;
        }

        // Parse headers
        String headerLine = lines[0].trim();
        List<String> headers = headerLine.split(',');
        Map<String, Integer> headerIndex = new Map<String, Integer>();

        for (Integer i = 0; i < headers.size(); i++) {
            headerIndex.put(headers[i].trim().toLowerCase(), i);
        }

        // Parse data rows
        for (Integer i = 1; i < lines.size(); i++) {
            String line = lines[i].trim();
            if (String.isBlank(line)) {
                continue;
            }

            List<String> values = line.split(',');
            CSVRow row = new CSVRow();
            row.rowNumber = i + 1;

            if (headerIndex.containsKey('accountid') && headerIndex.get('accountid') < values.size()) {
                row.AccountId = values[headerIndex.get('accountid')].trim();
            }
            if (headerIndex.containsKey('productid') && headerIndex.get('productid') < values.size()) {
                row.ProductId = values[headerIndex.get('productid')].trim();
            }
            if (headerIndex.containsKey('month') && headerIndex.get('month') < values.size()) {
                row.Month = values[headerIndex.get('month')].trim();
            }
            if (headerIndex.containsKey('quantity') && headerIndex.get('quantity') < values.size()) {
                row.Quantity = values[headerIndex.get('quantity')].trim();
            }
            if (headerIndex.containsKey('unitprice') && headerIndex.get('unitprice') < values.size()) {
                row.UnitPrice = values[headerIndex.get('unitprice')].trim();
            }
            if (headerIndex.containsKey('direct') && headerIndex.get('direct') < values.size()) {
                row.Direct = values[headerIndex.get('direct')].trim();
            }
            if (headerIndex.containsKey('local') && headerIndex.get('local') < values.size()) {
                row.Local = values[headerIndex.get('local')].trim();
            }
            if (headerIndex.containsKey('warehouse') && headerIndex.get('warehouse') < values.size()) {
                row.Warehouse = values[headerIndex.get('warehouse')].trim();
            }

            rows.add(row);
        }

        return rows;
    }

    /**
     * Parse date from MM/DD/YYYY format
     */
    private static Date parseDate(String dateStr) {
        if (String.isBlank(dateStr)) {
            return Date.today();
        }

        List<String> parts = dateStr.split('/');
        if (parts.size() != 3) {
            throw new IllegalArgumentException('Invalid date format. Expected MM/DD/YYYY');
        }

        Integer month = Integer.valueOf(parts[0]);
        Integer day = Integer.valueOf(parts[1]);
        Integer year = Integer.valueOf(parts[2]);

        return Date.newInstance(year, month, day);
    }

    /**
     * Validate Salesforce ID
     */
    private static Boolean isValidId(String idStr, String prefix) {
        if (String.isBlank(idStr)) {
            return false;
        }

        if (idStr.length() != 15 && idStr.length() != 18) {
            return false;
        }

        if (String.isNotBlank(prefix) && !idStr.startsWith(prefix)) {
            return false;
        }

        return true;
    }

    /**
     * Get upload template
     */
    @AuraEnabled(cacheable=true)
    public static String getCSVTemplate() {
        List<String> headers = new List<String>{
            'AccountId', 'ProductId', 'Month', 'Quantity',
            'UnitPrice', 'Direct', 'Local', 'Warehouse'
        };

        List<String> example = new List<String>{
            '001XXXXXXXXXXXXXXX', '01tXXXXXXXXXXXXXXX', '01/01/2025', '100',
            '50.00', 'true', 'false', 'Main Warehouse'
        };

        return String.join(headers, ',') + '\n' + String.join(example, ',');
    }
}
