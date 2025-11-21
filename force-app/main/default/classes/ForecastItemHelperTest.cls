@IsTest
private class ForecastItemHelperTest {
	private final static Integer EMEA_PRODUCT_QUANTITY = 3;
	private final static Integer NACA_PRODUCT_QUANTITY = 2;
	private final static Integer ORDER_ITEM_QUANTITY = 4;
	private final static String PRODUCT_NAME = 'Test-ForecastItemHelper-product';
	private final static String ACCOUNT_NAME = 'Test-ForecastItemHelper-account';
	private final static String PRICEBOOK_NAME = 'Test-ForecastItemHelper-pricebook';
	private final static Date FORECAST_DATE = System.today();
	private final static Date PREVIOUS_YEAR_DATE = FORECAST_DATE.addYears(-1);
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

		OrderItem orderItemCurrent = new TestHelper.OrderItemRecord(testProduct.Id, order.Id, pbe.Id)
				.setQuantity(ORDER_ITEM_QUANTITY)
				.setShipmentDate(FORECAST_DATE)
				.save();

		new TestHelper.OrderItemRecord(testProduct.Id, order.Id, pbe.Id)
				.setQuantity(ORDER_ITEM_QUANTITY)
				.setShipmentDate(PREVIOUS_YEAR_DATE)
				.save();

		new TestHelper.OrderItemRecord(testProduct.Id, order.Id, pbe.Id)
				.setShipmentDate(IRRELEVANT_DATE)
				.save();

		Forecast_Product__c forecastProduct = new Forecast_Product__c(Account__c = account.Id, Product__c = testProduct.Id);
		insert forecastProduct;

		Forecast_Month__c forecastMonth = new Forecast_Month__c(Month__c = FORECAST_DATE, Forecast_Product__c = forecastProduct.Id, CurrencyIsoCode = 'PLN');
		insert forecastMonth;

		Forecast_Item__c forecastItem = new Forecast_Item__c(
				Order_Product__c = orderItemCurrent.Id,
				Forecast__c = forecastMonth.Id,
				CurrencyIsoCode = forecastMonth.CurrencyIsoCode,
				Quantity__c = EMEA_PRODUCT_QUANTITY,
				Item_Type__c = Constants.forecastItem.ITEM_TYPE_CURRENT_ORDER
		);
		insert forecastItem;
	}

	@IsTest
	static void isOrderItemDateConnectedToForecastItemTest() {
		Account account = getAccountByName(ACCOUNT_NAME);
		Product2 testProduct = getProductByName(PRODUCT_NAME);
		Pricebook2 customPricebook = getPricebookByName(PRICEBOOK_NAME);
		PricebookEntry pbe = getPricebookEntryByPricebookAndProduct(customPricebook.Id, testProduct.Id);

		OrderItem orderItemCurrent = getOrderItemByPricebookEntryAndShipmentDate(pbe.Id, FORECAST_DATE);
		OrderItem orderItemPreviousYear = getOrderItemByPricebookEntryAndShipmentDate(pbe.Id, PREVIOUS_YEAR_DATE);
		OrderItem orderItemUnrelated = getOrderItemByPricebookEntryAndShipmentDate(pbe.Id, IRRELEVANT_DATE);

		Forecast_Item__c forecastItem = getForecastItemByParameters(FORECAST_DATE, account.Id, testProduct.Id);

		System.assertEquals(true, ForecastItemHelper.isOrderItemDateConnectedToForecastItem(orderItemCurrent, forecastItem));
		System.assertEquals(true, ForecastItemHelper.isOrderItemDateConnectedToForecastItem(orderItemPreviousYear, forecastItem));
		System.assertEquals(false, ForecastItemHelper.isOrderItemDateConnectedToForecastItem(orderItemUnrelated, forecastItem));
	}

	@IsTest
	static void isOrderProductConnectedToForecastMonthTest() {
		Account account = getAccountByName(ACCOUNT_NAME);
		Product2 testProduct = getProductByName(PRODUCT_NAME);
		Pricebook2 customPricebook = getPricebookByName(PRICEBOOK_NAME);
		PricebookEntry pbe = getPricebookEntryByPricebookAndProduct(customPricebook.Id, testProduct.Id);

		OrderItem orderItemCurrent = getOrderItemByPricebookEntryAndShipmentDate(pbe.Id, FORECAST_DATE);
		OrderItem orderItemPreviousYear = getOrderItemByPricebookEntryAndShipmentDate(pbe.Id, PREVIOUS_YEAR_DATE);
		OrderItem orderItemUnrelated = getOrderItemByPricebookEntryAndShipmentDate(pbe.Id, IRRELEVANT_DATE);
		Forecast_Product__c forecastProduct = getForecastProductByParameters(account.Id, testProduct.Id);
		Forecast_Month__c forecastMonth = getForecastMonthByParameters(FORECAST_DATE, account.Id, testProduct.Id);

		System.assertEquals(true, ForecastItemHelper.isOrderProductConnectedToForecastMonth(orderItemCurrent, forecastMonth, forecastProduct));
		System.assertEquals(true, ForecastItemHelper.isOrderProductConnectedToForecastMonth(orderItemPreviousYear, forecastMonth, forecastProduct));
		System.assertEquals(false, ForecastItemHelper.isOrderProductConnectedToForecastMonth(orderItemUnrelated, forecastMonth, forecastProduct));

		forecastProduct.Product__c = TestUtility.getFakeId(Schema.Product2.getSObjectType());
		System.assertEquals(false, ForecastItemHelper.isOrderProductConnectedToForecastMonth(orderItemCurrent, forecastMonth, forecastProduct));

		Forecast_Product__c forecastProduct2 = forecastProduct.clone(false);
		forecastProduct2.Account__c = TestUtility.getFakeId(Schema.Account.getSObjectType());
		System.assertEquals(false, ForecastItemHelper.isOrderProductConnectedToForecastMonth(orderItemCurrent, forecastMonth, forecastProduct2));
	}

	@IsTest
	static void buildForecastItemTest() {
		Product2 testProduct = getProductByName(PRODUCT_NAME);
		Pricebook2 customPricebook = getPricebookByName(PRICEBOOK_NAME);
		PricebookEntry pbe = getPricebookEntryByPricebookAndProduct(customPricebook.Id, testProduct.Id);
		OrderItem orderItemCurrent = getOrderItemByPricebookEntryAndShipmentDate(pbe.Id, FORECAST_DATE);

		Forecast_Item__c forecastItem = ForecastItemHelper.buildForecastItem(orderItemCurrent, FORECAST_DATE, new Forecast_Item__c());
		System.assertEquals(orderItemCurrent.Id, forecastItem.Order_Product__c);
		System.assertEquals(Constants.forecastItem.ITEM_TYPE_CURRENT_ORDER, forecastItem.Item_Type__c);
		System.assertEquals(EMEA_PRODUCT_QUANTITY * ORDER_ITEM_QUANTITY, forecastItem.Quantity__c);
	}

	@IsTest
	static void buildNewForecastItemsTest() {
		Account account = getAccountByName(ACCOUNT_NAME);
		Product2 testProduct = getProductByName(PRODUCT_NAME);
		Pricebook2 customPricebook = getPricebookByName(PRICEBOOK_NAME);
		PricebookEntry pbe = getPricebookEntryByPricebookAndProduct(customPricebook.Id, testProduct.Id);

		List<OrderItem> orderItems = new List<OrderItem>();
		orderItems.add(getOrderItemByPricebookEntryAndShipmentDate(pbe.Id, FORECAST_DATE));
		orderItems.add(getOrderItemByPricebookEntryAndShipmentDate(pbe.Id, PREVIOUS_YEAR_DATE));
		orderItems.add(getOrderItemByPricebookEntryAndShipmentDate(pbe.Id, IRRELEVANT_DATE));

		Map<Id,Forecast_Product__c> forecastProductsByIds = new Map<Id,Forecast_Product__c>();
		Forecast_Product__c forecastProduct = getForecastProductByParameters(account.Id, testProduct.Id);
		forecastProductsByIds.put(forecastProduct.Id, forecastProduct);

		List<Forecast_Month__c> forecastMonths = new List<Forecast_Month__c>();
		forecastMonths.add(getForecastMonthByParameters(FORECAST_DATE, account.Id, testProduct.Id));

		List<Forecast_Item__c> forecastItems = ForecastItemHelper.buildNewForecastItems(forecastMonths, forecastProductsByIds, orderItems);

		System.assertEquals(2, forecastItems.size());
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

	private static Forecast_Item__c getForecastItemByParameters(Date monthDate, Id accountId, Id productId) {
		return [
				SELECT Id, Forecast__r.Month__c, Forecast__r.Forecast_Product__r.Account__c,
						Forecast__r.Forecast_Product__r.Product__c
				FROM Forecast_Item__c
				WHERE Forecast__r.Month__c = :monthDate
					AND Forecast__r.Forecast_Product__r.Account__c = :accountId
					AND Forecast__r.Forecast_Product__r.Product__c = :productId
				LIMIT 1
		];
	}

	private static Forecast_Month__c getForecastMonthByParameters(Date monthDate, Id accountId, Id productId) {
		return [
				SELECT Id, CurrencyIsoCode, Month__c, Forecast_Product__r.Account__c, Forecast_Product__r.Product__c
				FROM Forecast_Month__c
				WHERE Month__c = :monthDate
					AND Forecast_Product__r.Account__c = :accountId
					AND Forecast_Product__r.Product__c = :productId
				LIMIT 1
		];
	}

	private static Forecast_Product__c getForecastProductByParameters(Id accountId, Id productId) {
		return [
				SELECT Id, Account__c, Product__c
				FROM Forecast_Product__c
				WHERE Account__c = :accountId AND Product__c = :productId
				LIMIT 1
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