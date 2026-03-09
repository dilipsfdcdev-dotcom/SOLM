trigger OrderItemTrigger on OrderItem (after insert, after update, before delete) {
	TriggerHandlerDispatcher.execute(new OrderItemTriggerHandler());
}