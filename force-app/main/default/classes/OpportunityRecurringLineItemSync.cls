public with sharing class OpportunityRecurringLineItemSync {

    @InvocableMethod(label='Sync Line Items' description='Sync Line Items for recurring Opportunities' category='Opportunity')
    public static void syncLineItems(List<String> recordIds) {
        Map<Id, List<OpportunityLineItem>> opportunityLineItemMap = getOpportunityLineItemMap(recordIds);

        List<Id> opportunitiesToClear = new List<Id>();
        List<OpportunityLineItem> lineItemsToInsert = new List<OpportunityLineItem>();

        for(Opportunity opp: [
            SELECT Id, Opportunity__c 
            FROM Opportunity 
            WHERE Is_this_a_recurring_opportunity__c = true
            AND Sync_Products_with_main_Opportunity__c = true
            AND Opportunity__c IN :recordIds
        ]){
            opportunitiesToClear.add(opp.Id);

            for(OpportunityLineItem lineItem: opportunityLineItemMap.get(opp.Opportunity__c)){
                OpportunityLineItem OLI = new OpportunityLineItem();
                OLI.OpportunityId = opp.Id;
                OLI.Quantity = lineItem.Quantity;
                OLI.UnitPrice = lineItem.UnitPrice;
                OLI.PricebookEntryId = lineItem.PricebookEntryId;
                lineItemsToInsert.add(OLI);
            }
        }

        Savepoint sp = Database.setSavepoint();
        try {
            if(opportunitiesToClear.size() > 0){
                delete [SELECT Id FROM OpportunityLineItem WHERE OpportunityId IN :opportunitiesToClear];
            }

            if(lineItemsToInsert.size() > 0){
                insert lineItemsToInsert;
            }
 
        } catch (Exception e) {
            Database.rollback(sp);
        }
    }

    private static Map<Id, List<OpportunityLineItem>> getOpportunityLineItemMap(List<String> recordIds){
        Map<Id, List<OpportunityLineItem>> opportunityLineItemMap = new Map <Id, List<OpportunityLineItem>>();

        for(Opportunity opp: [
            SELECT Id, (SELECT Id, Quantity, UnitPrice, PricebookEntryId FROM OpportunityLineItems)
            FROM Opportunity 
            WHERE Id IN :recordIds
        ]){
            opportunityLineItemMap.put(opp.Id, opp.OpportunityLineItems);
        }

        return opportunityLineItemMap;
    }
}