trigger VoiceCallTrigger on VoiceCall (after update) {
    if (Trigger.isAfter && Trigger.isUpdate) {
        VoiceCallHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
    }
}