public class ForecastOpportunityEntryWrapper{
    @AuraEnabled public Id recordId;
    @AuraEnabled public String name;
    @AuraEnabled public String comment;
    @AuraEnabled public String buApproval;

    @AuraEnabled public Boolean approved = false;
    @AuraEnabled public Boolean rejected = false;
    @AuraEnabled public Boolean pending = false;

    @AuraEnabled public Id opportunityId;
    @AuraEnabled public Map<String, Decimal> forecastNumbers = new Map<String, Decimal>(); 
    
    public ForecastOpportunityEntryWrapper(Forecast_Item__c item, List<String> dateRange){ 
        this.recordId = item.Forecast_Opportunity__c;
        this.name = item.Forecast_Opportunity__r.Opportunity_Product__r.Opportunity.Name;
        this.comment = item.Forecast_Opportunity__r.Comment__c;
        this.buApproval = item.Forecast_Opportunity__r.BU_Approval__c;
        this.opportunityId = item.Forecast_Opportunity__r.Opportunity_Product__r.OpportunityId;

        for (String d : dateRange) {
            this.forecastNumbers.put(d, 0);
        }  

        if(item.Forecast_Opportunity__r.BU_Approval__c == Constants.approval.APPROVED){
            this.approved = true;
        }else if(item.Forecast_Opportunity__r.BU_Approval__c == Constants.approval.REJECTED){
            this.rejected = true;
        }else{
            this.pending = true;
        }
    }
}