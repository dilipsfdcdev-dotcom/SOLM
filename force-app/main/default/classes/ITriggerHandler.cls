public interface ITriggerHandler {

    void beforeInsert(List<sObject> newRecordsList);

    void afterInsert(List<sObject> newRecordsList , Map<Id, sObject> newRecordsMap);

    void beforeUpdate(Map<Id, sObject> newRecordsMap, Map<Id, sObject> oldRecordsMap);
    
    void afterUpdate(Map<Id, sObject> newRecordsMap,  Map<Id, sObject> oldRecordsMap);

    void afterUndelete(List<sObject> newRecordsList , Map<Id, sObject> newRecordsMap);
    
    void beforeDelete(List<sObject> oldRecordsList , Map<Id, sObject> oldRecordsMap);
    
    void afterDelete(Map<Id, sObject> oldRecordsMap);

    String getImplementationName();
}