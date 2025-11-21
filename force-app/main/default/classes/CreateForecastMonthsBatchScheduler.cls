global class CreateForecastMonthsBatchScheduler implements Schedulable {
	global void execute(SchedulableContext sc) {
		CreateForecastMonthsBatch forecastMonthsBatch = new CreateForecastMonthsBatch();
		database.executebatch(forecastMonthsBatch);
	}
}