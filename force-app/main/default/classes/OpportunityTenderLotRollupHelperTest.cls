@isTest
public class OpportunityTenderLotRollupHelperTest {

    private static final string TENDER_NAME = 'TEST-EMEA-Tender';

    @TestSetup
    static void makeData(){
        Account acc = new TestHelper.AccountRecord()
            .asEMEA()
            .save();

        Pricebook2 customPricebook = new TestHelper.PricebookRecord().save();

        Opportunity opp = new TestHelper.OpportunityRecord (
            TENDER_NAME, acc.Id, Constants.opportunity.RECORD_TYPE_EMEA_TENDER_ID )
            .setPricebookId(customPricebook.Id)
            .setStage(Constants.opportunity.STAGE_ANALYZING)
            .setCurrencyIsoCode('EUR')
            .save();

        Opportunity openLOT = new TestHelper.OpportunityRecord (
            'TEST-open-LOT', acc.Id, Constants.opportunity.RECORD_TYPE_EMEA_TENDER_LOT_ID)
            .setParent(opp.Id)
            .setAmount(1000)
            .setStage(Constants.opportunity.STAGE_ANALYZING)
            .setPricebookId(customPricebook.Id)
            .setCurrencyIsoCode('EUR')
            .build();

        Opportunity closedWonLOT = new TestHelper.OpportunityRecord (
            'TEST-closed-won-LOT', acc.Id, Constants.opportunity.RECORD_TYPE_EMEA_TENDER_LOT_ID)
            .setParent(opp.Id)
            .setAmount(1000)
            .setStage(Constants.opportunity.STAGE_CLOSED_WON)
            .setPricebookId(customPricebook.Id)
            .setCurrencyIsoCode('EUR')
            .build();

        insert new List<Opportunity>{openLOT, closedWonLOT};
    }

    @isTest
    private static void LOT_CreatedTest(){
        Opportunity tender = getTender();

        Test.startTest();
            new TestHelper.OpportunityRecord (
                'TEST-open-LOT', tender.AccountId, Constants.opportunity.RECORD_TYPE_EMEA_TENDER_LOT_ID)
                .setParent(tender.Id)
                .setAmount(1000)
                .setStage(Constants.opportunity.STAGE_ANALYZING)
                .setPricebookId(tender.Pricebook2Id)
                .setCurrencyIsoCode(tender.CurrencyIsoCode)
                .save();
        Test.stopTest();

        tender = getTender();

        System.assertEquals(3, tender.Number_of_LOTs__c);
        System.assertEquals(1, tender.Closed_Won_LOTs__c);
        System.assertEquals(2, tender.Open_LOTs__c);
        System.assertEquals(1200, tender.Expected_Revenue_on_LOTs__c);

    }

    @isTest
    private static void LOT_UpdatedTest(){
        Opportunity tender = getTender();

        Opportunity openLOT = tender.Opportunities__r[0];
        openLOT.Amount = 2000;

        Test.startTest();
            update openLOT;
        Test.stopTest();

        tender = getTender();

        System.assertEquals(2, tender.Number_of_LOTs__c);
        System.assertEquals(1, tender.Closed_Won_LOTs__c);
        System.assertEquals(1, tender.Open_LOTs__c);
        System.assertEquals(1200, tender.Expected_Revenue_on_LOTs__c);
    }

    @isTest
    private static void LOT_DeletedTest(){
        Opportunity tender = getTender();

        Test.startTest();
            delete tender.Opportunities__r[0];
        Test.stopTest();

        tender = getTender();

        System.assertEquals(1, tender.Number_of_LOTs__c);
        System.assertEquals(1, tender.Closed_Won_LOTs__c);
        System.assertEquals(0, tender.Open_LOTs__c);
        System.assertEquals(1000, tender.Expected_Revenue_on_LOTs__c);
    }

    @isTest
    private static void ALL_LOTs_DeletedTest(){
        Opportunity tender = getTender();

        Test.startTest();
            delete tender.Opportunities__r;
        Test.stopTest();

        tender = getTender();

        System.assertEquals(0, tender.Number_of_LOTs__c);
        System.assertEquals(0, tender.Closed_Won_LOTs__c);
        System.assertEquals(0, tender.Open_LOTs__c);
        System.assertEquals(0, tender.Expected_Revenue_on_LOTs__c);
    }

    private static Opportunity getTender(){
        return [
            SELECT Id, AccountId, Pricebook2Id, CurrencyIsoCode,
                Number_of_LOTs__c, Open_LOTs__c, Closed_Lost_LOTs__c, Closed_Won_LOTs__c, Disqualified_LOTs__c, Expected_Revenue_on_LOTs__c,
                (SELECT Id, Amount FROM Opportunities__r ORDER BY Probability)
            FROM Opportunity 
            WHERE Name = :TENDER_NAME 
            LIMIT 1
        ];
    }
}