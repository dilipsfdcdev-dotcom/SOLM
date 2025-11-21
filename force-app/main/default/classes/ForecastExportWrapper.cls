public class ForecastExportWrapper{
    public String ExternalId; 
    public String AccountCode;
    public String AccountName;
    public String AccountIncoterms;
    public String AccountPaymentTerms;
    public String Country;
    public String Branch;
    public String ProductCode;
    public String ForecastStatus;
    public String ShipmentMethod;
    public String Warehouse;
    public String DemandType;
    public String OpportunityName;
    public String AdjustmentName;
    public String FulfillmentDate;
    public String Quantity;
    public String OpportunityPricebook;
    public String OpportunityPrice;
    public String PartnerName;
    public String PartnerCode;
    public String PartnerIncoterms;
    public String PartnerPaymentTerms;

    transient private Forecast_Item__c item;

    public ForecastExportWrapper(Forecast_Item__c item){
        this.item = item;
    }

    public ForecastExportWrapper build(){
        setExternalId();
        setAccountDetails();
        setBranchInfo();
        setProductInfo();
        this.ForecastStatus = checkForecastStatus() ? 'Active' : 'Inactive';
        setForecastInfo();
        setOpportunityInfo();
        setAdjustmentInfo();
        setPartnerDetails();
        return this;
    }

    private void setExternalId(){
        this.ExternalId = item.External_Id__c;
    }

    private void setAccountDetails(){
        this.AccountCode = item.Forecast__r.Forecast_Product__r.Account__r.SAP_Code__c?.substringAfter('-');
        this.AccountName = item.Forecast__r.Forecast_Product__r.Account__r.Name;
        this.AccountIncoterms = item?.Forecast_Opportunity__r?.Opportunity_Product__r?.Opportunity.Incoterms__c 
            == null ? item.Forecast__r.Forecast_Product__r.Account__r.Incoterms__c : item.Forecast_Opportunity__r.Opportunity_Product__r.Opportunity.Incoterms__c; 
        this.AccountPaymentTerms = item?.Forecast_Opportunity__r?.Opportunity_Product__r?.Opportunity.Payment_Terms__c 
            == null ? item.Forecast__r.Forecast_Product__r.Account__r.Payment_Terms__c : item.Forecast_Opportunity__r.Opportunity_Product__r.Opportunity.Payment_Terms__c; 
    }

    private void setBranchInfo(){
        this.Country = item.Forecast__r.Forecast_Product__r.Account__r.Branch__c;
        this.Branch = item.Forecast__r.Forecast_Product__r.Account__r.RecordType.DeveloperName == Constants.account.RECORD_TYPE_NACA ? Constants.account.BRANCH_NACA : Constants.account.BRANCH_EMEA;
    }

    private void setProductInfo(){
        this.ProductCode = item.Forecast__r.Forecast_Product__r.Product__r.SAP_Code__c;
    }

    private void setForecastInfo(){
        this.ShipmentMethod = item.Fulfillment__c;
        this.Warehouse = item.Fulfillment__c == Constants.forecastItem.FULFILLMENT_DIRECT ? Constants.forecastItem.WAREHOUSE_DIRECT_CODE : item.Forecast__r.Forecast_Product__r?.Local_Warehouse__r.Name;
        this.DemandType = item.Item_Type__c;
        this.FulfillmentDate = String.valueOf(item.Forecast__r.Month__c);
        this.Quantity = String.valueOf(item.Quantity__c);
    }

    private Boolean checkForecastStatus(){
        if(!item.Active__c){
            return false;
        }else if(!item.Forecast__r.Forecast_Product__r.Account__r.Forecast_Enabled__c){
            return false;
        }else if(item.Fulfillment__c == Constants.forecastItem.FULFILLMENT_DIRECT && !item.Forecast__r.Forecast_Product__r.Direct_Enabled__c){
            return false;
        }else if(item.Fulfillment__c == Constants.forecastItem.FULFILLMENT_LOCAL && !item.Forecast__r.Forecast_Product__r.Local_Enabled__c){
            return false;
        }else if(item.Item_Type__c == Constants.forecastItem.ITEM_TYPE_OPP_PRODUCT && item.BU_Approval__c != Constants.approval.APPROVED){
            return false;
        }else if(item.Item_Type__c == Constants.forecastItem.ITEM_TYPE_OPP_PRODUCT && item.Forecast_Opportunity__r.Opportunity_Product__c == null){
            return false;
        }
        return true;
    }

    private void setOpportunityInfo(){
        this.OpportunityName = item?.Forecast_Opportunity__r?.Opportunity_Product__r?.Opportunity.Name; 
        this.OpportunityPricebook = item?.Forecast_Opportunity__r?.Opportunity_Product__r?.PricebookEntry?.Pricebook2.Name;
        this.OpportunityPrice = String.valueOf(item?.Forecast_Opportunity__r?.Opportunity_Product__r?.UnitPrice != null ? item.Forecast_Opportunity__r.Opportunity_Product__r.UnitPrice : 0);
    }

    private void setAdjustmentInfo(){
        this.AdjustmentName = item?.Forecast_Adjustment__r.Name;
    }

    private void setPartnerDetails(){
        if(item?.Forecast_Opportunity__r?.Opportunity_Product__r?.Opportunity.Business_Partner__c != null){
            this.PartnerName = item.Forecast_Opportunity__r.Opportunity_Product__r.Opportunity.Business_Partner__r.Name;
            this.PartnerCode = item.Forecast_Opportunity__r.Opportunity_Product__r.Opportunity.Business_Partner__r.SAP_Code__c?.substringAfter('-');
            this.PartnerIncoterms = item.Forecast_Opportunity__r.Opportunity_Product__r.Opportunity.Business_Partner__r.Incoterms__c;
            this.PartnerPaymentTerms = item.Forecast_Opportunity__r.Opportunity_Product__r.Opportunity.Business_Partner__r.Payment_Terms__c;
        }else if(item.Forecast__r.Forecast_Product__r.Account__r.Default_Partner__c != null){
            this.PartnerName = item.Forecast__r.Forecast_Product__r.Account__r.Default_Partner__r.Name;
            this.PartnerCode = item.Forecast__r.Forecast_Product__r.Account__r.Default_Partner__r.SAP_Code__c?.substringAfter('-');
            this.PartnerIncoterms = item.Forecast__r.Forecast_Product__r.Account__r.Default_Partner__r.Incoterms__c;
            this.PartnerPaymentTerms = item.Forecast__r.Forecast_Product__r.Account__r.Default_Partner__r.Payment_Terms__c;
        }
    }
}