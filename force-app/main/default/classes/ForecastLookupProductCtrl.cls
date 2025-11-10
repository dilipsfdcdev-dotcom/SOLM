public with sharing class ForecastLookupProductCtrl {
    private final static Integer MAX_RESULTS = 10;
    private static final string PRODUCT2_ICON = 'standard:product';

    @AuraEnabled
    public static List<LookupSearchResult> search(String searchTerm, List<String> selectedIds, String accountId) {
        List<List<SObject>> searchResults = [
            FIND :searchTerm
            IN ALL FIELDS
            RETURNING
                Product2(Id, Name, ProductCode, NACA_Case_Qty__c, EMEA_Case_Qty__c, SAP_Code__c WHERE Id NOT IN :selectedIds 
                    AND Id NOT IN (SELECT Product__c FROM Forecast_Product__c WHERE Account__c = :accountId AND (Direct_Enabled__c = TRUE OR Local_Enabled__c = TRUE ))
                    AND (NACA_Case_Qty__c != null OR EMEA_Case_Qty__c != null))
            LIMIT :MAX_RESULTS
        ];
    
        List<LookupSearchResult> results = new List<LookupSearchResult>();

        Product2[] products = (List<Product2>) searchResults[0];
        for (Product2 product : products) {
            String subtitle = 'Product';
            subtitle += product.ProductCode == null ? ' • SKU: N/A' : ' • SKU: ' + product.ProductCode;
            subtitle += product.NACA_Case_Qty__c != null ? ' • UoM: ' + product.NACA_Case_Qty__c : ' • UoM: ' + product.EMEA_Case_Qty__c;
            results.add(new LookupSearchResult(product.Id, 'Product2', PRODUCT2_ICON, product.Name, subtitle));
        }
        
        results.sort();
        return results;
    }

    @AuraEnabled
    public static List<LookupSearchResult> searchProducts(String searchTerm, List<String> selectedIds) {
        List<List<SObject>> searchResults = [
            FIND :searchTerm
            IN ALL FIELDS
            RETURNING
                Product2(Id, Name, ProductCode, NACA_Case_Qty__c, EMEA_Case_Qty__c, SAP_Code__c WHERE Id NOT IN :selectedIds 
                    AND (NACA_Case_Qty__c != null OR EMEA_Case_Qty__c != null))
            LIMIT :MAX_RESULTS
        ];
    
        List<LookupSearchResult> results = new List<LookupSearchResult>();

        Product2[] products = (List<Product2>) searchResults[0];
        for (Product2 product : products) {
            String subtitle = 'Product';
            subtitle += product.ProductCode == null ? ' • SKU: N/A' : ' • SKU: ' + product.ProductCode;
            subtitle += product.NACA_Case_Qty__c != null ? ' • UoM: ' + product.NACA_Case_Qty__c : ' • UoM: ' + product.EMEA_Case_Qty__c;
            results.add(new LookupSearchResult(product.Id, 'Product2', PRODUCT2_ICON, product.Name, subtitle));
        }
        
        results.sort();
        return results;
    }
}