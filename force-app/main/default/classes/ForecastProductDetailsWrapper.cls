public class ForecastProductDetailsWrapper {
    private Id productId;
    private Id accountId;
    private Date startDate;
    private string volume;
    private boolean direct;
    @AuraEnabled public ForecastProductInfoWrapper productInfo;

    @AuraEnabled public List<String> dateRange = new List<String>();

    @AuraEnabled public Map<String, Decimal> baseDirectMap = new Map<String, Decimal> ();
    @AuraEnabled public  Map<String, Decimal> baseLocalMap = new Map<String, Decimal> ();

    @AuraEnabled public List<ForecastAdjustmentEntryWrapper> directAdjustmentEntries = new List<ForecastAdjustmentEntryWrapper>();
    @AuraEnabled public List<ForecastAdjustmentEntryWrapper> localAdjustmentEntries = new List<ForecastAdjustmentEntryWrapper>();

    @AuraEnabled public List<ForecastOpportunityEntryWrapper> directOppsEntries = new List<ForecastOpportunityEntryWrapper>();
    @AuraEnabled public List<ForecastOpportunityEntryWrapper> localOppsEntries = new List<ForecastOpportunityEntryWrapper>();

    @AuraEnabled public Boolean directEnabled = false;
    @AuraEnabled public Boolean localEnabled = false;

    @AuraEnabled public Map<String, Decimal> previousYearOrdersMap = new Map<String, Decimal> ();
    @AuraEnabled public Map<String, Decimal> currentYearOrdersMap = new Map<String, Decimal> ();

    @AuraEnabled public Map<String, Decimal> opportunitiesTotalDirectMap = new Map<String, Decimal> ();
    @AuraEnabled public Map<String, Decimal> adjustmentsTotalDirectMap = new Map<String, Decimal> ();
    @AuraEnabled public Map<String, Decimal> forecastTotalDirectMap = new Map<String, Decimal> ();

    @AuraEnabled public Map<String, Decimal> opportunitiesTotalLocalMap = new Map<String, Decimal> ();
    @AuraEnabled public Map<String, Decimal> adjustmentsTotalLocalMap = new Map<String, Decimal> ();
    @AuraEnabled public Map<String, Decimal> forecastTotalLocalMap = new Map<String, Decimal> ();

    @AuraEnabled public Map<String, Decimal> baseSummaryMap = new Map<String, Decimal> ();
    @AuraEnabled public Map<String, Decimal> opportunitiesSummaryMap = new Map<String, Decimal> ();
    @AuraEnabled public Map<String, Decimal> adjustmentsSummaryMap = new Map<String, Decimal> ();
    @AuraEnabled public Map<String, Decimal> forecastSummaryMap = new Map<String, Decimal> ();

    private Map<Id, ForecastAdjustmentEntryWrapper> directAdjustmentEntriesMap = new Map<Id, ForecastAdjustmentEntryWrapper>();
    private Map<Id, ForecastAdjustmentEntryWrapper> localAdjustmentEntriesMap = new Map<Id, ForecastAdjustmentEntryWrapper>();

    private Map<Id, ForecastOpportunityEntryWrapper> directOppsEntriesMap = new Map<Id, ForecastOpportunityEntryWrapper>();
    private Map<Id, ForecastOpportunityEntryWrapper> localOppsEntriesMap = new Map<Id, ForecastOpportunityEntryWrapper>();

    @AuraEnabled public PicklistWrapper warehouse;

    public ForecastProductDetailsWrapper(String accountId, String productId, Date startDate, String volume,boolean direct) {
        this.startDate = startDate;
        this.productId = productId;
        this.accountId = accountId;
        this.volume = volume;
        this.direct = direct;
    }

    public ForecastProductDetailsWrapper build(){
        setProductInfo();
        setDateRange();
        setBaseAndTotals();
        setAdjustments();
        setOpportunities();
        return this;
    }

    private void setProductInfo(){
        Forecast_Product__c forecast = getForecastInfo();
        productInfo = new ForecastProductInfoWrapper(forecast.Product__r);
        productInfo.UnitPrice = Integer.valueOf(forecast.Price__c != null ? forecast.Price__c : 0);
        directEnabled = forecast.Direct_Enabled__c;
        localEnabled = forecast.Local_Enabled__c;

        if(forecast.Local_Warehouse__c != null){
            warehouse = new PicklistWrapper(forecast.Local_Warehouse__c, forecast.Local_Warehouse__r.Name, forecast.Local_Warehouse__r.Active__c);
        }
    }

    private void setDateRange(){
        dateRange = ForecastUtil.prepareDateRange(startDate);
    }

    private void setBaseAndTotals(){
        for (String d : dateRange) {
            previousYearOrdersMap.put(d, 0);
            currentYearOrdersMap.put(d, 0);

            baseDirectMap.put(d, 0);
            opportunitiesTotalDirectMap.put(d, 0);
            adjustmentsTotalDirectMap.put(d, 0);
            forecastTotalDirectMap.put(d, 0);

            baseLocalMap.put(d, 0);
            opportunitiesTotalLocalMap.put(d, 0);
            adjustmentsTotalLocalMap.put(d, 0);
            forecastTotalLocalMap.put(d, 0);

            baseSummaryMap.put(d, 0);
            opportunitiesSummaryMap.put(d, 0);
            adjustmentsSummaryMap.put(d, 0);
            forecastSummaryMap.put(d, 0);
        }

        for(Forecast_Month__c forecastMonth: getForecastMonths()){
            String key = ForecastUtil.getMonthUniqueId(forecastMonth.Month__c);
            
            previousYearOrdersMap.put(key, ForecastUtil.getQuantityInVolume(forecastMonth.Previous_Year_Orders__c, volume, productInfo.uom));
            currentYearOrdersMap.put(key, ForecastUtil.getQuantityInVolume(forecastMonth.Current_Orders__c, volume, productInfo.uom));

            baseDirectMap.put(key, ForecastUtil.getQuantityInVolume(forecastMonth.Base_Direct__c, volume, productInfo.uom));
            opportunitiesTotalDirectMap.put(key, ForecastUtil.getQuantityInVolume(forecastMonth.Opportunities_Total_Direct__c, volume, productInfo.uom));
            adjustmentsTotalDirectMap.put(key, ForecastUtil.getQuantityInVolume(forecastMonth.Adjustments_Total_Direct__c, volume, productInfo.uom));
            forecastTotalDirectMap.put(key, ForecastUtil.getQuantityInVolume(forecastMonth.Forecast_Total_Direct__c, volume, productInfo.uom));

            baseLocalMap.put(key, ForecastUtil.getQuantityInVolume(forecastMonth.Base_Warehouse__c, volume, productInfo.uom));
            opportunitiesTotalLocalMap.put(key, ForecastUtil.getQuantityInVolume(forecastMonth.Opportunities_Total_Warehouse__c, volume, productInfo.uom));
            adjustmentsTotalLocalMap.put(key, ForecastUtil.getQuantityInVolume(forecastMonth.Adjustments_Total_Warehouse__c, volume, productInfo.uom));
            forecastTotalLocalMap.put(key, ForecastUtil.getQuantityInVolume(forecastMonth.Forecast_Total_Warehouse__c, volume, productInfo.uom));

            baseSummaryMap.put(key, ForecastUtil.getQuantityInVolume(forecastMonth.Base_Total__c, volume, productInfo.uom));
            opportunitiesSummaryMap.put(key, ForecastUtil.getQuantityInVolume(forecastMonth.Opportunities_Total__c, volume, productInfo.uom));
            adjustmentsSummaryMap.put(key, ForecastUtil.getQuantityInVolume(forecastMonth.Adjustments_Total__c, volume, productInfo.uom));
            forecastSummaryMap.put(key, ForecastUtil.getQuantityInVolume(forecastMonth.Forecast_Total__c, volume, productInfo.uom));
        }
    }

    private void setAdjustments(){
        for(Forecast_Item__c forecastItem: getForecastAdjustments()){
            setAdjustmentMapEntry(forecastItem);
        }

        directAdjustmentEntries = directAdjustmentEntriesMap.values();
        localAdjustmentEntries = localAdjustmentEntriesMap.values();
    }

    private void setAdjustmentMapEntry(Forecast_Item__c item){
        ForecastAdjustmentEntryWrapper wrapper;

        if(item.Fulfillment__c == Constants.forecastItem.FULFILLMENT_DIRECT){
            wrapper = directAdjustmentEntriesMap.get(item.Forecast_Adjustment__c);
        }else{
            wrapper = localAdjustmentEntriesMap.get(item.Forecast_Adjustment__c);
        }

        if(wrapper == null){
            wrapper = new ForecastAdjustmentEntryWrapper(item, dateRange);
        }

        String key = ForecastUtil.getMonthUniqueId(item.Forecast__r.Month__c);
        wrapper.forecastNumbers.put(key, ForecastUtil.getQuantityInVolume(item.Quantity__c, volume, productInfo.uom));

        if(item.Fulfillment__c == Constants.forecastItem.FULFILLMENT_DIRECT){
            directAdjustmentEntriesMap.put(item.Forecast_Adjustment__c, wrapper);
        }else{
            localAdjustmentEntriesMap.put(item.Forecast_Adjustment__c, wrapper);
        }
    }

    private void setOpportunities(){
        for(Forecast_Item__c forecastItem: getForecastOpportunities()){
            setOpportunityMapEntry(forecastItem);
        }

        directOppsEntries = directOppsEntriesMap.values();
        localOppsEntries = localOppsEntriesMap.values();
    }

    private void setOpportunityMapEntry(Forecast_Item__c item){
        ForecastOpportunityEntryWrapper wrapper;

        if(item.Fulfillment__c == Constants.forecastItem.FULFILLMENT_DIRECT){
            wrapper = directOppsEntriesMap.get(item.Forecast_Opportunity__c);
        }else{
            wrapper = localOppsEntriesMap.get(item.Forecast_Opportunity__c);
        }

        if(wrapper == null){
            wrapper = new ForecastOpportunityEntryWrapper(item, dateRange);
        }

        String key = ForecastUtil.getMonthUniqueId(item.Forecast__r.Month__c);
        wrapper.forecastNumbers.put(key, ForecastUtil.getQuantityInVolume(item.Quantity__c, volume, productInfo.uom));

        if(item.Fulfillment__c == Constants.forecastItem.FULFILLMENT_DIRECT){
            directOppsEntriesMap.put(item.Forecast_Opportunity__c, wrapper);
        }else{
            localOppsEntriesMap.put(item.Forecast_Opportunity__c, wrapper);
        }
    }

    public Forecast_Product__c getForecastInfo(){
        return [
            SELECT Id, Direct_Enabled__c, Local_Enabled__c,price__c,
                Product__c, Product__r.Id, Product__r.ProductCode, Product__r.Name, 
                Product__r.NACA_Case_Qty__c, Product__r.EMEA_Case_Qty__c, Product__r.Product_Line__c,
                Local_Warehouse__r.Name, Local_Warehouse__r.Active__c, Local_Warehouse__c
            FROM Forecast_Product__c
            WHERE Account__c = :accountId 
            AND Product__c = :productId
            AND Direct_Enabled__c =: direct
        ];
    }

    private List<Forecast_Month__c> getForecastMonths(){
        return [
                SELECT 
                    Id, Month__c, Current_Orders__c, Previous_Year_Orders__c,
                    Base_Direct__c, Base_Warehouse__c, Base_Total__c,
                    Adjustments_Total_Direct__c, Adjustments_Total_Warehouse__c, Adjustments_Total__c,
                    Opportunities_Total_Direct__c, Opportunities_Total_Warehouse__c, Opportunities_Total__c,
                    Forecast_Total_Direct__c, Forecast_Total_Warehouse__c, Forecast_Total__c
                FROM Forecast_Month__c 
                WHERE Forecast_Product__r.Account__c = :accountId 
                AND Forecast_Product__r.Product__c = :productId
                AND Month__c >= :startDate
                ORDER BY Month__c ASC
        ];
    }

    private List<Forecast_Item__c> getForecastAdjustments(){
        return [
                SELECT 
                    Id, Forecast_Adjustment__c, Forecast_Adjustment__r.Comment__c, Forecast_Adjustment__r.Name, Forecast_Adjustment__r.Forecast_Opportunity__c,
                    Forecast_Adjustment__r.Forecast_Opportunity__r.Opportunity_Product__r.Opportunity.Name,
                    Quantity__c, Fulfillment__c, Item_Type__c, Forecast__r.Month__c
                FROM Forecast_Item__c 
                WHERE Item_Type__c = :Constants.forecastItem.ITEM_TYPE_ADJUSTMENT
                AND Active__c = true
                AND Forecast__r.Forecast_Product__r.Account__c = :accountId 
                AND Forecast__r.Forecast_Product__r.Product__c  = :productId
                AND Forecast__r.Month__c >= :startDate
                ORDER BY Forecast_Adjustment__c
        ];
    }

    private List<Forecast_Item__c> getForecastOpportunities(){
        return [
            SELECT 
                Id, Forecast_Opportunity__c, Forecast_Opportunity__r.Comment__c, Forecast_Opportunity__r.BU_Approval__c,
                Forecast_Opportunity__r.Opportunity_Product__r.OpportunityId, Forecast_Opportunity__r.Opportunity_Product__r.Opportunity.Name,
                Quantity__c, Fulfillment__c, Item_Type__c, Forecast__r.Month__c, BU_Approval__c
            FROM Forecast_Item__c 
            WHERE Item_Type__c = :Constants.forecastItem.ITEM_TYPE_OPP_PRODUCT
            AND Active__c = true
            AND Forecast__r.Forecast_Product__r.Account__c = :accountId 
            AND Forecast__r.Forecast_Product__r.Product__c  = :productId
            AND Forecast__r.Month__c >= :startDate
            ORDER BY Forecast_Adjustment__c
        ];
    }
}