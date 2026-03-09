public class SAP_NACA extends SAP_Instance{ 

    public SAP_NACA(){
        //Region
        super.regionKeyWord = 'NACA';

        //Account
        super.accountsEndpoint = SAP_Endpoints.naca.ACCOUNTS_ENDPOINT;
        super.accountParser =  'NACA_SAP_PARSER_Account';
        super.accountBuilder = 'NACA_SAP_AccountBuilder';

        //PriceBook
        super.getPriceBooksEndpoint = SAP_Endpoints.naca.GET_PRICE_BOOKS;
        super.priceBookParser = 'NACA_SAP_PARSER_PriceBook';
        super.priceBookBuilder = 'NACA_SAP_PriceBookBuilder';

        //PriceBookEntry
        super.getPriceBookEntriesEndpoint = SAP_Endpoints.naca.GET_PRICE_BOOK_ENTRIES;
        super.priceBookEntryParser = 'NACA_SAP_PARSER_PriceBookEntry';

        //Product
        super.getProductsEndpoint = SAP_Endpoints.naca.GET_PRODUCTS;
        super.productParser = 'NACA_SAP_PARSER_Product';
        super.productBuilder = 'NACA_SAP_ProductBuilder';

        //Order
        super.orderEndpoint = SAP_Endpoints.naca.ORDERS_ENDPOINT;
        super.orderParser = 'SAP_PARSER_Order';
        super.orderBuilder = 'NACA_SAP_OrderBuilder';

		//Warehouse
		super.warehouseParser = 'NACA_SAP_PARSER_Warehouse';
		super.warehouseEndpoint = SAP_Endpoints.naca.WAREHOUSE_ENDPOINT;

        //Extra Vaiables
        super.userSAPCodeField = User.SAP_Code__c;
        super.userSAPCodeFieldName = 'SAP_Code__c';        
    }
}