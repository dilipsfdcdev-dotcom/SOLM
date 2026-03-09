public with sharing class OpportunityNewLOTCtrl {
    @AuraEnabled
    public static string saveLOT(Opportunity lot) {
        try {
            insert lot;
            return lot.Id;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}