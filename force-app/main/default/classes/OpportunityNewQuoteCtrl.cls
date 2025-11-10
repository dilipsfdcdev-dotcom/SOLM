public with sharing class OpportunityNewQuoteCtrl {
    @AuraEnabled
    public static string saveQuote(Id opportunityId, Quote form) {
        Savepoint sp = Database.setSavepoint();
        String opportunityRecordTypeId = getOpportunityById(opportunityId).RecordTypeId;

        try {
            Quote newQuote = new QuoteBuilder (
                    form,
                    opportunityId,
                    Constants.quote.recordTypeIdByOpportunityRTId.get(opportunityRecordTypeId)
            )
            .setName()
            .setBilling()
            .setShipping()
            .save();

            copyLineItemsToQuote(opportunityId, newQuote.Id, opportunityRecordTypeId);

            return newQuote.Id;
        } catch (Exception e) {
            Database.rollback(sp);
            throw new AuraHandledException(e.getMessage());
        }
    }

    private static Opportunity getOpportunityById(Id opportunityId){
        return [SELECT Id, RecordTypeId FROM Opportunity WHERE Id =: opportunityId];
    }

    private class QuoteBuilder {
        private Quote newQuote;

        public QuoteBuilder(Quote form, Id opportunityId, Id quoteRecordTypeId) {
            this.newQuote = form;
            this.newQuote.OpportunityId = opportunityId;
            this.newQuote.RecordTypeId = quoteRecordTypeId;
        }

        public QuoteBuilder setName(){
            if(newQuote.Name == null){
                newQuote.Name = 'Autofill';
            }
            return this;
        }

        public QuoteBuilder setBilling() {
            Account billingAccount = getAccount(newQuote.Bill_To_Account__c);
            newQuote.BillingName = billingAccount.Name;
            newQuote.BillingStreet = billingAccount.BillingStreet;
            newQuote.BillingCity = billingAccount.BillingCity;
            newQuote.BillingState = billingAccount.BillingState;
            newQuote.BillingPostalCode = billingAccount.BillingPostalCode;
            newQuote.BillingCountry = billingAccount.BillingCountry;
            return this;
        }

        public QuoteBuilder setShipping() {
            Account shippingAccount = getAccount(newQuote.Ship_To_Account__c);
            newQuote.ShippingName = shippingAccount.Name;
            newQuote.ShippingStreet = shippingAccount.ShippingStreet;
            newQuote.ShippingCity = shippingAccount.ShippingCity;
            newQuote.ShippingState = shippingAccount.ShippingState;
            newQuote.ShippingPostalCode = shippingAccount.ShippingPostalCode;
            newQuote.ShippingCountry = shippingAccount.ShippingCountry;
            return this;
        }

        public Quote save() {
            insert newQuote;
            return newQuote;
        }

        private Account getAccount(Id accId) {
            return [SELECT Id, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry,
                ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, ShippingCountry, Name
                FROM Account
                WHERE Id =: accId LIMIT 1
            ];
        }
    }

    @AuraEnabled
    public static Contact getContactInfo(Id contactId) {
        try {
            return [SELECT Id, Email, Phone FROM Contact WHERE Id =: contactId LIMIT 1];
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    private static Set <Id> getOpportunityIds (Id oppId, String oppRecordTypeId) {
        if(oppRecordTypeId != Constants.opportunity.RECORD_TYPE_EMEA_TENDER_ID) {
            return new Set<Id> {oppId};
        }

        return new Map<Id, Opportunity> ([
                SELECT Id, StageName, Opportunity__c
                FROM Opportunity
                WHERE Opportunity__c =: oppId
                AND StageName !=: Constants.opportunity.STAGE_DISQUALIFIED
                AND StageName !=: Constants.opportunity.STAGE_CLOSED_LOST
        ]).keySet();
    }

    private static void copyLineItemsToQuote(Id oppId, Id quoteId, String oppRecordTypeId) {
        List < QuoteLineItem > quoteLineItems = new List < QuoteLineItem > ();
        Set <Id> opportunityIds = getOpportunityIds(oppId, oppRecordTypeId);

        if(opportunityIds.isEmpty()) {
            return;
        }

        for (OpportunityLineItem oppLineItem: [
                SELECT Id, PricebookEntryId, Quantity, UnitPrice, Discount, Research__c
                FROM OpportunityLineItem
                WHERE OpportunityId IN: opportunityIds
            ]) {

            if(oppRecordTypeId == Constants.opportunity.RECORD_TYPE_EMEA_TENDER_ID && oppLineItem.Research__c) {
                continue;
            }

            quoteLineItems.add(new QuoteLineItem(
                QuoteId = quoteId,
                PricebookEntryId = oppLineItem.PricebookEntryId,
                Quantity = oppLineItem.Quantity,
                UnitPrice = oppLineItem.UnitPrice,
                Discount = oppLineItem.Discount
            ));
        }

        if (!quoteLineItems.isEmpty()) {
            insert quoteLineItems;
        }
    }
}