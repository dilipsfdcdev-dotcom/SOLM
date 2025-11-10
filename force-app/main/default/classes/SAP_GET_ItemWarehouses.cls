public with sharing class SAP_GET_ItemWarehouses {
    private SAP_Instance sapInstance;
    Map<String,String> requestParamsMap;
    private Map<String, String> warehouse2SAPMap = new Map<String, String>();
    private List<ISAP_PARSER_WarehouseParser> responses = new List<ISAP_PARSER_WarehouseParser>();
    private HttpResponse sapResponse;

    public SAP_GET_ItemWarehouses(String instanceRegion) {
        this.sapInstance = SAP_InstanceFactory.getInstance(instanceRegion);
    }

    public SAP_GET_ItemWarehouses(String instanceRegion, Map<String,String> requestParamsMap) {
        this(instanceRegion);
        this.requestParamsMap = requestParamsMap;
    }

    public void sync(){
        try {
            callSAP();
            parseResponse();
            upsertWarehouses();
       } catch (Exception e) {
            new Logger('WareHouse', 'SAP GET', sapInstance.regionKeyWord).error(e).create();
       }
    }

    public void callSAP(){
        String endpoint = SAP_Endpoints.buildEndpointWithParams(sapInstance.warehouseEndpoint, requestParamsMap);

        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:'+ endpoint);
        req.setMethod('GET');
        req.setTimeout(120000); 
        Http http = new Http();
        sapResponse = http.send(req);
    }

    public void parseResponse(){
        if(sapResponse.getStatusCode() == HttpStatusCode.OK) {
            ISAP_PARSER_WarehouseParser parser = (ISAP_PARSER_WarehouseParser)Type.forName(sapInstance.warehouseParser).newInstance();
           responses = parser.parse(sapResponse.getBody());
        }else{
           Logger log = new Logger('Warehouse', 'SAP GET', sapInstance.regionKeyWord);
           log.stack = 'SAP_GET_ItemWarehouses, invalid response';
           log.message = String.valueOf(sapResponse.getStatusCode());
           log.create();
        }
    }

    private void upsertWarehouses(){
        if(!responses.isEmpty()){
            Set<String> wareHouseCodes = new Set<String>();
            Set<String> wareHouseCodesDuplicate = new Set<String>();
            for(ISAP_PARSER_WarehouseParser response : responses) {
                wareHouseCodes.add(response.getWhsCode());
            }
            if(wareHouseCodes.size() > 0){
                getWarehouse2SAPMap(wareHouseCodes);
            }

            List<Warehouse__c> warehouseToInsert = new List<Warehouse__c>();
            List<Warehouse__c> warehouseToUpdate = new List<Warehouse__c>();
           
            for (ISAP_PARSER_WarehouseParser response : responses){
                if (!wareHouseCodesDuplicate.contains(response.getWhsCode()))
                {
                    wareHouseCodesDuplicate.add( response.getWhsCode());
                    Warehouse__c warehouse = new Warehouse__c();
                    warehouse.Active__c = true;
                    warehouse.Name = response.getWhsCode();
                    warehouse.SAP_Code__c = response.getWhsCode();
                    warehouse.Region_New__c = response.getRegion();
                    warehouse.Entity__c = (response.getWhsCode()).substringBefore('.');
    
                    String warehouseSFId = warehouse2SAPMap.get(warehouse.SAP_Code__c);
    
                    if(warehouseSFId == null){
                        warehouseToInsert.add(warehouse);
                    }else{
                        warehouse.Id = warehouseSFId;
                        warehouseToUpdate.add(warehouse);
                    }
                }

            }
            if(!warehouseToInsert.isEmpty()){
                List<Database.SaveResult> insertResult = Database.Insert(warehouseToInsert, false);
                
                String stackTrace = new DmlException().getStackTraceString();
                for(String errorMessage : ExceptionDataProcessor.getSaveResultErrorDetails(insertResult, warehouseToInsert, Warehouse__c.SAP_Code__c)){
                    new Logger('Warehouse insert', 'SAP GET', sapInstance.regionKeyWord).errorString(errorMessage, stackTrace).create();
                }
            }

            if(!warehouseToUpdate.isEmpty()){
                List<Database.SaveResult> updateResult = Database.Update(warehouseToUpdate, false);
                
                String stackTrace = new DmlException().getStackTraceString();
                for(String errorMessage : ExceptionDataProcessor.getSaveResultErrorDetails(updateResult, warehouseToUpdate, Warehouse__c.SAP_Code__c)){
                    new Logger('Warehouse update', 'SAP GET', sapInstance.regionKeyWord).errorString(errorMessage, stackTrace).create();
                 }
            }
        }
    }

    private void getWarehouse2SAPMap(Set<String> wareHouseCodes){
        for(Warehouse__c wh : [
            SELECT Id, SAP_Code__c 
            FROM Warehouse__c
            WHERE SAP_Code__c IN :wareHouseCodes
        ]){
            warehouse2SAPMap.put(wh.SAP_Code__c, wh.Id);
        }
    }
}