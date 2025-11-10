@IsTest
private class QuoteLineItemTriggerHandlerTest {
	@IsTest
	static void createQlisHistoryTest() {
		Account acc = new TestHelper.AccountRecord()
				.asEMEA()
				.setBillingCity('Chicago')
				.setBillingCountry('United States')
				.setBillingPostalCode('12345')
				.setBillingStreet('Street')
				.setShippingSameAsBilling()
				.save();

		Product2 testProduct = new TestHelper.ProductRecord().save();
		Pricebook2 customPricebook = new TestHelper.PricebookRecord().save();
		PricebookEntry pbe = new TestHelper.PricebookEntryRecord(customPricebook.Id, testProduct.Id).save();

		Opportunity opp = new TestHelper.OpportunityRecord (
				'TEST-opportunity', acc.Id, Constants.opportunity.RECORD_TYPE_EMEA_TENDER_ID )
				.setPricebookId(customPricebook.Id)
				.save();

		Quote quote = new Quote(
				Name = 'Test quote',
				Bill_To_Account__c = acc.Id,
				Ship_To_Account__c = acc.Id,
				OpportunityId = opp.id
		);
		insert quote;

		QuoteLineItem quoteLineItem = new QuoteLineItem(
				QuoteId = quote.Id,
				PricebookEntryId = pbe.Id,
				Quantity = 1,
				UnitPrice = 0,
				Discount = 0
		);
		insert quoteLineItem;

		Test.startTest();
		quoteLineItem.Quantity = 2;
		quoteLineItem.UnitPrice = 3;
		update quoteLineItem;
		Test.stopTest();

		List<Quote_Line_Item_History__c> qlisHistory = getQlisHistory(quoteLineItem.Id);
		System.assertEquals(1, qlisHistory.size());
		System.assertEquals(1, qlisHistory.get(0).Quantity__c);
		System.assertEquals(0, qlisHistory.get(0).Sales_Price__c);
	}

	private static List<Quote_Line_Item_History__c> getQlisHistory(Id quoteLineItemId){
		return [
				SELECT Id, Quantity__c, Sales_Price__c
				FROM Quote_Line_Item_History__c
				WHERE Quote_Line_Item__c =: quoteLineItemId
		];
	}
}