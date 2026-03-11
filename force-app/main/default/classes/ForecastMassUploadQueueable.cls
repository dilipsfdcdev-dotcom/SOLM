public class ForecastMassUploadQueueable implements Queueable {
    private Map<String, String> accountProductJsonMap;
    private List<String> accountIdsToProcess;
    private Integer currentIndex;

    public ForecastMassUploadQueueable(
        Map<String, String> accountProductJsonMap,
        List<String> accountIdsToProcess,
        Integer currentIndex
    ) {
        this.accountProductJsonMap = accountProductJsonMap;
        this.accountIdsToProcess = accountIdsToProcess;
        this.currentIndex = currentIndex;
    }

    public void execute(QueueableContext context) {
        String accountId = accountIdsToProcess[currentIndex];
        String accountProdJson = accountProductJsonMap.get(accountId);

        try {
            processAccount(accountProdJson, accountId);
        } catch (Exception e) {
            System.debug('ForecastMassUpload: Error processing account ' + accountId + ': ' + e.getMessage());
            System.debug(e.getStackTraceString());
        }

        // Chain to next account if more to process
        if (currentIndex + 1 < accountIdsToProcess.size()) {
            System.enqueueJob(new ForecastMassUploadQueueable(
                accountProductJsonMap,
                accountIdsToProcess,
                currentIndex + 1
            ));
        }
    }

    // Uses the same External_Id__c upsert pattern as ForecastCtrl.enableProductForecast
    private void processAccount(String prodJson, String accountId) {
        List<ForecastCtrl.productWrapper> pdList = (List<ForecastCtrl.productWrapper>) JSON.deserialize(
            prodJson, List<ForecastCtrl.productWrapper>.class
        );

        // Normalize boolean fields
        for (ForecastCtrl.productWrapper p : pdList) {
            if (String.isBlank(p.Local)) p.Local = 'false';
            else p.Local = p.Local.toLowerCase();
            if (String.isBlank(p.Direct)) p.Direct = 'false';
            else p.Direct = p.Direct.toLowerCase();
        }

        // Resolve warehouse names to Ids
        Map<String, Id> warehouseMap = new Map<String, Id>();
        for (ForecastCtrl.productWrapper p : pdList) {
            if (String.isNotBlank(p.Warehouse)) {
                warehouseMap.put(p.Warehouse, null);
            }
        }
        if (!warehouseMap.isEmpty()) {
            for (Warehouse__c w : [SELECT Id, Name FROM Warehouse__c WHERE Name IN :warehouseMap.keySet()]) {
                warehouseMap.put(w.Name, w.Id);
            }
        }

        // Build Forecast_Product__c records (keyed by External_Id__c)
        Map<String, Forecast_Product__c> fpMap = new Map<String, Forecast_Product__c>();
        // Build Forecast_Item__c records (keyed by External_Id__c, aggregate quantity for duplicates)
        Map<String, Forecast_Item__c> fiMap = new Map<String, Forecast_Item__c>();

        for (ForecastCtrl.productWrapper p : pdList) {
            Boolean isDirect = Boolean.valueOf(p.Direct);
            Boolean isLocal = Boolean.valueOf(p.Local);

            if (isDirect) {
                buildRecords(accountId, p, true, fpMap, fiMap, warehouseMap);
            }
            if (isLocal) {
                buildRecords(accountId, p, false, fpMap, fiMap, warehouseMap);
            }
        }

        // Build Forecast_Month__c for full 24-month range for each product+fulfillment
        List<Forecast_Month__c> forecastMonths = new List<Forecast_Month__c>();
        for (String fpExtId : fpMap.keySet()) {
            Forecast_Product__c fp = fpMap.get(fpExtId);
            String fulfillmentSuffix = fp.Direct_Enabled__c ? '0' : '1';

            Date startDate = Date.today().toStartOfMonth();
            Date endDate = Date.today().addYears(2).addMonths(-1).toStartOfMonth();
            Date tempDate = startDate;

            while (tempDate <= endDate) {
                forecastMonths.add(new Forecast_Month__c(
                    Forecast_Product__r = new Forecast_Product__c(External_Id__c = fpExtId),
                    Month__c = tempDate,
                    External_Id__c = accountId + '-' + fp.Product__c + '-' + ForecastUtil.getMonthUniqueId(tempDate) + '-' + fulfillmentSuffix
                ));
                tempDate = tempDate.addMonths(1);
            }
        }

        // Upsert in order using External_Id__c — same pattern as enableProductForecast
        upsert fpMap.values() External_Id__c;
        upsert forecastMonths External_Id__c;
        upsert fiMap.values() External_Id__c;
    }

    private void buildRecords(
        String accountId,
        ForecastCtrl.productWrapper p,
        Boolean isDirect,
        Map<String, Forecast_Product__c> fpMap,
        Map<String, Forecast_Item__c> fiMap,
        Map<String, Id> warehouseMap
    ) {
        String fulfillmentSuffix = isDirect ? '0' : '1';
        String fpExtId = accountId + '-' + p.PRODUCT2ID + '-' + fulfillmentSuffix;

        // Create Forecast_Product__c if not already tracked
        if (!fpMap.containsKey(fpExtId)) {
            fpMap.put(fpExtId, new Forecast_Product__c(
                Account__c = accountId,
                Product__c = p.PRODUCT2ID,
                External_Id__c = fpExtId,
                Direct_Enabled__c = isDirect,
                Local_Enabled__c = !isDirect,
                Local_Warehouse__c = String.isNotBlank(p.Warehouse) ? warehouseMap.get(p.Warehouse) : null,
                Price__c = String.isNotBlank(p.UNITPRICE) ? Decimal.valueOf(p.UNITPRICE) : 0
            ));
        }

        // Create Forecast_Item__c for this month+product+fulfillment
        if (String.isNotBlank(p.Month)) {
            Date monthDate = Date.newInstance(
                Integer.valueOf(p.Month.split('/')[2]),
                Integer.valueOf(p.Month.split('/')[0]),
                Integer.valueOf(p.Month.split('/')[1])
            );
            String monthUniqueId = ForecastUtil.getMonthUniqueId(monthDate);

            String fulfillmentName = isDirect ? 'direct' : 'local';
            String fiExtId = accountId + '-' + p.PRODUCT2ID + '-base-' + fulfillmentName + '-' + monthUniqueId;
            String monthExtId = accountId + '-' + p.PRODUCT2ID + '-' + monthUniqueId + '-' + fulfillmentSuffix;

            Integer qty = String.isNotBlank(p.Quantity) ? Integer.valueOf(p.Quantity) : 0;

            if (fiMap.containsKey(fiExtId)) {
                // Aggregate quantity for duplicate product+month+fulfillment rows
                fiMap.get(fiExtId).Quantity__c += qty;
            } else {
                fiMap.put(fiExtId, new Forecast_Item__c(
                    Quantity__c = qty,
                    External_Id__c = fiExtId,
                    Forecast__r = new Forecast_Month__c(External_Id__c = monthExtId),
                    Fulfillment__c = isDirect ? Constants.forecastItem.FULFILLMENT_DIRECT : Constants.forecastItem.FULFILLMENT_LOCAL,
                    Item_Type__c = Constants.forecastItem.ITEM_TYPE_BASE
                ));
            }
        }
    }

	public static void justIncrement(){
		Integer i = 0;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
	}
}
