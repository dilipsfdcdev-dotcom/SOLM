public class ForecastProductInfoWrapper{

    @AuraEnabled public Id productId;
    @AuraEnabled public String name;
    @AuraEnabled public String productLine;
    @AuraEnabled public String productCode;
    @AuraEnabled public Integer uom;
    @AuraEnabled public Decimal UnitPrice;
    @AuraEnabled public String AccountName;
    @AuraEnabled public String AccountId;
    public ForecastProductInfoWrapper(Product2 product){
        this.productId = product.Id;
        this.name = product.Name;
        this.productLine = product.Product_Line__c;
        this.productCode = product.ProductCode;
        this.uom = Integer.valueOf(product.NACA_Case_Qty__c);
    }   

    public ForecastProductInfoWrapper(Id productId){
        Product2 product = getProductInfo(productId);
        this.productId = product.Id;
        this.name = product.Name;
        this.productLine = product.Product_Line__c;
        this.productCode = product.ProductCode;
        this.uom = Integer.valueOf(product.NACA_Case_Qty__c);
    }   

    private Product2 getProductInfo(Id productId){
        return [
            SELECT Id, ProductCode, Name, NACA_Case_Qty__c, Product_Line__c,Unit_Price__c
            FROM Product2
            WHERE Id = :productId LIMIT 1
        ];
    }
}