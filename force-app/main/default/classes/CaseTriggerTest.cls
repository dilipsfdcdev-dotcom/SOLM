@isTest
private class CaseTriggerTest {

    @testSetup
    static void setupData() {
        // Get Person Account RecordType
        RecordType personAccRt = [
            SELECT Id 
            FROM RecordType 
            WHERE SObjectType = 'Account' AND DeveloperName = 'PersonAccount' 
            LIMIT 1
        ];
        
        // Get Insujet Lead RecordType
        RecordType insujetLeadRt = [
            SELECT Id 
            FROM RecordType 
            WHERE SObjectType = 'Lead' AND DeveloperName = 'Insujet' 
            LIMIT 1
        ];
        
        // Create a Person Account with AccountSource = 'Insujet' and matching email
        Account acc = new Account(
            RecordTypeId = personAccRt.Id,
            LastName = 'Test Account',
            PersonEmail = 'execuser@example.com',
            AccountSource = 'Insujet'
        );
        insert acc;
        
        // Create a Lead with RecordType = Insujet and matching email
        Lead lead = new Lead(
            RecordTypeId = insujetLeadRt.Id,
            LastName = 'Test Lead',
            Company = 'Test Company',
            Email = 'leaduser@example.com',
            Status = 'Open - Not Contacted'
        );
        insert lead;
    }
    
    @isTest
    static void testHandleBeforeInsertWithAccountMatch() {
        Case c = new Case(
            Priority = 'Service Clients',
            Description = 'Sender Email: execuser@example.com'
        );

        Test.startTest();
        insert c;
        Test.stopTest();

    }

    @isTest
    static void testHandleBeforeInsertWithLeadMatch() {
        Case c = new Case(
            Priority = 'Service Clients',
            Description = 'Sender Email: leaduser@example.com'
        );

        Test.startTest();
        insert c;
        Test.stopTest();

        Case result = [SELECT AccountId, Lead__c, Type__c, SuppliedEmail FROM Case WHERE Id = :c.Id];
    }

    @isTest
    static void testHandleBeforeInsertNoMatch() {
        Case c = new Case(
            Priority = 'Service Clients',
            Description = 'Sender Email: unknown@example.com'
        );

        Test.startTest();
        insert c;
        Test.stopTest();

        Case result = [SELECT AccountId, Lead__c, Type__c, SuppliedEmail FROM Case WHERE Id = :c.Id];
        System.assertEquals(null, result.AccountId);
        System.assertEquals(null, result.Lead__c);
        System.assertEquals(null, result.Type__c);
        System.assertEquals('unknown@example.com', result.SuppliedEmail);
    }

    @isTest
    static void testHandleBeforeInsertWrongPriority() {
        Case c = new Case(
            Priority = 'Low',
            Description = 'Sender Email: execuser@example.com'
        );

        Test.startTest();
        insert c;
        Test.stopTest();

        Case result = [SELECT AccountId, Lead__c, Type__c, SuppliedEmail FROM Case WHERE Id = :c.Id];
        System.assertEquals(null, result.AccountId);
        System.assertEquals(null, result.Lead__c);
        System.assertEquals(null, result.Type__c);
        System.assertEquals(null, result.SuppliedEmail);
    }

    @isTest
    static void testHandleExecutiveFlagUpdateOnInsert() {
        Case c = new Case(
            Priority = 'Medium',
            SuppliedEmail = 'exec@test.com', // Ensure this is part of Label.Executive_Email_Addresses
            Origin = 'Web',
            Subject = 'Exec Insert Test'
        );

        Test.startTest();
        insert c;
        Test.stopTest();

        Case result = [SELECT Executive_Request__c, Urgent__c, Case_Priority__c FROM Case WHERE Id = :c.Id];
        // Cannot assert these if email is not in label
        System.assertEquals(true, result.Executive_Request__c);
        System.assertEquals(true, result.Urgent__c);
        System.assertEquals('Urgent', result.Case_Priority__c);
    }

    @isTest
    static void testHandleExecutiveFlagUpdateOnUpdate() {
        Case c = new Case(
            Priority = 'Medium',
            SuppliedEmail = 'regular@test.com',
            Origin = 'Web',
            Subject = 'Update Test'
        );

        insert c;

        c.SuppliedEmail = 'exec@test.com'; // Should be in Label.Executive_Email_Addresses

        Test.startTest();
        update c;
        Test.stopTest();

        Case result = [SELECT Executive_Request__c, Urgent__c, Case_Priority__c FROM Case WHERE Id = :c.Id];
        System.assertEquals(true, result.Executive_Request__c);
        System.assertEquals(true, result.Urgent__c);
        System.assertEquals('Urgent', result.Case_Priority__c);
    }

    @isTest
    static void testHandleExecutiveFlagNegativeCase() {
        Case c = new Case(
            Priority = 'Medium',
            SuppliedEmail = 'nonexec@test.com',
            Origin = 'Phone'
        );

        Test.startTest();
        insert c;
        Test.stopTest();

        Case result = [SELECT Executive_Request__c FROM Case WHERE Id = :c.Id];
        System.assertEquals(false, result.Executive_Request__c);
    }
}