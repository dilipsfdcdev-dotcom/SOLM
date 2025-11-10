public with sharing class SAP_GET_Products {
    private SAP_Instance sapInstance;
    Map<String,String> requestParamsMap;

    private List<ISAP_PARSER> responses = new List<ISAP_PARSER>();
    private HttpResponse sapResponse;

    public SAP_GET_Products(String instanceRegion) {
        this.sapInstance = SAP_InstanceFactory.getInstance(instanceRegion);
    }

    public SAP_GET_Products(String instanceRegion, Map<String,String> requestParamsMap) {
        this(instanceRegion);
        this.requestParamsMap = requestParamsMap;
    }

    public void sync(){
       try {
            callSAP();
            parseResponse();
            upsertProducts();
       } catch (Exception e) {
            new Logger('Product2', 'SAP GET', sapInstance.regionKeyWord).error(e).create();
       }
    }

    private void callSAP(){
        String endpoint = SAP_Endpoints.buildEndpointWithParams(sapInstance.getProductsEndpoint, requestParamsMap);

        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:'+ endpoint);
        req.setMethod('GET');
        req.setTimeout(120000); 
        Http http = new Http();
        sapResponse = http.send(req);
    }

    private void parseResponse(){
        if(sapResponse.getStatusCode() == HttpStatusCode.OK) {
           ISAP_PARSER parser = (ISAP_PARSER)Type.forName(sapInstance.productParser).newInstance();
           responses = parser.parse(sapResponse.getBody());
        }else{
           Logger log = new Logger('Product2', 'SAP GET', sapInstance.regionKeyWord);
           log.stack = 'SAP_GET_Products, invalid response';
           log.message = String.valueOf(sapResponse.getStatusCode());
           log.create();
        }
    }

    private void upsertProducts(){
        if(!responses.isEmpty()){
            List<Product2> productsToUpsert = new List<Product2>();

            for (ISAP_PARSER wrapper: responses){
                ISAP_ProductBuilder productBuilder = (ISAP_ProductBuilder)Type.forName(sapInstance.productBuilder).newInstance();
                productsToUpsert.add(productBuilder.build(wrapper));
            }
    
            if(!productsToUpsert.isEmpty()){
                List<Database.UpsertResult> upsertResult = Database.upsert(productsToUpsert, Product2.SAP_Code__c, false);
                String stackTrace = new DmlException().getStackTraceString();
                for(String errorMessage : ExceptionDataProcessor.getUpsertResultErrorDetails(upsertResult, productsToUpsert, Product2.SAP_Code__c)){
                    new Logger('Product2', 'SAP GET', sapInstance.regionKeyWord).errorString(errorMessage, stackTrace).create();
                }
            }
        }
    }
   
}