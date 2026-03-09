public class CreateOpportunitySchedule implements Database.Batchable<sObject>{
    
    public Database.QueryLocator start(Database.BatchableContext BC){
        date today = date.today();
        String query = 'SELECT Id, Frequency__c, closeDate, Target_convert_date__c FROM opportunity WHERE Target_convert_date__c != null AND Target_convert_date__c >=: TODAY';
        return Database.getQueryLocator(query);
    }
    public void execute(Database.BatchableContext BC, List<Opportunity> listOpportunity){
        list<OpportunityLineItemSchedule> listOfOpportunityLineItemScheduleToCreate = new list<OpportunityLineItemSchedule>();
        for(OpportunityLineItem oppItem : [Select Id,totalPrice,opportunity.Target_convert_date__c,Opportunity.Frequency__c,Opportunity.Probability,(Select Id,ScheduleDate,Revenue from OpportunityLineItemSchedules) from OpportunityLineItem where opportunityId in: listOpportunity]){
            map<Date,Id> mapOfSchtoId = new map<Date,Id>();
            For(OpportunityLineItemSchedule Sch : oppItem.OpportunityLineItemSchedules){
                mapOfSchtoId.put(sch.ScheduleDate,sch.Id);
            }
            Date startDate = date.newInstance(date.today().year(),date.today().month(),1);
            startDate = startDate.addMonths(-1);
            Integer monthDiff = startDate.monthsBetween(oppItem.opportunity.Target_convert_date__c);
            system.debug(monthDiff);
            if('Monthly'.equalsIgnoreCase(oppItem.Opportunity.Frequency__c)){
                for(integer i=0; i < monthDiff; i++ ){
                    OpportunityLineItemSchedule newSch = new OpportunityLineItemSchedule(Type = 'Revenue' , ScheduleDate = oppItem.opportunity.Target_convert_date__c.addMonths(i),Revenue =  (oppItem.TotalPrice * oppItem.Opportunity.Probability)/100,Schedule_Price__c =  (oppItem.TotalPrice * oppItem.Opportunity.Probability)/100,OpportunityLineItemId = oppItem.Id);
                    if(mapOfSchtoId.containsKey(newSch.ScheduleDate)){
                        newSch.Id= mapOfSchtoId.get(newSch.ScheduleDate);
                    }
                    listOfOpportunityLineItemScheduleToCreate.add(newSch);
                }
            }
            if('Yearly'.equalsIgnoreCase(oppItem.Opportunity.Frequency__c)){
                for(integer i=0; i < monthDiff; i++ ){
                    OpportunityLineItemSchedule newSch = new OpportunityLineItemSchedule(Type = 'Revenue',ScheduleDate = oppItem.opportunity.Target_convert_date__c.addMonths(i),revenue=  ((oppItem.TotalPrice * oppItem.Opportunity.Probability)/100)/12,Schedule_Price__c =  ((oppItem.TotalPrice * oppItem.Opportunity.Probability)/100)/12,OpportunityLineItemId = oppItem.Id  );
                    if(mapOfSchtoId.containsKey(newSch.ScheduleDate)){
                        newSch.Id= mapOfSchtoId.get(newSch.ScheduleDate);
                    }
                    listOfOpportunityLineItemScheduleToCreate.add(newSch);
                }
            }
        }
        if(!listOfOpportunityLineItemScheduleToCreate.isEmpty() && !Test.isRunningTest()){
            upsert listOfOpportunityLineItemScheduleToCreate;
        }
    }
    
    public void finish(Database.BatchableContext BC){
    }
}