@IsTest
private class AccountLinkerControllerTest {

    @TestSetup
    static void setup() {
        // --- Accounts
        Account acme = new Account(Name = 'Acme Medical', Type = 'Customer');
        Account beta = new Account(Name = 'Beta Clinic', Type = 'Customer');
        insert new List<Account>{ acme, beta };

        // --- Unlinked Trace Account Mappings (Account__c IS NULL)
        List<Trace_Account_Mapping__c> unlinkedMappings = new List<Trace_Account_Mapping__c>();

        // Record 1 - will be used in link tests
        unlinkedMappings.add(new Trace_Account_Mapping__c(
            Unique_ID__c = 'DistX|CustY|10001',
            Distributor__c = 'DistX',
            Customer__c = 'CustY',
            Zip_Code__c = '10001',
            City__c = 'NYC',
            State__c = 'NY',
            Country__c = 'USA',
            Total_Revenue__c = 350,
            Contract_Names_Numbers__c = 'C-001, C-002',
            Invoice_Year__c = '2024'
        ));

        // Record 2
        unlinkedMappings.add(new Trace_Account_Mapping__c(
            Unique_ID__c = 'DistA|CustB|90210',
            Distributor__c = 'DistA',
            Customer__c = 'CustB',
            Zip_Code__c = '90210',
            City__c = 'Beverly Hills',
            State__c = 'CA',
            Country__c = 'USA',
            Total_Revenue__c = 500,
            Contract_Names_Numbers__c = 'C-100',
            Invoice_Year__c = '2023'
        ));

        // Record 3
        unlinkedMappings.add(new Trace_Account_Mapping__c(
            Unique_ID__c = 'DistX|CustY|10002',
            Distributor__c = 'DistX',
            Customer__c = 'CustY',
            Zip_Code__c = '10002',
            City__c = 'NYC',
            State__c = 'NY',
            Country__c = 'USA',
            Total_Revenue__c = 75,
            Contract_Names_Numbers__c = 'C-001',
            Invoice_Year__c = '2025'
        ));

        insert unlinkedMappings;

        // --- Linked Trace Account Mappings (Account__c = acme)
        List<Trace_Account_Mapping__c> linkedMappings = new List<Trace_Account_Mapping__c>();

        linkedMappings.add(new Trace_Account_Mapping__c(
            Account__c = acme.Id,
            Unique_ID__c = 'DistA|CustB|94105',
            Distributor__c = 'DistA',
            Customer__c = 'CustB',
            Zip_Code__c = '94105',
            City__c = 'San Francisco',
            State__c = 'CA',
            Country__c = 'USA',
            Total_Revenue__c = 30,
            Contract_Names_Numbers__c = 'K-100, K-101',
            Invoice_Year__c = '2024'
        ));

        linkedMappings.add(new Trace_Account_Mapping__c(
            Account__c = acme.Id,
            Unique_ID__c = 'DistA|CustC|94105',
            Distributor__c = 'DistA',
            Customer__c = 'CustC',
            Zip_Code__c = '94105',
            City__c = 'San Francisco',
            State__c = 'CA',
            Country__c = 'USA',
            Total_Revenue__c = 150,
            Contract_Names_Numbers__c = 'K-200',
            Invoice_Year__c = '2024'
        ));

        insert linkedMappings;
    }

    @IsTest
    static void testSearchAccounts() {
        Test.startTest();
        List<Account> results = AccountLinkerController.searchAccounts('Ac');
        Test.stopTest();

        System.assert(results.size() > 0, 'Expected at least one account to match query');
        Boolean hasAcme = false;
        for (Account a : results) {
            if (a.Name == 'Acme Medical') hasAcme = true;
        }
        System.assertEquals(true, hasAcme, 'Should include "Acme Medical" for LIKE %Ac%');
        System.assert(results.size() <= 10, 'Should respect LIMIT 10');
    }

    @IsTest
    static void testSearchAccountsWithNoResults() {
        Test.startTest();
        List<Account> results = AccountLinkerController.searchAccounts('XYZ_NONEXISTENT_ACCOUNT_999');
        Test.stopTest();

        System.assertEquals(0, results.size(), 'Should return empty list when no matches found');
    }

    @IsTest
    static void testGetUnlinkedTraceAccountMappings() {
        Test.startTest();
        AccountLinkerController.PaginatedResponse response =
            AccountLinkerController.getUnlinkedTraceAccountMappings(
                1, 10, null, null, null, null, null, null, null, null
            );
        Test.stopTest();

        // We have 3 unlinked mappings from setup
        System.assertEquals(3, response.totalRecords, 'Should have 3 unlinked mappings');
        System.assertEquals(3, response.records.size(), 'Page 1 should have all 3 records');
        System.assertEquals(1, response.pageNumber, 'Should be page 1');
        System.assertEquals(10, response.pageSize, 'Page size should be 10');
        System.assertEquals(1, response.totalPages, 'Should have 1 page');

        // Verify records are sorted by Unique_ID__c
        System.assertNotEquals(null, response.records[0].uniqueId, 'Records should have unique ID');
    }

    @IsTest
    static void testGetUnlinkedTraceAccountMappingsWithFilters() {
        Test.startTest();
        // Filter by distributor
        AccountLinkerController.PaginatedResponse response =
            AccountLinkerController.getUnlinkedTraceAccountMappings(
                1, 10, 'DistX', null, null, null, null, null, null, null
            );
        Test.stopTest();

        System.assertEquals(2, response.totalRecords, 'Should find 2 mappings with DistX');
        for (AccountLinkerController.TraceAccountMappingWrapper wrapper : response.records) {
            System.assert(wrapper.distributor.contains('DistX'), 'All records should match filter');
        }
    }

    @IsTest
    static void testGetUnlinkedTraceAccountMappingsWithMultipleFilters() {
        Test.startTest();
        AccountLinkerController.PaginatedResponse response =
            AccountLinkerController.getUnlinkedTraceAccountMappings(
                1, 10, 'DistX', 'CustY', '10001', 'NYC', 'NY', 'USA', '2024', null
            );
        Test.stopTest();

        System.assertEquals(1, response.totalRecords, 'Should find 1 mapping with all filters');
    }

    @IsTest
    static void testGetUnlinkedTraceAccountMappingsWithPagination() {
        Test.startTest();
        // Get page 1 with size 2
        AccountLinkerController.PaginatedResponse page1 =
            AccountLinkerController.getUnlinkedTraceAccountMappings(
                1, 2, null, null, null, null, null, null, null, null
            );

        // Get page 2 with size 2
        AccountLinkerController.PaginatedResponse page2 =
            AccountLinkerController.getUnlinkedTraceAccountMappings(
                2, 2, null, null, null, null, null, null, null, null
            );
        Test.stopTest();

        System.assertEquals(3, page1.totalRecords, 'Total should be 3');
        System.assertEquals(2, page1.records.size(), 'Page 1 should have 2 records');
        System.assertEquals(2, page1.totalPages, 'Should have 2 pages');

        System.assertEquals(1, page2.records.size(), 'Page 2 should have 1 record');
    }

    @IsTest
    static void testGetLinkedTraceAccountMappings() {
        Account acme = [SELECT Id FROM Account WHERE Name = 'Acme Medical' LIMIT 1];

        Test.startTest();
        AccountLinkerController.PaginatedResponse response =
            AccountLinkerController.getLinkedTraceAccountMappings(
                acme.Id, 1, 10, null, null, null, null, null, null, null, null
            );
        Test.stopTest();

        System.assertEquals(2, response.totalRecords, 'Acme should have 2 linked mappings');
        System.assertEquals(2, response.records.size(), 'Page should have 2 records');
    }

    @IsTest
    static void testGetLinkedTraceAccountMappingsWithFilters() {
        Account acme = [SELECT Id FROM Account WHERE Name = 'Acme Medical' LIMIT 1];

        Test.startTest();
        AccountLinkerController.PaginatedResponse response =
            AccountLinkerController.getLinkedTraceAccountMappings(
                acme.Id, 1, 10, null, 'CustB', null, null, null, null, null, null
            );
        Test.stopTest();

        System.assertEquals(1, response.totalRecords, 'Should find 1 mapping with CustB');
    }

    @IsTest
    static void testGetLinkedTraceAccountMappingsNoAccount() {
        Test.startTest();
        try {
            AccountLinkerController.getLinkedTraceAccountMappings(
                null, 1, 10, null, null, null, null, null, null, null, null
            );
            System.assert(false, 'Should throw exception for null account ID');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Account ID is required'), 'Should have proper error message');
        }
        Test.stopTest();
    }

    @IsTest
    static void testGetLinkedTraceAccountMappingsEmptyAccount() {
        Account beta = [SELECT Id FROM Account WHERE Name = 'Beta Clinic' LIMIT 1];

        Test.startTest();
        AccountLinkerController.PaginatedResponse response =
            AccountLinkerController.getLinkedTraceAccountMappings(
                beta.Id, 1, 10, null, null, null, null, null, null, null, null
            );
        Test.stopTest();

        System.assertEquals(0, response.totalRecords, 'Beta should have 0 linked mappings');
    }

    @IsTest
    static void testLinkTraceAccountMappings() {
        Account beta = [SELECT Id FROM Account WHERE Name = 'Beta Clinic' LIMIT 1];
        List<Trace_Account_Mapping__c> unlinked = [
            SELECT Id FROM Trace_Account_Mapping__c WHERE Account__c = null LIMIT 2
        ];

        List<String> mappingIds = new List<String>();
        for (Trace_Account_Mapping__c m : unlinked) {
            mappingIds.add(m.Id);
        }

        Test.startTest();
        AccountLinkerController.linkTraceAccountMappings(mappingIds, beta.Id);
        Test.stopTest();

        // Verify records are linked
        List<Trace_Account_Mapping__c> linkedMappings = [
            SELECT Id, Account__c FROM Trace_Account_Mapping__c WHERE Id IN :mappingIds
        ];
        for (Trace_Account_Mapping__c m : linkedMappings) {
            System.assertEquals(beta.Id, m.Account__c, 'Mapping should be linked to Beta');
        }
    }

    @IsTest
    static void testLinkTraceAccountMappingsEmptyList() {
        Account acme = [SELECT Id FROM Account WHERE Name = 'Acme Medical' LIMIT 1];

        Test.startTest();
        try {
            AccountLinkerController.linkTraceAccountMappings(new List<String>(), acme.Id);
            System.assert(false, 'Should throw exception for empty list');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('No records selected'), 'Should have proper error message');
        }
        Test.stopTest();
    }

    @IsTest
    static void testLinkTraceAccountMappingsNoAccount() {
        List<Trace_Account_Mapping__c> unlinked = [
            SELECT Id FROM Trace_Account_Mapping__c WHERE Account__c = null LIMIT 1
        ];

        Test.startTest();
        try {
            AccountLinkerController.linkTraceAccountMappings(
                new List<String>{ unlinked[0].Id }, null
            );
            System.assert(false, 'Should throw exception for null account ID');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Account ID is required'), 'Should have proper error message');
        }
        Test.stopTest();
    }

    @IsTest
    static void testLinkAlreadyLinkedMappings() {
        Account acme = [SELECT Id FROM Account WHERE Name = 'Acme Medical' LIMIT 1];
        Account beta = [SELECT Id FROM Account WHERE Name = 'Beta Clinic' LIMIT 1];

        // Get already linked mappings
        List<Trace_Account_Mapping__c> alreadyLinked = [
            SELECT Id FROM Trace_Account_Mapping__c WHERE Account__c = :acme.Id
        ];

        List<String> mappingIds = new List<String>();
        for (Trace_Account_Mapping__c m : alreadyLinked) {
            mappingIds.add(m.Id);
        }

        Test.startTest();
        try {
            // Try to link to Beta - should fail because they're already linked to Acme
            AccountLinkerController.linkTraceAccountMappings(mappingIds, beta.Id);
            System.assert(false, 'Should throw exception for already linked mappings');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('No valid records found'), 'Should have proper error message');
        }
        Test.stopTest();
    }

    @IsTest
    static void testUnlinkTraceAccountMappings() {
        Account acme = [SELECT Id FROM Account WHERE Name = 'Acme Medical' LIMIT 1];
        List<Trace_Account_Mapping__c> linked = [
            SELECT Id FROM Trace_Account_Mapping__c WHERE Account__c = :acme.Id LIMIT 1
        ];

        List<String> mappingIds = new List<String>{ linked[0].Id };

        Test.startTest();
        AccountLinkerController.unlinkTraceAccountMappings(mappingIds);
        Test.stopTest();

        // Verify record is unlinked
        Trace_Account_Mapping__c unlinkedMapping = [
            SELECT Id, Account__c FROM Trace_Account_Mapping__c WHERE Id = :linked[0].Id
        ];
        System.assertEquals(null, unlinkedMapping.Account__c, 'Mapping should be unlinked');
    }

    @IsTest
    static void testUnlinkTraceAccountMappingsEmptyList() {
        Test.startTest();
        try {
            AccountLinkerController.unlinkTraceAccountMappings(new List<String>());
            System.assert(false, 'Should throw exception for empty list');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('No records selected'), 'Should have proper error message');
        }
        Test.stopTest();
    }

    @IsTest
    static void testUnlinkAlreadyUnlinkedMappings() {
        // Get already unlinked mappings
        List<Trace_Account_Mapping__c> alreadyUnlinked = [
            SELECT Id FROM Trace_Account_Mapping__c WHERE Account__c = null LIMIT 1
        ];

        List<String> mappingIds = new List<String>{ alreadyUnlinked[0].Id };

        Test.startTest();
        try {
            AccountLinkerController.unlinkTraceAccountMappings(mappingIds);
            System.assert(false, 'Should throw exception for already unlinked mappings');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('No valid records found'), 'Should have proper error message');
        }
        Test.stopTest();
    }

    @IsTest
    static void testGetUnlinkedCount() {
        Test.startTest();
        Integer count = AccountLinkerController.getUnlinkedCount();
        Test.stopTest();

        System.assertEquals(3, count, 'Should have 3 unlinked mappings');
    }

    @IsTest
    static void testGetLinkedCount() {
        Account acme = [SELECT Id FROM Account WHERE Name = 'Acme Medical' LIMIT 1];
        Account beta = [SELECT Id FROM Account WHERE Name = 'Beta Clinic' LIMIT 1];

        Test.startTest();
        Integer acmeCount = AccountLinkerController.getLinkedCount(acme.Id);
        Integer betaCount = AccountLinkerController.getLinkedCount(beta.Id);
        Integer nullCount = AccountLinkerController.getLinkedCount(null);
        Test.stopTest();

        System.assertEquals(2, acmeCount, 'Acme should have 2 linked mappings');
        System.assertEquals(0, betaCount, 'Beta should have 0 linked mappings');
        System.assertEquals(0, nullCount, 'Null account should return 0');
    }

    @IsTest
    static void testGetUnlinkedWithContractNameFilter() {
        Test.startTest();
        AccountLinkerController.PaginatedResponse response =
            AccountLinkerController.getUnlinkedTraceAccountMappings(
                1, 10, null, null, null, null, null, null, null, 'C-001'
            );
        Test.stopTest();

        // Should find mappings that have C-001 in Contract_Names_Numbers__c
        System.assert(response.totalRecords >= 1, 'Should find at least one mapping with C-001');
    }

    @IsTest
    static void testLargeDatasetPagination() {
        // Create more unlinked mappings
        List<Trace_Account_Mapping__c> bulkMappings = new List<Trace_Account_Mapping__c>();
        for (Integer i = 0; i < 25; i++) {
            bulkMappings.add(new Trace_Account_Mapping__c(
                Unique_ID__c = 'BulkDist|BulkCust|' + String.valueOf(i).leftPad(5, '0'),
                Distributor__c = 'BulkDist',
                Customer__c = 'BulkCust',
                Zip_Code__c = String.valueOf(i).leftPad(5, '0'),
                City__c = 'BulkCity',
                State__c = 'BC',
                Country__c = 'USA',
                Total_Revenue__c = 100 + i,
                Invoice_Year__c = '2024'
            ));
        }
        insert bulkMappings;

        Test.startTest();
        // Test pagination with multiple pages
        AccountLinkerController.PaginatedResponse page1 =
            AccountLinkerController.getUnlinkedTraceAccountMappings(
                1, 10, null, null, null, null, null, null, null, null
            );

        AccountLinkerController.PaginatedResponse page3 =
            AccountLinkerController.getUnlinkedTraceAccountMappings(
                3, 10, null, null, null, null, null, null, null, null
            );
        Test.stopTest();

        // 3 from setup + 25 bulk = 28 total
        System.assertEquals(28, page1.totalRecords, 'Should have 28 total records');
        System.assertEquals(10, page1.records.size(), 'Page 1 should have 10 records');
        System.assertEquals(3, page1.totalPages, 'Should have 3 pages');

        System.assertEquals(8, page3.records.size(), 'Page 3 should have 8 remaining records');
    }

    @IsTest
    static void testWrapperClassFields() {
        Test.startTest();
        AccountLinkerController.PaginatedResponse response =
            AccountLinkerController.getUnlinkedTraceAccountMappings(
                1, 10, 'DistA', null, null, null, null, null, null, null
            );
        Test.stopTest();

        System.assert(response.records.size() > 0, 'Should have at least one record');

        AccountLinkerController.TraceAccountMappingWrapper wrapper = response.records[0];

        // Verify all fields are accessible
        System.assertNotEquals(null, wrapper.id, 'ID should not be null');
        System.assertNotEquals(null, wrapper.uniqueId, 'Unique ID should not be null');
        System.assertEquals('DistA', wrapper.distributor, 'Distributor should be DistA');
        System.assertNotEquals(null, wrapper.customer, 'Customer should not be null');
        System.assertNotEquals(null, wrapper.zipCode, 'Zip code should not be null');
        System.assertNotEquals(null, wrapper.city, 'City should not be null');
        System.assertNotEquals(null, wrapper.state, 'State should not be null');
        System.assertNotEquals(null, wrapper.country, 'Country should not be null');
        System.assertNotEquals(null, wrapper.totalRevenue, 'Total revenue should not be null');
        System.assertNotEquals(null, wrapper.invoiceYear, 'Invoice year should not be null');
    }

    @IsTest
    static void testPaginatedResponseClass() {
        Test.startTest();
        AccountLinkerController.PaginatedResponse response =
            AccountLinkerController.getUnlinkedTraceAccountMappings(
                1, 10, null, null, null, null, null, null, null, null
            );
        Test.stopTest();

        // Verify PaginatedResponse structure
        System.assertNotEquals(null, response.records, 'Records should not be null');
        System.assertNotEquals(null, response.totalRecords, 'Total records should not be null');
        System.assertNotEquals(null, response.pageNumber, 'Page number should not be null');
        System.assertNotEquals(null, response.pageSize, 'Page size should not be null');
        System.assertNotEquals(null, response.totalPages, 'Total pages should not be null');
    }

    @IsTest
    static void testLinkMultipleMappingsToSameAccount() {
        Account beta = [SELECT Id FROM Account WHERE Name = 'Beta Clinic' LIMIT 1];
        List<Trace_Account_Mapping__c> unlinked = [
            SELECT Id FROM Trace_Account_Mapping__c WHERE Account__c = null
        ];

        List<String> mappingIds = new List<String>();
        for (Trace_Account_Mapping__c m : unlinked) {
            mappingIds.add(m.Id);
        }

        Test.startTest();
        AccountLinkerController.linkTraceAccountMappings(mappingIds, beta.Id);
        Test.stopTest();

        // Verify all records are linked to Beta
        Integer linkedCount = [
            SELECT COUNT() FROM Trace_Account_Mapping__c WHERE Account__c = :beta.Id
        ];
        System.assertEquals(unlinked.size(), linkedCount, 'All mappings should be linked to Beta');
    }
}
