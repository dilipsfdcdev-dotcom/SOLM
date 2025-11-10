public with sharing class SAPSettingHelper {
	public static Set<String> buildSalesOwnersToSkipSet(SAP_Setting__mdt sapSetting) {
		Set<String> skipSet = new Set<String>();

		if(sapSetting == null || sapSetting.Skipped_Account_by_Ownership__c == null){
			return skipSet;
		}

		for(String temp : (sapSetting.Skipped_Account_by_Ownership__c).split(';')){
			skipSet.add(temp);
		}

		return skipSet;
	}
}