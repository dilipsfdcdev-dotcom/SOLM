@isTest
public class AccountToMuleTest {

    @TestSetup
    static void setup() {

        Account account = new Account(
            Name = 'Sol Millennium Medical Inc. 123',
            Phone = '5555555',
            ShippingCountry = 'US',
            //ShippingState = 'LA',
            ShippingCity = 'LA',
            ShippingStreet = '311 South Wacker Drive, Suite – 4100, Chicago - 60606',
            BillingCountry = 'US',
            //BillingState = 'LA',
            BillingCity = 'LA',
            BillingStreet = '311 South Wacker Drive, Suite – 4100, Chicago - 60606',
            BillingPostalCode = '123456',
            //Billing_Contact_Name__c = 
            SAP_Code__c = 'CIC00015',
            Payment_Terms__c = 'Net50-C',
            Incoterms__c = 'CIF',
            Sector__c = 'Public',
            Organization_Type__c = 'Hospital',
            Federal_Tax_Id_Number__c = 'abc123',
            
            Type = 'Customer'
        );
        insert account;
    }
    
    @isTest
    static void testAccountInsert() {
        
        Test.startTest();
        List<Account> acc = [SELECT 
                                Id, Name, SAP_Code__c, OwnerId, Type,                              		
                                Phone, Industry, Group__c,  
                                BillingCountryCode, BillingState, BillingStateCode, BillingCity, 
                                BillingPostalCode, BillingStreet,                                     
                                ShippingCountryCode, ShippingState, ShippingStateCode, ShippingCity, 
                                ShippingPostalCode, ShippingStreet, RecordTypeId                                     
                                FROM Account WHERE SAP_Code__c = 'CIC00015' LIMIT 1];

        Test.stopTest();

    }
}