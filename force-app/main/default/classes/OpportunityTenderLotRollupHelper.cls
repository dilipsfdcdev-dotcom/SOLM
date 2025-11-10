public with sharing class OpportunityTenderLotRollupHelper {

    private Map<Id, Opportunity> newRecordsMap;
    private Map<Id, Opportunity> oldRecordsMap;

    private Set<String> tenderIds = new Set<String>();

    public OpportunityTenderLotRollupHelper(Map<Id, SObject> newRecordsMap, Map<Id, SObject> oldRecordsMap) {
        this.newRecordsMap = (Map<Id, Opportunity>) newRecordsMap;
        this.oldRecordsMap = (Map<Id, Opportunity>) oldRecordsMap;
    }

    public OpportunityTenderLotRollupHelper getTendersOnLotInsert(){
        for(Opportunity opp: newRecordsMap.values()){
            if(isLOTRecordType(opp)){
                tenderIds.add(opp.Opportunity__c);
            }
        }
        return this;
    }

    public OpportunityTenderLotRollupHelper getTendersOnLotUpdate(){
        for(Opportunity opp: newRecordsMap.values()){
            Opportunity oldOpp = oldRecordsMap.get(opp.Id);

            if(isLOTRecordType(opp) && (isExpectedRevenueChanged(opp, oldOpp) || isStageChanged(opp, oldOpp))){
                tenderIds.add(opp.Opportunity__c);
            }
        }
        return this;
    }

    public OpportunityTenderLotRollupHelper getTendersOnLotDelete(){
        for(Opportunity opp: oldRecordsMap.values()){
            if(isLOTRecordType(opp)){
                tenderIds.add(opp.Opportunity__c);
            }
        }
        return this;
    }

    public void recalculateTenderRollupFields(){
        if(tenderIds.isEmpty()){
            return;
        }

        Map<Id, Opportunity> forUpdate = createTenderMap(tenderIds);

        List<AggregateResult> lotAggregates = [
            SELECT Opportunity__c tender, SUM(Expected_Revenue__c) expectedRevenue, stageName, COUNT(Id) countByStage 
            FROM Opportunity 
            WHERE RecordTypeId = :Constants.opportunity.RECORD_TYPE_EMEA_TENDER_LOT_ID 
            AND Opportunity__c IN :tenderIds 
            GROUP BY Opportunity__c, StageName
        ]; 

        for(AggregateResult lotAggregate: lotAggregates){
            Id tenderId = (Id) lotAggregate.get('tender');

            Opportunity tender = forUpdate.get(tenderId);
  
            Object expectedRevenue = lotAggregate.get('expectedRevenue');
            if(expectedRevenue != null){
                tender.Expected_Revenue_on_LOTs__c += (Decimal) expectedRevenue;
            }

            Integer lotsInStage = (Integer)lotAggregate.get('countByStage');
            tender.Number_of_LOTs__c += lotsInStage;

            switch on (String)lotAggregate.get('stageName') {
                when 'Analyzing', 'Preparation', 'Offer Submitted', 'Results' {		
                    tender.Open_LOTs__c += lotsInStage;
                }	
                when 'Closed Won' {
                    tender.Closed_Won_LOTs__c += lotsInStage;
                }
                when 'Closed Lost' {
                    tender.Closed_Lost_LOTs__c += lotsInStage;
                }
                when 'Disqualified' {
                    tender.Disqualified_LOTs__c += lotsInStage;
                }
            }

            forUpdate.put(tender.Id, tender);
        }

        update forUpdate.values();
    }

    private Map<Id, Opportunity> createTenderMap(Set<String> tenderIds){
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>();
        for(String tenderId: tenderIds){
            Opportunity tender = new Opportunity(
                Id = tenderId,
                Number_of_LOTs__c = 0,
                Open_LOTs__c = 0,
                Closed_Lost_LOTs__c = 0,
                Closed_Won_LOTs__c = 0,
                Disqualified_LOTs__c = 0,
                Expected_Revenue_on_LOTs__c = 0
            );
            oppMap.put(tenderId, tender);
        }
        return oppMap;
    }

    private Boolean isLOTRecordType(Opportunity opp){
        return opp.RecordTypeId ==  Constants.opportunity.RECORD_TYPE_EMEA_TENDER_LOT_ID;
    }

    private Boolean isExpectedRevenueChanged(Opportunity newOpp, Opportunity oldOpp){
        return newOpp.ExpectedRevenue != oldOpp.ExpectedRevenue;
    }

    private Boolean isStageChanged(Opportunity newOpp, Opportunity oldOpp){
        return newOpp.StageName != oldOpp.StageName;
    }
}