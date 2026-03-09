@RestResource(urlMapping='/RunScheduler/*')
global with sharing class SchedulerService {

    @HttpPost
    global static String executeScheduler() {
        try {
            // Create an instance of the scheduler class and execute it
            SAP_NACA_GET_AccountsScheduler scheduler = new SAP_NACA_GET_AccountsScheduler();
            scheduler.execute(null);
            return 'Scheduler executed successfully.';
        } catch (Exception e) {
            // Handle exceptions and return an error message
            return 'Error executing scheduler: ' + e.getMessage();
        }
    }
}