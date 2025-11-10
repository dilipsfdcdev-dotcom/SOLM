public with sharing class ForecastMonthTriggerHandler extends TriggerHandler {
	public override String getImplementationName(){
		return ForecastMonthTriggerHandler.class.getName();
	}

	public override void afterInsert(List<SObject> newRecordsList , Map<Id, SObject> newRecordsMap) {
		new ForecastMonthTriggerHelper(newRecordsList, newRecordsMap).createForecastItems();
	}

	public override void beforeInsert(List<SObject> newRecordsList) {
		new ForecastMonthTriggerHelper(newRecordsList).setExternalIds();
	}
}