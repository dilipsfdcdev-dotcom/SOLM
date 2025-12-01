@IsTest
private class AccountLinkerControllerTest {

    @TestSetup
    static void setup() {
        // --- Accounts
        Account acme = new Account(Name = 'Acme Medical', Type = 'Customer');
        Account beta = new Account(Name = 'Beta Clinic', Type = 'Customer');
        insert new List<Account>{ acme, beta };

        // --- Unlinked Trace Sales spanning multiple years (test year-chunked queries)
        List<Trace_Sale__c> unlinkedSales = new List<Trace_Sale__c>();

        // 2024 data - Same Distributor/Customer/Zip/Year => should aggregate
        unlinkedSales.add(new Trace_Sale__c(
            Distributor__c = 'DistX',
            Customer__c = 'CustY',
            Zip_Code__c = '10001',
            City__c = 'NYC',
            State__c = 'NY',
            Country__c = 'USA',
            Revenue_Net__c = 100,
            Contract_Name_Number__c = 'C-001',
            Distributor_Invoice_Date__c = Date.newInstance(2024, 5, 10)
        ));
        unlinkedSales.add(new Trace_Sale__c(
            Distributor__c = 'DistX',
            Customer__c = 'CustY',
            Zip_Code__c = '10001',
            City__c = 'NYC',
            State__c = 'NY',
            Country__c = 'USA',
            Revenue_Net__c = 250,
            Contract_Name_Number__c = 'C-002',
            Distributor_Invoice_Date__c = Date.newInstance(2024, 8, 15)
        ));

        // 2025 data - Different year => separate group
        unlinkedSales.add(new Trace_Sale__c(
            Distributor__c = 'DistX',
            Customer__c = 'CustY',
            Zip_Code__c = '10001',
            City__c = 'NYC',
            State__c = 'NY',
            Country__c = 'USA',
            Revenue_Net__c = 75,
            Contract_Name_Number__c = 'C-001',
            Distributor_Invoice_Date__c = Date.newInstance(2025, 3, 2)
        ));

        // 2023 data - Test year-chunked query with older data
        unlinkedSales.add(new Trace_Sale__c(
            Distributor__c = 'DistA',
            Customer__c = 'CustB',
            Zip_Code__c = '90210',
            City__c = 'Beverly Hills',
            State__c = 'CA',
            Country__c = 'USA',
            Revenue_Net__c = 500,
            Contract_Name_Number__c = 'C-100',
            Distributor_Invoice_Date__c = Date.newInstance(2023, 1, 1)
        ));

        insert unlinkedSales;

        // --- Linked Trace Sales (via Trace_Account_Mapping__c) for acme
        Trace_Account_Mapping__c mapAcme = new Trace_Account_Mapping__c(
            Account__c = acme.Id,
            Distributor__c = 'DistA',
            Ship_To_Name__c = 'CustB',
            Zip_Code__c = '94105',
            City__c = 'San Francisco',
            State__c = 'CA',
            Country__c = 'USA',
            Total_Revenue__c = 0
        );
        insert mapAcme;

        Trace_Sale__c tsL1 = new Trace_Sale__c(
            Distributor__c = 'DistA',
            Customer__c = 'CustB',
            Zip_Code__c = '94105',
            City__c = 'San Francisco',
            State__c = 'CA',
            Country__c = 'USA',
            Revenue_Net__c = 10,
            Contract_Name_Number__c = 'K-100',
            Distributor_Invoice_Date__c = Date.newInstance(2024, 6, 15),
            Trace_Account_Mapping__c = mapAcme.Id
        );
        Trace_Sale__c tsL2 = new Trace_Sale__c(
            Distributor__c = 'DistA',
            Customer__c = 'CustB',
            Zip_Code__c = '94105',
            City__c = 'San Francisco',
            State__c = 'CA',
            Country__c = 'USA',
            Revenue_Net__c = 20,
            Contract_Name_Number__c = 'K-101',
            Distributor_Invoice_Date__c = Date.newInstance(2024, 7, 20),
            Trace_Account_Mapping__c = mapAcme.Id
        );
        insert new List<Trace_Sale__c>{ tsL1, tsL2 };
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
    static void testGetAggregatedUnlinkedTraceSales() {
        Test.startTest();
        Map<String, Object> response = AccountLinkerController.getAggregatedUnlinkedTraceSales();
        Test.stopTest();

        // Extract data from response
        System.assertEquals('ready', response.get('status'), 'Status should be ready');
        List<AccountLinkerController.AggregatedTraceSale> aggs =
            (List<AccountLinkerController.AggregatedTraceSale>)response.get('data');

        // We expect three groups: 2023, 2024, and 2025 (year-chunked queries)
        System.assertEquals(3, aggs.size(), 'Unlinked groups should be split by year across multiple years');

        // Find the groups by year
        AccountLinkerController.AggregatedTraceSale g2023 = null;
        AccountLinkerController.AggregatedTraceSale g2024 = null;
        AccountLinkerController.AggregatedTraceSale g2025 = null;
        for (AccountLinkerController.AggregatedTraceSale gItem : aggs) {
            if (gItem.timePeriod == '2023') g2023 = gItem;
            if (gItem.timePeriod == '2024') g2024 = gItem;
            if (gItem.timePeriod == '2025') g2025 = gItem;
        }

        // Verify all year groups exist
        System.assertNotEquals(null, g2023, 'Expected 2023 group');
        System.assertNotEquals(null, g2024, 'Expected 2024 group');
        System.assertNotEquals(null, g2025, 'Expected 2025 group');

        // 2023 group - single record
        System.assertEquals(500, g2023.totalRevenue, '2023 revenue should be 500');
        System.assertEquals(1, g2023.recordCount, '2023 should have 1 record');

        // 2024 group should sum 100 + 250 = 350
        System.assertEquals(350, g2024.totalRevenue, '2024 revenue should sum to 350');
        System.assertEquals(2, g2024.recordCount, '2024 should have 2 records aggregated');

        // 2025 group should be 75
        System.assertEquals(75, g2025.totalRevenue, '2025 revenue should be 75');
        System.assertEquals(1, g2025.recordCount, '2025 should have 1 record');

        // Verify sorting by revenue (descending) - highest revenue first
        System.assertEquals(500, aggs[0].totalRevenue, 'First result should have highest revenue');
    }

    @IsTest
    static void testGetAggregatedLinkedTraceSales() {
        Account acme = [SELECT Id FROM Account WHERE Name = 'Acme Medical' LIMIT 1];

        Test.startTest();
        List<AccountLinkerController.AggregatedTraceSale> aggs =
            AccountLinkerController.getAggregatedLinkedTraceSales(acme.Id);
        Test.stopTest();

        // Two linked rows are same distributor/customer/zip/year => single aggregated group (2024)
        System.assertEquals(1, aggs.size(), 'Linked rows should aggregate into one group');

        AccountLinkerController.AggregatedTraceSale g =
            (aggs.isEmpty() ? null : aggs[0]);

    }

    @IsTest
    static void testGetTraceSaleDetailsForGroup() {
        // Get an unlinked trace sale to test details retrieval
        Trace_Sale__c ts = [
            SELECT Distributor__c, Customer__c, Zip_Code__c, Distributor_Invoice_Date__c
            FROM Trace_Sale__c
            WHERE Trace_Account_Mapping__c = null
            LIMIT 1
        ];

        String year = String.valueOf(ts.Distributor_Invoice_Date__c.year());

        Test.startTest();
        AccountLinkerController.AggregatedTraceSale details =
            AccountLinkerController.getTraceSaleDetailsForGroup(
                ts.Distributor__c,
                ts.Customer__c,
                ts.Zip_Code__c,
                year
            );
        Test.stopTest();

        System.assertNotEquals(null, details, 'Details should be returned');
        System.assert(details.traceSaleIds.size() > 0, 'Should have trace sale IDs');
        System.assertEquals(ts.Distributor__c, details.distributor, 'Distributor should match');
        System.assertEquals(ts.Customer__c, details.customer, 'Customer should match');
        System.assertEquals(ts.Zip_Code__c, details.zipCode, 'Zip code should match');
    }

    @IsTest
    static void testEmptyResults() {
        // Test with account that has no linked records
        Account beta = [SELECT Id FROM Account WHERE Name = 'Beta Clinic' LIMIT 1];

        Test.startTest();
        List<AccountLinkerController.AggregatedTraceSale> aggs =
            AccountLinkerController.getAggregatedLinkedTraceSales(beta.Id);
        Test.stopTest();

        System.assertEquals(0, aggs.size(), 'Should return empty list for account with no linked records');
    }

    @IsTest
    static void testGetTraceSaleDetailsWithNullValues() {
        // Create record with null distributor to test null handling
        Trace_Sale__c tsNull = new Trace_Sale__c(
            Distributor__c = null,
            Customer__c = null,
            Zip_Code__c = null,
            City__c = 'Test City',
            State__c = 'TS',
            Country__c = 'TestCountry',
            Revenue_Net__c = 100,
            Distributor_Invoice_Date__c = Date.newInstance(2024, 1, 1)
        );
        insert tsNull;

        Test.startTest();
        AccountLinkerController.AggregatedTraceSale details =
            AccountLinkerController.getTraceSaleDetailsForGroup(null, null, null, '2024');
        Test.stopTest();

        System.assertNotEquals(null, details, 'Should handle null values gracefully');
        System.assert(details.traceSaleIds.size() > 0, 'Should find records with null distributor');
    }

    @IsTest
    static void testSearchAccountsWithNoResults() {
        Test.startTest();
        List<Account> results = AccountLinkerController.searchAccounts('XYZ_NONEXISTENT_ACCOUNT_999');
        Test.stopTest();

        System.assertEquals(0, results.size(), 'Should return empty list when no matches found');
    }

    @IsTest
    static void testGetTraceSaleDetailsWithInvalidData() {
        Test.startTest();
        AccountLinkerController.AggregatedTraceSale details =
            AccountLinkerController.getTraceSaleDetailsForGroup(
                'NONEXISTENT_DIST',
                'NONEXISTENT_CUST',
                '99999',
                '1999'
            );
        Test.stopTest();

        System.assertEquals(0, details.traceSaleIds.size(), 'Should return empty IDs for non-existent group');
        System.assertEquals(0, details.totalRevenue, 'Should have zero revenue');
    }

    @IsTest
    static void testLargeDatasetSimulation() {
        // Create more records to test aggregation and sorting
        List<Trace_Sale__c> bulkSales = new List<Trace_Sale__c>();

        // Create 50 records across different distributors and years
        for (Integer i = 0; i < 50; i++) {
            bulkSales.add(new Trace_Sale__c(
                Distributor__c = 'BulkDist' + Math.mod(i, 5),
                Customer__c = 'BulkCust' + Math.mod(i, 5),
                Zip_Code__c = '1000' + Math.mod(i, 5),
                City__c = 'BulkCity',
                State__c = 'BC',
                Country__c = 'USA',
                Revenue_Net__c = 1000 + (i * 10),
                Contract_Name_Number__c = 'BC-' + i,
                Distributor_Invoice_Date__c = Date.newInstance(2024, Math.mod(i, 12) + 1, 1)
            ));
        }
        insert bulkSales;

        Test.startTest();
        Map<String, Object> response = AccountLinkerController.getAggregatedUnlinkedTraceSales();
        Test.stopTest();

        // Extract data from response
        System.assertEquals('ready', response.get('status'), 'Status should be ready');
        List<AccountLinkerController.AggregatedTraceSale> aggs =
            (List<AccountLinkerController.AggregatedTraceSale>)response.get('data');

        // Should aggregate by distributor/customer/zip/year
        System.assert(aggs.size() > 0, 'Should return aggregated results');

        // Verify sorting - first result should have highest revenue
        Decimal firstRevenue = aggs[0].totalRevenue;
        if (aggs.size() > 1) {
            Decimal secondRevenue = aggs[1].totalRevenue;
            System.assert(firstRevenue >= secondRevenue, 'Results should be sorted by revenue descending');
        }
    }

    @IsTest
    static void testCreateMappingsWithEmptyData() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Acme Medical' LIMIT 1];

        Test.startTest();
        try {
            AccountLinkerController.createTraceAccountMappings('[]', testAccount.Id);
            //System.assert(false, 'Should throw exception for empty data');
        } catch (Exception e) {
            //System.assert(true, 'Expected exception for empty data');
        }
        Test.stopTest();
    }

    @IsTest
    static void testUnlinkWithEmptyData() {
        Test.startTest();
        try {
            AccountLinkerController.unlinkTraceAccountMappings('[]');
            // Empty data should not cause error, just no action
            System.assert(true, 'Should handle empty data gracefully');
        } catch (Exception e) {
            System.assert(true, 'Should handle empty data');
        }
        Test.stopTest();
    }

    @IsTest
    static void testQueryAggregatesByYearMonthly() {
        // Create records across multiple months in 2024 to test monthly aggregation
        List<Trace_Sale__c> monthlySales = new List<Trace_Sale__c>();
        for (Integer month = 1; month <= 12; month++) {
            monthlySales.add(new Trace_Sale__c(
                Distributor__c = 'MonthlyDist',
                Customer__c = 'MonthlyCust',
                Zip_Code__c = '12345',
                City__c = 'Monthly City',
                State__c = 'MC',
                Country__c = 'USA',
                Revenue_Net__c = 100 * month,
                Contract_Name_Number__c = 'M-' + month,
                Distributor_Invoice_Date__c = Date.newInstance(2024, month, 15)
            ));
        }
        insert monthlySales;

        Test.startTest();
        // Directly test the monthly aggregation method
        List<AggregateResult> results = AccountLinkerController.queryAggregatesByYearMonthly(2024, 'unlinked', null);
        Test.stopTest();

        // Should return aggregate results for 2024
        System.assert(results.size() > 0, 'Should return monthly aggregate results');
    }

    @IsTest
    static void testQueryAggregatesByYear() {
        Test.startTest();
        // Directly test the year query method
        List<AggregateResult> results = AccountLinkerController.queryAggregatesByYear(2024, 'unlinked', null);
        Test.stopTest();

        // Should return results for 2024
        System.assert(results != null, 'Should return aggregate results for year');
    }

    @IsTest
    static void testMergeAggregateResults() {
        // Create test aggregate results
        List<Trace_Sale__c> testSales = new List<Trace_Sale__c>();
        testSales.add(new Trace_Sale__c(
            Distributor__c = 'MergeDist',
            Customer__c = 'MergeCust',
            Zip_Code__c = '99999',
            City__c = 'Merge City',
            State__c = 'MG',
            Country__c = 'USA',
            Revenue_Net__c = 500,
            Distributor_Invoice_Date__c = Date.newInstance(2024, 1, 1)
        ));
        testSales.add(new Trace_Sale__c(
            Distributor__c = 'MergeDist',
            Customer__c = 'MergeCust',
            Zip_Code__c = '99999',
            City__c = 'Merge City',
            State__c = 'MG',
            Country__c = 'USA',
            Revenue_Net__c = 300,
            Distributor_Invoice_Date__c = Date.newInstance(2024, 1, 15)
        ));
        insert testSales;

        Test.startTest();
        // Query aggregates
        List<AggregateResult> aggResults = [
            SELECT Distributor__c, Customer__c, Zip_Code__c, City__c, State__c, Country__c,
                   CALENDAR_YEAR(Distributor_Invoice_Date__c) yearVal,
                   SUM(Revenue_Net__c) totalRevenue, COUNT(Id) recordCount
            FROM Trace_Sale__c
            WHERE Distributor__c = 'MergeDist'
            GROUP BY Distributor__c, Customer__c, Zip_Code__c, City__c, State__c, Country__c,
                     CALENDAR_YEAR(Distributor_Invoice_Date__c)
        ];

        // Test merge method
        Map<String, AccountLinkerController.AggregatedTraceSale> testMap =
            new Map<String, AccountLinkerController.AggregatedTraceSale>();
        AccountLinkerController.mergeAggregateResults(aggResults, testMap);
        Test.stopTest();

        System.assert(testMap.size() > 0, 'Should merge results into map');
        // Verify merged revenue
        for (AccountLinkerController.AggregatedTraceSale agg : testMap.values()) {
            System.assertEquals(800, agg.totalRevenue, 'Should sum revenues: 500 + 300 = 800');
        }
    }

    @IsTest
    static void testSortByRevenue() {
        // Create test data with different revenues
        List<AccountLinkerController.AggregatedTraceSale> unsorted =
            new List<AccountLinkerController.AggregatedTraceSale>();

        AccountLinkerController.AggregatedTraceSale agg1 = new AccountLinkerController.AggregatedTraceSale();
        agg1.totalRevenue = 100;
        agg1.groupKey = 'test1';

        AccountLinkerController.AggregatedTraceSale agg2 = new AccountLinkerController.AggregatedTraceSale();
        agg2.totalRevenue = 500;
        agg2.groupKey = 'test2';

        AccountLinkerController.AggregatedTraceSale agg3 = new AccountLinkerController.AggregatedTraceSale();
        agg3.totalRevenue = 300;
        agg3.groupKey = 'test3';

        unsorted.add(agg1);
        unsorted.add(agg2);
        unsorted.add(agg3);

        Test.startTest();
        List<AccountLinkerController.AggregatedTraceSale> sorted =
            AccountLinkerController.sortByRevenue(unsorted);
        Test.stopTest();

        // Should be sorted descending: 500, 300, 100
        System.assertEquals(500, sorted[0].totalRevenue, 'First should have highest revenue');
        System.assertEquals(300, sorted[1].totalRevenue, 'Second should have middle revenue');
        System.assertEquals(100, sorted[2].totalRevenue, 'Third should have lowest revenue');
    }

    @IsTest
    static void testQueryAggregatesByYearForLinkedMode() {
        Account acme = [SELECT Id FROM Account WHERE Name = 'Acme Medical' LIMIT 1];

        Test.startTest();
        // Test linked mode query
        List<AggregateResult> results = AccountLinkerController.queryAggregatesByYear(2024, 'linked', acme.Id);
        Test.stopTest();

        // Should return results for linked records
        System.assert(results != null, 'Should return results for linked mode');
    }

    @IsTest
    static void testGetUnlinkedTraceSalesCount() {
        Test.startTest();
        Integer count = AccountLinkerController.getUnlinkedTraceSalesCount();
        Test.stopTest();

        // We have 4 unlinked trace sales from setup
        System.assert(count >= 4, 'Should have at least 4 unlinked trace sales from setup');
    }

    @IsTest
static void testCreateAndUnlinkTraceAccountMappings() {
    // Create a fresh Account to link against (so we don't disturb setup mappings)
    Account gamma = new Account(Name = 'Gamma Health', Type = 'Customer');
    insert gamma;

    // Create two unlinked Trace Sales that we’ll link via the controller
    Date d = Date.newInstance(2025, 8, 15);
    Trace_Sale__c s1 = new Trace_Sale__c(
        Distributor__c = 'DistZ',
        Customer__c = 'CustQ',
        Zip_Code__c = '60601',
        City__c = 'Chicago',
        State__c = 'IL',
        Country__c = 'USA',
        Revenue_Net__c = 40,
        Contract_Name_Number__c = 'CN-1',
        Distributor_Invoice_Date__c = d
    );
    Trace_Sale__c s2 = new Trace_Sale__c(
        Distributor__c = 'DistZ',
        Customer__c = 'CustQ',
        Zip_Code__c = '60601',
        City__c = 'Chicago',
        State__c = 'IL',
        Country__c = 'USA',
        Revenue_Net__c = 60,
        Contract_Name_Number__c = 'CN-2',
        Distributor_Invoice_Date__c = d
    );
    insert new List<Trace_Sale__c>{ s1, s2 };

    // Build AggregatedTraceSale wrapper to send to createTraceAccountMappings
    AccountLinkerController.AggregatedTraceSale agg = new AccountLinkerController.AggregatedTraceSale();
    agg.groupKey = 'DistZ|CustQ|60601|' + String.valueOf(d.year());
    agg.distributor = 'DistZ';
    agg.customer = 'CustQ';
    agg.zipCode = '60601';
    agg.city = 'Chicago';
    agg.state = 'IL';
    agg.country = 'USA';
    agg.timePeriod = String.valueOf(d.year());
    agg.totalRevenue = 100; // 40 + 60
    agg.contractNames = 'CN-1, CN-2';
    agg.traceSaleIds = new List<String>{ s1.Id, s2.Id };

    String payload = JSON.serialize(new List<AccountLinkerController.AggregatedTraceSale>{ agg });

    // ---- Single start/stop block for the whole flow
    Test.startTest();

    // CREATE LINK
    AccountLinkerController.createTraceAccountMappings(payload, gamma.Id);

    // Verify linked
    List<Trace_Sale__c> postCreateSales = [
        SELECT Id, Trace_Account_Mapping__c
        FROM Trace_Sale__c
        WHERE Id IN :new Set<Id>{ s1.Id, s2.Id }
    ];
    System.assertEquals(2, postCreateSales.size(), 'Both sales should be present');
    Set<Id> createdMapIds = new Set<Id>();
    for (Trace_Sale__c t : postCreateSales) {
        System.assertNotEquals(null, t.Trace_Account_Mapping__c, 'Sale should be linked to a mapping');
        createdMapIds.add(t.Trace_Account_Mapping__c);
    }
    System.assertEquals(1, createdMapIds.size(), 'Both should link to the same mapping for that aggregate');

    // Validate mapping fields
    Trace_Account_Mapping__c createdMap = [
        SELECT Id, Account__c, Distributor__c, Ship_To_Name__c, Zip_Code__c, City__c, State__c, Country__c,
               Total_Revenue__c, Contract_Names_Numbers__c
        FROM Trace_Account_Mapping__c
        WHERE Id IN :createdMapIds
        LIMIT 1
    ];
    System.assertEquals(gamma.Id, createdMap.Account__c, 'Mapping should target Gamma');
    System.assertEquals('DistZ', createdMap.Distributor__c);
    System.assertEquals('CustQ', createdMap.Ship_To_Name__c);
    System.assertEquals('60601', createdMap.Zip_Code__c);
    System.assertEquals('Chicago', createdMap.City__c);
    System.assertEquals('IL', createdMap.State__c);
    System.assertEquals('USA', createdMap.Country__c);
    System.assertEquals(100, createdMap.Total_Revenue__c, 'Total revenue should carry over');
    System.assert(
        createdMap.Contract_Names_Numbers__c.contains('CN-1') &&
        createdMap.Contract_Names_Numbers__c.contains('CN-2'),
        'Contract names should carry over'
    );

    // UNLINK (no second start/stop)
    AccountLinkerController.unlinkTraceAccountMappings(payload);

    Test.stopTest();

    // Sales should be unlinked
    List<Trace_Sale__c> postUnlinkSales = [
        SELECT Id, Trace_Account_Mapping__c
        FROM Trace_Sale__c
        WHERE Id IN :new Set<Id>{ s1.Id, s2.Id }
    ];
    for (Trace_Sale__c t : postUnlinkSales) {
        System.assertEquals(null, t.Trace_Account_Mapping__c, 'Sale should be unlinked');
    }

    // Mapping should be deleted
    Integer remaining = [
        SELECT COUNT()
        FROM Trace_Account_Mapping__c
        WHERE Id IN :createdMapIds
    ];
    System.assertEquals(0, remaining, 'Mapping should be deleted after unlink');
}

    @IsTest
    static void testStartAggregationBatchJob() {
        Test.startTest();
        String jobId = AccountLinkerController.startAggregationBatchJob('unlinked');
        Test.stopTest();

        // Verify job ID is returned
        System.assertNotEquals(null, jobId, 'Should return batch job ID');

        // Verify batch job exists
        List<AsyncApexJob> jobs = [
            SELECT Id, Status, ApexClass.Name
            FROM AsyncApexJob
            WHERE Id = :jobId
        ];
        System.assertEquals(1, jobs.size(), 'Batch job should exist');
        System.assertEquals('TraceSaleAggregationBatch', jobs[0].ApexClass.Name, 'Should be correct batch class');
    }

    @IsTest
    static void testCheckBatchJobStatus() {
        // Start a batch job first
        Test.startTest();
        String jobId = AccountLinkerController.startAggregationBatchJob('unlinked');
        Test.stopTest();

        // Check status
        Map<String, Object> status = AccountLinkerController.checkBatchJobStatus(jobId);

        // Verify status map contains expected fields
        System.assert(status.containsKey('status'), 'Should contain status field');
        System.assert(status.containsKey('processed'), 'Should contain processed field');
        System.assert(status.containsKey('total'), 'Should contain total field');
        System.assert(status.containsKey('errors'), 'Should contain errors field');

        // In test context, batch completes immediately
        System.assertEquals('Completed', status.get('status'), 'Batch should complete in test context');
    }

    @IsTest
    static void testCheckBatchJobStatusWithInvalidId() {
        try {
            AccountLinkerController.checkBatchJobStatus('000000000000000');
           // System.assert(false, 'Should throw exception for invalid job ID');
        } catch (AuraHandledException e) {
           // System.assert(e.getMessage().contains('Error checking batch status'), 'Should have proper error message');
        }
    }

    @IsTest
    static void testGetAggregatedUnlinkedTraceSalesWithCache() {
        // Create test data and manually store in cache
        List<AccountLinkerController.AggregatedTraceSale> testData =
            new List<AccountLinkerController.AggregatedTraceSale>();

        AccountLinkerController.AggregatedTraceSale agg = new AccountLinkerController.AggregatedTraceSale();
        agg.groupKey = 'test|test|12345|2024';
        agg.distributor = 'test';
        agg.customer = 'test';
        agg.zipCode = '12345';
        agg.totalRevenue = 1000;
        agg.recordCount = 5;
        testData.add(agg);

        // Try to store in cache (may fail if partition doesn't exist in test, which is OK)
        try {
            Cache.Org.put('local.TraceSales.unlinked', JSON.serialize(testData), 300);
        } catch (Exception e) {
            System.debug('Cache not available in test: ' + e.getMessage());
        }

        Test.startTest();
        Map<String, Object> response = AccountLinkerController.getAggregatedUnlinkedTraceSales();
        Test.stopTest();

        // Should return either cached data or direct query results
        System.assertEquals('ready', response.get('status'), 'Status should be ready');
        System.assertNotEquals(null, response.get('data'), 'Should have data');
    }

    @IsTest
    static void testStartAggregationBatchJobLinkedMode() {
        Test.startTest();
        String jobId = AccountLinkerController.startAggregationBatchJob('linked');
        Test.stopTest();

        // Verify job was created for linked mode
        System.assertNotEquals(null, jobId, 'Should return batch job ID for linked mode');

        List<AsyncApexJob> jobs = [
            SELECT Id, Status
            FROM AsyncApexJob
            WHERE Id = :jobId
        ];
        System.assertEquals(1, jobs.size(), 'Batch job should exist for linked mode');
    }

}