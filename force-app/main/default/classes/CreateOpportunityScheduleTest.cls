@isTest
public class CreateOpportunityScheduleTest {
	@isTest
    public static void createSch(){
        OpportunityLineItem oppLineItem = new TestHelper.OpportunityLineItemRecord().setSalesPrice(10).save();
        Opportunity opp = [Select Id from Opportunity limit 1];
        opp.Target_convert_date__c = date.today().addMonths(12);
        opp.Frequency__c = 'Monthly';
        update opp;
        Test.startTest();
        ScheduleClassForRevenueCalculation sh1 = new ScheduleClassForRevenueCalculation();
        String sch = '0 0 2 * * ?'; 
        system.schedule('ScheduleClassForRevenueCalculation', sch, sh1); 
        Test.stopTest();
    }
    
    @isTest
    public static void createSchYrly(){
        OpportunityLineItem oppLineItem = new TestHelper.OpportunityLineItemRecord().setSalesPrice(10).save();
        Opportunity opp = [Select Id from Opportunity limit 1];
        opp.Target_convert_date__c = date.today().addMonths(12);
        opp.Frequency__c = 'Yearly';
        update opp;
        Test.startTest();
        ScheduleClassForRevenueCalculation sh1 = new ScheduleClassForRevenueCalculation();
        String sch = '0 0 2 * * ?'; 
        system.schedule('ScheduleClassForRevenueCalculation', sch, sh1); 
        Test.stopTest();
    }
}