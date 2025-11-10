public interface ISAP_OrderBuilder {
    void init(ISAP_PARSER wrapper);

    void setSAPCode();

    String getSalesPersonCode();

    void setAccount();

    void setCurrency();

    void setDates();

    void setStatus();

    void setOrderType();

    void setOrderAddresses();

    void setPricebook ();
    
    void setAdditionalInformation();

    Order buildOrder();

    List<OrderItem> buildOrderProducts();
}