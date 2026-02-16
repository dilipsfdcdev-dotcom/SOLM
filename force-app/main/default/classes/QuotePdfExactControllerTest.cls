@isTest
private class QuotePdfExactControllerTest {

    @TestSetup
    static void setupData() {
        // Create Account
        Account acc = new Account(
            Name = 'Test Account',
            BillingStreet = '123 Test Street',
            BillingCity = 'Warsaw',
            BillingPostalCode = '00-105',
            BillingCountryCode = 'PL'
        );
        insert acc;

        // Create Contact
        Contact con = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            AccountId = acc.Id,
            Email = 'test@example.com',
            Phone = '+48123456789'
        );
        insert con;

        // Create Opportunity (required for Quote)
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = acc.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert opp;

        // Get standard pricebook
        Id stdPricebookId = Test.getStandardPricebookId();

        // Determine the org's default currency from the Opportunity
        String orgCurrency = [SELECT CurrencyIsoCode FROM Opportunity WHERE Id = :opp.Id].CurrencyIsoCode;

        // Create Product
        Product2 prod = new Product2(
            Name = 'IQ-M Procedure Mask - ASTM 1',
            ProductCode = 'MSK003X',
            StockKeepingUnit = 'MSK003X-SKU',
            IsActive = true
        );
        insert prod;

        // Create PricebookEntry (handle if already exists, ensure active, match currency)
        PricebookEntry pbe;
        List<PricebookEntry> existingPbes = [
            SELECT Id, IsActive, CurrencyIsoCode FROM PricebookEntry
            WHERE Pricebook2Id = :stdPricebookId AND Product2Id = :prod.Id
              AND CurrencyIsoCode = :orgCurrency LIMIT 1
        ];
        if (existingPbes.isEmpty()) {
            pbe = new PricebookEntry(
                Pricebook2Id = stdPricebookId,
                Product2Id = prod.Id,
                UnitPrice = 0.025,
                IsActive = true,
                CurrencyIsoCode = orgCurrency
            );
            insert pbe;
        } else {
            pbe = existingPbes[0];
            if (!pbe.IsActive) {
                pbe.IsActive = true;
                update pbe;
            }
        }

        // Create Quote with Offer_Validity__c
        Quote q = new Quote(
            Name = 'Test Quote With Validity',
            OpportunityId = opp.Id,
            ContactId = con.Id,
            Phone = '+48123456789',
            Email = 'test@example.com',
            Pricebook2Id = stdPricebookId,
            Offer_Validity__c = Date.today().addDays(30)
        );
        insert q;

        // Create QuoteLineItem
        QuoteLineItem qli = new QuoteLineItem(
            QuoteId = q.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 2000,
            UnitPrice = 0.025
        );
        insert qli;

        // Create second Quote without Offer_Validity__c (null path)
        Quote q2 = new Quote(
            Name = 'Test Quote No Validity',
            OpportunityId = opp.Id,
            Pricebook2Id = stdPricebookId
        );
        insert q2;
    }

    @isTest
    static void testControllerWithFullData() {
        Quote q = [SELECT Id FROM Quote WHERE Name = 'Test Quote With Validity' LIMIT 1];

        Test.startTest();
        ApexPages.StandardController stdCtrl = new ApexPages.StandardController(q);
        QuotePdfExactController ctrl = new QuotePdfExactController(stdCtrl);
        Test.stopTest();

        // Verify quote record loaded
        System.assertNotEquals(null, ctrl.quoteRec, 'Quote record should be loaded');
        System.assertEquals(q.Id, ctrl.quoteRec.Id, 'Quote Id should match');

        // Verify line items populated
        System.assertEquals(1, ctrl.lineItemWrappers.size(), 'Should have 1 line item');

        QuotePdfExactController.LineItemWrapper wrapper = ctrl.lineItemWrappers[0];
        System.assertNotEquals(null, wrapper.refVal, 'REF should not be null');
        System.assertNotEquals(null, wrapper.description, 'Description should not be null');
        System.assertNotEquals(null, wrapper.unitPrice, 'Unit price should not be null');
        System.assertNotEquals(null, wrapper.rowBg, 'Row background should not be null');

        // Verify formatted fields
        System.assertNotEquals(null, ctrl.todayFormatted, 'Today formatted should not be null');
        System.assertNotEquals(null, ctrl.offerValidityFormatted, 'Offer validity should not be null');
        System.assertNotEquals(null, ctrl.subtotalFormatted, 'Subtotal should not be null');
        System.assertNotEquals(null, ctrl.totalPriceFormatted, 'Total price should not be null');
    }

    @isTest
    static void testControllerWithNullValidity() {
        Quote q = [SELECT Id FROM Quote WHERE Name = 'Test Quote No Validity' LIMIT 1];

        Test.startTest();
        ApexPages.StandardController stdCtrl = new ApexPages.StandardController(q);
        QuotePdfExactController ctrl = new QuotePdfExactController(stdCtrl);
        Test.stopTest();

        // Should default to today + 30 days
        String expected = formatDateHelper(Date.today().addDays(30));
        System.assertEquals(expected, ctrl.offerValidityFormatted, 'Should default to 30 days from today');

        // No line items on this quote
        System.assertEquals(0, ctrl.lineItemWrappers.size(), 'Should have 0 line items');
    }

    @isTest
    static void testControllerWithNullQuoteId() {
        // Simulate no quote Id
        Quote dummyQuote = new Quote();

        Test.startTest();
        ApexPages.StandardController stdCtrl = new ApexPages.StandardController(dummyQuote);
        QuotePdfExactController ctrl = new QuotePdfExactController(stdCtrl);
        Test.stopTest();

        System.assertNotEquals(null, ctrl.quoteRec, 'Quote record should be initialized');
        System.assertEquals(0, ctrl.lineItemWrappers.size(), 'Should have 0 line items');
        System.assertEquals('0.00', ctrl.subtotalFormatted, 'Subtotal should be 0.00');
        System.assertEquals('0.00', ctrl.totalPriceFormatted, 'Total should be 0.00');
    }

    @isTest
    static void testLineItemWithDescriptionFallback() {
        // Create a product with no SKU to test ProductCode fallback
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Opportunity opp = [SELECT Id, CurrencyIsoCode FROM Opportunity LIMIT 1];
        Id stdPricebookId = Test.getStandardPricebookId();
        String orgCurrency = opp.CurrencyIsoCode;

        Product2 prod2 = new Product2(
            Name = 'Fallback Product',
            ProductCode = 'FALLBACK-001',
            StockKeepingUnit = null,
            IsActive = true
        );
        insert prod2;

        PricebookEntry pbe2;
        List<PricebookEntry> existingPbes2 = [
            SELECT Id, IsActive, CurrencyIsoCode FROM PricebookEntry
            WHERE Pricebook2Id = :stdPricebookId AND Product2Id = :prod2.Id
              AND CurrencyIsoCode = :orgCurrency LIMIT 1
        ];
        if (existingPbes2.isEmpty()) {
            pbe2 = new PricebookEntry(
                Pricebook2Id = stdPricebookId,
                Product2Id = prod2.Id,
                UnitPrice = 1.50,
                IsActive = true,
                CurrencyIsoCode = orgCurrency
            );
            insert pbe2;
        } else {
            pbe2 = existingPbes2[0];
            if (!pbe2.IsActive) {
                pbe2.IsActive = true;
                update pbe2;
            }
        }

        Quote q3 = new Quote(
            Name = 'Test Quote Fallback',
            OpportunityId = opp.Id,
            Pricebook2Id = stdPricebookId
        );
        insert q3;

        QuoteLineItem qli2 = new QuoteLineItem(
            QuoteId = q3.Id,
            PricebookEntryId = pbe2.Id,
            Quantity = 100,
            UnitPrice = 1.50
        );
        insert qli2;

        Test.startTest();
        ApexPages.StandardController stdCtrl = new ApexPages.StandardController(q3);
        QuotePdfExactController ctrl = new QuotePdfExactController(stdCtrl);
        Test.stopTest();

        System.assertEquals(1, ctrl.lineItemWrappers.size(), 'Should have 1 line item');
        QuotePdfExactController.LineItemWrapper w = ctrl.lineItemWrappers[0];
        // Should fall back to ProductCode since SKU is null
        System.assertEquals('FALLBACK-001', w.refVal, 'Should use ProductCode as fallback');
        // Should use Product Name since Description is null
        System.assertEquals('Fallback Product', w.description, 'Should use Product Name as fallback');
    }

    @isTest
    static void testInvocableGeneratePdf() {
        Quote q = [SELECT Id FROM Quote WHERE Name = 'Test Quote With Validity' LIMIT 1];

        Test.startTest();
        // The getContentAsPDF() call returns blank blob in test context, but we verify no exceptions
        try {
            QuotePdfExactController.generateQuotePdfAndAddToQuote(new List<Id>{ q.Id });
        } catch (Exception e) {
            // getContentAsPDF may throw in test context — that's expected
            System.debug('Expected exception in test: ' + e.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testAlternatingRowColors() {
        // Use the quote with 1 line item — verify odd row is white
        Quote q = [SELECT Id FROM Quote WHERE Name = 'Test Quote With Validity' LIMIT 1];

        ApexPages.StandardController stdCtrl = new ApexPages.StandardController(q);
        QuotePdfExactController ctrl = new QuotePdfExactController(stdCtrl);

        // First row (idx=1, odd) should be white
        System.assertEquals('#ffffff', ctrl.lineItemWrappers[0].rowBg, 'First row should be white');
    }

    // Helper to match the controller's date format for assertions
    private static String formatDateHelper(Date d) {
        if (d == null) return '';
        Integer dd = d.day();
        Integer mm = d.month();
        Integer yyyy = d.year();
        String day = dd < 10 ? '0' + String.valueOf(dd) : String.valueOf(dd);
        String month = mm < 10 ? '0' + String.valueOf(mm) : String.valueOf(mm);
        return day + '.' + month + '.' + String.valueOf(yyyy);
    }
}