public with sharing class OrderItemTriggerHandler extends TriggerHandler {
	public override String getImplementationName(){
		return OrderItemTriggerHandler.class.getName();
	}

	public override void afterInsert(List<SObject> newRecordsList , Map<Id, SObject> newRecordsMap) {
		new OrderItemTriggerHelper(newRecordsList, newRecordsMap).createForecastsItems();
	}

	public override void afterUpdate(Map<Id, sObject> newRecordsMap,  Map<Id, sObject> oldRecordsMap){
		new OrderItemTriggerHelper(newRecordsMap, oldRecordsMap).uploadForecastsItems();
	}

	public override void beforeDelete(List<sObject> oldRecordsList, Map<Id, sObject> oldRecordsMap){
		new OrderItemTriggerHelper(oldRecordsMap).removeForecastsItems();
	}
}