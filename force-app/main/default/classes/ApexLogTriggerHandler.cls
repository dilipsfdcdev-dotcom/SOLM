public with sharing class ApexLogTriggerHandler {
	private final List<Debug_Log__e> newRecordsList;

	public ApexLogTriggerHandler(List<Debug_Log__e> newRecordsList) {
		this.newRecordsList = newRecordsList;
	}

	public void afterInsert() {
		new ApexEventSubscriber(newRecordsList).log();
	}
}