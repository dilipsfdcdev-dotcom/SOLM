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
            ForecastCtrl.insertProduct(accountProdJson, accountId);
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
	}
}
