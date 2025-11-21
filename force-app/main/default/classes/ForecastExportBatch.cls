global class ForecastExportBatch implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful  {

    @TestVisible static String payloadForTests;

    private Integer syncTime;

    global ForecastExportBatch(){
        this.syncTime = -2;
    }

    global ForecastExportBatch(Integer syncTime){
        this.syncTime = syncTime;
    }

	global Database.QueryLocator start(Database.BatchableContext bc) {
		return Database.getQueryLocator([
                SELECT id, Item_Type__c, Fulfillment__c, Quantity__c, Forecast__r.Month__c, External_Id__c, Active__c, BU_Approval__c,
                    Forecast__r.Forecast_Product__r.Local_Enabled__c,  Forecast__r.Forecast_Product__r.Direct_Enabled__c, Forecast__r.Forecast_Product__r.Local_Warehouse__r.Name,
                    Forecast__r.Forecast_Product__r.Account__r.Name, Forecast__r.Forecast_Product__r.Account__c, Forecast__r.Forecast_Product__r.Account__r.SAP_Code__c, 
                    Forecast__r.Forecast_Product__r.Account__r.Branch__c, Forecast__r.Forecast_Product__r.Account__r.Forecast_Enabled__c, 
                    Forecast__r.Forecast_Product__r.Account__r.Incoterms__c, Forecast__r.Forecast_Product__r.Account__r.Payment_Terms__c, 
                    Forecast__r.Forecast_Product__r.Account__r.RecordType.DeveloperName,
                    Forecast__r.Forecast_Product__r.Product__c, Forecast__r.Forecast_Product__r.Product__r.SAP_Code__c,
                    Forecast_Adjustment__r.Name,
                    Forecast__r.Forecast_Product__r.Account__r.Default_Partner__c, Forecast__r.Forecast_Product__r.Account__r.Default_Partner__r.Name, 
                    Forecast__r.Forecast_Product__r.Account__r.Default_Partner__r.SAP_Code__c, Forecast__r.Forecast_Product__r.Account__r.Default_Partner__r.Incoterms__c, 
                    Forecast__r.Forecast_Product__r.Account__r.Default_Partner__r.Payment_Terms__c, 
                    Forecast_Opportunity__r.Opportunity_Product__r.UnitPrice,
                    Forecast_Opportunity__r.Opportunity_Product__r.Opportunity.Incoterms__c, Forecast_Opportunity__r.Opportunity_Product__r.Opportunity.Payment_Terms__c, 
                    Forecast_Opportunity__r.Opportunity_Product__r.Opportunity.Name, Forecast_Opportunity__r.Opportunity_Product__r.PricebookEntry.Pricebook2.Name,
                    Forecast_Opportunity__r.Opportunity_Product__r.Opportunity.Business_Partner__r.Name, Forecast_Opportunity__r.Opportunity_Product__r.Opportunity.Business_Partner__c, 
                    Forecast_Opportunity__r.Opportunity_Product__r.Opportunity.Business_Partner__r.SAP_Code__c, 
                    Forecast_Opportunity__r.Opportunity_Product__r.Opportunity.Business_Partner__r.Incoterms__c, Forecast_Opportunity__r.Opportunity_Product__r.Opportunity.Business_Partner__r.Payment_Terms__c
                FROM Forecast_Item__c 
                WHERE Item_Type__c NOT IN (:Constants.forecastItem.ITEM_TYPE_CURRENT_ORDER, :Constants.forecastItem.ITEM_TYPE_PREVIOUS_YEAR_ORDER)
                AND Forecast__r.Month__c >= :Date.today().toStartOfMonth()
                AND (
                    LastModifiedDate > :DateTime.now().addHours(this.syncTime) OR
                    Forecast__r.Forecast_Product__r.Account__r.LastModifiedDate > :DateTime.now().addHours(this.syncTime) OR
                    Forecast__r.Forecast_Product__r.LastModifiedDate > :DateTime.now().addHours(this.syncTime) OR
                    Forecast_Adjustment__r.LastModifiedDate > :DateTime.now().addHours(this.syncTime) OR
                    Forecast_Opportunity__r.LastModifiedDate > :DateTime.now().addHours(this.syncTime) OR
                    Forecast_Opportunity__r.Opportunity_Product__r.Opportunity.LastModifiedDate > :DateTime.now().addHours(this.syncTime) OR
                    Forecast__r.Forecast_Product__r.Account__r.Default_Partner__r.LastModifiedDate > :DateTime.now().addHours(this.syncTime) OR    
                    Forecast_Opportunity__r.Opportunity_Product__r.Opportunity.Business_Partner__R.LastModifiedDate > :DateTime.now().addHours(this.syncTime)                               
                )
                ORDER BY Forecast__r.Month__c
        ]);
	}

	global void execute(Database.BatchableContext bc, List<Forecast_Item__c> scope) {
        try {
            String payload = new ForecastExportBuilder(scope).build().serialize();

            if(Test.isRunningTest()){
                payloadForTests = payload;
            }
            
            if(!String.isEmpty(payload)){
                Http http = new Http();
                HttpRequest req = new HttpRequest();
                req.setEndpoint('callout:' + 'DW/SFforecast');
                
                req.setMethod('POST');
                req.setHeader('Content-Type', 'application/json;charset=UTF-8');
                req.setBody(payload);
                req.setTimeout(120000); 
                system.debug('Forecast Batch Error Payload :' + payload);
                HttpResponse response = http.send(req);
                system.debug('Forecast Batch Error Request Details :' + req);
				system.debug('Forecast Batch Error Response :' + response);
                if(response.getStatusCode() != HttpStatusCode.OK) { 
                    new Logger('Forecast', 'POST').errorString(String.valueOf(response.getStatusCode()), response.getBody()).create();
                }  
            }         
        } catch (Exception e) {
            new Logger('Forecast', 'POST').error(e).create();
        }
	}

	global void finish(Database.BatchableContext bc) {

	}

    public class ForecastExportBuilder{
        List<ForecastExportWrapper> wrappers;
        List<Forecast_Item__c> forecastItems;

        public ForecastExportBuilder(List<Forecast_Item__c> scope){
            this.wrappers = new List<ForecastExportWrapper>();
            this.forecastItems = scope;
        }

        public ForecastExportBuilder build(){
            for(Forecast_Item__c item: forecastItems){
                ForecastExportWrapper wrapper = new ForecastExportWrapper(item);
                wrappers.add(wrapper.build());
            }
            return this;
        }

        public String serialize(){
            return JSON.serialize(wrappers);
        }
    }
}