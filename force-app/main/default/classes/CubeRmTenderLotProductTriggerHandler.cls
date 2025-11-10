public class CubeRmTenderLotProductTriggerHandler extends CubeRmTriggerHandler{
	public override void afterInsert() {
        CubeRmHelper.updateLotStatusWhenProductAdded((List<cuberm_tc__TenderLotProduct__c>) trigger.new);
    }
    
    public override void beforeInsert() {
        CubeRmHelper.updatePricebookEntryOnLotProduct((List<cuberm_tc__TenderLotProduct__c>) trigger.new);
    }
    
    public override void beforeUpdate() {
        CubeRmHelper.updatePricebookEntryOnLotProduct((List<cuberm_tc__TenderLotProduct__c>) trigger.new);
    }
}