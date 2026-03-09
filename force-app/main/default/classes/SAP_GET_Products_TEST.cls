@isTest
private class SAP_GET_Products_TEST {
  
    @isTest
    private static void getProducts_NACA(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new NACA_MOCK());

        new SAP_GET_Products('NACA').sync();
        Test.stopTest();

        List<Log__c> logs = [SELECT Id, Message__c FROM Log__c];
        List<Product2> products = [SELECT Id, SAP_Code__c, ProductCode, NACA_Active__c, Product_Line__c FROM Product2];

        System.assertEquals(0, logs.size(), 'No errors reported');
        System.assertEquals(2, products.size(), '2 Products created based on SAP response');

        for(Product2 product: products){
            System.assertNotEquals(null, product.SAP_Code__c);
            System.assertNotEquals(null, product.ProductCode);
            System.assert(product.NACA_Active__c);
            System.assertNotEquals(null, product.Product_Line__c);
        }
    }

    @isTest
    private static void getProducts_EMEA(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new EMEA_MOCK());

        new SAP_GET_Products('EMEA').sync();
        Test.stopTest();

        List<Log__c> logs = [SELECT Id, Message__c FROM Log__c];
        List<Product2> products = [SELECT Id, SAP_Code__c, ProductCode, EMEA_Active__c FROM Product2];

        System.assertEquals(0, logs.size(), 'No errors reported');
        System.assertEquals(2, products.size(), '2 Products created based on SAP response');

        for(Product2 product: products){
            System.assertNotEquals(null, product.SAP_Code__c);
            System.assertNotEquals(null, product.ProductCode);
            System.assert(product.EMEA_Active__c);
        }
    }

    @isTest
    private static void getProductBadResponse(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MOCK_SAP_NoAuthResponse());

        new SAP_GET_Products('NACA').sync();
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
                            '"ItemCode": "101SAP",' +
                            '"ItemName": "Product 1",' +
                            '"SWW": "101",' +
                            '"OldItemCode": "101",' +
                            '"FrgnName": "Product 1",' +
                            '"ItmsGrpNam": "Items",' +
                            '"Active": "Y",' +
                            '"FirmName": "OEM",' +
                            '"NCMCode": "",' +
                            '"SalUnitMsr": "Case1200",' +
                            '"NumInSale": 1200.00,' +
                            '"SalPackMsr": "",' +
                            '"SalPackUn": 1.0,' +
                            '"Sheight1": "0.0000",' +
                            '"SWidth1": "0.0000",' +
                            '"SLength1": "0.0000",' +
                            '"SVolume": "3.00000",' +
                            '"SWeight": "0.000000",' +
                            '"UgpEntry": 3,' +
                            '"UgpName": "1-100-1200",' +
                            '"CodeBars": "",' +
                            '"U_LG_SETOR": "",' +
                            '"U_LG_SUBGProd": "",' +
                            '"U_LG_FamProd": "",' +
                            '"U_LG_EspProd": "",' +
                            '"SUomCode": "Case1200",' +
                            '"U_LG_FamProdName": "",' +
                            '"U_LG_EspProdName": "",' +
                            '"U_LG_SETORName": "",' +
                            '"U_LG_SUBGProdName": "",' +
                            '"Channel_ECommerce": "Y",' +
                            '"Channel_CRM": "Y",' +
                            '"Channel_MarketPlaces": "N",' +
                            '"U_box_Qty": "100",' +
                            '"U_C_Qty": "1200",' +
                            '"Segment": "Medication Delivery",' +
                            '"ProductLine": "Safety Winged Infusion Set",' +
                            '"Material": "Finished Product",' +
                            '"Branding": "Own Brand",' +
                            '"Category": "Infusion",' +
                            '"SubCategory": "Safety Butterfly Needle & Set (Shield Technology)"' +
                        '},' +
                        '{' +
                            '"ItemCode": "102SAP",' +
                            '"ItemName": "Product 2",' +
                            '"SWW": "102",' +
                            '"OldItemCode": "101",' +
                            '"FrgnName": "Product 2",' +
                            '"ItmsGrpNam": "Items",' +
                            '"Active": "Y",' +
                            '"FirmName": "OEM",' +
                            '"NCMCode": "",' +
                            '"SalUnitMsr": "Case1200",' +
                            '"NumInSale": 1200.00,' +
                            '"SalPackMsr": "",' +
                            '"SalPackUn": 1.0,' +
                            '"Sheight1": "0.0000",' +
                            '"SWidth1": "0.0000",' +
                            '"SLength1": "0.0000",' +
                            '"SVolume": "3.00000",' +
                            '"SWeight": "0.000000",' +
                            '"UgpEntry": 3,' +
                            '"UgpName": "1-100-1200",' +
                            '"CodeBars": "",' +
                            '"U_LG_SETOR": "",' +
                            '"U_LG_SUBGProd": "",' +
                            '"U_LG_FamProd": "",' +
                            '"U_LG_EspProd": "",' +
                            '"SUomCode": "Case1200",' +
                            '"U_LG_FamProdName": "",' +
                            '"U_LG_EspProdName": "",' +
                            '"U_LG_SETORName": "",' +
                            '"U_LG_SUBGProdName": "",' +
                            '"Channel_ECommerce": "Y",' +
                            '"Channel_CRM": "Y",' +
                            '"Channel_MarketPlaces": "N",' +
                            '"U_box_Qty": "",' +
                            '"U_C_Qty": "1200",' +
                            '"Segment": "Dyalisis and Respiratory Care",' +
                            '"ProductLine": "Non Invasive Ventilator",' +
                            '"Material": "Finished Product",' +
                            '"Branding": "OEM",' +
                            '"Category": "Respiratory Supplies & Devices",' +
                            '"SubCategory": "Portable Ventilator"' +
                        '}' +
                ']'; 
            }
        }


    public class EMEA_MOCK implements HttpCalloutMock{
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
                            '"ItemCode": "101SAP",' +
                            '"ItemName": "Product 1",' +
                            '"OldItemCode": "101",' +
                            '"ItmsGrpNam": "Items",' +
                            '"Active": "Y",' +
                            '"NumInSale": 200.00' +
                        '},' +
                        '{' +
                            '"ItemCode": "102SAP",' +
                            '"ItemName": "Product 2",' +
                            '"OldItemCode": "102",' +
                            '"ItmsGrpNam": "Items",' +
                            '"Active": "Y",' +
                            '"NumInSale": 100.00' +
                        '}' +
                ']'; 
            }
        }
}