@isTest
private class OpportunityRecurringTest {

    private final static Date OPPORTUNITY_CLOSE_DATE = Date.newInstance(2022, 2, 15);
  
    @testSetup 
    private static void setup(){
        Account acc = new TestHelper.AccountRecord()
                            .asNACA()
                            .setBillingCity('Chicago')
                            .setBillingCountry('United States')
                            .setBillingPostalCode('12345')
                            .setBillingStreet('Street')
                            .setShippingSameAsBilling()
                            .save();

        Contact con = new TestHelper.ContactRecord()
                            .setEmail('test@gmail.com')
                            .save();

        Product2 testProductMask = new TestHelper.ProductRecord().setName('Mask').save();
        Product2 testProductSyringe = new TestHelper.ProductRecord().setName('Syringe').save();

        Pricebook2 customPricebook = new TestHelper.PricebookRecord().save();

        Opportunity opp = new TestHelper.OpportunityRecord(acc.Id)
                            .setPricebookId(customPricebook.Id)
                            .setCloseDate(OPPORTUNITY_CLOSE_DATE)
                            .save();

        insert new List<OpportunityLineItem>{
            new TestHelper.OpportunityLineItemRecord(
                opp.Id,
                new TestHelper.PricebookEntryRecord(customPricebook.Id, testProductMask.Id).save().Id,
                testProductMask.Id
            ).build(),
            new TestHelper.OpportunityLineItemRecord(
                opp.Id,
                new TestHelper.PricebookEntryRecord(customPricebook.Id, testProductSyringe.Id).save().Id,
                testProductSyringe.Id
            ).build()
        };
    }

    @isTest
    private static void recurringOpportunityWeeklyTest(){
        Opportunity mainOpp = getOpportunity();

        Test.startTest();
        OpportunityRecurring.makeOpportunityRecurring(mainOpp.Id,  Date.newInstance(2022, 3, 10), 'Weekly');
        Test.stopTest();
        
        List<Opportunity> recurringOpportunities = getRecurringOpportunities(mainOpp.Id);

        System.assertEquals(4, recurringOpportunities.size());

        for(Opportunity opp: recurringOpportunities){
            System.assertEquals(opp.Amount, mainOpp.Amount);
            System.assertEquals(opp.StageName, mainOpp.StageName);
        }
    }

    @isTest
    private static void recurringOpportunityMonthlyTest(){
        Opportunity mainOpp = getOpportunity();

        Test.startTest();
        OpportunityRecurring.makeOpportunityRecurring(mainOpp.Id,  Date.newInstance(2022, 5, 10), 'Monthly');
        Test.stopTest();
        
        List<Opportunity> recurringOpportunities = getRecurringOpportunities(mainOpp.Id);

        System.assertEquals(3, recurringOpportunities.size());

        for(Opportunity opp: recurringOpportunities){
            System.assertEquals(opp.Amount, mainOpp.Amount);
            System.assertEquals(opp.StageName, mainOpp.StageName);
        }
    }

    @isTest
    private static void recurringOpportunityYearlyTest(){
        Opportunity mainOpp = getOpportunity();

        Test.startTest();
        OpportunityRecurring.makeOpportunityRecurring(mainOpp.Id,  Date.newInstance(2024, 4, 10), 'Yearly');
        Test.stopTest();
        
        List<Opportunity> recurringOpportunities = getRecurringOpportunities(mainOpp.Id);

        System.assertEquals(2, recurringOpportunities.size());

        for(Opportunity opp: recurringOpportunities){
            System.assertEquals(opp.Amount, mainOpp.Amount);
            System.assertEquals(opp.StageName, mainOpp.StageName);
        }
    }

    @isTest
    private static void recurringDateBeforeOpportunityCloseDateValidationTest(){
        Opportunity opp = getOpportunity();

        Boolean exceptionThrown = false;

        Test.startTest();

        try {
            OpportunityRecurring.makeOpportunityRecurring(opp.Id, OPPORTUNITY_CLOSE_DATE.addDays(-4), 'Monthly');
        } catch (Exception e) {
            exceptionThrown = true;
        }

        Test.stopTest();

        System.assert(exceptionThrown);
    }

    @isTest
    private static void recurringDateWeeklyValidationTest(){
        Opportunity opp = getOpportunity();

        Boolean exceptionThrown = false;

        Test.startTest();

        try {
            OpportunityRecurring.makeOpportunityRecurring(opp.Id, OPPORTUNITY_CLOSE_DATE.addDays(1), 'Weekly');
        } catch (Exception e) {
            exceptionThrown = true;
        }

        Test.stopTest();

        System.assert(exceptionThrown);
    }

    @isTest
    private static void recurringDateMonthlyValidationTest(){
        Opportunity opp = getOpportunity();

        Boolean exceptionThrown = false;

        Test.startTest();

        try {
            OpportunityRecurring.makeOpportunityRecurring(opp.Id, OPPORTUNITY_CLOSE_DATE.addDays(10), 'Monthly');
        } catch (Exception e) {
            exceptionThrown = true;
        }

        Test.stopTest();

        System.assert(exceptionThrown);
        
    }

    @isTest
    private static void recurringDateYearlyValidationTest(){
        Opportunity opp = getOpportunity();

        Boolean exceptionThrown = false;

        Test.startTest();

        try {
            OpportunityRecurring.makeOpportunityRecurring(opp.Id, OPPORTUNITY_CLOSE_DATE.addMonths(3), 'Yearly');
        } catch (Exception e) {
            exceptionThrown = true;
        }

        Test.stopTest();

        System.assert(exceptionThrown);
    }

    @isTest
    private static void recurringOpportunityStatusSyncTest(){
        Opportunity mainOpp = getOpportunity();
        OpportunityRecurring.makeOpportunityRecurring(mainOpp.Id, OPPORTUNITY_CLOSE_DATE.addMonths(3), 'Monthly');

        List<Opportunity> recurringOpportunities = getRecurringOpportunities(mainOpp.Id);

        for(Opportunity opp: recurringOpportunities){
            System.assertEquals(opp.Amount, mainOpp.Amount);
            System.assertEquals(opp.StageName, mainOpp.StageName);
        }

        Test.startTest();

        mainOpp.StageName = Constants.opportunity.STAGE_NEGOTIATION;
        update mainOpp;

        Test.stopTest();

        recurringOpportunities = getRecurringOpportunities(mainOpp.Id);

        for(Opportunity opp: recurringOpportunities){
            System.assertEquals(Constants.opportunity.STAGE_NEGOTIATION, mainOpp.StageName);
        }
    }

    @isTest
    private static void recurringOpportunityProductsSyncTest(){
        Pricebook2 customPricebook = [SELECT Id, IsStandard FROM Pricebook2 WHERE IsStandard = false LIMIT 1];
        Opportunity mainOpp = getOpportunity();
        Decimal amountBeforeChange = mainOpp.Amount;

        OpportunityRecurring.makeOpportunityRecurring(mainOpp.Id, OPPORTUNITY_CLOSE_DATE.addMonths(3), 'Monthly');
        
        Product2 testProduct = new TestHelper.ProductRecord().save();

        Test.startTest();

        new TestHelper.OpportunityLineItemRecord(
            mainOpp.Id,
            new TestHelper.PricebookEntryRecord(customPricebook.Id, testProduct.Id).save().Id,
            testProduct.Id
        ).save();
        
        Test.stopTest();

        mainOpp = getOpportunity();
        List<Opportunity> recurringOpportunities = getRecurringOpportunities(mainOpp.Id);

        System.assert(mainOpp.Amount > amountBeforeChange);

        for(Opportunity opp: recurringOpportunities){
            System.assertEquals(opp.Amount, mainOpp.Amount);
        }
        
    }

    private static Opportunity getOpportunity(){
        return [SELECT Id, Amount, StageName FROM Opportunity LIMIT 1];
    }

    private static List<Opportunity> getRecurringOpportunities(Id recordId){
        return [
            SELECT Id, Opportunity__c, StageName, Amount, CloseDate
            FROM Opportunity 
            WHERE Is_this_a_recurring_opportunity__c = true
            AND Opportunity__c = :recordId
        ];
    }
}