@isTest
private class SAP_GET_PriceBooks_TEST {
 
    @isTest
    private static void getPrice_NACA(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new NACA_MOCK());
        new SAP_GET_PriceBooks('NACA').sync();
        Test.stopTest();

        List<Pricebook2> pricebooks = [SELECT Id, SAP_Code__c FROM Pricebook2];
        List<Log__c> logs = [SELECT Id, Message__c FROM Log__c];

        System.assertEquals(0, logs.size(), 'No errors reported');
        System.assertEquals(2, pricebooks.size(), '2 PriceBooks created based on SAP response');
        System.assertNotEquals(null, pricebooks[0].SAP_Code__c, 'SAP Code present');
    }

    @isTest
    private static void getPriceBookBadResponse(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MOCK_SAP_NoAuthResponse());

        new SAP_GET_PriceBooks('NACA').sync();
        Test.stopTest();

        List<Log__c> logs = [SELECT Id, Message__c FROM Log__c];

        System.assertEquals(1, logs.size(), 'errors are reported');
        System.assertEquals(String.valueOf(HttpStatusCode.BAD_REQUEST), logs[0].Message__c, 'Response code present');
    }

    public class NACA_MOCK implements HttpCalloutMock{
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
                        '"ListNum": 59,' +
                        '"ListName": "Distributor Price List",' +
                        '"ValidFor": "Y",' +
                        '"PrimCurr": "$",' +
                        '"AddCurr2": "$",' +
                        '"AddCurr1": "$",' +
                        '"Channel_ECommerce": "Y",' +
                        '"Channel_CRM": "Y",' +
                        '"Channel_MarketPlaces": "Y"' +
                    '},' + 
                    '{' + 
                        '"ListNum": 60,' +
                        '"ListName": "Market Price List",' +
                        '"ValidFor": "Y",' +
                        '"PrimCurr": "$",' +
                        '"AddCurr2": "$",' +
                        '"AddCurr1": "$",' +
                        '"Channel_ECommerce": "Y",' +
                        '"Channel_CRM": "Y",' +
                        '"Channel_MarketPlaces": "Y"' +
                    '}' + 
                ']'; 
            }
    }
}