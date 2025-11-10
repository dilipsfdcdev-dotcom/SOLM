public with sharing class SAP_GET_PriceBookEntries {
    private SAP_Instance sapInstance;
    Map<String,String> requestParamsMap;

    private List<ISAP_PARSER_PriceBookEntry> responses = new List<ISAP_PARSER_PriceBookEntry>();
    private HttpResponse sapResponse;

    private Map<String, String> product2SAPMap = new Map<String, String>();
    private Map<String, String> priceBook2SAPMap = new Map<String, String>();
    private Map<String, String> existingPriceBookEntrySAPMap = new Map<String, String>();

    public SAP_GET_PriceBookEntries(String instanceRegion) {
        this.sapInstance = SAP_InstanceFactory.getInstance(instanceRegion);
    }

    public SAP_GET_PriceBookEntries(String instanceRegion, Map<String,String> requestParamsMap) {
        this(instanceRegion);
        this.requestParamsMap = requestParamsMap;
    }

    public void sync(){
        try {
            callSAP();
            parseResponse();
            createPriceBookEntry();
       } catch (Exception e) {
            new Logger('PriceBookEntry', 'SAP GET', sapInstance.regionKeyWord).error(e).create();
       }
    }

    private void callSAP(){
        String endpoint = SAP_Endpoints.buildEndpointWithParams(sapInstance.getPriceBookEntriesEndpoint, requestParamsMap);

        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:'+ endpoint);
        req.setMethod('GET');
        req.setTimeout(120000); 
        Http http = new Http();
        sapResponse = http.send(req);
    }

    private void parseResponse(){
        if(sapResponse.getStatusCode() == HttpStatusCode.OK) {
            ISAP_PARSER_PriceBookEntry parser = (ISAP_PARSER_PriceBookEntry)Type.forName(sapInstance.priceBookEntryParser).newInstance();
            responses = parser.parse(sapResponse.getBody());
        }else{
           Logger log = new Logger('PriceBookEntry', 'SAP', sapInstance.regionKeyWord);
           log.stack = 'SAP_GET_PriceBookEntries, invalid response';
           log.message = String.valueOf(sapResponse.getStatusCode());
           log.create();
        }
    }
   
    private void createPriceBookEntry(){
        if(!responses.isEmpty()){
            createRecordMaps(responses);

            List<PricebookEntry> pricebookToInsert = new List<PricebookEntry>();
            List<PricebookEntry> pricebookToUpdate = new List<PricebookEntry>();
           
            for(ISAP_PARSER_PriceBookEntry response : responses){

                PricebookEntry pbEntry = new PricebookEntry();
                pbEntry.IsActive = response.getIsActive();
                pbEntry.SAP_Code__c = response.getPriceBookEntryCode();
                pbEntry.UnitPrice = response.getPrice();

                String pbEntrySFId = existingPriceBookEntrySAPMap.get(pbEntry.SAP_Code__c);

                if(pbEntrySFId == null){
                    pbEntry.Pricebook2Id = priceBook2SAPMap.get(response.getPriceBookCode());
                    pbEntry.Product2Id = product2SAPMap.get(response.getProduct2Code());
                    pricebookToInsert.add(pbEntry);
                }else{
                    pbEntry.Id = pbEntrySFId;
                    pricebookToUpdate.add(pbEntry);
                }
            }
            
            if(!pricebookToInsert.isEmpty()){
                List<Database.SaveResult> insertResult = Database.Insert(pricebookToInsert, false);
                
                String stackTrace = new DmlException().getStackTraceString();
                for(String errorMessage : ExceptionDataProcessor.getSaveResultErrorDetails(insertResult, pricebookToInsert, PricebookEntry.SAP_Code__c)){
                    new Logger('PricebookEntry insert', 'SAP GET', sapInstance.regionKeyWord).errorString(errorMessage, stackTrace).create();
                }
            }

            if(!pricebookToUpdate.isEmpty()){
                List<Database.SaveResult> updateResult = Database.Update(pricebookToUpdate, false);
                
                String stackTrace = new DmlException().getStackTraceString();
                for(String errorMessage : ExceptionDataProcessor.getSaveResultErrorDetails(updateResult, pricebookToUpdate, PricebookEntry.SAP_Code__c)){
                    new Logger('PricebookEntry update', 'SAP GET', sapInstance.regionKeyWord).errorString(errorMessage, stackTrace).create();
                 }
            }
        }
    }
    
    private void createRecordMaps(List<ISAP_PARSER_PriceBookEntry> responses) {
        Set<String> priceBook2Codes = new Set<String>();
        Set<String> product2Codes = new Set<String>();
        Set<String> priceBookEntryCodes = new Set<String>();
        
        for(ISAP_PARSER_PriceBookEntry response : responses) {
            priceBook2Codes.add(response.getPriceBookCode());
            product2Codes.add(response.getProduct2Code());
            priceBookEntryCodes.add(response.getPriceBookEntryCode());
        }
        
        if(priceBook2Codes.size() > 0){
            getPricebook2SAPMap(priceBook2Codes);
        }

        if(product2Codes.size() > 0){
            getProduct2SAPMap(product2Codes);
        }
        
        if(priceBookEntryCodes.size() > 0){
            getExistingPriceBookEntrySAPMap(priceBookEntryCodes);
        }
        
    }

    private void getPricebook2SAPMap(Set<String> priceBook2Codes){
        for(Pricebook2 pricebook : [
            SELECT Id, SAP_Code__c 
            FROM Pricebook2
            WHERE SAP_Code__c IN :priceBook2Codes
        ]){
            priceBook2SAPMap.put(pricebook.SAP_Code__c, pricebook.Id);
        }
    }
            
    private void getProduct2SAPMap(Set<String> product2Codes){
        for(Product2 product : [
            SELECT Id, SAP_Code__c 
            FROM Product2
            WHERE SAP_Code__c IN :product2Codes
        ]){
            product2SAPMap.put(product.SAP_Code__c, product.Id);
        }
    }
    
    private void getExistingPriceBookEntrySAPMap(Set<String> priceBookEntryCodes){
        for(PricebookEntry pbentry:[
            SELECT Id, SAP_Code__c 
            FROM PricebookEntry 
            WHERE SAP_Code__c IN :priceBookEntryCodes]){
            existingPriceBookEntrySAPMap.put(pbentry.SAP_Code__c, pbentry.Id);
        }
    }
}