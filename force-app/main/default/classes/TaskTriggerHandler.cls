public with sharing class TaskTriggerHandler extends TriggerHandler {
	public override String getImplementationName() {
		return TaskTriggerHandler.class.getName();
	}

	public override void afterUpdate(Map<Id, sObject> newRecordsMap,  Map<Id, sObject> oldRecordsMap) {
		TaskTriggerHelper.sendNotification((Map<Id, Task>)oldRecordsMap, (Map<Id, Task>)newRecordsMap);
	}
}