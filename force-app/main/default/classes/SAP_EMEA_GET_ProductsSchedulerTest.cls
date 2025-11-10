@isTest
public class SAP_EMEA_GET_ProductsSchedulerTest {
    @isTest
    public static void testschedule() {
        Test.StartTest();
        SAP_EMEA_GET_ProductsScheduler sh1 = new SAP_EMEA_GET_ProductsScheduler();
        String sch = '0 0 23 * * ?';
        system.schedule('Test', sch, sh1); 
        Test.stopTest();
    }
    @isTest
    public static void testschedule1() {
        Test.StartTest();
        SAP_EMEA_GET_ProductsScheduler.PriceBookEntryJob sh1 = new SAP_EMEA_GET_ProductsScheduler.PriceBookEntryJob(new map<string,string>{'Test'=>'Test'});
        System.enqueueJob(sh1);
        Test.stopTest();
    }

}