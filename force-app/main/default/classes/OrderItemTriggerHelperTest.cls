@IsTest
private class OrderItemTriggerHelperTest {
	private final static Integer EMEA_PRODUCT_QUANTITY = 3;
	private final static Integer NACA_PRODUCT_QUANTITY = 2;
	private final static Integer ORDER_ITEM_QUANTITY = 4;
	private final static String PRODUCT_NAME = 'Test-OrderItemTriggerHelper-product';
	private final static String ACCOUNT_NAME = 'Test-OrderItemTriggerHelper-account';
	private final static String PRICEBOOK_NAME = 'Test-OrderItemTriggerHelper-pricebook';
	private final static Date FORECAST_DATE = System.today();
	private final static Date IRRELEVANT_DATE = FORECAST_DATE.addDays(40);

	@TestSetup
	private static void setup() {
		Account account = new TestHelper.AccountRecord().setName(ACCOUNT_NAME).save();
		Product2 testProduct = new TestHelper.ProductRecord()
				.setName(PRODUCT_NAME)
				.setNACAQuantity(NACA_PRODUCT_QUANTITY)
				.setEMEAQuantity(EMEA_PRODUCT_QUANTITY)
				.save();
		Pricebook2 customPricebook = new TestHelper.PricebookRecord().setName(PRICEBOOK_NAME).save();
		PricebookEntry pbe = new TestHelper.PricebookEntryRecord(customPricebook.Id, testProduct.Id).save();
		Order order = new TestHelper.OrderRecord(account.Id, Constants.order.RECORD_TYPE_EMEA_ID)
				.setPricebookId(customPricebook.Id).save();

		new TestHelper.OrderItemRecord(testProduct.Id, order.Id, pbe.Id)
				.setQuantity(ORDER_ITEM_QUANTITY)
				.setShipmentDate(FORECAST_DATE)
				.save();

		new TestHelper.OrderItemRecord(testProduct.Id, order.Id, pbe.Id)
				.setShipmentDate(IRRELEVANT_DATE)
				.save();

		Forecast_Product__c forecastProduct = new Forecast_Product__c(Account__c = account.Id, Product__c = testProduct.Id);
		insert forecastProduct;

		// after inserting forecastMonth, forecastItems for orderItems are created
		Forecast_Month__c forecastMonth = new Forecast_Month__c(Month__c = FORECAST_DATE, Forecast_Product__c = forecastProduct.Id, CurrencyIsoCode = 'PLN');
		insert forecastMonth;
	}

	@IsTest
	static void createForecastsItemsTest() {
		Account account = getAccountByName(ACCOUNT_NAME);
		Product2 testProduct = getProductByName(PRODUCT_NAME);
		Pricebook2 customPricebook = getPricebookByName(PRICEBOOK_NAME);
		PricebookEntry pbe = getPricebookEntryByPricebookAndProduct(customPricebook.Id, testProduct.Id);

		Order order = new TestHelper.OrderRecord(account.Id, Constants.order.RECORD_TYPE_NACA_ID)
				.setPricebookId(customPricebook.Id).save();

		Test.startTest();
		OrderItem orderItem = new TestHelper.OrderItemRecord(testProduct.Id, order.Id, pbe.Id).setQuantity(ORDER_ITEM_QUANTITY)
				.setShipmentDate(FORECAST_DATE)
				.save();
		Test.stopTest();

		List<Forecast_Item__c> forecastItems = getForecastItemsByOrderItemId(orderItem.Id);
		System.assertEquals(1, forecastItems?.size());
		System.assertEquals(ORDER_ITEM_QUANTITY * NACA_PRODUCT_QUANTITY, forecastItems.get(0).Quantity__c);
		System.assertEquals(Constants.forecastItem.ITEM_TYPE_CURRENT_ORDER, forecastItems.get(0).Item_Type__c);
	}

	@IsTest
	static void uploadForecastsItemsShipmentDateToNotMatchForecastMonthTest() {
		Product2 testProduct = getProductByName(PRODUCT_NAME);
		Pricebook2 customPricebook = getPricebookByName(PRICEBOOK_NAME);
		PricebookEntry pbe = getPricebookEntryByPricebookAndProduct(customPricebook.Id, testProduct.Id);

		OrderItem orderItem = getOrderItemByPricebookEntryAndShipmentDate(pbe.Id, FORECAST_DATE);
		List<Forecast_Item__c> forecastItems = getForecastItemsByOrderItemId(orderItem.Id);
		System.assertEquals(1, forecastItems?.size());
		Id forecastItemId = forecastItems.get(0).Id;

		Test.startTest();
		orderItem.Shipment_Date__c = IRRELEVANT_DATE;
		update orderItem;
		Test.stopTest();

		System.assertEquals(0, getForecastItemsByOrderItemId(orderItem.Id)?.size());
		System.assertEquals(0, [SELECT Id FROM Forecast_Item__c WHERE Id = :forecastItemId]?.size());
	}

	@IsTest
	static void uploadForecastsItemsShipmentDateToMatchForecastMonthTest() {
		Product2 testProduct = getProductByName(PRODUCT_NAME);
		Pricebook2 customPricebook = getPricebookByName(PRICEBOOK_NAME);
		PricebookEntry pbe = getPricebookEntryByPricebookAndProduct(customPricebook.Id, testProduct.Id);

		OrderItem orderItem = getOrderItemByPricebookEntryAndShipmentDate(pbe.Id, IRRELEVANT_DATE);
		System.assertEquals(0, getForecastItemsByOrderItemId(orderItem.Id)?.size());

		Test.startTest();
		orderItem.Quantity = ORDER_ITEM_QUANTITY + 1;
		orderItem.Shipment_Date__c = FORECAST_DATE;
		update orderItem;
		Test.stopTest();

		List<Forecast_Item__c> forecastItems = getForecastItemsByOrderItemId(orderItem.Id);
		System.assertEquals(1, forecastItems?.size());
		System.assertEquals((ORDER_ITEM_QUANTITY + 1) * EMEA_PRODUCT_QUANTITY, forecastItems.get(0).Quantity__c);
	}

	@IsTest
	static void uploadForecastsItemsChangeJustQuantityTest() {
		Product2 testProduct = getProductByName(PRODUCT_NAME);
		Pricebook2 customPricebook = getPricebookByName(PRICEBOOK_NAME);
		PricebookEntry pbe = getPricebookEntryByPricebookAndProduct(customPricebook.Id, testProduct.Id);

		OrderItem orderItem = getOrderItemByPricebookEntryAndShipmentDate(pbe.Id, FORECAST_DATE);
		List<Forecast_Item__c> forecastItems = getForecastItemsByOrderItemId(orderItem.Id);
		System.assertEquals(1, forecastItems?.size());
		System.assertEquals(EMEA_PRODUCT_QUANTITY * ORDER_ITEM_QUANTITY, forecastItems.get(0).Quantity__c);

		Test.startTest();
		orderItem.Quantity = ORDER_ITEM_QUANTITY + 1;
		update orderItem;
		Test.stopTest();

		forecastItems = getForecastItemsByOrderItemId(orderItem.Id);
		System.assertEquals(1, forecastItems?.size());
		System.assertEquals((ORDER_ITEM_QUANTITY + 1) * EMEA_PRODUCT_QUANTITY, forecastItems.get(0).Quantity__c);
	}

	@IsTest
	static void removeForecastsItemsTest() {
		Product2 testProduct = getProductByName(PRODUCT_NAME);
		Pricebook2 customPricebook = getPricebookByName(PRICEBOOK_NAME);
		PricebookEntry pbe = getPricebookEntryByPricebookAndProduct(customPricebook.Id, testProduct.Id);

		OrderItem orderItem = getOrderItemByPricebookEntryAndShipmentDate(pbe.Id, FORECAST_DATE);
		System.assertNotEquals(0, getForecastItemsByOrderItemId(orderItem.Id)?.size());

		Test.startTest();
		delete orderItem;
		Test.stopTest();

		System.assertEquals(0, getForecastItemsByOrderItemId(orderItem.Id)?.size());
	}

	private static Account getAccountByName(String accountName) {
		return [SELECT Id FROM Account WHERE Name = :accountName LIMIT 1];
	}

	private static Product2 getProductByName(String productName) {
		return [SELECT Id FROM Product2 WHERE Name = :productName LIMIT 1];
	}

	private static Pricebook2 getPricebookByName(String pricebookName) {
		return [SELECT Id FROM Pricebook2 WHERE Name = :pricebookName LIMIT 1];
	}

	private static PricebookEntry getPricebookEntryByPricebookAndProduct(Id pricebookId, Id productId) {
		return [
				SELECT Id
				FROM PricebookEntry
				WHERE Pricebook2Id = :pricebookId AND Product2Id = :productId
				LIMIT 1
		];
	}

	private static List<Forecast_Item__c> getForecastItemsByOrderItemId(Id orderItemId) {
		return [
				SELECT Id, Item_Type__c, Quantity__c, Order_Product__c
				FROM Forecast_Item__c
				WHERE Order_Product__c = :orderItemId
		];
	}

	private static OrderItem getOrderItemByPricebookEntryAndShipmentDate(Id pricebookEntryId, Date shipmentDate) {
		return [
				SELECT Id, Quantity, PricebookEntryId, Product2Id, Shipment_Date__c, Order.AccountId,
						Order.RecordType.DeveloperName, Product2.NACA_Case_Qty__c, Product2.EMEA_Case_Qty__c
				FROM OrderItem
				WHERE PricebookEntryId = :pricebookEntryId AND Shipment_Date__c = :shipmentDate
				LIMIT 1
		];
	}
}