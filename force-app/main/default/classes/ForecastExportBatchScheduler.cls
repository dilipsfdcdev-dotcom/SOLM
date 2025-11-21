global class ForecastExportBatchScheduler implements Schedulable {

    private ForecastExportBatch exportBatch;
    private Integer size;

    global ForecastExportBatchScheduler(ForecastExportBatch exportBatch, Integer size){
        this.exportBatch = exportBatch;
        this.size = size;
    }

	global void execute(SchedulableContext sc) {
		Database.executebatch(exportBatch, size);
	}
}