@isTest
private class SchedulerServiceTest {

    @isTest
    static void testExecuteSchedulerSuccess() {
        // Simulate the behavior of the scheduler as if it was successful
        Test.startTest();
        // Call the REST resource method
        String result = SchedulerService.executeScheduler();
        Test.stopTest();

        // Assert that the result is as expected
        System.assertEquals('Scheduler executed successfully.', result, 'The scheduler should execute successfully.');
    }
}