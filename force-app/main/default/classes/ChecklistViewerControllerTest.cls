@isTest
private class ChecklistViewerControllerTest {
    
    // Utility method to create a test Case
    private static Case createTestCase() {
        Case testCase = new Case(
            Subject = 'Test Case'
        );
        insert testCase;
        return testCase;
    }
    
    // Utility method to create test Checklist Items
    private static List<Checklist_Items__c> createTestChecklistItems(String objectLabel) {
        // Adjust fields as per your org’s configuration and required fields
        Checklist_Items__c item1 = new Checklist_Items__c(
            IsActive__c = true,
            Related_To__c = objectLabel,
            Status__c = 'New',
            Checklist__c = 'Test Checklist 1'
        );

        Checklist_Items__c item2 = new Checklist_Items__c(
            IsActive__c = true,
            Related_To__c = objectLabel,
            Status__c = 'New',
            Checklist__c = 'Test Checklist 2'
        );

        insert new List<Checklist_Items__c> { item1, item2 };
        return new List<Checklist_Items__c> { item1, item2 };
    }

    // Utility method to create test Checklist Actions
    private static Checklist_Action__c createTestChecklistAction(Id checklistItemId, Id caseId) {
        Checklist_Action__c action = new Checklist_Action__c(
            Checklist_Item__c = checklistItemId,
            Case__c = caseId,
            Action_Timestamp__c = DateTime.now()
        );
        insert action;
        return action;
    }

    @isTest
    static void testGetChecklistItems() {
        // Create a test Case (just to have a recordId; though it's not directly used in the WHERE clause)
        Case testCase = createTestCase();

        // The method retrieves object label from the API name.
        // For 'Case', the label is typically "Case" (in standard English orgs).
        // If your org is in a different language or has a different label, adjust accordingly.
        String objectApiName = 'Case';
        String caseLabel = Schema.getGlobalDescribe()
                                 .get(objectApiName)
                                 .getDescribe()
                                 .getLabel();
        
        // Create test checklist items related to the "Case" label
        List<Checklist_Items__c> items = createTestChecklistItems(caseLabel);
        
        // Call the method we want to test
        List<Checklist_Items__c> results = ChecklistViewerController.getChecklistItems(testCase.Id, objectApiName);
        
        // Assert that we got back the correct number of records
        System.assertEquals(2, results.size(), 'Expected two active checklist items for Cases.');
        
        // Further assertions can be made on fields, order, etc.
    }

    @isTest
    static void testGetChecklistItemsNoMatchingLabel() {
        // Create a test Case
        Case testCase = createTestCase();

        // Create test checklist items but with a label "Case"
        // (They will only match if objectLabel == 'Case')
        String objectApiName = 'Case';
        String caseLabel = Schema.getGlobalDescribe()
                                 .get(objectApiName)
                                 .getDescribe()
                                 .getLabel();
        createTestChecklistItems(caseLabel);
        
        // Call the method with an invalid object API name
        // so getObjectLabel will return null
        List<Checklist_Items__c> results = ChecklistViewerController.getChecklistItems(testCase.Id, 'NonExistentObject');
        
        // Expect 0 results because the label won't match
        System.assertEquals(0, results.size(), 'No items should be returned for a non-existent object label.');
    }
    
    @isTest
    static void testGetCompletedChecklistActions() {
        // Create a test Case
        Case testCase = createTestCase();
        
        // Create test Checklist Items (we just need one for demonstration)
        String objectApiName = 'Case';
        String caseLabel = Schema.getGlobalDescribe()
                                 .get(objectApiName)
                                 .getDescribe()
                                 .getLabel();
        List<Checklist_Items__c> items = createTestChecklistItems(caseLabel);
        
        // Create a test Checklist Action for the first Checklist Item
        Checklist_Action__c action = createTestChecklistAction(items[0].Id, testCase.Id);
        
        // Call the method we want to test
        List<Checklist_Action__c> completedActions = ChecklistViewerController.getCompletedChecklistActions(testCase.Id);
        
        // Assert we got back the newly inserted record
        System.assertEquals(1, completedActions.size(), 'Expected one completed checklist action.');
        System.assertEquals(items[0].Id, completedActions[0].Checklist_Item__c, 'Checklist item IDs should match.');
    }

    @isTest
    static void testCreateChecklistAction() {
        // Create a test Case
        Case testCase = createTestCase();

        // Create test Checklist Items
        String objectApiName = 'Case';
        String caseLabel = Schema.getGlobalDescribe()
                                 .get(objectApiName)
                                 .getDescribe()
                                 .getLabel();
        List<Checklist_Items__c> items = createTestChecklistItems(caseLabel);

        // Capture the current count of Checklist_Action__c
        Integer initialCount = [SELECT count() FROM Checklist_Action__c];
        
        // Call the createChecklistAction method
        ChecklistViewerController.createChecklistAction(
            items[0].Id,      // checklistItemId
            testCase.Id,      // relatedRecordId
            'Case'            // objectType
        );
        
        // Verify that a new Checklist_Action__c record was created
        Integer finalCount = [SELECT count() FROM Checklist_Action__c];
        System.assertEquals(initialCount + 1, finalCount, 'There should be exactly one new Checklist Action record created.');

        // Optionally, query back the newly created action and assert its fields
        Checklist_Action__c createdAction = [
            SELECT Id, Checklist_Item__c, Case__c, Action_Timestamp__c
            FROM Checklist_Action__c
            WHERE Checklist_Item__c = :items[0].Id
            AND Case__c = :testCase.Id
            LIMIT 1
        ];
        
        System.assertNotEquals(null, createdAction, 'The created Checklist_Action__c should not be null.');
        System.assertEquals(items[0].Id, createdAction.Checklist_Item__c, 'Checklist item ID should match.');
        System.assertEquals(testCase.Id, createdAction.Case__c, 'Case ID should match.');
        System.assertNotEquals(null, createdAction.Action_Timestamp__c, 'Action_Timestamp__c should not be null.');
    }

}