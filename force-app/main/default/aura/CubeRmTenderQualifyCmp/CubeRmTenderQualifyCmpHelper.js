({
	addJsonProperty: function (component, fieldId, jObj) {
        if (component.find(fieldId).get('v.value')) {
            jObj[fieldId.replace('Id', '__c')] = component.find(fieldId).get('v.value');
        }
    }
})