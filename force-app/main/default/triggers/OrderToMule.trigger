trigger OrderToMule on Order (after insert, after update) {
    List<ListenerOrder__e> events = new List<ListenerOrder__e>();

    for (Order od : Trigger.new) {

        ListenerOrder__e event = new ListenerOrder__e();
        event.AccountId__c = od.AccountId;
        event.ExternalID1__c = od.Id;
		//event.ExternalID2__c = od.ccrz_Order_Id__c;
        event.SAP_Code__c = od.SAP_Code__c;
        event.EndDate__c = String.valueOf(od.EndDate);
        event.Description__c = od.Description;
        event.EffectiveDate__c = String.valueOf(od.EffectiveDate);
        //event.FormaDeFrete__c = od.Forma_de_frete__c;
        event.OwnerId__c = od.OwnerId;
        //event.Prazo__c = od.Prazo__c;
        //event.ShipAmount__c = String.valueOf(od.Ship_Amount__c);
        //event.Transportadora__c = od.Transportadora__c;
        //event.TransportCost__c = String.valueOf(od.Transport_Cost__c);
        event.Type__c = od.Type;
        
        events.add(event);
    }

    if (!events.isEmpty()) {
        EventBus.publish(events);
        System.debug('Order send to Mule');
    }    
}