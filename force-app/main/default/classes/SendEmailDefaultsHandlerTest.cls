@IsTest
private class SendEmailDefaultsHandlerTest {
	@TestSetup
	private static void setup() {
		EmailTemplate emailTemplate = new EmailTemplate (
				DeveloperName = SendEmailDefaultsHandler.TEST_EMAIL_TEMPLATE_NAME,
				TemplateType= 'Text',
				Name = SendEmailDefaultsHandler.TEST_EMAIL_TEMPLATE_NAME,
				FolderId = UserInfo.getUserId());
		insert emailTemplate;
	}

	@IsTest
	static void sendEmailDefaultsHandlerTest() {
		Case caseRecord = new Case(
				Status = Constants.caseConstants.STATUS_NEW,
				Origin = Constants.caseConstants.ORIGIN_EMAIL,
				Priority = Constants.caseConstants.PRIORITY_MEDIUM_RETURNS,
				Type = Constants.caseConstants.TYPE_ORDER_PLACEMENT);
		insert caseRecord;
		QuickAction.QuickActionDefaults [] defaults = new List<QuickAction.QuickActionDefaults>();
		QuickAction.SendEmailQuickActionDefaults sendEmailDefaults = Test.newSendEmailQuickActionDefaults(caseRecord.Id, null);
		defaults.add(sendEmailDefaults);
		Test.startTest();
		new SendEmailDefaultsHandler().onInitDefaults(defaults);
		Test.stopTest();
		EmailMessage emailMessage = (EmailMessage) sendEmailDefaults.getTargetSObject();
		System.assertEquals(null, emailMessage?.EmailTemplateId);
	}

	@IsTest
	static void sendEmailDefaultsHandlerInReplyTest() {
		Case caseRecord = new Case(
				Status = Constants.caseConstants.STATUS_NEW,
				Origin = Constants.caseConstants.ORIGIN_EMAIL,
				Priority = Constants.caseConstants.PRIORITY_MEDIUM_RETURNS,
				Type = Constants.caseConstants.TYPE_ORDER_PLACEMENT);
		insert caseRecord;

		Contact contact = new TestHelper.ContactRecord().save();
		QuickAction.QuickActionDefaults [] defaults = new List<QuickAction.QuickActionDefaults>();
		QuickAction.SendEmailQuickActionDefaults sendEmailDefaults = Test.newSendEmailQuickActionDefaults(caseRecord.Id, contact.Id);
		defaults.add(sendEmailDefaults);
		Test.startTest();
		SendEmailDefaultsHandler cntl = new SendEmailDefaultsHandler();
		cntl.onInitDefaults(defaults);
		Test.stopTest();
		EmailMessage emailMessage = (EmailMessage) sendEmailDefaults.getTargetSObject();
		System.assertEquals(null, emailMessage?.EmailTemplateId);
	}
}