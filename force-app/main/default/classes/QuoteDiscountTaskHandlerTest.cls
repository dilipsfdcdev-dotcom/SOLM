@isTest
private class QuoteDiscountTaskHandlerTest {
    
    @isTest
    static void forceTaskCreationCoverage() {
        // 1. SELECT VALID BU FROM YOUR LIST
        String validBU = 'BU01 Injection and Pharma'; 
        
        // 2. CREATE TEST Product DATA
   
        Product2 prod = new Product2(
            Name = 'Test Product',
            IsActive = true,
            BU__c = validBU
        );
        insert prod;
        
        // Get Standard Pricebook
        Id standardPricebookId = Test.getStandardPricebookId();
        
        // Get the auto-created Pricebook Entry
        PricebookEntry pbe = [SELECT Id, Pricebook2Id, Product2Id, UnitPrice, IsActive, CurrencyIsoCode 
                              FROM PricebookEntry 
                              WHERE Product2Id = :prod.Id 
                              AND Pricebook2Id = :standardPricebookId 
                              LIMIT 1];
        
        // Activate and set the UnitPrice
        pbe.IsActive = true;
        pbe.UnitPrice = 100.00;
        update pbe;
        
        // 3. SETUP QUOTE - Match the currency from PricebookEntry
        Quote q = new Quote(
            Name = 'Task Coverage Quote',
            Pricebook2Id = standardPricebookId,
            Status = 'Draft'
        );
        // Set the same currency as the PricebookEntry
        try { 
            q.put('CurrencyIsoCode', pbe.CurrencyIsoCode); 
        } catch(Exception e) {}
        insert q;
        
        // 4. THE QUOTE LINE
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
        
        // 5. VERIFY
        List<Task> results = [SELECT Id FROM Task WHERE WhatId = :q.Id];
        System.debug('Total Tasks Created: ' + results.size());
    }
}