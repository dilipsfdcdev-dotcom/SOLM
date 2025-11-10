public with sharing class CustomMetadataService {
    private static CustomMetadataService metadataService;
    private Map<String, List<SObject>> metadataCollections = new Map<String, List<SObject>> ();

    private CustomMetadataService() {}

    public static CustomMetadataService getInstance() {
        if (metadataService == null) {
            metadataService = new CustomMetadataService();
        }
        return metadataService;
    }

    public List<SObject> get(List<SObject> queryResult) {
        String metadataApiName = queryResult.getSObjectType().getDescribe().getName();
        return get(metadataApiName, queryResult);
    }

    public List<SObject> get(String key, SObject record) {
        return get(key, new List<SObject>{record});
    }

    public List<SObject> get(String key, List<SObject> queryResult) {
        if (metadataCollections.containsKey(key)) {
            return metadataCollections.get(key);
        } else {
            return queryResult;
        }
    }

    public void setMetadataMock(List<SObject> queryResult) {
        setMetadataMock(queryResult, false);
    }

    public void setMetadataMock(String key, List<SObject> queryResult) {
        setMetadataMock(key, queryResult, false);
    }

    public void setMetadataMock(List<SObject> queryResult, Boolean preserveId) {
        String metadataApiName = queryResult.getSObjectType().getDescribe().getName();
        metadataCollections.put(metadataApiName, queryResult.deepClone(preserveId));
    }

    public void setMetadataMock(String key, List<SObject> queryResult, Boolean preserveId) {
        metadataCollections.put(key, queryResult.deepClone(preserveId));
    }
}