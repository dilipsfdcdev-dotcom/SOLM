trigger OpportunityTrigger on Opportunity (after insert, after update, after delete, before delete){
    try {
        if(trigger.isAfter && trigger.isUpdate){
            OpportunityTriggerHandler.sendEmailToBuBasedOnProbablity(Trigger.new, Trigger.oldMap);
          }

        TriggerHandlerDispatcher.execute(new OpportunityTriggerHandler());
    } catch (Exception e) {
        new Logger('Opportunity', 'OpportunityTriggerHandler').error(e).create();
    }
}