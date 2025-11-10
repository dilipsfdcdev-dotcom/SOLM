@RestResource(urlMapping='/newLead')
global with sharing class ENDPOINT_Lead {
 
    @HttpPost
    global static void insertLead(){
        RestRequest request = RestContext.request;
        RestResponse response = RestContext.response;

        Database.DMLOptions dmo = new Database.DMLOptions(); 
        dmo.assignmentRuleHeader.useDefaultRule = true;
        String json = request.requestBody.toString();

        try {
            if(String.isEmpty(json)){
                response.statusCode = HttpStatusCode.BAD_REQUEST;
            }else{
                Lead newLead = new Lead();
                ENDPOINT_LeadWrapper wrapper = (ENDPOINT_LeadWrapper) System.JSON.deserialize(json, ENDPOINT_LeadWrapper.class);
    
                newLead.RecordTypeId = Constants.lead.RECORD_TYPE_NACA_ID;
                newLead.FirstName = wrapper.first_name;
                newLead.LastName = wrapper.last_name;
                newLead.Company = wrapper.company;
                newLead.Phone = wrapper.phone;
                newLead.Email = wrapper.email;
                newLead.Description = wrapper.message;
                newLead.LeadSource = Constants.lead.SOURCE_SOL_M_WEBPAGE;
                newLead.Agreed_to_Privacy_Policy__c = true;
        
                newLead.setOptions(dmo);
                insert newLead;
    
                response.statusCode = HttpStatusCode.OK;
            }
       } catch (Exception e) {
            response.statusCode = HttpStatusCode.INTERNAL_SERVER_ERROR;
            response.responseBody = Blob.valueOf(e.getMessage());
            new Logger('Lead', 'sol-m.com contact form', 'NACA').errorString(e.getMessage(), json).create();
       }
    }
}