public with sharing class OpportunityLineItemTriggerHelper {
	private Map<Id, OpportunityLineItem> oldRecordsMap;
	private Map<Id, OpportunityLineItem> newRecordsMap;
	private List<OpportunityLineItem> newRecordsList;

	public OpportunityLineItemTriggerHelper(Map<Id, SObject> newRecordsMap, Map<Id, SObject> oldRecordsMap) {
		this.newRecordsMap = (Map<Id,OpportunityLineItem>) newRecordsMap;
		this.oldRecordsMap = (Map<Id,OpportunityLineItem>) oldRecordsMap;

		this.newRecordsList = this.newRecordsMap.values();
	}

	private List<OpportunityLineItem> filterOppLineItemsChangedBySchedules() {
		List<OpportunityLineItem> filteredOppLineItems = new List<OpportunityLineItem>();

		for(OpportunityLineItem newOppLineItem : this.newRecordsList) {
			if(Util.isFieldChanged(this.oldRecordsMap?.get(newOppLineItem.Id), newOppLineItem, OpportunityLineItem.Quantity)
					&& newOppLineItem.HasQuantitySchedule == true) {
				filteredOppLineItems.add(newOppLineItem);
			}
		}
		return filteredOppLineItems;
	}

	public OpportunityLineItemTriggerHelper preventChangingSalesPriceBySchedules() {
		List<OpportunityLineItem> oppLineItemsToUpdate = new List<OpportunityLineItem>();
		for(OpportunityLineItem filteredOppLineItem : filterOppLineItemsChangedBySchedules()) {
			OpportunityLineItem opportunityLineItem = new OpportunityLineItem(
					Id = filteredOppLineItem.Id,
					UnitPrice = this.oldRecordsMap?.get(filteredOppLineItem.Id).UnitPrice
			);
			oppLineItemsToUpdate.add(opportunityLineItem);
		}

		update oppLineItemsToUpdate;
		return this;
	}
}