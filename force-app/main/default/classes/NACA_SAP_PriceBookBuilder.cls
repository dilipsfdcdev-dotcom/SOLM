public class NACA_SAP_PriceBookBuilder implements ISAP_PriceBookBuilder{
    private NACA_SAP_PARSER_PriceBook wrapper;
    private Pricebook2 priceBook;
 
    public Pricebook2 build(ISAP_PARSER wrapper){ 
        this.wrapper = (NACA_SAP_PARSER_PriceBook) wrapper;
        priceBook = new Pricebook2(RecordTypeId = Constants.priceBook.RECORD_TYPE_NACA_ID);

        setName();
        setActive();
        setSAPCode();
        return priceBook;
    } 

    public void setName(){ 
       priceBook.Name = wrapper.ListName;
    } 
       
    public void setActive(){ 
        priceBook.IsActive = true;
    } 
    
    public void setSAPCode(){ 
        priceBook.SAP_Code__c = String.valueOf(wrapper.ListNum) + ' - NACA';
    } 

}