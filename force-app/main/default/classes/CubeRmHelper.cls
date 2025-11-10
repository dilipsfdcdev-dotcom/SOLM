global with sharing class CubeRmHelper extends cuberm_tc.ClientHelper {
    private static final Integer CustomerSuggestThreshold = 50;
    private static final Integer CustomerMapThreshold = 80;
    private static final Integer KeywordSuggestThreshold = 50;
    private static final Integer KeywordMapThreshold = 90;
    private static final String EMEA_RECORD_TYPE = 'Account_EMEA';
    private static final String OPP_EMEA_RECORD_TYPE = 'Opportunity_EMEA';

    public class TenderLotResultDto {
        public TenderLotResultDto() {
            this.TenderLots = new List <cuberm_tc__TenderLot__c>();
            this.Warnings = new List<String>();
        }
        @AuraEnabled
        public List<cuberm_tc__TenderLot__c> TenderLots { get; set; }
        @AuraEnabled
        public String AccountId { get; set; }
        @AuraEnabled
        public String AccountName { get; set; }
        @AuraEnabled
        public String RecordTypeId { get; set; }
        @AuraEnabled
        public Date oppCloseDate { get; set; }
        @AuraEnabled
        public String OppTenderType { get; set; }
        @AuraEnabled
        public String OppType { get; set; }
        @AuraEnabled
        public String SubType { get; set; }
        @AuraEnabled
        public List<String> Warnings { get; set; }
    }

    public class AccountResultDto {
        @AuraEnabled
        public String AccountName { get; set; }
        @AuraEnabled
        public List<Opportunity> Opportunities { get; set; }
    }

    public class SaveDtoReturn {
        @AuraEnabled
        public String OpportunityId { get; set; }
        @AuraEnabled
        public String OpportunityLocalName { get; set; }
    }

    public class OpportunitySaveDto {
        public OpportunitySaveDto() {
            this.LotIds = new List<String>();
        }
        @AuraEnabled
        public String TenderId { get; set; }
        @AuraEnabled
        public String AccountName { get; set; }
        @AuraEnabled
        public String AccountId { get; set; }
        @AuraEnabled
        public String OpportunityName { get; set; }
        @AuraEnabled
        public String OpportunityId { get; set; }
        @AuraEnabled
        public Date SubmissionDeadline { get; set; }
        @AuraEnabled
        public String OppOwnerId { get; set; }
        @AuraEnabled
        public Date OppCloseDate { get; set; }
        @AuraEnabled
        public String CurrencyIsoCode { get; set; }
        @AuraEnabled
        public String Type { get; set; }
        @AuraEnabled
        public String Stage { get; set; }
        @AuraEnabled
        public String SubType { get; set; }
        @AuraEnabled
        public String TenderType { get; set; }
        @AuraEnabled
        public List<String> LotIds { get; set; }
        @AuraEnabled
        public String URL { get; set; }
    }

    public override void calculateTenderRIndex(List<cuberm_tc__Tender__c> tenders) {
        try {
            if (!Schema.SObjectType.cuberm_tc__KeywordWeight__c.isAccessible() ||
                !Schema.SObjectType.cuberm_tc__Tender__c.isAccessible() ||
                !Schema.SObjectType.cuberm_tc__Tender__c.isUpdateable()) {
                permissionException('Object permission error. Please contact your administrator.');
            }

            Map<String, cuberm_tc__KeywordWeight__c> keywordWeightMap = new Map<String, cuberm_tc__KeywordWeight__c>();
            List<cuberm_tc__KeywordWeight__c> keywordWeights = [
                SELECT Id, Name, cuberm_tc__NameFull__c, cuberm_tc__Weight__c
                FROM cuberm_tc__KeywordWeight__c
                WITH SECURITY_ENFORCED
            ];
            for (cuberm_tc__KeywordWeight__c keywordWeight : keywordWeights) {
                keywordWeightMap.put(toLowerCase(keywordWeight.cuberm_tc__NameFull__c).trim(), keywordWeight);
            }

            for (cuberm_tc__Tender__c tender : tenders) {
                if (String.isNotBlank(tender.cuberm_tc__Keywords__c)) {
                    evaluateKeywordsLength(tender);
                    List<String> keywordList = tender.cuberm_tc__Keywords__c.split(',');
                    Integer maxRIndex = calculateMaxQIndex(keywordList, keywordWeightMap);
                    tender.Qualification_Index_Value__c = String.valueOf(maxRIndex);
                } else {
                    tender.Qualification_Index_Value__c = null;
                }
            }
            calculateTenderQAttachmentIndex(tenders,keywordWeightMap);
        } catch (Exception ex) {
            exceptionHandle(ex, 'CalculateTenderRIndex');
        }
    }

    public override void calculateTenderLotRIndex(List<cuberm_tc__TenderLot__c> tenderLotsList, Map<Id, cuberm_tc__TenderLot__c> tenderLotsMapOld) {
        try {
            if (!Schema.SObjectType.cuberm_tc__KeywordWeight__c.isAccessible() ||
                !Schema.SObjectType.cuberm_tc__TenderLot__c.isAccessible() ||
                !Schema.SObjectType.cuberm_tc__TenderLot__c.isUpdateable() ||
                !Schema.SObjectType.cuberm_tc__Tender__c.isAccessible()) {
                permissionException('Object permission error. Please contact your administrator.(cuberm_tc__Tender__c, cuberm_tc__TenderLot__c, cuberm_tc__KeywordWeight__c)');
            }

            Set<String> keywordSet = new Set<String>();
            List<cuberm_tc__TenderLot__c> processLotList = new List<cuberm_tc__TenderLot__c>();
            setProcessLotList(tenderLotsList, tenderLotsMapOld, keywordSet, processLotList);

            List<cuberm_tc__KeywordWeight__c> keywordList = new List<cuberm_tc__KeywordWeight__c>();
            if (Test.isRunningTest()) {
                keywordList = [SELECT Id, Name, cuberm_tc__NameFull__c, cuberm_tc__Weight__c FROM cuberm_tc__KeywordWeight__c WITH SECURITY_ENFORCED];
            } else {
                if (keywordSet.size() > 0) {
                    String searchStr = String.join(new List<String>(keywordSet), ';');
                    String rtrnObj = 'cuberm_tc__KeywordWeight__c(Id, Name, cuberm_tc__Weight__c ORDER BY Name)';
                    keywordList = (List<cuberm_tc__KeywordWeight__c>) cuberm_tc.ApexUtils.findObjects(searchStr, rtrnObj);
                }
            }

            Map<String, cuberm_tc__KeywordWeight__c> keywords = new Map<String, cuberm_tc__KeywordWeight__c>();
            for (cuberm_tc__KeywordWeight__c keyword : keywordList) {
                keywords.put(toLowerCase(keyword.Name).trim(), keyword);
            }

            Map<String, Double> keywordDistanceMap = new Map<String, Double>();
            setKeywordDistanceMap(keywordSet, keywords, keywordDistanceMap);

            for (cuberm_tc__TenderLot__c lot : processLotList) {

                if (String.isNotBlank(lot.cuberm_tc__Keywords__c)) {
                    List<String> lotKeywords = lot.cuberm_tc__Keywords__c.split(',');
                    Integer maxRIndex =  calculateMaxQIndex(lotKeywords, keywords);
                    lot.Qualification_Index_Value__c = String.valueOf(maxRIndex);
                    setSelectedKeyword(tenderLotsMapOld, lot, lotKeywords, keywords, keywordDistanceMap);
                } else {
                    lot.Qualification_Index_Value__c = null;
                }
            }
            setTenderQindexAsLotQindex(tenderLotsList);
        } catch (Exception ex) {
            exceptionHandle(ex, 'CalculateTenderLotRIndex');
        }
    }

    public override void suggestTenderCustomer(cuberm_tc__Tender__c tender) {
        try {
            if (tender.cuberm_tc__Stage__c != 'Qualified') {
                return;
            }
            if (!Schema.SObjectType.Account.isAccessible() ||
                !Schema.SObjectType.cuberm_tc__TenderCustomerSuggestion__c.isAccessible() ||
                !Schema.SObjectType.cuberm_tc__TenderCustomerSuggestion__c.isCreateable() ||
                !Schema.SObjectType.cuberm_tc__TenderCustomerSuggestion__c.isDeletable() ||
                !Schema.SObjectType.cuberm_tc__TenderCustomer__c.isAccessible() ||
                !Schema.SObjectType.cuberm_tc__TenderCustomer__c.isCreateable()) {
                permissionException('SuggestTenderCustomer method, Object permission error. Please contact your administrator.');
            }

            Database.delete([SELECT Id FROM cuberm_tc__TenderCustomerSuggestion__c WHERE cuberm_tc__Tender__c = :tender.Id WITH SECURITY_ENFORCED], true);

            if (tender.cuberm_tc__ContractingAuthority__c != null) {
                Id accRecordTypeId = [SELECT Id FROM RecordType WHERE SobjectType = 'Account' AND IsActive = TRUE AND DeveloperName = :EMEA_RECORD_TYPE ].Id;
                String authority = tender.cuberm_tc__ContractingAuthority__c.replace(' ', ';');
                String searchObject = 'Account(Id, Name WHERE RecordTypeId = \'' + accRecordTypeId + '\')';
                List<Account> accounts = (List<Account>)findObjects(authority, searchObject);
                if (Test.isRunningTest()) {
                    accounts = [SELECT Id, Name FROM Account WITH SECURITY_ENFORCED];
                }
                List<cuberm_tc__TenderCustomerSuggestion__c> suggestions = new List<cuberm_tc__TenderCustomerSuggestion__c>();
                calculateAccountsScore(accounts, suggestions, tender);

                if (!suggestions.isEmpty()) {
                    Database.insert(suggestions, true);
                    insertTenderCustomer(suggestions, tender);
                }
            }
        } catch (Exception ex) {
            exceptionHandle(ex, 'SuggestTenderCustomer');
        }
    }

    private static void exceptionHandle(Exception ex, String method) {
        CubeRM_tc.DebugLog.createLog('{"Type" : "Error","ApexClass" : "CubeRmHelper","Method" : "' + method + '","RecordId" : "","Message" : "Line: ' + ex.getLineNumber() + ' ' + ex.getMessage() + '","StackTrace" : "' + ex.getStackTraceString() + '"}');
        throw ex;
    }

    @TestVisible
    private static void permissionException(String message) {
        AuraHandledException e = new AuraHandledException(message);
        e.setMessage(message);
        throw e;
    }

    private static String toLowerCase(String text) {
        return text.toLowerCase('en');
    }

    private static String getMatchedKeyword(List<String> lotKeywords, Map<String, cuberm_tc__KeywordWeight__c > keywords, Map<String, Double> keywordDistanceMap) {
        Double maxDistance = 0;
        String matchedKeywordId = null;
        for (String lotKwrd : lotKeywords) {
            for (String kwrd : keywords.keySet()) {
                Double distance = keywordDistanceMap.get(toLowerCase(lotKwrd) + ',' + kwrd);
                if (distance != null && distance >= KeywordMapThreshold && distance > maxDistance) {
                    matchedKeywordId = keywords.get(kwrd).Id;
                    maxDistance = distance;
                }
            }
        }
        return matchedKeywordId;
    }

    private static List<SObject> findObjects(String keywords, String rtrnObj) {
        List<String> keywordList = keywords.split(';');
        List<Set<String>> keywordPages = new List<Set<String>>();
        for (Integer i = 0; i < (keywordList.size() / 200) + 1; i++) {
            Set<String> lstTemp = new Set<String>();
            for (Integer j = (i * 200); (j < (i * 200) + 200) && j < keywordList.size(); j++) {
                lstTemp.add(keywordList.get(j));
            }
            keywordPages.add(lstTemp);
        }

        List<SObject> resultList = new List<SObject>();
        for (Set<String> keywordPage : keywordPages) {
            String searchString = '(';
            for (String kwrd : keywordPage) {
                searchString += '"*' + kwrd + '*" OR ';
            }

            searchString = searchString.removeEnd(' OR ');
            searchString += ')';

            String searchQuery = 'FIND :searchString IN ALL FIELDS RETURNING ' + rtrnObj + ' WITH SPELL_CORRECTION = true';
            List<List<SObject>> results = Search.query(searchQuery);
            resultList.addAll(results[0]);
        }
        return resultList;
    }

    public static void calculateTenderQAttachmentIndex(List<cuberm_tc__Tender__c> tenders, Map<String, cuberm_tc__KeywordWeight__c> keywordWeightMap) {
        try {
            for (cuberm_tc__Tender__c tender : tenders) {
                if (String.isNotBlank(tender.cuberm_tc__AttachmentsKeywords__c)) {
                    List<String> keywordList = tender.cuberm_tc__AttachmentsKeywords__c.split(',');
                    Integer maxRIndex = calculateMaxQIndex(keywordList, keywordWeightMap);
                    tender.cuberm_tc__AttachmentsQualificationIndexValue__c = String.valueOf(maxRIndex);
                } else {
                    tender.cuberm_tc__AttachmentsQualificationIndexValue__c = null;
                }
            }
        } catch (Exception ex) {
            exceptionHandle(ex, 'calculateTenderQAttachmentIndex');
        }
    }

    public static Integer calculateMaxQIndex(List<String> keywordsList, Map<String, cuberm_tc__KeywordWeight__c> keywordWeightMap) {
        Integer maxRIndex = 0;
        for (String key : keywordsList) {
            cuberm_tc__KeywordWeight__c keywordWeight = keywordWeightMap.get(toLowerCase(key).trim());
            if (keywordWeight != null) {
                Integer rIndex = (Integer) keywordWeight.cuberm_tc__Weight__c;
                if (rIndex > maxRIndex) {
                    maxRIndex = rIndex;
                }
            }
        }
        return maxRIndex;
    }

    public static void evaluateKeywordsLength(cuberm_tc__Tender__c tender) {
        if (tender.cuberm_tc__Keywords__c.length() > 255) {
            tender.KeywordsSort__c = tender.cuberm_tc__Keywords__c.substring(0, 255);
        } else {
            tender.KeywordsSort__c = tender.cuberm_tc__Keywords__c;
        }
    }

    public static void calculateAccountsScore(List<Account> accounts, List<cuberm_tc__TenderCustomerSuggestion__c> suggestions, cuberm_tc__Tender__c tender) {
        for (Account account : accounts) {
            Double distance = cuberm_tc.ApexUtils.levenshteinDistance(tender.cuberm_tc__ContractingAuthority__c, account.Name);
            if (distance >= CustomerSuggestThreshold) {
                cuberm_tc__TenderCustomerSuggestion__c suggestion = new cuberm_tc__TenderCustomerSuggestion__c();
                suggestion.cuberm_tc__Tender__c = tender.Id;
                suggestion.cuberm_tc__Account__c = account.Id;
                suggestion.cuberm_tc__Score__c = distance;
                suggestions.add(suggestion);
            }
        }
    }

    public static void insertTenderCustomer(List<cuberm_tc__TenderCustomerSuggestion__c> suggestions, cuberm_tc__Tender__c tender) {
        if ([SELECT COUNT() FROM cuberm_tc__TenderCustomer__c WHERE cuberm_tc__Tender__c = :tender.Id WITH SECURITY_ENFORCED] == 0) {
            cuberm_tc__TenderCustomerSuggestion__c bestSuggestion = new cuberm_tc__TenderCustomerSuggestion__c(cuberm_tc__Score__c = 0);
            for (cuberm_tc__TenderCustomerSuggestion__c suggestion : suggestions) {
                if (suggestion.cuberm_tc__Score__c > bestSuggestion.cuberm_tc__Score__c) {
                    bestSuggestion = suggestion;
                }
            }
            List<cuberm_tc__TenderCustomer__c> tenderCust = [SELECT Id FROM cuberm_tc__TenderCustomer__c WHERE cuberm_tc__Tender__c = :tender.Id];
            if (bestSuggestion.cuberm_tc__Score__c >= CustomerMapThreshold && tenderCust.size() == 0) {
                cuberm_tc__TenderCustomer__c tenderCustomer = new cuberm_tc__TenderCustomer__c();
                tenderCustomer.cuberm_tc__Tender__c = tender.Id;
                tenderCustomer.cuberm_tc__Account__c = bestSuggestion.cuberm_tc__Account__c;
                Database.insert(tenderCustomer, true);
            }
        }
    }

    public static void setProcessLotList(List<cuberm_tc__TenderLot__c> tenderLotsList, Map<Id, cuberm_tc__TenderLot__c> tenderLotsMapOld, Set<String> keywordSet, List<cuberm_tc__TenderLot__c> processLotList) {
        for (cuberm_tc__TenderLot__c lot : tenderLotsList) {
            if (String.isNotBlank(lot.cuberm_tc__Keywords__c)) {
                List<String> keywordSplit = lot.cuberm_tc__Keywords__c.split(',');
                for (String key : keywordSplit) {
                    keywordSet.add(toLowerCase(key).trim());
                }
            }
            if (tenderLotsMapOld == null || tenderLotsMapOld.size() == 0) { //if Insert
                if (String.isNotBlank(lot.cuberm_tc__Keywords__c)) {
                    processLotList.add(lot);
                }
            } else { //if Update
                processLotList.add(lot);
            }
        }
    }

    public static void setSelectedKeyword(Map<Id, cuberm_tc__TenderLot__c> tenderLotsMapOld, cuberm_tc__TenderLot__c lot, List<String> lotKeywords, Map<String, cuberm_tc__KeywordWeight__c> keywords, Map<String, Double> keywordDistanceMap) {
        if (tenderLotsMapOld == null || tenderLotsMapOld.size() == 0) { //if Insert
            String matchedKeywordId = getMatchedKeyword(lotKeywords, keywords, keywordDistanceMap);
            if (matchedKeywordId != null) {
                lot.Keyword__c = matchedKeywordId;
            }
        } else { //if Update
            if (lot.Keyword__c == null) {
                cuberm_tc__TenderLot__c tenderLotOld = tenderLotsMapOld.get(lot.Id);
                if (tenderLotOld.cuberm_tc__Keywords__c != lot.cuberm_tc__Keywords__c) {
                    String matchedKeywordId = getMatchedKeyword(lotKeywords, keywords, keywordDistanceMap);
                    if (matchedKeywordId != null) {
                        lot.Keyword__c = matchedKeywordId;
                    }
                }
            }
        }
    }

    public static void setTenderQindexAsLotQindex(List<cuberm_tc__TenderLot__c> tenderLotsList) {
        cuberm_tc__Tender__c tender = [SELECT Qualification_Index_Value__c, (SELECT Id FROM cuberm_tc__TenderLots__r) FROM cuberm_tc__Tender__c WHERE Id = :tenderLotsList[0].cuberm_tc__Tender__c];
        if (tender.cuberm_tc__TenderLots__r.size() == 1 && (tenderLotsList[0].Qualification_Index_Value__c == null || tenderLotsList[0].Qualification_Index_Value__c == '0') &&
            (tender.Qualification_Index_Value__c != null && tender.Qualification_Index_Value__c != '0')) {
            tenderLotsList[0].Qualification_Index_Value__c = tender.Qualification_Index_Value__c;
        }
    }

    public static void setKeywordDistanceMap(Set<String> keywordSet, Map<String, cuberm_tc__KeywordWeight__c> keywords, Map<String, Double> keywordDistanceMap) {
        for (String kwrd : keywordSet) {
            for (String keyword : keywords.keySet()) {
                Double distance = cuberm_tc.ApexUtils.levenshteinDistance(kwrd, keyword);
                if (distance >= KeywordSuggestThreshold) {
                    keywordDistanceMap.put(kwrd + ',' + keyword, distance);
                }
            }
        }
    }
    
    public static void transferProductToOutcomeOnAwarded(List<cuberm_tc__Tender__c> triggerNew, Map<Id, cuberm_tc__Tender__c> oldTenderLotMap){
        Set<String> awardedTenders = new Set<String>();
        for (cuberm_tc__Tender__c tenderNew : triggerNew) {
            cuberm_tc__Tender__c tenderOld = oldTenderLotMap.get(tenderNew.Id);
            if (tenderOld.cuberm_tc__Stage__c != 'Awarded' && tenderNew.cuberm_tc__Stage__c == 'Awarded') {
                awardedTenders.add(tenderNew.Id);
            }
        }
        if (awardedTenders.size() > 0) {
            CubeRmHelper.updateLotAwardChildrenOnAwarded(awardedTenders);
        }
    }
    
    public static void updateLotAwardChildrenOnAwarded(Set<String> awardedTenders){
        String orgName = UserInfo.getOrganizationName();
        List<String> lotStatus = CubeRmHelper.getPicklistValues('cuberm_tc__TenderLot__c', 'cuberm_tc__Status__c'); //2nd value 'Bid' 3rd 'Linked'
        List<cuberm_tc__TenderLot__c> biddedLots = [
                SELECT Id, (
                        SELECT cuberm_tc__Product__c,cuberm_tc__Quantity__c, cuberm_tc__UnitPrice__c, CurrencyIsoCode, Distributor__c
                        FROM cuberm_tc__TenderLotProducts__r
                        ORDER BY Id
                ), (SELECT Id FROM cuberm_tc__TenderLotAwards__r)
                FROM cuberm_tc__TenderLot__c
                WHERE cuberm_tc__Tender__c IN :awardedTenders
                AND (cuberm_tc__Status__c = :lotStatus[1] OR cuberm_tc__Status__c = :lotStatus[2])
        ];
        List<cuberm_tc__TenderLotAward__c> lotAwards = new List<cuberm_tc__TenderLotAward__c>();
        Set<Id> productIds = new Set<Id>();
        for (cuberm_tc__TenderLot__c biddedLot : biddedLots) {
            if (biddedLot.cuberm_tc__TenderLotAwards__r.isEmpty()) {
                for (cuberm_tc__TenderLotProduct__c lotProduct : biddedLot.cuberm_tc__TenderLotProducts__r) {
                    lotAwards.add(new cuberm_tc__TenderLotAward__c(cuberm_tc__TenderLot__c = biddedLot.Id,
                            cuberm_tc__TenderLotProduct__c = lotProduct.Id,
                            OutcomeProduct__c = lotProduct.cuberm_tc__Product__c,
                            cuberm_tc__Company__c = orgName,
                            cuberm_tc__Quantity__c = lotProduct.cuberm_tc__Quantity__c,
                            cuberm_tc__Price__c = lotProduct.cuberm_tc__UnitPrice__c,
                            Distributor__c = lotProduct.Distributor__c));
                    productIds.add(lotProduct.Id);
                }
            }
        }
        if(!lotAwards.isEmpty()) {
            insert lotAwards;
        }
        Map<String, Id> lotAwardIdsByLotAndProduct = new Map<String, Id>();
        for(cuberm_tc__TenderLotAward__c lotAward : lotAwards){
            lotAwardIdsByLotAndProduct.put('' + lotAward.cuberm_tc__TenderLot__c + lotAward.OutcomeProduct__c, lotAward.Id);
        }
        List<cuberm_tc__TenderLotAwardChild__c> tenderLotAwardChildren = new List<cuberm_tc__TenderLotAwardChild__c>();
        for (cuberm_tc__TenderLotProductCompetitor__c tenderLotProductCompetitor : [
                SELECT CompetitorProductName__c,
                        EstimatedPrice__c,
                        Competitor__c,
            			CompetitorName__c,
                        CompetitorProduct__c,
                        cuberm_tc__TenderLotProduct__c,
                        cuberm_tc__TenderLotProduct__r.cuberm_tc__TenderLot__c,
                        cuberm_tc__TenderLotProduct__r.cuberm_tc__Product__c,
                        cuberm_tc__TenderLotProduct__r.cuberm_tc__Quantity__c,
                        CurrencyIsoCode,
                        Distributor__c
                FROM cuberm_tc__TenderLotProductCompetitor__c
                WHERE cuberm_tc__TenderLotProduct__c IN :productIds
                ORDER BY Id
        ]) {
            tenderLotAwardChildren.add(new cuberm_tc__TenderLotAwardChild__c
                    (cuberm_tc__TenderLotAward__c = (Id) lotAwardIdsByLotAndProduct.get('' + tenderLotProductCompetitor.cuberm_tc__TenderLotProduct__r.cuberm_tc__TenderLot__c + tenderLotProductCompetitor.cuberm_tc__TenderLotProduct__r.cuberm_tc__Product__c),
                            cuberm_tc__TenderLotProductCompetitor__c = tenderLotProductCompetitor.Id,
                            Competitor__c = tenderLotProductCompetitor.Competitor__c,
                            cuberm_tc__Company__c = tenderLotProductCompetitor.CompetitorName__c,
                            cuberm_tc__Product__c = tenderLotProductCompetitor.CompetitorProductName__c,
                            OutcomeProduct__c = tenderLotProductCompetitor.CompetitorProduct__c,
                            cuberm_tc__Quantity__c = tenderLotProductCompetitor.cuberm_tc__tenderLotProduct__r.cuberm_tc__Quantity__c,
                            cuberm_tc__Price__c = tenderLotProductCompetitor.EstimatedPrice__c,
                            Distributor__c = tenderLotProductCompetitor.Distributor__c));
        }
        if(!tenderLotAwardChildren.isEmpty()){
            insert tenderLotAwardChildren;
        }

    }
    
    public static List<String> getPicklistValues(String objectName, String fieldName) {
        List<String> values = new List<String>();
        DescribeFieldResult fieldResult = Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap().get(fieldName).getDescribe();
        List<Schema.PicklistEntry> pEntries = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry pEntry : pEntries) {
            values.add(pEntry.getLabel());
        }
        return values;
    }
    
    public static void updateLotStatusWhenProductAdded(List<cuberm_tc__TenderLotProduct__c> triggerNew) {
        Set<Id> tenderLotIds = new Set<Id>();
    	List<string> lotStatus = getPicklistValues('cuberm_tc__TenderLot__c', 'cuberm_tc__Status__c');
        for (cuberm_tc__TenderLotProduct__c lotProductNew : triggerNew) {
            tenderLotIds.add(lotProductNew.cuberm_tc__TenderLot__c);
        }
        
        Map<Id, cuberm_tc__TenderLot__c> tenderLotMap = new Map<Id, cuberm_tc__TenderLot__c>([SELECT Id, cuberm_tc__Status__c FROM cuberm_tc__TenderLot__c WHERE Id = :tenderLotIds AND cuberm_tc__Status__c = :lotStatus[0]]);
        
        for (cuberm_tc__TenderLot__c tenderLot : tenderLotMap.values()) {
            tenderLot.cuberm_tc__Status__c = lotStatus[1];
        }  
        update tenderLotMap.values();
    }

    @AuraEnabled
    public static TenderLotResultDto PrepareImport(String tenderId, List<String> lotIds) {
        TenderLotResultDto result = new TenderLotResultDto();
        cuberm_tc__Tender__c tender = [
                SELECT SalesRep__c, Tender_Type__c, cuberm_tc__ContractingAuthority__c, PriceBook__c, cuberm_tc__Country__c, MainAccount__c, MainAccount__r.Name
                FROM cuberm_tc__Tender__c
                WHERE Id = :tenderId
                WITH SECURITY_ENFORCED
        ];
        if (tender.Tender_Type__c == 'Past') {
            result.Warnings.add('You cannot create Opportunity for a Past Tender.');
        }
        if (tender.PriceBook__c == null && !Test.isRunningTest()) {
            result.Warnings.add('You must select a Pricebook for the Tender.');
        }

        List<cuberm_tc__TenderLot__c> biddedLots = new List<cuberm_tc__TenderLot__c>();
        biddedLots = [
                SELECT Id, cuberm_tc__Lot__c, cuberm_tc__Tender__r.LocalTitle__c, cuberm_tc__Tender__r.Name,
                        cuberm_tc__Tender__c, cuberm_tc__Status__c
                FROM cuberm_tc__TenderLot__c
                WHERE cuberm_tc__Tender__c = :tenderId
                AND Id IN :lotIds
                WITH SECURITY_ENFORCED
        ];

        if (biddedLots.size() == 0) {
            result.Warnings.add('Please select at least one Lot to create the Opportunity.');
        } else {
            Set<String> tLotProductsSet = new Set<String>();
            List<cuberm_tc__TenderLotProduct__c> tLotProducts = [
                    SELECT cuberm_tc__TenderLot__c
                    FROM cuberm_tc__TenderLotProduct__c
                    WHERE cuberm_tc__TenderLot__c IN :biddedLots
                    WITH SECURITY_ENFORCED
            ];
            for (cuberm_tc__TenderLotProduct__c tLotProduct : tLotProducts) {
                tLotProductsSet.add(tLotProduct.cuberm_tc__TenderLot__c);
            }

            for (cuberm_tc__TenderLot__c biddedLot : biddedLots) {
                if (!tLotProductsSet.contains(biddedLot.Id)) {
                    result.Warnings.add('Products not associated with Lot ' + biddedLot.cuberm_tc__Lot__c + '. Please add products into the Lot before linking to Opportunity.');
                }
            }
        }
        if (result.Warnings.size() > 0) {
            return result;
        }

        result.TenderLots.addAll(biddedLots);

        if (tender.MainAccount__c != null) {
            result.AccountId = tender.MainAccount__c;
            result.AccountName = tender.MainAccount__r.Name;
        }

        return result;
    }

    @AuraEnabled
    public static AccountResultDto GetAccountResults(String accountId, String tenderId) {
        AccountResultDto result = new AccountResultDto();
        try {
            result.AccountName = [SELECT Name FROM Account WHERE Id = :accountId WITH SECURITY_ENFORCED].Name;
            result.Opportunities = [
                    SELECT Name, CloseDate, Amount, StageName
                    FROM Opportunity
                    WHERE AccountId = :accountId
                    AND CubeRMTender__c != :tenderId
                    WITH SECURITY_ENFORCED
                    ORDER BY Name
            ];

        } catch (Exception ex) {
            exceptionHandle(ex, 'GetAccountResults');
        }
        return result;
    }

    @AuraEnabled
    public static SaveDtoReturn SaveOpportunity(OpportunitySaveDto opptyDto) {
        SaveDtoReturn saveReturn = new SaveDtoReturn();
        try {
            List<String> lotStatus = getPicklistValues('cuberm_tc__TenderLot__c', 'cuberm_tc__Status__c'); //2nd value 'Bid' 3rd 'Linked'
            if (opptyDto.AccountId == null || opptyDto.OppCloseDate == null || opptyDto.CurrencyIsoCode == null) {
                throwHandledException('You must Select an Account/Close Date/CurrencyIsoCode to procced.');
            }
            cuberm_tc__Tender__c tender = [
                    SELECT Name, PriceBook__c
                    FROM cuberm_tc__Tender__c
                    WHERE Id = :opptyDto.TenderId
                    WITH SECURITY_ENFORCED
            ];
            
            Id oppRecordTypeId = [SELECT Id FROM RecordType WHERE SobjectType = 'Opportunity' AND IsActive = TRUE AND DeveloperName = :OPP_EMEA_RECORD_TYPE ].Id;

            Opportunity opportunity = new Opportunity();
            if (opptyDto.OpportunityId == null) {
                opportunity.AccountId = opptyDto.AccountId;
            } else {
                opportunity = [
                        SELECT AccountId, CloseDate, StageName, CubeRMTender__c
                        FROM Opportunity
                        WHERE Id = :opptyDto.OpportunityId
                        WITH SECURITY_ENFORCED
                ];
            }
            opportunity.CloseDate = opptyDto.OppCloseDate;
            opportunity.OwnerId = opptyDto.OppOwnerId;
            opportunity.StageName = opptyDto.Stage;
            opportunity.RecordTypeId = oppRecordTypeId;
            opportunity.CubeRMTender__c = opptyDto.TenderId;
            opportunity.Pricebook2Id = tender.PriceBook__c;
            opportunity.CurrencyIsoCode = opptyDto.CurrencyIsoCode;
            opportunity.Name = opptyDto.OpportunityName;

            Map<Id, cuberm_tc__TenderLot__c> tenderLots = new Map<Id, cuberm_tc__TenderLot__c>([
                    SELECT Id, cuberm_tc__Status__c, cuberm_tc__Lot__c, Opportunity__c,
                            QualityCriteriaRollup__c
                    FROM cuberm_tc__TenderLot__c
                    WHERE cuberm_tc__Tender__c = :opptyDto.TenderId
                    AND Id IN :opptyDto.LotIds
                    WITH SECURITY_ENFORCED
            ]);

            upsert opportunity;

            saveReturn.OpportunityId = opportunity.Id;

            for (cuberm_tc__TenderLot__c tLot : tenderLots.values()) {
                if (tLot.cuberm_tc__Status__c == lotStatus[1]) {
                    tLot.cuberm_tc__Status__c = lotStatus[2];
                    tLot.cuberm_tc__IsImported__c = true;
                }
                tLot.Opportunity__c = opportunity.Id;
            }
            update tenderLots.values();

            createOpportunityLineItems(opptyDto.LotIds, opportunity);
        }catch (Exception ex){
            throwHandledAuraException(ex, 'SaveOpportunity', 'Line: ' + ex.getLineNumber() + ' ' + ex.getMessage());
        }
        return saveReturn;
    }

    private static void createOpportunityLineItems(List<String> lotIds, Opportunity opp) {
        try{
            List<cuberm_tc__TenderLotProduct__c> tLotProducts = [
                    SELECT Id, cuberm_tc__Product__c, cuberm_tc__Product__r.ProductCode,
                            cuberm_tc__TenderLot__r.Name, cuberm_tc__UnitPrice__c, cuberm_tc__Quantity__c, PricebookEntryId__c
                    FROM cuberm_tc__TenderLotProduct__c
                    WHERE cuberm_tc__TenderLot__c IN :lotIds
                    WITH SECURITY_ENFORCED
                    ORDER BY cuberm_tc__TenderLot__c
            ];

            List<OpportunityLineItem> oppLineItemList = new List<OpportunityLineItem>();
            for (cuberm_tc__TenderLotProduct__c tLotProduct : tLotProducts) {
                OpportunityLineItem oppLineItem = new OpportunityLineItem();
                oppLineItem.OpportunityId = opp.Id;
                oppLineItem.CubeRMTenderLotProduct__c = tLotProduct.Id;
                oppLineItem.Product2Id = tLotProduct.cuberm_tc__Product__c;
                oppLineItem.UnitPrice = tLotProduct.cuberm_tc__UnitPrice__c;
                oppLineItem.Quantity = tLotProduct.cuberm_tc__Quantity__c;
                oppLineItem.CubeRMTenderLot__c = tLotProduct.cuberm_tc__TenderLot__c;
                oppLineItem.PricebookEntryId = tLotProduct.PricebookEntryId__c;
system.debug('oppLI'+oppLineItem);
                oppLineItemList.add(oppLineItem);
            }
            insert oppLineItemList;
        }catch (Exception ex){
            throwHandledAuraException(ex, 'SaveOpportunity', 'Line: ' + ex.getLineNumber() + ' ' + ex.getMessage());
        }
    }

    public override List<sObject> TableSearchData(String objectName, List<String> columnNames, List<String> columnTypes, List<String> columnValues, String tenderId, String lotId,
            integer count, integer offset, String sortField, String sortDirection, boolean showAll) {
        String searchClause = '';

        if (columnNames.size() > 0) {
            searchClause += 'WHERE ';
            for (integer i = 0; i < columnNames.size(); i++) {
                switch on columnTypes[i] {
                    when 'lookup' {
                        searchClause += columnNames[i] + '=\'' + columnValues[i] + '\' AND ';
                    } when 'date' {
                        searchClause += columnNames[i] + '=' + columnValues[i].trim() + ' AND ';
                    } when 'number', 'currency' {
                        searchClause += columnNames[i] + '>=' + columnValues[i] + ' AND ';
                    } when 'boolean' {
                        searchClause += columnNames[i] + '=' + columnValues[i] + ' AND ';
                    } when else {
                        List<String> columnParts = columnValues[i].split(' ');
                        for (String part : columnParts) {
                            if (part.trim() != '') {
                                searchClause += columnNames[i] + ' LIKE \'%' + part.trim() + '%\' AND ';
                            }
                        }
                    }
                }
            }
            searchClause = searchClause.subString(0, searchClause.length() - 5);
        }

        if (objectName == 'Product2') {
            cuberm_tc__Tender__c tender = [SELECT cuberm_tc__Country__c, PriceBook__c FROM cuberm_tc__Tender__c WHERE Id = :tenderId WITH SECURITY_ENFORCED];
            if (tender.PriceBook__c == null && !Test.isRunningTest())
                throwHandledException('Please select pricebook for tender.');
            List<PricebookEntry> pbEntries = [
                    SELECT Product2Id
                    FROM PricebookEntry
                    WHERE Pricebook2Id = :tender.PriceBook__c
                    AND IsActive = true
                    WITH SECURITY_ENFORCED
            ];
            Set<Id> productIds = new Set<Id>();
            //MATE -8: Select Products from the selected Pricebook only. No filter with keyword.
            for (PricebookEntry pbEntry : pbEntries) {
                productIds.add(pbEntry.Product2Id);
            }

            if (String.isEmpty(searchClause))
                searchClause += 'WHERE Id IN :productIds';
            else
                searchClause += ' AND Id IN :productIds';
        }
        if (objectName == 'Account') {
            Id accRecordTypeId = [SELECT Id FROM RecordType WHERE SobjectType = 'Account' AND IsActive = TRUE AND DeveloperName = 'Account_EMEA'].Id;
            if (String.isEmpty(searchClause)) {
                searchClause += '  WHERE RecordTypeId = \'' + accRecordTypeId + '\' ';
            } else {
                searchClause += '  AND RecordTypeId = \'' + accRecordTypeId + '\' ';
            }
        }

        return Database.query('SELECT ' + getFieldsOfObject(objectName) + ' FROM ' + objectName + ' ' + searchClause + ' WITH SECURITY_ENFORCED ORDER BY ' + sortField +
                ' ' + sortDirection + ' LIMIT ' + count + ' OFFSET ' + offset);
    }

    @TestVisible
    private static String getFieldsOfObject(String sobjectName) {
        String queryFields = '';

        Schema.DescribeSObjectResult dsr = Schema.getGlobalDescribe().get(sobjectName).getDescribe();
        Map<String, Schema.SObjectField> fields = dsr.fields.getMap();

        for (String s : fields.keySet()) {
            Schema.DescribeFieldResult fldDsr = fields.get(s).getDescribe();
            if (fldDsr.isAccessible()) {
                queryFields += fields.get(s).getDescribe().getName() + ',';
            }
        }

        return queryFields.substring(0, queryFields.length() - 1);
    }

    private static void throwHandledAuraException(Exception ex, String method, String message) {
        CubeRM_tc.DebugLog.createLog('{"Type" : "Error","ApexClass" : "CubeRmHelper","Method" : "' + method + '","RecordId" : "","Message" : "Line: ' + ex.getLineNumber() + ' ' + ex.getMessage() + '","StackTrace" : "' + ex.getStackTraceString() + '"}');
        AuraHandledException e = new AuraHandledException(message);
        e.setMessage(message);
        throw e;
    }
    
    @TestVisible
    private static void throwHandledException(String message) {
        AuraHandledException e = new AuraHandledException(message);
        e.setMessage(message);
        throw e;
    }

    @AuraEnabled
    public static void unlinkLotsFromOpportunity(List<Id> lotIds, Id tenderId) {
        Savepoint sp = Database.setSavepoint();
        try {
            cuberm_tc__Tender__c tender = [SELECT cuberm_tc__Country__c FROM cuberm_tc__Tender__c WHERE Id = :tenderId LIMIT 1];
            Map<Id, cuberm_tc__TenderLotProduct__c> linkedTenderLotProductsMap = new Map<Id, cuberm_tc__TenderLotProduct__c>([
                SELECT Id, cuberm_tc__TenderLot__c
                FROM cuberm_tc__TenderLotProduct__c
                WHERE cuberm_tc__TenderLot__c IN :lotIds
                AND cuberm_tc__TenderLot__r.cuberm_tc__IsImported__c = TRUE
                ORDER BY cuberm_tc__TenderLot__c, Id
            ]);
            //lot status 2nd value 'Bid' 3rd 'Linked'
            List<String> lotStatus = getPicklistValues('cuberm_tc__TenderLot__c', 'cuberm_tc__Status__c');
            Map<Id, cuberm_tc__TenderLot__c> linkedTenderLotsMap = new Map<Id, cuberm_tc__TenderLot__c>([
                SELECT Opportunity__c, cuberm_tc__Status__c, cuberm_tc__IsImported__c
                FROM cuberm_tc__TenderLot__c
                WHERE Id IN :lotIds
                AND cuberm_tc__IsImported__c = TRUE
                ORDER BY Id
            ]);
            unlinkProductsFromOpportunityLineItems(linkedTenderLotProductsMap.keySet(), linkedTenderLotsMap.values());
            unlinkOpportunityFromLots(linkedTenderLotsMap.values(), lotStatus);
        } catch (Exception ex) {
            Database.rollback(sp);
            throwHandledAuraException(ex, 'unlinkLotsFromOpportunity', 'Line: ' + ex.getLineNumber() + ' ' + ex.getMessage());
        }
    }

    private static void unlinkProductsFromOpportunityLineItems(Set<Id> tenderLotProductIds,
        List<cuberm_tc__TenderLot__c> tenderLots) {
        try {
            Set<Id> opportunityIds = new Set<Id>();
            for (cuberm_tc__TenderLot__c tLot : tenderLots) {
                opportunityIds.add(tLot.Opportunity__c);
            }
            List<OpportunityLineItem> opportunityLineItems = [
                SELECT CubeRMTenderLotProduct__c
                FROM OpportunityLineItem
                WHERE OpportunityId IN :opportunityIds
                AND CubeRMTenderLotProduct__c IN :tenderLotProductIds
            ];
            delete opportunityLineItems;

            List<Opportunity> opportunitiesAfter = [
                SELECT CubeRMTender__c, (
                    SELECT CubeRMTenderLotProduct__c
                    FROM OpportunityLineItems
                    WHERE CubeRMTenderLotProduct__c != NULL
                )
                FROM Opportunity
                WHERE Id IN :opportunityIds
            ];
            List<Opportunity> opportunitiesToUpdate = new List<Opportunity>();
            for(Opportunity oppAfter : opportunitiesAfter){
                if (oppAfter.OpportunityLineItems.isEmpty()) {
                    oppAfter.CubeRMTender__c = null;
                    opportunitiesToUpdate.add(oppAfter);
                }
            }
            update opportunitiesToUpdate;
        } catch (Exception ex) {
            throwHandledAuraException(ex, 'unlinkProductsFromOpportunityLineItems', 'Line: ' + ex.getLineNumber() + ' ' + ex.getMessage());
        }
    }

    private static void unlinkOpportunityFromLots(List<cuberm_tc__TenderLot__c> linkedTenderLots,
        List<String> lotStatus) {
        try {
            for (cuberm_tc__TenderLot__c linkedLot : linkedTenderLots) {
                linkedLot.Opportunity__c = null;
                linkedLot.cuberm_tc__Status__c = lotStatus[1];
                linkedLot.cuberm_tc__IsImported__c = false;
            }
            update linkedTenderLots;
        } catch (Exception ex) {
            throwHandledAuraException(ex, 'unlinkOpportunityFromLots', 'Line: ' + ex.getLineNumber() + ' ' + ex.getMessage());
        }
    }
    
    public static void updatePricebookEntryOnLotProduct(List<cuberm_tc__TenderLotProduct__c> triggerNew) {
        Map<String, PricebookEntry> pbEntryMap = new Map<String, PricebookEntry>();
        Set<Id> productIds = new Set<Id>();
        Set<Id> pocPricebooks = new Set<Id>();
        Set<Id> tenderLotIds = new Set<Id>();
    
        for (cuberm_tc__TenderLotProduct__c lotProductNew : triggerNew) {
            productIds.add(lotProductNew.cuberm_tc__Product__c);
            tenderLotIds.add(lotProductNew.cuberm_tc__TenderLot__c);
        }
    
        Map<Id, cuberm_tc__TenderLot__c> tenderLotMap = new Map<Id, cuberm_tc__TenderLot__c>([SELECT cuberm_tc__Tender__r.PriceBook__c, cuberm_tc__Status__c FROM cuberm_tc__TenderLot__c WHERE Id = :tenderLotIds]);
        for (cuberm_tc__TenderLot__c tenderLot : tenderLotMap.values()) {
            pocPricebooks.add(tenderLot.cuberm_tc__Tender__r.PriceBook__c);
        }
    
        List<PricebookEntry> pbEntries = [
                SELECT Product2Id, Pricebook2Id, CurrencyIsoCode, UnitPrice
                FROM PricebookEntry
                WHERE Product2Id IN :productIds
                AND Pricebook2Id IN :pocPricebooks
                AND IsActive = TRUE
        ];
        for (PricebookEntry pbEntry : pbEntries) {
            pbEntryMap.put('' + pbEntry.Product2Id + pbEntry.Pricebook2Id, pbEntry);
        }
        for (cuberm_tc__TenderLotProduct__c lotProductNew : triggerNew) {
            cuberm_tc__TenderLot__c tenderLot = tenderLotMap.get(lotProductNew.cuberm_tc__TenderLot__c);
            if (pbEntryMap.containsKey('' + lotProductNew.cuberm_tc__Product__c + tenderLot.cuberm_tc__Tender__r.PriceBook__c)) {
                PricebookEntry pEntry = pbEntryMap.get('' + lotProductNew.cuberm_tc__Product__c + tenderLot.cuberm_tc__Tender__r.PriceBook__c);
                lotProductNew.PricebookEntryId__c = pEntry.Id;
                lotProductNew.CurrencyIsoCode = pEntry.CurrencyIsoCode;
                lotProductNew.cuberm_tc__ListPrice__c = pEntry.UnitPrice;
            }
        }
    }
}