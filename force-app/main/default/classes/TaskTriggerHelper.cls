public with sharing class TaskTriggerHelper {
	@testVisible
	private static Map<Id,Task> filterTasksForCompletedNotification(Map<Id,Task> oldTasksById, Map<Id,Task> newTasksById) {
		Map<Id,Task> filteredTasksById = new Map<Id,Task>();

		for(Task newTask : newTasksById.values()) {
			if(Util.isFieldChanged(oldTasksById?.get(newTask.Id), newTask, Task.Status)
					&& newTask.Status == Constants.task.STATUS_COMPLETED
					&& newTask.OwnerId != newTask.CreatedById) {
				filteredTasksById.put(newTask.Id, newTask);
			}
		}
		return filteredTasksById;
	}

	public static void sendNotification(Map<Id,Task> oldTasksById, Map<Id,Task> newTasksById) {
		Map<Id,Task> filteredTasksById = filterTasksForCompletedNotification(oldTasksById, newTasksById);

		CustomNotificationType notificationType = [
				SELECT Id, DeveloperName
				FROM CustomNotificationType
				WHERE DeveloperName =: Constants.task.CUSTOM_NOTIFICATION_TYPE_NAME
		];

		for(Task task : filteredTasksById.values()) {
			Messaging.CustomNotification notification = new Messaging.CustomNotification();
			notification.setTitle(Label.Task_completion_notification_title);
			notification.setBody(task.Subject + ' was completed.');
			notification.setNotificationTypeId(notificationType.Id);
			notification.setTargetId(task.Id);

			Set<String> addressee = new Set<String>();
			addressee.add(task.CreatedById);

			notification.send(addressee);
		}
	}
}