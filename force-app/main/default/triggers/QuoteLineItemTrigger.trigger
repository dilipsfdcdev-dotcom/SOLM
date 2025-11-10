trigger QuoteLineItemTrigger on QuoteLineItem (after update) {
	if(Trigger.isAfter) {
		if(Trigger.isUpdate) {
			QuoteLineItemTriggerHandler.createQlisHistory(Trigger.oldMap, Trigger.newMap);
		}
	}
}