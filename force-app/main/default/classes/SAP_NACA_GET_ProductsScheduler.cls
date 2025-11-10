public class SAP_NACA_GET_ProductsScheduler implements Schedulable, Database.AllowsCallouts{
    Map <String, String> requestParamsMap;

    public void execute(SchedulableContext SC){ 
        sync();
    }

    @future(callout=true)
    public static void sync(){
        Map <String, String>  requestParamsMap = new Map<String,string>{
            'date' => Datetime.now().addMinutes(-10).format('yyyy-MM-dd\'T\'HH:mm:ss', 'America/Chicago')
        };

        new SAP_GET_PriceBooks('NACA', requestParamsMap).sync();
        System.enqueueJob(new ProductJob(requestParamsMap));
    }

    public class ProductJob implements Queueable, Database.AllowsCallouts {
        Map <String, String> requestParamsMap;

        public ProductJob(Map <String, String> paramsMap) {
            this.requestParamsMap = paramsMap;
        }

        public void execute(QueueableContext context) {
            new SAP_GET_Products('NACA', requestParamsMap).sync();
            System.enqueueJob(new PriceBookEntryJob(requestParamsMap));
        }
    }

    public class PriceBookEntryJob implements Queueable, Database.AllowsCallouts {
        Map <String, String> requestParamsMap;

        public PriceBookEntryJob(Map <String, String> paramsMap) {
            this.requestParamsMap = paramsMap;
        }

        public void execute(QueueableContext context) {
            new SAP_GET_PriceBookEntries('NACA', requestParamsMap).sync();
        }
    }
}

/*
Run every 10 minutes
System.schedule('SAP_NACA_GET_ProductsScheduler 1', '0 0 * * * ?', new SAP_NACA_GET_ProductsScheduler());
System.schedule('SAP_NACA_GET_ProductsScheduler 2', '0 10 * * * ?', new SAP_NACA_GET_ProductsScheduler());
System.schedule('SAP_NACA_GET_ProductsScheduler 3', '0 20 * * * ?', new SAP_NACA_GET_ProductsScheduler());
System.schedule('SAP_NACA_GET_ProductsScheduler 4', '0 30 * * * ?', new SAP_NACA_GET_ProductsScheduler());
System.schedule('SAP_NACA_GET_ProductsScheduler 5', '0 40 * * * ?', new SAP_NACA_GET_ProductsScheduler());
System.schedule('SAP_NACA_GET_ProductsScheduler 6', '0 50 * * * ?', new SAP_NACA_GET_ProductsScheduler());
*/