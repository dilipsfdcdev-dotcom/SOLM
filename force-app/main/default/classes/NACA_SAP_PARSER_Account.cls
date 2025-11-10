public class NACA_SAP_PARSER_Account implements ISAP_PARSER{

    public String U_ExternalID;
    public String CardCode;	
    public String CardName;	
    public String CardFName;
    public Integer Series;	
    public String CardType;	
    public Integer GroupCode;	
    public String Active;
    public String CurrencyISO;
    public String E_Mail;	
    public String Phone1;	
    public String Phone2;	
    public String Cellular;	
    public String CompanyPrivate;	
    public String Notes;	
    public String Territory;	
    public String CreditLine;	
    public Integer GroupNum;	
    public String PymntGroup;	
    public Integer SlpCode;	
    public String SlpName;	
    public String CustomerOwnershipType;	
    public String InBusinessSince;	
    public String TaxExemptAccount;	
    public String FederalTaxIdNumber;	
    public String OrderConfirmationEmail;	
    public String SendingInvoicesEmail;	
    public String DeliveryNotificationEmail;
    public String SPSSendPOAck;
    public String SPSSendInvoice;
    public String SPSSendASN;
    public String SPSOrderStandAlone;
    public ContactEmployees[] ContactEmployees;
    public BPAddresses[] BPAddresses;
    public BPPaymentMethods[] BPPaymentMethods;
    
    public class BPPaymentMethods {}

    public class ContactEmployees {
        public String Name;	
        public String FirstName;	
        public String MiddleName;	
        public String LastName;	
        public String Tel1;	
        public String E_MailL;
    }

    public class BPAddresses {
        public String AddressName;
        public String County;
        public String AddrType;	
        public String Street;
        public String StreetNo;	
        public String Building;	
        public String ZipCode;
        public String Block;	
        public String City;	
        public String State;	
        public String Country;	
        public String AdressType;
        public String GlobalLocationNumber;
        public String U_CCarrierName;
        public String U_CAccount;
        public String U_CMaxPalletHeight;
        public String U_CReceivingHours;
    }

    public static List<NACA_SAP_PARSER_Account> parse(String json) {
		List<NACA_SAP_PARSER_Account> responses = new List<NACA_SAP_PARSER_Account>();
        JSONParser parser = System.JSON.createParser(json.replaceAll('Currency', 'CurrencyISO')); //Currency is reserved keyword in Apex

        while (parser.nextToken() != null) {
            if (parser.getCurrentToken() == JSONToken.START_ARRAY) {
                while (parser.nextToken() != null) {
                    if (parser.getCurrentToken() == JSONToken.START_OBJECT) {
                        NACA_SAP_PARSER_Account account = (NACA_SAP_PARSER_Account)parser.readValueAs(NACA_SAP_PARSER_Account.class);
                        responses.add(account);
                        parser.skipChildren();
                    }
                }
            }
        }
        
        return responses;
    }
}