public with sharing class UTIL_Exceptions {
    public static void throwAuraHandledException(String exceptionMsg){
		AuraHandledException ahe = new AuraHandledException(exceptionMsg);
		ahe.setMessage(exceptionMsg);
		throw ahe;
	}
}