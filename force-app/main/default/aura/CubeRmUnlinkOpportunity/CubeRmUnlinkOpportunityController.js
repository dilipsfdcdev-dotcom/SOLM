({
    doInit: function (component, _event, helper) {
        try {
            let appEvent = $A.get("e.cuberm_tc:RefreshEvent");
            appEvent.setParam('type', 'TenderLotsChecked');
            appEvent.fire();
            let lotsArray = appEvent.getParam('tenderLotsFiltered');
            helper.unlinkInit(component, lotsArray);
        } catch (err) {
            helper.showErrorUnlink(component, err.message);
        }

    },

    confirmUnlink: function (component, _event, helper) {
        try {
            component.find('unlinkButtonId').set('v.disabled', true);
            component.set('v.showUnlinkSpinner', true);
            let lotIds = component.get('v.linkedLotIds');
            helper.unlinkConfirm(component, lotIds);
        } catch (err) {
            helper.showErrorUnlink(component, err.message);
        }
    },

    closeQuickActionUnlink: function (component, _event, helper) {
        try {
            $A.get('e.force:closeQuickAction').fire();
        } catch (err) {
            helper.showErrorUnlink(component, err.message);
        }
    }
})