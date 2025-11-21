@IsTest
private class OpportunitySetForecastHandlerTest {
	private final static Integer EMEA_PRODUCT_QUANTITY = 3;
	private final static Integer NACA_PRODUCT_QUANTITY = 2;

	private final static String OPPORTUNITY_EMEA_NAME = 'Test-opportunity-emea';
	private final static String OPPORTUNITY_NACA_NAME = 'Test-opportunity-naca';

	private final static String PRODUCT_NAME = 'Test-OpportunitySetForecastHandlerTest-product';
	private final static String ACCOUNT_NAME = 'Test-OpportunitySetForecastHandlerTest-account';
	private final static String PRICEBOOK_NAME = 'Test-OpportunitySetForecastHandlerTest-pricebook';

	private final static Date FORECAST_DATE = System.today();

	@TestSetup
	private static void setup() {
		Account account = new TestHelper.AccountRecord().setName(ACCOUNT_NAME).save();
		Product2 testProduct = new TestHelper.ProductRecord()
				.setName(PRODUCT_NAME)
				.setNACAQuantity(NACA_PRODUCT_QUANTITY)
				.setEMEAQuantity(EMEA_PRODUCT_QUANTITY)
				.enableQuantitySchedule()
				.save();
		Pricebook2 customPricebook = new TestHelper.PricebookRecord().setName(PRICEBOOK_NAME).save();
		PricebookEntry pbe = new TestHelper.PricebookEntryRecord(customPricebook.Id, testProduct.Id).save();

		Opportunity oppEMEA = new TestHelper.OpportunityRecord (
				OPPORTUNITY_EMEA_NAME, account.Id, Constants.opportunity.RECORD_TYPE_EMEA_ID )
				.setPricebookId(customPricebook.Id)
				.setStage(Constants.opportunity.STAGE_FORECASTING)
				.build();

		Opportunity oppNACA = new TestHelper.OpportunityRecord (
				OPPORTUNITY_NACA_NAME, account.Id, Constants.opportunity.RECORD_TYPE_NACA_ID )
				.setPricebookId(customPricebook.Id)
				.setStage(Constants.opportunity.STAGE_CLOSED_WON)
				.build();

		insert new List<Opportunity>{oppEMEA, oppNACA};

		OpportunityLineItem oppLineItemEMEA = new TestHelper.OpportunityLineItemRecord(
				oppEMEA.Id,
				pbe.Id,
				testProduct.Id
		).build();

		OpportunityLineItem oppLineItemNACA = new TestHelper.OpportunityLineItemRecord(
				oppNACA.Id,
				pbe.Id,
				testProduct.Id
		).build();

		insert new List<OpportunityLineItem>{oppLineItemEMEA, oppLineItemNACA};

		OpportunityLineItemSchedule schedule = new OpportunityLineItemSchedule(
				OpportunityLineItemId = oppLineItemNACA.Id,
				Quantity = 10,
				ScheduleDate = FORECAST_DATE,
				Type = 'Quantity'
		);
		insert schedule;

		Forecast_Product__c forecastProduct = new Forecast_Product__c(Account__c = account.Id, Product__c = testProduct.Id, Direct_Enabled__c = true, Local_Enabled__c = true);
		insert forecastProduct;

		Forecast_Month__c forecastMonth = new Forecast_Month__c(Month__c = FORECAST_DATE, Forecast_Product__c = forecastProduct.Id, External_Id__c = ForecastUtil.getForecastMonthExternalId(account.Id, testProduct.Id, FORECAST_DATE));
		insert forecastMonth;

		Forecast_Opportunity__c forecastOpportunity = new TestHelper.ForecastOpportunityRecord(oppLineItemNACA.Id, Constants.forecastItem.FULFILLMENT_DIRECT).save();

		new TestHelper.ForecastItemRecord(
				ForecastUtil.getOpportunityForecastItemExternalId(account.Id, testProduct.Id, FORECAST_DATE, Constants.forecastItem.FULFILLMENT_DIRECT, forecastOpportunity.Id),
				Constants.forecastItem.ITEM_TYPE_OPP_PRODUCT,
				10,
				forecastMonth.Id
		).setForecastOpportunityId(forecastOpportunity.Id)
				.setFulfillment(Constants.forecastItem.FULFILLMENT_DIRECT)
				.save();
	}

	@IsTest
	static void upsertAndConsolidateScheduleRecordsTest() {
		Opportunity opp = getOpportunityByRecordType(Constants.opportunity.RECORD_TYPE_NACA_ID);
		OpportunityLineItem oppLineItem = getOppLineItemsByOpportunityId(opp.Id).get(0);

		OpportunityLineItemSchedule schedule = new OpportunityLineItemSchedule(
				OpportunityLineItemId = oppLineItem.Id,
				Quantity = 11,
				ScheduleDate = FORECAST_DATE,
				Type = 'Quantity'
		);
		insert schedule;

		List<OpportunityLineItemSchedule> schedules = [SELECT Id FROM OpportunityLineItemSchedule];
		System.assertEquals(2, schedules.size());
		Id accountId = getAccountByName(ACCOUNT_NAME).Id;

		SetForecastProductWrapper productWrapper = new SetForecastProductWrapper()
				.buildWithoutForecastProductData(oppLineItem, accountId, OpportunitySetForecastHandler.NACA_CASE_QUANTITY_FIELD, OpportunitySetForecastHandler.CASES_VOLUME);

		SetForecastScheduleWrapper scheduleWrapper = new SetForecastScheduleWrapper();
		scheduleWrapper.scheduleId = schedule.Id;
		scheduleWrapper.scheduleDate = FORECAST_DATE;
		scheduleWrapper.quantity = 20;

		productWrapper.scheduleWrappers =  new List<SetForecastScheduleWrapper>{scheduleWrapper};

		Test.startTest();
		OpportunitySetForecastHandler.upsertAndConsolidateScheduleRecords(new List<SetForecastProductWrapper>{productWrapper}, 'NACA');
		Test.stopTest();

		schedules = getSchedulesByOppLineItemId(oppLineItem.Id);
		System.assertEquals(1, schedules.size());
		System.assertEquals(20, schedules.get(0).Quantity);
	}

	@IsTest
	static void upsertForecastOpportunityRecordsTest() {
		Opportunity opp = getOpportunityByRecordType(Constants.opportunity.RECORD_TYPE_NACA_ID);
		OpportunityLineItem oppLineItem = getOppLineItemsByOpportunityId(opp.Id).get(0);
		List<Forecast_Opportunity__c> forecastOpportunities = getForecastOpportunitiesByFulfillmentAndOppLineItemId(oppLineItem.Id, Constants.forecastItem.FULFILLMENT_DIRECT);
		System.assertEquals(1, forecastOpportunities.size());

		Id accountId = getAccountByName(ACCOUNT_NAME).Id;

		SetForecastProductWrapper productWrapper = new SetForecastProductWrapper()
				.buildWithoutForecastProductData(oppLineItem, accountId, OpportunitySetForecastHandler.NACA_CASE_QUANTITY_FIELD, OpportunitySetForecastHandler.CASES_VOLUME)
				.setForecastOpportunityData(forecastOpportunities.get(0).Id, 'test comment', Constants.forecastItem.FULFILLMENT_DIRECT);
		productWrapper.fulfillment = 'directShipment';
		productWrapper.comment = 'test comment';

		Test.startTest();
		Map<String,Forecast_Opportunity__c> forecastOppsByExternalIds = OpportunitySetForecastHandler.getForecastOpportunitiesByExternalIds(new List<SetForecastProductWrapper>{productWrapper});
		OpportunitySetForecastHandler.upsertForecastOpportunityRecords(forecastOppsByExternalIds);
		Test.stopTest();

		forecastOpportunities = getForecastOpportunitiesByFulfillmentAndOppLineItemId(oppLineItem.Id, Constants.forecastItem.FULFILLMENT_DIRECT);
		System.assertEquals(1, forecastOpportunities.size());
		System.assertEquals('test comment', forecastOpportunities.get(0).Comment__c);
	}

	@IsTest
	static void upsertForecastItemsTest() {
		List<Forecast_Item__c> forecastItems = [SELECT Id FROM Forecast_Item__c];
		System.assertEquals(1, forecastItems.size());

		Opportunity opp = getOpportunityByRecordType(Constants.opportunity.RECORD_TYPE_NACA_ID);
		OpportunityLineItem oppLineItem = getOppLineItemsByOpportunityId(opp.Id).get(0);
		OpportunityLineItemSchedule schedule = getSchedulesByOppLineItemId(oppLineItem.Id).get(0);

		Id accountId = getAccountByName(ACCOUNT_NAME).Id;
		Id productId = getProductByName(PRODUCT_NAME).Id;
		Forecast_Product__c forecastProduct = getForecastProductByAccountAndProduct(accountId, productId);

		List<Forecast_Opportunity__c> forecastOpportunities = getForecastOpportunitiesByFulfillmentAndOppLineItemId(oppLineItem.Id, Constants.forecastItem.FULFILLMENT_DIRECT);
		Forecast_Opportunity__c forecastOpportunity = forecastOpportunities.get(0);

		Map<String,Forecast_Opportunity__c> forecastOpportunitiesByExternalIds = new Map<String,Forecast_Opportunity__c> {forecastOpportunity.External_Id__c => forecastOpportunity};

		SetForecastProductWrapper productWrapper = new SetForecastProductWrapper()
				.buildWithoutForecastProductData(oppLineItem, accountId, OpportunitySetForecastHandler.NACA_CASE_QUANTITY_FIELD, OpportunitySetForecastHandler.PIECES_VOLUME)
				.setFulfillmentByForecastProduct(forecastProduct)
				.setForecastOpportunityData(forecastOpportunity.Id, 'test comment', Constants.forecastItem.FULFILLMENT_DIRECT);
		productWrapper.fulfillment = 'directShipment';

		SetForecastScheduleWrapper scheduleWrapper1 = new SetForecastScheduleWrapper();
		scheduleWrapper1.scheduleDate = schedule.ScheduleDate;
		scheduleWrapper1.quantity = 20;

		SetForecastScheduleWrapper scheduleWrapper2 = new SetForecastScheduleWrapper();
		scheduleWrapper2.scheduleDate = FORECAST_DATE.addMonths(1);
		scheduleWrapper2.quantity = 20;

		productWrapper.scheduleWrappers = new List<SetForecastScheduleWrapper>{scheduleWrapper1, scheduleWrapper2};

		List<SetForecastProductWrapper> productWrappers = new List<SetForecastProductWrapper>{productWrapper};
		/*OpportunitySetForecastHandler.upsertForecastMonths(productWrappers);
		Test.startTest();
		OpportunitySetForecastHandler.upsertForecastItems(productWrappers, forecastOpportunitiesByExternalIds);
		Test.stopTest();

		forecastItems = getForecastItemsByOpportunityForecastId(forecastOpportunity.Id);
		System.assertEquals(2, forecastItems.size());
		System.assertEquals(20, forecastItems.get(0).Quantity__c);*/
	}

	@IsTest
	static void countQuantityForScheduleTest() {
		System.assertEquals(100, OpportunitySetForecastHandler.countQuantityForSchedule(OpportunitySetForecastHandler.CASES_VOLUME, 100, 5, OpportunitySetForecastHandler.NACA_REGION));
		System.assertEquals(20, OpportunitySetForecastHandler.countQuantityForSchedule(OpportunitySetForecastHandler.PIECES_VOLUME, 100, 5, OpportunitySetForecastHandler.NACA_REGION));
		System.assertEquals(500, OpportunitySetForecastHandler.countQuantityForSchedule(OpportunitySetForecastHandler.CASES_VOLUME, 100, 5, OpportunitySetForecastHandler.EMEA_REGION));
		System.assertEquals(100, OpportunitySetForecastHandler.countQuantityForSchedule(OpportunitySetForecastHandler.PIECES_VOLUME, 100, 5, OpportunitySetForecastHandler.EMEA_REGION));
	}

	@IsTest
	static void changeQuantityVolumeToPiecesTest() {
		System.assertEquals(100, OpportunitySetForecastHandler.changeQuantityVolumeToPieces(OpportunitySetForecastHandler.CASES_VOLUME, 20, 5));
		System.assertEquals(20, OpportunitySetForecastHandler.changeQuantityVolumeToPieces(OpportunitySetForecastHandler.PIECES_VOLUME, 20, 5));
	}

	private static Account getAccountByName(String accountName) {
		return [SELECT Id FROM Account WHERE Name = :accountName LIMIT 1];
	}

	private static Product2 getProductByName(String productName) {
		return [SELECT Id FROM Product2 WHERE Name = :productName LIMIT 1];
	}

	private static List<Forecast_Item__c> getForecastItemsByOpportunityForecastId(Id oppForecastId) {
		return [
				SELECT Id, Item_Type__c, Quantity__c, Forecast_Opportunity__c, Forecast__c, Fulfillment__c, External_Id__c
				FROM Forecast_Item__c
				WHERE Forecast_Opportunity__c = :oppForecastId
		];
	}

	private static List<Forecast_Opportunity__c> getForecastOpportunitiesByFulfillmentAndOppLineItemId(Id oppLineItemId, String fulfillment) {
		return [
				SELECT Id, Comment__c, External_Id__c, Fulfillment__c, Opportunity_Product__c
				FROM Forecast_Opportunity__c
				WHERE Opportunity_Product__c = :oppLineItemId AND Fulfillment__c = :fulfillment
		];
	}

	private static Forecast_Product__c getForecastProductByAccountAndProduct(String accId, String productId){
		return [
				SELECT Id, Direct_Enabled__c, Local_Enabled__c
				FROM Forecast_Product__c
				WHERE Account__c = :accId
				AND Product__c = :productId
				LIMIT 1
		];
	}

	private static Opportunity getOpportunityByRecordType(Id recordTypeId) {
		return [SELECT Id FROM Opportunity WHERE RecordTypeId = :recordTypeId LIMIT 1];
	}

	private static List<OpportunityLineItem> getOppLineItemsByOpportunityId(Id oppId) {
		return [
				SELECT Id, Product2Id, Product2.Name, Product2.Product_Line__c, Product2.ProductCode, CurrencyIsoCode, Product2.NACA_Case_Qty__c, Product2.EMEA_Case_Qty__c
				FROM OpportunityLineItem
				WHERE OpportunityId = :oppId
		];
	}

	private static List<OpportunityLineItemSchedule> getSchedulesByOppLineItemId(Id oppLineItemId) {
		return [SELECT Id, Quantity, ScheduleDate, OpportunityLineItemId FROM OpportunityLineItemSchedule WHERE OpportunityLineItemId = :oppLineItemId];
	}
}