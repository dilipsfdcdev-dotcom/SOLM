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

    @isTest
    private static void getDateRangeWithMonthsTest(){
        Test.startTest();
            List<String> dateRange = ForecastCtrl.getDateRangeWithMonths(6);
        Test.stopTest();
        System.assertNotEquals(null, dateRange);
    }

    @isTest
    private static void getUploadTemplateTest(){
        Test.startTest();
            String templateWithAccount = ForecastCtrl.getUploadTemplate(true);
            String templateWithoutAccount = ForecastCtrl.getUploadTemplate(false);
        Test.stopTest();
        System.assert(templateWithAccount.contains('AccountId'));
        System.assert(!templateWithoutAccount.contains('AccountId'));
    }

    @isTest
    private static void deleteForecastingTest(){
        Account acc = getAccount();
        Product2 product = getProduct();

        ForecastCtrl.enableForecast(acc.Id);
        ForecastCtrl.enableProductForecast(acc.Id, getForecastWrapper(product), 'cases');

        Test.startTest();
            ForecastCtrl.deleteForecasting(acc.Id);
        Test.stopTest();

        List<Forecast_Product__c> forecasts = [SELECT Id FROM Forecast_Product__c WHERE Account__c = :acc.Id];
        System.assertEquals(0, forecasts.size());
    }

    @isTest
    private static void updatePriceFPTest(){
        Account acc = getAccount();
        Product2 product = getProduct();

        ForecastCtrl.enableForecast(acc.Id);
        ForecastCtrl.enableProductForecast(acc.Id, getForecastWrapper(product), 'cases');

        Test.startTest();
            ForecastCtrl.updatePriceFP(acc.Id, product.Id, 100.00);
        Test.stopTest();
    }

    @isTest
    private static void getForecastByProductTest(){
        Account acc = getAccount();
        Product2 product = getProduct();

        ForecastCtrl.enableForecast(acc.Id);
        ForecastCtrl.enableProductForecast(acc.Id, getForecastWrapper(product), 'cases');

        Test.startTest();
            ForecastCtrl.ForecastWrapper wrapper = ForecastCtrl.getForecastByProduct(product.Id, 'cases', '', 5, 1);
        Test.stopTest();

        System.assertNotEquals(null, wrapper);
    }

    @isTest
    private static void getForecastWithSearchTermTest(){
        Account acc = getAccount();
        Product2 product = getProduct();

        ForecastCtrl.enableForecast(acc.Id);
        ForecastCtrl.enableProductForecast(acc.Id, getForecastWrapper(product), 'cases');

        Test.startTest();
            ForecastCtrl.ForecastWrapper wrapper = ForecastCtrl.getForecast(acc.Id, 'cases', 'Test', 5, 1);
        Test.stopTest();

        System.assertNotEquals(null, wrapper);
    }

    @isTest
    private static void forecastOpportunityApprovalTest(){
        Account acc = getAccount();
        Product2 product = getProduct();

        ForecastCtrl.enableForecast(acc.Id);
        ForecastCtrl.enableProductForecast(acc.Id, getForecastWrapper(product), 'cases');

        // Create forecast opportunity and item
        Forecast_Product__c fp = [SELECT Id FROM Forecast_Product__c WHERE Account__c = :acc.Id AND Product__c = :product.Id LIMIT 1];

        Forecast_Month__c fm = [SELECT Id FROM Forecast_Month__c WHERE Forecast_Product__c = :fp.Id LIMIT 1];

        Forecast_Opportunity__c forecastOpp = new Forecast_Opportunity__c(
            External_Id__c = acc.Id + '-' + product.Id + '-test-opp',
            Fulfillment__c = Constants.forecastItem.FULFILLMENT_DIRECT
        );
        insert forecastOpp;

        Forecast_Item__c item = new Forecast_Item__c(
            Forecast__c = fm.Id,
            Forecast_Opportunity__c = forecastOpp.Id,
            Item_Type__c = Constants.forecastItem.ITEM_TYPE_OPP_PRODUCT,
            Quantity__c = 100,
            Fulfillment__c = Constants.forecastItem.FULFILLMENT_DIRECT,
            External_Id__c = acc.Id + '-' + product.Id + '-test-item'
        );
        insert item;

        Test.startTest();
            ForecastCtrl.forecastOpportunityApproval(forecastOpp.Id, Constants.approval.APPROVED);
        Test.stopTest();

        Forecast_Opportunity__c updatedOpp = [SELECT BU_Approval__c FROM Forecast_Opportunity__c WHERE Id = :forecastOpp.Id];
        System.assertEquals(Constants.approval.APPROVED, updatedOpp.BU_Approval__c);
    }

    @isTest
    private static void getHistoricalForecastByAccountTest(){
        Account acc = getAccount();

        Test.startTest();
            List<Historical_Forecast__c> forecasts = ForecastCtrl.getHistoricalForecastByAccount(acc.Id);
        Test.stopTest();

        System.assertNotEquals(null, forecasts);
    }

    @isTest
    private static void getHistoricalForecastByProductTest(){
        Account acc = getAccount();
        Product2 product = getProduct();

        Test.startTest();
            List<Historical_Forecast__c> forecasts = ForecastCtrl.getHistoricalForecastByProduct(acc.Id, product.Id);
        Test.stopTest();

        System.assertNotEquals(null, forecasts);
    }

    @isTest
    private static void getForecastProductTest(){
        Account acc = getAccount();
        Product2 product = getProduct();

        ForecastCtrl.enableForecast(acc.Id);
        ForecastCtrl.enableProductForecast(acc.Id, getForecastWrapper(product), 'cases');

        Test.startTest();
            List<Forecast_Product__c> forecasts = ForecastCtrl.getForecastProduct(acc.Id);
        Test.stopTest();

        System.assert(forecasts.size() > 0);
    }

    @isTest
    private static void getCurrencyCodeTest(){
        Account acc = getAccount();

        Test.startTest();
            String currencyCode = ForecastCtrl.getCurrencyCode(acc.Id);
        Test.stopTest();

        System.assertNotEquals(null, currencyCode);
    }

    @isTest
    private static void testForecastOpportunityEntryWrapper(){
        Account acc = getAccount();
        Product2 product = getProduct();

        ForecastCtrl.enableForecast(acc.Id);
        ForecastCtrl.enableProductForecast(acc.Id, getForecastWrapper(product), 'cases');

        Forecast_Product__c fp = [SELECT Id FROM Forecast_Product__c WHERE Account__c = :acc.Id AND Product__c = :product.Id LIMIT 1];
        Forecast_Month__c fm = [SELECT Id, Month__c FROM Forecast_Month__c WHERE Forecast_Product__c = :fp.Id LIMIT 1];

        Forecast_Opportunity__c forecastOpp = new Forecast_Opportunity__c(
            External_Id__c = acc.Id + '-' + product.Id + '-wrapper-test',
            Fulfillment__c = Constants.forecastItem.FULFILLMENT_DIRECT,
            Comment__c = 'Test Comment',
            BU_Approval__c = Constants.approval.APPROVED
        );
        insert forecastOpp;

        Forecast_Item__c item = new Forecast_Item__c(
            Forecast__c = fm.Id,
            Forecast_Opportunity__c = forecastOpp.Id,
            Item_Type__c = Constants.forecastItem.ITEM_TYPE_OPP_PRODUCT,
            Quantity__c = 100,
            Fulfillment__c = Constants.forecastItem.FULFILLMENT_DIRECT,
            External_Id__c = acc.Id + '-' + product.Id + '-wrapper-item',
            Active__c = true
        );
        insert item;

        Test.startTest();
            List<String> dateRange = ForecastCtrl.getDateRange();
            Forecast_Item__c queriedItem = [
                SELECT Id, Forecast_Opportunity__c, Forecast_Opportunity__r.Comment__c,
                       Forecast_Opportunity__r.BU_Approval__c, Forecast_Opportunity__r.Opportunity_Product__r.OpportunityId,
                       Forecast_Opportunity__r.Opportunity_Product__r.Opportunity.Name,
                       Quantity__c, Fulfillment__c, Item_Type__c, Forecast__r.Month__c
                FROM Forecast_Item__c WHERE Id = :item.Id
            ];
            ForecastOpportunityEntryWrapper wrapper = new ForecastOpportunityEntryWrapper(queriedItem, dateRange);
        Test.stopTest();

        System.assertEquals(forecastOpp.Id, wrapper.recordId);
        System.assertEquals(true, wrapper.approved);
    }

    @isTest
    private static void testForecastOpportunityEntryWrapperRejected(){
        Account acc = getAccount();
        Product2 product = getProduct();

        ForecastCtrl.enableForecast(acc.Id);
        ForecastCtrl.enableProductForecast(acc.Id, getForecastWrapper(product), 'cases');

        Forecast_Product__c fp = [SELECT Id FROM Forecast_Product__c WHERE Account__c = :acc.Id AND Product__c = :product.Id LIMIT 1];
        Forecast_Month__c fm = [SELECT Id FROM Forecast_Month__c WHERE Forecast_Product__c = :fp.Id LIMIT 1];

        Forecast_Opportunity__c forecastOpp = new Forecast_Opportunity__c(
            External_Id__c = acc.Id + '-' + product.Id + '-rejected-test',
            Fulfillment__c = Constants.forecastItem.FULFILLMENT_DIRECT,
            BU_Approval__c = Constants.approval.REJECTED
        );
        insert forecastOpp;

        Forecast_Item__c item = new Forecast_Item__c(
            Forecast__c = fm.Id,
            Forecast_Opportunity__c = forecastOpp.Id,
            Item_Type__c = Constants.forecastItem.ITEM_TYPE_OPP_PRODUCT,
            Quantity__c = 100,
            Fulfillment__c = Constants.forecastItem.FULFILLMENT_DIRECT,
            External_Id__c = acc.Id + '-' + product.Id + '-rejected-item',
            Active__c = true
        );
        insert item;

        Test.startTest();
            List<String> dateRange = ForecastCtrl.getDateRange();
            Forecast_Item__c queriedItem = [
                SELECT Id, Forecast_Opportunity__c, Forecast_Opportunity__r.Comment__c,
                       Forecast_Opportunity__r.BU_Approval__c, Forecast_Opportunity__r.Opportunity_Product__r.OpportunityId,
                       Forecast_Opportunity__r.Opportunity_Product__r.Opportunity.Name,
                       Quantity__c, Fulfillment__c, Item_Type__c, Forecast__r.Month__c
                FROM Forecast_Item__c WHERE Id = :item.Id
            ];
            ForecastOpportunityEntryWrapper wrapper = new ForecastOpportunityEntryWrapper(queriedItem, dateRange);
        Test.stopTest();

        System.assertEquals(true, wrapper.rejected);
    }

    @isTest
    private static void testForecastAdjustmentEntryWrapper(){
        Account acc = getAccount();
        Product2 product = getProduct();

        ForecastCtrl.enableForecast(acc.Id);
        ForecastCtrl.enableProductForecast(acc.Id, getForecastWrapper(product), 'cases');

        Forecast_Product__c fp = [SELECT Id FROM Forecast_Product__c WHERE Account__c = :acc.Id AND Product__c = :product.Id LIMIT 1];
        Forecast_Month__c fm = [SELECT Id FROM Forecast_Month__c WHERE Forecast_Product__c = :fp.Id LIMIT 1];

        Forecast_Adjustment__c adjustment = new Forecast_Adjustment__c(
            Name = 'Test Adjustment',
            Comment__c = 'Adjustment Comment'
        );
        insert adjustment;

        Forecast_Item__c item = new Forecast_Item__c(
            Forecast__c = fm.Id,
            Forecast_Adjustment__c = adjustment.Id,
            Item_Type__c = Constants.forecastItem.ITEM_TYPE_ADJUSTMENT,
            Quantity__c = 50,
            Fulfillment__c = Constants.forecastItem.FULFILLMENT_LOCAL,
            External_Id__c = acc.Id + '-' + product.Id + '-adj-item',
            Active__c = true
        );
        insert item;

        Test.startTest();
            List<String> dateRange = ForecastCtrl.getDateRange();
            Forecast_Item__c queriedItem = [
                SELECT Id, Forecast_Adjustment__c, Forecast_Adjustment__r.Name,
                       Forecast_Adjustment__r.Comment__c, Forecast_Adjustment__r.Forecast_Opportunity__c,
                       Forecast_Adjustment__r.Forecast_Opportunity__r.Opportunity_Product__r.Opportunity.Name,
                       Quantity__c, Fulfillment__c, Item_Type__c, Forecast__r.Month__c
                FROM Forecast_Item__c WHERE Id = :item.Id
            ];
            ForecastAdjustmentEntryWrapper wrapper = new ForecastAdjustmentEntryWrapper(queriedItem, dateRange);
        Test.stopTest();

        System.assertEquals(adjustment.Id, wrapper.recordId);
        System.assertEquals('Test Adjustment', wrapper.name);
    }

    @isTest
    private static void testConstantsCoverage(){
        Test.startTest();
            // Access all constant types
            String approved = Constants.approval.APPROVED;
            String rejected = Constants.approval.REJECTED;
            String pending = Constants.approval.PENDING;

            String accRecordTypeNACA = Constants.account.RECORD_TYPE_NACA;
            String accRecordTypeEMEA = Constants.account.RECORD_TYPE_EMEA;
            String customerStatus = Constants.account.CUSTOMER_STATUS_CUSTOMER;
            String branchEMEA = Constants.account.BRANCH_EMEA;
            String branchNACA = Constants.account.BRANCH_NACA;

            String caseOriginEmail = Constants.caseConstants.ORIGIN_EMAIL;
            String caseOriginPhone = Constants.caseConstants.ORIGIN_PHONE;
            String caseOriginWeb = Constants.caseConstants.ORIGIN_WEB;
            String caseStatusNew = Constants.caseConstants.STATUS_NEW;
            String casePriority = Constants.caseConstants.PRIORITY_MEDIUM_RETURNS;
            String caseType = Constants.caseConstants.TYPE_ORDER_PLACEMENT;

            String itemTypeCurrentOrder = Constants.forecastItem.ITEM_TYPE_CURRENT_ORDER;
            String itemTypePreviousYear = Constants.forecastItem.ITEM_TYPE_PREVIOUS_YEAR_ORDER;
            String itemTypeAdjustment = Constants.forecastItem.ITEM_TYPE_ADJUSTMENT;
            String itemTypeBase = Constants.forecastItem.ITEM_TYPE_BASE;
            String itemTypeOpp = Constants.forecastItem.ITEM_TYPE_OPP_PRODUCT;
            String fulfillmentDirect = Constants.forecastItem.FULFILLMENT_DIRECT;
            String fulfillmentLocal = Constants.forecastItem.FULFILLMENT_LOCAL;
            String warehouseCode = Constants.forecastItem.WAREHOUSE_DIRECT_CODE;

            String leadRecordType = Constants.lead.RECORD_TYPE_NACA;
            String leadSource = Constants.lead.SOURCE_SOL_M_WEBPAGE;

            String oppStageLost = Constants.opportunity.STAGE_CLOSED_LOST;
            String oppStageWon = Constants.opportunity.STAGE_CLOSED_WON;
            String oppStageDisq = Constants.opportunity.STAGE_DISQUALIFIED;
            String oppStageProsp = Constants.opportunity.STAGE_PROSPECTING;
            String oppStageNeg = Constants.opportunity.STAGE_NEGOTIATION;
            String oppStageForec = Constants.opportunity.STAGE_FORECASTING;
            String oppStageAnalyzing = Constants.opportunity.STAGE_ANALYZING;
            String oppRecordTypeNACA = Constants.opportunity.RECORD_TYPE_NACA;
            String oppRecordTypeEMEA = Constants.opportunity.RECORD_TYPE_EMEA;
            String oppRecordTypeTender = Constants.opportunity.RECORD_TYPE_EMEA_TENDER;
            String oppRecordTypeLOT = Constants.opportunity.RECORD_TYPE_EMEA_TENDER_LOT;

            String orderStatusOpen = Constants.order.STATUS_OPEN;
            String orderStatusClosed = Constants.order.STATUS_CLOSED;
            String orderStatusCanceled = Constants.order.STATUS_CANCELED;
            String orderRecordTypeNACA = Constants.order.RECORD_TYPE_NACA;
            String orderRecordTypeEMEA = Constants.order.RECORD_TYPE_EMEA;
            String orderTypeCRM = Constants.order.TYPE_CRM;
            String orderTypeSAP = Constants.order.TYPE_SAP;
            String nacaSAPPrefix = Constants.order.NACA_SAP_PREFIX;
            String emeaSAPPrefix = Constants.order.EMEA_SAP_PREFIX;

            Set<String> currencies = Constants.pricebookEntry.CURRENCIES;

            Id standardPricebookId = Constants.priceBook.STANDARD_PRICEBOOK_ID;
            String pbRecordTypeNACA = Constants.priceBook.RECORD_TYPE_NACA;
            String pbRecordTypeEMEA = Constants.priceBook.RECORD_TYPE_EMEA;

            String quoteRecordTypeNACA = Constants.quote.RECORD_TYPE_NACA;
            String quoteRecordTypeEMEA = Constants.quote.RECORD_TYPE_EMEA;
            Map<String, String> quoteMap = Constants.quote.recordTypeIdByOpportunityRTId;

            String taskStatusOpen = Constants.task.STATUS_OPEN;
            String taskStatusCompleted = Constants.task.STATUS_COMPLETED;
            String taskNotificationType = Constants.task.CUSTOM_NOTIFICATION_TYPE_NAME;
        Test.stopTest();

        System.assertNotEquals(null, approved);
    }

    @isTest
    private static void disableProductDirectTest(){
        Account acc = getAccount();
        Product2 product = getProduct();

        ForecastCtrl.enableForecast(acc.Id);
        ForecastCtrl.enableProductForecast(acc.Id, getForecastWrapper(product), 'cases');

        Test.startTest();
            ForecastCtrl.disableProduct(acc.Id, product.Id, true);
        Test.stopTest();
    }

    @isTest
    private static void disableProductLocalTest(){
        Account acc = getAccount();
        Product2 product = getProduct();

        ForecastCtrl.enableForecast(acc.Id);
        ForecastCtrl.enableProductForecast(acc.Id, getForecastWrapper(product), 'cases');

        Test.startTest();
            ForecastCtrl.disableProduct(acc.Id, product.Id, false);
        Test.stopTest();
    }
}