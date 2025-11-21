public with sharing class OpportunitySetForecastDAO {
	public static Opportunity fetchOpportunityById(Id opportunityId) {
		return [
				SELECT Id, AccountId, RecordTypeId, RecordType.DeveloperName, CloseDate, StageName,
				(SELECT Id, CurrencyIsoCode, HasSchedule, ListPrice, Product2Id, Product2.Name, Product2.NACA_Case_Qty__c,
						Product2.EMEA_Case_Qty__c, Product2.ProductCode, Product2.Product_Line__c, Quantity
				FROM OpportunityLineItems)
				FROM Opportunity
				WHERE Id =: opportunityId
		];
	}

	public static List<OpportunityLineItem> fetchOpportunityLineItemsByIds(Set<Id> oppLineItemsIds) {
		return [
				SELECT Id, CurrencyIsoCode, HasSchedule, ListPrice, Product2Id, Product2.Name, Product2.NACA_Case_Qty__c,
						Product2.EMEA_Case_Qty__c, Quantity, Opportunity.CloseDate
				FROM OpportunityLineItem
				WHERE Id IN :oppLineItemsIds
		];
	}

	public static List<Forecast_Item__c> fetchForecastItemsByForecastOpportunityIdsAndDateRange(Set<Id> forecastOppsIds, Date startDate, Date endDate) {
		return [
				SELECT Id, External_ID__c
				FROM Forecast_Item__c
				WHERE Forecast__r.Month__c >= :startDate
				AND Forecast__r.Month__c <= :endDate
				AND Forecast_Opportunity__c IN :forecastOppsIds
		];
	}

	public static List<Forecast_Month__c> fetchForecastMonthsByForecastProductIdAndDateRange(Set<Id> forecastProductIds, Date startDate, Date endDate) {
		return [
				SELECT Id, Forecast_Product__c, Month__c, External_ID__c
				FROM Forecast_Month__c
				WHERE Month__c >= :startDate
				AND Month__c <= :endDate
				AND Forecast_Product__c IN :forecastProductIds
		];
	}

	public static List<Forecast_Opportunity__c> fetchForecastOpportunitiesByOppLineItemIds(Set<Id> oppLineItemIds) {
		return [
				SELECT Id, Opportunity_Product__c, Opportunity_Product__r.Product2Id, Comment__c, External_Id__c, Fulfillment__c
				FROM Forecast_Opportunity__c
				WHERE Opportunity_Product__c IN :oppLineItemIds
		];
	}

	public static List<Forecast_Product__c> fetchForecastProductsByProductsAndAccountIds(Set<Id> productsIds, Id accountId) {
		return [
				SELECT Id, Account__c, Product__c, Local_Enabled__c, Direct_Enabled__c
				FROM Forecast_Product__c
				WHERE Account__c = :accountId
				AND Product__c IN :productsIds
				AND (Local_Enabled__c = TRUE OR Direct_Enabled__c = TRUE)
		];
	}

	public static List<OpportunityLineItemSchedule> fetchOppLineItemSchedules(Set<Id> oppLineItemsIds, Date startDate, Date endDate) {
		return [
				SELECT Id, ScheduleDate, Quantity, OpportunityLineItemId
				FROM OpportunityLineItemSchedule
				WHERE ScheduleDate >= :startDate
				AND ScheduleDate <= :endDate
				AND OpportunityLineItemId IN :oppLineItemsIds
		];
	}
}