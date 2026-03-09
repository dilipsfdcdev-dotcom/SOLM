@isTest
private class ENDPOINT_LeadTest {

    @isTest
    private static void newLeadEndpointTest(){
        setRestContext();
        setResponseContext();

        Test.startTest();
        ENDPOINT_Lead.insertLead();
        Test.stopTest();

        List<Lead> newLeads = [SELECT Id, LeadSource FROM Lead];

        System.assertEquals(1, newLeads.size());
        System.assertEquals(Constants.lead.SOURCE_SOL_M_WEBPAGE, newLeads[0].LeadSource);
    }    

    private static void setResponseContext(){
        RestResponse res = new RestResponse();
        RestContext.response = res;
    }

    private static void setRestContext(){
        RestRequest req = new RestRequest();
        req.addHeader('httpMethod', 'POST');
        req.requestUri = '/services/apexrest/newLead';
        req.requestBody = Blob.valueOf('{"first_name":"test","last_name":"test","email":"test@test.com","phone":"123","company":"test","message":"test"}');
        RestContext.request = req;
    }
}