public class EMEA_SAP_PARSER_Account implements ISAP_PARSER{

    public String Active;
    public String CardCode;
    public String CardName;
    public String CurrencyISO;
    public Integer GroupCode;
    public String Industry;
    public String E_Mail;
    public String Incoterms;
    public String InvoicingEmail;
    public String LicTradNum;
    public String MarketingEmail;
    public String OrderRealizationEmail;
    public String Phone1;
    public String PymntGroup;
    public String QualityRegulatoryEmail;
    public String BillToDef;
    public String ShipToDef;
    public Integer SlpCode;
    public BPAddresses[] BPAddresses;

    public class BPPaymentMethods {}

    public class BPAddresses {
        public String AddressName;
        public String Street;
        public String ZipCode;
        public String Zone;
        public String City;
        public String Country;
        public String AdressType;
    }

    public static List<EMEA_SAP_PARSER_Account> parse(String json) {
		List<EMEA_SAP_PARSER_Account> responses = new List<EMEA_SAP_PARSER_Account>();
        JSONParser parser = System.JSON.createParser(json.replaceAll('Currency', 'CurrencyISO')); //Currency is reserved keyword in Apex

        while (parser.nextToken() != null) {
            if (parser.getCurrentToken() == JSONToken.START_ARRAY) {
                while (parser.nextToken() != null) {
                    if (parser.getCurrentToken() == JSONToken.START_OBJECT) {
                        EMEA_SAP_PARSER_Account account = (EMEA_SAP_PARSER_Account)parser.readValueAs(EMEA_SAP_PARSER_Account.class);
                        responses.add(account);
                        parser.skipChildren();
                    }
                }
            }
        }
        
        return responses;
    }
}