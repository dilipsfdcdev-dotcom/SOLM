@RestResource(urlMapping='/shopify/warranty')
global with sharing class ShopifyWarrantyEndpoint {

    global class WarrantyPayload {
        public String fullName;
        public String email;
        public String phone;
        public String purchasedDate;
        public String serialNumber;
        public String source;
        public String country;
    }

    @HttpPost
    global static void createWarranty() {
        String raw = RestContext.request.requestBody.toString();
        if (String.isBlank(raw)) {
            RestContext.response.statusCode = 400;
            return;
        }

        List<WarrantyPayload> payloads =
            (raw.trim().startsWith('['))
            ? (List<WarrantyPayload>)JSON.deserialize(raw, List<WarrantyPayload>.class)
            : new List<WarrantyPayload>{ (WarrantyPayload)JSON.deserialize(raw, WarrantyPayload.class) };

        Set<String> allEmails = new Set<String>();
        for (WarrantyPayload p : payloads)
            if (String.isNotBlank(p.email)) allEmails.add(p.email.trim().toLowerCase());

        Map<String, Id> emailToAccount = new Map<String, Id>();
        if (!allEmails.isEmpty()) {
            for (Account a : [
                SELECT Id, PersonEmail
                FROM Account
                WHERE IsPersonAccount = TRUE
                AND PersonEmail IN :allEmails
            ]) {
                emailToAccount.put(a.PersonEmail.toLowerCase(), a.Id);
            }
        }

        Set<String> missingEmails = new Set<String>(allEmails);
        missingEmails.removeAll(emailToAccount.keySet());

        Id personRtId;
        List<RecordType> rt = [
            SELECT Id
            FROM RecordType
            WHERE SObjectType = 'Account'
            AND IsPersonType = TRUE
            AND IsActive = TRUE
            LIMIT 1
        ];
        if (!rt.isEmpty()) personRtId = rt[0].Id;
        if (personRtId == null) {
            RestContext.response.statusCode = 500;
            RestContext.response.responseBody =
                Blob.valueOf('No active Person Account record type found.');
            return;
        }

        if (!missingEmails.isEmpty()) {
            Map<String, Lead> emailToLead = new Map<String, Lead>();
            for (Lead l : [
                SELECT Id, Email, Company, Phone, LastName
                FROM Lead
                WHERE IsConverted = FALSE
                AND Email IN :missingEmails
                ORDER BY CreatedDate ASC
            ]) {
                String em = (l.Email == null) ? null : l.Email.toLowerCase();
                if (em != null && !emailToLead.containsKey(em))
                    emailToLead.put(em, l);
            }

            if (!emailToLead.isEmpty()) {

                // Map of form submissions by Lead Id
                Map<Id, List<Form_Submission__c>> leadIdToForms = new Map<Id, List<Form_Submission__c>>();
                for (Form_Submission__c fs : [
                    SELECT Id, Lead__c
                    FROM Form_Submission__c
                    WHERE Lead__c IN :emailToLead.values()
                ]) {
                    if (!leadIdToForms.containsKey(fs.Lead__c)) {
                        leadIdToForms.put(fs.Lead__c, new List<Form_Submission__c>());
                    }
                    leadIdToForms.get(fs.Lead__c).add(fs);
                }

                // Map of Cases by Lead Id
                Map<Id, List<Case>> leadIdToCases = new Map<Id, List<Case>>();
                for (Case c : [
                    SELECT Id, Lead__c
                    FROM Case
                    WHERE Lead__c IN :emailToLead.values()
                ]) {
                    if (!leadIdToCases.containsKey(c.Lead__c)) {
                        leadIdToCases.put(c.Lead__c, new List<Case>());
                    }
                    leadIdToCases.get(c.Lead__c).add(c);
                }

                // Get converted lead status
                String convertedStatus;
                for (LeadStatus ls : [
                    SELECT MasterLabel
                    FROM LeadStatus
                    WHERE IsConverted = TRUE
                    LIMIT 1
                ]) {
                    convertedStatus = ls.MasterLabel;
                    break;
                }

                List<Lead> leadsOrdered = new List<Lead>(emailToLead.values());
                List<Account> stubs = new List<Account>();
                for (Lead l : leadsOrdered) {
                    Account pa = new Account();
                    pa.RecordTypeId = personRtId;
                    pa.LastName = String.isNotBlank(l.LastName) ? l.LastName : 'Unknown';
                    pa.PersonEmail = l.Email;
                    pa.PersonMobilePhone = l.Phone;
                    pa.Region__c = 'EMEA';
                    pa.Entity__c = 'SMFR';
                    pa.Branch__c = 'FR';
                    pa.AccountSource = 'Insujet';
                    stubs.add(pa);
                }
                insert stubs;

                Map<Id, Id> leadToStub = new Map<Id, Id>();
                for (Integer i = 0; i < leadsOrdered.size(); i++)
                    leadToStub.put(leadsOrdered[i].Id, stubs[i].Id);

                List<Database.LeadConvert> lcs = new List<Database.LeadConvert>();
                List<String> lcEmail = new List<String>();

                for (Lead l : leadsOrdered) {
                    if (String.isNotBlank(l.Company)) l.Company = null;

                    Database.LeadConvert lc = new Database.LeadConvert();
                    lc.setLeadId(l.Id);
                    lc.setAccountId(leadToStub.get(l.Id));
                    lc.setDoNotCreateOpportunity(true);
                    lc.setConvertedStatus(convertedStatus);

                    lcs.add(lc);
                    lcEmail.add(l.Email.toLowerCase());
                }

                Savepoint sp = Database.setSavepoint();
                Map<String, String> failed = new Map<String, String>();
                Set<Id> convertedLeadIds = new Set<Id>();
                List<Database.LeadConvertResult> res = Database.convertLead(lcs, false);

                for (Integer i = 0; i < res.size(); i++) {
                    Lead srcLead = leadsOrdered[i];
                    String em = lcEmail[i];

                    if (res[i] != null && res[i].isSuccess()) {
                        Id acctId = res[i].getAccountId();
                        emailToAccount.put(em, acctId);
                        missingEmails.remove(em);
                        convertedLeadIds.add(srcLead.Id);

                        if (leadIdToForms.containsKey(srcLead.Id)) {
                            for (Form_Submission__c fs : leadIdToForms.get(srcLead.Id))
                                fs.Account__c = acctId;
                            update leadIdToForms.get(srcLead.Id);
                        }

                        if (leadIdToCases.containsKey(srcLead.Id)) {
                            for (Case c : leadIdToCases.get(srcLead.Id)) {
                                c.AccountId = acctId;
                                c.Lead__c = null;
                            }
                            update leadIdToCases.get(srcLead.Id);
                        }

                    } else {
                        String msg = (res[i] == null) ? 'null result' : String.join(res[i].getErrors(), '; ');
                        failed.put(em, msg);
                    }
                }

                if (failed.isEmpty() && !convertedLeadIds.isEmpty()) {
                    try {
                        List<Lead> leadsToDelete = new List<Lead>();
                        for (Id lid : convertedLeadIds)
                            leadsToDelete.add(new Lead(Id = lid));
                        delete leadsToDelete;
                    } catch (Exception delEx) {
                        Database.rollback(sp);
                        RestContext.response.statusCode = 500;
                        RestContext.response.responseBody =
                            Blob.valueOf('Converted, but failed to delete Leads. Reason: ' + delEx.getMessage());
                        return;
                    }
                }

                if (!failed.isEmpty()) {
                    Database.rollback(sp);
                    RestContext.response.statusCode = 500;
                    RestContext.response.responseBody =
                        Blob.valueOf('Lead conversion failed for the following e-mail(s): ' +
                                     String.join(failed.keySet(), ', ') +
                                     '.  Reason(s): ' + String.join(failed.values(), ' | '));
                    return;
                }
            }
        }

        // Create new Person Accounts for any still-missing emails
        List<Account> accountsToInsert = new List<Account>();
        Map<String, WarrantyPayload> emailToPayload = new Map<String, WarrantyPayload>();

        for (WarrantyPayload p : payloads) {
            String em = String.isBlank(p.email) ? null : p.email.trim().toLowerCase();
            if (em != null && missingEmails.contains(em) && !emailToPayload.containsKey(em))
                emailToPayload.put(em, p);
        }

        for (String em : missingEmails) {
            WarrantyPayload src = emailToPayload.get(em);
            Account pa = new Account();
            pa.RecordTypeId = personRtId;
            pa.Region__c = 'EMEA';
            pa.Entity__c = 'SMFR';
            pa.Branch__c = 'FR';
            pa.AccountSource = 'Insujet';

            if (String.isNotBlank(src.fullName) && src.fullName.contains(' ')) {
                Integer split = src.fullName.indexOf(' ');
                pa.FirstName = src.fullName.substring(0, split).trim();
                pa.LastName = src.fullName.substring(split + 1).trim();
            } else {
                pa.LastName = String.isNotBlank(src.fullName) ? src.fullName.trim() : 'Unknown';
            }

            pa.PersonEmail = em;
            pa.PersonMobilePhone = src.phone;
            accountsToInsert.add(pa);
        }

        if (!accountsToInsert.isEmpty()) {
            insert accountsToInsert;
            for (Account a : accountsToInsert)
                emailToAccount.put(a.PersonEmail.toLowerCase(), a.Id);
        }

        // Create Warranty__c records and track Accounts to update if name mismatch
List<Warranty__c> warranties = new List<Warranty__c>();
Map<Id, Account> accountsToUpdate = new Map<Id, Account>();

for (WarrantyPayload p : payloads) {
    Warranty__c w = new Warranty__c();
    w.Full_Name__c = p.fullName;
    w.Email__c = p.email;
    w.Phone__c = p.phone;
    w.Serial_Number__c = p.serialNumber;
    w.Source__c = p.source;
    w.Country__c = p.country;

    if (String.isNotBlank(p.purchasedDate)) {
        try {
            w.Purchased_Date__c = Date.valueOf(p.purchasedDate);
        } catch (Exception ignore) {}
    }

    String emKey = String.isBlank(p.email) ? null : p.email.trim().toLowerCase();
    if (emKey != null && emailToAccount.containsKey(emKey)) {
        Id acctId = emailToAccount.get(emKey);
        w.Account__c = acctId;

        // Check and update account name if different from warranty name
        if (String.isNotBlank(p.fullName) && p.fullName.contains(' ')) {
            Integer split = p.fullName.indexOf(' ');
            String firstName = p.fullName.substring(0, split).trim();
            String lastName = p.fullName.substring(split + 1).trim();

            Account existing = [SELECT Id, FirstName, LastName FROM Account WHERE Id = :acctId LIMIT 1];
            if ((existing.FirstName != firstName || existing.LastName != lastName)
                && (String.isNotBlank(firstName) || String.isNotBlank(lastName))) {
                existing.FirstName = firstName;
                existing.LastName = lastName;
                accountsToUpdate.put(existing.Id, existing);
            }
        } else if (String.isNotBlank(p.fullName)) {
            Account existing = [SELECT Id, FirstName, LastName FROM Account WHERE Id = :acctId LIMIT 1];
            if (existing.FirstName != null || existing.LastName != p.fullName.trim()) {
                existing.FirstName = null;
                existing.LastName = p.fullName.trim();
                accountsToUpdate.put(existing.Id, existing);
            }
        }
    }

    warranties.add(w);
}

if (!accountsToUpdate.isEmpty()) update accountsToUpdate.values();
if (!warranties.isEmpty()) insert warranties;

RestContext.response.statusCode = 201;
    }
}