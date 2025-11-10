public with sharing class QuotePDFController {
    
    public Quote quoteRecord { get; set; }
    public List<QuoteLineItem> quoteLineItems { get; set; }

    public QuotePDFController() {
        Id quoteId = ApexPages.currentPage().getParameters().get('id');
        if (quoteId != null) {
            quoteRecord = [
                SELECT Id, Name, Account.Name, Opportunity.Name, ExpirationDate, 
                       QuoteNumber, BillingStreet, BillingCity, BillingState, 
                       BillingPostalCode, BillingCountry, ShippingStreet, ShippingCity, 
                       ShippingState, ShippingPostalCode, ShippingCountry
                FROM Quote
                WHERE Id = :quoteId
                LIMIT 1
            ];
            
            quoteLineItems = [
                SELECT Id, Product2.Name, Product2.ProductCode, Quantity, UnitPrice, TotalPrice
                FROM QuoteLineItem
                WHERE QuoteId = :quoteId
                ORDER BY Product2.ProductCode ASC
            ];
        } else {
            quoteRecord = new Quote();
            quoteLineItems = new List<QuoteLineItem>();
        }
    }

    public Quote getQuote() {
        return quoteRecord;
    }

    public List<QuoteLineItem> getQuoteLineItems() {
        return quoteLineItems;
    }
}