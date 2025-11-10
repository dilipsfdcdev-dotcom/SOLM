public class PicklistWrapper {
    @AuraEnabled public String value;
    @AuraEnabled public String label;
    @AuraEnabled public Boolean active;

    public PicklistWrapper(String value, String label) {
        this.active = true;
        this.value = value;
        this.label = label;
    }

    public PicklistWrapper(String value, String label, Boolean active) {
        this(value, label);
        this.active = active;
    }
}