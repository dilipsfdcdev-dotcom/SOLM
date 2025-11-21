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
}