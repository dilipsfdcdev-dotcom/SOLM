@IsTest
private class CreateForecastMonthsBatchSchedulerTest {
	static final String CRON_EXP = '0 0 1 1 * ?';
	static final String JOB_NAME = 'CreateForecastMonthsBatch_MonthlyRun';

	@IsTest
	static void testCreateForecastMonthsOnceAMonth() {
		Test.startTest();
		String jobId = System.schedule(JOB_NAME, CRON_EXP, new CreateForecastMonthsBatchScheduler());
		CronTrigger ct = [
				SELECT Id, CronExpression, TimesTriggered, NextFireTime
				FROM CronTrigger
				WHERE Id = :jobId
		];
		System.assertEquals(CRON_EXP, ct.CronExpression);
		System.assertEquals(0, ct.TimesTriggered);
		Test.stopTest();
	}
}