public with sharing class QuoteToPDFController {
    public Quote quote { get; private set; }
    public List<QuoteLineWrapper> lines { get; private set; }

    // Pre-formatted date strings (for safe use in Visualforce)
    public String createdDateStr { get; private set; }
    public String expirationDateStr { get; private set; }

    public class QuoteLineWrapper {
        public String productCode { get; set; }
        public String productName { get; set; }
        public Decimal quantity { get; set; }
        public Decimal unitPrice { get; set; }
        public Decimal totalPrice { get; set; }

        // Static sample values requested
        public String qtyBoxCase { get; set; }
        public String pricePerPcsStatic { get; set; }
        public String pricePerBoxStatic { get; set; }

        public QuoteLineWrapper(String pCode, String pName, Decimal qty, Decimal uPrice, Decimal tPrice) {
            productCode = pCode;
            productName = pName;
            quantity = qty;
            unitPrice = uPrice;
            totalPrice = tPrice;

            // Static placeholders
            qtyBoxCase = '50 / 2000';
            pricePerPcsStatic = '0.0250';
            pricePerBoxStatic = '1.25';
        }
    }

    public QuoteToPDFController(ApexPages.StandardController controller) {
        Id qId = (Id)controller.getId();
        if (qId == null) {
            quote = new Quote();
            lines = new List<QuoteLineWrapper>();
            createdDateStr = '';
            expirationDateStr = '';
            return;
        }

        // Query Quote info
        quote = [
            SELECT Id, Name, QuoteNumber, CreatedDate, ExpirationDate,
                   Account.Name, BillingStreet, BillingCity, BillingPostalCode, BillingCountry
            FROM Quote
            WHERE Id = :qId
            LIMIT 1
        ];

        // Format CreatedDate (DateTime)
        if (quote.CreatedDate != null) {
            createdDateStr = quote.CreatedDate.format(); // locale default
        } else {
            createdDateStr = '';
        }

        // Format ExpirationDate (Date)
        if (quote.ExpirationDate != null) {
            Date exp = quote.ExpirationDate;
            expirationDateStr = String.valueOf(exp.day()) + '.' + String.valueOf(exp.month()) + '.' + String.valueOf(exp.year());
        } else {
            expirationDateStr = '';
        }

        // Query quote line items
        List<QuoteLineItem> qlis = [
            SELECT Id, Quantity, UnitPrice, TotalPrice,
                   PricebookEntry.Product2.Name, PricebookEntry.Product2.ProductCode
            FROM QuoteLineItem
            WHERE QuoteId = :qId
            ORDER BY CreatedDate
        ];

        lines = new List<QuoteLineWrapper>();
        for (QuoteLineItem qli : qlis) {
            String pCode = (qli.PricebookEntry != null && qli.PricebookEntry.Product2 != null) ? qli.PricebookEntry.Product2.ProductCode : '';
            String pName = (qli.PricebookEntry != null && qli.PricebookEntry.Product2 != null) ? qli.PricebookEntry.Product2.Name : '--';
            lines.add(new QuoteLineWrapper(pCode, pName, qli.Quantity, qli.UnitPrice, qli.TotalPrice));
        }
    }
}