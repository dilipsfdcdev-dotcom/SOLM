public with sharing class MassDeleteLeadsController {
    @AuraEnabled
    public static void deleteSelectedLeads(List<Id> leadIds) {

        List<Form_Submission__c> childRecords = [
            SELECT Id 
            FROM Form_Submission__c 
            WHERE Lead__c IN :leadIds
        ];

        delete childRecords;

        // Step 2: Delete the Leads themselves
        delete [SELECT Id FROM Lead WHERE Id IN :leadIds];
    }
}