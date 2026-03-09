@IsTest
public class VoiceCallHandlerTest {

    @TestSetup
    static void makeData() {
        // ---- Ensure Queues with exact DeveloperNames (OK in tests)
        Map<String, Group> existingByDev = new Map<String, Group>();
        for (Group g : [
            SELECT Id, Name, DeveloperName
            FROM Group
            WHERE Type = 'Queue'
            AND DeveloperName IN ('Orders','AR','AP','Returns','Complaints')
        ]) {
            existingByDev.put(g.DeveloperName, g);
        }

        List<Group> groupsToInsert = new List<Group>();
        for (String dn : new List<String>{'Orders','AR','AP','Returns','Complaints'}) {
            if (!existingByDev.containsKey(dn)) {
                groupsToInsert.add(new Group(
                    Name = dn + ' Queue (Test)',
                    DeveloperName = dn,
                    Type = 'Queue'
                ));
            }
        }
        if (!groupsToInsert.isEmpty()) insert groupsToInsert;

        // Refresh
        existingByDev.clear();
        for (Group g : [
            SELECT Id, Name, DeveloperName
            FROM Group
            WHERE Type = 'Queue'
            AND DeveloperName IN ('Orders','AR','AP','Returns','Complaints')
        ]) {
            existingByDev.put(g.DeveloperName, g);
        }

        // ---- Ensure QueueSobject for Case so queues can own Cases
        // ---- Ensure QueueSobject for Case so queues can own Cases
        Set<Id> queueIds = new Set<Id>();
        for (Group g : existingByDev.values()) {
            queueIds.add(g.Id);
        }

        Map<Id, QueueSobject> haveCase = new Map<Id, QueueSobject>();
        for (QueueSobject qso : [
            SELECT Id, QueueId, SobjectType
            FROM QueueSobject
            WHERE QueueId IN :queueIds AND SobjectType = 'Case'
        ]) {
            haveCase.put(qso.QueueId, qso);
        }
        List<QueueSobject> qsoToInsert = new List<QueueSobject>();
        for (Group g : existingByDev.values()) {
            if (!haveCase.containsKey(g.Id)) {
                qsoToInsert.add(new QueueSobject(QueueId = g.Id, SobjectType = 'Case'));
            }
        }
        if (!qsoToInsert.isEmpty()) insert qsoToInsert;

        // ---- Basic Contact
        insert new Contact(FirstName = 'Test', LastName = 'Contact', Email = 'test@example.com', Phone = '+15551234567');

        // ---- NOTE: Do NOT insert CallCenter or RecordType (DML not allowed on these in tests)
        // We'll just query them later and use if available.
    }

    // Helpers
    private static Id optionalCallCenterId() {
        List<CallCenter> cc = [SELECT Id FROM CallCenter LIMIT 1];
        return cc.isEmpty() ? null : cc[0].Id;
    }
    private static Contact anyContact() {
        return [SELECT Id FROM Contact LIMIT 1];
    }
    private static Map<String, Id> queueIdsByDevName() {
        Map<String, Id> m = new Map<String, Id>();
        for (Group g : [
            SELECT Id, DeveloperName FROM Group
            WHERE Type = 'Queue'
            AND DeveloperName IN ('Orders','AR','AP','Returns','Complaints')
        ]) {
            m.put(g.DeveloperName, g.Id);
        }
        return m;
    }
    private static Map<String, Id> caseRtByDevName() {
        Map<String, Id> m = new Map<String, Id>();
        for (RecordType rt : [
            SELECT Id, DeveloperName
            FROM RecordType
            WHERE SobjectType = 'Case'
        ]) {
            m.put(rt.DeveloperName, rt.Id);
        }
        return m;
    }

    // Creates an "old" VoiceCall row; only sets CallCenterId if provided
    private static VoiceCall makeOldVC(String ivr, Contact c, Id callCenterId) {
        VoiceCall vc = new VoiceCall(
            CallType = 'Inbound',
            CallStartDateTime = System.now().addMinutes(-10),
            CallEndDateTime = System.now().addMinutes(-5),
            CallDurationInSeconds = 300,
            FromPhoneNumber = '+15551234567',
            ToPhoneNumber = '+15559876543',
            Contact__c = c.Id,
            OwnerId = UserInfo.getUserId(),
            IVR_Selection__c = ivr,
            SourceType = 'Service',
            VendorType = 'ContactCenter',
            VendorCallKey = 'vk-' + String.valueOf(Math.mod(Crypto.getRandomInteger(), 1000000)),
            UserId = UserInfo.getUserId(),
            CallDisposition = 'Completed'
        );
        if (callCenterId != null) vc.CallCenterId = callCenterId;
        return vc;
    }

    @IsTest
    static void test_No_IVR_Selection_Uses_VC_Owner() {
        Contact c = anyContact();
        Id ccId = optionalCallCenterId();

        VoiceCall oldVc = makeOldVC(null, c, ccId);
        insert oldVc;

        Map<Id, VoiceCall> oldMap = new Map<Id, VoiceCall>{ oldVc.Id => oldVc };
        VoiceCall newVc = oldVc.clone(true);
        newVc.CallOrigin = 'Voicemail';

        Test.startTest();
        VoiceCallHandler.handleAfterUpdate(new List<VoiceCall>{ newVc }, oldMap);
        Test.stopTest();

        Case created = [SELECT Id, OwnerId FROM Case LIMIT 1];
        System.assertEquals(UserInfo.getUserId(), created.OwnerId, 'Fallback owner should be VoiceCall owner');
    }

    @IsTest
    static void test_No_CallOrigin_Change_No_Action() {
        Contact c = anyContact();
        Id ccId = optionalCallCenterId();

        VoiceCall oldVc = makeOldVC('returns', c, ccId);
        oldVc.CallOrigin = 'Voicemail';
        insert oldVc;

        Map<Id, VoiceCall> oldMap = new Map<Id, VoiceCall>{ oldVc.Id => oldVc };
        VoiceCall newVc = oldVc.clone(true); // CallOrigin unchanged

        Test.startTest();
        VoiceCallHandler.handleAfterUpdate(new List<VoiceCall>{ newVc }, oldMap);
        Test.stopTest();

        System.assertEquals(0, [SELECT COUNT() FROM Case], 'No case should be created if CallOrigin did not change to Voicemail');
    }

    @IsTest
    static void test_Empty_Inputs_No_Action() {
        Test.startTest();
        VoiceCallHandler.handleAfterUpdate(new List<VoiceCall>(), new Map<Id, VoiceCall>());
        Test.stopTest();

        System.assertEquals(0, [SELECT COUNT() FROM Case], 'No case should be created for empty input');
    }
}