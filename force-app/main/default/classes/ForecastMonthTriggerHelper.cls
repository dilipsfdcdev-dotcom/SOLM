public with sharing class ForecastMonthTriggerHelper {
	private Map<Id, Forecast_Month__c> newRecordsMap;
	private List<Forecast_Month__c> newRecordsList;

	public ForecastMonthTriggerHelper(List<SObject> newRecordsList, Map<Id, SObject> newRecordsMap) {
		this.newRecordsList = (List<Forecast_Month__c>) newRecordsList;
		this.newRecordsMap = (Map<Id, Forecast_Month__c>) newRecordsMap;
	}

	public ForecastMonthTriggerHelper(List<SObject> newRecordsList) {
		this.newRecordsList = (List<Forecast_Month__c>) newRecordsList;
	}

	public ForecastMonthTriggerHelper setExternalIds() {
		Set<Id> forecastProductsIds = new Set<Id>();
		for(Forecast_Month__c forecastMonth : newRecordsList) {
			forecastProductsIds.add(forecastMonth.Forecast_Product__c);
		}
		if(forecastProductsIds.isEmpty()) {
			return this;
		}

		Map<Id,Forecast_Product__c> forecastProducts = fetchForecastProductsByIds(forecastProductsIds);
		for(Forecast_Month__c forecastMonth : newRecordsList) {
			Forecast_Product__c forecastProduct = forecastProducts.get(forecastMonth.Forecast_Product__c);
			forecastMonth.External_ID__c = forecastProduct.Account__c + '-' + forecastProduct.Product__c + '-'
					+  ForecastUtil.getMonthUniqueId(forecastMonth.Month__c) + '-'+ (forecastProduct.Direct_Enabled__c ? '0' : '1');
            system.debug(forecastMonth.External_ID__c);
		}
		return this;
	}

	private Map<Id,Forecast_Product__c> fetchForecastProductsByIds(Set<Id> forecastProductsIds) {
		return new Map<Id, Forecast_Product__c> ([
			SELECT Id, Account__c, Product__c,Direct_Enabled__c
			FROM Forecast_Product__c
			WHERE Id IN :forecastProductsIds
		]);
	}

	private List<OrderItem> fetchOrderItemsByParameters(Set<Id> accountsIds, Set<Id> productsIds, Set<Integer> months, Set<Integer> years) {
		return [
				SELECT Id, Shipment_Date__c, Order.AccountId, Product2Id, Quantity, Order.RecordType.DeveloperName,
						Product2.EMEA_Case_Qty__c, Product2.NACA_Case_Qty__c
				FROM OrderItem
				WHERE Order.AccountId IN :accountsIds
				AND Product2Id IN :productsIds
				AND CALENDAR_MONTH(Shipment_Date__c) IN :months
				AND CALENDAR_YEAR(Shipment_Date__c) IN :years
		];
	}

	public ForecastMonthTriggerHelper createForecastItems() {
		Set<Id> forecastProductsIds = new Set<Id>();
		Set<Integer> months = new Set<Integer>();
		Set<Integer> years = new Set<Integer>();
		for(Forecast_Month__c forecastMonth : newRecordsList) {
			forecastProductsIds.add(forecastMonth.Forecast_Product__c);
			months.add(forecastMonth.Month__c.month());
			years.add(forecastMonth.Month__c.year());
			years.add(forecastMonth.Month__c.year()-1);
		}
		if(forecastProductsIds.isEmpty()) {
			return this;
		}

		Map<Id,Forecast_Product__c> forecastProducts = fetchForecastProductsByIds(forecastProductsIds);
		Set<Id> accountsIds = new Set<Id>();
		Set<Id> productsIds = new Set<Id>();
		for(Forecast_Product__c forecastProduct : forecastProducts.values()) {
			accountsIds.add(forecastProduct.Account__c);
			productsIds.add(forecastProduct.Product__c);
		}

		List<OrderItem> orderProducts = fetchOrderItemsByParameters(accountsIds, productsIds, months, years);
		List<Forecast_Item__c> forecastItemsToInsert = ForecastItemHelper.buildNewForecastItems(newRecordsList, forecastProducts, orderProducts);
		system.debug('forecastItemsToInsert-->'+forecastItemsToInsert);
		insert forecastItemsToInsert;
		return this;
	}
}