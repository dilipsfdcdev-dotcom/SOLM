public class VoiceCallHandler {

    // ✅ Move CaseConfig OUTSIDE the method
    public class CaseConfig {
        public String recordTypeKey;
        public String typeValue;
        public String priorityValue;

        public CaseConfig(String rt, String t, String p) {
            this.recordTypeKey = rt;
            this.typeValue = t;
            this.priorityValue = p;
        }
    }

    public static void handleAfterUpdate(List<VoiceCall> newVoiceCalls, Map<Id, VoiceCall> oldVoiceCallMap) {
        System.debug(LoggingLevel.INFO, 'VoiceCallHandler.handleAfterUpdate: START'
            + ' | newVoiceCalls.size=' + (newVoiceCalls != null ? newVoiceCalls.size() : 0)
            + ' | oldVoiceCallMap.size=' + (oldVoiceCallMap != null ? oldVoiceCallMap.size() : 0));

        List<VoiceCall> voiceCallsToProcess = new List<VoiceCall>();

        // Filter records where CallOrigin changed to 'Voicemail'
        for (VoiceCall vcNew : newVoiceCalls) {
            VoiceCall vcOld = oldVoiceCallMap != null ? oldVoiceCallMap.get(vcNew.Id) : null;
            Boolean changedToVoicemail = (vcNew.CallOrigin == 'Voicemail' && vcOld != null && vcOld.CallOrigin != 'Voicemail');
            System.debug(LoggingLevel.DEBUG, 'Evaluate VC ' + vcNew.Id
                + ' | OldOrigin=' + (vcOld != null ? vcOld.CallOrigin : 'null')
                + ' | NewOrigin=' + vcNew.CallOrigin
                + ' | changedToVoicemail=' + changedToVoicemail);
            if (changedToVoicemail) {
                voiceCallsToProcess.add(vcNew);
            }
        }
        System.debug(LoggingLevel.INFO, 'Filtered voiceCallsToProcess.size=' + voiceCallsToProcess.size());
        if (voiceCallsToProcess.isEmpty()) {
            System.debug(LoggingLevel.INFO, 'No VoiceCall moved to Voicemail. EXIT');
            return;
        }

        // ---- Queues: API Name -> Id
        Map<String, Id> queueApiNameToId = new Map<String, Id>();
        for (Group g : [
            SELECT Id, DeveloperName
            FROM Group
            WHERE Type = 'Queue'
            AND DeveloperName IN ('Orders','AR','AP','Returns','Complaints')
        ]) {
            queueApiNameToId.put(g.DeveloperName, g.Id);
        }
        System.debug(LoggingLevel.INFO, 'Loaded Queues (API -> Id): ' + queueApiNameToId);

        // ---- IVR to Queue mapping
        Map<String, String> ivrSelectionToQueueAPI = new Map<String, String>{
            'orderdelivery' => 'Orders',
            'orderordeliverystatus' => 'Orders',
            'productavailability' => 'Orders',
            'finance' => 'AR',
            'returns' => 'Returns',
            'qualityandregulatory' => 'Complaints'
        };
        System.debug(LoggingLevel.DEBUG, 'IVR->Queue map: ' + ivrSelectionToQueueAPI);

        // ---- IVR to CaseConfig mapping (works now)
        Map<String, CaseConfig> ivrToCaseConfig = new Map<String, CaseConfig>{
            'returns' => new CaseConfig('Sales_Ops', 'Simple return', 'return'),
            'productavailability' => new CaseConfig('Sales_Ops', 'etd', 'orders'),
            'finance' => new CaseConfig('Finance', 'Unknown request for investigation', 'AR'),
            'qualityandregulatory' => new CaseConfig('Quality', 'redirected', 'complaints'),
            'orderdelivery' => new CaseConfig('Sales_Ops', 'ETD update', 'High - Orders'),
            'orderordeliverystatus' => new CaseConfig('Sales_Ops', 'ETD update', 'High - Orders')
        };
        System.debug(LoggingLevel.DEBUG, 'IVR->CaseConfig map keys=' + ivrToCaseConfig.keySet());

        // ---- Preload Case RecordType Ids
        Map<String, Id> rtByDevName = new Map<String, Id>();
        Map<String, Id> rtByNameLower = new Map<String, Id>();
        for (RecordType rt : [
            SELECT Id, DeveloperName, Name
            FROM RecordType
            WHERE SObjectType = 'Case'
        ]) {
            if (rt.DeveloperName != null) rtByDevName.put(rt.DeveloperName, rt.Id);
            if (rt.Name != null) rtByNameLower.put(rt.Name.toLowerCase(), rt.Id);
        }
        System.debug(LoggingLevel.INFO, 'RecordTypes loaded: byDev=' + rtByDevName.size() + ', byName=' + rtByNameLower.size());

        List<Case> casesToCreate = new List<Case>();
        Map<Id, Id> voiceCallToCaseMap = new Map<Id, Id>();

        for (VoiceCall vcNew : voiceCallsToProcess) {
            String normIvr = normalize(vcNew.IVR_Selection__c);
            System.debug(LoggingLevel.DEBUG, 'VC ' + vcNew.Id + ' | Raw IVR=' + vcNew.IVR_Selection__c + ' | Normalized=' + normIvr);

            // Owner selection
            Id ownerId;
            if (normIvr != null
                && ivrSelectionToQueueAPI.containsKey(normIvr)
                && queueApiNameToId.containsKey(ivrSelectionToQueueAPI.get(normIvr))) {
                String queueApi = ivrSelectionToQueueAPI.get(normIvr);
                ownerId = queueApiNameToId.get(queueApi);
                System.debug(LoggingLevel.INFO, 'VC ' + vcNew.Id + ' | Queue matched: ' + queueApi + ' | OwnerId=' + ownerId);
            } else {
                ownerId = vcNew.OwnerId;
                System.debug(LoggingLevel.INFO, 'VC ' + vcNew.Id + ' | No queue match. Using existing OwnerId=' + ownerId);
            }

            // CaseConfig resolution
            Id caseRtId;
            String caseType;
            String casePriority;

            CaseConfig cfg = ivrToCaseConfig.get(normIvr);
            if (cfg != null) {
                if (cfg.recordTypeKey != null) {
                    if (rtByDevName.containsKey(cfg.recordTypeKey)) {
                        caseRtId = rtByDevName.get(cfg.recordTypeKey);
                    } else if (rtByNameLower.containsKey(cfg.recordTypeKey.toLowerCase())) {
                        caseRtId = rtByNameLower.get(cfg.recordTypeKey.toLowerCase());
                    }
                }
                caseType = cfg.typeValue;
                casePriority = cfg.priorityValue;

                System.debug(LoggingLevel.INFO, 'VC ' + vcNew.Id
                    + ' | CaseConfig: rtKey=' + cfg.recordTypeKey
                    + ' -> rtId=' + caseRtId
                    + ' | type=' + caseType
                    + ' | priority=' + casePriority);
            } else {
                System.debug(LoggingLevel.WARN, 'VC ' + vcNew.Id + ' | No CaseConfig for normIvr=' + normIvr + '. Defaults will be used.');
            }

            Case newCase = new Case(
                Subject = 'Voicemail',
                Origin = 'Phone',
                ContactId = vcNew.Contact__c,
                OwnerId = ownerId,
                Status = 'New'
            );
            if (caseRtId != null) newCase.RecordTypeId = caseRtId;
            if (caseType != null) newCase.Type = caseType;
            if (casePriority != null) newCase.Priority = casePriority;

            casesToCreate.add(newCase);
            voiceCallToCaseMap.put(vcNew.Id, null);

            System.debug(LoggingLevel.DEBUG, 'VC ' + vcNew.Id + ' | Prepared Case (pre-insert): '
                + 'Subject=' + newCase.Subject
                + ', RT=' + newCase.RecordTypeId
                + ', Type=' + newCase.Type
                + ', Priority=' + newCase.Priority
                + ', Owner=' + newCase.OwnerId
                + ', Contact=' + newCase.ContactId);
        }

        System.debug(LoggingLevel.INFO, 'casesToCreate.size=' + casesToCreate.size());

        if (!casesToCreate.isEmpty()) {
            try {
                insert casesToCreate;
                System.debug(LoggingLevel.INFO, 'Inserted Cases count=' + casesToCreate.size()
                    + ' | firstId=' + casesToCreate[0].Id);
            } catch (DmlException d) {
                System.debug(LoggingLevel.ERROR, 'Case insert failed: ' + d.getMessage());
                throw d;
            }

            Integer i = 0;
            for (Id vcId : voiceCallToCaseMap.keySet()) {
                if (i < casesToCreate.size()) {
                    voiceCallToCaseMap.put(vcId, casesToCreate[i].Id);
                }
                i++;
            }
            System.debug(LoggingLevel.DEBUG, 'voiceCallToCaseMap after insert: ' + voiceCallToCaseMap);

            List<VoiceCall> voiceCallsToUpdate = new List<VoiceCall>();
            for (VoiceCall vcNew : voiceCallsToProcess) {
                Id linkedCaseId = voiceCallToCaseMap.get(vcNew.Id);
                voiceCallsToUpdate.add(new VoiceCall(
                    Id = vcNew.Id,
                    Case__c = linkedCaseId,
                    RelatedRecordId = linkedCaseId
                ));
            }
            System.debug(LoggingLevel.INFO, 'voiceCallsToUpdate.size=' + voiceCallsToUpdate.size());

            try {
                update voiceCallsToUpdate;
                System.debug(LoggingLevel.INFO, 'Updated VoiceCalls with Case links. Example record='
                    + (voiceCallsToUpdate.isEmpty() ? null : voiceCallsToUpdate[0]));
            } catch (DmlException d) {
                System.debug(LoggingLevel.ERROR, 'VoiceCall update failed: ' + d.getMessage());
                throw d;
            }
        }

        System.debug(LoggingLevel.INFO, 'VoiceCallHandler.handleAfterUpdate: END');
    }

    // Helper method moved outside method
    private static String normalize(String s) {
        if (s == null) return null;
        String out = s.toLowerCase().replaceAll('[^a-z]', '');
        System.debug(LoggingLevel.DEBUG, 'normalize("' + s + '") -> "' + out + '"');
        return out;
    }
}