@IsTest
public with sharing class CreateForecastMonthsBatchTest {
	private final static String PRODUCT_NAME = 'Test-CreateForecastMonthsBatch-product';
	private final static String ACCOUNT_NAME = 'Test-CreateForecastMonthsBatch-account';
	private final static Date MONTH = Date.today().toStartOfMonth().addYears(1).addMonths(-1);

	@TestSetup
	static void setup(){
		Account account = new TestHelper.AccountRecord()
				.setName(ACCOUNT_NAME)
				.setForecasting(true)
				.save();
		Product2 testProduct = new TestHelper.ProductRecord()
				.setName(PRODUCT_NAME)
				.save();

		Forecast_Product__c forecastProduct = new Forecast_Product__c(
			Account__c = account.Id, 
			Product__c = testProduct.Id,
			Direct_Enabled__c = true,
			Local_Enabled__c = true
		);

		insert forecastProduct;
	}

	@IsTest
	static void testBatchSuccess(){

		Test.startTest();
		CreateForecastMonthsBatch batch = new CreateForecastMonthsBatch();
		Database.executeBatch(batch, 1);
		Test.stopTest();

		List<Forecast_Month__c> forecastMonths = [SELECT Month__c FROM Forecast_Month__c];

		System.assertEquals(1, forecastMonths.size());
		System.assertEquals(MONTH, forecastMonths[0].Month__c);
	}
}