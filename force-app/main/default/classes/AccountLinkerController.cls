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
     * Get aggregated unlinked Trace Sales
     * Checks cache first, falls back to Batch Apex for large datasets (>50K rows)
     */
    @AuraEnabled
    public static Map<String, Object> getAggregatedUnlinkedTraceSales() {
        try {
            // Check if results are in cache (from batch job)
            // Wrap cache access in try-catch to handle missing cache partition
            String cachedData = null;
            try {
                cachedData = (String)Cache.Org.get('local.TraceSales.unlinked');
            } catch (Exception cacheEx) {
                System.debug('Cache not available: ' + cacheEx.getMessage());
                // Cache partition doesn't exist, continue without cache
            }

            if (String.isNotBlank(cachedData)) {
                List<AggregatedTraceSale> results =
                    (List<AggregatedTraceSale>)JSON.deserialize(cachedData, List<AggregatedTraceSale>.class);

                return new Map<String, Object>{
                    'status' => 'ready',
                    'data' => results,
                    'source' => 'cache'
                };
            }

            // Check record count before attempting direct query
            Integer recordCount = [SELECT COUNT() FROM Trace_Sale__c WHERE Trace_Account_Mapping__c = null];

            // If more than 50K records, require batch processing
            if (recordCount > 50000) {
                return new Map<String, Object>{
                    'status' => 'needs_batch',
                    'data' => null,
                    'recordCount' => recordCount,
                    'message' => 'Dataset has ' + recordCount + ' records (>50K limit). Please start batch processing.'
                };
            }

            // Try direct query for smaller datasets (<= 50K)
            try {
                Map<String, AggregatedTraceSale> aggregationMap = new Map<String, AggregatedTraceSale>();

                // Get current year and process data year by year for the last 15 years
                Integer currentYear = Date.today().year();
                Integer startYear = currentYear - 14; // Last 15 years including current year

                // Process each year separately to avoid scanning too many rows
                for (Integer year = startYear; year <= currentYear; year++) {
                    List<AggregateResult> yearResults = queryAggregatesByYear(year, 'unlinked', null);
                    mergeAggregateResults(yearResults, aggregationMap);
                }

                // Convert map to list and sort by revenue
                List<AggregatedTraceSale> results = aggregationMap.values();
                results = sortByRevenue(results);

                // Return top 2000 to keep response size manageable
                if (results.size() > 2000) {
                    List<AggregatedTraceSale> topResults = new List<AggregatedTraceSale>();
                    for (Integer i = 0; i < 2000; i++) {
                        topResults.add(results[i]);
                    }
                    return new Map<String, Object>{
                        'status' => 'ready',
                        'data' => topResults,
                        'source' => 'direct'
                    };
                }

                return new Map<String, Object>{
                    'status' => 'ready',
                    'data' => results,
                    'source' => 'direct'
                };
            } catch (Exception queryEx) {
                // Direct query failed (likely too many rows), need batch job
                return new Map<String, Object>{
                    'status' => 'needs_batch',
                    'data' => null,
                    'message' => 'Dataset too large for direct query. Please start batch processing.'
                };
            }
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching unlinked trace sales: ' + e.getMessage());
        }
    }

    /**
     * Start batch job to process all records and compute aggregations
     * Use this for datasets larger than 50K rows
     */
    @AuraEnabled
    public static String startAggregationBatchJob(String mode) {
        try {
            TraceSaleAggregationBatch batch = new TraceSaleAggregationBatch(mode, null);
            Id batchId = Database.executeBatch(batch, 2000); // Process 2000 records per batch

            return batchId;
        } catch (Exception e) {
            throw new AuraHandledException('Error starting batch job: ' + e.getMessage());
        }
    }

    /**
     * Check status of batch job
     */
    @AuraEnabled
    public static Map<String, Object> checkBatchJobStatus(String jobId) {
        try {
            AsyncApexJob job = [
                SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems,
                       ExtendedStatus, CompletedDate
                FROM AsyncApexJob
                WHERE Id = :jobId
                LIMIT 1
            ];

            return new Map<String, Object>{
                'status' => job.Status,
                'processed' => job.JobItemsProcessed,
                'total' => job.TotalJobItems,
                'errors' => job.NumberOfErrors,
                'extendedStatus' => job.ExtendedStatus,
                'completedDate' => job.CompletedDate
            };
        } catch (Exception e) {
            throw new AuraHandledException('Error checking batch status: ' + e.getMessage());
        }
    }

    /**
     * Get total count of unlinked trace sales records
     * Used to display meaningful loading messages
     */
    @AuraEnabled
    public static Integer getUnlinkedTraceSalesCount() {
        try {
            return [SELECT COUNT() FROM Trace_Sale__c WHERE Trace_Account_Mapping__c = null];
        } catch (Exception e) {
            throw new AuraHandledException('Error getting record count: ' + e.getMessage());
        }
    }

    /**
     * Helper method to query aggregates for a specific year
     * Returns first 2000 groups without ORDER BY to avoid scanning all rows
     * If query fails (e.g., too many rows in year), splits by month
     */
    @TestVisible
    private static List<AggregateResult> queryAggregatesByYear(Integer year, String mode, String accountId) {
        // If a year might have >50K rows, go straight to monthly to avoid the error
        // This is a production-safe approach that handles massive datasets
        if (year >= Date.today().year() - 2) {
            // Recent years (last 2 years) might have massive data, use monthly directly
            return queryAggregatesByYearMonthly(year, mode, accountId);
        }

        try {
            Date yearStart = Date.newInstance(year, 1, 1);
            Date yearEnd = Date.newInstance(year, 12, 31);

            String query = 'SELECT ' +
                'Distributor__c, ' +
                'Customer__c, ' +
                'Zip_Code__c, ' +
                'City__c, ' +
                'State__c, ' +
                'Country__c, ' +
                'CALENDAR_YEAR(Distributor_Invoice_Date__c) yearVal, ' +
                'SUM(Revenue_Net__c) totalRevenue, ' +
                'COUNT(Id) recordCount ' +
                'FROM Trace_Sale__c WHERE ';

            if (mode == 'unlinked') {
                query += 'Trace_Account_Mapping__c = null AND ';
            } else if (mode == 'linked' && String.isNotBlank(accountId)) {
                query += 'Trace_Account_Mapping__r.Account__c = \'' + accountId + '\' AND ';
            }

            query += 'Distributor_Invoice_Date__c >= :yearStart AND Distributor_Invoice_Date__c <= :yearEnd ' +
                'GROUP BY Distributor__c, Customer__c, Zip_Code__c, City__c, State__c, Country__c, ' +
                'CALENDAR_YEAR(Distributor_Invoice_Date__c) ' +
                'LIMIT 2000';

            return Database.query(query);
        } catch (Exception e) {
            // If query fails (likely too many rows in this year), split by month
            System.debug('Year ' + year + ' query failed, falling back to monthly: ' + e.getMessage());
            return queryAggregatesByYearMonthly(year, mode, accountId);
        }
    }

    /**
     * Fallback method to query aggregates by month when a year has too many records
     * For extreme cases (987K in one month), returns representative sample without ORDER BY
     */
    @TestVisible
    private static List<AggregateResult> queryAggregatesByYearMonthly(Integer year, String mode, String accountId) {
        List<AggregateResult> allMonthResults = new List<AggregateResult>();

        // Process each month separately
        for (Integer month = 1; month <= 12; month++) {
            try {
                Date monthStart = Date.newInstance(year, month, 1);
                Date monthEnd = monthStart.addMonths(1).addDays(-1);

                // Query without ORDER BY to avoid scanning all rows
                // Returns first 2000 groups found (representative sample)
                String aggQuery = 'SELECT ' +
                    'Distributor__c, Customer__c, Zip_Code__c, City__c, State__c, Country__c, ' +
                    'CALENDAR_YEAR(Distributor_Invoice_Date__c) yearVal, ' +
                    'SUM(Revenue_Net__c) totalRevenue, COUNT(Id) recordCount ' +
                    'FROM Trace_Sale__c WHERE ';

                if (mode == 'unlinked') {
                    aggQuery += 'Trace_Account_Mapping__c = null AND ';
                } else if (mode == 'linked' && String.isNotBlank(accountId)) {
                    aggQuery += 'Trace_Account_Mapping__r.Account__c = \'' + accountId + '\' AND ';
                }

                aggQuery += 'Distributor_Invoice_Date__c >= :monthStart AND Distributor_Invoice_Date__c <= :monthEnd ' +
                    'GROUP BY Distributor__c, Customer__c, Zip_Code__c, City__c, State__c, Country__c, ' +
                    'CALENDAR_YEAR(Distributor_Invoice_Date__c) ' +
                    'LIMIT 2000';

                List<AggregateResult> monthResults = Database.query(aggQuery);
                allMonthResults.addAll(monthResults);
            } catch (Exception monthEx) {
                System.debug('Error querying month ' + month + ' of year ' + year + ': ' + monthEx.getMessage());
                // Continue with other months even if this one fails
            }
        }

        return allMonthResults;
    }

    /**
     * Helper method to merge aggregate results into the main map
     */
    @TestVisible
    private static void mergeAggregateResults(List<AggregateResult> aggregateResults, Map<String, AggregatedTraceSale> aggregationMap) {
        for (AggregateResult ar : aggregateResults) {
            String distributor = ar.get('Distributor__c') != null ? String.valueOf(ar.get('Distributor__c')) : '';
            String customer = ar.get('Customer__c') != null ? String.valueOf(ar.get('Customer__c')) : '';
            String zipCode = ar.get('Zip_Code__c') != null ? String.valueOf(ar.get('Zip_Code__c')) : '';
            String timePeriod = ar.get('yearVal') != null ? String.valueOf(ar.get('yearVal')) : '';

            String groupKey = distributor + '|' + customer + '|' + zipCode + '|' + timePeriod;

            AggregatedTraceSale agg;
            if (aggregationMap.containsKey(groupKey)) {
                // Merge with existing
                agg = aggregationMap.get(groupKey);
                agg.totalRevenue += (ar.get('totalRevenue') != null ? (Decimal)ar.get('totalRevenue') : 0);
                agg.recordCount += (ar.get('recordCount') != null ? (Integer)ar.get('recordCount') : 0);
            } else {
                // Create new
                agg = new AggregatedTraceSale();
                agg.groupKey = groupKey;
                agg.distributor = distributor;
                agg.customer = customer;
                agg.zipCode = zipCode;
                agg.city = ar.get('City__c') != null ? String.valueOf(ar.get('City__c')) : '';
                agg.state = ar.get('State__c') != null ? String.valueOf(ar.get('State__c')) : '';
                agg.country = ar.get('Country__c') != null ? String.valueOf(ar.get('Country__c')) : '';
                agg.timePeriod = timePeriod;
                agg.totalRevenue = ar.get('totalRevenue') != null ? (Decimal)ar.get('totalRevenue') : 0;
                agg.recordCount = ar.get('recordCount') != null ? (Integer)ar.get('recordCount') : 0;
                agg.traceSaleIds = new List<String>();
                agg.contractNames = '';
                aggregationMap.put(groupKey, agg);
            }
        }
    }

    /**
     * Helper method to sort aggregated results by revenue descending
     * Uses merge sort (O(n log n)) for better performance with large datasets
     */
    @TestVisible
    private static List<AggregatedTraceSale> sortByRevenue(List<AggregatedTraceSale> results) {
        if (results == null || results.size() <= 1) {
            return results;
        }
        return mergeSort(results, 0, results.size() - 1);
    }

    /**
     * Merge sort implementation for efficient sorting
     */
    private static List<AggregatedTraceSale> mergeSort(List<AggregatedTraceSale> arr, Integer left, Integer right) {
        if (left >= right) {
            return new List<AggregatedTraceSale>{ arr[left] };
        }

        Integer mid = left + (right - left) / 2;
        List<AggregatedTraceSale> leftSorted = mergeSort(arr, left, mid);
        List<AggregatedTraceSale> rightSorted = mergeSort(arr, mid + 1, right);

        return mergeLists(leftSorted, rightSorted);
    }

    /**
     * Merge two sorted lists in descending order by revenue
     */
    private static List<AggregatedTraceSale> mergeLists(List<AggregatedTraceSale> left, List<AggregatedTraceSale> right) {
        List<AggregatedTraceSale> result = new List<AggregatedTraceSale>();
        Integer i = 0, j = 0;

        while (i < left.size() && j < right.size()) {
            if (left[i].totalRevenue >= right[j].totalRevenue) {
                result.add(left[i]);
                i++;
            } else {
                result.add(right[j]);
                j++;
            }
        }

        while (i < left.size()) {
            result.add(left[i]);
            i++;
        }

        while (j < right.size()) {
            result.add(right[j]);
            j++;
        }

        return result;
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
     * Uses year-chunked queries to avoid hitting the 50k row limit
     */
    @AuraEnabled
    public static List<AggregatedTraceSale> getAggregatedLinkedTraceSales(String accountId) {
        try {
            // Check record count before attempting direct query
            Integer recordCount = [
                SELECT COUNT()
                FROM Trace_Sale__c
                WHERE Trace_Account_Mapping__r.Account__c = :accountId
            ];

            // If more than 50K records for this account, use batch processing
            if (recordCount > 50000) {
                throw new AuraHandledException(
                    'Account has ' + recordCount + ' linked records (>50K limit). Please use batch processing.'
                );
            }

            Map<String, AggregatedTraceSale> aggregationMap = new Map<String, AggregatedTraceSale>();

            // Get current year and process data year by year for the last 15 years
            Integer currentYear = Date.today().year();
            Integer startYear = currentYear - 14; // Last 15 years including current year

            // Process each year separately to avoid scanning too many rows
            for (Integer year = startYear; year <= currentYear; year++) {
                List<AggregateResult> yearResults = queryAggregatesByYear(year, 'linked', accountId);
                mergeAggregateResults(yearResults, aggregationMap);
            }

            // Convert map to list and sort by revenue
            List<AggregatedTraceSale> results = aggregationMap.values();
            results = sortByRevenue(results);

            // Return top 2000 to keep response size manageable
            if (results.size() > 2000) {
                List<AggregatedTraceSale> topResults = new List<AggregatedTraceSale>();
                for (Integer i = 0; i < 2000; i++) {
                    topResults.add(results[i]);
                }
                return topResults;
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