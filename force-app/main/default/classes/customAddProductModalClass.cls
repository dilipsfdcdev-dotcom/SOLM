public without sharing class customAddProductModalClass {

    @AuraEnabled
    public static String findProducts(
        String recordId,
        String name,
        String productCode,
        List<String> productFamily,
        Integer RecordLimit
    ) {
        if (String.isBlank(recordId)) {
            return JSON.serialize(new wrapperClass());
        }

        Quote qt = [
            SELECT Id, Pricebook2Id, Pricebook2.Name, CurrencyIsoCode
            FROM Quote
            WHERE Id = :recordId
            LIMIT 1
        ];

        wrapperClass wc = new wrapperClass();
        if (qt.Pricebook2Id != null) {
            wc.priceBook = qt.Pricebook2.Name;
        } else {
            wc.productList = new List<ProductWrapper>();
            return JSON.serialize(wc);
        }

        // ✅ Get existing QLI product codes (to exclude)
        Set<String> existingProductCodes = new Set<String>();
        for (QuoteLineItem qli : [
            SELECT Product2.ProductCode
            FROM QuoteLineItem
            WHERE QuoteId = :qt.Id
            AND Product2.ProductCode != null
        ]) {
            existingProductCodes.add(qli.Product2.ProductCode);
        }

        // Query Product2 (exclude products already added)
        List<Product2> products;
        if (productFamily != null && !productFamily.isEmpty()) {
            products = [
                SELECT Id, Family, Description, ProductCode, Name
                FROM Product2
                WHERE IsActive = true
                AND Family IN :productFamily
                AND ProductCode NOT IN :existingProductCodes
            ];
        } else {
            products = [
                SELECT Id, Family, Description, ProductCode, Name
                FROM Product2
                WHERE IsActive = true
                AND ProductCode NOT IN :existingProductCodes
            ];
        }

        if (products.isEmpty()) {
            wc.productList = new List<ProductWrapper>();
            return JSON.serialize(wc);
        }

        // Always cap at 300
        Integer limitVal = 300;

        // Name pattern
        String namePattern = null;
        if (!String.isBlank(name)) {
            namePattern = '%' + name.trim() + '%';
        }

        // Query PricebookEntry
        List<PricebookEntry> lstPBE;
        if (!String.isBlank(name) && !String.isBlank(productCode)) {
            lstPBE = [
                SELECT Id, UnitPrice, Product2Id, CurrencyIsoCode
                FROM PricebookEntry
                WHERE Pricebook2Id = :qt.Pricebook2Id
                  AND IsActive = true
                  AND CurrencyIsoCode = :qt.CurrencyIsoCode
                  AND Product2Id IN :products
                  AND Product2.Name LIKE :namePattern
                  AND Product2.ProductCode = :productCode
                LIMIT :limitVal
            ];
        } else if (!String.isBlank(name)) {
            lstPBE = [
                SELECT Id, UnitPrice, Product2Id, CurrencyIsoCode
                FROM PricebookEntry
                WHERE Pricebook2Id = :qt.Pricebook2Id
                  AND IsActive = true
                  AND CurrencyIsoCode = :qt.CurrencyIsoCode
                  AND Product2Id IN :products
                  AND Product2.Name LIKE :namePattern
                LIMIT :limitVal
            ];
        } else if (!String.isBlank(productCode)) {
            lstPBE = [
                SELECT Id, UnitPrice, Product2Id, CurrencyIsoCode
                FROM PricebookEntry
                WHERE Pricebook2Id = :qt.Pricebook2Id
                  AND IsActive = true
                  AND CurrencyIsoCode = :qt.CurrencyIsoCode
                  AND Product2Id IN :products
                  AND Product2.ProductCode = :productCode
                LIMIT :limitVal
            ];
        } else {
            lstPBE = [
                SELECT Id, UnitPrice, Product2Id, CurrencyIsoCode
                FROM PricebookEntry
                WHERE Pricebook2Id = :qt.Pricebook2Id
                  AND IsActive = true
                  AND CurrencyIsoCode = :qt.CurrencyIsoCode
                  AND Product2Id IN :products
                LIMIT :limitVal
            ];
        }

        // Map Product2
        Map<Id, Product2> mapProduct = new Map<Id, Product2>(products);

        // Build wrapper list
        List<ProductWrapper> lstProduct = new List<ProductWrapper>();
        for (PricebookEntry pbe : lstPBE) {
            Product2 p2 = mapProduct.get(pbe.Product2Id);
            if (p2 != null) {
                ProductWrapper pw = new ProductWrapper();
                pw.Id = pbe.Id;
                pw.purl = '/lightning/r/' + pbe.Id + '/view';
                pw.Product2Id = p2.Id;
                pw.Name = p2.Name;
                pw.Family = p2.Family;
                pw.ProductCode = p2.ProductCode;
                pw.Description = p2.Description;
                pw.Price = pbe.UnitPrice;
                lstProduct.add(pw);
            }
        }

        wc.productList = lstProduct;
        return JSON.serialize(wc);
    }

    @AuraEnabled
    public static List<PicklistValue> getproductfamily() {
        String strObjectName = 'Product2';
        String strPicklistField = 'Family';
        Schema.SObjectType objSobjectType = Schema.getGlobalDescribe().get(strObjectName);
        Schema.DescribeSObjectResult objDescribeSobject = objSobjectType.getDescribe();
        Map<String, Schema.SObjectField> mapFields = objDescribeSobject.fields.getMap();
        List<Schema.PicklistEntry> lstPickListValues = mapFields.get(strPicklistField).getDescribe().getPickListValues();

        List<PicklistValue> pvList = new List<PicklistValue>();
        for (Schema.PicklistEntry objPickList : lstPickListValues) {
            pvList.add(new PicklistValue(objPickList.getValue(), objPickList.getLabel()));
        }
        return pvList;
    }

    @AuraEnabled
    public static String saveProducts(String recordData, String recId) {
        List<ProductWrapper> wc = (List<ProductWrapper>) JSON.deserialize(recordData, List<ProductWrapper>.class);
        List<QuoteLineItem> lstQLI = new List<QuoteLineItem>();

        for (ProductWrapper pw : wc) {
            QuoteLineItem qli = new QuoteLineItem();
            if (pw.Id != null) {
                qli.PricebookEntryId = pw.Id;
            }
            qli.Quantity = (pw.Quantity == null) ? 1 : pw.Quantity;
            qli.UnitPrice = pw.Price;
            qli.ServiceDate = pw.PDate;
            qli.Description = pw.LineDescription;
            qli.QuoteId = recId;
            if (pw.Product2Id != null) {
                qli.Product2Id = pw.Product2Id;
            }
            lstQLI.add(qli);
        }

        try {
            insert lstQLI;
            return 'success';
        } catch (DmlException e) {
            System.debug('DML Error: ' + e.getMessage());
            return 'DML Error: ' + e.getMessage();
        } catch (Exception e) {
            System.debug('Unexpected Error: ' + e.getMessage());
            return 'error';
        }
    }

    public class wrapperClass {
        public String priceBook;
        public List<ProductWrapper> productList;
    }

    public class ProductWrapper {
        public String Name;
        public String Id; // PricebookEntry Id
        public String purl;
        public String Product2Id;
        public String ProductCode;
        public Decimal Price;
        public Decimal Quantity = 1;
        public String Family;
        public Date PDate;
        public String Description;
        public String LineDescription;
    }

    public class PicklistValue {
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public String value { get; set; }

        public PicklistValue(String value, String label) {
            this.value = value;
            this.label = label;
        }
    }
}