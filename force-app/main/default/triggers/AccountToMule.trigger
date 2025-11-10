trigger AccountToMule on Account (after insert, after update) {
    List<ListenerAccount__e> events = new List<ListenerAccount__e>();

    for (Account acc : Trigger.new) {
        
        String IntegratorId = System.Label.IntegratorId;
        System.debug('Name: ' + acc.Name);
        System.debug('IntegratorId: ' + IntegratorId + ' / LastModifyById: ' + acc.LastModifiedById);
        System.debug('SAP_integration_compliance__c: ' + acc.SAP_integration_compliance__c);
        
        if (acc.LastModifiedById != IntegratorId && acc.SAP_integration_compliance__c == true) {
            ListenerAccount__e event = new ListenerAccount__e();
        	event.Name__c = acc.Name;
        	event.ExternalID__c = acc.Id;        
        	event.Active__c = String.valueOf(acc.Active__c);
        	event.SAP_integration_compliance__c = acc.SAP_integration_compliance__c;
        	event.Customer_Status__c = acc.Customer_Status__c;
        	event.SAP_Database__c = acc.SAP_Database__c;
        	event.Entity__c = acc.Entity__c;
        	event.SAP_Code__c = acc.SAP_Code__c;
        	event.OwnerId__c = acc.OwnerId;
        	event.Type__c = acc.Type;
        	event.Invoice_Email__c = acc.Invoicing_Email__c;
        	event.Phone__c = acc.Phone;
        	event.Payment_Terms__c = acc.Payment_Terms__c;
        	event.Industry__c = acc.Industry;
        	event.Group__c = acc.Group__c;
        
        	event.BillingCountry__c = acc.BillingCountryCode;
        	event.BillingState__c = acc.BillingState;
        	event.BillingStateCode__c = acc.BillingStateCode;
        	event.BillingCity__c = acc.BillingCity;
        	event.BillingPostalCode__c = acc.BillingPostalCode;
        	event.BillingStreet__c = acc.BillingStreet;
        
        	event.ShippingCountry__c = acc.BillingCountryCode;
        	event.ShippingState__c = acc.ShippingState;
        	event.ShippingStateCode__c = acc.ShippingStateCode;
        	event.ShippingCity__c = acc.ShippingCity;
        	event.ShippingPostalCode__c = acc.ShippingPostalCode;
        	event.ShippingStreet__c = acc.ShippingStreet;

        	event.RecordTypeName__c = acc.RecordType.Name;

        	events.add(event);
        }
        
        
    }

    if (!events.isEmpty()) {
        EventBus.publish(events);
        System.debug('Account sent to Mule');
    }
}