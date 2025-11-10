public class ForecastProductTotalsWrapper{
    private string volume;
    @AuraEnabled public ForecastProductInfoWrapper productInfo;
    @AuraEnabled public String warehouseNameDirect;
    @AuraEnabled public String warehouseNameLocal;
    @AuraEnabled public Boolean directEnabled;
    @AuraEnabled public Boolean localEnabled;

    @AuraEnabled public Map<String, Decimal> previousYearOrdersMap = new Map<String, Decimal>();
    @AuraEnabled public Map<String, Decimal> currentYearOrdersMap = new Map<String, Decimal>();
    @AuraEnabled public Map<String, Decimal> baseTotalMap = new Map<String, Decimal>();
    @AuraEnabled public Map<String, Decimal> opportunitiesTotalMap = new Map<String, Decimal>();
    @AuraEnabled public Map<String, Decimal> adjustmentsTotalMap = new Map<String, Decimal>();
    @AuraEnabled public Map<String, Decimal> forecastTotalMap = new Map<String, Decimal>();

    public ForecastProductTotalsWrapper(Product2 product, String AccountName, String AccountId, String volume, Boolean directEnabled, Boolean localEnabled, Warehouse__c warehouse,Decimal UnitPrice){
        this.productInfo = new ForecastProductInfoWrapper(product);
        this.productInfo.UnitPrice = UnitPrice;
        this.productInfo.AccountName = AccountName;
        this.productInfo.AccountId = AccountId;
        this.volume = volume; 
        this.directEnabled = directEnabled;
        this.localEnabled = localEnabled;

        if(localEnabled && warehouse != null){
            this.warehouseNameLocal = warehouse.Name;
        }

        if(directEnabled && warehouse != null){
            this.warehouseNameDirect = warehouse.Name;
        }
    }

    public ForecastProductTotalsWrapper setData(List<String> dateRange, List<Forecast_Month__c> forecastMonths){
        for (String d : dateRange) {
            previousYearOrdersMap.put(d, 0);
            currentYearOrdersMap.put(d, 0);
            baseTotalMap.put(d, 0);
            opportunitiesTotalMap.put(d, 0);
            adjustmentsTotalMap.put(d, 0);
            forecastTotalMap.put(d, 0);
        }

        for(Forecast_Month__c forecastMonth: forecastMonths){
            String key = ForecastUtil.getMonthUniqueId(forecastMonth.Month__c);
            
            previousYearOrdersMap.put(key, ForecastUtil.getQuantityInVolume(forecastMonth.Previous_Year_Orders__c, volume, productInfo.uom));
            currentYearOrdersMap.put(key, ForecastUtil.getQuantityInVolume(forecastMonth.Current_Orders__c, volume, productInfo.uom));
            baseTotalMap.put(key, ForecastUtil.getQuantityInVolume(forecastMonth.Base_Total__c, volume, productInfo.uom));
            opportunitiesTotalMap.put(key, ForecastUtil.getQuantityInVolume(forecastMonth.Opportunities_Total__c, volume, productInfo.uom));
            adjustmentsTotalMap.put(key, ForecastUtil.getQuantityInVolume(forecastMonth.Adjustments_Total__c, volume, productInfo.uom));
            forecastTotalMap.put(key, ForecastUtil.getQuantityInVolume(forecastMonth.Forecast_Total__c, volume, productInfo.uom));                
        }
        
        return this;
    }
}