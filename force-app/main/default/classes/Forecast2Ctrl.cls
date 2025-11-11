/**
 * Forecast 2.0 Main Controller
 * Enhanced wrapper with better error handling and additional features
 * Delegates to existing ForecastCtrl for core functionality
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

            String response = ForecastCtrl.enableForecast(accountId);
            result.data = response;
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

            String response = ForecastCtrl.disableForecast(accountId);
            result.data = response;
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

            String response = ForecastCtrl.checkForecast(accountId);
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
     */
    @AuraEnabled(cacheable=true)
    public static EnhancedForecastWrapper getForecast(String accountId, String volume) {
        EnhancedForecastWrapper result = new EnhancedForecastWrapper();
        try {
            if (String.isBlank(accountId)) {
                result.success = false;
                result.error = 'Account ID is required';
                return result;
            }

            List<ForecastCtrl.ForecastProductWrapper> response = ForecastCtrl.getForecast(accountId, volume);
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
    public static EnhancedForecastWrapper getForecastByProduct(String productId, String volume) {
        EnhancedForecastWrapper result = new EnhancedForecastWrapper();
        try {
            if (String.isBlank(productId)) {
                result.success = false;
                result.error = 'Product ID is required';
                return result;
            }

            List<ForecastCtrl.ForecastProductWrapper> response = ForecastCtrl.getForecastByProduct(productId, volume);
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
     */
    @AuraEnabled(cacheable=true)
    public static EnhancedForecastWrapper getForecastDetailsForProduct(String forecastProductId, String volume) {
        EnhancedForecastWrapper result = new EnhancedForecastWrapper();
        try {
            if (String.isBlank(forecastProductId)) {
                result.success = false;
                result.error = 'Forecast Product ID is required';
                return result;
            }

            ForecastCtrl.ForecastProductDetailsWrapper response =
                ForecastCtrl.getForecastDetailsForProduct(forecastProductId, volume);
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
     */
    @AuraEnabled
    public static EnhancedForecastWrapper upsertBaseForecast(String jsonData) {
        EnhancedForecastWrapper result = new EnhancedForecastWrapper();
        try {
            if (String.isBlank(jsonData)) {
                result.success = false;
                result.error = 'Forecast data is required';
                return result;
            }

            String response = ForecastCtrl.upsertBaseForecast(jsonData);
            result.data = response;
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
     */
    @AuraEnabled
    public static EnhancedForecastWrapper upsertForecastAdjustments(String jsonData) {
        EnhancedForecastWrapper result = new EnhancedForecastWrapper();
        try {
            if (String.isBlank(jsonData)) {
                result.success = false;
                result.error = 'Adjustment data is required';
                return result;
            }

            String response = ForecastCtrl.upsertForecastAdjustments(jsonData);
            result.data = response;
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
     */
    @AuraEnabled
    public static EnhancedForecastWrapper setFulfillmentMethod(String forecastProductId, String method) {
        EnhancedForecastWrapper result = new EnhancedForecastWrapper();
        try {
            if (String.isBlank(forecastProductId)) {
                result.success = false;
                result.error = 'Forecast Product ID is required';
                return result;
            }

            String response = ForecastCtrl.setFulfillmentMethod(forecastProductId, method);
            result.data = response;
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
     */
    @AuraEnabled
    public static EnhancedForecastWrapper disableProduct(String forecastProductId) {
        EnhancedForecastWrapper result = new EnhancedForecastWrapper();
        try {
            if (String.isBlank(forecastProductId)) {
                result.success = false;
                result.error = 'Forecast Product ID is required';
                return result;
            }

            String response = ForecastCtrl.disableProduct(forecastProductId);
            result.data = response;
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
     */
    @AuraEnabled
    public static EnhancedForecastWrapper updateWarehouse(String forecastProductId, String warehouseId) {
        EnhancedForecastWrapper result = new EnhancedForecastWrapper();
        try {
            if (String.isBlank(forecastProductId)) {
                result.success = false;
                result.error = 'Forecast Product ID is required';
                return result;
            }

            String response = ForecastCtrl.updateWarehouse(forecastProductId, warehouseId);
            result.data = response;
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
     */
    @AuraEnabled
    public static EnhancedForecastWrapper updatePriceFP(String forecastProductId, Decimal price) {
        EnhancedForecastWrapper result = new EnhancedForecastWrapper();
        try {
            if (String.isBlank(forecastProductId)) {
                result.success = false;
                result.error = 'Forecast Product ID is required';
                return result;
            }

            String response = ForecastCtrl.updatePriceFP(forecastProductId, price);
            result.data = response;
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
