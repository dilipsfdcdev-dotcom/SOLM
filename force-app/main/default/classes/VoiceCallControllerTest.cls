@isTest
public class VoiceCallControllerTest {
    
    @TestSetup
    static void makeData() {
        // Create test contact
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            Email = 'test@example.com',
            Phone = '+15551234567'
        );
        insert testContact;
        
        // Create CallCenter
        CallCenter testCallCenter = [SELECT Id from CallCenter LIMIT 1];
        // Create VoiceCall records with same FromPhoneNumber
        List<VoiceCall> voiceCalls = new List<VoiceCall>{
            new VoiceCall(
                CallType = 'Inbound',
                CallStartDateTime = System.now().addMinutes(-10),
                CallEndDateTime = System.now().addMinutes(-5),
                CallDurationInSeconds = 300,
                FromPhoneNumber = '+15551234567',
                ToPhoneNumber = '+15559876543',
                Contact__c = testContact.Id,
                OwnerId = UserInfo.getUserId(),
                SourceType = 'Service',
                VendorType = 'ContactCenter',
                VendorCallKey = 'test-vendor-key-1',
                UserId = UserInfo.getUserId(),
                CallDisposition = 'Completed',
                CallCenterId = testCallCenter.Id
            ),
            new VoiceCall(
                CallType = 'Outbound',
                CallStartDateTime = System.now().addMinutes(-20),
                CallEndDateTime = System.now().addMinutes(-15),
                CallDurationInSeconds = 250,
                FromPhoneNumber = '+15551234567',
                ToPhoneNumber = '+15559876544',
                Contact__c = testContact.Id,
                OwnerId = UserInfo.getUserId(),
                SourceType = 'Service',
                VendorType = 'ContactCenter',
                VendorCallKey = 'test-vendor-key-2',
                UserId = UserInfo.getUserId(),
                CallDisposition = 'Completed',
                CallCenterId = testCallCenter.Id
            )
        };
        insert voiceCalls;
    }
    
    @isTest
    static void testGetVoiceCalls() {
        // Get test VoiceCall
        VoiceCall testCall = [SELECT Id, Name, Case__c, Contact__c, Call_Category__c, IVR_Selection__c, 
                   CallOrigin, QueueName, CallType, CallDurationInSeconds, CreatedDate, FromPhoneNumber
            FROM VoiceCall LIMIT 1];
        
        Test.startTest();
        List<VoiceCall> result = VoiceCallController.getVoiceCalls(testCall.Id);
        Test.stopTest();
        
        // Verify results
        System.assertEquals(2, result.size(), 'Should return 2 VoiceCall records');
        System.assertEquals('+15551234567', result[0].FromPhoneNumber, 'Should have matching FromPhoneNumber');
    }
    
    @isTest
    static void testGetVoiceCallsNoRecords() {
        // Create VoiceCall with unique phone number
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        CallCenter testCallCenter = [SELECT Id FROM CallCenter LIMIT 1];
        
        VoiceCall uniqueCall = new VoiceCall(
            CallType = 'Inbound',
            CallStartDateTime = System.now().addMinutes(-5),
            CallEndDateTime = System.now(),
            CallDurationInSeconds = 300,
            FromPhoneNumber = '+15559999999',
            ToPhoneNumber = '+15559876543',
            Contact__c = testContact.Id,
            OwnerId = UserInfo.getUserId(),
            SourceType = 'Service',
            VendorType = 'ContactCenter',
            VendorCallKey = 'test-vendor-key-unique',
            UserId = UserInfo.getUserId(),
            CallDisposition = 'Completed',
            CallCenterId = testCallCenter.Id
        );
        insert uniqueCall;
        
        Test.startTest();
        List<VoiceCall> result = VoiceCallController.getVoiceCalls(uniqueCall.Id);
        Test.stopTest();
        
        // Should return only the one record with unique phone number
        System.assertEquals(1, result.size(), 'Should return 1 VoiceCall record');
    }
}