public with sharing class QuoteToOrderCtrl {

    @AuraEnabled
    public static string generateOrder(Id quoteId) {
        Savepoint sp = Database.setSavepoint();
        try {
            return new OrderBuilder(quoteId)
                                    .setOrderDetails()
                                    .insertOrder()
                                    .insertOrderItems()
                                    .getOrder();
        } catch (Exception e) {
            Database.rollback(sp);
            throw new AuraHandledException(e.getMessage());
        }
    }

    private class OrderBuilder {
        private Order newOrder;
        private Quote quoteToOrder;

        public OrderBuilder(Id quoteId){
            this.quoteToOrder = getQuoteDetails(quoteId);
        }

        public OrderBuilder setOrderDetails(){
            newOrder = new Order(
                Status = Constants.order.STATUS_OPEN,
                RecordTypeId = Constants.order.RECORD_TYPE_NACA_ID,
                AccountId = quoteToOrder.AccountId,
                QuoteId = quoteToOrder.Id,
                OpportunityId = quoteToOrder.OpportunityId,
                Bill_To_Account__c = quoteToOrder.Bill_To_Account__c,
                Ship_To_Account__c = quoteToOrder.Ship_To_Account__c,
                Type = Constants.order.TYPE_CRM,
                EffectiveDate = Date.today(),
                BillingStreet = quoteToOrder.BillingStreet,
                BillingCity = quoteToOrder.BillingCity,
                BillingState = quoteToOrder.BillingState,
                BillingPostalCode = quoteToOrder.BillingPostalCode,
                BillingCountry = quoteToOrder.BillingCountry,
                ShippingStreet = quoteToOrder.ShippingStreet,
                ShippingCity = quoteToOrder.ShippingCity,
                ShippingState = quoteToOrder.ShippingState,
                ShippingPostalCode = quoteToOrder.ShippingPostalCode,
                ShippingCountry = quoteToOrder.ShippingCountry,
                CurrencyIsoCode = quoteToOrder.Account.CurrencyIsoCode,
                Pricebook2Id = quoteToOrder.Opportunity.Pricebook2Id
            );
            return this;
        }

        public OrderBuilder insertOrder(){
            insert newOrder;
            return this;
        }

        public OrderBuilder insertOrderItems(){
            List < OrderItem > orderProducts = new List < OrderItem > ();

            for (QuoteLineItem quoteLineItem: [SELECT Id, PricebookEntryId, Quantity, UnitPrice
                    FROM QuoteLineItem
                    WHERE QuoteId = :quoteToOrder.Id
                ]) {
                orderProducts.add(new OrderItem(
                    OrderId = newOrder.Id,
                    PricebookEntryId = quoteLineItem.PricebookEntryId,
                    Quantity = quoteLineItem.Quantity,
                    UnitPrice = quoteLineItem.UnitPrice,
                    QuoteLineItemId = quoteLineItem.Id
                ));
            }

            if (!orderProducts.isEmpty()) {
                insert orderProducts;
            }
            return this;
        }

        public Id getOrder(){
            return newOrder.Id;
        }

        private Quote getQuoteDetails(Id quoteId){
            return [SELECT Id, AccountId, Bill_To_Account__c, Ship_To_Account__c, OpportunityId, 
                    BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry,
                    ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, ShippingCountry,
                    Account.CurrencyIsoCode, Opportunity.Pricebook2Id
                    FROM Quote 
                    WHERE Id = :quoteId 
                    LIMIT 1];
        }
    }
}