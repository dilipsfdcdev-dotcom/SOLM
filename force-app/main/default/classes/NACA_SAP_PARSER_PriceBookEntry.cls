public class NACA_SAP_PARSER_PriceBookEntry implements ISAP_PARSER_PriceBookEntry{

    public Integer ListNum;
    public String ListName;
    public String Price;
    public String PricePCS;
    public String ItemCode;
    public String Channel_ECommerce;
    public String Channel_CRM;
    public String Channel_MarketPlaces;
  
    public static List<NACA_SAP_PARSER_PriceBookEntry> parse(String json) {
      return (List<NACA_SAP_PARSER_PriceBookEntry>) System.JSON.deserialize(json, List<NACA_SAP_PARSER_PriceBookEntry>.class);
    }

    public Decimal getPrice(){
        return Decimal.valueOf(PricePCS);
    } 

    public String getPriceBookCode(){
        return String.valueOf(ListNum + ' - NACA');
    }

    public String getProduct2Code(){
        return ItemCode;
    } 

    public String getPriceBookEntryCode(){
        return ItemCode + String.valueOf(ListNum) + 'USD';
    }

    public Boolean getIsActive(){
        return true;
    }
}