@isTest
private class ApexEventSubscriberTest {
	
    @isTest
    static void logsArePersisted() {
		Debug_Log__e logEvent = new Debug_Log__e(
			Message__c = 'Test Message',
			Stack_Trace__c = 'Test Stack'
		);

        Test.startTest();
        new ApexEventSubscriber(new List<Debug_Log__e>{ logEvent }).log();

        Test.stopTest();

        List<Log__c> logs = [SELECT Message__c, Stack_Trace__c FROM Log__c];
		System.assertEquals(1, logs.size());
		System.assertEquals('Test Message', logs[0].Message__c);
		System.assertEquals('Test Stack', logs[0].Stack_Trace__c);
	}
}