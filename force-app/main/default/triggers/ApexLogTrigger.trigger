trigger ApexLogTrigger on Debug_Log__e (after insert) {
    ApexLogTriggerHandler handle = new ApexLogTriggerHandler(Trigger.new);

	if(Trigger.isAfter) {
		if(Trigger.isInsert) {
            handle.afterInsert();
        }
	}
}