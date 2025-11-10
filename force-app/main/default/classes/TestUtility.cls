public with sharing class TestUtility {
	static Integer counter = 1;

	public static Id getFakeId(Schema.SObjectType sObjectType) {
		String index = String.valueOf(counter++);
		return (Id) (sObjectType.getDescribe().getKeyPrefix() +
				'0'.repeat(12 - index.length()) +
				index);
	}
}