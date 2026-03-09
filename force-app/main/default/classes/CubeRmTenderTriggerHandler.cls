public class CubeRmTenderTriggerHandler extends CubeRmTriggerHandler{
	public override void beforeUpdate() {
        CubeRmHelper.transferProductToOutcomeOnAwarded((List<cuberm_tc__Tender__c>) trigger.new, (Map<Id, cuberm_tc__Tender__c>) Trigger.oldMap);
    }
}