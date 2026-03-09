@isTest
private class SAP_GET_Orders_TEST {

    @IsTest
    private static void upsertOrderForNACA(){
        String accSapCode = 'C0100';
        String accSapCodeWithPrefix = Constants.order.NACA_SAP_PREFIX + accSapCode;
        String productSapCode = '110101010001';
        String orderStatus = 'C'; //Closed
        String pricebookExternalId = 'TEST';

        Account acc = new TestHelper.AccountRecord()
            .asNACA()
            .setSAPCode(accSapCodeWithPrefix)
            .save();

        Pricebook2 customPricebook = new TestHelper.PricebookRecord().setSAPCode(pricebookExternalId).save();
        Product2 product = new TestHelper.ProductRecord().setSAPCode(productSapCode).save();
        Product2 tmpProduct = new TestHelper.ProductRecord().save();

        PricebookEntry tmpPbe = new TestHelper.PricebookEntryRecord(customPricebook.Id, tmpProduct.Id, 'EUR')
            .save();

        new TestHelper.PricebookEntryRecord(customPricebook.Id, product.Id, 'EUR')
                .setSAPCode(productSapCode + pricebookExternalId + 'EUR')
                .save();

        Order order = new TestHelper.OrderRecord()
                .setPricebookId(customPricebook.Id)
                .setSapCode('NACA-12345')
                .setCurrencyIsoCode('EUR')
                .save();
        new TestHelper.OrderItemRecord(product.Id, order.Id, tmpPbe.Id)
                .setSAPCode('NACA-12345-0').save();
  
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new NACA_MOCK(
            new Map<String,String>{
                'accSapCode' => accSapCode,
                'productSapCode' => productSapCode,
                'orderStatus' => orderStatus
            }
        ));

        new SAP_GET_Orders('NACA').sync();
        Test.stopTest();

        List<Order> orders = [
            SELECT id, SAP_Code__c, Status, EffectiveDate, EndDate, 
            (SELECT Id, SAP_Code__c, Status__c, Quantity, UnitPrice, Shipment_Date__c, Product2Id FROM OrderItems) 
            FROM Order 
            WHERE Account.SAP_Code__c = :accSapCodeWithPrefix
        ];

        List<Log__c> logs = [SELECT Id, Message__c, Stack_Trace__c FROM Log__c];
        System.assertEquals(0, logs.size(), 'No errors reported');

        System.assertEquals(1, orders.size());
        System.assertEquals(2, orders[0].OrderItems.size());

        System.assertNotEquals(null, orders[0].SAP_Code__c);
        System.assertNotEquals(null, orders[0].EffectiveDate);
        System.assertNotEquals(null, orders[0].EndDate);
        System.assertEquals(Constants.order.STATUS_CLOSED, orders[0].Status);

        for(OrderItem item: orders[0].OrderItems){
            System.assertNotEquals(null, item.SAP_Code__c);
            System.assertNotEquals(null, item.Shipment_Date__c);
            System.assertEquals(product.Id, item.Product2Id);
        }
    }

    @isTest
    private static void getOrderBadRequest(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MOCK_SAP_NoAuthResponse());

        new SAP_GET_Orders('NACA').sync();
        Test.stopTest();

        List<Log__c> logs = [SELECT Id, Message__c FROM Log__c];

        System.assertEquals(1, logs.size(), 'errors are reported');
        System.assertEquals(String.valueOf(HttpStatusCode.BAD_REQUEST), logs[0].Message__c, 'Response code present');
    }
 
    public class NACA_MOCK implements HttpCalloutMock{
        private Map<String, String> paramsMap;

        public NACA_MOCK(Map<String, String> paramsMap){
            this.paramsMap = paramsMap;
        }

        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(prepareBody());
            res.setStatusCode(200);
            return res;
        }
    
        private string prepareBody(){
            return '[' +
                        '{' + 
                            '"DocEntry": 12345,' +
                            '"DocNum": 66123,' +
                            '"CardCode": "' + paramsMap.get('accSapCode') + '",' +
                            '"CardName": "Test Account",' +
                            '"DocDate": "2022-05-30T00:00:00",' +
                            '"DocDueDate": "2022-06-30T00:00:00",' +
                            '"TaxDate": "2022-06-08T00:00:00",' +
                            '"DocStatus": "' + paramsMap.get('orderStatus') + '",' +
                            '"CANCELED": "N",' +
                            '"DocCur": "EUR",' +
                            '"SlpCode": 20,' +
                            '"SlpName": "Test Sales Rep",' +
                            '"Comments": "GND",' +
                            '"ExternalID1": "",' +
                            '"ExternalID2": "",' +
                            '"U_TipoPedido": "",' +
                            '"TranspName": "",' +
                            '"Carrier": "",' +
                            '"TotalExpns": "3780.00",' +
                            '"ShipToCode": "Test Account Shipping",' +
                            '"PayToCode": "Test Account Billing",' +
                            '"Confirmed": "Confirmed",' +
                            '"PymntGroup": "Net60-C",' +
                            '"PeyMethod": "",' +
                            '"Descript": "",' +
                            '"MainUsage": "",' +
                            '"Incoterms": "",' +
                            '"Header": "",' +
                            '"Itens": [' +
                                '{' +
                                    '"ItemCode": "' + paramsMap.get('productSapCode') + '",' +
                                    '"ItemName": "Test Product",' +
                                    '"Quantity": "25.00",' +
                                    '"Price": "100.00",' +
                                    '"DelivrdQty": "500.00",' +
                                    '"OpenCreQty": "0.00",' +
                                    '"LineStatus": "C",' +
                                    '"LineNum": "0",' + 
                                    '"TargetType": "Entrega",' +
                                    '"TrgetEntry": "23006",' +
                                    '"DiscPrcnt": "0.00",' +
                                    '"WhsCode": "SMUS.320",' +
                                    '"ShipDate": "2022-06-15T00:00:00",' +
                                    '"Usage": "",' +
                                    '"OrderItemNumber": ""' +
                                '},' +
                                '{' +
                                    '"ItemCode": "' + paramsMap.get('productSapCode') + '",' +
                                    '"ItemName": "Test Product",' +
                                    '"Quantity": "25.00",' +
                                    '"Price": "100.00",' +
                                    '"DelivrdQty": "500.00",' +
                                    '"OpenCreQty": "0.00",' +
                                    '"LineStatus": "C",' +
                                    '"LineNum": "1",' + 
                                    '"TargetType": "Entrega",' +
                                    '"TrgetEntry": "23006",' +
                                    '"DiscPrcnt": "0.00",' +
                                    '"WhsCode": "SMUS.320",' +
                                    '"ShipDate": "2022-06-30T00:00:00",' +
                                    '"Usage": "",' +
                                    '"OrderItemNumber": ""' +
                                '}' +
                            ']' +
                        '}' + 
                    ']'; 
           }
      }
}