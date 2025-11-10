@isTest
private class SAP_GET_Accounts_TEST {

    @isTest
    private static void getAccounts_EMEA(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SAP_EMEA_GET_Accounts_MOCK());

        new SAP_GET_Accounts('EMEA').sync();
        Test.stopTest();

        List<Account> accounts = [SELECT Id, SAP_Code__c FROM Account];
        List<Log__c> logs = [SELECT Id, Message__c FROM Log__c];

       // System.assertEquals(0, logs.size(), 'No errors reported');
      //  System.assertEquals(2, accounts.size(), '2 Account created based on SAP response');
        //System.assertNotEquals(null, accounts[0].SAP_Code__c, 'SAP Code present');
    }

    @isTest
    private static void getAccounts_NACA(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SAP_NACA_GET_Accounts_MOCK());

        new SAP_GET_Accounts('NACA').sync();
        Test.stopTest();

        List<Account> accounts = [SELECT Id, SAP_Code__c FROM Account];
        List<Log__c> logs = [SELECT Id, Message__c FROM Log__c];
        
      //  System.assertEquals(0, logs.size(), 'No errors reported');
       // System.assertEquals(2, accounts.size(), '2 Account created based on SAP response');
       // System.assertNotEquals(null, accounts[0].SAP_Code__c, 'SAP Code present');
    }

    @isTest
    private static void skipInternalAccounts_NACA(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SAP_NACA_GET_Accounts_MOCK('SKIP'));

        new SAP_GET_Accounts('NACA').sync();
        Test.stopTest();

        List<Account> accounts = [SELECT Id, SAP_Code__c FROM Account];
        List<Log__c> logs = [SELECT Id, Message__c FROM Log__c];

       // System.assertEquals(0, logs.size(), 'No errors reported');
        //System.assertEquals(0, accounts.size(), 'Account skipped');
    }

    @isTest
    private static void getAccountsBadResponse(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MOCK_SAP_NoAuthResponse());

        new SAP_GET_Accounts('NACA').sync();
        Test.stopTest();

        List<Log__c> logs = [SELECT Id, Message__c FROM Log__c];

       // System.assertEquals(1, logs.size(), 'No errors reported');
       // System.assertEquals(String.valueOf(HttpStatusCode.BAD_REQUEST), logs[0].Message__c, 'Response code present');
    }
}