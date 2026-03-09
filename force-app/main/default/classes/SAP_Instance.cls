public abstract class SAP_Instance {
    public String regionKeyWord;

    public String accountsEndpoint;
    public String accountParser;
    public String accountBuilder;

    public String getPriceBooksEndpoint;
    public String getProductsEndpoint;
    public String getPriceBookEntriesEndpoint;

    public String priceBookParser;
    public String priceBookBuilder;

    public String priceBookEntryParser;

    public String productParser;
    public String productBuilder;

    public Schema.SObjectField userSAPCodeField;
    public String userSAPCodeFieldName;

    public String orderParser;
    public String orderBuilder;
    public String orderEndpoint;

    public String warehouseParser;
    public String warehouseEndpoint;
}