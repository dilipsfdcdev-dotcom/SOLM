public with sharing class ChecklistViewerController {
    @AuraEnabled(cacheable=true)
    public static List<Checklist_Items__c> getChecklistItems(Id recordId, String objectName) {
        String objectLabel = getObjectLabel(objectName);
        return [
            SELECT Id, Checklist__c, IsActive__c, Related_To__c, Status__c
            FROM Checklist_Items__c
            WHERE IsActive__c = true
            AND Related_To__c = :objectLabel
			ORDER BY Order__c ASC
        ];
    }

    private static String getObjectLabel(String objectApiName) {
        Schema.SObjectType objType = Schema.getGlobalDescribe().get(objectApiName);
        return objType != null ? objType.getDescribe().getLabel() : null;
    }

	@AuraEnabled(cacheable=true)
    public static List<Checklist_Action__c> getCompletedChecklistActions(Id relatedRecordId) {
        return [
            SELECT Checklist_Item__c
            FROM Checklist_Action__c
            WHERE Case__c = :relatedRecordId
        ];
    }

	 @AuraEnabled
    public static void createChecklistAction(Id checklistItemId, Id relatedRecordId, String objectType) {
        Checklist_Action__c action = new Checklist_Action__c();
        action.Checklist_Item__c = checklistItemId;
        action.Action_Timestamp__c = DateTime.now();
        
        // Set related record lookup based on object type
         if (objectType == 'Case') {
            action.Case__c = relatedRecordId;
        }
        insert action;
    }
}