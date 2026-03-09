public class CaseTriggerHandler {
    
    public static void handleBeforeInsert(List<Case> newCases) {
        Set<String> emails = new Set<String>();
        Map<Id, String> caseIdToExtractedEmail = new Map<Id, String>();
        
        // Step 1: Extract email from Description using regex
        Pattern emailPattern = Pattern.compile('(?i)Sender Email:\\s*(\\S+@[\\w.-]+)');
        
        for (Case c : newCases) {
            if (c.Priority == 'Service Clients' && c.Description != null) {
                Matcher matcher = emailPattern.matcher(c.Description);
                if (matcher.find()) {
                    String extractedEmail = matcher.group(1).trim().toLowerCase();
                    emails.add(extractedEmail);
                    caseIdToExtractedEmail.put(c.Id, extractedEmail);
                }
            }
        }
        
        // Step 2: Fetch matching Accounts and Leads based on extracted emails
        Map<String, Account> emailToAccountMap = new Map<String, Account>();
        Map<String, Lead> emailToLeadMap = new Map<String, Lead>();
        
        if (!emails.isEmpty()) {
            for (Account acc : [
                SELECT Id, PersonEmail
                FROM Account
                WHERE IsPersonAccount = true
                AND AccountSource = 'Insujet'
                AND PersonEmail IN :emails
            ]) {
                if (acc.PersonEmail != null) {
                    emailToAccountMap.put(acc.PersonEmail.toLowerCase(), acc);
                }
            }
            
            for (Lead lead : [
                SELECT Id, Email
                FROM Lead
                WHERE Email IN :emails
                AND RecordType.DeveloperName = 'Insujet'
            ]) {
                if (lead.Email != null) {
                    emailToLeadMap.put(lead.Email.toLowerCase(), lead);
                }
            }
        }
        
        // Step 3: Set AccountId or Lead__c, Type__c, and SuppliedEmail using the extracted email
        for (Case c : newCases) {
            if (c.Priority == 'Service Clients' && caseIdToExtractedEmail.containsKey(c.Id)) {
                String email = caseIdToExtractedEmail.get(c.Id);
                
                if (emailToAccountMap.containsKey(email)) {
                    c.AccountId = emailToAccountMap.get(email).Id;
                    c.Type__c = 'insujet';
                } else if (emailToLeadMap.containsKey(email)) {
                    c.Lead__c = emailToLeadMap.get(email).Id;
                    c.Type__c = 'insujet';
                }
                
                // Always set SuppliedEmail from extracted value
                c.SuppliedEmail = email;
            }
        }
    }
    
    public static void handleFormSubmissionCloseOnCaseClose(List<Case> newList, Map<Id, Case> oldMap) {
        if (newList == null || newList.isEmpty()) return;
        
        // Collect subjects from qualifying cases
        Set<String> subjectsToClose = new Set<String>();
        for (Case c : newList) {
            if (
                c != null &&
                c.Type__c == 'insujet' &&
                c.Status == 'Closed' &&
                c.Subject != null &&
                oldMap != null &&
                oldMap.containsKey(c.Id) &&
                oldMap.get(c.Id) != null &&
                oldMap.get(c.Id).Status != 'Closed'
            ) {
                subjectsToClose.add(c.Subject);
            }
        }
        
        if (subjectsToClose.isEmpty()) return;
        
        // Query all form submissions with matching subjects (skip ones already Closed)
        List<Form_Submission__c> formsToUpdate = [
            SELECT Id, Subject__c, Status__c
            FROM Form_Submission__c
            WHERE Subject__c IN :subjectsToClose
        ];
        
        if (formsToUpdate.isEmpty()) return;
        
        // Set status to Closed in bulk
        for (Form_Submission__c fs : formsToUpdate) {
            fs.Status__c = 'Closed';
        }
        
        try {
            update formsToUpdate;
        } catch (DmlException e) {
            System.debug('Error updating Form_Submission__c to Closed: ' + e.getMessage());
        }
    }
    
    public static void handleExecutiveFlagUpdate(List<Case> newList, Map<Id, Case> oldMap, Boolean isInsert, Boolean isUpdate) {
        Set<String> emailSet = new Set<String>();
        if (!String.isEmpty(Label.Executive_Email_Addresses)) {
            emailSet.addAll(Label.Executive_Email_Addresses.split(';'));
        }
        
        List<Case> casesToUpdate = new List<Case>();
        
        for (Case c : newList) {
            Case oldCase = isUpdate ? oldMap.get(c.Id) : null;
            
            Boolean meetsEmailCondition = (
                c.SuppliedEmail != null &&
                emailSet.contains(c.SuppliedEmail) &&
                (
                    isInsert || 
                    (isUpdate && oldCase != null && c.SuppliedEmail != oldCase.SuppliedEmail)
                )
            );
            
            Boolean meetsTypeCondition = c.Type__c == 'Standard Cost Maintanence';
            
            if (meetsEmailCondition || meetsTypeCondition) {
                casesToUpdate.add(new Case(
                    Id = c.Id,
                    Executive_Request__c = true,
                    Urgent__c = true,
                    Case_Priority__c = 'Urgent'
                ));
            }
        }
        
        if (!casesToUpdate.isEmpty()) {
            try {
                update casesToUpdate;
            } catch (DmlException e) {
                System.debug('Error updating cases: ' + e.getMessage());
            }
        }
    }
}