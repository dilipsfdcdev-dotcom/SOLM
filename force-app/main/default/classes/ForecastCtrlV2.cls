/**
 * ForecastCtrlV2 - Enhanced Forecast Controller for Forecasting 2.0
 * Supports mass upload with AccountId column for multi-account forecast uploads
 */
public with sharing class ForecastCtrlV2 {

    public class ProductWrapperV2 {
        public String AccountId;
        public String PRODUCT2ID;
        public String Direct;
        public String Local;
        public String Month;
        public String UNITPRICE;
        public String Quantity;
        public String Warehouse;
    }

    public class UploadResult {
        public Integer successCount = 0;
        public Integer errorCount = 0;
        public List<String> errors = new List<String>();
        public Set<String> processedAccounts = new Set<String>();
    }

    /**
     * Mass Upload Method - Supports multiple accounts in single CSV
     * CSV Format: AccountId, PRODUCT2ID, Direct, Local, Month, UNITPRICE, Quantity, Warehouse
     */
    @AuraEnabled
    public static String insertProductMassUpload(String prodJson) {
        try {
            if (String.isBlank(prodJson)) {
                return 'Error: No data provided';
            }

            List<ProductWrapperV2> pdList = (List<ProductWrapperV2>) JSON.deserialize(prodJson, List<ProductWrapperV2>.class);

            if (pdList.isEmpty()) {
                return 'Error: CSV file is empty';
            }

            // Validate AccountId column exists
            Boolean hasAccountId = false;
            for (ProductWrapperV2 p : pdList) {
                if (String.isNotBlank(p.AccountId)) {
                    hasAccountId = true;
                    break;
                }
            }

            if (!hasAccountId) {
                return 'Error: AccountId column is required for mass upload. Please include AccountId in your CSV.';
            }

            // Group products by AccountId
            Map<String, List<ProductWrapperV2>> productsByAccount = new Map<String, List<ProductWrapperV2>>();
            Set<String> accountIds = new Set<String>();

            for (ProductWrapperV2 p : pdList) {
                if (String.isNotBlank(p.AccountId)) {
                    accountIds.add(p.AccountId);

                    if (!productsByAccount.containsKey(p.AccountId)) {
                        productsByAccount.put(p.AccountId, new List<ProductWrapperV2>());
                    }
                    productsByAccount.get(p.AccountId).add(p);
                }
            }

            // Validate all accounts exist
            Map<Id, Account> accountMap = new Map<Id, Account>([
                SELECT Id, Name
                FROM Account
                WHERE Id IN :accountIds
            ]);

            if (accountMap.size() != accountIds.size()) {
                return 'Error: One or more AccountIds in the CSV do not exist in the system';
            }

            // Process each account
            UploadResult uploadResult = new UploadResult();

            for (String accountId : productsByAccount.keySet()) {
                try {
                    List<ProductWrapperV2> accountProducts = productsByAccount.get(accountId);
                    processAccountForecast(accountId, accountProducts);
                    uploadResult.successCount++;
                    uploadResult.processedAccounts.add(accountMap.get(accountId).Name);
                } catch (Exception e) {
                    uploadResult.errorCount++;
                    uploadResult.errors.add('Account ' + accountMap.get(accountId).Name + ': ' + e.getMessage());
                    System.debug('Error processing account ' + accountId + ': ' + e.getMessage());
                }
            }

            // Return result summary
            if (uploadResult.errorCount > 0) {
                String errorMsg = 'Partial Success: ' + uploadResult.successCount + ' accounts processed successfully, ' +
                                uploadResult.errorCount + ' failed. Errors: ' + String.join(uploadResult.errors, '; ');
                return errorMsg;
            }

            return 'Success';

        } catch (Exception e) {
            System.debug('Mass Upload Error: ' + e.getMessage());
            System.debug('Stack Trace: ' + e.getStackTraceString());
            return 'Error: ' + e.getMessage();
        }
    }

    /**
     * Process forecast data for a single account
     */
    private static void processAccountForecast(String accountId, List<ProductWrapperV2> products) {
        Map<Id, List<Forecast_Product__c>> productIdToForecastProduct = new Map<Id, List<Forecast_Product__c>>();
        Map<String, Id> warehouseNameToId = new Map<String, Id>();
        Map<String, Forecast_Product__c> forecastProductMap = new Map<String, Forecast_Product__c>();
        Set<Id> productIds = new Set<Id>();

        // Collect product IDs and warehouse names
        for (ProductWrapperV2 p : products) {
            if (String.isNotBlank(p.PRODUCT2ID)) {
                productIds.add(p.PRODUCT2ID);
            }
            if (String.isNotBlank(p.Warehouse)) {
                warehouseNameToId.put(p.Warehouse, null);
            }
        }

        // Query warehouses
        for (Warehouse__c w : [SELECT Id, Name FROM Warehouse__c WHERE Name IN :warehouseNameToId.keySet()]) {
            warehouseNameToId.put(w.Name, w.Id);
        }

        // Query existing forecast products
        for (Forecast_Product__c fp : [
            SELECT Id, Local_Enabled__c, Direct_Enabled__c, Product__c, Price__c
            FROM Forecast_Product__c
            WHERE Product__c IN :productIds AND Account__c = :accountId
        ]) {
            if (!productIdToForecastProduct.containsKey(fp.Product__c)) {
                productIdToForecastProduct.put(fp.Product__c, new List<Forecast_Product__c>());
            }
            productIdToForecastProduct.get(fp.Product__c).add(fp);
        }

        // Build forecast product records
        Map<String, Map<Integer, List<Integer>>> productToQuantityByMonth = new Map<String, Map<Integer, List<Integer>>>();
        Map<String, List<Date>> productToMonths = new Map<String, List<Date>>();

        for (ProductWrapperV2 p : products) {
            Id fpId = null;

            // Normalize boolean values
            String localEnabled = String.isBlank(p.Local) ? 'false' : p.Local.toLowerCase();
            String directEnabled = String.isBlank(p.Direct) ? 'false' : p.Direct.toLowerCase();

            // Find existing forecast product
            if (productIdToForecastProduct.containsKey(p.PRODUCT2ID)) {
                for (Forecast_Product__c fp : productIdToForecastProduct.get(p.PRODUCT2ID)) {
                    if (Boolean.valueOf(localEnabled) && fp.Local_Enabled__c) {
                        fpId = fp.Id;
                    }
                    if (Boolean.valueOf(directEnabled) && fp.Direct_Enabled__c) {
                        fpId = fp.Id;
                    }
                }
            }

            // Create product key
            String productKey = p.PRODUCT2ID + ';' + localEnabled + ';' + directEnabled;

            // Create or update forecast product
            forecastProductMap.put(fpId + ';' + productKey, new Forecast_Product__c(
                Id = fpId,
                Local_Warehouse__c = warehouseNameToId.get(p.Warehouse),
                Local_Enabled__c = Boolean.valueOf(localEnabled),
                Direct_Enabled__c = Boolean.valueOf(directEnabled),
                Price__c = String.isNotBlank(p.UNITPRICE) ? Decimal.valueOf(p.UNITPRICE) : 0,
                Account__c = accountId,
                Product__c = p.PRODUCT2ID,
                external_id__c = accountId + '-' + p.PRODUCT2ID + '-' + (Boolean.valueOf(directEnabled) ? '0' : '1')
            ));

            // Parse month date
            if (String.isNotBlank(p.Month)) {
                Date monthDate = parseMonthDate(p.Month);

                if (monthDate != null) {
                    if (!productToMonths.containsKey(productKey)) {
                        productToMonths.put(productKey, new List<Date>());
                    }
                    productToMonths.get(productKey).add(monthDate);

                    // Store quantity
                    Integer quantity = String.isNotBlank(p.Quantity) ? Integer.valueOf(p.Quantity) : 0;

                    if (!productToQuantityByMonth.containsKey(productKey)) {
                        productToQuantityByMonth.put(productKey, new Map<Integer, List<Integer>>());
                    }

                    Integer monthKey = monthDate.year() * 100 + monthDate.month();

                    if (!productToQuantityByMonth.get(productKey).containsKey(monthKey)) {
                        productToQuantityByMonth.get(productKey).put(monthKey, new List<Integer>());
                    }

                    productToQuantityByMonth.get(productKey).get(monthKey).add(quantity);
                }
            }
        }

        // Upsert Forecast Products
        if (!forecastProductMap.isEmpty()) {
            Database.UpsertResult[] results = Database.upsert(forecastProductMap.values(), Forecast_Product__c.external_id__c, false);

            // Check for errors
            for (Database.UpsertResult result : results) {
                if (!result.isSuccess()) {
                    for (Database.Error err : result.getErrors()) {
                        System.debug('Forecast Product Upsert Error: ' + err.getMessage());
                    }
                }
            }
        }

        // Query created forecast products to get IDs
        Map<String, Forecast_Product__c> externalIdToForecastProduct = new Map<String, Forecast_Product__c>();
        for (Forecast_Product__c fp : [
            SELECT Id, external_id__c, Product__c, Direct_Enabled__c, Local_Enabled__c
            FROM Forecast_Product__c
            WHERE Account__c = :accountId AND Product__c IN :productIds
        ]) {
            externalIdToForecastProduct.put(fp.external_id__c, fp);
        }

        // Create Forecast Months and Items
        List<Forecast_Month__c> forecastMonths = new List<Forecast_Month__c>();

        for (String productKey : productToMonths.keySet()) {
            List<String> keyParts = productKey.split(';');
            String productId = keyParts[0];
            Boolean directEnabled = Boolean.valueOf(keyParts[2]);

            String externalId = accountId + '-' + productId + '-' + (directEnabled ? '0' : '1');
            Forecast_Product__c fp = externalIdToForecastProduct.get(externalId);

            if (fp != null) {
                for (Date monthDate : productToMonths.get(productKey)) {
                    Integer monthKey = monthDate.year() * 100 + monthDate.month();
                    List<Integer> quantities = productToQuantityByMonth.get(productKey).get(monthKey);

                    Integer totalQuantity = 0;
                    for (Integer qty : quantities) {
                        totalQuantity += qty;
                    }

                    forecastMonths.add(new Forecast_Month__c(
                        Forecast_Product__c = fp.Id,
                        Month__c = monthDate,
                        Base_Total__c = totalQuantity,
                        Base_Direct__c = directEnabled ? totalQuantity : 0,
                        Base_Warehouse__c = !directEnabled ? totalQuantity : 0
                    ));
                }
            }
        }

        if (!forecastMonths.isEmpty()) {
            upsert forecastMonths;
        }

        // Update account forecasted products count
        updateAccountForecastCount(accountId);
    }

    /**
     * Parse month date from various formats
     */
    private static Date parseMonthDate(String monthStr) {
        try {
            // Support formats: MM/DD/YYYY, M/D/YYYY, YYYY-MM-DD
            if (monthStr.contains('/')) {
                List<String> parts = monthStr.split('/');
                if (parts.size() == 3) {
                    Integer month = Integer.valueOf(parts[0]);
                    Integer day = Integer.valueOf(parts[1]);
                    Integer year = Integer.valueOf(parts[2]);
                    return Date.newInstance(year, month, day);
                }
            } else if (monthStr.contains('-')) {
                return Date.valueOf(monthStr);
            }
        } catch (Exception e) {
            System.debug('Error parsing date: ' + monthStr + ' - ' + e.getMessage());
        }
        return null;
    }

    /**
     * Update forecasted products count on account
     */
    private static void updateAccountForecastCount(String accountId) {
        Integer count = [
            SELECT COUNT()
            FROM Forecast_Product__c
            WHERE Account__c = :accountId
        ];

        Account acc = new Account(
            Id = accountId,
            Forecasted_Products_Number__c = count
        );

        update acc;
    }
}
