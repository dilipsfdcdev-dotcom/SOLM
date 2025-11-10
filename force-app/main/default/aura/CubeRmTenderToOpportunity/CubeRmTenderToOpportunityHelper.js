({
    prepareImport : function(component, lotIds) {
        component.set('v.lotIds', []);
        component.set('v.lotIds', lotIds);
        let action = component.get('c.PrepareImport');
        
        action.setParams({
            'tenderId' : component.get('v.recordId'),
            'lotIds' : lotIds
        });
        
        action.setCallback(this, function(response) {
            let state = response.getState();
            let cancelButton = component.find('cancelButtonId');
            if (state === 'SUCCESS') {
                let result = response.getReturnValue();
                if(result.Warnings.length > 0){
                    component.set('v.warnings', result.Warnings);
                }else{
                    component.set('v.lots', result.TenderLots);
                    component.set('v.accountName', result.AccountName);
                    component.set('v.oppRecordType', result.RecordTypeId);

                    if(result.AccountId) {
                        component.set('v.accountIds', [result.AccountId]);
                    } 
                    component.set('v.opptyTenderType', result.OppTenderType);
                    component.set('v.opptyType', result.OppType);
                    component.set('v.opptySubType', result.SubType);
                    component.set('v.opptyCloseDate', result.oppCloseDate);
                    let saveButton = component.find('saveButtonId');
                    saveButton.set('v.disabled',false);
                }   
            } else if (state === 'ERROR') {
                let toastEvent = $A.get('e.force:showToast');
                toastEvent.setParams({
                    type: 'error',
                    title: 'Error!',
                    message: response.getError()[0].message
                });
                toastEvent.fire();
            } else {
                console.log('Returned with state: ' + state);
            }
            component.set('v.showSpinner', false);
            cancelButton.set('v.disabled',false);
        });
        
        $A.enqueueAction(action);
    },
    
    getAccountResults : function(component) {
        component.set('v.showSpinner', true);
        let action = component.get('c.GetAccountResults');
        console.log(component.get('v.accountIds'));
        console.log(component.get('v.accountIds')[0]);
        console.log(component.get('v.recordId'));
        action.setParams({
            'accountId' : component.get('v.accountIds')[0],
            'tenderId' : component.get('v.recordId')
        });
        
        action.setCallback(this, function(response) {
            let state = response.getState();
            if (state === 'SUCCESS') {
                let result = response.getReturnValue();
                component.set('v.accountName', result.AccountName);
                let opptyResultOptions = [];
                result.Opportunities.forEach(function(oppty) {
                    opptyResultOptions.push({name: oppty.Name,
                                             value: oppty.Id,
                                             label: (oppty.Name ? oppty.Name : '') +
                                             '\nClose Date: ' + (oppty.CloseDate ? oppty.CloseDate : '' ) +
                                             '\nStage: ' + (oppty.StageName)
                                            });
                });
                component.set('v.opptyResultOptions', opptyResultOptions);
                this.updateAccountResultCount(component);
            } else if (state === 'ERROR') {
                let toastEvent = $A.get('e.force:showToast');
                toastEvent.setParams({
                    type: 'error',
                    title: 'Error!',
                    message: response.getError()[0].message
                });
                toastEvent.fire();
            } else {
                console.log('Returned with state: ' + state);   
            }
            component.set('v.showSpinner', false);
        });
        
        $A.enqueueAction(action);
    },

    saveOpportunity : function(component) {
        let cancelButton = component.find('cancelButtonId');
        let saveButton = component.find('saveButtonId');
        cancelButton.set('v.disabled',true);
        saveButton.set('v.disabled',true);
        let action = component.get('c.SaveOpportunity');
        action.setParams({
            "opptyDto": {
                TenderId: component.get("v.recordId"),
                AccountName: component.get("v.accountName"),
                AccountId: component.get("v.accountIds")[0],
                OpportunityName: component.get("v.opptyOption") === "select" ? component.find("OpptyNameSelectedId").get("v.value") : component.find("OpptyNameId").get("v.value"),
                OpportunityId: component.get("v.opptyOption") === "select" ? component.get("v.opptyId") : null,
                Stage: component.find("StageNameId").get("v.value"),
                CurrencyIsoCode: component.find("OpptyCurrencyId").get("v.value"),
                LotIds: component.get("v.lotIds"),
                URL: window.location.origin,
                OppCloseDate: component.find("CloseDateId").get("v.value"),
                OppOwnerId: component.find("OppOwnerId").get("v.value")
            }
        });

        action.setCallback(this, function(response) {
            let state = response.getState();
            let toastEvent = $A.get('e.force:showToast');
            if (state === 'SUCCESS') {
                let urlOrigin = window.location.origin;
                let result = response.getReturnValue();
                let messageTemplate = 'The Tender linked to the Opportunity {0} successfully.';
                let messageTemplateData = [{url: urlOrigin+'/lightning/r/Opportunity/'+result.OpportunityId+'/view', label: result.OpportunityLocalName}];
                if(result.QuoteId){
                    messageTemplate += ' And Quote {1}.';
                    messageTemplateData.push({url: urlOrigin+'/lightning/r/SBQQ__Quote__c/'+result.QuoteId+'/view', label: result.QuoteNumber});
                }
                toastEvent.setParams({
                    mode: 'dismissible',
                    type: 'success',
                    title: 'Success!',
                    message: 'The Tender linked to an Opportunity successfully.',
                    messageTemplate: messageTemplate,
                    messageTemplateData: messageTemplateData,
                    duration: 10000
                });
                toastEvent.fire();
            } else if (state === 'ERROR') {
                toastEvent.setParams({
                    type: 'error',
                    title: 'Error!',
                    message: response.getError()[0].message
                });
                toastEvent.fire();
            } else {
                toastEvent.setParams({
                    type: 'error',
                    title: 'Error!',
                    message: 'Callback Returned with state: ' + state
                });
                toastEvent.fire();
                console.log('Callback Returned with state: ' + state);
            }
            $A.get('e.force:closeQuickAction').fire();
            $A.get('e.force:refreshView').fire();
        });
        
        $A.enqueueAction(action);
    },
    
    updateAccountResultCount : function(component) {
        let opptyCount = component.get('v.opptyResultOptions').length;
        
        if(opptyCount) {
            let radioOptions = component.get('v.opptyOptions');
            radioOptions[1].label = 'Choose Existing (' + opptyCount + ')';
            component.set('v.opptyOptions', radioOptions);
        } else {
            let radioOptions = component.get('v.opptyOptions');
            radioOptions[1].label = 'Choose Existing';
            component.set('v.opptyOptions', radioOptions);
        }
    }
})