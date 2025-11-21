public with sharing class Util {
	public static Object getFieldValue(SObject sobj, String fieldName) {
		while (fieldName.contains('.') && sobj != null) {
			sobj = sobj.getSObject(fieldName.substringBefore('.'));
			fieldName = fieldName.substringAfter('.');
		}
		return sobj?.get(fieldName);
	}

	public static Boolean isFieldChanged(SObject old, SObject current, String fieldName) {
		return (old == null && getFieldValue(current, fieldName) != null)
				|| getFieldValue(old, fieldName) != getFieldValue(current, fieldName);
	}

	public static Boolean isFieldChanged(SObject old, SObject current, SObjectField fieldName) {
		return isFieldChanged(old, current, String.valueOf(fieldName));
	}
}