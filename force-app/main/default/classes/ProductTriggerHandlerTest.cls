@IsTest
private class ProductTriggerHandlerTest {
	@IsTest
	private static void testBehavior() {
		Product2 product = new Product2(Name = 'Test Product');

		Test.startTest();
		insert product;
		Test.stopTest();

		List<PricebookEntry> pbes = [
				SELECT CurrencyIsoCode, Product2Id
				FROM PricebookEntry
				WHERE Product2Id =: product.Id
		];

		System.assertEquals(5, pbes.size());
	}
}