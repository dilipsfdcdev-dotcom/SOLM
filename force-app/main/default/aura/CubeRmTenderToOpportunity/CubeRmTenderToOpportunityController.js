({
    doInit : function(component, event, helper) {
        let appEvent = $A.get("e.cuberm_tc:RefreshEvent");
        appEvent.setParam("type", "TenderLotsChecked");
        appEvent.fire();
        let lotsArray = appEvent.getParam("tenderLotsFiltered");
        if(!lotsArray){
            let toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                type: "warning",
                title: "Warning!",
                message: "Please select at least one Lot to create Opportunity."
            });
            toastEvent.fire();
            $A.get("e.force:closeQuickAction").fire();
            return;
        }
        let checkedLots =  lotsArray.filter(obj => {return obj.cuberm_tc__Status__c =="No Bid" && obj.Checked;});
        if(checkedLots.length > 0){
            let toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                type: "warning",
                title: "Warning!",
                message: "The Lot(s) "+checkedLots.map(function(obj) { return obj["cuberm_tc__Lot__c"];}).toString()+" in the filtered lot list need different status to create Opportunity."
            });
            toastEvent.fire();
            $A.get("e.force:closeQuickAction").fire();
            return;
        }
        let checkedBidLots =  lotsArray.filter(obj => {return obj.cuberm_tc__Status__c !="No Bid" && obj.Checked;});
        if(checkedBidLots.length == 0){
            let toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                type: "warning",
                title: "Warning!",
                message: "Please select at least one Lot to create Opportunity."
            });
            toastEvent.fire();
            $A.get("e.force:closeQuickAction").fire();
            return;
        }
        helper.updateAccountResultCount(component);
        component.find("StageNameId").set("v.value","Prospecting");
        component.set("v.showSpinner", false);
        helper.prepareImport(component, checkedBidLots.map(obj=>{ let rObj = {};  rObj = obj.Id; return rObj; }));
    },
    
    accountChanged : function(component, event, helper) {
        if(component.get("v.accountIds").length > 0) {
            helper.getAccountResults(component);
        } else {
            component.set("v.opptyResultOptions", []);
            helper.updateAccountResultCount(component);
        }
    },

    opptyChanged : function(component, event, helper) {
        let opptyId = component.get("v.opptyId");
        let opptyResultOptions = component.get("v.opptyResultOptions");
        if(opptyId) {
            let index = opptyResultOptions.findIndex(i => i.value === opptyId);
            component.set("v.opptyNameSelected", opptyResultOptions[index].name);
        }
    },
    
    handleConfirmDialogNo : function(component, event, helper) {
        component.set("v.showConfirmDialog", false);
    },
    
    handleConfirmDialogYes : function(component, event, helper) {
         component.set("v.showConfirmDialog", false);
         component.set("v.showSpinner", true);
         helper.saveOpportunity(component);
    },

    saveOppty : function(component, event, helper) {
        let errors = [];

        let accountId = component.find("AccountId").get("v.value");
        if(!accountId[0]) {
            errors.push("Account is required.");
        }

        if(component.get("v.opptyOption") == "create") {
            if(!component.get("v.opptyName")) {
                errors.push("Opportunity Local Name is required.");
            }
        }
        if(component.get("v.opptyOption") == "select") {
            if(!component.get("v.opptyId")) {
                errors.push("Opportunity is required.");
            }
        }
        if(component.find("CloseDateId").get("v.value") === null){
            errors.push("Close Date is required");
        }
        component.set("v.errors", errors);

        if(errors.length == 0) {
            if(component.get("v.opptyOption") == "select") {
                component.set("v.showConfirmDialog", true);
            } else {
                component.set("v.showSpinner", true);
                helper.saveOpportunity(component);
            }
        }
    },
    
    closeModal : function (component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
    }
});