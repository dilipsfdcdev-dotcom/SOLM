@IsTest
private class QuoteToOrderCtrlTest {

    @IsTest
    private static void generateOrderTest() {
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

        Id quoteId = OpportunityNewQuoteCtrl.saveQuote(opp.id, new Quote(
            Bill_To_Account__c = acc.Id,
            Ship_To_Account__c = acc.Id,
            ContactId = con.Id,
            Email = con.Email
        ));

        Test.startTest();
            QuoteToOrderCtrl.generateOrder(quoteId);
        Test.stopTest();

        Order newOrder = getOrderWithItems();

        System.assertEquals(acc.Id, newOrder.AccountId);
        System.assertEquals(opp.Id, newOrder.OpportunityId);
        System.assertEquals(quoteId, newOrder.QuoteId);
        System.assertEquals(Constants.order.STATUS_OPEN, newOrder.Status);

        System.assertEquals(1, newOrder.OrderItems.size());
    }

    private static Order getOrderWithItems() {
        return [SELECT Id, AccountId, QuoteId, OpportunityId, Status,
            (SELECT Id FROM OrderItems) FROM Order LIMIT 1
        ];
    }
}