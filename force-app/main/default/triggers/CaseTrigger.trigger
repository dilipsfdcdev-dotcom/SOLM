trigger CaseTrigger on Case (before insert, after insert, after update) {
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            CaseTriggerHandler.handleBeforeInsert(Trigger.new);
        }
    }

    if (Trigger.isAfter) {
        if (Trigger.isInsert || Trigger.isUpdate) {
            CaseTriggerHandler.handleExecutiveFlagUpdate(Trigger.new, Trigger.oldMap, Trigger.isInsert, Trigger.isUpdate);
        }
    }
}