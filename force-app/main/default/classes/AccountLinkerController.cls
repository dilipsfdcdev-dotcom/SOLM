public with sharing class AccountLinkerController {
    
    /**
     * Search for accounts based on search term
     */
    @AuraEnabled(cacheable=true)
    public static List<Account> searchAccounts(String searchTerm) {
        try {
            String searchKey = '%' + searchTerm + '%';
            return [
                SELECT Id, Name, Type 
                FROM Account 
                WHERE Name LIKE :searchKey 
                ORDER BY Name 
                LIMIT 10
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Error searching accounts: ' + e.getMessage());
        }
    }
    
    /**
     * Wrapper class for aggregated trace sale data
     */
    public class AggregatedTraceSale {
        @AuraEnabled public String groupKey { get; set; }
        @AuraEnabled public String distributor { get; set; }
        @AuraEnabled public String customer { get; set; }
        @AuraEnabled public String zipCode { get; set; }
        @AuraEnabled public String city { get; set; }
        @AuraEnabled public String state { get; set; }
        @AuraEnabled public String country { get; set; }
        @AuraEnabled public Decimal totalRevenue { get; set; }
        @AuraEnabled public String contractNames { get; set; }
        @AuraEnabled public List<String> traceSaleIds { get; set; }
        @AuraEnabled public String timePeriod { get; set; }
        @AuraEnabled public Integer recordCount { get; set; }
    }
    
    /**
     * Get aggregated unlinked Trace Sales using SOQL Aggregate Query
     * This approach avoids hitting the 50k row limit by aggregating in the database
     */
    @AuraEnabled
    public static List<AggregatedTraceSale> getAggregatedUnlinkedTraceSales() {
        try {
            // Use aggregate query to get grouped data
            List<AggregateResult> aggregateResults = [
                SELECT 
                    Distributor__c,
                    Customer__c,
                    Zip_Code__c,
                    City__c,
                    State__c,
                    Country__c,
                    CALENDAR_YEAR(Distributor_Invoice_Date__c) yearVal,
                    SUM(Revenue_Net__c) totalRevenue,
                    COUNT(Id) recordCount
                FROM Trace_Sale__c
                WHERE Trace_Account_Mapping__c = null
                GROUP BY 
                    Distributor__c,
                    Customer__c,
                    Zip_Code__c,
                    City__c,
                    State__c,
                    Country__c,
                    CALENDAR_YEAR(Distributor_Invoice_Date__c)
                ORDER BY SUM(Revenue_Net__c) DESC
                LIMIT 2000
            ];
            
            // Convert aggregate results to wrapper objects
            List<AggregatedTraceSale> results = new List<AggregatedTraceSale>();
            
            for (AggregateResult ar : aggregateResults) {
                AggregatedTraceSale agg = new AggregatedTraceSale();
                
                agg.distributor = ar.get('Distributor__c') != null ? String.valueOf(ar.get('Distributor__c')) : '';
                agg.customer = ar.get('Customer__c') != null ? String.valueOf(ar.get('Customer__c')) : '';
                agg.zipCode = ar.get('Zip_Code__c') != null ? String.valueOf(ar.get('Zip_Code__c')) : '';
                agg.city = ar.get('City__c') != null ? String.valueOf(ar.get('City__c')) : '';
                agg.state = ar.get('State__c') != null ? String.valueOf(ar.get('State__c')) : '';
                agg.country = ar.get('Country__c') != null ? String.valueOf(ar.get('Country__c')) : '';
                agg.timePeriod = ar.get('yearVal') != null ? String.valueOf(ar.get('yearVal')) : '';
                agg.totalRevenue = ar.get('totalRevenue') != null ? (Decimal)ar.get('totalRevenue') : 0;
                agg.recordCount = ar.get('recordCount') != null ? (Integer)ar.get('recordCount') : 0;
                
                // Create group key
                agg.groupKey = agg.distributor + '|' + agg.customer + '|' + agg.zipCode + '|' + agg.timePeriod;
                
                // Initialize empty lists/values that will be populated when needed
                agg.traceSaleIds = new List<String>();
                agg.contractNames = '';
                
                results.add(agg);
            }
            
            return results;
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching unlinked trace sales: ' + e.getMessage());
        }
    }
    
    /**
     * Get detailed Trace Sale IDs and contract names for a specific group
     * This is called on-demand when user selects rows to link
     */
    @AuraEnabled
    public static AggregatedTraceSale getTraceSaleDetailsForGroup(
        String distributor,
        String customer,
        String zipCode,
        String year
    ) {
        try {
            AggregatedTraceSale result = new AggregatedTraceSale();
            result.distributor = distributor;
            result.customer = customer;
            result.zipCode = zipCode;
            result.timePeriod = year;
            result.traceSaleIds = new List<String>();
            result.totalRevenue = 0;
            
            Set<String> contractNamesSet = new Set<String>();
            
            // Build WHERE clause
            String whereClause = 'Trace_Account_Mapping__c = null';
            
            if (String.isNotBlank(distributor)) {
                whereClause += ' AND Distributor__c = :distributor';
            } else {
                whereClause += ' AND Distributor__c = null';
            }
            
            if (String.isNotBlank(customer)) {
                whereClause += ' AND Customer__c = :customer';
            } else {
                whereClause += ' AND Customer__c = null';
            }
            
            if (String.isNotBlank(zipCode)) {
                whereClause += ' AND Zip_Code__c = :zipCode';
            } else {
                whereClause += ' AND Zip_Code__c = null';
            }
            
            if (String.isNotBlank(year)) {
                whereClause += ' AND CALENDAR_YEAR(Distributor_Invoice_Date__c) = ' + year;
            }
            
            // Query for specific records in this group
            String queryString = 'SELECT Id, Revenue_Net__c, Contract_Name_Number__c, City__c, State__c, Country__c ' +
                                'FROM Trace_Sale__c ' +
                                'WHERE ' + whereClause +
                                ' LIMIT 10000';
            
            List<Trace_Sale__c> traceSales = Database.query(queryString);
            
            for (Trace_Sale__c ts : traceSales) {
                result.traceSaleIds.add(ts.Id);
                
                if (ts.Revenue_Net__c != null) {
                    result.totalRevenue += ts.Revenue_Net__c;
                }
                
                if (String.isNotBlank(ts.Contract_Name_Number__c)) {
                    contractNamesSet.add(ts.Contract_Name_Number__c.trim());
                }
                
                // Set location info from first record
                if (result.traceSaleIds.size() == 1) {
                    result.city = ts.City__c != null ? ts.City__c : '';
                    result.state = ts.State__c != null ? ts.State__c : '';
                    result.country = ts.Country__c != null ? ts.Country__c : '';
                }
            }
            
            result.contractNames = String.join(new List<String>(contractNamesSet), ', ');
            result.recordCount = result.traceSaleIds.size();
            
            return result;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching trace sale details: ' + e.getMessage());
        }
    }
    
    /**
     * Get aggregated linked Trace Sales for a specific account
     */
    @AuraEnabled
    public static List<AggregatedTraceSale> getAggregatedLinkedTraceSales(String accountId) {
        try {
            // Use aggregate query
            List<AggregateResult> aggregateResults = [
                SELECT 
                    Distributor__c,
                    Customer__c,
                    Zip_Code__c,
                    City__c,
                    State__c,
                    Country__c,
                    CALENDAR_YEAR(Distributor_Invoice_Date__c) yearVal,
                    SUM(Revenue_Net__c) totalRevenue,
                    COUNT(Id) recordCount
                FROM Trace_Sale__c
                WHERE Trace_Account_Mapping__r.Account__c = :accountId
                GROUP BY 
                    Distributor__c,
                    Customer__c,
                    Zip_Code__c,
                    City__c,
                    State__c,
                    Country__c,
                    CALENDAR_YEAR(Distributor_Invoice_Date__c)
                ORDER BY SUM(Revenue_Net__c) DESC
                LIMIT 2000
            ];
            
            List<AggregatedTraceSale> results = new List<AggregatedTraceSale>();
            
            for (AggregateResult ar : aggregateResults) {
                AggregatedTraceSale agg = new AggregatedTraceSale();
                
                agg.distributor = ar.get('Distributor__c') != null ? String.valueOf(ar.get('Distributor__c')) : '';
                agg.customer = ar.get('Customer__c') != null ? String.valueOf(ar.get('Customer__c')) : '';
                agg.zipCode = ar.get('Zip_Code__c') != null ? String.valueOf(ar.get('Zip_Code__c')) : '';
                agg.city = ar.get('City__c') != null ? String.valueOf(ar.get('City__c')) : '';
                agg.state = ar.get('State__c') != null ? String.valueOf(ar.get('State__c')) : '';
                agg.country = ar.get('Country__c') != null ? String.valueOf(ar.get('Country__c')) : '';
                agg.timePeriod = ar.get('yearVal') != null ? String.valueOf(ar.get('yearVal')) : '';
                agg.totalRevenue = ar.get('totalRevenue') != null ? (Decimal)ar.get('totalRevenue') : 0;
                agg.recordCount = ar.get('recordCount') != null ? (Integer)ar.get('recordCount') : 0;
                
                agg.groupKey = agg.distributor + '|' + agg.customer + '|' + agg.zipCode + '|' + agg.timePeriod;
                agg.traceSaleIds = new List<String>();
                agg.contractNames = '';
                
                results.add(agg);
            }
            
            return results;
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching linked trace sales: ' + e.getMessage());
        }
    }
    
    /**
     * Create Trace Account Mapping records and link Trace Sales
     * This method fetches the detailed IDs before linking
     */
    @AuraEnabled
    public static void createTraceAccountMappings(String aggregatedDataJson, String accountId) {
        try {
            if (String.isBlank(aggregatedDataJson)) {
                throw new AuraHandledException('No data provided');
            }
            
            if (String.isBlank(accountId)) {
                throw new AuraHandledException('Account ID is required');
            }
            
            List<AggregatedTraceSale> aggregatedData = 
                (List<AggregatedTraceSale>) JSON.deserialize(aggregatedDataJson, List<AggregatedTraceSale>.class);
            
            List<Trace_Account_Mapping__c> mappingsToInsert = new List<Trace_Account_Mapping__c>();
            Map<Integer, AggregatedTraceSale> indexToDataMap = new Map<Integer, AggregatedTraceSale>();
            
            // First, get detailed data for each group
            for (Integer i = 0; i < aggregatedData.size(); i++) {
                AggregatedTraceSale agg = aggregatedData[i];
                
                // Fetch detailed IDs if not already populated
                if (agg.traceSaleIds == null || agg.traceSaleIds.isEmpty()) {
                    AggregatedTraceSale detailedData = getTraceSaleDetailsForGroup(
                        agg.distributor,
                        agg.customer,
                        agg.zipCode,
                        agg.timePeriod
                    );
                    agg.traceSaleIds = detailedData.traceSaleIds;
                    agg.contractNames = detailedData.contractNames;
                    agg.city = detailedData.city;
                    agg.state = detailedData.state;
                    agg.country = detailedData.country;
                }
                
                // Create mapping record
                Trace_Account_Mapping__c mapping = new Trace_Account_Mapping__c();
                mapping.Account__c = accountId;
                mapping.Distributor__c = agg.distributor;
                mapping.Ship_To_Name__c = agg.customer;
                mapping.Zip_Code__c = agg.zipCode;
                mapping.City__c = agg.city;
                mapping.State__c = agg.state;
                mapping.Country__c = agg.country;
                mapping.Total_Revenue__c = agg.totalRevenue;
                mapping.Contract_Names_Numbers__c = agg.contractNames;
                
                mappingsToInsert.add(mapping);
                indexToDataMap.put(i, agg);
            }
            
            // Insert mapping records
            insert mappingsToInsert;
            
            // Update Trace Sales with the mapping reference in batches
            List<Trace_Sale__c> traceSalesToUpdate = new List<Trace_Sale__c>();
            
            for (Integer i = 0; i < mappingsToInsert.size(); i++) {
                Trace_Account_Mapping__c mapping = mappingsToInsert[i];
                AggregatedTraceSale agg = indexToDataMap.get(i);
                
                for (String traceSaleId : agg.traceSaleIds) {
                    Trace_Sale__c ts = new Trace_Sale__c();
                    ts.Id = traceSaleId;
                    ts.Trace_Account_Mapping__c = mapping.Id;
                    traceSalesToUpdate.add(ts);
                    
                    // Update in batches of 10,000 to avoid DML limits
                    if (traceSalesToUpdate.size() >= 10000) {
                        update traceSalesToUpdate;
                        traceSalesToUpdate.clear();
                    }
                }
            }
            
            // Update any remaining records
            if (!traceSalesToUpdate.isEmpty()) {
                update traceSalesToUpdate;
            }
            
        } catch (Exception e) {
            throw new AuraHandledException('Error creating trace account mappings: ' + e.getMessage());
        }
    }
    
    /**
     * Unlink Trace Sales from Account (remove mapping reference)
     */
    @AuraEnabled
    public static void unlinkTraceAccountMappings(String aggregatedDataJson) {
        try {
            if (String.isBlank(aggregatedDataJson)) {
                throw new AuraHandledException('No data provided');
            }
            
            List<AggregatedTraceSale> aggregatedData = 
                (List<AggregatedTraceSale>) JSON.deserialize(aggregatedDataJson, List<AggregatedTraceSale>.class);
            
            Set<String> allTraceSaleIds = new Set<String>();
            
            // Fetch detailed IDs for each group if not provided
            for (AggregatedTraceSale agg : aggregatedData) {
                if (agg.traceSaleIds == null || agg.traceSaleIds.isEmpty()) {
                    AggregatedTraceSale detailedData = getTraceSaleDetailsForGroup(
                        agg.distributor,
                        agg.customer,
                        agg.zipCode,
                        agg.timePeriod
                    );
                    agg.traceSaleIds = detailedData.traceSaleIds;
                }
                allTraceSaleIds.addAll(agg.traceSaleIds);
            }
            
            // Process in batches
            List<String> idList = new List<String>(allTraceSaleIds);
            Integer batchSize = 10000;
            Set<Id> mappingIdsToDelete = new Set<Id>();
            
            for (Integer i = 0; i < idList.size(); i += batchSize) {
                Integer endIndex = Math.min(i + batchSize, idList.size());
                List<String> batchIds = new List<String>();
                for (Integer j = i; j < endIndex; j++) {
                    batchIds.add(idList[j]);
                }
                
                List<Trace_Sale__c> traceSalesToUpdate = [
                    SELECT Id, Trace_Account_Mapping__c 
                    FROM Trace_Sale__c 
                    WHERE Id IN :batchIds
                ];
                
                for (Trace_Sale__c ts : traceSalesToUpdate) {
                    if (ts.Trace_Account_Mapping__c != null) {
                        mappingIdsToDelete.add(ts.Trace_Account_Mapping__c);
                    }
                    ts.Trace_Account_Mapping__c = null;
                }
                
                update traceSalesToUpdate;
            }
            
            // Delete the mapping records
            if (!mappingIdsToDelete.isEmpty()) {
                List<Trace_Account_Mapping__c> mappingsToDelete = [
                    SELECT Id FROM Trace_Account_Mapping__c WHERE Id IN :mappingIdsToDelete
                ];
                delete mappingsToDelete;
            }
            
        } catch (Exception e) {
            throw new AuraHandledException('Error unlinking trace account mappings: ' + e.getMessage());
        }
    }
}