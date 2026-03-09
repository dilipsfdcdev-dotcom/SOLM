public virtual with sharing class SAP_PARSER_Order implements ISAP_PARSER {
    public Integer DocEntry;
	public Integer DocNum;
	public String CardCode;
	public String CardName;
	public String DocDate;
	public String DocDueDate;
	public String TaxDate;
	public String DocStatus;
	public String CANCELED;
	public String DocCur;
	public Integer SlpCode;
	public String SlpName;
	public String Comments;
	public String ExternalID1;
	public String ExternalID2;
	public String NumAtCard;
	public String U_TipoPedido;
	public String TranspName;
	public String Carrier;
	public String TotalExpns;
	public String ShipToCode;
	public String PayToCode;
	public String Confirmed;
	public String PymntGroup;
	public String PeyMethod;
	public String Descript;
	public String MainUsage;
	public String Incoterms;
	public String Header;
	public Itens[] Itens;

	public class Itens {
		public String ItemCode;
		public String ItemName;	
		public String Quantity;	
		public String Price;
		public String DelivrdQty;
		public String OpenCreQty;
		public String LineStatus;
		public String LineNum;
		public String TargetType;
		public String TrgetEntry;
		public String DiscPrcnt;
		public String WhsCode;
		public String ShipDate;	
		public String Usage;
		public String OrderItemNumber;
	}

    public static List<SAP_PARSER_Order> parse(String json) {
        return (List<SAP_PARSER_Order>) System.JSON.deserialize(json, List<SAP_PARSER_Order>.class);
    }
}