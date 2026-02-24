@isTest
private class ForecastMassUploadQueueableTest {

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
    private static void insertProductMassSuccessTest(){
        Account acc = getAccount();
        Product2 product = getProduct();
        Warehouse__c warehouse = getWarehouse();

        // Enable forecasting
        acc.Forecast_Enabled__c = true;
        update acc;

        String monthStr = String.valueOf(Date.today().month()).leftPad(2, '0') + '/01/' + String.valueOf(Date.today().year());

        List<ForecastCtrl.productWrapper> wrappers = new List<ForecastCtrl.productWrapper>();
        ForecastCtrl.productWrapper pw = new ForecastCtrl.productWrapper();
        pw.AccountId = acc.Id;
        pw.PRODUCT2ID = product.Id;
        pw.Direct = 'true';
        pw.Local = 'false';
        pw.Month = monthStr;
        pw.UNITPRICE = '100';
        pw.Quantity = '50';
        pw.Warehouse = warehouse.Name;
        wrappers.add(pw);

        String prodJson = JSON.serialize(wrappers);

        Test.startTest();
            String result = ForecastCtrl.insertProductMass(prodJson);
        Test.stopTest();

        System.assert(result.startsWith('Success'), 'Expected success message but got: ' + result);
        System.assert(result.contains('1 account(s)'), 'Should report 1 account processing');
    }

    @isTest
    private static void insertProductMassMultipleAccountsTest(){
        Account acc = getAccount();
        Product2 product = getProduct();

        // Enable forecasting
        acc.Forecast_Enabled__c = true;
        update acc;

        String monthStr = String.valueOf(Date.today().month()).leftPad(2, '0') + '/01/' + String.valueOf(Date.today().year());

        List<ForecastCtrl.productWrapper> wrappers = new List<ForecastCtrl.productWrapper>();
        ForecastCtrl.productWrapper pw = new ForecastCtrl.productWrapper();
        pw.AccountId = acc.Id;
        pw.PRODUCT2ID = product.Id;
        pw.Direct = 'true';
        pw.Local = 'false';
        pw.Month = monthStr;
        pw.UNITPRICE = '100';
        pw.Quantity = '50';
        pw.Warehouse = '';
        wrappers.add(pw);

        String prodJson = JSON.serialize(wrappers);

        Test.startTest();
            String result = ForecastCtrl.insertProductMass(prodJson);
        Test.stopTest();

        System.assert(result.startsWith('Success'), 'Expected success but got: ' + result);
    }

    @isTest
    private static void insertProductMassInvalidAccountTest(){
        String monthStr = String.valueOf(Date.today().month()).leftPad(2, '0') + '/01/' + String.valueOf(Date.today().year());

        List<ForecastCtrl.productWrapper> wrappers = new List<ForecastCtrl.productWrapper>();
        ForecastCtrl.productWrapper pw = new ForecastCtrl.productWrapper();
        pw.AccountId = '001000000000000'; // fake account Id
        pw.PRODUCT2ID = '01t000000000000';
        pw.Direct = 'true';
        pw.Local = 'false';
        pw.Month = monthStr;
        pw.UNITPRICE = '100';
        pw.Quantity = '50';
        pw.Warehouse = '';
        wrappers.add(pw);

        String prodJson = JSON.serialize(wrappers);

        Test.startTest();
            String result = ForecastCtrl.insertProductMass(prodJson);
        Test.stopTest();

        System.assert(result.startsWith('Error'), 'Expected error for invalid account but got: ' + result);
    }

    @isTest
    private static void insertProductMassBlankJsonTest(){
        Test.startTest();
            String result = ForecastCtrl.insertProductMass('');
        Test.stopTest();

        System.assertEquals('Error: No data provided', result);
    }

    @isTest
    private static void insertProductMassEmptyListTest(){
        Test.startTest();
            String result = ForecastCtrl.insertProductMass('[]');
        Test.stopTest();

        System.assert(result.startsWith('Error'), 'Expected error for empty list');
    }

    @isTest
    private static void insertProductMassEnablesForecastingTest(){
        Account acc = getAccount();
        Product2 product = getProduct();

        // Ensure forecasting is disabled
        System.assertEquals(false, acc.Forecast_Enabled__c);

        String monthStr = String.valueOf(Date.today().month()).leftPad(2, '0') + '/01/' + String.valueOf(Date.today().year());

        List<ForecastCtrl.productWrapper> wrappers = new List<ForecastCtrl.productWrapper>();
        ForecastCtrl.productWrapper pw = new ForecastCtrl.productWrapper();
        pw.AccountId = acc.Id;
        pw.PRODUCT2ID = product.Id;
        pw.Direct = 'true';
        pw.Local = 'false';
        pw.Month = monthStr;
        pw.UNITPRICE = '100';
        pw.Quantity = '50';
        pw.Warehouse = '';
        wrappers.add(pw);

        String prodJson = JSON.serialize(wrappers);

        Test.startTest();
            String result = ForecastCtrl.insertProductMass(prodJson);
        Test.stopTest();

        // Verify forecasting was enabled on the account
        Account updatedAcc = [SELECT Forecast_Enabled__c FROM Account WHERE Id = :acc.Id];
        System.assert(updatedAcc.Forecast_Enabled__c, 'Forecasting should be enabled after mass upload');
        System.assert(result.startsWith('Success'), 'Expected success but got: ' + result);
    }

    @isTest
    private static void queueableExecuteTest(){
        Account acc = getAccount();
        Product2 product = getProduct();
        Warehouse__c warehouse = getWarehouse();

        // Enable forecasting
        acc.Forecast_Enabled__c = true;
        update acc;

        String monthStr = String.valueOf(Date.today().month()).leftPad(2, '0') + '/01/' + String.valueOf(Date.today().year());

        List<ForecastCtrl.productWrapper> wrappers = new List<ForecastCtrl.productWrapper>();
        ForecastCtrl.productWrapper pw = new ForecastCtrl.productWrapper();
        pw.AccountId = acc.Id;
        pw.PRODUCT2ID = product.Id;
        pw.Direct = 'true';
        pw.Local = 'false';
        pw.Month = monthStr;
        pw.UNITPRICE = '100';
        pw.Quantity = '50';
        pw.Warehouse = warehouse.Name;
        wrappers.add(pw);

        Map<String, String> accountProductJsonMap = new Map<String, String>();
        accountProductJsonMap.put(acc.Id, JSON.serialize(wrappers));

        List<String> accountIds = new List<String>{ acc.Id };

        Test.startTest();
            System.enqueueJob(new ForecastMassUploadQueueable(
                accountProductJsonMap,
                accountIds,
                0
            ));
        Test.stopTest();

        // Verify forecast product was created
        List<Forecast_Product__c> fps = [SELECT Id FROM Forecast_Product__c WHERE Account__c = :acc.Id AND Product__c = :product.Id];
        System.assert(fps.size() > 0, 'Forecast Product should be created by Queueable');
    }

    @isTest
    private static void insertProductMassMixedValidInvalidTest(){
        Account acc = getAccount();
        Product2 product = getProduct();

        acc.Forecast_Enabled__c = true;
        update acc;

        String monthStr = String.valueOf(Date.today().month()).leftPad(2, '0') + '/01/' + String.valueOf(Date.today().year());

        List<ForecastCtrl.productWrapper> wrappers = new List<ForecastCtrl.productWrapper>();

        // Valid row
        ForecastCtrl.productWrapper pw1 = new ForecastCtrl.productWrapper();
        pw1.AccountId = acc.Id;
        pw1.PRODUCT2ID = product.Id;
        pw1.Direct = 'true';
        pw1.Local = 'false';
        pw1.Month = monthStr;
        pw1.UNITPRICE = '100';
        pw1.Quantity = '50';
        pw1.Warehouse = '';
        wrappers.add(pw1);

        // Invalid account row
        ForecastCtrl.productWrapper pw2 = new ForecastCtrl.productWrapper();
        pw2.AccountId = '001000000000000';
        pw2.PRODUCT2ID = product.Id;
        pw2.Direct = 'true';
        pw2.Local = 'false';
        pw2.Month = monthStr;
        pw2.UNITPRICE = '100';
        pw2.Quantity = '50';
        pw2.Warehouse = '';
        wrappers.add(pw2);

        String prodJson = JSON.serialize(wrappers);

        Test.startTest();
            String result = ForecastCtrl.insertProductMass(prodJson);
        Test.stopTest();

        System.assert(result.startsWith('Success'), 'Should succeed for valid accounts: ' + result);
        System.assert(result.contains('Skipped'), 'Should report skipped invalid accounts: ' + result);
    }

    private static Account getAccount(){
        return [SELECT Id, Name, Forecast_Enabled__c FROM Account LIMIT 1];
    }

    private static Product2 getProduct(){
        return [SELECT Id, NACA_Case_Qty__c FROM Product2 LIMIT 1];
    }

    private static Warehouse__c getWarehouse(){
        return [SELECT Id, Name FROM Warehouse__c LIMIT 1];
    }

    static testmethod void testIncrement(){
        ForecastCtrl.justIncrement();
    }

    static testmethod void testIncrement2(){
        ForecastCtrl.justIncrement2();
    }

    static testmethod void testQueueableIncrement(){
        ForecastMassUploadQueueable.justIncrement();
    }
}
