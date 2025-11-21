@IsTest
private class ForecastMonthTriggerHelperTest {
	private final static Integer EMEA_PRODUCT_QUANTITY = 3;
	private final static Integer NACA_PRODUCT_QUANTITY = 2;
	private final static Integer ORDER_ITEM_QUANTITY = 9;
	private final static String PRODUCT_NAME = 'Test-forecasting-product';
	private final static String ACCOUNT_NAME = 'Test-forecasting-account';

	@testSetup
	private static void setup() {
		new TestHelper.AccountRecord().setName(ACCOUNT_NAME).save();
		new TestHelper.ProductRecord()
				.setName(PRODUCT_NAME)
				.setNACAQuantity(NACA_PRODUCT_QUANTITY)
				.setEMEAQuantity(EMEA_PRODUCT_QUANTITY)
				.save();
	}

	@IsTest
	static void setExternalIdsTest() {
		Account account = getAccountByName(ACCOUNT_NAME);
		Product2 testProduct = getProductByName(PRODUCT_NAME);

		Forecast_Product__c forecastProduct = new Forecast_Product__c(Account__c = account.Id, Product__c = testProduct.Id);
		insert forecastProduct;

		Test.startTest();
		Forecast_Month__c forecastMonth = new Forecast_Month__c(Month__c = System.today(), Forecast_Product__c = forecastProduct.Id);
		insert forecastMonth;
		Test.stopTest();

		forecastMonth = [SELECT Id, External_ID__c FROM Forecast_Month__c WHERE Id = :forecastMonth.Id LIMIT 1];
		//System.assertEquals(account.Id  + '-' + testProduct.Id + '-' +  ForecastUtil.getMonthUniqueId(System.today()), forecastMonth.External_ID__c);
	}

	@IsTest
	static void createForecastItemsEMEACurrentOrderTest() {
		Account account = getAccountByName(ACCOUNT_NAME);
		Product2 testProduct = getProductByName(PRODUCT_NAME);
		Pricebook2 customPricebook = new TestHelper.PricebookRecord().save();
		PricebookEntry pbe = new TestHelper.PricebookEntryRecord(customPricebook.Id, testProduct.Id).save();

		Order order = new TestHelper.OrderRecord(account.Id, Constants.order.RECORD_TYPE_EMEA_ID)
				.setPricebookId(customPricebook.Id).save();

		new TestHelper.OrderItemRecord(testProduct.Id, order.Id, pbe.Id)
				.setQuantity(ORDER_ITEM_QUANTITY)
				.setShipmentDate(System.today())
				.save();

		new TestHelper.OrderItemRecord(testProduct.Id, order.Id, pbe.Id)
				.setQuantity(ORDER_ITEM_QUANTITY)
				.setShipmentDate(System.today().addDays(-40))
				.save();

		Forecast_Product__c forecastProduct = new Forecast_Product__c(Account__c = account.Id, Product__c = testProduct.Id);
		insert forecastProduct;

		Test.startTest();
		Forecast_Month__c forecastMonth = new Forecast_Month__c(Month__c = System.today(), Forecast_Product__c = forecastProduct.Id);
		insert forecastMonth;
		Test.stopTest();

		List<Forecast_Item__c> forecastItems = getForecastItemsByForecastMonthId(forecastMonth.Id);

		//System.assertEquals(1, forecastItems.size());
		//System.assertEquals(ORDER_ITEM_QUANTITY * EMEA_PRODUCT_QUANTITY, forecastItems.get(0).Quantity__c);
		//System.assertEquals(Constants.forecastItem.ITEM_TYPE_CURRENT_ORDER, forecastItems.get(0).Item_Type__c);
	}

	@IsTest
	static void createForecastItemsNACAPreviousYearTest() {
		Account account = getAccountByName(ACCOUNT_NAME);
		Product2 testProduct = getProductByName(PRODUCT_NAME);
		Pricebook2 customPricebook = new TestHelper.PricebookRecord().save();
		PricebookEntry pbe = new TestHelper.PricebookEntryRecord(customPricebook.Id, testProduct.Id).save();

		Order order = new TestHelper.OrderRecord(account.Id, Constants.order.RECORD_TYPE_NACA_ID)
				.setPricebookId(customPricebook.Id).save();

		new TestHelper.OrderItemRecord(testProduct.Id, order.Id, pbe.Id)
				.setQuantity(ORDER_ITEM_QUANTITY)
				.setShipmentDate(System.today().addYears(-1))
				.save();

		new TestHelper.OrderItemRecord(testProduct.Id, order.Id, pbe.Id)
				.setQuantity(ORDER_ITEM_QUANTITY)
				.setShipmentDate(System.today().addDays(-40))
				.save();

		Forecast_Product__c forecastProduct = new Forecast_Product__c(Account__c = account.Id, Product__c = testProduct.Id);
		insert forecastProduct;

		Test.startTest();
			Forecast_Month__c forecastMonth = new Forecast_Month__c(Month__c = System.today(), Forecast_Product__c = forecastProduct.Id);
			insert forecastMonth;
		Test.stopTest();

		List<Forecast_Item__c> forecastItems = getForecastItemsByForecastMonthId(forecastMonth.Id);

		//System.assertEquals(1, forecastItems.size());
		//System.assertEquals(ORDER_ITEM_QUANTITY * NACA_PRODUCT_QUANTITY, forecastItems.get(0).Quantity__c);
		//System.assertEquals(Constants.forecastItem.ITEM_TYPE_PREVIOUS_YEAR_ORDER, forecastItems.get(0).Item_Type__c);
	}

	private static Account getAccountByName(String accountName) {
		return [SELECT Id FROM Account WHERE Name = :accountName LIMIT 1];
	}

	private static Product2 getProductByName(String productName) {
		return [SELECT Id FROM Product2 WHERE Name = :productName LIMIT 1];
	}

	private static List<Forecast_Item__c> getForecastItemsByForecastMonthId(Id forecastMonthId) {
		return [
			SELECT Id, Forecast__c, Quantity__c, Item_Type__c
			FROM Forecast_Item__c
			WHERE Forecast__c = :forecastMonthId
		];
	}

	private static Forecast_Month__c getForecastMonthById(Id forecastMonthId) {
		return [SELECT Id, External_ID__c FROM Forecast_Month__c WHERE Id = :forecastMonthId LIMIT 1];
	}
}