public with sharing class SetForecastScheduleWrapper {
	@AuraEnabled
	public Id scheduleId { get; set; }
	@AuraEnabled
	public Decimal quantity { get; set; }
	@AuraEnabled
	public Date scheduleDate { get; set; }
}