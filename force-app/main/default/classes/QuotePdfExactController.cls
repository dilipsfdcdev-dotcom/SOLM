public with sharing class QuotePdfExactController {
    public Id quoteId { get; set; }
    public Quote quoteRec { get; set; }
    public List<LineItemWrapper> lineItemWrappers { get; set; }

    public String todayFormatted { get { return formatDate(Date.today()); } }
    public String offerValidityFormatted { get; set; }
    public String subtotalFormatted { get; set; }
    public String totalPriceFormatted { get; set; }

    private String currencySymbol = '';

    public QuotePdfExactController(ApexPages.StandardController std) {
        this.quoteId = std.getId();
        lineItemWrappers = new List<LineItemWrapper>();

        if (quoteId != null) {
            quoteRec = [
                SELECT Id, Name, AccountId, Account.Name,
                       Account.BillingStreet, Account.BillingCity, Account.BillingPostalCode, Account.BillingCountry,
                       TotalPrice, CurrencyIsoCode, Offer_Validity__c,Incoterm__c,
                       Contact.Name, Phone, Email
                FROM Quote
                WHERE Id = :quoteId
                LIMIT 1
            ];

            currencySymbol = getCurrencySymbol(quoteRec.CurrencyIsoCode);

            if (quoteRec.Offer_Validity__c != null) {
                offerValidityFormatted = formatDate(quoteRec.Offer_Validity__c);
            } else {
                offerValidityFormatted = formatDate(Date.today().addDays(30));
            }

            // Pull all quote line item details including your custom fields
            List<QuoteLineItem> items = [
                SELECT Id,
                       Qty_box_Case__c,
                       UnitPrice,
                       Price_per_Box__c,
                       TotalPrice,
                       Description,
                       PricebookEntry.Product2.ProductCode,
                       PricebookEntry.Product2.StockKeepingUnit,
                       PricebookEntry.Product2.Name
                FROM QuoteLineItem
                WHERE QuoteId = :quoteId
                ORDER BY CreatedDate ASC
            ];

            Decimal subtotal = 0;
            Integer idx = 0;

            for (QuoteLineItem li : items) {
                idx++;
                LineItemWrapper w = new LineItemWrapper();

                // Product reference (SKU or Product Code)
                String sku = '';
                if (li.PricebookEntry != null && li.PricebookEntry.Product2 != null) {
                    sku = (li.PricebookEntry.Product2.StockKeepingUnit != null)
                        ? li.PricebookEntry.Product2.StockKeepingUnit
                        : (li.PricebookEntry.Product2.ProductCode != null ? li.PricebookEntry.Product2.ProductCode : '');
                }
                w.refVal = (sku != null && sku != '') ? sku : '';

                // Description
                if (li.Description != null && li.Description.trim().length() > 0) {
                    w.description = li.Description;
                } else if (li.PricebookEntry != null && li.PricebookEntry.Product2 != null) {
                    w.description = li.PricebookEntry.Product2.Name;
                } else {
                    w.description = '';
                }

                //  Custom quantity field
                w.qty = (li.Qty_box_Case__c != null) ? String.valueOf(li.Qty_box_Case__c) : '0';

                //  Price per pcs (UnitPrice)
                w.unitPrice = (li.UnitPrice != null) ? formatCurrency(li.UnitPrice, 4) : '';

                //  Price per box (custom)
                w.pricePerBox = (li.Price_per_Box__c != null) ? formatCurrency(li.Price_per_Box__c, 2) : '';

                //  Total
                w.totalPrice = (li.Price_per_Box__c != null) ? formatCurrency(li.Price_per_Box__c, 2) : '';
                w.rowBg = (Math.mod(idx, 2) == 0) ? '#f9f9f9' : '#ffffff';

                lineItemWrappers.add(w);
                if (li.TotalPrice != null) subtotal += li.TotalPrice;
            }

            subtotalFormatted = formatCurrency(subtotal, 2);
            totalPriceFormatted = (quoteRec.TotalPrice != null)
                ? formatCurrency(quoteRec.TotalPrice, 2)
                : subtotalFormatted;

        } else {
            quoteRec = new Quote();
            offerValidityFormatted = formatDate(Date.today().addDays(30));
            subtotalFormatted = '0.00';
            totalPriceFormatted = '0.00';
        }
    }

    //  Wrapper for each quote line
    public class LineItemWrapper {
        public String refVal { get; set; }
        public String description { get; set; }
        public String qty { get; set; }              // now maps Qty_box_Case__c
        public String unitPrice { get; set; }        // UnitPrice (Price per pcs)
        public String pricePerBox { get; set; }      // Price_per_Box__c
        public String totalPrice { get; set; }
        public String rowBg { get; set; }
    }

    // ---------- Formatting Helpers ----------
    private String formatCurrency(Decimal val, Integer scale) {
        if (val == null) return '';
        Decimal d = val.setScale(scale, RoundingMode.HALF_UP);

        String formatted = '';
        try {
            formatted = String.format('{0,number,#,##0.' + repeat('0', scale) + '}', new List<Object>{ d });
        } catch (Exception e) {
            formatted = String.valueOf(d);
        }
        return currencySymbol + ' ' + formatted;
    }

    private String repeat(String s, Integer n) {
        String result = '';
        for (Integer i = 0; i < n; i++) result += s;
        return result;
    }

    private String formatDate(Date d) {
        if (d == null) return '';
        Integer dd = d.day();
        Integer mm = d.month();
        Integer yyyy = d.year();
        String day = dd < 10 ? '0' + String.valueOf(dd) : String.valueOf(dd);
        String month = mm < 10 ? '0' + String.valueOf(mm) : String.valueOf(mm);
        return day + '.' + month + '.' + String.valueOf(yyyy);
    }

    private String getCurrencySymbol(String iso) {
        if (iso == null) return '';
        iso = iso.toUpperCase();
        Map<String, String> symbols = new Map<String, String>{
            'USD' => '$',
            'EUR' => '€',
            'GBP' => '£',
            'PLN' => 'zł',
            'CAD' => 'C$',
            'AUD' => 'A$'
        };
        return symbols.containsKey(iso) ? symbols.get(iso) : iso;
    }

    //  Invocable method to generate and attach the PDF to Quote PDFs
    @InvocableMethod(label='Generate Quote PDF and Add to Quote PDFs'
                     description='Render the Quote VF page to PDF and save it in the Quote PDFs related list.')
    public static void generateQuotePdfAndAddToQuote(List<Id> quoteIds) {
        List<QuoteDocument> quoteDocs = new List<QuoteDocument>();

        for (Id qId : quoteIds) {
            try {
                PageReference pdfPage = Page.QuotePDF; // Ensure your VF page name matches
                pdfPage.getParameters().put('id', qId);
                Blob pdfBlob = pdfPage.getContentAsPDF();

                QuoteDocument qd = new QuoteDocument();
                qd.QuoteId = qId;
                qd.Document = pdfBlob;
                quoteDocs.add(qd);

            } catch (Exception e) {
                System.debug('Error generating Quote PDF for Quote ' + qId + ': ' + e.getMessage());
            }
        }

        if (!quoteDocs.isEmpty()) {
            insert quoteDocs;
        }
    }
}