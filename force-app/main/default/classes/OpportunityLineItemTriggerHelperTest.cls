@IsTest
private class OpportunityLineItemTriggerHelperTest {
	@IsTest
	static void preventChangingSalesPriceBySchedulesTest() {
		OpportunityLineItem oppLineItem = new TestHelper.OpportunityLineItemRecord().setSalesPrice(10).save();
		OpportunityLineItemSchedule schedule = new OpportunityLineItemSchedule(
				OpportunityLineItemId = oppLineItem.Id,
				Quantity = 5,
				ScheduleDate = System.today(),
				Type = 'Quantity'
		);
		insert schedule;

		oppLineItem = [SELECT Quantity, TotalPrice, UnitPrice FROM OpportunityLineItem WHERE Id = :oppLineItem.Id];
		System.assertEquals(5, oppLineItem.Quantity);
		System.assertEquals(10, oppLineItem.UnitPrice);
		System.assertEquals(50, oppLineItem.TotalPrice);

		Test.startTest();
		schedule.Quantity = 7;
		update schedule;

		oppLineItem = [SELECT Quantity, TotalPrice, UnitPrice FROM OpportunityLineItem WHERE Id = :oppLineItem.Id];
		System.assertEquals(7, oppLineItem.Quantity);
		System.assertEquals(10, oppLineItem.UnitPrice);
		System.assertEquals(70, oppLineItem.TotalPrice);
		Test.stopTest();
	}
}