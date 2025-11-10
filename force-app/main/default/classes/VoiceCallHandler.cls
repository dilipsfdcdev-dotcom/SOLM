public class VoiceCallHandler {

    public static void handleAfterUpdate(List<VoiceCall> newVoiceCalls, Map<Id, VoiceCall> oldVoiceCallMap) {
        List<VoiceCall> voiceCallsToProcess = new List<VoiceCall>();

        // Filter records where CallOrigin is changed to 'Voicemail'
        for (VoiceCall vcNew : newVoiceCalls) {
            VoiceCall vcOld = oldVoiceCallMap.get(vcNew.Id);
            if (vcNew.CallOrigin == 'Voicemail' && vcOld != null && vcOld.CallOrigin != 'Voicemail') {
                voiceCallsToProcess.add(vcNew);
            }
        }

        if (voiceCallsToProcess.isEmpty()) {
            System.debug('No VoiceCall records changed CallOrigin to Voicemail. Exiting handler.');
            return;
        }

        // Query all relevant queue Ids
        Map<String, Id> queueApiNameToId = new Map<String, Id>();
        for (Group g : [
            SELECT Id, DeveloperName 
            FROM Group 
            WHERE Type = 'Queue' 
            AND DeveloperName IN ('Orders','AR','AP','Returns','Complaints')
        ]) {
            queueApiNameToId.put(g.DeveloperName, g.Id);
        }
        System.debug('Queue API to ID map: ' + queueApiNameToId);

        // Map IVR selection values to queue API names
        Map<String, String> ivrSelectionToQueueAPI = new Map<String, String>{
            'orderdelivery' => 'Orders',
            'productavailability' => 'Orders',
            'accountsreceivable' => 'AR',
            'accountspayable' => 'AP',
            'returns' => 'Returns',
            'qualityandregulatory' => 'Complaints'
        };

        List<Case> casesToCreate = new List<Case>();
        Map<Id, Id> voiceCallToCaseMap = new Map<Id, Id>();

        for (VoiceCall vcNew : voiceCallsToProcess) {
            Id ownerId;

            if (vcNew.IVR_Selection__c != null 
                && ivrSelectionToQueueAPI.containsKey(vcNew.IVR_Selection__c.toLowerCase())
                && queueApiNameToId.containsKey(ivrSelectionToQueueAPI.get(vcNew.IVR_Selection__c.toLowerCase()))) {
                
                String queueAPI = ivrSelectionToQueueAPI.get(vcNew.IVR_Selection__c.toLowerCase());
                ownerId = queueApiNameToId.get(queueAPI);
                System.debug('Matched IVR Selection: ' + vcNew.IVR_Selection__c + ' to Queue: ' + queueAPI + ' with Id: ' + ownerId);
            } else {
                ownerId = vcNew.OwnerId;
                System.debug('No IVR Selection match for ' + vcNew.IVR_Selection__c + ', using VoiceCall OwnerId: ' + ownerId);
            }

            Case newCase = new Case(
                Subject = 'Voicemail',
                Origin = 'Phone',
                ContactId = vcNew.Contact__c,
                OwnerId = ownerId,
                Status = 'New'
            );
            casesToCreate.add(newCase);
            voiceCallToCaseMap.put(vcNew.Id, null);
        }

        if (!casesToCreate.isEmpty()) {
            System.debug('Inserting Cases: ' + casesToCreate);
            insert casesToCreate;

            Integer i = 0;
            for (Id vcId : voiceCallToCaseMap.keySet()) {
                voiceCallToCaseMap.put(vcId, casesToCreate[i].Id);
                i++;
            }
            System.debug('VoiceCall to Case map after insert: ' + voiceCallToCaseMap);

            List<VoiceCall> voiceCallsToUpdate = new List<VoiceCall>();
            for (VoiceCall vcNew : voiceCallsToProcess) {
                if (voiceCallToCaseMap.containsKey(vcNew.Id)) {
                    VoiceCall vcToUpdate = new VoiceCall(
                        Id = vcNew.Id,
                        Case__c = voiceCallToCaseMap.get(vcNew.Id),
                        RelatedRecordId = voiceCallToCaseMap.get(vcNew.Id)
                    );
                    voiceCallsToUpdate.add(vcToUpdate);
                }
            }

            if (!voiceCallsToUpdate.isEmpty()) {
                System.debug('Updating VoiceCalls: ' + voiceCallsToUpdate);
                update voiceCallsToUpdate;
            }
        }
    }
}