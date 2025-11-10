@IsTest
public without sharing class CubeRmHelperTest {
    static final String EMEA_RECORD_TYPE = 'Account_EMEA';
    @TestSetup
    static void setup() {
        cuberm_tc__CubeRMSettings__c settings = cuberm_tc__CubeRMSettings__c.getOrgDefaults();
        settings.cuberm_tc__APIUrl__c = 'test';
        settings.cuberm_tc__CompanyOAuth__c = 'test';
        settings.cuberm_tc__CompanyUID__c = 'test';
        settings.cuberm_tc__CompanyKeywordObject__c = 'cuberm_tc__KeywordWeight__c';
        settings.cuberm_tc__CustomerMappingThreshold__c = 70;
        settings.cuberm_tc__CustomerHelperClass__c = 'CubeRmHelper';
        settings.cuberm_tc__TenderApiPageSize__c = 100;
        upsert settings;
        
    }
    
    @IsTest
    static void cubeRmHelperSuccess() {
        Id accRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(EMEA_RECORD_TYPE).getRecordTypeId();
        Account account = new Account(Name = 'test', RecordTypeId = accRecordTypeId, Customer_Status__c = 'Customer', Type = 'Competitor');
        insert account;
        Account account2 = new Account(Name = 'test1', RecordTypeId = accRecordTypeId);
        insert account2;
        cuberm_tc__KeywordWeight__c keywordWeight = new cuberm_tc__KeywordWeight__c(Name = 'test', cuberm_tc__NameFull__c = 'test', cuberm_tc__Weight__c = 1);
        insert keywordWeight;
        Test.startTest();
        Id pricebk = Test.getStandardPricebookId();
        Product2 prod = new Product2(Name='test');
        insert prod;
        Product2 prod2 = new Product2(Name='test2');
        insert prod2;
        cuberm_tc__Tender__c tender = new cuberm_tc__Tender__c(Pricebook__c=pricebk,cuberm_tc__Country__c = 'GR',cuberm_tc__ContractingAuthority__c = 'test', cuberm_tc__Keywords__c = 'test',
                                                               cuberm_tc__Type__c = 'Anticipated', SubmissionDeadline__c = Date.today(), MainAccount__c = account.Id, cuberm_tc__AttachmentsKeywords__c = 'test,test1');
        insert tender;
        cuberm_tc__TenderLot__c tenderLot = new cuberm_tc__TenderLot__c(Qualification_Index_Value__c = '0',cuberm_tc__Tender__c = tender.Id, cuberm_tc__Keywords__c = 'test', cuberm_tc__Status__c = 'No Bid');
        insert tenderLot;
        tenderLot.cuberm_tc__Status__c = 'Bid';
        tenderLot.Keyword__c = null;
        tenderLot.cuberm_tc__Keywords__c = 'test2';
        update tenderLot;
        cuberm_tc__TenderLot__c tenderLot2 = new cuberm_tc__TenderLot__c(Qualification_Index_Value__c = '0',cuberm_tc__Tender__c = tender.Id, cuberm_tc__Keywords__c = 'test3', cuberm_tc__Status__c = 'Imported');
        insert tenderLot2;
        Test.stopTest();
    }
    
    @IsTest
    static void cubeRmHelperFailure() {
        try {
            new CubeRmHelper().calculateTenderRIndex(new List<cuberm_tc__Tender__c>{null});
        } catch (Exception ex) {
            System.assertNotEquals(null, ex);
        }
        try {
            CubeRmHelper.unlinkLotsFromOpportunity(null,null);
        } catch (Exception ex) {
            System.assertNotEquals(null, ex);
        }
    }
    
    @IsTest
    static void testTransferProductToOutcomeOnAwarded() {
        Id accRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(EMEA_RECORD_TYPE).getRecordTypeId();
        Account account = new Account(Name = 'test', RecordTypeId = accRecordTypeId, Customer_Status__c = 'Customer', Type = 'Competitor');
        insert account;
        
        Id pricebk = Test.getStandardPricebookId();
        Product2 prod = new Product2(Name='test');
        insert prod;
        
        cuberm_tc__Tender__c tender = new cuberm_tc__Tender__c(Pricebook__c=pricebk,cuberm_tc__Country__c = 'GR',cuberm_tc__ContractingAuthority__c = 'test', cuberm_tc__Keywords__c = 'test',
                                                               cuberm_tc__Type__c = 'Anticipated', SubmissionDeadline__c = Date.today(), MainAccount__c = account.Id, cuberm_tc__AttachmentsKeywords__c = 'test,test1', cuberm_tc__Stage__c = 'Qualified');
        insert tender;
        
        cuberm_tc__TenderLot__c tenderLot = new cuberm_tc__TenderLot__c(Qualification_Index_Value__c = '0',cuberm_tc__Tender__c = tender.Id, cuberm_tc__Keywords__c = 'test', cuberm_tc__Status__c = 'No Bid');
        insert tenderLot;
        
        cuberm_tc__TenderLotProduct__c tenderLotProduct = new cuberm_tc__TenderLotProduct__c(cuberm_tc__TenderLot__c = tenderLot.Id, cuberm_tc__Product__c = prod.Id, cuberm_tc__Quantity__c = 7, cuberm_tc__UnitPrice__c = 10);
        insert tenderLotProduct;
        
        cuberm_tc__TenderLotProductCompetitor__c tenderLotProductComp = new cuberm_tc__TenderLotProductCompetitor__c(CompetitorProduct__c = prod.Id, Competitor__c = account.Id, cuberm_tc__TenderLotProduct__c = tenderLotProduct.Id, EstimatedPrice__c =20);
        insert tenderLotProductComp;
        
        Test.startTest();
        tender.cuberm_tc__Stage__c = 'Awarded';
        update tender;
        Test.stopTest();
        
        List<cuberm_tc__TenderLotAward__c> lotAwards = [SELECT Id FROM cuberm_tc__TenderLotAward__c];
        
        System.assertEquals(1, lotAwards.size(), 'Not having any awards in the system');
    }
    
    @IsTest
    static void testLinkToOpp() {
        
        Id accRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(EMEA_RECORD_TYPE).getRecordTypeId();
        Account acc = new Account(Name = 'Test Account', RecordTypeId = accRecordTypeId, Customer_Status__c = 'Customer');
        insert acc;
        
        Id pb = Test.getStandardPricebookId();
        Product2 prod = new Product2(Name='test');
        insert prod;
        PricebookEntry pbeId = [SELECT id FROM PricebookEntry WHERE Pricebook2Id =: pb LIMIT 1];
        pbeId.IsActive = true;
        update pbeId;
        
        cuberm_tc__Tender__c tender = new cuberm_tc__Tender__c(Name = 'Test', cuberm_tc__Country__c = 'GR', MainAccount__c = acc.Id, PriceBook__c = pb);
        insert tender;
        cuberm_tc__TenderLot__c lot = new cuberm_tc__TenderLot__c(cuberm_tc__Tender__c = tender.Id);
        insert lot;
        cuberm_tc__TenderLotProduct__c lotProduct = new cuberm_tc__TenderLotProduct__c(cuberm_tc__TenderLot__c = lot.Id, cuberm_tc__Quantity__c = 1, cuberm_tc__Product__c = prod.Id, PricebookEntryId__c = pbeId.Id);
        insert lotProduct;
        
        
        
        CubeRmHelper.TenderLotResultDto tenderLotResult = CubeRmHelper.PrepareImport(tender.Id, new List<String>{lot.Id});
        
        CubeRmHelper.OpportunitySaveDto opptyDto = new CubeRmHelper.OpportunitySaveDto();
        opptyDto.LotIds = new List<String>{lot.Id};
            opptyDto.TenderId = tender.Id;
        opptyDto.AccountId = acc.Id;
        opptyDto.AccountName = acc.Name;
        opptyDto.OpportunityName = 'Test Opportunity';
        opptyDto.OpportunityId = null;
        opptyDto.SubmissionDeadline = Date.newInstance(2023, 2, 20);
        opptyDto.CurrencyIsoCode = 'USD';
        opptyDto.Stage = 'Proposal';
        opptyDto.OppCloseDate = Date.today();
        opptyDto.OppOwnerId = UserInfo.getUserId();
        
        CubeRmHelper.SaveDtoReturn savedOppDto = CubeRmHelper.SaveOpportunity(opptyDto);
        
        System.assertEquals([SELECT Id FROM Opportunity].size(), 1);
        System.assertEquals([SELECT Id FROM OpportunityLineItem].size(), 1);
        
        // WHEN we unlink the Opportunity from The Lots
        Test.startTest();
        CubeRmHelper.unlinkLotsFromOpportunity(new List<String>{
            lot.Id
                }, tender.Id);
        Test.stopTest();
        
        // THEN the Opportunity must have no link to the Tender and IsImported should be false for the Lots.
        Opportunity newOpp = [SELECT CubeRMTender__c FROM Opportunity WHERE Id = :savedOppDto.OpportunityId];
        cuberm_tc__TenderLot__c newTenderLot = [
            SELECT cuberm_tc__IsImported__c
            FROM cuberm_tc__TenderLot__c
            WHERE Id = :lot.Id
        ];
        System.assertNotEquals(newOpp.CubeRMTender__c, tender.Id, 'Expected Opportunity unlinked from the Tender.');
        System.assertEquals(newTenderLot.cuberm_tc__IsImported__c, false, 'Expected the Lot to not be Imported.');
        
    }
    
    @IsTest
    static void testGetFieldsOfObject(){
        /*Profile prof = [select id from profile where name = 'System Administrator'];
User user = new User();
user.firstName = 'test1';
user.lastName = 'test2';
user.profileId = prof.id;
user.username = 'testbcdtestkp@test.com.test';
user.email = 'testbcd1@test.com';
user.Alias = 'standt';
user.EmailEncodingKey='UTF-8';
user.LanguageLocaleKey='en_US';
user.LocaleSidKey='en_US';
user.TimeZoneSidKey='America/Los_Angeles';
insert user;
system.runAs(user){*/
        test.startTest();
        CubeRmHelper.getFieldsOfObject('Product2');
        test.stopTest();
        /* }*/
    }
}