public with sharing class ForecastItemHelper {
	public static Boolean isOrderItemDateConnectedToForecastItem(OrderItem orderItem, Forecast_Item__c forecastItem) {
		return forecastItem.Forecast__r.Month__c.month() == orderItem.Shipment_Date__c.month()
				&& (forecastItem.Forecast__r.Month__c.year() == orderItem.Shipment_Date__c.year()
				|| forecastItem.Forecast__r.Month__c.year()-1 == orderItem.Shipment_Date__c.year());
	}

	@TestVisible
	private static Boolean isOrderProductConnectedToForecastMonth(OrderItem orderProduct, Forecast_Month__c forecastMonth, Forecast_Product__c forecastProduct) {
		return orderProduct.Order.AccountId == forecastProduct.Account__c
				&& orderProduct.Product2Id == forecastProduct.Product__c
				&& orderProduct.Shipment_Date__c.month() == forecastMonth.Month__c.month()
				&& (
				orderProduct.Shipment_Date__c.year() == forecastMonth.Month__c.year()
						|| orderProduct.Shipment_Date__c.year() == forecastMonth.Month__c.year()-1
		);
	}

	public static Forecast_Item__c buildForecastItem(OrderItem orderProduct, Date forecastMonthDate, Forecast_Item__c forecastItem) {
		forecastItem.Order_Product__c = orderProduct.Id;

		if(orderProduct.Order.RecordType.DeveloperName == Constants.order.RECORD_TYPE_NACA) {
			forecastItem.Quantity__c = orderProduct.Product2.NACA_Case_Qty__c * orderProduct.Quantity;
		} else if(orderProduct.Order.RecordType.DeveloperName == Constants.order.RECORD_TYPE_EMEA) {
			forecastItem.Quantity__c = orderProduct.Product2.EMEA_Case_Qty__c * orderProduct.Quantity;
		}

		if(orderProduct.Shipment_Date__c.year() == forecastMonthDate.year()) {
			forecastItem.Item_Type__c = Constants.forecastItem.ITEM_TYPE_CURRENT_ORDER;
		} else if(orderProduct.Shipment_Date__c.year() == forecastMonthDate.year()-1) {
			forecastItem.Item_Type__c = Constants.forecastItem.ITEM_TYPE_PREVIOUS_YEAR_ORDER;
		}
		return forecastItem;
	}

	public static List<Forecast_Item__c> buildNewForecastItems(List<Forecast_Month__c> forecastMonths, Map<Id,Forecast_Product__c> forecastProductsByIds, List<OrderItem> orderProducts) {
		List<Forecast_Item__c> forecastItemsToInsert = new List<Forecast_Item__c>();

		for(Forecast_Month__c forecastMonth : forecastMonths) {
			Forecast_Product__c forecastProduct = forecastProductsByIds.get(forecastMonth.Forecast_Product__c);

			for(OrderItem orderProduct : orderProducts) {
				if(isOrderProductConnectedToForecastMonth(orderProduct, forecastMonth, forecastProduct)) {
					Forecast_Item__c forecastItem = buildForecastItem(
							orderProduct,
							forecastMonth.Month__c,
							new Forecast_Item__c(
									Forecast__c = forecastMonth.Id,
									CurrencyIsoCode = forecastMonth.CurrencyIsoCode
							));

					forecastItemsToInsert.add(forecastItem);
				}
			}
		}
		return forecastItemsToInsert;
	}

	public void deactivateOpportunityItems(Set<Id> oppLineItemIds){
		List<Forecast_Opportunity__c> forecastOppsForUpdate = new List<Forecast_Opportunity__c>();
		List<Forecast_Item__c> forecastItemsForUpdate = new List<Forecast_Item__c>();

		for(Forecast_Opportunity__c opp: getOppRelatedForecastRecords(oppLineItemIds)){
			opp.Comment__c = 'Opportunity Product ' + opp.Opportunity_Product__r.Name + ' has been deleted';
			forecastOppsForUpdate.add(opp);

			for(Forecast_Item__c item: opp.Forecast_Items__r){
				item.Active__c = false;
				forecastItemsForUpdate.add(item);
			}
		}
		update forecastOppsForUpdate;
		update forecastItemsForUpdate;
	}

	private List<Forecast_Opportunity__c> getOppRelatedForecastRecords(Set<Id> oppLineItemIds){
		return [
			SELECT Id, Opportunity_Product__c, Opportunity_Product__r.Name,
			(SELECT Id FROM Forecast_Items__r WHERE Forecast__r.Month__c >= :Date.today().toStartOfMonth())
			FROM Forecast_Opportunity__c 
			WHERE Opportunity_Product__c IN :oppLineItemIds
		];
	}
}