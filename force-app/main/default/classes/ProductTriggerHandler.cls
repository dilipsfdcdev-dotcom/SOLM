public with sharing class ProductTriggerHandler {
	public static List<PricebookEntry> setPricebookEntries(Map<Id, Product2> productsById) {
		List <PricebookEntry> pbes = new List<PricebookEntry> ();
		Id standardPricebookId = Constants.priceBook.STANDARD_PRICEBOOK_ID;

		for(Product2 product : productsById.values()) {
			for(String currencyIsoCode : Constants.pricebookEntry.CURRENCIES) {
				PricebookEntry pbe = new PricebookEntry(
						CurrencyIsoCode = currencyIsoCode,
						Pricebook2Id = standardPricebookId,
						Product2Id = product.Id,
						UnitPrice = 0
				);

				if(product.SAP_Code__c != null){
					pbe.SAP_Code__c = product.SAP_Code__c + 'STANDARD' + currencyIsoCode;
				}
				
				pbes.add(pbe);
			}
		}

		return pbes;
	}
}