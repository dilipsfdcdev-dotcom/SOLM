@isTest
private class OpportunityNewQuoteCtrlTest {

    @IsTest
    private static void saveQuoteForEMEATenderTest() {
        Account acc = new TestHelper.AccountRecord()
                .asEMEA()
                .setBillingCity('Chicago')
                .setBillingCountry('United States')
                .setBillingPostalCode('12345')
                .setBillingStreet('Street')
                .setShippingSameAsBilling()
                .save();

        Contact con = new TestHelper.ContactRecord()
                .setEmail('test123@gmail.com')
                .save();

        Product2 testProduct = new TestHelper.ProductRecord().save();
        Pricebook2 customPricebook = new TestHelper.PricebookRecord().save();

        Opportunity opp = new TestHelper.OpportunityRecord (
                'TEST-opp-123', acc.Id, Constants.opportunity.RECORD_TYPE_EMEA_TENDER_ID )
                .setPricebookId(customPricebook.Id)
                .save();

        List<Opportunity> opportunities = new List<Opportunity>();

        Opportunity oppLOT = new TestHelper.OpportunityRecord (
                'TEST-opp-LOT', acc.Id, Constants.opportunity.RECORD_TYPE_EMEA_TENDER_LOT_ID)
                .setParent(opp.Id)
                .setStage(Constants.opportunity.STAGE_PROSPECTING)
                .setPricebookId(customPricebook.Id)
                .opp;

        Opportunity oppLOTClosedLost = new TestHelper.OpportunityRecord (
                'TEST-opp-LOT-closed-lost', acc.Id, Constants.opportunity.RECORD_TYPE_EMEA_TENDER_LOT_ID)
                .setParent(opp.Id)
                .asClosedLost()
                .setPricebookId(customPricebook.Id)
                .opp;

        opportunities.add(oppLOT);
        opportunities.add(oppLOTClosedLost);
        insert opportunities;

        PricebookEntry pbe = new TestHelper.PricebookEntryRecord(customPricebook.Id, testProduct.Id).save();

        List<OpportunityLineItem> olis = new List<OpportunityLineItem>();
        olis.add(
            new TestHelper.OpportunityLineItemRecord(
                oppLOT.Id,
                pbe.Id,
                testProduct.Id, false
            ).oli
        );

        olis.add(
                new TestHelper.OpportunityLineItemRecord(
                        oppLOT.Id,
                        pbe.Id,
                        testProduct.Id, false
                ).oli
        );

        olis.add(
            new TestHelper.OpportunityLineItemRecord(
                oppLOT.Id,
                pbe.Id,
                testProduct.Id, true
            ).oli
        );

        olis.add(
                new TestHelper.OpportunityLineItemRecord(
                    oppLOTClosedLost.Id,
                    pbe.Id,
                    testProduct.Id, false
                ).oli
        );

        insert olis;

        Test.startTest();
        OpportunityNewQuoteCtrl.saveQuote(opp.id, new Quote(
                Bill_To_Account__c = acc.Id,
                Ship_To_Account__c = acc.Id,
                ContactId = con.Id,
                Email = con.Email
        ));
        Test.stopTest();

        Quote newQuote = getQuoteWithItems();

        System.assertEquals(2, newQuote.QuoteLineItems.size());
    }

    @IsTest
    private static void saveQuoteTest() {
        Account acc = new TestHelper.AccountRecord()
                            .asNACA()
                            .setBillingCity('Chicago')
                            .setBillingCountry('United States')
                            .setBillingPostalCode('12345')
                            .setBillingStreet('Street')
                            .setShippingSameAsBilling()
                            .save();

        Contact con = new TestHelper.ContactRecord()
                            .setEmail('test@gmail.com')
                            .save();

        Product2 testProduct = new TestHelper.ProductRecord().save();
        Pricebook2 customPricebook = new TestHelper.PricebookRecord().save();

        Opportunity opp = new TestHelper.OpportunityRecord(acc.Id)
                            .setPricebookId(customPricebook.Id)
                            .save();
                            
        new TestHelper.OpportunityLineItemRecord(
            opp.Id,
            new TestHelper.PricebookEntryRecord(customPricebook.Id, testProduct.Id).save().Id,
            testProduct.Id
        ).save();

        Test.startTest();
            OpportunityNewQuoteCtrl.saveQuote(opp.id, new Quote(
                Bill_To_Account__c = acc.Id,
                Ship_To_Account__c = acc.Id,
                ContactId = con.Id,
                Email = con.Email
            ));
        Test.stopTest();
        
        Quote newQuote = getQuoteWithItems();

        System.assertEquals(acc.Name, newQuote.BillingName);
        System.assertEquals(acc.Name, newQuote.ShippingName);
        System.assertEquals(acc.BillingCity, newQuote.BillingCity);
        System.assertEquals(acc.ShippingCity, newQuote.ShippingCity);
        System.assertEquals(con.Id, newQuote.ContactId);

        System.assertEquals(1, newQuote.QuoteLineItems.size());
    }

    @IsTest
    private static void getContactInfoTest() {
        Contact con = new TestHelper.ContactRecord()
                            .setEmail('test@gmail.com')
                            .save();
        
        Test.startTest();
        con = OpportunityNewQuoteCtrl.getContactInfo(con.Id);
        Test.stopTest();

        System.assertNotEquals(null, con);
    }

    private static Quote getQuoteWithItems(){
        return [SELECT Id, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry,
                    ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, ShippingCountry,
                    BillingName, ShippingName, ContactId, Email, Phone,
                (SELECT Id FROM QuoteLineItems) FROM Quote LIMIT 1];
    }
}