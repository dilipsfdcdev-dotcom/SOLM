public class EMEA_SAP_AccountBuilder implements ISAP_AccountBuilder {
    private Account acc;
    Map<String,Id> userSAPCodeMap;
    private EMEA_SAP_PARSER_Account wrapper;
    private SAP_Setting__mdt sapSetting;

    public EMEA_SAP_AccountBuilder(){}

    public void init(ISAP_PARSER wrapper, Map<String,Id> userSAPCodeMap, SAP_Setting__mdt sapSetting){
        this.acc = new Account(RecordTypeId = Constants.account.RECORD_TYPE_EMEA_ID);
        this.userSAPCodeMap = userSAPCodeMap;
        this.wrapper = (EMEA_SAP_PARSER_Account) wrapper;
        this.sapSetting = sapSetting;
    }

    public Account build(){
        setActive();
        setSAPCode();
        setOwner();
        setName();
        setNIP();
        setPhone();
        setCustomerStatus();
        setCurrency();
        setGroup();
        setOrganizationType();
        setIncoterms();
        setMarketingEmail();
        setInvoicingEmail();
        setOrderRealizationEmail();
        setPurchaseDepartmentEmail();
        setQualityRegulatoryEmail();
        setPaymentTermsCode();
        setBillingAddress();
        setShippingAddress();
        return acc;
    }

    public void setName(){
        acc.Name = wrapper.CardName;
    }

    public void setNIP(){
        acc.NIP__c = wrapper.LicTradNum;
    }

    public void setSAPCode(){
        acc.SAP_Code__c = 'SMPL-' + wrapper.CardCode;
    }

    public void setOwner(){
        if(Test.isRunningTest()){
            acc.OwnerId = UserInfo.getUserId();
            return;
        }

        if(!acc.Active__c) {
            acc.OwnerId = UserInfo.getUserId();
            return;
        }

        acc.OwnerId = userSAPCodeMap.get(String.valueOf(wrapper.SlpCode));
        if(acc.OwnerId == null){
            acc.OwnerId = userSAPCodeMap.get(String.valueOf(Integer.valueOf(sapSetting.Default_Account_Owner__c)));
        }
    }

    public String getSalesPersonCode(){
        return String.valueOf(wrapper.SlpCode);
    }

    public void setPhone(){
        acc.Phone = wrapper.Phone1;
    }

    public void setActive(){
        switch on wrapper.Active {
            when 'Y'{
                acc.Active__c = true;
            }
            when else {
                acc.Active__c = false;
            }
        }
    }

    public void setCustomerStatus(){
        acc.Customer_Status__c = Constants.account.CUSTOMER_STATUS_CUSTOMER;
    }

    public void setCurrency(){
        acc.MultiCurrency__c = false;
        switch on wrapper.CurrencyISO {
            when '##' {
                acc.CurrencyIsoCode = 'EUR';
                acc.MultiCurrency__c = true;
            }
            when '$' {
                acc.CurrencyIsoCode = 'USD';
            }
            when else {
                acc.CurrencyIsoCode = wrapper.CurrencyISO;
            }
        }
    }

    public void setGroup() {
        acc.Group__c = EMEA_SAP_Dictionary.GROUP_SAP_CODE_MAP.get(wrapper.GroupCode);
    }

    public void setOrganizationType() {
        acc.Organization_Type__c = EMEA_SAP_Dictionary.ORGANIZATION_TYPE_SAP_CODE_MAP.get(wrapper.Industry);
    }

    public void setIncoterms() {
        acc.Incoterms__c = wrapper.Incoterms;
    }

    public void setMarketingEmail() {
        acc.Marketing_Email__c = wrapper.MarketingEmail;
    }

    public void setInvoicingEmail() {
        acc.Invoicing_Email__c = wrapper.InvoicingEmail;
    }

    public void setOrderRealizationEmail() {
        acc.Order_Realization_Email__c = wrapper.OrderRealizationEmail;
    }

    public void setPurchaseDepartmentEmail() {
        acc.Purchase_Department_E_mail__c = wrapper.E_Mail;
    }

    public void setQualityRegulatoryEmail() {
        acc.Quality_Regulatory_Email__c = wrapper.QualityRegulatoryEmail;
    }

    public void setPaymentTermsCode() {
        acc.Payment_Terms__c = wrapper.PymntGroup;
    }

    public void setBillingAddress() {
        EMEA_SAP_PARSER_Account.BPAddresses billingAddress = getBillingAddress();

        if(billingAddress != null){
            acc.BillingCountryCode = billingAddress.Country;
            acc.BillingCity = billingAddress.City;
            acc.BillingStreet = billingAddress.Street;
            acc.BillingPostalCode = billingAddress.ZipCode;
        }
    }

    /*
        Business Partner in SAP should have one Billing Address
     */
    private EMEA_SAP_PARSER_Account.BPAddresses getBillingAddress(){
        for(EMEA_SAP_PARSER_Account.BPAddresses BPAddress: wrapper.BPAddresses){
            if(BPAddress.AdressType == 'B' && BPAddress.AddressName == wrapper.BillToDef){
                return BPAddress;
            }
        }
        return null;
    }
    /*
        Sync Shipping Address for Business Partner if one address present in SAP.
        If multiply - sync skipped
     */
    public void setShippingAddress(){
        EMEA_SAP_PARSER_Account.BPAddresses shippingAddress = getShippingAddress();

        if(shippingAddress != null){
            acc.ShippingCountryCode = shippingAddress.Country;
            acc.ShippingCity = shippingAddress.City;
            acc.ShippingStreet = shippingAddress.Street;
            acc.ShippingPostalCode = shippingAddress.ZipCode;

            if (shippingAddress.Zone != null || shippingAddress.Zone != '')
            {
                Integer intNum = Integer.valueOf(shippingAddress.Zone); // Convert to integer to remove leading zeros
                String strWithoutLeadingZeros = String.valueOf(intNum); // Convert back to string
                acc.Zone__c = strWithoutLeadingZeros;
            } else {
                acc.Zone__c = shippingAddress.Zone;
            }

            
        }
    }

    private EMEA_SAP_PARSER_Account.BPAddresses getShippingAddress(){
        List<EMEA_SAP_PARSER_Account.BPAddresses> shippingAddresses = new List<EMEA_SAP_PARSER_Account.BPAddresses>();

        for(EMEA_SAP_PARSER_Account.BPAddresses BPAddress: wrapper.BPAddresses){
            if(BPAddress.AdressType == 'S' && BPAddress.AddressName == wrapper.ShipToDef){
                return BPAddress;
            }
        }

        return null;
    }
}