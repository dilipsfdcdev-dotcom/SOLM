@IsTest
private class SetForecastProductWrapperTest {
	@IsTest
	static void setFulfillmentByForecastProductTest() {
		Forecast_Product__c forecastProduct = new Forecast_Product__c(
				Account__c = TestUtility.getFakeId(Schema.Account.getSObjectType()),
				Product__c = TestUtility.getFakeId(Schema.Product2.getSObjectType()),
				Local_Enabled__c = true,
				Direct_Enabled__c = true
		);

		SetForecastProductWrapper productWrapper = new SetForecastProductWrapper().setFulfillmentByForecastProduct(forecastProduct);
		System.assert(productWrapper.isLocalEnabled);
		System.assert(productWrapper.isDirectEnabled);
		System.assertEquals('Yes', productWrapper.directEnabled);
		System.assertEquals('Yes', productWrapper.localEnabled);

		forecastProduct.Local_Enabled__c = false;
		productWrapper.setFulfillmentByForecastProduct(forecastProduct);
		System.assert(!productWrapper.isLocalEnabled);
		System.assertEquals('No', productWrapper.localEnabled);
		System.assert(productWrapper.isDirectEnabled);
		System.assertEquals('Yes', productWrapper.directEnabled);

		forecastProduct.Local_Enabled__c = true;
		forecastProduct.Direct_Enabled__c = false;
		productWrapper.setFulfillmentByForecastProduct(forecastProduct);
		System.assert(productWrapper.isLocalEnabled);
		System.assertEquals('Yes', productWrapper.localEnabled);
		System.assert(!productWrapper.isDirectEnabled);
		System.assertEquals('No', productWrapper.directEnabled);
	}
}