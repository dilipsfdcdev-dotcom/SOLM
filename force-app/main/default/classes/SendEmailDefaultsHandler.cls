global class SendEmailDefaultsHandler implements QuickAction.QuickActionDefaultsHandler {
	public final static String TEST_EMAIL_TEMPLATE_NAME = 'Test_Email_Template_Name';

	global SendEmailDefaultsHandler() {
	}

	global void onInitDefaults(QuickAction.QuickActionDefaults[] defaults) {
		QuickAction.SendEmailQuickActionDefaults sendEmailDefaults = getSendEmailDefaults(defaults);
		if (sendEmailDefaults == null) {
			return;
		}

		Case caseRecord = [SELECT Priority, Type FROM Case WHERE Id = :sendEmailDefaults.getContextId()];
		List<Email_Template_Setting__mdt> emailTemplateSettings = getEmailTemplateSettingsByCasePriorityAndType(caseRecord.Priority, caseRecord.Type);
		if(emailTemplateSettings.isEmpty()) {
			return;
		}
		String emailTemplateDeveloperName = getEmailTemplateDeveloperName(emailTemplateSettings, caseRecord.Type);
		if (sendEmailDefaults.getInReplyToId() != null) {
			return;
		}
		sendEmailDefaults.setTemplateId(getTemplateIdHelper(emailTemplateDeveloperName));
		sendEmailDefaults.setInsertTemplateBody(false);
		sendEmailDefaults.setIgnoreTemplateSubject(false);
	}

	private QuickAction.SendEmailQuickActionDefaults getSendEmailDefaults(QuickAction.QuickActionDefaults[] defaults) {
		for (Integer j = 0; j < defaults.size(); j++) {
			QuickAction.QuickActionDefaults quickActionDefault = defaults.get(j);
			if (quickActionDefault instanceof QuickAction.SendEmailQuickActionDefaults &&
					quickActionDefault.getTargetSObject().getSObjectType() == EmailMessage.sObjectType
					&& (quickActionDefault.getActionName().equals('Case.SendEmail') || quickActionDefault.getActionName().equals('Case.Email'))
					&& (quickActionDefault.getActionType().equals('SendEmail') || quickActionDefault.getActionType().equals('Email'))
			) {
				return (QuickAction.SendEmailQuickActionDefaults)defaults.get(j);
			}
		}
		return null;
	}

	private String getEmailTemplateDeveloperName(List<Email_Template_Setting__mdt> emailTemplateSettings, String caseRecordType) {
		String emailTemplateDeveloperName = emailTemplateSettings.get(0).Template_Developer_Name__c;
		for(Email_Template_Setting__mdt emailTemplateSetting : emailTemplateSettings) {
			if(emailTemplateSetting.Case_Type__c == caseRecordType) {
				emailTemplateDeveloperName = emailTemplateSetting.Template_Developer_Name__c;
			}
		}
		return emailTemplateDeveloperName;
	}

	private Id getTemplateIdHelper(String templateApiName) {
		List<EmailTemplate> templates = [SELECT Id, Name FROM EmailTemplate WHERE DeveloperName = :templateApiName];
		if(templates.isEmpty()) {
			return null;
		}
		return templates.get(0).Id;
	}

	private List<Email_Template_Setting__mdt> getEmailTemplateSettingsByCasePriorityAndType(String casePriority, String caseType) {
		if(Test.isRunningTest()) {
			return new List<Email_Template_Setting__mdt> {
					new Email_Template_Setting__mdt(
							Case_Priority__c = Constants.caseConstants.PRIORITY_MEDIUM_RETURNS,
							Template_Developer_Name__c = SendEmailDefaultsHandler.TEST_EMAIL_TEMPLATE_NAME,
							DeveloperName = 'test_setting'
					)
			};
		}

		return [
				SELECT Case_Priority__c, Case_Type__c, Template_Developer_Name__c
				FROM Email_Template_Setting__mdt
				WHERE Case_Priority__c = :casePriority
				AND (Case_Type__c = :caseType OR Case_Type__c = NULL)
		];
	}
}