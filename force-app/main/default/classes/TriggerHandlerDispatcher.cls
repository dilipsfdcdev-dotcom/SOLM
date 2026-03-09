public with sharing class TriggerHandlerDispatcher {

    private class TriggerHandlerException extends Exception {}
    private static CustomMetadataService mdtService = CustomMetadataService.getInstance();

    public static void execute(ITriggerHandler handler) {
        String handlerName = handler.getImplementationName();
        Boolean isHandlerEnabled;

        List<Trigger_Handler_Setting__mdt> handlerSetting = (List<Trigger_Handler_Setting__mdt>) mdtService.get(Trigger_Handler_Setting__mdt.getSObjectType().getDescribe().getName(),
            Trigger_Handler_Setting__mdt.getInstance(handlerName));

        if(!handlerSetting.isEmpty() && handlerSetting[0] != null) {
            isHandlerEnabled = isHandlerEnabled(handlerSetting[0]);
        } else {
            throw new TriggerHandlerException('Trigger Handler Setting not found for ' + handlerName);
        }
        
        if(isHandlerEnabled) {
            executeTriggerContext(handler);
        } 
    }

    private static Boolean isHandlerEnabled(Trigger_Handler_Setting__mdt handlerSetting){
        return handlerSetting.Is_Enabled__c
                && (handlerSetting.User_bypass__c == null ? true : !handlerSetting.User_bypass__c.contains(UserInfo.getUserId()));
    }

    private static void executeTriggerContext(ITriggerHandler handler) {
        if(Trigger.isBefore){
            if(Trigger.isInsert) {
                handler.beforeInsert(Trigger.new);
            }
            else if(Trigger.isUpdate) {
                handler.beforeUpdate(Trigger.newMap, Trigger.oldMap);
            }
            else if(Trigger.isDelete) {
                handler.beforeDelete(Trigger.old, Trigger.oldMap);
            }
        } else if (Trigger.isAfter) {
            if(Trigger.isInsert) {
                handler.afterInsert(Trigger.new, Trigger.newMap);
            }
            else if(Trigger.isUpdate) {
            	handler.afterUpdate(Trigger.newMap, Trigger.oldMap);
            }
            else if(Trigger.isDelete) {
                handler.afterDelete(Trigger.oldMap);
            }
            else if(Trigger.isUndelete) {
                handler.afterUndelete(Trigger.new, Trigger.newMap);
            }
        }
    }
}