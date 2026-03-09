public with sharing class SAP_EMEA extends SAP_Instance {

	public SAP_EMEA(){
		//Region
		super.regionKeyWord = 'EMEA';

		//Account
		super.accountsEndpoint = SAP_Endpoints.emea.ACCOUNTS_ENDPOINT;
		super.accountParser =  'EMEA_SAP_PARSER_Account';
		super.accountBuilder = 'EMEA_SAP_AccountBuilder';

		//PriceBook
		super.getPriceBooksEndpoint = SAP_Endpoints.emea.GET_PRICE_BOOKS;
		super.priceBookParser = 'EMEA_SAP_PARSER_PriceBook';
        super.priceBookBuilder = 'EMEA_SAP_PriceBookBuilder';

		//PriceBookEntry
		super.getPriceBookEntriesEndpoint = SAP_Endpoints.emea.GET_PRICE_BOOK_ENTRIES;
		super.priceBookEntryParser = 'EMEA_SAP_PARSER_PriceBookEntry';

		//Product
		super.getProductsEndpoint = SAP_Endpoints.emea.GET_PRODUCTS;
		super.productParser = 'EMEA_SAP_PARSER_Product';
        super.productBuilder = 'EMEA_SAP_ProductBuilder';

		//Order
		super.orderParser = 'SAP_PARSER_Order';
		super.orderBuilder = 'EMEA_SAP_OrderBuilder';
		super.orderEndpoint = SAP_Endpoints.emea.ORDERS_ENDPOINT;

		//Warehouse
		super.warehouseParser = 'EMEA_SAP_PARSER_Warehouse';
		super.warehouseEndpoint = SAP_Endpoints.emea.WAREHOUSE_ENDPOINT;

		//Extra Vaiables
		super.userSAPCodeField = User.EMEA_SAP_Code__c;
		super.userSAPCodeFieldName = 'EMEA_SAP_Code__c';
	}
}