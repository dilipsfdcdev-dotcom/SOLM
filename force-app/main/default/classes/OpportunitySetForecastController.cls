public with sharing class OpportunitySetForecastController {
	@AuraEnabled
	public static void saveForecasting(List<SetForecastProductWrapper> productWrappers, String opportunityRecordType) {
		try {
			Map<String,Forecast_Opportunity__c> forecastOpportunitiesByExternalIds = OpportunitySetForecastHandler.getForecastOpportunitiesByExternalIds(productWrappers);
			OpportunitySetForecastHandler.upsertForecastOpportunityRecords(forecastOpportunitiesByExternalIds);
			OpportunitySetForecastHandler.upsertAndConsolidateScheduleRecords(productWrappers, opportunityRecordType);
			OpportunitySetForecastHandler.upsertForecastMonths(productWrappers);
			OpportunitySetForecastHandler.upsertForecastItems(productWrappers, forecastOpportunitiesByExternalIds);
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	@AuraEnabled
	public static ResultWrapper getForecastingOpportunityDataToProcess(Id opportunityId) {
		try {
			return buildResultWrapper(opportunityId);
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	public static ResultWrapper buildResultWrapper(Id opportunityId) {
		Set<Id> productsIds = new Set<Id>();
		Map<Id,SetForecastProductWrapper> productWrappersByOlisIds = new Map<Id,SetForecastProductWrapper>();

		Opportunity opportunity = OpportunitySetForecastDAO.fetchOpportunityById(opportunityId);
		String quantityFieldName = OpportunitySetForecastHandler.QUANTITY_FIELD_NAME_BY_RECORD_TYPE.get(opportunity.RecordType.DeveloperName);
		String volume = OpportunitySetForecastHandler.VOLUME_BY_RECORD_TYPE.get(opportunity.RecordType.DeveloperName);

		for(OpportunityLineItem oli : opportunity.OpportunityLineItems) {
			productWrappersByOlisIds.put(oli.Id, new SetForecastProductWrapper().buildWithoutForecastProductData(oli, opportunity.AccountId, quantityFieldName, volume));
			productsIds.add(oli.Product2Id);
		}
		if(productsIds.isEmpty() || productWrappersByOlisIds.isEmpty()) {
			return null;
		}

		List<Forecast_Opportunity__c> forecastOpportunities = OpportunitySetForecastDAO.fetchForecastOpportunitiesByOppLineItemIds(productWrappersByOlisIds.keySet());
		for(Forecast_Opportunity__c forecastOpportunity : forecastOpportunities) {
			productWrappersByOlisIds.get(forecastOpportunity.Opportunity_Product__c).setForecastOpportunityData(forecastOpportunity.Id, forecastOpportunity.Comment__c, forecastOpportunity.Fulfillment__c);
		}

		List<Forecast_Product__c> forecastProducts = OpportunitySetForecastDAO.fetchForecastProductsByProductsAndAccountIds(productsIds, opportunity.AccountId);
		productWrappersByOlisIds = filterAndUpdateProductWrappersByForecastProducts(forecastProducts, productWrappersByOlisIds);
		if(productWrappersByOlisIds.isEmpty()) {
			return null;
		}

		List<OpportunityLineItemSchedule> oppLineItemSchedules = OpportunitySetForecastDAO.fetchOppLineItemSchedules(productWrappersByOlisIds.keySet(), OpportunitySetForecastHandler.START_DATE, OpportunitySetForecastHandler.END_DATE.addDays(30));
		oppLineItemSchedules.addAll(OpportunitySetForecastHandler.createSchedulesForOppLineItems(opportunity.OpportunityLineItems, opportunity));
		productWrappersByOlisIds = buildScheduleWrappersForProductWrappers(productWrappersByOlisIds, oppLineItemSchedules);

		return new ResultWrapper(OpportunitySetForecastHandler.RECORD_TYPE_BY_DEV_NAME.get(opportunity.RecordType.DeveloperName), productWrappersByOlisIds.values());
	}

	@TestVisible
	private static Map<Id,SetForecastProductWrapper> filterAndUpdateProductWrappersByForecastProducts(List<Forecast_Product__c> forecastProducts, Map<Id,SetForecastProductWrapper> productWrappersByOlisIds) {
		Map<Id,SetForecastProductWrapper> resultProductWrappers = new Map<Id,SetForecastProductWrapper>();
		for(Forecast_Product__c forecastProduct : forecastProducts) {
			for(SetForecastProductWrapper productWrapper : productWrappersByOlisIds.values()) {
				if(forecastProduct.Product__c == productWrapper.productId) {
					resultProductWrappers.put(
									productWrapper.opportunityLineItemId,
									productWrapper.setFulfillmentByForecastProduct(forecastProduct)
					);
				}
			}
		}
		return resultProductWrappers;
	}

	private static List<SetForecastScheduleWrapper> buildScheduleWrappersForProduct(Id oppLineItemId, List<OpportunityLineItemSchedule> oliSchedules) {
		List<SetForecastScheduleWrapper> scheduleWrappers = new List<SetForecastScheduleWrapper>();
		Map<String,SetForecastScheduleWrapper> scheduleWrappersByMonthAndYear = new Map<String,SetForecastScheduleWrapper>();

		for(OpportunityLineItemSchedule oliSchedule : oliSchedules) {
			if(oliSchedule.OpportunityLineItemId == oppLineItemId) {
				SetForecastScheduleWrapper scheduleWrapper = new SetForecastScheduleWrapper();
				if(oliSchedule.Quantity != 0) {
					scheduleWrapper.quantity = oliSchedule.Quantity;
				}
				scheduleWrapper.scheduleId = oliSchedule.Id;
				scheduleWrapper.scheduleDate = oliSchedule.ScheduleDate;

				String monthUniqueId = ForecastUtil.getMonthUniqueId(oliSchedule.ScheduleDate);
				if(scheduleWrappersByMonthAndYear.containsKey(monthUniqueId)) {
					scheduleWrapper.quantity += scheduleWrappersByMonthAndYear.get(monthUniqueId).quantity;
				}
				scheduleWrappersByMonthAndYear.put(monthUniqueId, scheduleWrapper);
			}
		}

		for(Date tmpDate = OpportunitySetForecastHandler.START_DATE; tmpDate <= OpportunitySetForecastHandler.END_DATE; tmpDate = tmpDate.addMonths(1)) {
			String monthUniqueId = ForecastUtil.getMonthUniqueId(tmpDate);
			SetForecastScheduleWrapper scheduleWrapper;
			if(scheduleWrappersByMonthAndYear.containsKey(monthUniqueId)) {
				scheduleWrapper = scheduleWrappersByMonthAndYear.get(monthUniqueId);
			} else {
				scheduleWrapper = new SetForecastScheduleWrapper();
				scheduleWrapper.scheduleDate = tmpDate;
			}
			scheduleWrappers.add(scheduleWrapper);
		}
		return scheduleWrappers;
	}

	private static Map<Id,SetForecastProductWrapper> buildScheduleWrappersForProductWrappers(Map<Id,SetForecastProductWrapper> productWrappersByProductsIds, List<OpportunityLineItemSchedule> oppLineItemSchedules) {
		for(SetForecastProductWrapper productWrapper : productWrappersByProductsIds.values()) {
			List<SetForecastScheduleWrapper> scheduleWrappers = buildScheduleWrappersForProduct(productWrapper.opportunityLineItemId, oppLineItemSchedules);
			productWrapper.scheduleWrappers = scheduleWrappers;
			productWrappersByProductsIds.put(productWrapper.opportunityLineItemId, productWrapper);
		}
		return productWrappersByProductsIds;
	}

	@TestVisible
	class ResultWrapper {
		@AuraEnabled public String recordType { get; set; }
		@AuraEnabled public List<SetForecastProductWrapper> products { get; set; }

		public ResultWrapper(String recordType, List<SetForecastProductWrapper> products) {
			this.recordType = recordType;
			this.products = products;
		}
	}
}