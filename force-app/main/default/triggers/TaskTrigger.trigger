trigger TaskTrigger on Task (after update) {
	TriggerHandlerDispatcher.execute(new TaskTriggerHandler());
}