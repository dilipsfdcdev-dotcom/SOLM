public class SAP_Endpoints {

	/* NACA */
	public static NACA_Endpoints naca {
		get {
			if (naca == null) {
				naca = new NACA_Endpoints();
			}
			return naca;
		}
		set;
	}

	public static EMEA_Endpoints emea {
		get {
			if (emea == null) {
				emea = new EMEA_Endpoints();
			}
			return emea;
		}
		set;
	}


	/*
		to get Account by SAP Code use parameter cardcode=
		to get Accounts modified since date use parameter date=, example date format 2022-02-04T10:00:00
	*/
	public class EMEA_Endpoints {
		public final String GET_PRICE_BOOKS = 'EMEA_SAP/PLListPriceLists';
		public final String GET_PRICE_BOOK_ENTRIES = 'EMEA_SAP/PLPriceLists';
		public final String GET_PRODUCTS = 'EMEA_SAP/PLItems';
		public final String ORDERS_ENDPOINT = 'EMEA_SAP/PLOrders';
		public final String ACCOUNTS_ENDPOINT= 'EMEA_SAP/PLBusinessPartners';
		public final String WAREHOUSE_ENDPOINT= 'EMEA_SAP/PLItemWarehouse';
	}

    public class NACA_Endpoints {
        public final String GET_PRICE_BOOKS = 'NACA_SAP/USListPriceLists';
        public final String GET_PRICE_BOOK_ENTRIES = 'NACA_SAP/USPriceLists';
        public final String GET_PRODUCTS = 'NACA_SAP/USItemMasterData';
        public final String ORDERS_ENDPOINT = 'NACA_SAP/USOrders';
        public final String ACCOUNTS_ENDPOINT= 'NACASAP/USBusinessPartners';
		public final String WAREHOUSE_ENDPOINT= 'NACA_SAP/USItemWarehouse';
    }

    public static String buildEndpointWithParams(String endpoint, Map<String,String> requestParamsMap){
        if(requestParamsMap != null){
            String endpointWithParams = endpoint;
            for(String param : requestParamsMap.keySet()){
                //endpointWithParams = endpointWithParams + '&' + param + '=' + requestParamsMap.get(param);
				endpointWithParams = endpointWithParams + '&' + param + '=' + '20240601' +'&dateTo=20240616';
				//endpointWithParams = endpointWithParams + '&' + param + '=' + '2010-04-09T01:43:06';
            }
            return endpointWithParams.replaceFirst('&', '?');
        }else{
            return endpoint;
        }
    }
}