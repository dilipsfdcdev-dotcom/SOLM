global class ScheduleClassForRevenueCalculation implements Schedulable{
    
    global void execute(System.SchedulableContext ctx){
        database.executeBatch(new CreateOpportunitySchedule());

    }
}