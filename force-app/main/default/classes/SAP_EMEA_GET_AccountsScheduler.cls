global class SAP_EMEA_GET_AccountsScheduler implements Schedulable, Database.AllowsCallouts{
    global void execute(SchedulableContext SC){ 
        sync();
    }

    @future(callout=true)
    public static void sync(){
        Map <String, String>  requestParamsMap = new Map<String,string>{
            'date' => Datetime.now().addMinutes(-10).format('yyyy-MM-dd\'T\'HH:mm:ss', 'Europe/London')
        };

        new SAP_GET_Accounts('EMEA', requestParamsMap).sync();
    }
}

/*
Run every 10 minutes

System.schedule('SAP_EMEA_GET_Accounts 1', '0 5 * * * ?', new SAP_EMEA_GET_AccountsScheduler());
System.schedule('SAP_EMEA_GET_Accounts 2', '0 15 * * * ?', new SAP_EMEA_GET_AccountsScheduler());
System.schedule('SAP_EMEA_GET_Accounts 3', '0 25 * * * ?', new SAP_EMEA_GET_AccountsScheduler());
System.schedule('SAP_EMEA_GET_Accounts 4', '0 35 * * * ?', new SAP_EMEA_GET_AccountsScheduler());
System.schedule('SAP_EMEA_GET_Accounts 5', '0 45 * * * ?', new SAP_EMEA_GET_AccountsScheduler());
System.schedule('SAP_EMEA_GET_Accounts 6', '0 55 * * * ?', new SAP_EMEA_GET_AccountsScheduler());
*/