trigger ProductTrigger on Product2 (after insert) {
	if(Trigger.isAfter) {
		if(Trigger.isInsert) {
			List <PricebookEntry> pbes = ProductTriggerHandler.setPricebookEntries(Trigger.newMap);
			insert pbes;
		}
	}
}