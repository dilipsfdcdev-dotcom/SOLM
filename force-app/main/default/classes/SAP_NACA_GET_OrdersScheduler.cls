public with sharing class SAP_NACA_GET_OrdersScheduler implements Schedulable, Database.AllowsCallouts{
    public void execute(SchedulableContext SC){ 
        sync();
    }

    @future(callout=true)
    public static void sync(){
        Map <String, String>  requestParamsMap = new Map<String,string>{
            'date' => Datetime.now().addMinutes(-10).format('yyyy-MM-dd\'T\'HH:mm:ss', 'America/Chicago')
        };

        new SAP_GET_Orders('NACA', requestParamsMap).sync();
    }
}

/*
Run every 10 minutes

System.schedule('SAP_NACA_GET_Orders 1', '0 0 * * * ?', new SAP_NACA_GET_OrdersScheduler());
System.schedule('SAP_NACA_GET_Orders 2', '0 10 * * * ?', new SAP_NACA_GET_OrdersScheduler());
System.schedule('SAP_NACA_GET_Orders 3', '0 20 * * * ?', new SAP_NACA_GET_OrdersScheduler());
System.schedule('SAP_NACA_GET_Orders 4', '0 30 * * * ?', new SAP_NACA_GET_OrdersScheduler());
System.schedule('SAP_NACA_GET_Orders 5', '0 40 * * * ?', new SAP_NACA_GET_OrdersScheduler());
System.schedule('SAP_NACA_GET_Orders 6', '0 50 * * * ?', new SAP_NACA_GET_OrdersScheduler());
*/