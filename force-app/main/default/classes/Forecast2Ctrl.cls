/**
 * Forecast 2.0 Main Controller
 * Enhanced wrapper with better error handling and additional features
 * Note: This is a lightweight wrapper - most functionality delegates to existing ForecastCtrl
 */
public with sharing class Forecast2Ctrl {

    /**
     * Enhanced wrapper for forecast products with additional metadata
     */
    public class EnhancedForecastWrapper {
        @AuraEnabled public Object data { get; set; }
        @AuraEnabled public Boolean success { get; set; }
        @AuraEnabled public String message { get; set; }
        @AuraEnabled public String error { get; set; }
    }

    /**
     * Enable forecast for account with enhanced error handling
     */
    @AuraEnabled
    public static EnhancedForecastWrapper enableForecast(String accountId) {
        EnhancedForecastWrapper result = new EnhancedForecastWrapper();
        try {
            if (String.isBlank(accountId)) {
                result.success = false;
                result.error = 'Account ID is required';
                return result;
            }

            ForecastCtrl.enableForecast(accountId);
            result.data = 'Success';
            result.success = true;
            result.message = 'Forecast enabled successfully';

        } catch (Exception e) {
            result.success = false;
            result.error = e.getMessage();
            result.message = 'Failed to enable forecast';
        }
        return result;
    }

    /**
     * Disable forecast for account with enhanced error handling
     */
    @AuraEnabled
    public static EnhancedForecastWrapper disableForecast(String accountId) {
        EnhancedForecastWrapper result = new EnhancedForecastWrapper();
        try {
            if (String.isBlank(accountId)) {
                result.success = false;
                result.error = 'Account ID is required';
                return result;
            }

            ForecastCtrl.disableForecast(accountId);
            result.data = 'Success';
            result.success = true;
            result.message = 'Forecast disabled successfully';

        } catch (Exception e) {
            result.success = false;
            result.error = e.getMessage();
            result.message = 'Failed to disable forecast';
        }
        return result;
    }

    /**
     * Check if forecast is enabled for account
     */
    @AuraEnabled(cacheable=true)
    public static EnhancedForecastWrapper checkForecast(String accountId) {
        EnhancedForecastWrapper result = new EnhancedForecastWrapper();
        try {
            if (String.isBlank(accountId)) {
                result.success = false;
                result.error = 'Account ID is required';
                return result;
            }

            ForecastCtrl.ForecastAccountInfo response = ForecastCtrl.checkForecast(accountId);
            result.data = response;
            result.success = true;

        } catch (Exception e) {
            result.success = false;
            result.error = e.getMessage();
        }
        return result;
    }

    /**
     * Get forecast data for account
     * Note: getForecast in ForecastCtrl requires searchTerm, pageSize, pageNumber
     */
    @AuraEnabled(cacheable=true)
    public static EnhancedForecastWrapper getForecast(
        String accountId,
        String volume,
        String searchTerm,
        Integer pageSize,
        Integer pageNumber
    ) {
        EnhancedForecastWrapper result = new EnhancedForecastWrapper();
        try {
            if (String.isBlank(accountId)) {
                result.success = false;
                result.error = 'Account ID is required';
                return result;
            }

            ForecastCtrl.ForecastWrapper response = ForecastCtrl.getForecast(
                accountId,
                volume,
                searchTerm,
                pageSize,
                pageNumber
            );
            result.data = response;
            result.success = true;

        } catch (Exception e) {
            result.success = false;
            result.error = e.getMessage();
        }
        return result;
    }

    /**
     * Get forecast by product
     */
    @AuraEnabled(cacheable=true)
    public static EnhancedForecastWrapper getForecastByProduct(
        String productId,
        String volume,
        String searchTerm,
        Integer pageSize,
        Integer pageNumber
    ) {
        EnhancedForecastWrapper result = new EnhancedForecastWrapper();
        try {
            if (String.isBlank(productId)) {
                result.success = false;
                result.error = 'Product ID is required';
                return result;
            }

            ForecastCtrl.ForecastWrapper response = ForecastCtrl.getForecastByProduct(
                productId,
                volume,
                searchTerm,
                pageSize,
                pageNumber
            );
            result.data = response;
            result.success = true;

        } catch (Exception e) {
            result.success = false;
            result.error = e.getMessage();
        }
        return result;
    }

    /**
     * Get forecast details for product
     * Note: getForecastDetailsForProduct requires accountId, productId, volume, direct
     */
    @AuraEnabled(cacheable=true)
    public static EnhancedForecastWrapper getForecastDetailsForProduct(
        String accountId,
        String productId,
        String volume,
        Boolean direct
    ) {
        EnhancedForecastWrapper result = new EnhancedForecastWrapper();
        try {
            if (String.isBlank(accountId) || String.isBlank(productId)) {
                result.success = false;
                result.error = 'Account ID and Product ID are required';
                return result;
            }

            ForecastCtrl.ForecastProductDetailsWrapper response =
                ForecastCtrl.getForecastDetailsForProduct(accountId, productId, volume, direct);
            result.data = response;
            result.success = true;

        } catch (Exception e) {
            result.success = false;
            result.error = e.getMessage();
        }
        return result;
    }

    /**
     * Insert products with enhanced error handling
     */
    @AuraEnabled
    public static EnhancedForecastWrapper insertProduct(String prodJson, String accountId) {
        EnhancedForecastWrapper result = new EnhancedForecastWrapper();
        try {
            if (String.isBlank(accountId)) {
                result.success = false;
                result.error = 'Account ID is required';
                return result;
            }

            if (String.isBlank(prodJson)) {
                result.success = false;
                result.error = 'Product data is required';
                return result;
            }

            String response = ForecastCtrl.insertProduct(prodJson, accountId);
            result.data = response;
            result.success = true;
            result.message = 'Products imported successfully';

        } catch (Exception e) {
            result.success = false;
            result.error = e.getMessage();
            result.message = 'Failed to import products';
        }
        return result;
    }

    /**
     * Upsert base forecast
     * Note: upsertBaseForecast requires accountId, productId, baseForecastMap, volume, uom, direct
     */
    @AuraEnabled
    public static EnhancedForecastWrapper upsertBaseForecast(
        String accountId,
        String productId,
        String baseForecastMap,
        String volume,
        Integer uom,
        Boolean direct
    ) {
        EnhancedForecastWrapper result = new EnhancedForecastWrapper();
        try {
            if (String.isBlank(accountId) || String.isBlank(productId)) {
                result.success = false;
                result.error = 'Account ID and Product ID are required';
                return result;
            }

            ForecastCtrl.upsertBaseForecast(accountId, productId, baseForecastMap, volume, uom, direct);
            result.data = 'Success';
            result.success = true;
            result.message = 'Base forecast updated successfully';

        } catch (Exception e) {
            result.success = false;
            result.error = e.getMessage();
            result.message = 'Failed to update base forecast';
        }
        return result;
    }

    /**
     * Upsert forecast adjustments
     * Note: upsertForecastAdjustments requires many parameters
     */
    @AuraEnabled
    public static EnhancedForecastWrapper upsertForecastAdjustments(
        String accountId,
        String productId,
        String adjustmentId,
        String adjustmentName,
        String forecastDataMap,
        String volume,
        Integer uom,
        String comment
    ) {
        EnhancedForecastWrapper result = new EnhancedForecastWrapper();
        try {
            if (String.isBlank(accountId) || String.isBlank(productId)) {
                result.success = false;
                result.error = 'Account ID and Product ID are required';
                return result;
            }

            ForecastCtrl.upsertForecastAdjustments(
                accountId,
                productId,
                adjustmentId,
                adjustmentName,
                forecastDataMap,
                volume,
                uom,
                comment
            );
            result.data = 'Success';
            result.success = true;
            result.message = 'Adjustments saved successfully';

        } catch (Exception e) {
            result.success = false;
            result.error = e.getMessage();
            result.message = 'Failed to save adjustments';
        }
        return result;
    }

    /**
     * Set fulfillment method
     * Note: setFulfillmentMethod requires accountId, productId, method, value
     */
    @AuraEnabled
    public static EnhancedForecastWrapper setFulfillmentMethod(
        String accountId,
        String productId,
        String method,
        Boolean value
    ) {
        EnhancedForecastWrapper result = new EnhancedForecastWrapper();
        try {
            if (String.isBlank(accountId) || String.isBlank(productId)) {
                result.success = false;
                result.error = 'Account ID and Product ID are required';
                return result;
            }

            ForecastCtrl.setFulfillmentMethod(accountId, productId, method, value);
            result.data = 'Success';
            result.success = true;
            result.message = 'Fulfillment method updated';

        } catch (Exception e) {
            result.success = false;
            result.error = e.getMessage();
            result.message = 'Failed to update fulfillment method';
        }
        return result;
    }

    /**
     * Disable product
     * Note: disableProduct requires accountId, productId, direct
     */
    @AuraEnabled
    public static EnhancedForecastWrapper disableProduct(
        String accountId,
        String productId,
        Boolean direct
    ) {
        EnhancedForecastWrapper result = new EnhancedForecastWrapper();
        try {
            if (String.isBlank(accountId) || String.isBlank(productId)) {
                result.success = false;
                result.error = 'Account ID and Product ID are required';
                return result;
            }

            ForecastCtrl.disableProduct(accountId, productId, direct);
            result.data = 'Success';
            result.success = true;
            result.message = 'Product disabled successfully';

        } catch (Exception e) {
            result.success = false;
            result.error = e.getMessage();
            result.message = 'Failed to disable product';
        }
        return result;
    }

    /**
     * Update warehouse
     * Note: updateWarehouse requires accountId, productId, warehouseId, direct
     */
    @AuraEnabled
    public static EnhancedForecastWrapper updateWarehouse(
        String accountId,
        String productId,
        String warehouseId,
        Boolean direct
    ) {
        EnhancedForecastWrapper result = new EnhancedForecastWrapper();
        try {
            if (String.isBlank(accountId) || String.isBlank(productId)) {
                result.success = false;
                result.error = 'Account ID and Product ID are required';
                return result;
            }

            ForecastCtrl.updateWarehouse(accountId, productId, warehouseId, direct);
            result.data = 'Success';
            result.success = true;
            result.message = 'Warehouse updated successfully';

        } catch (Exception e) {
            result.success = false;
            result.error = e.getMessage();
            result.message = 'Failed to update warehouse';
        }
        return result;
    }

    /**
     * Update price
     * Note: updatePriceFP requires accountId, productId, price
     */
    @AuraEnabled
    public static EnhancedForecastWrapper updatePriceFP(
        String accountId,
        String productId,
        Decimal price
    ) {
        EnhancedForecastWrapper result = new EnhancedForecastWrapper();
        try {
            if (String.isBlank(accountId) || String.isBlank(productId)) {
                result.success = false;
                result.error = 'Account ID and Product ID are required';
                return result;
            }

            ForecastCtrl.updatePriceFP(accountId, productId, price);
            result.data = 'Success';
            result.success = true;
            result.message = 'Price updated successfully';

        } catch (Exception e) {
            result.success = false;
            result.error = e.getMessage();
            result.message = 'Failed to update price';
        }
        return result;
    }

    /**
     * Get date range
     */
    @AuraEnabled(cacheable=true)
    public static EnhancedForecastWrapper getDateRange() {
        EnhancedForecastWrapper result = new EnhancedForecastWrapper();
        try {
            List<String> response = ForecastCtrl.getDateRange();
            result.data = response;
            result.success = true;

        } catch (Exception e) {
            result.success = false;
            result.error = e.getMessage();
        }
        return result;
    }

    /**
     * Get currency code
     */
    @AuraEnabled(cacheable=true)
    public static EnhancedForecastWrapper getCurrencyCode(String accountId) {
        EnhancedForecastWrapper result = new EnhancedForecastWrapper();
        try {
            if (String.isBlank(accountId)) {
                result.success = false;
                result.error = 'Account ID is required';
                return result;
            }

            String response = ForecastCtrl.getCurrencyCode(accountId);
            result.data = response;
            result.success = true;

        } catch (Exception e) {
            result.success = false;
            result.error = e.getMessage();
        }
        return result;
    }

    /**
     * Check user permissions
     */
    @AuraEnabled(cacheable=true)
    public static Boolean hasManageForecastPermission() {
        return FeatureManagement.checkPermission('Forecasting_Manage');
    }
}
