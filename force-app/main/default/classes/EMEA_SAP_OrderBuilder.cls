public with sharing class EMEA_SAP_OrderBuilder extends SAP_OrderBuilder {
    public override void init(ISAP_PARSER wrapper){
        super.init(wrapper);
        super.order = new Order(RecordTypeId = Constants.order.RECORD_TYPE_EMEA_ID);
    }

    public override void setSAPCode(){
        super.setSAPCode();
        super.order.SAP_Code__c = Constants.order.EMEA_SAP_PREFIX + String.valueOf(super.wrapper.DocEntry);
    }

    public override void setAccount(){
        Account referenceAccount = new Account(SAP_Code__c = Constants.order.EMEA_SAP_PREFIX + super.wrapper.CardCode);
        super.order.Account = referenceAccount;
    }
}