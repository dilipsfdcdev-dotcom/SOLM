public virtual class TriggerHandler implements ITriggerHandler{
    public virtual void beforeInsert(List<sObject> newRecordsList){}

    public virtual void afterInsert(List<sObject> newRecordsList , Map<Id, sObject> newRecordsMap){}

    public virtual void beforeUpdate(Map<Id, sObject> newRecordsMap, Map<Id, sObject> oldRecordsMap){}
    
    public virtual void afterUpdate(Map<Id, sObject> newRecordsMap,  Map<Id, sObject> oldRecordsMap){}

    public virtual void afterUndelete(List<sObject> newRecordsList , Map<Id, sObject> newRecordsMap){}
    
    public virtual void beforeDelete(List<sObject> oldRecordsList , Map<Id, sObject> oldRecordsMap){}
    
    public virtual void afterDelete(Map<Id, sObject> oldRecordsMap){}

    public virtual String getImplementationName(){
        return TriggerHandler.class.getName();
    }
}