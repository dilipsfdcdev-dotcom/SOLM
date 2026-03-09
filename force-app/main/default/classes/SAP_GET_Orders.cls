public with sharing class SAP_GET_Orders {
    private SAP_Instance sapInstance;

    Map<String,String> requestParamsMap;
    private List<ISAP_PARSER> responses = new List<ISAP_PARSER>();
    private HttpResponse sapResponse;

    private Set<String> salesOwnersToSkipSet;

    public SAP_GET_Orders(String instanceRegion) {
        this.sapInstance = SAP_InstanceFactory.getInstance(instanceRegion);
        this.salesOwnersToSkipSet = SAPSettingHelper.buildSalesOwnersToSkipSet(SAP_Setting__mdt.getInstance(instanceRegion));
    }

    public SAP_GET_Orders(String instanceRegion, Map<String,String> requestParamsMap) {
        this(instanceRegion);
        this.requestParamsMap = requestParamsMap;
    }
     
    public void sync(){
       try {
            callSAP();
            parseResponse();
            upsertOrders();
        } catch (Exception e) {
            new Logger('Order', 'SAP GET', sapInstance.regionKeyWord).error(e).create();
        }
    }

    public void callSAP(){
        String endpoint = SAP_Endpoints.buildEndpointWithParams(sapInstance.orderEndpoint, requestParamsMap);

        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:'+ endpoint);
        req.setMethod('GET');
        req.setTimeout(120000); 
        Http http = new Http();
        sapResponse = http.send(req);
    }

    public void parseResponse(){
        if(sapResponse.getStatusCode() == HttpStatusCode.OK) {
            ISAP_PARSER parser = (ISAP_PARSER)Type.forName(sapInstance.orderParser).newInstance();
            responses = parser.parse(sapResponse.getBody());
		}else{
           Logger log = new Logger('Order', 'SAP GET', sapInstance.regionKeyWord);
           log.stack = 'SAP_GET_Orders, invalid response';
           log.message = String.valueOf(sapResponse.getStatusCode());
           log.create();
        }
    }

    public void upsertOrders(){
        if(!responses.isEmpty()){
            List<Order> ordersToUpsert = new List<Order>();
            List<OrderItem> orderProductsToUpsert = new List<OrderItem>();

            for (ISAP_PARSER wrapper: responses){
                ISAP_OrderBuilder orderBuilder = (ISAP_OrderBuilder)Type.forName(sapInstance.orderBuilder).newInstance();
                orderBuilder.init(wrapper);

                if(salesOwnersToSkipSet.contains(orderBuilder.getSalesPersonCode())){
                    continue;
                }

                ordersToUpsert.add(orderBuilder.buildOrder());
                orderProductsToUpsert.addAll(orderBuilder.buildOrderProducts());
            }
    
            if(!ordersToUpsert.isEmpty()){
                List<Database.UpsertResult> upsertResult = Database.upsert(ordersToUpsert, Order.SAP_Code__c, false);
                String stackTrace = new DmlException().getStackTraceString();
                for(String errorMessage : ExceptionDataProcessor.getUpsertResultErrorDetails(upsertResult, ordersToUpsert, Order.SAP_Code__c)){
                    new Logger('Order', 'SAP GET', sapInstance.regionKeyWord).errorString(errorMessage, stackTrace).create();
                }
            }

            if(!orderProductsToUpsert.isEmpty()){
                Map<String, OrderItem> orderProductsToUpsertBySAPCodes = new Map<String, OrderItem>();
                for(OrderItem orderItem : orderProductsToUpsert) {
                    orderProductsToUpsertBySAPCodes.put(orderItem.SAP_Code__c, orderItem);
                }

                List<OrderItem> allOrderItems = fetchOrderProductsBySAPCodes(orderProductsToUpsertBySAPCodes.keySet());
                List<OrderItem> orderItemsToReplace = new List<OrderItem>();
                List<OrderItem> orderItemsToReplaceWithIds = new List<OrderItem>();
                for(OrderItem oldOrderItem : allOrderItems) {
                    OrderItem newOrderItem = orderProductsToUpsertBySAPCodes.get(oldOrderItem.SAP_Code__c);
                    if(oldOrderItem.PricebookEntry.SAP_Code__c != newOrderItem.PricebookEntry.SAP_Code__c) {
                        orderProductsToUpsertBySAPCodes.remove(oldOrderItem.SAP_Code__c);
                        orderItemsToReplace.add(newOrderItem);
                        OrderItem newOrderItemWithId = newOrderItem.clone(false);
                        newOrderItemWithId.Id = oldOrderItem.Id;
                        orderItemsToReplaceWithIds.add(newOrderItemWithId);
                    }
                }
                orderProductsToUpsert = orderProductsToUpsertBySAPCodes.values();

                if(!orderProductsToUpsert.isEmpty()){
                    List<Database.UpsertResult> upsertResult = Database.upsert(orderProductsToUpsert, OrderItem.SAP_Code__c, false);
                    String stackTrace = new DmlException().getStackTraceString();
                    for(String errorMessage : ExceptionDataProcessor.getUpsertResultErrorDetails(upsertResult, orderProductsToUpsert, OrderItem.SAP_Code__c)){
                        new Logger('OrderItems', 'SAP GET', sapInstance.regionKeyWord).errorString(errorMessage, stackTrace).create();
                    }
                }

                if(!orderItemsToReplace.isEmpty()){
                    List<Database.DeleteResult> deleteResults = Database.delete(orderItemsToReplaceWithIds,false);
                    String stackTrace = new DmlException().getStackTraceString();
                    for(String errorMessage : ExceptionDataProcessor.getDeleteResultErrorDetails(deleteResults, orderItemsToReplace, OrderItem.SAP_Code__c)){
                        new Logger('OrderItems', 'SAP GET', sapInstance.regionKeyWord).errorString(errorMessage, stackTrace).create();
                    }

                    List<Database.SaveResult> saveResult = Database.Insert(orderItemsToReplace, false);
                    stackTrace = new DmlException().getStackTraceString();
                    for(String errorMessage : ExceptionDataProcessor.getSaveResultErrorDetails(saveResult, orderItemsToReplace, OrderItem.SAP_Code__c)){
                        new Logger('OrderItems', 'SAP GET', sapInstance.regionKeyWord).errorString(errorMessage, stackTrace).create();
                    }
                }
            }
        }
    }

    private List<OrderItem> fetchOrderProductsBySAPCodes(Set<String> sapCodes) {
        return [
                SELECT Id, SAP_Code__c, PricebookEntryId, PricebookEntry.SAP_Code__c
                FROM OrderItem
                WHERE SAP_Code__c IN :sapCodes
        ];
    }
}