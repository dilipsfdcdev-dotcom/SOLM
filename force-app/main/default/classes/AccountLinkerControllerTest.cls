@IsTest
private class AccountLinkerControllerTest {

    @TestSetup
    static void setup() {
        // --- Accounts
        Account acme = new Account(Name = 'Acme Medical', Type = 'Customer');
        Account beta = new Account(Name = 'Beta Clinic', Type = 'Customer');
        insert new List<Account>{ acme, beta };

        // --- Unlinked Trace Sales (Trace_Account_Mapping__c == null)
        Date y2024 = Date.newInstance(2024, 5, 10);
        Date y2025 = Date.newInstance(2025, 3, 2);

        // Same Distributor/Customer/Zip/Year => should aggregate
        Trace_Sale__c tsU1 = new Trace_Sale__c(
            Distributor__c = 'DistX',
            Customer__c = 'CustY',
            Zip_Code__c = '10001',
            City__c = 'NYC',
            State__c = 'NY',
            Country__c = 'USA',
            Revenue_Net__c = 100,
            Contract_Name_Number__c = 'C-001',
            Distributor_Invoice_Date__c = y2024
        );
        Trace_Sale__c tsU2 = new Trace_Sale__c(
            Distributor__c = 'DistX',
            Customer__c = 'CustY',
            Zip_Code__c = '10001',
            City__c = 'NYC',
            State__c = 'NY',
            Country__c = 'USA',
            Revenue_Net__c = 250,
            Contract_Name_Number__c = 'C-002',
            Distributor_Invoice_Date__c = y2024
        );
        // Different year => separate group
        Trace_Sale__c tsU3 = new Trace_Sale__c(
            Distributor__c = 'DistX',
            Customer__c = 'CustY',
            Zip_Code__c = '10001',
            City__c = 'NYC',
            State__c = 'NY',
            Country__c = 'USA',
            Revenue_Net__c = 75,
            Contract_Name_Number__c = 'C-001', // duplicate contract id to test uniqueness
            Distributor_Invoice_Date__c = y2025
        );
        insert new List<Trace_Sale__c>{ tsU1, tsU2, tsU3 };

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
            Distributor_Invoice_Date__c = y2024,
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
            Distributor_Invoice_Date__c = y2024,
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
        List<AccountLinkerController.AggregatedTraceSale> aggs =
            AccountLinkerController.getAggregatedUnlinkedTraceSales();
        Test.stopTest();

        // We expect two groups: one for 2024 and one for 2025
        System.assertEquals(2, aggs.size(), 'Unlinked groups should be split by year');

        // Find the 2024 and 2025 groups
        AccountLinkerController.AggregatedTraceSale g2024 = null;
        AccountLinkerController.AggregatedTraceSale g2025 = null;
        for (AccountLinkerController.AggregatedTraceSale gItem : aggs) {
            if (gItem.timePeriod == '2024') g2024 = gItem;
            if (gItem.timePeriod == '2025') g2025 = gItem;
        }
        System.assertNotEquals(null, g2024, 'Expected 2024 group');
        System.assertNotEquals(null, g2025, 'Expected 2025 group');

        // 2024 group should sum 100 + 250 = 350 and include both contracts C-001, C-002 (unique)
        System.assertEquals(350, g2024.totalRevenue, '2024 revenue should sum');
        System.assert(
            g2024.contractNames.contains('C-001') && g2024.contractNames.contains('C-002'),
            '2024 group should have unique contract names C-001, C-002'
        );

        // 2025 group should be 75 and include only C-001
        System.assertEquals(75, g2025.totalRevenue, '2025 revenue should sum');
        System.assertEquals(true, g2025.contractNames.contains('C-001'), '2025 group should include C-001');
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

        System.assertNotEquals(null, g, 'Expected an aggregated group');
        System.assertEquals('2024', g.timePeriod, 'Linked group should be year 2024');
        System.assertEquals(30, g.totalRevenue, '10 + 20 = 30');
        System.assert(
            g.contractNames.contains('K-100') && g.contractNames.contains('K-101'),
            'Linked group should include both K-100 and K-101'
        );
    }

    @IsTest
static void testCreateAndUnlinkTraceAccountMappings() {
    // Create a fresh Account to link against (so we don’t disturb setup mappings)
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

}