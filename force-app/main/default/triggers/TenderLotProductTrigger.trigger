trigger TenderLotProductTrigger on cuberm_tc__TenderLotProduct__c (after insert, before insert, before update) {
	new CubeRmTenderLotProductTriggerHandler().run();
}