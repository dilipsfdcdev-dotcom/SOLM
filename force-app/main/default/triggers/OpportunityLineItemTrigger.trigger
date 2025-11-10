trigger OpportunityLineItemTrigger on OpportunityLineItem (after update, before delete) {
	TriggerHandlerDispatcher.execute(new OpportunityLineItemTriggerHandler());
}