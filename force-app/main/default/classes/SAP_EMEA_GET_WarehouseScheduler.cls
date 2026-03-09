public with sharing class SAP_EMEA_GET_WarehouseScheduler implements Schedulable, Database.AllowsCallouts{
    public void execute(SchedulableContext SC){ 
        sync();
    }

    @future(callout=true)
    public static void sync(){
        Map <String, String>  requestParamsMap = new Map<String,string>{
            'date' => Datetime.now().addMinutes(-10).format('yyyy-MM-dd\'T\'HH:mm:ss', 'Europe/London')
        };

        new SAP_GET_ItemWarehouses('EMEA', requestParamsMap).sync();
    }
}