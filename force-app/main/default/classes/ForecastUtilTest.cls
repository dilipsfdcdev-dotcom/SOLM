@IsTest
private class ForecastUtilTest {
	@IsTest
	static void getOpportunityForecastExternalIdTest() {
		System.assertEquals('test Fulfillment-0011000000AaaaAAAA', ForecastUtil.getOpportunityForecastExternalId('test Fulfillment', '0011000000AaaaAAAA'));
	}

	@IsTest
	static void getOpportunityForecastItemExternalIdTest() {
		/*System.assertEquals(
				'000000000AccountID-001100000ProductID-Oct-22-Opportunity Product-test Fulfillment-0000000oPPforecast',
				ForecastUtil.getOpportunityForecastItemExternalId(
						'000000000AccountID', '001100000ProductID', Date.parse('10/01/2022'), 'test Fulfillment', '0000000oPPforecast')
		);*/
	}
}