public with sharing class OrderItemTriggerHelper {
	private Map<Id, OrderItem> newRecordsMap;
	private Map<Id, OrderItem> oldRecordsMap;
	private List<OrderItem> newRecordsList;

	public OrderItemTriggerHelper(List<SObject> newRecordsList, Map<Id, SObject> newRecordsMap) {
		this.newRecordsList = (List<OrderItem>) newRecordsList;
		this.newRecordsMap = (Map<Id, OrderItem>) newRecordsMap;
	}

	public OrderItemTriggerHelper(Map<Id, SObject> newRecordsMap, Map<Id, SObject> oldRecordsMap) {
		this.newRecordsMap = (Map<Id, OrderItem>) newRecordsMap;
		this.oldRecordsMap = (Map<Id, OrderItem>) oldRecordsMap;
	}

	public OrderItemTriggerHelper(Map<Id, SObject> oldRecordsMap) {
		this.oldRecordsMap = (Map<Id, OrderItem>) oldRecordsMap;
	}

	private List<Forecast_Item__c> fetchForecastItemsByOrderProductIds(Set<Id> orderProductIds) {
		return [
				SELECT Id, Order_Product__c, Quantity__c, Item_Type__c, Forecast__c,
						Forecast__r.Month__c
				FROM Forecast_Item__c
				WHERE Order_Product__c IN :orderProductIds
		];
	}

	private Map<Id,OrderItem> fetchOrderItemsByIds(Set<Id> orderItemIds) {
		return new Map<Id,OrderItem>([
				SELECT Id, Quantity, Shipment_Date__c, Product2Id,
						Order.AccountId, Order.RecordType.DeveloperName,
						Product2.EMEA_Case_Qty__c, Product2.NACA_Case_Qty__c
				FROM OrderItem
				WHERE Id IN :orderItemIds
		]);
	}

	private List<Forecast_Month__c> fetchForecastMonthsByParameters(Set<Id> accountIds, Set<Id> productIds, Set<Integer> months, Set<Integer> years) {
		return [
				SELECT Id, Month__c, CurrencyIsoCode, Forecast_Product__c,
						Forecast_Product__r.Account__c, Forecast_Product__r.Product__c
				FROM Forecast_Month__c
				WHERE Forecast_Product__r.Account__c IN :accountIds
					AND Forecast_Product__r.Product__c IN :productIds
					AND CALENDAR_MONTH(Month__c) IN :months
					AND CALENDAR_YEAR(Month__c) IN :years
		];
	}

	private Map<Id,Forecast_Product__c> buildForecastProductList (List<Forecast_Month__c> forecastMonths) {
		Map<Id,Forecast_Product__c> forecastProducts = new Map<Id,Forecast_Product__c>();
		for(Forecast_Month__c forecastMonth : forecastMonths) {
			Forecast_Product__c forecastProduct = new Forecast_Product__c(
					Id = forecastMonth.Forecast_Product__c,
					Account__c = forecastMonth.Forecast_Product__r.Account__c,
					Product__c = forecastMonth.Forecast_Product__r.Product__c
			);
			forecastProducts.put(forecastProduct.Id, forecastProduct);
		}
		return forecastProducts;
	}

	private void buildNewForecastItems(List<OrderItem> orderItems) {
		Set<Id> accountIds = new Set<Id>();
		Set<Id> productIds = new Set<Id>();
		Set<Integer> months = new Set<Integer>();
		Set<Integer> years = new Set<Integer>();
		for(OrderItem orderItem : orderItems) {
			accountIds.add(orderItem.Order.AccountId);
			productIds.add(orderItem.Product2Id);
			if(orderItem.Shipment_Date__c != null) {
				months.add(orderItem.Shipment_Date__c.month());
				years.add(orderItem.Shipment_Date__c.year());
				years.add(orderItem.Shipment_Date__c.year() + 1);
			}
		}
		if(months.isEmpty()) {
			return;
		}

		List<Forecast_Month__c> forecastMonths = fetchForecastMonthsByParameters(accountIds, productIds, months, years);
		if(forecastMonths.isEmpty()) {
			return;
		}

		Map<Id,Forecast_Product__c> forecastProducts = buildForecastProductList(forecastMonths);
		List<Forecast_Item__c> forecastItemsToInsert = ForecastItemHelper.buildNewForecastItems(forecastMonths, forecastProducts, orderItems);

		if(!forecastItemsToInsert.isEmpty()) {
			insert forecastItemsToInsert;
		}
	}

	private Set<Id> filterOrderItemsToManageForecastingItemsIds() {
		Set<Id> orderItemsChangedIds = new Set<Id>();

		for(OrderItem newOrderItem : newRecordsMap.values()) {
			OrderItem oldOrderItem = oldRecordsMap?.get(newOrderItem.Id);
			if(Util.isFieldChanged(oldOrderItem, newOrderItem, OrderItem.Shipment_Date__c)
					|| Util.isFieldChanged(oldOrderItem, newOrderItem, OrderItem.Quantity)) {
				orderItemsChangedIds.add(newOrderItem.Id);
			}
		}
		return orderItemsChangedIds;
	}

	private Set<Id> filterOrderItemsWithChangedShipmentDateIds() {
		Set<Id> orderItemsChangedDateIds = new Set<Id>();

		for(OrderItem newOrderItem : newRecordsMap.values()) {
			OrderItem oldOrderItem = oldRecordsMap?.get(newOrderItem.Id);
			if(Util.isFieldChanged(oldOrderItem, newOrderItem, OrderItem.Shipment_Date__c)
					&& (newOrderItem.Shipment_Date__c?.month() != oldOrderItem.Shipment_Date__c?.month()
							|| newOrderItem.Shipment_Date__c?.year() != oldOrderItem.Shipment_Date__c?.year())) {
				orderItemsChangedDateIds.add(newOrderItem.Id);
			}
		}
		return orderItemsChangedDateIds;
	}

	private Map<Id,OrderItem> filterOrderItemMapByKeySet(Map<Id,OrderItem> orderItemsMapToFilter, Set<Id> keySet) {
		Map<Id,OrderItem> orderItemsReplaced = new Map<Id,OrderItem>();

		for(Id key : keySet) {
			if(orderItemsMapToFilter.containsKey(key)) {
				orderItemsReplaced.put(key, orderItemsMapToFilter.get(key));
			}
		}
		return orderItemsReplaced;
	}

	public OrderItemTriggerHelper createForecastsItems() {
		Map<Id,OrderItem> orderItemsByIds = fetchOrderItemsByIds(this.newRecordsMap.keySet());
		buildNewForecastItems(orderItemsByIds.values());
		return this;
	}

	public OrderItemTriggerHelper uploadForecastsItems() {
		Set<Id> changedDateOrderItemsIds = filterOrderItemsWithChangedShipmentDateIds();
		Set<Id> changedOrderItemsIds = filterOrderItemsToManageForecastingItemsIds();

		Map<Id,OrderItem> changedOrderItemsById = fetchOrderItemsByIds(changedOrderItemsIds);
		if(changedOrderItemsById.isEmpty()) {
			return this;
		}

		List<Forecast_Item__c> allForecastItems = fetchForecastItemsByOrderProductIds(changedOrderItemsIds);
		List<Forecast_Item__c> forecastItemsToRemove = new List<Forecast_Item__c>();
		List<Forecast_Item__c> forecastItemsToUpdate = new List<Forecast_Item__c>();
		for(Forecast_Item__c forecastItem : allForecastItems) {
			OrderItem orderItem = changedOrderItemsById.get(forecastItem.Order_Product__c);
			if(ForecastItemHelper.isOrderItemDateConnectedToForecastItem(orderItem, forecastItem)) {
				forecastItem = ForecastItemHelper.buildForecastItem(orderItem, forecastItem.Forecast__r.Month__c, forecastItem);
				forecastItemsToUpdate.add(forecastItem);
				changedDateOrderItemsIds.remove(orderItem.Id);
			} else {
				forecastItemsToRemove.add(forecastItem);
			}
		}

		if(!changedDateOrderItemsIds.isEmpty()) {
			Map<Id,OrderItem> orderItemsDateChangedById = filterOrderItemMapByKeySet(changedOrderItemsById, changedDateOrderItemsIds);
			buildNewForecastItems(orderItemsDateChangedById.values());

			if(!forecastItemsToRemove.isEmpty()) {
				delete forecastItemsToRemove;
			}
		}

		if(!forecastItemsToUpdate.isEmpty()) {
			update forecastItemsToUpdate;
		}
		return this;
	}

	public OrderItemTriggerHelper removeForecastsItems() {
		if(this.oldRecordsMap == null || this.oldRecordsMap.isEmpty()) {
			return this;
		}

		List<Forecast_Item__c> forecastItemsToRemove = fetchForecastItemsByOrderProductIds(this.oldRecordsMap.keySet());

		if(!forecastItemsToRemove.isEmpty()) {
			delete forecastItemsToRemove;
		}
		return this;
	}
}