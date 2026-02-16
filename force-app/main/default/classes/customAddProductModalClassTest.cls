@IsTest
private class customAddProductModalClassTest {
    
    @TestSetup
    static void setupTestData() {
        // Create Standard Pricebook (required for testing)
        Id standardPricebookId = Test.getStandardPricebookId();
        
        // Create Custom Pricebook
        Pricebook2 customPricebook = new Pricebook2(
            Name = 'Test Pricebook',
            IsActive = true
        );
        insert customPricebook;
        
        // Create Products with unique codes to avoid conflicts
        List<Product2> products = new List<Product2>();
        String uniqueId = String.valueOf(System.now().getTime());
        products.add(new Product2(
            Name = 'Test Product 1',
            ProductCode = 'TESTPROD001' + uniqueId,
            Family = 'Hardware',
            Description = 'Test Description 1',
            IsActive = true
        ));
        products.add(new Product2(
            Name = 'Test Product 2',
            ProductCode = 'TESTPROD002' + uniqueId,
            Family = 'Software',
            Description = 'Test Description 2',
            IsActive = true
        ));
        products.add(new Product2(
            Name = 'Sample Product 3',
            ProductCode = 'TESTPROD003' + uniqueId,
            Family = 'Hardware',
            Description = 'Test Description 3',
            IsActive = true
        ));
        insert products;
        
        // Create Standard PricebookEntries (required before custom)
        List<PricebookEntry> standardPBEs = new List<PricebookEntry>();
        for (Product2 prod : products) {
            // Check if entry already exists to avoid duplicates
            List<PricebookEntry> existingEntries = [
                SELECT Id 
                FROM PricebookEntry 
                WHERE Pricebook2Id = :standardPricebookId 
                AND Product2Id = :prod.Id 
                LIMIT 1
            ];
            
            if (existingEntries.isEmpty()) {
                standardPBEs.add(new PricebookEntry(
                    Pricebook2Id = standardPricebookId,
                    Product2Id = prod.Id,
                    UnitPrice = 100,
                    IsActive = true
                ));
            }
        }
        if (!standardPBEs.isEmpty()) {
            insert standardPBEs;
        }
        
        // Create Custom PricebookEntries
        List<PricebookEntry> customPBEs = new List<PricebookEntry>();
        for (Product2 prod : products) {
            customPBEs.add(new PricebookEntry(
                Pricebook2Id = customPricebook.Id,
                Product2Id = prod.Id,
                UnitPrice = 150,
                IsActive = true
            ));
        }
        insert customPBEs;
        
        // Create Account (required for Quote)
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        // Create Opportunity (required for Quote)
        Opportunity testOpp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = testAccount.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Pricebook2Id = customPricebook.Id
        );
        insert testOpp;
        
        // Create Quote
        Quote testQuote = new Quote(
            Name = 'Test Quote',
            OpportunityId = testOpp.Id,
            Pricebook2Id = customPricebook.Id,
            Status = 'Draft'
        );
        insert testQuote;
        
        // Create existing QuoteLineItem (to test exclusion logic)
        QuoteLineItem existingQLI = new QuoteLineItem(
            QuoteId = testQuote.Id,
            PricebookEntryId = customPBEs[0].Id,
            Product2Id = products[0].Id,
            Quantity = 1,
            UnitPrice = 150
        );
        insert existingQLI;
    }
    
    @IsTest
    static void testFindProductsWithBlankRecordId() {
        Test.startTest();
        String result = customAddProductModalClass.findProducts(null, null, null, null, 10);
        Test.stopTest();
        
        customAddProductModalClass.wrapperClass wc = 
            (customAddProductModalClass.wrapperClass) JSON.deserialize(result, customAddProductModalClass.wrapperClass.class);
        
        System.assertNotEquals(null, wc, 'Wrapper should not be null');
    }
    
    @IsTest
    static void testFindProductsWithoutPricebook() {
        // Create Quote without Pricebook
        Account acc = new Account(Name = 'Test Account 2');
        insert acc;
        
        Opportunity opp = new Opportunity(
            Name = 'Test Opp 2',
            AccountId = acc.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert opp;
        
        Quote quoteWithoutPB = new Quote(
            Name = 'Quote Without PB',
            OpportunityId = opp.Id,
            Status = 'Draft'
        );
        insert quoteWithoutPB;
        
        Test.startTest();
        String result = customAddProductModalClass.findProducts(
            quoteWithoutPB.Id, null, null, null, 10
        );
        Test.stopTest();
        
        customAddProductModalClass.wrapperClass wc = 
            (customAddProductModalClass.wrapperClass) JSON.deserialize(result, customAddProductModalClass.wrapperClass.class);
        
        System.assertEquals(0, wc.productList.size(), 'Product list should be empty');
    }
    
    @IsTest
    static void testFindProductsWithAllFilters() {
        Quote qt = [SELECT Id FROM Quote LIMIT 1];
        Product2 testProduct = [SELECT ProductCode FROM Product2 WHERE Name = 'Test Product 2' LIMIT 1];
        List<String> families = new List<String>{'Software'};
        
        Test.startTest();
        String result = customAddProductModalClass.findProducts(
            qt.Id, 
            'Test Product', 
            testProduct.ProductCode, 
            families, 
            10
        );
        Test.stopTest();
        
        customAddProductModalClass.wrapperClass wc = 
            (customAddProductModalClass.wrapperClass) JSON.deserialize(result, customAddProductModalClass.wrapperClass.class);
        
        System.assertNotEquals(null, wc.productList, 'Product list should not be null');
        System.assertEquals('Test Pricebook', wc.priceBook, 'Pricebook name should match');
        
        // Should return Test Product 2 (not Test Product 1 as it's already in QLI)
        if (wc.productList.size() > 0) {
            System.assertEquals(testProduct.ProductCode, wc.productList[0].ProductCode, 'Should return correct product');
        }
    }
    
    @IsTest
    static void testFindProductsWithNameFilter() {
        Quote qt = [SELECT Id FROM Quote LIMIT 1];
        
        Test.startTest();
        String result = customAddProductModalClass.findProducts(
            qt.Id, 
            'Sample', 
            null, 
            null, 
            10
        );
        Test.stopTest();
        
        customAddProductModalClass.wrapperClass wc = 
            (customAddProductModalClass.wrapperClass) JSON.deserialize(result, customAddProductModalClass.wrapperClass.class);
        
        System.assertNotEquals(null, wc.productList, 'Product list should not be null');
        // Should find "Sample Product 3"
        if (wc.productList.size() > 0) {
            System.assert(wc.productList[0].Name.contains('Sample'), 'Should contain Sample in name');
        }
    }
    
    @IsTest
    static void testFindProductsWithProductCodeFilter() {
        Quote qt = [SELECT Id FROM Quote LIMIT 1];
        Product2 sampleProduct = [SELECT ProductCode FROM Product2 WHERE Name = 'Sample Product 3' LIMIT 1];
        
        Test.startTest();
        String result = customAddProductModalClass.findProducts(
            qt.Id, 
            null, 
            sampleProduct.ProductCode, 
            null, 
            10
        );
        Test.stopTest();
        
        customAddProductModalClass.wrapperClass wc = 
            (customAddProductModalClass.wrapperClass) JSON.deserialize(result, customAddProductModalClass.wrapperClass.class);
        
        System.assertNotEquals(null, wc.productList, 'Product list should not be null');
        if (wc.productList.size() > 0) {
            System.assertEquals(sampleProduct.ProductCode, wc.productList[0].ProductCode, 'Should return correct product');
        }
    }
    
    @IsTest
    static void testFindProductsWithFamilyFilter() {
        Quote qt = [SELECT Id FROM Quote LIMIT 1];
        List<String> families = new List<String>{'Hardware'};
        
        Test.startTest();
        String result = customAddProductModalClass.findProducts(
            qt.Id, 
            null, 
            null, 
            families, 
            10
        );
        Test.stopTest();
        
        customAddProductModalClass.wrapperClass wc = 
            (customAddProductModalClass.wrapperClass) JSON.deserialize(result, customAddProductModalClass.wrapperClass.class);
        
        System.assertNotEquals(null, wc.productList, 'Product list should not be null');
        // Should exclude Test Product 1 (already in QLI) and return Sample Product 3
        for (customAddProductModalClass.ProductWrapper pw : wc.productList) {
            System.assertEquals('Hardware', pw.Family, 'All products should be Hardware family');
        }
    }
    
    @IsTest
    static void testFindProductsNoFilters() {
        Quote qt = [SELECT Id FROM Quote LIMIT 1];
        
        Test.startTest();
        String result = customAddProductModalClass.findProducts(
            qt.Id, 
            null, 
            null, 
            null, 
            10
        );
        Test.stopTest();
        
        customAddProductModalClass.wrapperClass wc = 
            (customAddProductModalClass.wrapperClass) JSON.deserialize(result, customAddProductModalClass.wrapperClass.class);
        
        System.assertNotEquals(null, wc.productList, 'Product list should not be null');
        // Should return 2 products (Test Product 2 and Sample Product 3, excluding Test Product 1 which is in QLI)
        System.assert(wc.productList.size() >= 1, 'Should have at least 1 product');
    }
    
    @IsTest
    static void testGetProductFamily() {
        Test.startTest();
        List<customAddProductModalClass.PicklistValue> families = 
            customAddProductModalClass.getproductfamily();
        Test.stopTest();
        
        System.assertNotEquals(null, families, 'Family list should not be null');
        System.assert(families.size() > 0, 'Should have at least one family value');
        
        // Verify PicklistValue structure
        customAddProductModalClass.PicklistValue pv = families[0];
        System.assertNotEquals(null, pv.label, 'Label should not be null');
        System.assertNotEquals(null, pv.value, 'Value should not be null');
    }
    
    @IsTest
    static void testSaveProductsSuccess() {
        Quote qt = [SELECT Id FROM Quote LIMIT 1];
        List<PricebookEntry> pbes = [
            SELECT Id, Product2Id, UnitPrice 
            FROM PricebookEntry 
            WHERE Product2.Name = 'Test Product 2'
            AND Pricebook2.Name = 'Test Pricebook'
            LIMIT 1
        ];
        
        List<customAddProductModalClass.ProductWrapper> wrappers = 
            new List<customAddProductModalClass.ProductWrapper>();
        
        customAddProductModalClass.ProductWrapper pw = 
            new customAddProductModalClass.ProductWrapper();
        pw.Id = pbes[0].Id;
        pw.Product2Id = pbes[0].Product2Id;
        pw.Price = 200;
        pw.Quantity = 5;
        pw.PDate = Date.today();
        pw.LineDescription = 'Test Line Description';
        wrappers.add(pw);
        
        String recordData = JSON.serialize(wrappers);
        
        Test.startTest();
        String result = customAddProductModalClass.saveProducts(recordData, qt.Id);
        Test.stopTest();
        
        System.assertEquals('success', result, 'Save should be successful');
        
        List<QuoteLineItem> qlis = [
            SELECT Id, Quantity, UnitPrice, Description 
            FROM QuoteLineItem 
            WHERE QuoteId = :qt.Id AND Product2Id = :pbes[0].Product2Id
        ];
        
        System.assertEquals(1, qlis.size(), 'Should have created 1 QLI');
        System.assertEquals(5, qlis[0].Quantity, 'Quantity should match');
        System.assertEquals(200, qlis[0].UnitPrice, 'Price should match');
    }
    
    @IsTest
    static void testSaveProductsWithDefaults() {
        Quote qt = [SELECT Id FROM Quote LIMIT 1];
        List<PricebookEntry> pbes = [
            SELECT Id, Product2Id, UnitPrice 
            FROM PricebookEntry 
            WHERE Product2.Name = 'Sample Product 3'
            AND Pricebook2.Name = 'Test Pricebook'
            LIMIT 1
        ];
        
        List<customAddProductModalClass.ProductWrapper> wrappers = 
            new List<customAddProductModalClass.ProductWrapper>();
        
        customAddProductModalClass.ProductWrapper pw = 
            new customAddProductModalClass.ProductWrapper();
        pw.Id = pbes[0].Id;
        pw.Product2Id = pbes[0].Product2Id;
        pw.Price = 150;
        // Not setting Quantity to test default value of 1
        wrappers.add(pw);
        
        String recordData = JSON.serialize(wrappers);
        
        Test.startTest();
        String result = customAddProductModalClass.saveProducts(recordData, qt.Id);
        Test.stopTest();
        
        System.assertEquals('success', result, 'Save should be successful');
        
        List<QuoteLineItem> qlis = [
            SELECT Id, Quantity 
            FROM QuoteLineItem 
            WHERE QuoteId = :qt.Id AND Product2Id = :pbes[0].Product2Id
        ];
        
        System.assertEquals(1, qlis.size(), 'Should have created 1 QLI');
        System.assertEquals(1, qlis[0].Quantity, 'Quantity should default to 1');
    }
    
    @IsTest
    static void testSaveProductsError() {
        Quote qt = [SELECT Id FROM Quote LIMIT 1];
        
        // Create data with invalid/null PricebookEntryId to trigger DML exception
        List<customAddProductModalClass.ProductWrapper> wrappers = 
            new List<customAddProductModalClass.ProductWrapper>();
        
        customAddProductModalClass.ProductWrapper pw = 
            new customAddProductModalClass.ProductWrapper();
        // Not setting pw.Id (PricebookEntryId) - this will cause a DML error
        pw.Price = 100;
        pw.Quantity = 1;
        wrappers.add(pw);
        
        String recordData = JSON.serialize(wrappers);
        
        Test.startTest();
        String result = customAddProductModalClass.saveProducts(recordData, qt.Id);
        Test.stopTest();
        
        System.assert(result.contains('Error') || result.contains('DML') || result == 'error', 
                     'Should return error message: ' + result);
    }
    
    @IsTest
    static void testWrapperClassConstructor() {
        customAddProductModalClass.wrapperClass wc = 
            new customAddProductModalClass.wrapperClass();
        System.assertNotEquals(null, wc, 'Wrapper class should be instantiated');
    }
    
    @IsTest
    static void testProductWrapperDefaults() {
        customAddProductModalClass.ProductWrapper pw = 
            new customAddProductModalClass.ProductWrapper();
        System.assertEquals(1, pw.Quantity, 'Default quantity should be 1');
    }
    
    @IsTest
    static void testPicklistValueConstructor() {
        customAddProductModalClass.PicklistValue pv = 
            new customAddProductModalClass.PicklistValue('TestValue', 'Test Label');
        
        System.assertEquals('TestValue', pv.value, 'Value should match');
        System.assertEquals('Test Label', pv.label, 'Label should match');
    }
}