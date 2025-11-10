global class CreateForecastMonthsBatch implements Database.Batchable<sObject> {
	global Database.QueryLocator start(Database.BatchableContext bc) {
		return Database.getQueryLocator([SELECT Id, Account__c, Product__c FROM Forecast_Product__c WHERE Account__r.Forecast_Enabled__c = TRUE]);
	}

	global void execute(Database.BatchableContext bc, List<Forecast_Product__c> scope) {
		List<Forecast_Month__c> forecastMonths = new List<Forecast_Month__c>();		
		Date month = Date.today().toStartOfMonth().addYears(1).addMonths(-1);

		for (Forecast_Product__c forecastProduct : scope) {
			forecastMonths.add(
				new Forecast_Month__c(
					External_ID__c = ForecastUtil.getForecastMonthExternalId(forecastProduct.Account__c, forecastProduct.Product__c, month),
					Month__c = month,
					Forecast_Product__c = forecastProduct.Id
				)
			);
		}

		upsert forecastMonths External_ID__c;
	}

	global void finish(Database.BatchableContext bc) {
	}
}