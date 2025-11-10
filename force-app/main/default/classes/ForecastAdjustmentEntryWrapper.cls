public class ForecastAdjustmentEntryWrapper {
    @AuraEnabled public Id recordId;
    @AuraEnabled public String name;
    @AuraEnabled public String comment;
    @AuraEnabled public Id opportunityForecastId;
    @AuraEnabled public String opportunityName;

    @AuraEnabled public Map<String, Decimal> forecastNumbers = new Map<String, Decimal>();    

    public ForecastAdjustmentEntryWrapper(Forecast_Item__c item, List<String> dateRange){ 
        this.recordId = item.Forecast_Adjustment__c;
        this.name = item.Forecast_Adjustment__r.Name;
        this.comment = item.Forecast_Adjustment__r.Comment__c;
        this.opportunityForecastId = item.Forecast_Adjustment__r.Forecast_Opportunity__c;
        this.opportunityName = item.Forecast_Adjustment__r.Forecast_Opportunity__r.Opportunity_Product__r.Opportunity.Name;
        
        for (String d : dateRange) {
            this.forecastNumbers.put(d, 0);
        }  
    }
}