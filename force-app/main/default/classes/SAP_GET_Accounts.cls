public with sharing class SAP_GET_Accounts {
    private SAP_Instance sapInstance;
    private SAP_Setting__mdt sapSetting;

    Map<String,String> requestParamsMap;
    private List<ISAP_PARSER> responses = new List<ISAP_PARSER>();
    private HttpResponse sapResponse;

    private Map<String,Id> userSAPCodeMap;
    private Set<String> salesOwnersToSkipSet;

    public SAP_GET_Accounts(String instanceRegion) {
        this.sapInstance = SAP_InstanceFactory.getInstance(instanceRegion);
        this.sapSetting = SAP_Setting__mdt.getInstance(instanceRegion);
        buildSalesPersonSAPCodesMap();
        this.salesOwnersToSkipSet = SAPSettingHelper.buildSalesOwnersToSkipSet(this.sapSetting);
    }

    public SAP_GET_Accounts(String instanceRegion, Map<String,String> requestParamsMap) {
        this(instanceRegion);
        this.requestParamsMap = requestParamsMap;
    }
 
    public void sync(){
        try {
            callSAP();
            parseResponse();
            upsertAccounts();
       } catch (Exception e) {
            new Logger('Account', 'SAP GET', sapInstance.regionKeyWord).error(e).create();
       }
    }

    public void callSAP(){
        String endpoint = SAP_Endpoints.buildEndpointWithParams(sapInstance.accountsEndpoint, requestParamsMap);
        system.debug('endpoint-->'+endpoint);
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:'+ endpoint);
        req.setMethod('GET');
        req.setTimeout(120000); 
        Http http = new Http();
        system.debug('req-->'+req);
        sapResponse = http.send(req);
        system.debug('sapResponse-->'+sapResponse);
    }

    public void parseResponse(){
        system.debug('sapResponse.getStatusCode()-->'+sapResponse.getStatusCode());
        if(sapResponse.getStatusCode() == HttpStatusCode.OK) {
            ISAP_PARSER parser = (ISAP_PARSER)Type.forName(sapInstance.accountParser).newInstance();
            system.debug('sapResponse.getBody()-->'+sapResponse.getBody());
            responses = parser.parse(sapResponse.getBody());
		}else{
           Logger log = new Logger('Account', 'SAP GET', sapInstance.regionKeyWord);
           log.stack = 'SAP_GET_Accounts, invalid response';
           log.message = String.valueOf(sapResponse.getStatusCode());
           log.create();
        }
    }

    public void upsertAccounts(){
        if(!responses.isEmpty()){
            List<Account> accountsToUpsert = new List<Account>();

            for (ISAP_PARSER wrapper: responses){
                ISAP_AccountBuilder accountBuilder = (ISAP_AccountBuilder)Type.forName(sapInstance.accountBuilder).newInstance();
                
                accountBuilder.init(wrapper, userSAPCodeMap, sapSetting);

                if(salesOwnersToSkipSet.contains(accountBuilder.getSalesPersonCode())){
                    continue;
                }        
                
                accountsToUpsert.add(accountBuilder.build());
            }
            system.debug('accountsToUpsert-->'+accountsToUpsert);
            if(!accountsToUpsert.isEmpty()){
                List<Database.UpsertResult> upsertResult = Database.upsert(accountsToUpsert, Account.SAP_Code__c, false);
                String stackTrace = new DmlException().getStackTraceString();
                for(String errorMessage : ExceptionDataProcessor.getUpsertResultErrorDetails(upsertResult, accountsToUpsert, Account.SAP_Code__c)){
                    new Logger('Account', 'SAP GET', sapInstance.regionKeyWord).errorString(errorMessage, stackTrace).create();
                }
            }
        }
    }

    private void buildSalesPersonSAPCodesMap(){
        userSAPCodeMap = new Map<String, Id>();
        for(User user: getUsersList(sapInstance.userSAPCodeFieldName)){
            userSAPCodeMap.put((String) user.get(sapInstance.userSAPCodeField), user.Id);
        }
    }

    private List<User> getUsersList(String fieldName){
        return Database.query(
                String.format(
                    'SELECT Id, {0} FROM User WHERE {0} != null AND IsActive = TRUE',
                    new List<String>{
                            fieldName
                    }
                )
        );
    }
}