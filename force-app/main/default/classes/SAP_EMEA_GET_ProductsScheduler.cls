public class SAP_EMEA_GET_ProductsScheduler implements Schedulable, Database.AllowsCallouts{

    map <String, String> requestParamsMap;

    public void execute(SchedulableContext SC){ 
        sync();
    }

   /* @future(callout=true)
    public static void sync(){
        Map <String, String>  requestParamsMap = new Map<String,string>{
            'date' => Datetime.now().addMinutes(-10).format('yyyy-MM-dd\'T\'HH:mm:ss', 'Europe/London')
        };

        new SAP_GET_Products('EMEA', requestParamsMap).sync();
    }*/
    
    // Added New EMEA Callouts - Deepak 08/17/23
    @future(callout=true)
    public static void sync(){
        Map <String, String>  requestParamsMap = new Map<String,string>{
            'date' => Datetime.now().addMinutes(-10).format('yyyy-MM-dd\'T\'HH:mm:ss', 'Europe/London')
        };

        new SAP_GET_PriceBooks('EMEA', requestParamsMap).sync();
        System.enqueueJob(new ProductJob(requestParamsMap));
    }

    public class ProductJob implements Queueable, Database.AllowsCallouts {
        Map <String, String> requestParamsMap;

        public ProductJob(Map <String, String> paramsMap) {
            this.requestParamsMap = paramsMap;
        }

        public void execute(QueueableContext context) {
            new SAP_GET_Products('EMEA', requestParamsMap).sync();
            if(!test.isRunningTest()){
            System.enqueueJob(new PriceBookEntryJob(requestParamsMap));
            }
        }
    }

    public class PriceBookEntryJob implements Queueable, Database.AllowsCallouts {
        Map <String, String> requestParamsMap;

        public PriceBookEntryJob(Map <String, String> paramsMap) {
            this.requestParamsMap = paramsMap;
        }

        public void execute(QueueableContext context) {
            new SAP_GET_PriceBookEntries('EMEA', requestParamsMap).sync();
        }
    }
}

/*
Run every 10 minutes
System.schedule('SAP_EMEA_GET_ProductsScheduler 1', '0 5 * * * ?', new SAP_EMEA_GET_ProductsScheduler());
System.schedule('SAP_EMEA_GET_ProductsScheduler 2', '0 15 * * * ?', new SAP_EMEA_GET_ProductsScheduler());
System.schedule('SAP_EMEA_GET_ProductsScheduler 3', '0 25 * * * ?', new SAP_EMEA_GET_ProductsScheduler());
System.schedule('SAP_EMEA_GET_ProductsScheduler 4', '0 35 * * * ?', new SAP_EMEA_GET_ProductsScheduler());
System.schedule('SAP_EMEA_GET_ProductsScheduler 5', '0 45 * * * ?', new SAP_EMEA_GET_ProductsScheduler());
System.schedule('SAP_EMEA_GET_ProductsScheduler 6', '0 55 * * * ?', new SAP_EMEA_GET_ProductsScheduler());
*/