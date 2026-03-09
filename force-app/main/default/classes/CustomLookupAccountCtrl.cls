public with sharing class CustomLookupAccountCtrl {
    private static final Integer MAX_RESULTS = 5;
    private static final string ACC_ICON = 'standard:account';

    @AuraEnabled(cacheable=true scope='global')
    public static List<LookupSearchResult> search(String searchTerm, List<String> selectedIds) {
        searchTerm += '*';

        List<List<SObject>> searchResults = [
            FIND :searchTerm
            IN ALL FIELDS
            RETURNING
                Account(Id, Name, SAP_Code__c WHERE id NOT IN :selectedIds)
            LIMIT :MAX_RESULTS
        ];

        List<LookupSearchResult> results = new List<LookupSearchResult>();

        Account[] accounts = (List<Account>) searchResults[0];
        for (Account account : accounts) {
            String subtitle = account.SAP_Code__c == null ? 'Account' : 'Account • ' + account.SAP_Code__c;
            results.add(new LookupSearchResult(account.Id, 'Account', ACC_ICON, account.Name, subtitle));
        }
        
        results.sort();

        return results;
    }
}