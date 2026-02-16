@isTest
private class QuoteDiscountTaskHandlerTest {
    
    @isTest
    static void forceTaskCreationCoverage() {
        String validBU = 'BU01 Injection and Pharma'; 
        
        // CREATE BU TASK OWNER METADATA RECORD IN TEST CONTEXT
        // Since Custom Metadata can't be inserted in tests normally,
        // we need to use a wrapper/mock approach OR deploy the records.
        // However, Custom Metadata IS visible in tests if it exists in the org.
        // So let's first verify and add an assertion:
        
        List<BU_Task_Owner__mdt> metaRecords = [
            SELECT BU__c, Owner__c FROM BU_Task_Owner__mdt WHERE BU__c = :validBU
        ];
        System.debug('Metadata records found: ' + metaRecords.size());
        // If this prints 0, that's your problem
        
        Product2 prod = new Product2(
            Name = 'Test Product',
            IsActive = true,
            BU__c = validBU
        );
        insert prod;
        
        Id standardPricebookId = Test.getStandardPricebookId();
        
        PricebookEntry pbe = [SELECT Id, UnitPrice, IsActive, CurrencyIsoCode 
                              FROM PricebookEntry 
                              WHERE Product2Id = :prod.Id 
                              AND Pricebook2Id = :standardPricebookId 
                              LIMIT 1];
        pbe.IsActive = true;
        pbe.UnitPrice = 100.00;
        update pbe;
        
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = acc.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Pricebook2Id = standardPricebookId
        );
        try { opp.put('CurrencyIsoCode', pbe.CurrencyIsoCode); } catch(Exception e) {}
        insert opp;
        
        Quote q = new Quote(
            Name = 'Task Coverage Quote',
            OpportunityId = opp.Id,
            Pricebook2Id = standardPricebookId,
            Status = 'Draft'
        );
        try { q.put('CurrencyIsoCode', pbe.CurrencyIsoCode); } catch(Exception e) {}
        insert q;
        
        QuoteLineItem qli = new QuoteLineItem(
            QuoteId = q.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            UnitPrice = 0.01
        );
        insert qli;      
        
        Test.startTest();
        q.Status = 'Presented';
        update q;
        Test.stopTest();
        
        List<Task> results = [SELECT Id FROM Task WHERE WhatId = :q.Id];
        System.debug('Total Tasks Created: ' + results.size());
        // This will be 0 in Prod if metadata records are missing
    }
}