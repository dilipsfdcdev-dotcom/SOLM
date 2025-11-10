public with sharing class OpportunityLineItemTriggerHandler extends TriggerHandler {
	public override String getImplementationName(){
		return OpportunityLineItemTriggerHandler.class.getName();
	}

	public override void afterUpdate(Map<Id, sObject> newRecordsMap, Map<Id, sObject> oldRecordsMap) {
		//preventChangingSalesPriceBySchedules in afterUpdate because changes made by Schedules occurs between before and after update
		new OpportunityLineItemTriggerHelper(newRecordsMap, oldRecordsMap).preventChangingSalesPriceBySchedules();
	}

	public override void beforeDelete(List<sObject> oldRecordsList, Map<Id, sObject> oldRecordsMap){
		new ForecastItemHelper().deactivateOpportunityItems(oldRecordsMap.keySet());
	}
}