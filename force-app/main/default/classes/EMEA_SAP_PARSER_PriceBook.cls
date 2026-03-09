public class EMEA_SAP_PARSER_PriceBook implements ISAP_PARSER{

    public Integer ListNum;
	public String ListName;
	public String ValidFor;
	public String PrimCurr;
	public String AddCurr1;
	public String AddCurr2;
	public String Channel_ECommerce;
	public String Channel_CRM;
	public String Channel_MarketPlaces;

	public List<EMEA_SAP_PARSER_PriceBook> parse(String json) {
		return (List<EMEA_SAP_PARSER_PriceBook>) System.JSON.deserialize(json, List<EMEA_SAP_PARSER_PriceBook>.class);
	}
}