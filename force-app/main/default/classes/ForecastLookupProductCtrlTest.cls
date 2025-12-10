@isTest
private class ForecastLookupProductCtrlTest {

    @isTest
    private static void searchTest(){
        Account acc = new TestHelper.AccountRecord()
            .asNACA()
            .setSAPCode('NACA-C0001')
            .save();

        Product2 product = new TestHelper.ProductRecord()
            .setName('Lookup Test')
            .setNACAQuantity(100)
            .save();

        List<Id> fixedResults = new List<Id>();
        fixedResults.add(product.Id);

        Test.setFixedSearchResults(fixedResults);

        Test.startTest();
            List<LookupSearchResult> results = ForecastLookupProductCtrl.search('Lookup', new List<Id>{}, acc.Id);
        Test.stopTest();

        System.assert(results.size() > 0);
    }

    @isTest
    private static void searchProductsTest(){
        Product2 product = new TestHelper.ProductRecord()
            .setName('SearchProducts Test')
            .setNACAQuantity(100)
            .setProductCode('SP-TEST')
            .save();

        List<Id> fixedResults = new List<Id>();
        fixedResults.add(product.Id);

        Test.setFixedSearchResults(fixedResults);

        Test.startTest();
            List<LookupSearchResult> results = ForecastLookupProductCtrl.searchProducts('SearchProducts', new List<Id>{});
        Test.stopTest();

        System.assert(results.size() > 0);
    }

    @isTest
    private static void searchWithEMEAQuantityTest(){
        Account acc = new TestHelper.AccountRecord()
            .asNACA()
            .setSAPCode('NACA-C0002')
            .save();

        Product2 product = new TestHelper.ProductRecord()
            .setName('EMEA Lookup Test')
            .setEMEAQuantity(50)
            .save();

        List<Id> fixedResults = new List<Id>();
        fixedResults.add(product.Id);

        Test.setFixedSearchResults(fixedResults);

        Test.startTest();
            List<LookupSearchResult> results = ForecastLookupProductCtrl.search('EMEA', new List<Id>{}, acc.Id);
        Test.stopTest();

        System.assert(results.size() > 0);
    }
}