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
     * Wrapper class for Trace Account Mapping data with pagination support
     */
    public class TraceAccountMappingWrapper {
        @AuraEnabled public String id { get; set; }
        @AuraEnabled public String uniqueId { get; set; }
        @AuraEnabled public String distributor { get; set; }
        @AuraEnabled public String customer { get; set; }
        @AuraEnabled public String zipCode { get; set; }
        @AuraEnabled public String city { get; set; }
        @AuraEnabled public String state { get; set; }
        @AuraEnabled public String country { get; set; }
        @AuraEnabled public Decimal totalRevenue { get; set; }
        @AuraEnabled public String contractNames { get; set; }
        @AuraEnabled public String invoiceYear { get; set; }
    }

    /**
     * Wrapper class for paginated response
     */
    public class PaginatedResponse {
        @AuraEnabled public List<TraceAccountMappingWrapper> records { get; set; }
        @AuraEnabled public Integer totalRecords { get; set; }
        @AuraEnabled public Integer pageNumber { get; set; }
        @AuraEnabled public Integer pageSize { get; set; }
        @AuraEnabled public Integer totalPages { get; set; }
    }

    /**
     * Get unlinked Trace Account Mappings (Account__c IS NULL) with server-side pagination
     * Supports filtering and sorting by Unique_ID__c
     */
    @AuraEnabled
    public static PaginatedResponse getUnlinkedTraceAccountMappings(
        Integer pageNumber,
        Integer pageSize,
        String distributor,
        String customer,
        String zipCode,
        String city,
        String state,
        String country,
        String invoiceYear,
        String contractName
    ) {
        try {
            // Build dynamic WHERE clause
            String baseCondition = 'Account__c = null';
            List<String> conditions = new List<String>{ baseCondition };

            if (String.isNotBlank(distributor)) {
                String distributorFilter = '%' + String.escapeSingleQuotes(distributor) + '%';
                conditions.add('Distributor__c LIKE \'' + distributorFilter + '\'');
            }
            if (String.isNotBlank(customer)) {
                String customerFilter = '%' + String.escapeSingleQuotes(customer) + '%';
                conditions.add('Customer__c LIKE \'' + customerFilter + '\'');
            }
            if (String.isNotBlank(zipCode)) {
                String zipCodeFilter = '%' + String.escapeSingleQuotes(zipCode) + '%';
                conditions.add('Zip_Code__c LIKE \'' + zipCodeFilter + '\'');
            }
            if (String.isNotBlank(city)) {
                String cityFilter = '%' + String.escapeSingleQuotes(city) + '%';
                conditions.add('City__c LIKE \'' + cityFilter + '\'');
            }
            if (String.isNotBlank(state)) {
                String stateFilter = '%' + String.escapeSingleQuotes(state) + '%';
                conditions.add('State__c LIKE \'' + stateFilter + '\'');
            }
            if (String.isNotBlank(country)) {
                String countryFilter = '%' + String.escapeSingleQuotes(country) + '%';
                conditions.add('Country__c LIKE \'' + countryFilter + '\'');
            }
            if (String.isNotBlank(invoiceYear)) {
                String invoiceYearFilter = '%' + String.escapeSingleQuotes(invoiceYear) + '%';
                conditions.add('Invoice_Year__c LIKE \'' + invoiceYearFilter + '\'');
            }
            if (String.isNotBlank(contractName)) {
                String contractNameFilter = '%' + String.escapeSingleQuotes(contractName) + '%';
                conditions.add('Contract_Names_Numbers__c LIKE \'' + contractNameFilter + '\'');
            }

            String whereClause = String.join(conditions, ' AND ');

            // Get total count for pagination
            String countQuery = 'SELECT COUNT() FROM Trace_Account_Mapping__c WHERE ' + whereClause;
            Integer totalRecords = Database.countQuery(countQuery);

            // Calculate offset
            Integer offset = (pageNumber - 1) * pageSize;

            // Build main query with pagination
            String query = 'SELECT Id, Unique_ID__c, Distributor__c, Customer__c, Zip_Code__c, ' +
                          'City__c, State__c, Country__c, Total_Revenue__c, Contract_Names_Numbers__c, Invoice_Year__c ' +
                          'FROM Trace_Account_Mapping__c ' +
                          'WHERE ' + whereClause + ' ' +
                          'ORDER BY Unique_ID__c ASC ' +
                          'LIMIT :pageSize OFFSET :offset';

            List<Trace_Account_Mapping__c> mappings = Database.query(query);

            // Convert to wrapper
            List<TraceAccountMappingWrapper> wrapperList = new List<TraceAccountMappingWrapper>();
            for (Trace_Account_Mapping__c mapping : mappings) {
                TraceAccountMappingWrapper wrapper = new TraceAccountMappingWrapper();
                wrapper.id = mapping.Id;
                wrapper.uniqueId = mapping.Unique_ID__c;
                wrapper.distributor = mapping.Distributor__c;
                wrapper.customer = mapping.Customer__c;
                wrapper.zipCode = mapping.Zip_Code__c;
                wrapper.city = mapping.City__c;
                wrapper.state = mapping.State__c;
                wrapper.country = mapping.Country__c;
                wrapper.totalRevenue = mapping.Total_Revenue__c;
                wrapper.contractNames = mapping.Contract_Names_Numbers__c;
                wrapper.invoiceYear = mapping.Invoice_Year__c;
                wrapperList.add(wrapper);
            }

            // Build response
            PaginatedResponse response = new PaginatedResponse();
            response.records = wrapperList;
            response.totalRecords = totalRecords;
            response.pageNumber = pageNumber;
            response.pageSize = pageSize;
            response.totalPages = (Integer)Math.ceil((Double)totalRecords / pageSize);

            return response;

        } catch (Exception e) {
            throw new AuraHandledException('Error fetching unlinked trace account mappings: ' + e.getMessage());
        }
    }

    /**
     * Get linked Trace Account Mappings for a specific account with server-side pagination
     * Supports filtering and sorting by Unique_ID__c
     */
    @AuraEnabled
    public static PaginatedResponse getLinkedTraceAccountMappings(
        String accountId,
        Integer pageNumber,
        Integer pageSize,
        String distributor,
        String customer,
        String zipCode,
        String city,
        String state,
        String country,
        String invoiceYear,
        String contractName
    ) {
        try {
            if (String.isBlank(accountId)) {
                throw new AuraHandledException('Account ID is required');
            }

            // Build dynamic WHERE clause
            String baseCondition = 'Account__c = \'' + String.escapeSingleQuotes(accountId) + '\'';
            List<String> conditions = new List<String>{ baseCondition };

            if (String.isNotBlank(distributor)) {
                String distributorFilter = '%' + String.escapeSingleQuotes(distributor) + '%';
                conditions.add('Distributor__c LIKE \'' + distributorFilter + '\'');
            }
            if (String.isNotBlank(customer)) {
                String customerFilter = '%' + String.escapeSingleQuotes(customer) + '%';
                conditions.add('Customer__c LIKE \'' + customerFilter + '\'');
            }
            if (String.isNotBlank(zipCode)) {
                String zipCodeFilter = '%' + String.escapeSingleQuotes(zipCode) + '%';
                conditions.add('Zip_Code__c LIKE \'' + zipCodeFilter + '\'');
            }
            if (String.isNotBlank(city)) {
                String cityFilter = '%' + String.escapeSingleQuotes(city) + '%';
                conditions.add('City__c LIKE \'' + cityFilter + '\'');
            }
            if (String.isNotBlank(state)) {
                String stateFilter = '%' + String.escapeSingleQuotes(state) + '%';
                conditions.add('State__c LIKE \'' + stateFilter + '\'');
            }
            if (String.isNotBlank(country)) {
                String countryFilter = '%' + String.escapeSingleQuotes(country) + '%';
                conditions.add('Country__c LIKE \'' + countryFilter + '\'');
            }
            if (String.isNotBlank(invoiceYear)) {
                String invoiceYearFilter = '%' + String.escapeSingleQuotes(invoiceYear) + '%';
                conditions.add('Invoice_Year__c LIKE \'' + invoiceYearFilter + '\'');
            }
            if (String.isNotBlank(contractName)) {
                String contractNameFilter = '%' + String.escapeSingleQuotes(contractName) + '%';
                conditions.add('Contract_Names_Numbers__c LIKE \'' + contractNameFilter + '\'');
            }

            String whereClause = String.join(conditions, ' AND ');

            // Get total count for pagination
            String countQuery = 'SELECT COUNT() FROM Trace_Account_Mapping__c WHERE ' + whereClause;
            Integer totalRecords = Database.countQuery(countQuery);

            // Calculate offset
            Integer offset = (pageNumber - 1) * pageSize;

            // Build main query with pagination
            String query = 'SELECT Id, Unique_ID__c, Distributor__c, Customer__c, Zip_Code__c, ' +
                          'City__c, State__c, Country__c, Total_Revenue__c, Contract_Names_Numbers__c, Invoice_Year__c ' +
                          'FROM Trace_Account_Mapping__c ' +
                          'WHERE ' + whereClause + ' ' +
                          'ORDER BY Unique_ID__c ASC ' +
                          'LIMIT :pageSize OFFSET :offset';

            List<Trace_Account_Mapping__c> mappings = Database.query(query);

            // Convert to wrapper
            List<TraceAccountMappingWrapper> wrapperList = new List<TraceAccountMappingWrapper>();
            for (Trace_Account_Mapping__c mapping : mappings) {
                TraceAccountMappingWrapper wrapper = new TraceAccountMappingWrapper();
                wrapper.id = mapping.Id;
                wrapper.uniqueId = mapping.Unique_ID__c;
                wrapper.distributor = mapping.Distributor__c;
                wrapper.customer = mapping.Customer__c;
                wrapper.zipCode = mapping.Zip_Code__c;
                wrapper.city = mapping.City__c;
                wrapper.state = mapping.State__c;
                wrapper.country = mapping.Country__c;
                wrapper.totalRevenue = mapping.Total_Revenue__c;
                wrapper.contractNames = mapping.Contract_Names_Numbers__c;
                wrapper.invoiceYear = mapping.Invoice_Year__c;
                wrapperList.add(wrapper);
            }

            // Build response
            PaginatedResponse response = new PaginatedResponse();
            response.records = wrapperList;
            response.totalRecords = totalRecords;
            response.pageNumber = pageNumber;
            response.pageSize = pageSize;
            response.totalPages = (Integer)Math.ceil((Double)totalRecords / pageSize);

            return response;

        } catch (Exception e) {
            throw new AuraHandledException('Error fetching linked trace account mappings: ' + e.getMessage());
        }
    }

    /**
     * Link selected Trace Account Mappings to an Account
     * Sets Account__c field on the selected records
     */
    @AuraEnabled
    public static void linkTraceAccountMappings(List<String> mappingIds, String accountId) {
        try {
            if (mappingIds == null || mappingIds.isEmpty()) {
                throw new AuraHandledException('No records selected');
            }

            if (String.isBlank(accountId)) {
                throw new AuraHandledException('Account ID is required');
            }

            // Query the mappings to update
            List<Trace_Account_Mapping__c> mappingsToUpdate = [
                SELECT Id, Account__c
                FROM Trace_Account_Mapping__c
                WHERE Id IN :mappingIds AND Account__c = null
            ];

            if (mappingsToUpdate.isEmpty()) {
                throw new AuraHandledException('No valid records found to link');
            }

            // Update Account__c field
            for (Trace_Account_Mapping__c mapping : mappingsToUpdate) {
                mapping.Account__c = accountId;
            }

            update mappingsToUpdate;

        } catch (Exception e) {
            throw new AuraHandledException('Error linking trace account mappings: ' + e.getMessage());
        }
    }

    /**
     * Unlink selected Trace Account Mappings from an Account
     * Sets Account__c to null on the selected records
     */
    @AuraEnabled
    public static void unlinkTraceAccountMappings(List<String> mappingIds) {
        try {
            if (mappingIds == null || mappingIds.isEmpty()) {
                throw new AuraHandledException('No records selected');
            }

            // Query the mappings to update
            List<Trace_Account_Mapping__c> mappingsToUpdate = [
                SELECT Id, Account__c
                FROM Trace_Account_Mapping__c
                WHERE Id IN :mappingIds AND Account__c != null
            ];

            if (mappingsToUpdate.isEmpty()) {
                throw new AuraHandledException('No valid records found to unlink');
            }

            // Clear Account__c field
            for (Trace_Account_Mapping__c mapping : mappingsToUpdate) {
                mapping.Account__c = null;
            }

            update mappingsToUpdate;

        } catch (Exception e) {
            throw new AuraHandledException('Error unlinking trace account mappings: ' + e.getMessage());
        }
    }

    /**
     * Get count of unlinked Trace Account Mappings
     */
    @AuraEnabled
    public static Integer getUnlinkedCount() {
        try {
            return [SELECT COUNT() FROM Trace_Account_Mapping__c WHERE Account__c = null];
        } catch (Exception e) {
            throw new AuraHandledException('Error getting unlinked count: ' + e.getMessage());
        }
    }

    /**
     * Get count of linked Trace Account Mappings for a specific account
     */
    @AuraEnabled
    public static Integer getLinkedCount(String accountId) {
        try {
            if (String.isBlank(accountId)) {
                return 0;
            }
            return [SELECT COUNT() FROM Trace_Account_Mapping__c WHERE Account__c = :accountId];
        } catch (Exception e) {
            throw new AuraHandledException('Error getting linked count: ' + e.getMessage());
        }
    }
}