public with sharing class VoiceCallController {
    @AuraEnabled(cacheable=true)
    public static List<VoiceCall> getVoiceCalls(String recordId) {
        // Get FromPhoneNumber of the current VoiceCall
        VoiceCall currentCall = [
            SELECT Id, FromPhoneNumber FROM VoiceCall WHERE Id = :recordId LIMIT 1
        ];

        // Query related VoiceCall records
        return [
            SELECT Id, Name, Case__c, Contact__c, Call_Category__c, IVR_Selection__c, 
                   CallOrigin, QueueName, CallType, CallDurationInSeconds, CreatedDate
            FROM VoiceCall
            WHERE FromPhoneNumber = :currentCall.FromPhoneNumber
            ORDER BY CreatedDate DESC
            LIMIT 100
        ];
    }
}