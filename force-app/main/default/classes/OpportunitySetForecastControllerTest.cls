@IsTest
private class OpportunitySetForecastControllerTest {
	private final static Integer EMEA_PRODUCT_QUANTITY = 3;
	private final static Integer NACA_PRODUCT_QUANTITY = 2;

	private final static String OPPORTUNITY_EMEA_NAME = 'Test-opp-emea';
	private final static String OPPORTUNITY_NACA_NAME = 'Test-opp-naca';

	private final static String PRODUCT_NAME = 'Test-OpportunitySetForecastController-product';
	private final static String ACCOUNT_NAME = 'Test-OpportunitySetForecastController-account';
	private final static String PRICEBOOK_NAME = 'Test-OpportunitySetForecastController-pricebook';

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
	}

	@IsTest
	static void saveForecastingTest() {
		Opportunity opp = getOpportunityByRecordType(Constants.opportunity.RECORD_TYPE_NACA_ID);
		OpportunityLineItem oppLineItem = getOppLineItemsByOpportunityId(opp.Id).get(0);

		List<OpportunityLineItemSchedule> schedules = getSchedulesByOppLineItemId(oppLineItem.Id);
		System.assertEquals(1, schedules.size());
		OpportunityLineItemSchedule schedule = schedules.get(0);

		Id accountId = getAccountByName(ACCOUNT_NAME).Id;
		Forecast_Product__c forecastProduct = getForecastProductByAccountAndProductNames(ACCOUNT_NAME, PRODUCT_NAME);

		SetForecastProductWrapper productWrapper = new SetForecastProductWrapper()
				.buildWithoutForecastProductData(oppLineItem, accountId, OpportunitySetForecastHandler.NACA_CASE_QUANTITY_FIELD, 'cases');
		productWrapper.forecastProductId = forecastProduct.Id;
		productWrapper.comment = 'test comment';
		productWrapper.fulfillment = productWrapper.FULFILLMENT_LOCAL_WAREHOUSE_COMBOBOX_VALUE;

		SetForecastScheduleWrapper scheduleWrapper1 = new SetForecastScheduleWrapper();
		scheduleWrapper1.scheduleId = schedule.Id;
		scheduleWrapper1.scheduleDate = schedule.ScheduleDate;
		scheduleWrapper1.quantity = 20;

		SetForecastScheduleWrapper scheduleWrapper2 = new SetForecastScheduleWrapper();
		scheduleWrapper2.scheduleDate = FORECAST_DATE.addMonths(1);
		scheduleWrapper2.quantity = 15;

		productWrapper.scheduleWrappers = new List<SetForecastScheduleWrapper>{scheduleWrapper1, scheduleWrapper2};
/*
		Test.startTest();
		OpportunitySetForecastController.saveForecasting(new List<SetForecastProductWrapper>{productWrapper}, 'NACA');
		Test.stopTest();

		List<Forecast_Opportunity__c> forecastOpportunities = getForecastOpportunitiesByFulfillmentAndOppLineItemId(oppLineItem.Id, Constants.forecastItem.FULFILLMENT_LOCAL);
		System.assertEquals(1, forecastOpportunities.size());
		Forecast_Opportunity__c forecastOpp = forecastOpportunities.get(0);
		System.assertEquals(productWrapper.comment, forecastOpp.Comment__c);
		System.assertEquals(Constants.forecastItem.FULFILLMENT_LOCAL, forecastOpp.Fulfillment__c);
		System.assertEquals(oppLineItem.Id, forecastOpp.Opportunity_Product__c);

		List<Forecast_Item__c> forecastItems = getForecastItemsByOpportunityForecastId(forecastOpp.Id);
		System.assertEquals(2, forecastItems.size());

		schedules = getSchedulesByOppLineItemId(oppLineItem.Id);
		System.assertEquals(2, schedules.size());*/
	}

	@IsTest
	static void filterAndUpdateProductWrappersByForecastProductsTest() {
		Opportunity opp = getOpportunityByRecordType(Constants.opportunity.RECORD_TYPE_NACA_ID);

		Product2 testProduct = new TestHelper.ProductRecord()
				.setName('Product without forecasting')
				.setNACAQuantity(NACA_PRODUCT_QUANTITY)
				.save();

		Pricebook2 customPricebook = getPricebookByName(PRICEBOOK_NAME);
		PricebookEntry pbe = new TestHelper.PricebookEntryRecord(customPricebook.Id, testProduct.Id).save();

		Forecast_Product__c forecastProduct = getForecastProductByAccountAndProductNames(ACCOUNT_NAME, PRODUCT_NAME);
		Id accountId = getAccountByName(ACCOUNT_NAME).Id;
		OpportunityLineItem oppLineItem = getOppLineItemsByOpportunityId(opp.Id).get(0);
		OpportunityLineItem oppLineItem2 = new TestHelper.OpportunityLineItemRecord(opp.Id, pbe.Id, testProduct.Id).save();

		SetForecastProductWrapper productWrapper1 = new SetForecastProductWrapper()
				.buildWithoutForecastProductData(oppLineItem, accountId, OpportunitySetForecastHandler.NACA_CASE_QUANTITY_FIELD, OpportunitySetForecastHandler.PIECES_VOLUME);

		SetForecastProductWrapper productWrapper2 = new SetForecastProductWrapper()
				.buildWithoutForecastProductData(oppLineItem2, accountId, OpportunitySetForecastHandler.NACA_CASE_QUANTITY_FIELD, OpportunitySetForecastHandler.PIECES_VOLUME);

		Map<Id,SetForecastProductWrapper> productWrappersByOlisIds = OpportunitySetForecastController.filterAndUpdateProductWrappersByForecastProducts(
				new List<Forecast_Product__c>{forecastProduct},
				new Map<Id,SetForecastProductWrapper>{oppLineItem.Id => productWrapper1, oppLineItem2.Id => productWrapper2}
		);

		System.assertEquals(1, productWrappersByOlisIds.size());
		System.assert(productWrappersByOlisIds.containsKey(oppLineItem.Id));
		SetForecastProductWrapper updatedProductWrapper = productWrappersByOlisIds.get(oppLineItem.Id);
		System.assertEquals(forecastProduct.Id, updatedProductWrapper.forecastProductId);
	}

	@IsTest
	static void buildResultWrapperTest() {
		Opportunity opp = getOpportunityByRecordType(Constants.opportunity.RECORD_TYPE_NACA_ID);
		OpportunitySetForecastController.ResultWrapper resultWrapper = OpportunitySetForecastController.getForecastingOpportunityDataToProcess(opp.Id);

		System.assertEquals('NACA', resultWrapper.recordType);
		System.assertEquals(1, resultWrapper.products.size());
	}

	private static Account getAccountByName(String accountName) {
		return [SELECT Id FROM Account WHERE Name = :accountName LIMIT 1];
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
				SELECT Id, Comment__c, Fulfillment__c, Opportunity_Product__c
				FROM Forecast_Opportunity__c
				WHERE Opportunity_Product__c = :oppLineItemId AND Fulfillment__c = :fulfillment
		];
	}

	private static Forecast_Product__c getForecastProductByAccountAndProductNames(String accName, String productName){
		return [
				SELECT Id, Direct_Enabled__c, Local_Enabled__c, Product__c, Account__c
				FROM Forecast_Product__c
				WHERE Account__r.Name = :accName
				AND Product__r.Name = :productName
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

	private static Pricebook2 getPricebookByName(String pricebookName) {
		return [SELECT Id FROM Pricebook2 WHERE Name = :pricebookName LIMIT 1];
	}

	private static List<OpportunityLineItemSchedule> getSchedulesByOppLineItemId(Id oppLineItemId) {
		return [SELECT Id, Quantity, ScheduleDate, OpportunityLineItemId FROM OpportunityLineItemSchedule WHERE OpportunityLineItemId = :oppLineItemId];
	}
}