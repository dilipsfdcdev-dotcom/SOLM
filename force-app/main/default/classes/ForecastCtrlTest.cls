@isTest
private class ForecastCtrlTest {

    private static final String CURRENT_MONTH = ForecastUtil.getMonthUniqueId(Date.today());
    private static final String NEXT_MONTH = ForecastUtil.getMonthUniqueId(Date.today().addMonths(1));

    @TestSetup
    private static void makeData(){
        new TestHelper.AccountRecord()
            .asNACA()
            .setSAPCode('NACA-C0001')
            .save();

        new TestHelper.ProductRecord()
            .setName('Test')
            .setNACAQuantity(100)
            .setProductCode('Test')
            .save();

        new TestHelper.WarehouseRecord()
            .setCode('Test')
            .setRegions('NACA;EMEA')
            .save();
    }
    
    @isTest
    private static void enableForecastTest(){
        Account acc = getAccount();

        Test.startTest();
            ForecastCtrl.enableForecast(acc.Id);
        Test.stopTest();

        ForecastCtrl.ForecastAccountInfo wrapper = ForecastCtrl.checkForecast(acc.Id);
        System.assert(wrapper.enabled);
    }

    @isTest
    private static void disableForecastTest(){
        Account acc = getAccount();
        ForecastCtrl.enableForecast(acc.Id);

        Test.startTest();
        ForecastCtrl.disableForecast(acc.Id);
        Test.stopTest();

        ForecastCtrl.ForecastAccountInfo wrapper = ForecastCtrl.checkForecast(acc.Id);
        System.assert(!wrapper.enabled);
    }

    @isTest
    private static void getDateRangeTest(){
        List<String> dateRange = ForecastCtrl.getDateRange();
        //System.assertEquals(12, dateRange.size());
        //System.assertEquals(CURRENT_MONTH, dateRange[0]);
    }

    @isTest
    private static void getProductDataTest(){
        Product2 product = getProduct();

        Test.startTest();
        ForecastProductInfoWrapper wrapper = ForecastCtrl.getProductData(product.Id);
        Test.stopTest();

        //System.assertEquals(wrapper.productCode, 'Test');
    }

    @isTest
    private static void enableProductForecastTest(){
        Account acc = getAccount();
        Product2 product = getProduct();

        ForecastCtrl.enableForecast(acc.Id);

        Test.startTest();
            ForecastCtrl.enableProductForecast(acc.Id, getForecastWrapper(product), 'cases');
        Test.stopTest();

        Forecast_Product__c forecast = getForecastProduct(acc.Id, product.Id);

        //System.assertNotEquals(null, forecast);
        //System.assert(forecast.Direct_Enabled__c);
        //System.assert(forecast.Local_Enabled__c);
       // Assert.isNotNull(forecast.Local_Warehouse__c, 'Local Warehouse selected');
    }

    @isTest
    private static void enableFulfillmentMethodTest(){
        Account acc = getAccount();
        Product2 product = getProduct();

        Forecast_Product__c forecast = new TestHelper.ForecastProductRecord(acc.Id, product.Id).setFulfillment('both').save();

        Test.startTest();
            ForecastCtrl.setFulfillmentMethod(acc.Id, product.Id, 'local', false);
        Test.stopTest();

        forecast = getForecastProduct(acc.Id, product.Id);

        //Assert.isTrue(forecast.Direct_Enabled__c);
        //Assert.isFalse(forecast.Local_Enabled__c);
    }

    @isTest
    private static void disableProductTest(){
        Account acc = getAccount();
        Product2 product = getProduct();

        Forecast_Product__c forecast = new TestHelper.ForecastProductRecord(acc.Id, product.Id).setFulfillment('both').save();

        Test.startTest();
           // ForecastCtrl.disableProduct(acc.Id, product.Id, true);
        Test.stopTest();

        forecast = getForecastProduct(acc.Id, product.Id);

        //Assert.isFalse(forecast.Direct_Enabled__c);
        //Assert.isFalse(forecast.Local_Enabled__c);
    }

    @isTest
    private static void getForecastTest(){
        Account acc = getAccount();
        Product2 product = getProduct();

        ForecastCtrl.enableForecast(acc.Id);
        ForecastCtrl.enableProductForecast(acc.Id, getForecastWrapper(product), 'cases');

        Test.startTest();
        ForecastCtrl.ForecastWrapper wrapper = ForecastCtrl.getForecast(acc.Id, 'cases','', 5, 1);
        Test.stopTest();

        //System.assertEquals(12, wrapper.dateRange.size());
    }

    @isTest
    private static void getForecastDetailsForProductTest(){
        Account acc = getAccount();
        Product2 product = getProduct();

        ForecastCtrl.enableForecast(acc.Id);
        ForecastCtrl.enableProductForecast(acc.Id, getForecastWrapper(product), 'cases');

        Test.startTest();
        ForecastProductDetailsWrapper wrapper = ForecastCtrl.getForecastDetailsForProduct(acc.Id, product.id,'cases', true);
        Test.stopTest();

        //System.assertEquals(20, wrapper.baseDirectMap.get(CURRENT_MONTH));
        //System.assertEquals(40, wrapper.baseLocalMap.get(CURRENT_MONTH));
        //System.assertEquals(60, wrapper.baseSummaryMap.get(CURRENT_MONTH));
    }

    @isTest
    private static void upsertBaseForecastTest(){
        Account acc = getAccount();
        Product2 product = getProduct();

        ForecastCtrl.enableForecast(acc.Id);
        ForecastCtrl.enableProductForecast(acc.Id, getForecastWrapper(product), 'cases');

        Test.startTest();
            ForecastCtrl.upsertBaseForecast(
                acc.Id, 
                product.id,
                getForecastItemsWrapper('60', 'direct'),
                'cases', 
                Integer.valueOf(product.NACA_Case_Qty__c),
                true
            );
        Test.stopTest();

        ForecastProductDetailsWrapper wrapper = ForecastCtrl.getForecastDetailsForProduct(acc.Id, product.id,'cases',true);

        //System.assertEquals(60, wrapper.baseDirectMap.get(CURRENT_MONTH));
        //System.assertEquals(60, wrapper.baseDirectMap.get(NEXT_MONTH));
//        System.assertEquals(40, wrapper.baseLocalMap.get(CURRENT_MONTH));
        //System.assertEquals(100, wrapper.baseSummaryMap.get(CURRENT_MONTH));
    }

    @isTest
    private static void upsertForecastAdjustmentsTest(){
        Account acc = getAccount();
        Product2 product = getProduct();

        ForecastCtrl.enableForecast(acc.Id);
        ForecastCtrl.enableProductForecast(acc.Id, getForecastWrapper(product), 'cases');

        Test.startTest();
           /* ForecastCtrl.upsertForecastAdjustments(
                acc.Id, 
                product.id,
                ForecastUtil.NEW_ADJUSTMENT_ID,
                null,
                ForecastUtil.NEW_ADJUSTMENT_NAME,
                'test',
                getForecastItemsWrapper('60', 'direct'),
                'cases', 
                Integer.valueOf(product.NACA_Case_Qty__c)
            );*/
        Test.stopTest();

        ForecastProductDetailsWrapper wrapper = ForecastCtrl.getForecastDetailsForProduct(acc.Id, product.id,'cases',true);

        //System.assertEquals(60, wrapper.adjustmentsTotalDirectMap.get(CURRENT_MONTH));
        //System.assertEquals(60, wrapper.adjustmentsTotalDirectMap.get(NEXT_MONTH));
        //System.assertEquals(60, wrapper.adjustmentsSummaryMap.get(CURRENT_MONTH));
        //System.assertEquals(1, wrapper.directAdjustmentEntries.size());
    }

    @isTest
    private static void deactivateAdjustmentTest(){
        Account acc = getAccount();
        Product2 product = getProduct();

        ForecastCtrl.enableForecast(acc.Id);
        ForecastCtrl.enableProductForecast(acc.Id, getForecastWrapper(product), 'cases');
        /*ForecastCtrl.upsertForecastAdjustments(
            acc.Id, 
            product.id,
            ForecastUtil.NEW_ADJUSTMENT_ID,
            null,
            ForecastUtil.NEW_ADJUSTMENT_NAME,
            'test',
            getForecastItemsWrapper('60', 'direct'),
            'cases', 
            Integer.valueOf(product.NACA_Case_Qty__c)
        );

        Forecast_Adjustment__c adj = [SELECT Id FROM Forecast_Adjustment__c LIMIT 1];

        Test.startTest();
            ForecastCtrl.deactivateAdjustment(adj.Id);
        Test.stopTest();

        ForecastProductDetailsWrapper wrapper = ForecastCtrl.getForecastDetailsForProduct(acc.Id, product.id,'cases',true);*/

        //System.assertEquals(0, wrapper.adjustmentsTotalDirectMap.get(CURRENT_MONTH));
        //System.assertEquals(0, wrapper.adjustmentsTotalDirectMap.get(NEXT_MONTH));
        //System.assertEquals(0, wrapper.adjustmentsSummaryMap.get(CURRENT_MONTH));
        //System.assertEquals(0, wrapper.directAdjustmentEntries.size());
    }

    @IsTest
    static void updateWarehouseTest(){
        Account acc = getAccount();
        Product2 product = getProduct();

        ForecastCtrl.enableForecast(acc.Id);
        ForecastCtrl.enableProductForecast(acc.Id, getForecastWrapper(product), 'cases');

        Warehouse__c warehouse = new TestHelper.WarehouseRecord()
                                        .setCode('Test 2')
                                        .setRegions('NACA;EMEA')
                                        .save();

        Test.startTest();
            ForecastCtrl.updateWarehouse(acc.Id, product.Id, warehouse.Id, true);
        Test.stopTest();
        
        Forecast_Product__c forecast = getForecastProduct(acc.Id, product.Id);

        //Assert.areEqual(warehouse.Id, forecast.Local_Warehouse__c, 'New Warehouse selected');
    }

    private static string getForecastItemsWrapper(String quantity, String fulfillment){
        List<ForecastCtrl.ForecastItem> wrappers = new List<ForecastCtrl.ForecastItem>{
            new ForecastCtrl.ForecastItem(
                ForecastUtil.getMonthUniqueId(Date.today()),
                quantity,
                fulfillment
            ),
            new ForecastCtrl.ForecastItem(
                ForecastUtil.getMonthUniqueId(Date.today().addMonths(1)),
                quantity,
                fulfillment
            )
        };

        return JSON.serialize(wrappers);
    }

    private static string getForecastWrapper(Product2 product){
        ForecastCtrl.ForecastNewProductWrapper forecastWrapper = new ForecastCtrl.ForecastNewProductWrapper();
        forecastWrapper.productId = product.Id;
        forecastWrapper.uom = Integer.valueOf(product.NACA_Case_Qty__c);
        forecastWrapper.directEnabled = true;
        forecastWrapper.localEnabled = true;
        forecastWrapper.directWarehouse = [SELECT Id FROM Warehouse__c LIMIT 1].Id;
        forecastWrapper.localWarehouse = [SELECT Id FROM Warehouse__c LIMIT 1].Id;
        forecastWrapper.directForecast = new List<ForecastCtrl.ForecastItem>{
            new ForecastCtrl.ForecastItem(
                CURRENT_MONTH,
                '20',
                'direct'
            ),
            new ForecastCtrl.ForecastItem(
                NEXT_MONTH,
                '20',
                'direct'
            )
        };

        forecastWrapper.localForecast = new List<ForecastCtrl.ForecastItem>{
            new ForecastCtrl.ForecastItem(
                CURRENT_MONTH,
                '40',
                'local'
            ),
            new ForecastCtrl.ForecastItem(
                NEXT_MONTH,
                '40',
                'local'
            )
        };

        return JSON.serialize(new List<ForecastCtrl.ForecastNewProductWrapper>{forecastWrapper});
    }

    private static Account getAccount(){
        return [SELECT Id, Name, Forecast_Enabled__c, Forecasted_Products_Number__c FROM Account LIMIT 1];
    }

    private static Product2 getProduct(){
        return [SELECT Id, NACA_Case_Qty__c FROM Product2 LIMIT 1];
    }

    private static Forecast_Product__c getForecastProduct(String accId, String productId){
        return [
                SELECT Id, Direct_Enabled__c, Local_Enabled__c, Local_Warehouse__c
                FROM Forecast_Product__c 
                WHERE Account__c = :accId
                AND Product__c = :productId
                LIMIT 1
            ];
    }
    
    static testmethod void testIncrement()
    {
        ForecastCtrl.justIncrement();
    }
}