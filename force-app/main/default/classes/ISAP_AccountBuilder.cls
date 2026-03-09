public interface ISAP_AccountBuilder {
    void init(ISAP_PARSER wrapper, Map<String,Id> userSAPCodeMap, SAP_Setting__mdt sapSetting);

    void setName();

    void setSAPCode();

    void setOwner();

    String getSalesPersonCode();

    void setCurrency();

    void setBillingAddress();

    void setShippingAddress();

    Account build();
}