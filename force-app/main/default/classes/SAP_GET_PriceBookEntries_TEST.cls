@isTest
private class SAP_GET_PriceBookEntries_TEST {

    @isTest
    private static void insertNewPriceBookEntriesForNACA(){
        Pricebook2 priceBook16 = new TestHelper.PricebookRecord().setSAPCode('16 - NACA').build();
        Pricebook2 priceBook17 = new TestHelper.PricebookRecord().setSAPCode('17 - NACA').build();

        insert new List<Pricebook2>{
            priceBook16,
            priceBook17
        };
        
        Product2 product = new TestHelper.ProductRecord().setSAPCode('110101010001').save();
                
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new NACA_MOCK());

        new SAP_GET_PriceBookEntries('NACA').sync();
        Test.stopTest();

        List<PricebookEntry> pbeEntries = [SELECT Id, SAP_Code__c FROM PricebookEntry WHERE Pricebook2.IsStandard = false];
        List<Log__c> logs = [SELECT Id, Message__c FROM Log__c];

        System.assertEquals(0, logs.size(), 'No errors reported');
        System.assertEquals(2, pbeEntries.size());
        System.assertNotEquals(null, pbeEntries[0].SAP_Code__c, 'SAP Code present');
    }

    @isTest
    private static void insertUpdatePriceBookEntriesForNACA(){
        Pricebook2 priceBook16 = new TestHelper.PricebookRecord().setSAPCode('16 - NACA').build();
        Pricebook2 priceBook17 = new TestHelper.PricebookRecord().setSAPCode('17 - NACA').build();

        insert new List<Pricebook2>{
            priceBook16,
            priceBook17
        };
        
        Product2 product = new TestHelper.ProductRecord().setSAPCode('110101010001').save();

        new TestHelper.PricebookEntryRecord(priceBook16.Id, product.Id)
            .setSAPCode('110101010001' + '16' + 'USD')
            .save();
                
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new NACA_MOCK());

        new SAP_GET_PriceBookEntries('NACA').sync();
        Test.stopTest();

        List<PricebookEntry> pbeEntries = [SELECT Id, SAP_Code__c, UnitPrice FROM PricebookEntry WHERE Pricebook2.IsStandard = false];
        List<Log__c> logs = [SELECT Id, Message__c FROM Log__c];

        System.assertEquals(0, logs.size(), 'No errors reported');
        System.assertEquals(2, pbeEntries.size());

        for(PricebookEntry pbe: pbeEntries){
            System.assertNotEquals(null, pbe.SAP_Code__c, 'SAP Code present');
            System.assertEquals(6.00, pbe.UnitPrice, 'Unit Price synced with SAP');
        }
    }

    @isTest
    private static void getPriceBookEntriesBadRequest(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MOCK_SAP_NoAuthResponse());

        new SAP_GET_PriceBookEntries('NACA').sync();
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
                            '"ListNum": 16,' +
                            '"ListName": "Price List 16",' +
                            '"PricePCS": "6.00",' +
                            '"Price": "60.00",' +
                            '"ItemCode": "110101010001",' +
                            '"Channel_ECommerce": "Y",' +
                            '"Channel_CRM": "Y",' +
                            '"Channel_MarketPlaces": "Y"' +
                        '},' + 
                        '{' + 
                            '"ListNum": 17,' +
                            '"ListName": "Price List 17",' +
                            '"PricePCS": "6.00",' +
                            '"Price": "60.00",' +
                            '"ItemCode": "110101010001",' +
                            '"Channel_ECommerce": "Y",' +
                            '"Channel_CRM": "Y",' +
                            '"Channel_MarketPlaces": "Y"' +
                        '}' + 
                    ']'; 
           }
      }
}