@RestResource(urlMapping='/lead-convert')     // /services/apexrest/lead-convert
global with sharing class LeadConvertRest {

    /* ---------- data-transfer objects ---------- */
    global class EmailRequest {
        public String email;
    }
    global class ConvertResponse {
        public String status;     // NO_LEAD_FOUND | SUCCESS | ERROR
        public String contactId;  // set on SUCCESS
        public String message;    // optional error text
    }

    /* ---------- POST handler ---------- */
    @HttpPost
    global static ConvertResponse doPost() {
        // 1. Parse JSON body
        EmailRequest input = (EmailRequest)JSON.deserialize(
            RestContext.request.requestBody.toString(),
            EmailRequest.class
        );

        ConvertResponse res = new ConvertResponse();

        if (String.isBlank(input.email)) {
            res.status  = 'ERROR';
            res.message = 'Email is required';
            return res;
        }

        // 2. Find a Lead with that email
        Lead[] leads = [
            SELECT Id, Company, LastName, FirstName, Status
            FROM   Lead
            WHERE  Email = :input.email
            LIMIT  1
        ];

        if (leads.isEmpty()) {
            res.status  = 'NO_LEAD_FOUND';
            res.message = 'No Lead with that email';
            return res;
        }

        // 3. Convert Lead → Person Account (no Opportunity)
        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(leads[0].Id);
        lc.setDoNotCreateOpportunity(true);
        lc.setConvertedStatus(getConvertedStatus());

        Database.LeadConvertResult lcr = Database.convertLead(lc, true);

        if (lcr.isSuccess()) {
            res.status    = 'SUCCESS';
            res.contactId = lcr.getContactId();   // Person-Account contact
        } else {
            res.status  = 'ERROR';
            res.message = String.join(lcr.getErrors(), '; ');
        }
        return res;
    }

    /* ---------- helper ---------- */
    private static String getConvertedStatus() {
        for (Schema.PicklistEntry pe :
             Lead.Status.getDescribe().getPicklistValues()) {
            if (pe.isActive() && pe.getLabel().contains('Converted')) {
                return pe.getValue();
            }
        }
        return 'Qualified';   // fallback—adjust if needed
    }
}