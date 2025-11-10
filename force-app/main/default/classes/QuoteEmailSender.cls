public with sharing class QuoteEmailSender {
    public class EmailRequest {
        @InvocableVariable(required=true label='Quote Id')
        public Id quoteId;

        @InvocableVariable(label='To Addresses (comma-separated)')
        public String toAddresses;

        @InvocableVariable(label='CC Addresses (comma-separated)')
        public String ccAddresses;

        @InvocableVariable(label='Subject')
        public String subject;

        @InvocableVariable(label='Body (plain text or HTML)')
        public String body;
    }

    @InvocableMethod(label='Send Quote PDF Email (Customizable)'
                     description='Send the most recent Quote PDF to provided email addresses with custom subject/body.')
    public static void sendCustomQuoteEmail(List<EmailRequest> requests) {
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();

        for (EmailRequest req : requests) {
            try {
                // Fetch most recent Quote PDF
                QuoteDocument qDoc = [
                    SELECT Id, Document, CreatedDate
                    FROM QuoteDocument
                    WHERE QuoteId = :req.quoteId
                    ORDER BY CreatedDate DESC
                    LIMIT 1
                ];

                Quote q = [SELECT Name FROM Quote WHERE Id = :req.quoteId LIMIT 1];

                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

                // To / CC parsing
                if (req.toAddresses != null && req.toAddresses.trim() != '') {
                    mail.setToAddresses(req.toAddresses.split('[,;\\s]+'));
                }
                if (req.ccAddresses != null && req.ccAddresses.trim() != '') {
                    mail.setCcAddresses(req.ccAddresses.split('[,;\\s]+'));
                }

                // Subject + Body
                String subj = (req.subject != null && req.subject != '') ? req.subject : 'Quote ' + q.Name;
                mail.setSubject(subj);

                if (req.body != null && (req.body.contains('<') || req.body.contains('\n'))) {
                    mail.setHtmlBody(req.body);
                } else {
                    mail.setPlainTextBody(req.body != null ? req.body : 'Please find your quote attached.');
                }

                // PDF attachment
                Messaging.EmailFileAttachment attach = new Messaging.EmailFileAttachment();
                attach.setFileName('Quote_' + q.Name + '.pdf');
                attach.setBody(qDoc.Document);
                attach.setContentType('application/pdf');
                mail.setFileAttachments(new Messaging.EmailFileAttachment[] { attach });

                mails.add(mail);

            } catch (Exception e) {
                System.debug('⚠️ Error sending custom quote email: ' + e.getMessage());
            }
        }

        if (!mails.isEmpty()) {
            Messaging.sendEmail(mails);
        }
    }
}