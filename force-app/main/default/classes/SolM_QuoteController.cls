public with sharing class SolM_QuoteController {
    public Quote Quote { get; set; }
    public String subject { get; set; }
    public String body { get; set; }
    public String toAddress { get; set; }
    public Id contentDocumentId { get; set; }

    private ApexPages.StandardController stdController;

    public SolM_QuoteController(ApexPages.StandardController controller) {
        this.stdController = controller;
        this.Quote = [
            SELECT Id, Name, AccountId, ContactId, TotalPrice, Offer_Validity__c,
                   (SELECT Id, Product2.Name, Quantity, UnitPrice, TotalPrice FROM QuoteLineItems)
            FROM Quote
            WHERE Id = :controller.getId()
            LIMIT 1
        ];

        // Pre-fill email fields
        if (Quote.ContactId != null) {
            Contact c = [SELECT Id, Name, Email FROM Contact WHERE Id = :Quote.ContactId LIMIT 1];
            this.toAddress = c.Email;
            this.subject = 'Quote ' + Quote.Name + ' from Sol-Millennium';
            this.body = 'Dear ' + c.Name + ',\n\nPlease find attached the quotation for your review.\n\nKind regards,\nSol-Millennium Team';
        } else {
            this.toAddress = '';
            this.subject = 'Quote ' + Quote.Name + ' from Sol-Millennium';
            this.body = 'Please find attached the quotation for your review.';
        }

        // Check if docId is passed (from Save & Email)
        String docIdParam = ApexPages.currentPage().getParameters().get('docId');
        if (docIdParam != null) {
            try { this.contentDocumentId = Id.valueOf(docIdParam); } catch (Exception e) {}
        }
    }

    // Generate PDF blob from VF page
    private Blob getPdfBlob(Id quoteId) {
        PageReference pdfPage = Page.SolM_Quote_PDF;
        pdfPage.getParameters().put('id', String.valueOf(quoteId));
        try {
            return pdfPage.getContentAsPDF();
        } catch (Exception ex) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error generating PDF: ' + ex.getMessage()));
            throw ex;
        }
    }

    // Save PDF as ContentVersion and attach to Quote
    private Id savePdfToFiles(Blob pdfBlob, String fileName, Id linkedEntityId) {
        ContentVersion cv = new ContentVersion();
        cv.Title = fileName;
        cv.PathOnClient = fileName;
        cv.VersionData = pdfBlob;
        insert cv;

        ContentVersion cv2 = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];
        Id docId = cv2.ContentDocumentId;

        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = docId;
        cdl.LinkedEntityId = linkedEntityId;
        cdl.ShareType = 'V';
        cdl.Visibility = 'AllUsers';
        insert cdl;

        return docId;
    }

    // Button 1: Save to Quote
    public PageReference saveToQuote() {
        try {
            Blob pdf = getPdfBlob(this.Quote.Id);
            String fileName = 'Quote_' + this.Quote.Name + '.pdf';
            Id docId = savePdfToFiles(pdf, fileName, this.Quote.Id);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'PDF generated and attached to Quote.'));
            PageReference pr = new PageReference('/' + this.Quote.Id);
            pr.setRedirect(true);
            return pr;
        } catch (Exception ex) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Failed to save PDF: ' + ex.getMessage()));
            return null;
        }
    }

    // Button 2: Save & Email
    public PageReference saveAndOpenEmail() {
        try {
            Blob pdf = getPdfBlob(this.Quote.Id);
            String fileName = 'Quote_' + this.Quote.Name + '.pdf';
            Id docId = savePdfToFiles(pdf, fileName, this.Quote.Id);

            PageReference emailPage = Page.SolM_QuoteEmail;
            emailPage.getParameters().put('id', String.valueOf(this.Quote.Id));
            emailPage.getParameters().put('docId', String.valueOf(docId));
            emailPage.setRedirect(true);
            return emailPage;
        } catch (Exception ex) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Failed to prepare email: ' + ex.getMessage()));
            return null;
        }
    }

    // Send email (from the email VF page)
    public PageReference sendEmailFromVF() {
        if (String.isBlank(this.toAddress)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please specify a recipient email.'));
            return null;
        }
        if (this.contentDocumentId == null) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Attachment not found. Please generate the PDF first.'));
            return null;
        }

        try {
            ContentVersion cv = [
                SELECT VersionData, Title
                FROM ContentVersion
                WHERE ContentDocumentId = :this.contentDocumentId
                ORDER BY VersionNumber DESC
                LIMIT 1
            ];

            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(this.toAddress.split(','));
            mail.setSubject(this.subject);
            mail.setPlainTextBody(this.body);

            Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
            attachment.setFileName(cv.Title);
            attachment.setBody(cv.VersionData);
            mail.setFileAttachments(new Messaging.EmailFileAttachment[] { attachment });

            mail.setSaveAsActivity(false);
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });

            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'Email sent successfully.'));
            PageReference pr = new PageReference('/' + this.Quote.Id);
            pr.setRedirect(true);
            return pr;
        } catch (Exception ex) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Failed to send email: ' + ex.getMessage()));
            return null;
        }
    }

    // Cancel button → go back to Quote
    public PageReference cancel() {
        PageReference pr = new PageReference('/' + this.Quote.Id);
        pr.setRedirect(true);
        return pr;
    }
}