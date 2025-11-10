public class ApexEventSubscriber {
	List<Debug_Log__e> events;
	List<Log__c> logs = new List<Log__c>();

	public ApexEventSubscriber(List<Debug_Log__e> events) {
		this.events = events;
	}

	public void log() {
		for(Debug_Log__e event : events) {
			Log__c log = new Log__c(
				Message__c = event.Message__c,
				Error_Message__c = event.Error_Message__c,
				Stack_Trace__c = event.Stack_Trace__c,
				Type__c = event.Type__c,
                Market__c = event.Market__c,
				Object_Type__c = event.Object_Type__c,
				Area__c = event.Area__c
			);
			logs.add(log);
		}

		if (logs.size() > 0) {
			insert logs;
		}
	}
}