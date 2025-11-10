@isTest
private class CustomLookupAccountCtrlTest {
 
    @isTest
    private static void searchTest(){
        Account acc = new TestHelper.AccountRecord()
            .asNACA()
            .setSAPCode('NACA-C0001')
            .save();

        List<Id> fixedResults = new List<Id>();
        fixedResults.add(acc.Id);

        Test.setFixedSearchResults(fixedResults);

        Test.startTest();
            List<LookupSearchResult> results = CustomLookupAccountCtrl.search('C0001', new List<Id>{});
        Test.stopTest();
        
        System.assert(results.size() > 0);
    }
}