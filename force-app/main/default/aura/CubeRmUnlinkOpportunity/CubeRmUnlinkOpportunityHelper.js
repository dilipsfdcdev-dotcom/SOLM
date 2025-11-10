({
    unlinkInit: function (component, lotsArray) {
        try {
            let warnings = [];
            if (!lotsArray) {
                warnings.push('Please select Lot(s) to unlink from Opportunity.');
                component.set('v.warnings', warnings);
                component.set('v.showUnlinkSpinner', false);
                return;
            }
            let checkedLinkedLots = lotsArray.filter(obj => {
                return obj['cuberm_tc__IsImported__c'] === true && obj['Checked'] === true;
            });
            if (checkedLinkedLots.length === 0) {
                warnings.push('Please select Linked Lot(s) to unlink from Opportunity.');
                component.set('v.warnings', warnings);
            } else {
                let linkedLotIds = checkedLinkedLots.map((obj) => {
                    return obj['Id'];
                });
                component.set('v.linkedLotIds', linkedLotIds);
                component.set('v.unlinkText', 'Are you sure you want to unlink the selected Lot(s)?');
                component.find('unlinkButtonId').set('v.disabled', false);
            }
            component.set('v.showUnlinkSpinner', false);
        } catch (err) {
            this.showErrorUnlink(component, err.message);
        }
    },

    unlinkConfirm: function (component, lotIds) {
        try {
            let action = component.get('c.unlinkLotsFromOpportunity');
            action.setParams({'lotIds': lotIds, 'tenderId': component.get('v.recordId')});
            action.setCallback(this, function (response) {
                let state = response.getState();
                let toastEvent = $A.get('e.force:showToast');
                if (state === 'SUCCESS') {
                    $A.get('e.force:refreshView').fire();
                    toastEvent.setParams({
                        type: 'success',
                        title: 'Success!',
                        message: 'Lot(s) unlinked from Opportunity successfully.'
                    });
                    toastEvent.fire();
                    $A.get('e.force:closeQuickAction').fire();
                } else if (state === 'ERROR') {
                    console.error(response.getError()[0].message);
                    toastEvent.setParams({
                        type: 'error',
                        title: 'Error!',
                        message: response.getError()[0].message
                    });
                    toastEvent.fire();
                } else {
                    console.log('Callback Returned with state: ' + state);
                    toastEvent.setParams({
                        type: 'error',
                        title: 'Error!',
                        message: 'Callback Returned with state: ' + state
                    });
                    toastEvent.fire();
                }
            });
            $A.enqueueAction(action);
        } catch (err) {
            this.showErrorUnlink(component, err.message);
        }
    },

    showErrorUnlink: function (_component, errorMessage) {
        console.error(errorMessage);
        let toastEvent = $A.get('e.force:showToast');
        toastEvent.setParams({
            type: 'error',
            title: 'Error!',
            message: errorMessage
        });
        toastEvent.fire();
    }
})