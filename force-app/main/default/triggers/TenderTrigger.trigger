trigger TenderTrigger on cuberm_tc__Tender__c (before update) {
	new CubeRmTenderTriggerHandler().run();
}