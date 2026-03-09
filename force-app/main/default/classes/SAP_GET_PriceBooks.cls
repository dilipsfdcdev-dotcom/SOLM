public with sharing class SAP_GET_PriceBooks {
    private SAP_Instance sapInstance;
    Map<String,String> requestParamsMap;

    private List<ISAP_PARSER> responses = new List<ISAP_PARSER>();
    private HttpResponse sapResponse;

    public SAP_GET_PriceBooks(String instanceRegion) {
        this.sapInstance = SAP_InstanceFactory.getInstance(instanceRegion);
    }

    public SAP_GET_PriceBooks(String instanceRegion, Map<String,String> requestParamsMap) {
        this(instanceRegion);
        this.requestParamsMap = requestParamsMap;
    }

    public void sync(){
        try {
            callSAP();
            parseResponse();
            upsertPriceBooks();
       } catch (Exception e) {
            new Logger('PriceBook2', 'SAP GET', sapInstance.regionKeyWord).error(e).create();
       }
    }

    public void callSAP(){
        String endpoint = SAP_Endpoints.buildEndpointWithParams(sapInstance.getPriceBooksEndpoint, requestParamsMap);

        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:'+ endpoint);
        req.setMethod('GET');
        req.setTimeout(120000); 
        Http http = new Http();
        sapResponse = http.send(req);
    }

    public void parseResponse(){
        if(sapResponse.getStatusCode() == HttpStatusCode.OK) {
           ISAP_PARSER parser = (ISAP_PARSER)Type.forName(sapInstance.priceBookParser).newInstance();
           responses = parser.parse(sapResponse.getBody());
        }else{
           Logger log = new Logger('PriceBook2', 'SAP GET', sapInstance.regionKeyWord);
           log.stack = 'SAP_GET_PriceBooks, invalid response';
           log.message = String.valueOf(sapResponse.getStatusCode());
           log.create();
        }
    }

    private void upsertPriceBooks(){
        if(!responses.isEmpty()){
            List<Pricebook2> pricebookToUpsert = new List<Pricebook2>();

            for (ISAP_PARSER wrapper: responses){
                ISAP_PriceBookBuilder priceBookBuilder = (ISAP_PriceBookBuilder)Type.forName(sapInstance.priceBookBuilder).newInstance();
                pricebookToUpsert.add(priceBookBuilder.build(wrapper));
            }
    
            if(!pricebookToUpsert.isEmpty()){
                List<Database.UpsertResult> upsertResult = Database.upsert(pricebookToUpsert, Pricebook2.SAP_Code__c, false);
                String stackTrace = new DmlException().getStackTraceString();
                for(String errorMessage : ExceptionDataProcessor.getUpsertResultErrorDetails(upsertResult, pricebookToUpsert, Pricebook2.SAP_Code__c)){
                    new Logger('Pricebook2', 'SAP GET', sapInstance.regionKeyWord).errorString(errorMessage, stackTrace).create();
                }
            }
        }
    }
}