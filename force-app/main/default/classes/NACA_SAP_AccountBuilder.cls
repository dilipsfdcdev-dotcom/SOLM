public class NACA_SAP_AccountBuilder implements ISAP_AccountBuilder {
    private Account acc;
    Map<String,Id> userSAPCodeMap;
    private NACA_SAP_PARSER_Account wrapper;
    private SAP_Setting__mdt sapSetting;

    public NACA_SAP_AccountBuilder(){}

    public void init(ISAP_PARSER wrapper, Map<String,Id> userSAPCodeMap, SAP_Setting__mdt sapSetting){
        this.acc = new Account(RecordTypeId = Constants.account.RECORD_TYPE_NACA_ID);
        this.userSAPCodeMap = userSAPCodeMap;
        this.wrapper = (NACA_SAP_PARSER_Account) wrapper;
        this.sapSetting = sapSetting;
    }

    public Account build(){
        setGroup();
        setActive();
        setSAPCode();
        setOwner();
        setName();
        setPhone();
        setCustomerStatus();
        setCurrency();
        setFederalTaxId();
        setInBusinessSince();
        setTaxExemptAccount();
        setPurchaseDepartmentEmail();
        setOrderConfirmationEmail();
        setDeliveryConfirmationEmail();
        setSendingInvoicesEmail();
        setPaymentTermsCode();
        setBillingAddress();
        setBillingContactInfo();
        setShippingAddress();
        setShippingContactInfo();
        setEdiOptions();
        return acc;
    }

    public void setGroup() {
        acc.Group__c = NACA_SAP_Dictionary.GROUP_SAP_CODE_MAP.get(wrapper.GroupCode);
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

    public void setName(){
        acc.Name = wrapper.CardName;
    }

    public void setSAPCode(){
        acc.SAP_Code__c = 'NACA-' + wrapper.CardCode;
    }

    public void setOwner(){
        acc.OwnerId = userSAPCodeMap.get(String.valueOf(wrapper.SlpCode));

        if(Test.isRunningTest()){
            acc.OwnerId = UserInfo.getUserId();
            return;
        }

        if(acc.OwnerId == null){
            acc.OwnerId = userSAPCodeMap.get(String.valueOf(sapSetting.Default_Account_Owner__c));
        }
    }

    public String getSalesPersonCode(){
        return String.valueOf(wrapper.SlpCode);
    }

    public void setPhone(){
        acc.Phone = wrapper.Phone1;
       
    }

    public void setCustomerStatus(){
        acc.Customer_Status__c = Constants.account.CUSTOMER_STATUS_CUSTOMER;
    }

    public void setCurrency(){
        acc.CurrencyIsoCode = 'USD';
    }

    public void setFederalTaxId(){
        acc.Federal_Tax_Id_Number__c = wrapper.FederalTaxIdNumber;
    }

    public void setInBusinessSince(){
        if(wrapper.InBusinessSince != '0'){
            acc.In_business_since__c = wrapper.InBusinessSince;
        }
    }

    public void setTaxExemptAccount(){
        acc.Sales_Tax_Exempt_Account__c = getBooleanValue(wrapper.TaxExemptAccount);
    }
    
    public void setPurchaseDepartmentEmail(){
        acc.Purchase_Department_E_mail__c = wrapper.E_Mail;
    }

    public void setOrderConfirmationEmail(){
        acc.Order_Confirmation_Email__c = wrapper.OrderConfirmationEmail;
    }

    public void setDeliveryConfirmationEmail(){
        acc.Delivery_Notification_Email__c = wrapper.DeliveryNotificationEmail;
    }
    
    public void setSendingInvoicesEmail(){
        acc.Invoicing_Email__c = wrapper.SendingInvoicesEmail;
    }

    public void setPaymentTermsCode(){
        acc.Payment_Terms__c = wrapper.PymntGroup;
    }

    public void setBillingAddress(){
        NACA_SAP_PARSER_Account.BPAddresses billingAddress = getBillingAddress();

        if(billingAddress != null){
            acc.BillingCountryCode = billingAddress.Country;
            acc.BillingCity = billingAddress.City;
            acc.BillingStreet = billingAddress.Street;
            acc.BillingPostalCode = billingAddress.ZipCode;

            if(billingAddress.Country == 'US' || billingAddress.Country == 'CA') {
                acc.BillingStateCode = billingAddress.State;
            }
        }
    }

    /*
        Business Partner in SAP should have one Billing Address
     */
    private NACA_SAP_PARSER_Account.BPAddresses getBillingAddress(){
        for(NACA_SAP_PARSER_Account.BPAddresses BPAddress: wrapper.BPAddresses){
            if(BPAddress.AdressType == 'B'){
                return BPAddress;
            }
        }
        return null;
    }

    public void setBillingContactInfo(){
        NACA_SAP_PARSER_Account.ContactEmployees billingContact = getContactInfo('Billing Agent');

        if(billingContact != null){
            acc.Billing_Contact_Name__c = billingContact.FirstName + ' ' + billingContact.LastName;
            acc.Billing_Email__c = billingContact.E_MailL;
            acc.Billing_Phone__c = billingContact.Tel1;
        }
    }

    /*
        Sync Shipping Address for Business Partner if one address present in SAP.
        If multiply - sync skipped
     */
    public void setShippingAddress(){
        NACA_SAP_PARSER_Account.BPAddresses shippingAddress = getShippingAddress();

        if(shippingAddress != null){
            acc.ShippingCountryCode = shippingAddress.Country;
            acc.ShippingCity = shippingAddress.City;
            acc.ShippingStreet = shippingAddress.Street;
            acc.ShippingPostalCode = shippingAddress.ZipCode;

            if(shippingAddress.Country == 'US' || shippingAddress.Country == 'CA') {
                acc.ShippingStateCode = shippingAddress.State;
            }

            acc.Attention__c = shippingAddress.Block;
            acc.Suite_Room__c = shippingAddress.StreetNo;
            acc.Building_Floor__c = shippingAddress.Building;
            acc.Carrier_Name__c = shippingAddress.U_CCarrierName;
            acc.Shipping_Number__c = shippingAddress.U_CAccount;
            acc.Maximum_Pallet_Height__c = shippingAddress.U_CMaxPalletHeight;
            acc.Receiving_Hours__c = shippingAddress.U_CReceivingHours;
            acc.GLN__c = shippingAddress.GlobalLocationNumber;         
        }
    }

    private NACA_SAP_PARSER_Account.BPAddresses getShippingAddress(){
        List<NACA_SAP_PARSER_Account.BPAddresses> shippingAddresses = new List<NACA_SAP_PARSER_Account.BPAddresses>();

        for(NACA_SAP_PARSER_Account.BPAddresses BPAddress: wrapper.BPAddresses){
            if(BPAddress.AdressType == 'S'){
                shippingAddresses.add(BPAddress);
            }
        }

        if(shippingAddresses.size() == 1){
            return shippingAddresses[0];
        }

        return null;
    }

    public void setShippingContactInfo(){
        NACA_SAP_PARSER_Account.ContactEmployees shippingContact = getContactInfo('Purchasing Agent');
        if(shippingContact != null){
            acc.Shipping_Contact_Name__c = shippingContact.FirstName + ' ' + shippingContact.LastName;
            acc.Shipping_Email__c = shippingContact.E_MailL;
            acc.Shipping_Phone__c = shippingContact.Tel1;
        }    
    }

    private NACA_SAP_PARSER_Account.ContactEmployees getContactInfo(String contactIdName){
        for(NACA_SAP_PARSER_Account.ContactEmployees ContactEmployee: wrapper.ContactEmployees){
            if(ContactEmployee.Name == contactIdName){
                return ContactEmployee;
            }
        }
        return null;
    }

    public void setEdiOptions(){
        acc.X810_Invoice__c = getBooleanValue(wrapper.SPSSendInvoice); 
        acc.X850_Orders__c = getBooleanValue(wrapper.SPSOrderStandAlone); 
        acc.X855_Order_Acknowledgement__c = getBooleanValue(wrapper.SPSSendPOAck); 
        acc.X856_Advanced_Ship_Notice__c = getBooleanValue(wrapper.SPSSendASN); 
       
    }

    private Boolean getBooleanValue(String entry){
        if(entry != null && entry == 'Y'){
            return true;
        }
        return false;
    }
}