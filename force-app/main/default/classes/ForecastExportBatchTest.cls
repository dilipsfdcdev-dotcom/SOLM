@isTest
private class ForecastExportBatchTest {
	private final static Integer PRODUCT_UOM = 100;
	private final static String PRODUCT_NAME = 'Test-product';
	private final static String PRODUCT_CODE = '001';

	private final static String ACCOUNT_NAME = 'Test-account';
	private final static String DEFAULT_PARTNER_NAME = 'Test-partner';
    private final static String OPP_PARTNER_NAME = 'Test-opp-partner';

	private final static String ACCOUNT_CODE = 'NACA-100';
	private final static String DEFAULT_PARTNER_CODE = 'NACA-200';
    private final static String OPP_PARTNER_CODE = 'NACA-300';

    private final static String WAREHOUSE_NAME = 'SMUS.320';

    private final static String PRICEBOOK_NAME = 'Test-ForecastExportBatchTest-pricebook';
    private final static String OPPORTUNITY_NAME = 'Test-opp';

    private final static String ADJUSTMENT_NAME = 'Test-adj';

    private final static Date CURRENT_MONTH = System.today().toStartOfMonth();
    private final static Date NEXT_MONTH = System.today().addMonths(1).toStartOfMonth();

    @TestSetup
    static void makeData(){
        Account account = new TestHelper.AccountRecord()
                .setName(ACCOUNT_NAME)
                .asNACA()
                .setSAPCode(ACCOUNT_CODE)
                .setForecasting(true)
                .build();

        Account defaultPartner = new TestHelper.AccountRecord()
                .setName(DEFAULT_PARTNER_NAME)
                .asNACA()
                .setSAPCode(DEFAULT_PARTNER_CODE)
                .build();

        Account oppPartner = new TestHelper.AccountRecord()
                .setName(OPP_PARTNER_NAME)
                .asNACA()
                .setSAPCode(OPP_PARTNER_CODE)
                .build();

        insert new List<Account>{
            account, defaultPartner, oppPartner
        };

        account.Default_Partner__c = defaultPartner.Id;
        update account;

		Product2 testProduct = new TestHelper.ProductRecord()
				.setName(PRODUCT_NAME)
				.setNACAQuantity(PRODUCT_UOM)
                .setEMEAQuantity(PRODUCT_UOM)
				.enableQuantitySchedule()
                .setSAPCode(PRODUCT_CODE)
				.save();

        Pricebook2 customPricebook = new TestHelper.PricebookRecord().setName(PRICEBOOK_NAME).save();
        PricebookEntry pbe = new TestHelper.PricebookEntryRecord(customPricebook.Id, testProduct.Id).save();


		Opportunity opp = new TestHelper.OpportunityRecord (
            OPPORTUNITY_NAME, 
            account.Id, 
            Constants.opportunity.RECORD_TYPE_NACA_ID 
        )
        .setPricebookId(customPricebook.Id)
        .setStage(Constants.opportunity.STAGE_CLOSED_WON)
        .setPartner(getAccount(OPP_PARTNER_NAME).Id)
        .save();

        OpportunityLineItem oppLineItem = new TestHelper.OpportunityLineItemRecord(
            opp.Id,
            pbe.Id,
            testProduct.Id
        ).save();

		Forecast_Product__c forecastProduct = new TestHelper.ForecastProductRecord(
            account.Id, 
            testProduct.Id
        )
        .setFulfillment('both')
        .setWarehouse(        
            new TestHelper.WarehouseRecord()
                .setCode(WAREHOUSE_NAME)
                .setRegions('NACA;EMEA')
                .save()
        )
        .save();

		Forecast_Month__c currentMonth = new TestHelper.ForecastMonthRecord(CURRENT_MONTH, forecastProduct.Id).build();
        Forecast_Month__c nextMonth = new TestHelper.ForecastMonthRecord(NEXT_MONTH, forecastProduct.Id).build();

		insert new List<Forecast_Month__c>{
            currentMonth,
            nextMonth
        };

        insert new List<Forecast_Item__c>{
            new TestHelper.ForecastItemRecord()
                .asLocal()
                .asBase()
                .setForecastMonth(currentMonth.Id)
                .build(),
            new TestHelper.ForecastItemRecord()
                .asLocal()
                .asBase()
                .setForecastMonth(nextMonth.Id)
                .build(),
            new TestHelper.ForecastItemRecord()
                .asDirect()
                .asBase()
                .setForecastMonth(currentMonth.Id)
                .build(),
            new TestHelper.ForecastItemRecord()
                .asDirect()
                .asBase()
                .setForecastMonth(nextMonth.Id)
                .build()
        };
    }

    private static final String CRON_EXP = '0 0 1 1 * ?';
	private static final String JOB_NAME = 'ForecastExportBatchRun';

	@IsTest
	static void schedulerTest() {
		Test.startTest();
		String jobId = System.schedule(JOB_NAME, CRON_EXP, new ForecastExportBatchScheduler(
            new ForecastExportBatch(), 50
        ));
		CronTrigger ct = [
				SELECT Id, CronExpression, TimesTriggered, NextFireTime
				FROM CronTrigger
				WHERE Id = :jobId
		];
		System.assertEquals(CRON_EXP, ct.CronExpression);
		System.assertEquals(0, ct.TimesTriggered);
		Test.stopTest();
	}

    @isTest
    static void batchSuccessTest(){
        Test.setMock(HttpCalloutMock.class, new ForecastResponseMock()); 

        Test.startTest();
            Database.executebatch(new ForecastExportBatch());
        Test.stopTest();

        List<Log__c> logs = [SELECT Id, Message__c FROM Log__c];
        System.assertEquals(0, logs.size(), 'No errors reported');
    }
    
    @isTest
    static void batchFailureTest(){
        Test.setMock(HttpCalloutMock.class, new MOCK_SAP_NoAuthResponse()); 

        Test.startTest();
            Database.executebatch(new ForecastExportBatch());
        Test.stopTest();

        List<Log__c> logs = [SELECT Id, Message__c FROM Log__c];
        System.assertEquals(1, logs.size(), 'Errors reported');
    }

    @isTest
    static void base_both_active_Test(){
        Test.setMock(HttpCalloutMock.class, new ForecastResponseMock()); 

        Test.startTest();
            Database.executebatch(new ForecastExportBatch());
        Test.stopTest();

        List<ForecastExportWrapper> wrappers = (List<ForecastExportWrapper>) JSON.deserialize(ForecastExportBatch.payloadForTests, List<ForecastExportWrapper> .class);

        Assert.areEqual(4, wrappers.size(), 'Base forecast entries');

        for(ForecastExportWrapper wrapper: wrappers){
            Assert.areEqual(Constants.account.BRANCH_NACA, wrapper.Branch);
            Assert.areEqual(Constants.forecastItem.ITEM_TYPE_BASE, wrapper.DemandType);
        
            Assert.areEqual(ACCOUNT_CODE.substringAfter('-'), wrapper.AccountCode);
            Assert.areEqual(ACCOUNT_NAME, wrapper.AccountName);
            Assert.areEqual(DEFAULT_PARTNER_CODE.substringAfter('-'), wrapper.PartnerCode);
            Assert.areEqual(DEFAULT_PARTNER_NAME, wrapper.PartnerName);

            Assert.areEqual(PRODUCT_CODE, wrapper.ProductCode);
            
            Assert.isNull(wrapper.OpportunityName);
            Assert.isNull(wrapper.AdjustmentName);
            Assert.isNull(wrapper.OpportunityPricebook);

            Assert.areEqual(0, Integer.valueOf(wrapper.OpportunityPrice));
            Assert.areEqual('Active', wrapper.ForecastStatus);
        }

        List<ForecastExportWrapper> direct = filterWrappersByShipment(wrappers, Constants.forecastItem.FULFILLMENT_DIRECT);
        List<ForecastExportWrapper> local = filterWrappersByShipment(wrappers, Constants.forecastItem.FULFILLMENT_LOCAL);

        Assert.areEqual(2, direct.size(), 'Direct forecast entries');
        Assert.areEqual(2, local.size(), 'Local forecast entries');

        for(ForecastExportWrapper wrapper: direct){
            wrapper.Warehouse = Constants.forecastItem.WAREHOUSE_DIRECT_CODE;
        }

        for(ForecastExportWrapper wrapper: local){
            wrapper.Warehouse = WAREHOUSE_NAME;
        }
    }

    @isTest
    static void account_forecast_inactive_Test(){
        Test.setMock(HttpCalloutMock.class, new ForecastResponseMock()); 

        Account acc = getAccount(ACCOUNT_NAME);
        acc.Forecast_Enabled__c = false;
        update acc;

        Test.startTest();
            Database.executebatch(new ForecastExportBatch());
        Test.stopTest();

        List<ForecastExportWrapper> wrappers = (List<ForecastExportWrapper>) JSON.deserialize(ForecastExportBatch.payloadForTests, List<ForecastExportWrapper> .class);

        Assert.areEqual(4, wrappers.size(), 'Base forecast entries');

        for(ForecastExportWrapper wrapper: wrappers){
            Assert.isFalse(Boolean.valueOf(wrapper.ForecastStatus));
        }
    }

    @isTest
    static void direct_inactive_Test(){
        Test.setMock(HttpCalloutMock.class, new ForecastResponseMock()); 

        Account acc = getAccount(ACCOUNT_NAME);
        Product2 product = getProduct(PRODUCT_NAME);

        Forecast_Product__c forecastProduct = getForecastProduct(acc.Id, product.Id);
        forecastProduct.Direct_Enabled__c = false;
        update forecastProduct;

        Test.startTest();
            Database.executebatch(new ForecastExportBatch());
        Test.stopTest();

        List<ForecastExportWrapper> wrappers = (List<ForecastExportWrapper>) JSON.deserialize(ForecastExportBatch.payloadForTests, List<ForecastExportWrapper> .class);
        List<ForecastExportWrapper> direct = filterWrappersByShipment(wrappers, Constants.forecastItem.FULFILLMENT_DIRECT);
        List<ForecastExportWrapper> local = filterWrappersByShipment(wrappers, Constants.forecastItem.FULFILLMENT_LOCAL);

        Assert.areEqual(2, direct.size(), 'Direct forecast entries');
        Assert.areEqual(2, local.size(), 'Local forecast entries');

        for(ForecastExportWrapper wrapper: direct){
            Assert.areEqual('Inactive', wrapper.ForecastStatus);
        }

        for(ForecastExportWrapper wrapper: local){
            Assert.areEqual('Active', wrapper.ForecastStatus);
        }
    }

    @isTest
    static void opportunity_approved_Test(){
        Test.setMock(HttpCalloutMock.class, new ForecastResponseMock()); 

        Account acc = getAccount(ACCOUNT_NAME);
        Product2 product = getProduct(PRODUCT_NAME);
        Forecast_Product__c forecastProduct = getForecastProduct(acc.Id, product.Id);
        OpportunityLineItem oppLineItem = getOppLineItem();

        Forecast_Opportunity__c forecastOpp = new TestHelper.ForecastOpportunityRecord(oppLineItem.Id, Constants.forecastItem.FULFILLMENT_LOCAL).save();
        List<Forecast_Month__c> months = getForecastMonths();

        insert new List<Forecast_Item__c>{
            new TestHelper.ForecastItemRecord()
                .asLocal()
                .asOpportunity()
                .setForecastOpportunityId(forecastOpp.Id)
                .setApproval(Constants.approval.APPROVED)
                .setForecastMonth(months[0].Id)
                .build(),
            new TestHelper.ForecastItemRecord()
                .asLocal()
                .asOpportunity()
                .setForecastOpportunityId(forecastOpp.Id)
                .setApproval(Constants.approval.APPROVED)
                .setForecastMonth(months[1].Id)
                .build()
        };

        Test.startTest();
            Database.executebatch(new ForecastExportBatch());
        Test.stopTest();

        List<ForecastExportWrapper> wrappers = (List<ForecastExportWrapper>) JSON.deserialize(ForecastExportBatch.payloadForTests, List<ForecastExportWrapper> .class);
        List<ForecastExportWrapper> opps = filterWrappersByDemand(wrappers, Constants.forecastItem.ITEM_TYPE_OPP_PRODUCT);
        List<ForecastExportWrapper> base = filterWrappersByDemand(wrappers, Constants.forecastItem.ITEM_TYPE_BASE);

        Assert.areEqual(2, opps.size(), 'Opportunity forecast entries');
        Assert.areEqual(4, base.size(), 'Base forecast entries');

        for(ForecastExportWrapper wrapper: opps){
            Assert.areEqual('Active', wrapper.ForecastStatus);
            
            Assert.areEqual(OPP_PARTNER_CODE.substringAfter('-'), wrapper.PartnerCode);
            Assert.areEqual(OPP_PARTNER_NAME, wrapper.PartnerName);
            Assert.areEqual(OPPORTUNITY_NAME, wrapper.OpportunityName);

            Assert.areEqual(PRICEBOOK_NAME, wrapper.OpportunityPricebook);
            Assert.areEqual(10, Integer.valueOf(wrapper.OpportunityPrice));            
        }

        for(ForecastExportWrapper wrapper: base){
            Assert.areEqual('Active', wrapper.ForecastStatus);
            Assert.areEqual(DEFAULT_PARTNER_CODE.substringAfter('-'), wrapper.PartnerCode);
            Assert.areEqual(DEFAULT_PARTNER_NAME, wrapper.PartnerName);
        }
    }

    @isTest
    static void opportunity_deleted_Test(){
        Test.setMock(HttpCalloutMock.class, new ForecastResponseMock()); 

        Account acc = getAccount(ACCOUNT_NAME);
        Product2 product = getProduct(PRODUCT_NAME);
        Forecast_Product__c forecastProduct = getForecastProduct(acc.Id, product.Id);
        OpportunityLineItem oppLineItem = getOppLineItem();

        Forecast_Opportunity__c forecastOpp = new TestHelper.ForecastOpportunityRecord(oppLineItem.Id, Constants.forecastItem.FULFILLMENT_LOCAL).save();
        List<Forecast_Month__c> months = getForecastMonths();

        new TestHelper.ForecastItemRecord()
            .asLocal()
            .asOpportunity()
            .setForecastOpportunityId(forecastOpp.Id)
            .setApproval(Constants.approval.APPROVED)
            .setForecastMonth(months[0].Id)
            .save();
  
        delete [SELECT Id FROM Opportunity];

        Test.startTest();
            Database.executebatch(new ForecastExportBatch());
        Test.stopTest();

        List<ForecastExportWrapper> wrappers = (List<ForecastExportWrapper>) JSON.deserialize(ForecastExportBatch.payloadForTests, List<ForecastExportWrapper> .class);
        List<ForecastExportWrapper> opps = filterWrappersByDemand(wrappers, Constants.forecastItem.ITEM_TYPE_OPP_PRODUCT);

        Assert.areEqual(1, opps.size(), 'Opportunity forecast entries');

        for(ForecastExportWrapper wrapper: opps){
            Assert.isFalse(Boolean.valueOf(wrapper.ForecastStatus));
        }
    }

    @isTest
    static void adjustment_with_opportunity_Test(){
        Test.setMock(HttpCalloutMock.class, new ForecastResponseMock()); 

        Account acc = getAccount(ACCOUNT_NAME);
        Product2 product = getProduct(PRODUCT_NAME);
        OpportunityLineItem oppLineItem = getOppLineItem();

        Forecast_Opportunity__c forecastOpp = new TestHelper.ForecastOpportunityRecord(oppLineItem.Id, Constants.forecastItem.FULFILLMENT_LOCAL).save();
        Forecast_Adjustment__c forecastAdjustment = new TestHelper.ForecastAdjustmentRecord(ADJUSTMENT_NAME).setForecastOpportunity(forecastOpp.Id).save();
        List<Forecast_Month__c> months = getForecastMonths();

        insert new List<Forecast_Item__c>{
            new TestHelper.ForecastItemRecord()
                .asLocal()
                .asOpportunity()
                .setForecastOpportunityId(forecastOpp.Id)
                .setApproval(Constants.approval.APPROVED)
                .setForecastMonth(months[0].Id)
                .build(),
            new TestHelper.ForecastItemRecord()
                .asLocal()
                .asOpportunity()
                .setForecastOpportunityId(forecastOpp.Id)
                .setApproval(Constants.approval.APPROVED)
                .setForecastMonth(months[1].Id)
                .build(),
            new TestHelper.ForecastItemRecord()
                .asLocal()
                .asAdjustment()
                .setForecastOpportunityId(forecastOpp.Id)
                .setForecastAdjustmentId(forecastAdjustment.Id)
                .setForecastMonth(months[0].Id)
                .build(),
            new TestHelper.ForecastItemRecord()
                .asLocal()
                .asAdjustment()
                .setForecastOpportunityId(forecastOpp.Id)
                .setForecastAdjustmentId(forecastAdjustment.Id)
                .setForecastMonth(months[1].Id)
                .build()
        };

        Test.startTest();
            Database.executebatch(new ForecastExportBatch());
        Test.stopTest();

        List<ForecastExportWrapper> wrappers = (List<ForecastExportWrapper>) JSON.deserialize(ForecastExportBatch.payloadForTests, List<ForecastExportWrapper> .class);
        Assert.areEqual(8, wrappers.size(), 'All forecast entries');

        List<ForecastExportWrapper> adjustments = filterWrappersByDemand(wrappers, Constants.forecastItem.ITEM_TYPE_ADJUSTMENT);

        Assert.areEqual(2, adjustments.size(), 'Adjustment forecast entries');

        for(ForecastExportWrapper wrapper: adjustments){
            Assert.areEqual('Active', wrapper.ForecastStatus);
            Assert.areEqual(OPP_PARTNER_CODE.substringAfter('-'), wrapper.PartnerCode);
            Assert.areEqual(OPP_PARTNER_NAME, wrapper.PartnerName);
            Assert.areEqual(OPPORTUNITY_NAME, wrapper.OpportunityName);
            Assert.areEqual(ADJUSTMENT_NAME, wrapper.AdjustmentName);
            Assert.areEqual(PRICEBOOK_NAME, wrapper.OpportunityPricebook);  
            Assert.areEqual(Constants.forecastItem.FULFILLMENT_LOCAL, wrapper.ShipmentMethod);
            Assert.isNotNull(wrapper.OpportunityPrice);
        }
    }    

    @isTest
    static void adjustment_with_opportunity_delete_Test(){
        Test.setMock(HttpCalloutMock.class, new ForecastResponseMock()); 

        Account acc = getAccount(ACCOUNT_NAME);
        Product2 product = getProduct(PRODUCT_NAME);
        OpportunityLineItem oppLineItem = getOppLineItem();

        Forecast_Opportunity__c forecastOpp = new TestHelper.ForecastOpportunityRecord(oppLineItem.Id, Constants.forecastItem.FULFILLMENT_LOCAL).save();
        Forecast_Adjustment__c forecastAdjustment = new TestHelper.ForecastAdjustmentRecord(ADJUSTMENT_NAME).setForecastOpportunity(forecastOpp.Id).save();
        List<Forecast_Month__c> months = getForecastMonths();

        insert new List<Forecast_Item__c>{
            new TestHelper.ForecastItemRecord()
                .asLocal()
                .asOpportunity()
                .setForecastOpportunityId(forecastOpp.Id)
                .setApproval(Constants.approval.APPROVED)
                .setForecastMonth(months[0].Id)
                .build(),
            new TestHelper.ForecastItemRecord()
                .asLocal()
                .asOpportunity()
                .setForecastOpportunityId(forecastOpp.Id)
                .setApproval(Constants.approval.APPROVED)
                .setForecastMonth(months[1].Id)
                .build(),
            new TestHelper.ForecastItemRecord()
                .asLocal()
                .asAdjustment()
                .setForecastOpportunityId(forecastOpp.Id)
                .setForecastAdjustmentId(forecastAdjustment.Id)
                .setForecastMonth(months[0].Id)
                .build(),
            new TestHelper.ForecastItemRecord()
                .asLocal()
                .asAdjustment()
                .setForecastOpportunityId(forecastOpp.Id)
                .setForecastAdjustmentId(forecastAdjustment.Id)
                .setForecastMonth(months[1].Id)
                .build()
        };

        delete oppLineItem;

        Test.startTest();
            Database.executebatch(new ForecastExportBatch());
        Test.stopTest();

        List<ForecastExportWrapper> wrappers = (List<ForecastExportWrapper>) JSON.deserialize(ForecastExportBatch.payloadForTests, List<ForecastExportWrapper> .class);
        Assert.areEqual(8, wrappers.size(), 'All forecast entries');

        List<ForecastExportWrapper> adjustments = filterWrappersByDemand(wrappers, Constants.forecastItem.ITEM_TYPE_ADJUSTMENT);
        List<ForecastExportWrapper> opps = filterWrappersByDemand(wrappers, Constants.forecastItem.ITEM_TYPE_OPP_PRODUCT);

        Assert.areEqual(2, opps.size(), 'Opportunity forecast entries');
        Assert.areEqual(2, adjustments.size(), 'Adjustment forecast entries');

        for(ForecastExportWrapper wrapper: adjustments){
            Assert.isFalse(Boolean.valueOf(wrapper.ForecastStatus));
            Assert.isNull(wrapper.OpportunityName);
            Assert.areEqual(Constants.forecastItem.FULFILLMENT_LOCAL, wrapper.ShipmentMethod);
        }

        for(ForecastExportWrapper wrapper: opps){
            Assert.isFalse(Boolean.valueOf(wrapper.ForecastStatus));
            Assert.isNull(wrapper.OpportunityName);
            Assert.areEqual(Constants.forecastItem.FULFILLMENT_LOCAL, wrapper.ShipmentMethod);
        }
    }    

    @isTest
    static void adjustment_standalone_Test(){
        Test.setMock(HttpCalloutMock.class, new ForecastResponseMock()); 

        Account acc = getAccount(ACCOUNT_NAME);
        Product2 product = getProduct(PRODUCT_NAME);

        Forecast_Adjustment__c forecastAdjustment = new TestHelper.ForecastAdjustmentRecord(ADJUSTMENT_NAME).save();
        List<Forecast_Month__c> months = getForecastMonths();

        insert new List<Forecast_Item__c>{
            new TestHelper.ForecastItemRecord()
                .asLocal()
                .asAdjustment()
                .setForecastAdjustmentId(forecastAdjustment.Id)
                .setForecastMonth(months[0].Id)
                .build(),
            new TestHelper.ForecastItemRecord()
                .asLocal()
                .asAdjustment()
                .setForecastAdjustmentId(forecastAdjustment.Id)
                .setForecastMonth(months[1].Id)
                .build()
        };

        Test.startTest();
            Database.executebatch(new ForecastExportBatch());
        Test.stopTest();

        List<ForecastExportWrapper> wrappers = (List<ForecastExportWrapper>) JSON.deserialize(ForecastExportBatch.payloadForTests, List<ForecastExportWrapper> .class);
        Assert.areEqual(6, wrappers.size(), 'All forecast entries');

        List<ForecastExportWrapper> adjustments = filterWrappersByDemand(wrappers, Constants.forecastItem.ITEM_TYPE_ADJUSTMENT);
        Assert.areEqual(2, adjustments.size(), 'Adjustment forecast entries');

        for(ForecastExportWrapper wrapper: adjustments){
            Assert.areEqual('Active', wrapper.ForecastStatus);
            Assert.areEqual(DEFAULT_PARTNER_CODE.substringAfter('-'), wrapper.PartnerCode);
            Assert.areEqual(DEFAULT_PARTNER_NAME, wrapper.PartnerName);
            Assert.isNull(wrapper.OpportunityName);
            Assert.isNull(wrapper.OpportunityPricebook);
            Assert.areEqual(ADJUSTMENT_NAME, wrapper.AdjustmentName);
            Assert.areEqual(Constants.forecastItem.FULFILLMENT_LOCAL, wrapper.ShipmentMethod);
            Assert.areEqual(0, Integer.valueOf(wrapper.OpportunityPrice));            
        }
    }    

    private static List<ForecastExportWrapper> filterWrappersByDemand(List<ForecastExportWrapper> wrappers, String demandType){
        List<ForecastExportWrapper> filtered = new List<ForecastExportWrapper>();
        for(ForecastExportWrapper wrapper: wrappers){
            if(wrapper.DemandType == demandType){
                filtered.add(wrapper);
            }
        }
        return filtered;
    }

    private static List<ForecastExportWrapper> filterWrappersByShipment(List<ForecastExportWrapper> wrappers, String shipmentMethod){
        List<ForecastExportWrapper> filtered = new List<ForecastExportWrapper>();
        for(ForecastExportWrapper wrapper: wrappers){
            if(wrapper.ShipmentMethod == shipmentMethod){
                filtered.add(wrapper);
            }
        }
        return filtered;
    }

    private static Account getAccount(String name){
        return [
            SELECT Id, Name, Forecast_Enabled__c, Forecasted_Products_Number__c, LastModifiedDate 
            FROM Account 
            WHERE Name = :name
            LIMIT 1
        ];
    }

    private static Product2 getProduct(String name){
        return [
            SELECT Id, NACA_Case_Qty__c 
            FROM Product2 
            WHERE Name = :name
            LIMIT 1
        ];
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

	private static OpportunityLineItem getOppLineItem() {
		return [
				SELECT Id
				FROM OpportunityLineItem
				LIMIT 1
		];
	}

    private static List<Forecast_Month__c> getForecastMonths(){
        return [SELECT id, Month__c FROM Forecast_Month__c ORDER BY Month__c ASC];
    }

    public class ForecastResponseMock implements HttpCalloutMock{
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setBody('{"Msg": "Transmission finished successfully."}');
            response.setStatusCode(200);
            return response; 
        }
      }
}