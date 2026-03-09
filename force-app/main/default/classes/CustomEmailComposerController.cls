public with sharing class CustomEmailComposerController {

    public class EmailTemplateDTO {
        @AuraEnabled public Id id;
        @AuraEnabled public String name;
        @AuraEnabled public String developerName;
    }

    public class RenderResult {
        @AuraEnabled public String subject;
        @AuraEnabled public String htmlBody;
        @AuraEnabled public String plainBody;
    }

    public class FromAddressOption {
        @AuraEnabled public String id;
        @AuraEnabled public String email;
        @AuraEnabled public String displayName;
        @AuraEnabled public String type; // 'owner' or 'orgwide'
    }

    /**
     * Returns active classic email templates:
     *  - In normal run: only from "Solcotton" email folder
     *  - In tests: from ANY folder (no folder filter to avoid Folder DML / missing folder issues)
     */
    @AuraEnabled(cacheable=true)
    public static List<EmailTemplateDTO> getActiveTemplates() {
        List<EmailTemplateDTO> results = new List<EmailTemplateDTO>();
        List<EmailTemplate> templates;

        if (Test.isRunningTest()) {
            // In tests, don't filter by folder – just return all active templates
            templates = [
                SELECT Id, Name, DeveloperName
                FROM EmailTemplate
                WHERE IsActive = true
                ORDER BY Name
                LIMIT 200
            ];
        } else {
            // In real org usage: restrict to Solcotton email folder
            List<Folder> solcottonFolders = [
                SELECT Id
                FROM Folder
                WHERE Name = 'Solcotton'
                  AND Type = 'Email'
                LIMIT 1
            ];
            if (solcottonFolders.isEmpty()) {
                // No Solcotton folder -> no templates
                return results;
            }
            Id solcottonFolderId = solcottonFolders[0].Id;

            templates = [
                SELECT Id, Name, DeveloperName
                FROM EmailTemplate
                WHERE IsActive = true
                  AND FolderId = :solcottonFolderId
                ORDER BY Name
                LIMIT 200
            ];
        }

        for (EmailTemplate et : templates) {
            EmailTemplateDTO dto = new EmailTemplateDTO();
            dto.id = et.Id;
            dto.name = et.Name;
            dto.developerName = et.DeveloperName;
            results.add(dto);
        }
        return results;
    }

    /**
     * Returns available "From" address options including:
     * - Record owner's email (for Form_Submission__c)
     * - All verified Org-Wide Email Addresses
     */
    @AuraEnabled(cacheable=true)
    public static List<FromAddressOption> getFromAddressOptions(Id recordId) {
        List<FromAddressOption> options = new List<FromAddressOption>();

        // Get record owner's email if recordId is provided
        if (recordId != null) {
            try {
                String sObjectType = recordId.getSObjectType().getDescribe().getName();

                // Query the owner's email dynamically
                String query = 'SELECT OwnerId, Owner.Email, Owner.Name FROM ' +
                               String.escapeSingleQuotes(sObjectType) +
                               ' WHERE Id = :recordId LIMIT 1';
                List<SObject> records = Database.query(query);

                if (!records.isEmpty()) {
                    SObject record = records[0];
                    String ownerEmail = (String)record.getSObject('Owner').get('Email');
                    String ownerName = (String)record.getSObject('Owner').get('Name');

                    if (!String.isBlank(ownerEmail)) {
                        FromAddressOption ownerOption = new FromAddressOption();
                        ownerOption.id = 'owner';
                        ownerOption.email = ownerEmail;
                        ownerOption.displayName = ownerName + ' (Record Owner)';
                        ownerOption.type = 'owner';
                        options.add(ownerOption);
                    }
                }
            } catch (Exception e) {
                // Silent fail - owner email might not be accessible
                System.debug('Could not fetch owner email: ' + e.getMessage());
            }
        }

        // Get all verified Org-Wide Email Addresses
        try {
            List<OrgWideEmailAddress> orgWideAddresses = [
                SELECT Id, Address, DisplayName
                FROM OrgWideEmailAddress
                WHERE IsVerified = true
                ORDER BY DisplayName, Address
                LIMIT 100
            ];

            for (OrgWideEmailAddress owa : orgWideAddresses) {
                FromAddressOption owaOption = new FromAddressOption();
                owaOption.id = owa.Id;
                owaOption.email = owa.Address;
                owaOption.displayName = String.isBlank(owa.DisplayName)
                    ? owa.Address
                    : owa.DisplayName + ' <' + owa.Address + '>';
                owaOption.type = 'orgwide';
                options.add(owaOption);
            }
        } catch (Exception e) {
            // Silent fail - org-wide addresses might not be accessible
            System.debug('Could not fetch org-wide email addresses: ' + e.getMessage());
        }

        return options;
    }

    /**
     * Renders a stored email template for the given record Id.
     * Uses recordId as whatId (related record), no whoId.
     */
    @AuraEnabled(cacheable=true)
    public static RenderResult loadTemplate(Id templateId, Id recordId) {
        if (templateId == null || recordId == null) {
            throw new AuraHandledException('Template Id and record Id are required.');
        }

        Messaging.SingleEmailMessage rendered =
            Messaging.renderStoredEmailTemplate(templateId, null, recordId);

        RenderResult res = new RenderResult();
        res.subject   = rendered.getSubject();
        res.htmlBody  = rendered.getHtmlBody();
        res.plainBody = rendered.getPlainTextBody();
        return res;
    }

    /**
     * Sends an email using the edited subject/body and relates it to the recordId.
     * Supports multiple recipients in To, CC, and BCC fields (comma-separated).
     * Supports sending from Org-Wide Email Address.
     */
    @AuraEnabled
    public static void sendMail(
        String toAddresses,
        String ccAddresses,
        String bccAddresses,
        String subject,
        String htmlBody,
        Id recordId,
        String fromAddressId
    ) {
        if (String.isBlank(toAddresses)) {
            throw new AuraHandledException('At least one To address is required.');
        }
        if (String.isBlank(subject)) {
            throw new AuraHandledException('Subject is required.');
        }
        if (String.isBlank(htmlBody)) {
            throw new AuraHandledException('Email body is required.');
        }

        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();

        // Set From address (Org-Wide Email Address)
        if (!String.isBlank(fromAddressId) && fromAddressId != 'owner') {
            try {
                email.setOrgWideEmailAddressId(Id.valueOf(fromAddressId));
            } catch (Exception e) {
                System.debug('Could not set org-wide email address: ' + e.getMessage());
                // Continue without setting org-wide address
            }
        }
        // If 'owner' is selected or no fromAddressId, email will be sent from current user

        // Parse and set To addresses (comma-separated)
        List<String> toList = parseEmailAddresses(toAddresses);
        if (toList.isEmpty()) {
            throw new AuraHandledException('At least one valid To address is required.');
        }
        email.setToAddresses(toList);

        // Parse and set CC addresses (comma-separated)
        if (!String.isBlank(ccAddresses)) {
            List<String> ccList = parseEmailAddresses(ccAddresses);
            if (!ccList.isEmpty()) {
                email.setCcAddresses(ccList);
            }
        }

        // Parse and set BCC addresses (comma-separated)
        if (!String.isBlank(bccAddresses)) {
            List<String> bccList = parseEmailAddresses(bccAddresses);
            if (!bccList.isEmpty()) {
                email.setBccAddresses(bccList);
            }
        }

        email.setSubject(subject);
        email.setHtmlBody(htmlBody);

        if (recordId != null) {
            email.setWhatId(recordId);   // relate email to the custom object record
        }

        email.setSaveAsActivity(true);

        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
    }

    /**
     * Helper method to parse comma-separated email addresses.
     * Trims whitespace and filters out empty strings.
     */
    private static List<String> parseEmailAddresses(String addresses) {
        List<String> result = new List<String>();
        if (String.isBlank(addresses)) {
            return result;
        }

        for (String addr : addresses.split(',')) {
            String trimmed = addr.trim();
            if (!String.isBlank(trimmed)) {
                result.add(trimmed);
            }
        }
        return result;
    }
}