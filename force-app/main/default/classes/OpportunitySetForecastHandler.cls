public with sharing class OpportunitySetForecastHandler {
	public static final Date START_DATE = System.today().toStartOfMonth();
	public static final Date END_DATE = START_DATE.addYears(1).addMonths(-1);

	public static final String CASES_VOLUME = 'cases';
	public static final String PIECES_VOLUME = 'pieces';
	public static final String NACA_CASE_QUANTITY_FIELD = 'NACA_Case_Qty__c';
	public static final String EMEA_CASE_QUANTITY_FIELD = 'EMEA_Case_Qty__c';
	public static final String EMEA_REGION = 'EMEA';
	public static final String NACA_REGION = 'NACA';
	public static final String YES = 'Yes';
	public static final String NO = 'No';

	public static final Map<String,String> RECORD_TYPE_BY_DEV_NAME = new Map<String,String> {
			Constants.opportunity.RECORD_TYPE_NACA => NACA_REGION,
			Constants.opportunity.RECORD_TYPE_EMEA => EMEA_REGION,
			Constants.opportunity.RECORD_TYPE_EMEA_TENDER => EMEA_REGION,
			Constants.opportunity.RECORD_TYPE_EMEA_TENDER_LOT => EMEA_REGION
	};

	public static final Map<String,String> VOLUME_BY_RECORD_TYPE = new Map<String,String> {
			Constants.opportunity.RECORD_TYPE_NACA => CASES_VOLUME,
			Constants.opportunity.RECORD_TYPE_EMEA => PIECES_VOLUME,
			Constants.opportunity.RECORD_TYPE_EMEA_TENDER => PIECES_VOLUME,
			Constants.opportunity.RECORD_TYPE_EMEA_TENDER_LOT => PIECES_VOLUME
	};

	public static final Map<String,String> QUANTITY_FIELD_NAME_BY_RECORD_TYPE = new Map<String,String> {
			Constants.opportunity.RECORD_TYPE_NACA => NACA_CASE_QUANTITY_FIELD,
			Constants.opportunity.RECORD_TYPE_EMEA => EMEA_CASE_QUANTITY_FIELD,
			Constants.opportunity.RECORD_TYPE_EMEA_TENDER => EMEA_CASE_QUANTITY_FIELD,
			Constants.opportunity.RECORD_TYPE_EMEA_TENDER_LOT => EMEA_CASE_QUANTITY_FIELD
	};

	@TestVisible
	private static Decimal countQuantityForSchedule(String volume, Decimal scheduleQuantity, Decimal caseQuantity, String opportunityRegion) {
		if(volume == OpportunitySetForecastHandler.PIECES_VOLUME && opportunityRegion == OpportunitySetForecastHandler.NACA_REGION) {
			return scheduleQuantity / caseQuantity;
		} else if (volume == OpportunitySetForecastHandler.CASES_VOLUME && opportunityRegion == OpportunitySetForecastHandler.EMEA_REGION) {
			return scheduleQuantity * caseQuantity;
		} else {
			return scheduleQuantity;
		}
	}

	@TestVisible
	private static Decimal changeQuantityVolumeToPieces(String volume, Decimal scheduleQuantity, Decimal caseQuantity) {
		if (volume == OpportunitySetForecastHandler.CASES_VOLUME) {
			return scheduleQuantity * caseQuantity;
		} else {
			return scheduleQuantity;
		}
	}

	public static List<Forecast_Item__c> upsertForecastItems(List<SetForecastProductWrapper> productWrappers, Map<String,Forecast_Opportunity__c> upsertedForecastOppsByExternalIds) {
		Set<Id> forecastOpportunitiesIds = new Set<Id>();
		for(Forecast_Opportunity__c forecastOpportunity : upsertedForecastOppsByExternalIds.values()) {
			forecastOpportunitiesIds.add(forecastOpportunity.Id);
		}

		List<Forecast_Item__c> existingForecastItems = OpportunitySetForecastDAO.fetchForecastItemsByForecastOpportunityIdsAndDateRange(forecastOpportunitiesIds, START_DATE, END_DATE.addDays(30));
		Map<String,Forecast_Item__c> existingForecastItemsByExternalIds = new Map<String,Forecast_Item__c>();
		for(Forecast_Item__c forecastItem : existingForecastItems) {
			if(forecastItem.External_ID__c != null) {
				existingForecastItemsByExternalIds.put(forecastItem.External_ID__c, forecastItem);
			}
		}

		List<Forecast_Item__c> forecastItems = new List<Forecast_Item__c>();
		for(SetForecastProductWrapper productWrapper : productWrappers) {
			String fulfillment = productWrapper.getFulfillmentPicklistName();
			String forecastOppExternalId = ForecastUtil.getOpportunityForecastExternalId(fulfillment, productWrapper.opportunityLineItemId);
			for(SetForecastScheduleWrapper scheduleWrapper : productWrapper.scheduleWrappers) {
				if(scheduleWrapper.quantity != null) {
					Id forecastOpportunityId = upsertedForecastOppsByExternalIds.get(forecastOppExternalId).Id;
					String forecastItemExternalId = ForecastUtil.getOpportunityForecastItemExternalId(productWrapper.accountId, productWrapper.productId, scheduleWrapper.scheduleDate, fulfillment, forecastOpportunityId);
					Forecast_Item__c forecastItem = new Forecast_Item__c(
							External_Id__c = forecastItemExternalId,
							Item_Type__c = Constants.forecastItem.ITEM_TYPE_OPP_PRODUCT,
							Quantity__c = changeQuantityVolumeToPieces(productWrapper.volume, scheduleWrapper.quantity, productWrapper.caseQuantity),
							Fulfillment__c = fulfillment,
							Forecast_Opportunity__c = forecastOpportunityId,
							Forecast__r = new Forecast_Month__c(External_ID__c = ForecastUtil.getForecastMonthExternalId(productWrapper.accountId, productWrapper.productId, scheduleWrapper.scheduleDate))
					);

					if(existingForecastItemsByExternalIds.containsKey(forecastItemExternalId)) {
						forecastItem.Id = existingForecastItemsByExternalIds.get(forecastItemExternalId).Id;
					}
					forecastItems.add(forecastItem);
				}
			}
		}
		if(!forecastItems.isEmpty()) {
			upsert forecastItems;
		}
		return forecastItems;
	}

	public static List<Forecast_Month__c> upsertForecastMonths(List<SetForecastProductWrapper> productWrappers) {
		Set<Id> forecastProductsIds = new Set<Id>();
		for(SetForecastProductWrapper productWrapper : productWrappers) {
			forecastProductsIds.add(productWrapper.forecastProductId);
		}

		List<Forecast_Month__c> existingForecastMonths = OpportunitySetForecastDAO.fetchForecastMonthsByForecastProductIdAndDateRange(forecastProductsIds, START_DATE, END_DATE.addDays(30));
		Map<String,Forecast_Month__c> forecastMonthsByExternalIds = new Map<String,Forecast_Month__c>();
		for(Forecast_Month__c forecastMonth : existingForecastMonths) {
			forecastMonthsByExternalIds.put(forecastMonth.External_ID__c, forecastMonth);
		}

		List<Forecast_Month__c> forecastMonths = new List<Forecast_Month__c>();
		for(SetForecastProductWrapper productWrapper : productWrappers) {
			for(SetForecastScheduleWrapper scheduleWrapper : productWrapper.scheduleWrappers) {
				String forecastMonthExternalId = ForecastUtil.getForecastMonthExternalId(productWrapper.accountId, productWrapper.productId, scheduleWrapper.scheduleDate);
				if(!forecastMonthsByExternalIds.containsKey(forecastMonthExternalId)) {
					forecastMonths.add(new Forecast_Month__c(
							Month__c = scheduleWrapper.scheduleDate.toStartOfMonth(),
							Forecast_Product__c = productWrapper.forecastProductId,
							CurrencyIsoCode = productWrapper.currencyIsoCode
					));
				}
			}
		}
		if(!forecastMonths.isEmpty()) {
			insert forecastMonths;
		}
		return forecastMonths;
	}

	private static List<OpportunityLineItemSchedule> buildSchedulesByProductWrappers(List<SetForecastProductWrapper> productWrappers, String opportunityRegionName) {
		List<OpportunityLineItemSchedule> schedules = new List<OpportunityLineItemSchedule>();
		for(SetForecastProductWrapper productWrapper : productWrappers) {
			for(SetForecastScheduleWrapper scheduleWrapper : productWrapper.scheduleWrappers) {
				if(scheduleWrapper.quantity != null) {
					schedules.add(new OpportunityLineItemSchedule(
							Id = scheduleWrapper.scheduleId,
							OpportunityLineItemId = productWrapper.opportunityLineItemId,
							Quantity = countQuantityForSchedule(productWrapper.volume, scheduleWrapper.quantity, productWrapper.caseQuantity, opportunityRegionName),
							ScheduleDate = scheduleWrapper.scheduleDate,
							Type = 'Quantity'
					));
				}
			}
		}
		return schedules;
	}

	private static List<OpportunityLineItemSchedule> createHistoricalSchedules(List<OpportunityLineItem> oppLineItems) {
		List<OpportunityLineItemSchedule> schedulesToInsert = new List<OpportunityLineItemSchedule>();
		for(OpportunityLineItem oli : oppLineItems) {
			if(!oli.HasSchedule && oli.Opportunity.CloseDate < START_DATE) {
				schedulesToInsert.add(buildScheduleForOppLineItem(oli, oli.Opportunity.CloseDate));
			}
		}
		return schedulesToInsert;
	}
	
	public static List<OpportunityLineItemSchedule> upsertAndConsolidateScheduleRecords(List<SetForecastProductWrapper> productWrappers, String opportunityRegionName) {
		Set<Id> oppLineItemsIds = new Set<Id>();
		Set<Id> schedulesIds = new Set<Id>();
		for(SetForecastProductWrapper productWrapper : productWrappers) {
			oppLineItemsIds.add(productWrapper.opportunityLineItemId);
			for(SetForecastScheduleWrapper scheduleWrapper : productWrapper.scheduleWrappers) {
				if(scheduleWrapper.scheduleId != null) {
					schedulesIds.add(scheduleWrapper.scheduleId);
				}
			}
		}

		List<OpportunityLineItemSchedule> schedules = buildSchedulesByProductWrappers(productWrappers, opportunityRegionName);
		Map<Id,OpportunityLineItemSchedule> redundantSchedulesInDateRange = new Map<Id,OpportunityLineItemSchedule>(OpportunitySetForecastDAO.fetchOppLineItemSchedules(oppLineItemsIds, START_DATE, END_DATE.addDays(30)));
		List<OpportunityLineItem> opportunityLineItems = OpportunitySetForecastDAO.fetchOpportunityLineItemsByIds(oppLineItemsIds);
		schedules.addAll(createHistoricalSchedules(opportunityLineItems));

		for(Id scheduleId : schedulesIds) {
			redundantSchedulesInDateRange.remove(scheduleId);
		}
		if(!redundantSchedulesInDateRange.isEmpty()) {
			delete redundantSchedulesInDateRange.values();
		}

		if(!schedules.isEmpty()) {
			upsert schedules;
		}
		return schedules;
	}

	public static Map<String,Forecast_Opportunity__c> getForecastOpportunitiesByExternalIds(List<SetForecastProductWrapper> productWrappers) {
		Map<String,Forecast_Opportunity__c> forecastOpportunitiesByExternalIds = new Map<String,Forecast_Opportunity__c>();
		for(SetForecastProductWrapper productWrapper : productWrappers) {
			String fulfillment = productWrapper.getFulfillmentPicklistName();
			String forecastOppExternalId = ForecastUtil.getOpportunityForecastExternalId(fulfillment, productWrapper.opportunityLineItemId);
			forecastOpportunitiesByExternalIds.put(
					forecastOppExternalId,
					new Forecast_Opportunity__c(
							Id = productWrapper.getForecastOpportunityIdByFulfillment(),
							Opportunity_Product__c = productWrapper.opportunityLineItemId,
							Comment__c = productWrapper.comment,
							CurrencyIsoCode = productWrapper.currencyIsoCode,
							External_Id__c = forecastOppExternalId,
							Fulfillment__c = fulfillment
			));
		}
		return forecastOpportunitiesByExternalIds;
	}

	public static void upsertForecastOpportunityRecords(Map<String,Forecast_Opportunity__c> forecastOpportunitiesByExternalIds) {
		upsert forecastOpportunitiesByExternalIds.values();
	}

	private static OpportunityLineItemSchedule buildScheduleForOppLineItem(OpportunityLineItem oli, Date scheduleDate) {
		return new OpportunityLineItemSchedule(
				OpportunityLineItemId = oli.Id,
				Quantity = oli.Quantity,
				ScheduleDate = scheduleDate,
				Type = 'Quantity'
		);
	}
	
	public static List<OpportunityLineItemSchedule> createSchedulesForOppLineItems(List<OpportunityLineItem> oppLineItems, Opportunity opportunity) {
		List<OpportunityLineItemSchedule> schedulesToInsert = new List<OpportunityLineItemSchedule>();
		for(OpportunityLineItem oli : oppLineItems) {
			if(!oli.HasSchedule) {
				schedulesToInsert.add(buildScheduleForOppLineItem(oli, opportunity.CloseDate));
			}
		}
		return schedulesToInsert;
	}
}