public with sharing class OpportunityTriggerHandler extends TriggerHandler {
    
    public static void sendEmailToBuBasedOnProbablity(List<Opportunity> records, Map<Id, Opportunity> oldMap) {
        for (Opportunity newOpp : records) {
            Opportunity oldOpp = oldMap.get(newOpp.Id);
            
            // Check if the probability has been updated to either 80% or 90%
            if ((newOpp.Probability == 80 || newOpp.Probability == 90) && (oldOpp.Probability != 80 && oldOpp.Probability != 90)) {
                // Call the method to send the email
                sendEmailtoBu(newOpp.Id);
            }
        }
    }
    
    public static void sendEmailtoBu(String opportunityId){
        // Query the Opportunity and its related records
        Opportunity opp = [SELECT Id, Name, Amount, AccountId, Account.Name, CloseDate, OwnerId, Owner.Name, Probability
                           FROM Opportunity
                           WHERE Id = :opportunityId];
        // Build the HTML table header
        String htmlBody = '<p>Hello, an opportunity with SKUs tied to your BU has reached '+opp.Probability+'%!</p>' +
                          '<p>Please find the basic details below and if you need more information, ' +
                          'here is a link to the Opportunity: <a href="' + URL.getSalesforceBaseUrl().toExternalForm() + '/' + opp.Id + '">' + opp.Name + '</a></p>' +
                          '<p>Account: ' + opp.Account.Name + '<br>' +
                          'Opportunity: ' + opp.Name + '<br>' +
                          'Amount: ' + opp.Amount.format() + '<br>' +
                          'Owner: ' + opp.Owner.Name + '<br>' +
                          'Close Date: ' + opp.CloseDate.format() + '</p>' +
                          '<table border="1" style="border-collapse: collapse; width: 100%;">' +
                          '<tr>' +
                          '<th>Product</th><th>Product Code</th><th>Quantity</th><th>Sales Price</th><th>Product BU</th>' +
                          '</tr>';

        // Assume we have a list of opportunity line items
        // This would typically come from a SOQL query
        List<OpportunityLineItem> lineItems = [SELECT Product2.Name, ProductCode, Quantity, TotalPrice,Product2.BU__c
                                               FROM OpportunityLineItem 
                                               WHERE OpportunityId = :opportunityId];

        List<String> buValuesList = new List<String>();
        // Build the table rows for each line item
        for (OpportunityLineItem item : lineItems) {

            buValuesList.add(item.Product2.BU__c);

            htmlBody += '<tr>' +
                        '<td>' + item.Product2.Name + '</td>' +
                        '<td>' + item.ProductCode + '</td>' +
                        '<td>' + item.Quantity + '</td>' +
                        '<td>' + item.TotalPrice.format() + '</td>' +
                        '<td>' + item.Product2.BU__c + '</td>' +
                        '</tr>';
        }

        // Close the HTML table
        htmlBody += '</table>';

        List<String> emailIds = new List<String>();

        // Define a Map to relate BU prefixes to their respective email lists
        Map<String, List<String>> buEmailMap = new Map<String, List<String>>{
            'BU 1' => new List<String>{'mgitles@sol-m.com', 'jtyler@sol-m.com'},
            'BU 2' => new List<String>{'bmiles@sol-m.com', 'klombardo@sol-m.com'},
            'BU 3' => new List<String>{'csekema@sol-m.com', 'mharkness@sol-m.com'},
            'BU 4' => new List<String>{'Fiona@sol-m.com'}
        };

        for (String buValue : buValuesList) {
            // Check each defined BU prefix
            for (String buKey : buEmailMap.keySet()) {
                if (buValue.startsWith(buKey)) {
                    emailIds.addAll(buEmailMap.get(buKey));
                    break; // Stop checking after the first match to prevent unnecessary processing
                }
            }
        }
        // Create a single email message
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(emailIds); // Set the recipient address
        mail.setSubject('Opportunity Hits '+opp.Probability+'% -'+ opp.Name);
        mail.setHtmlBody(htmlBody); // Set the HTML body for the email

        // Send the email
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
    
    public override String getImplementationName(){
        return OpportunityTriggerHandler.class.getName();
    }

	public override void afterInsert(List<SObject> newRecordsList , Map<Id, SObject> newRecordsMap) {
        new OpportunityTenderLotRollupHelper(newRecordsMap, null)
            .getTendersOnLotInsert()
            .recalculateTenderRollupFields();

    }

	public override void afterUpdate(Map<Id, SObject> newRecordsMap, Map<Id, SObject> oldRecordsMap) {
        new OpportunityTenderLotRollupHelper(newRecordsMap, oldRecordsMap)
            .getTendersOnLotUpdate()
            .recalculateTenderRollupFields();
    }

	public override void afterDelete(Map<Id, SObject> oldRecordsMap) {
        new OpportunityTenderLotRollupHelper(null, oldRecordsMap)
            .getTendersOnLotDelete()
            .recalculateTenderRollupFields();
    }

	public override void beforeDelete(List<sObject> oldRecordsList, Map<Id, sObject> oldRecordsMap){
        new ForecastItemHelper().deactivateOpportunityItems(
            (new Map<Id,SObject>(
                [SELECT Id FROM OpportunityLineItem WHERE OpportunityId IN :oldRecordsMap.keySet()]
            )).keySet()
        );
	}
}