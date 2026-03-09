@IsTest
private class TaskTriggerHelperTest {
	@IsTest
	static void sendNotificationTest() {
		Profile profile = [SELECT Id FROM Profile WHERE Name='Standard User'];
		User user = new User(
				Alias = 'stand', Email='standard_user@test.com',
				EmailEncodingKey='UTF-8', LastName='Test_last_name', LanguageLocaleKey='en_US',
				LocaleSidKey='en_US', ProfileId = profile.Id,
				TimeZoneSidKey='America/Los_Angeles', UserName='standard_test_user@testorg.com'
		);
		insert user;

		Task t = new Task(
				Subject = 'Test_task1',
				OwnerId = user.Id, CreatedById = UserInfo.getUserId(),
				Status = Constants.task.STATUS_OPEN
		);
		insert t;

		t.Status = Constants.task.STATUS_COMPLETED;
		update t;
	}

	@IsTest
	static void filterTasksForCompletedNotificationTest() {
		Id currentUserId = UserInfo.getUserId();

		Map<Id,Task> oldTasksByIds = new Map<Id,Task>();
		Map<Id,Task> newTasksByIds = new Map<Id,Task>();

		Id task1Id = TestUtility.getFakeId(Schema.Task.getSObjectType());
		oldTasksByIds.put(task1Id, new Task(
				Subject = 'Test task 1',
				OwnerId = currentUserId, CreatedById = currentUserId,
				Status = Constants.task.STATUS_OPEN
		));
		newTasksByIds.put(task1Id, new Task(
				Id = task1Id, Subject = 'Test task 1',
				OwnerId = currentUserId, CreatedById = currentUserId,
				Status = Constants.task.STATUS_COMPLETED
		));

		Id task2Id = TestUtility.getFakeId(Schema.Task.getSObjectType());
		oldTasksByIds.put(task2Id, new Task(
				Subject = 'Test task 2',
				OwnerId = currentUserId, CreatedById = null,
				Status = Constants.task.STATUS_OPEN
		));
		newTasksByIds.put(task2Id, new Task(
				Id = task2Id, Subject = 'Test task 2',
				OwnerId = currentUserId, CreatedById = null,
				Status = Constants.task.STATUS_COMPLETED
		));

		Id task3Id = TestUtility.getFakeId(Schema.Task.getSObjectType());
		oldTasksByIds.put(task3Id, new Task(
				Subject = 'Test task 3',
				OwnerId = currentUserId, CreatedById = null,
				Status = Constants.task.STATUS_COMPLETED
		));
		newTasksByIds.put(task3Id, new Task(
				Id = task3Id, Subject = 'Test task 3',
				OwnerId = currentUserId, CreatedById = null,
				Status = Constants.task.STATUS_COMPLETED
		));

		Map<Id,Task> filteredTasksById = TaskTriggerHelper.filterTasksForCompletedNotification(oldTasksByIds, newTasksByIds);

		System.assertEquals(1, filteredTasksById.values().size());
		System.assertEquals(false, filteredTasksById.containsKey(task1Id));
		System.assertEquals(true, filteredTasksById.containsKey(task2Id));
		System.assertEquals(false, filteredTasksById.containsKey(task3Id));
	}
}