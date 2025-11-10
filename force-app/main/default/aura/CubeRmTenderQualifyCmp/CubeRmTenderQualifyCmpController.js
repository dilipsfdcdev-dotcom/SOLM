({
    handleLoad : function(component, event, helper) {
        try{
            $A.enqueueAction(component.get('c.handleSubmissionDeadline'));
            component.set('v.showQualifySpinner', false);
        }catch(err){
            console.error(err.message);
        }
    },
    
    handleSubmissionDeadline: function(component, event, helper) {
        try{
            if (component.find('SubmissionDeadlineId').get('v.value')){
                let reminderDate = new Date(component.find('SubmissionDeadlineId').get('v.value'));
                reminderDate.setDate(reminderDate.getDate()  - 5);
                reminderDate = $A.localizationService.formatDate(new Date(reminderDate), 'YYYY-MM-DD');
                component.set('v.reminderDate', reminderDate);
            }
        }catch(err){
            console.error(err.message);
        }
    },
 
	closeQuickAction : function(component, event, helper) {
        try {
            $A.get('e.cuberm_tc:RefreshEvent').setParam('type', 'QualifyClose').fire();
        } catch (err) {
            console.error(err.message);
        }
    },
    submitData : function(component, event, helper) {
        try {
            let jObj = {};
            if (component.find('AccountId').get('v.value')) {
                jObj['MainAccount__c'] = component.find('AccountId').get('v.value');
            }
            if (component.find('DocumentationCompletionDateId').get('v.value')) {
                jObj['DocumentationCompletionDate__c'] = component.find('DocumentationCompletionDateId').get('v.value');
            }
            if (component.find('SalesRepId').get('v.value')) {
                jObj['SalesRep__c'] = component.find('SalesRepId').get('v.value');
            }
            if (component.find('DocumentationCompletionDateReminderId').get('v.value')) {
                jObj['DocumentationCompletionDateReminder__c'] = component.find('DocumentationCompletionDateReminderId').get('v.value');
            }
            if (component.find('PricebookId').get('v.value')) {
                jObj['PriceBook__c'] = component.find('PricebookId').get('v.value');
            }
            if (component.find('QuestionsDeadlineId').get('v.value')) {
                jObj['QuestionsDeadline__c'] = component.find('QuestionsDeadlineId').get('v.value');
            }
            if (component.find('QuestionsDeadlineReminderId').get('v.value')) {
                jObj['QuestionsDeadlineReminder__c'] = component.find('QuestionsDeadlineReminderId').get('v.value');
            }
            if (component.find('SamplesNeededCheckboxId').get('v.value')) {
                jObj['SamplesNeeded__c'] = component.find('SamplesNeededCheckboxId').get('v.value');
            }
            if (component.find('SamplesDeliveryDateDeadlineId').get('v.value')) {
                jObj['SamplesDeliveryDeadline__c'] = component.find('SamplesDeliveryDateDeadlineId').get('v.value');
            }
            if (component.find('SamplesDeliveryDeadlineReminderId').get('v.value')) {
                jObj['SamplesDeliveryDeadline_Reminder__c'] = component.find('SamplesDeliveryDeadlineReminderId').get('v.value');
            }
            if (component.find('SubmissionDeadlineId').get('v.value')) {
                jObj['SubmissionDeadline__c'] = component.find('SubmissionDeadlineId').get('v.value');
            }
            if (component.find('SubmissionDeadlineReminderId').get('v.value')) {
                jObj['SubmissionDeadlineReminder__c'] = component.find('SubmissionDeadlineReminderId').get('v.value');
            }
            let serObj = JSON.stringify(jObj);
            let appEvent = $A.get('e.cuberm_tc:RefreshEvent');
            appEvent.setParams({
                type : 'QualifySubmit',
                json : serObj !='{}' ? serObj : ''
            });
            appEvent.fire();
        } catch (err) {
            console.error(err.message);
        }
    }
})