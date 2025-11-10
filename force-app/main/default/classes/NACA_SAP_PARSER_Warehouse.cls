public class NACA_SAP_PARSER_Warehouse implements ISAP_PARSER_WarehouseParser
{
	public String ItemCode;
	public String WhsCode;

	public List<NACA_SAP_PARSER_Warehouse> parse(String json) {
		return (List<NACA_SAP_PARSER_Warehouse>) System.JSON.deserialize(json, List<NACA_SAP_PARSER_Warehouse>.class);
	}

	public String getRegion(){
        return 'NACA';
    }

	public String getWhsCode(){
        return WhsCode;
    }
}