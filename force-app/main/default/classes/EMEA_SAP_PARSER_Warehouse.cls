public class EMEA_SAP_PARSER_Warehouse implements ISAP_PARSER_WarehouseParser
{
	public String ItemCode;
	public String WhsCode;

	public List<EMEA_SAP_PARSER_Warehouse> parse(String json) {
		return (List<EMEA_SAP_PARSER_Warehouse>) System.JSON.deserialize(json, List<EMEA_SAP_PARSER_Warehouse>.class);
	}

	public String getRegion(){
        return 'EMEA';
    }

	public String getWhsCode(){
        return WhsCode;
    }
}