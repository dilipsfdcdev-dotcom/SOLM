public with sharing class SAP_EMEA_GET_OrdersScheduler implements Schedulable, Database.AllowsCallouts{
    public void execute(SchedulableContext SC){ 
        sync();
    }

    @future(callout=true)
    public static void sync(){
        Map <String, String>  requestParamsMap = new Map<String,string>{
            'date' => Datetime.now().addMinutes(-10).format('yyyy-MM-dd\'T\'HH:mm:ss', 'Europe/London')
        };

        new SAP_GET_Orders('EMEA', requestParamsMap).sync();
    }
}

/*
Run every 10 minutes

System.schedule('SAP_EMEA_GET_Orders 1', '0 0 * * * ?', new SAP_EMEA_GET_OrdersScheduler());
System.schedule('SAP_EMEA_GET_Orders 2', '0 10 * * * ?', new SAP_EMEA_GET_OrdersScheduler());
System.schedule('SAP_EMEA_GET_Orders 3', '0 20 * * * ?', new SAP_EMEA_GET_OrdersScheduler());
System.schedule('SAP_EMEA_GET_Orders 4', '0 30 * * * ?', new SAP_EMEA_GET_OrdersScheduler());
System.schedule('SAP_EMEA_GET_Orders 5', '0 40 * * * ?', new SAP_EMEA_GET_OrdersScheduler());
System.schedule('SAP_EMEA_GET_Orders 6', '0 50 * * * ?', new SAP_EMEA_GET_OrdersScheduler());
*/