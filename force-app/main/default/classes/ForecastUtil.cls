public with sharing class ForecastUtil {
    public static final String NEW_ADJUSTMENT_ID = 'new';
    public static final String NEW_ADJUSTMENT_NAME = 'Adjustment';

    public static List<String> prepareDateRange(Date startDate){
        List<String> dateRange = new List<String>();

        Date endDate = startDate.addYears(1).addMonths(-1).toStartOfMonth();
        Date tempDate = startDate;

        while(tempDate <= endDate){
            dateRange.add(getMonthUniqueId(tempDate));
            tempDate = tempDate.addMonths(1);
        }

        return dateRange;
    }

    public static String getForecastProductExternalId(String accountId, String productId) {
        return accountId + '-' + productId;
    }

    public static String getOpportunityForecastExternalId(String fulfillment, Id oppLineItemId) {
        return fulfillment + '-' + oppLineItemId;
    }

    public static String getOpportunityForecastItemExternalId(Id accountId, Id productId, Date forecastDate, String fulfillment, Id forecastOpportunityId) {
        return getForecastMonthExternalId(accountId, productId, forecastDate) + '-' +  Constants.forecastItem.ITEM_TYPE_OPP_PRODUCT + '-' + fulfillment + '-' + forecastOpportunityId;
    }

    public static String getForecastMonthExternalId(Id accountId, Id productId, Date forecastDate) {
        return accountId + '-' + productId + '-' +  getMonthUniqueId(forecastDate);
    }

    public static string getMonthUniqueId(Date d){
        return UtilDate.getMonthShortName(d) + '-' + String.valueOf(d.year()).right(2);
    }

    public static string getFulfillment(String fulfillment){
        if(fulfillment == 'direct'){
            return Constants.forecastItem.FULFILLMENT_DIRECT;
        }else{
            return Constants.forecastItem.FULFILLMENT_LOCAL;
        }
    }

    public static Decimal getQuantityInVolume(Decimal quantity, String volume, Integer uom){
        if(volume == 'pieces' || quantity == 0 || uom == null){
            return quantity;
        }else{
            return (quantity/uom).setScale(2);
        }
    }

    public static Integer setQuantityInVolume(String quantity, String volume, Integer uom){
        return setQuantityInVolume(Decimal.valueOf(quantity), volume, uom);
    }

    public static Integer setQuantityInVolume(Decimal quantity, String volume, Integer uom){
        if(volume == 'pieces' || quantity == 0 || uom == null){
            return Integer.valueOf(quantity);
        }else{
            return Integer.valueOf(quantity * uom);
        }
    }
}