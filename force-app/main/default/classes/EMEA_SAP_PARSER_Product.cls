public class EMEA_SAP_PARSER_Product implements ISAP_PARSER {
    public String ItemCode;
	public String ItemName;
	public String SWW;
	public String OldItemCode;
	public String FrgnName;
	public String ItmsGrpNam;
	public String Active;
	public String FirmName;
	public String NCMCode;
	public String SalUnitMsr;
	public String NumInSale;
	public String SalPackMsr;
	public String SalPackUn;
	public String Sheight1;
	public String SWidth1;
	public String SLength1;
	public String SVolume;
	public String SWeight;
	public String UgpEntry;
	public String UgpName;
	public String CodeBars;
	public String U_LG_SETOR;
	public String U_LG_SUBGProd;
	public String U_LG_FamProd;
	public String U_LG_EspProd;	
	public String SUomCode;
	public String U_LG_FamProdName;
	public String U_LG_EspProdName;
	public String U_LG_SETORName;
	public String U_LG_SUBGProdName;
	public String Channel_ECommerce;
	public String Channel_CRM;
	public String Channel_MarketPlaces;
	public String U_box_Qty;
	public String U_C_Qty;
	public String Segment;
	public String ProductLine;
	public String Material;
	public String Branding;
	public String Category;
	public String SubCategory;

    public static List<EMEA_SAP_PARSER_Product> parse(String json) {
        return (List<EMEA_SAP_PARSER_Product>) System.JSON.deserialize(json, List<EMEA_SAP_PARSER_Product>.class);
    }
}