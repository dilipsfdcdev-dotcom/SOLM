trigger ForecastMonthTrigger on Forecast_Month__c (after insert, before insert) {
	TriggerHandlerDispatcher.execute(new ForecastMonthTriggerHandler());
}