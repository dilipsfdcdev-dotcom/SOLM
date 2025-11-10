public with sharing class OpportunityRecurring {

    @AuraEnabled
    public static void makeOpportunityRecurring(Id recordId, Date endDate, String frequency) {
        Savepoint sp = Database.setSavepoint();
        try {
            RecurringOpportunityBuilder recurringBuilder = new RecurringOpportunityBuilder(recordId, endDate, frequency)
                .calculateRecurringDates()
                .updateParentOpportunity()
                .createChildOpportunities()
                .copyProducts();
        } catch (Exception e) {
            Database.rollback(sp);
            throw new AuraHandledException(e.getMessage());
        }
    }

    private class RecurringOpportunityBuilder {
        private Opportunity mainOpportunity;
        private Date recurringEnd;
        private String frequency;

        private Set<Date> recurringDates;
        private List<Opportunity> recurringOpportunities;

        public RecurringOpportunityBuilder(Id recordId, Date endDate, String frequency) {
            this.mainOpportunity = getMainOpportunity(recordId);
            this.recurringEnd = endDate;
            this.frequency = frequency;
        }

        private Opportunity getMainOpportunity(Id recordId){
            return [
                SELECT Id, CloseDate, RecordTypeId, Business_Partner__c, Name, StageName, AccountId,
                    CurrencyIsoCode, Probability, OwnerId,
                    (SELECT Id, Quantity, UnitPrice, PricebookEntryId FROM OpportunityLineItems)
                FROM Opportunity 
                WHERE Id = :recordId
            ];
        }
        
        public RecurringOpportunityBuilder calculateRecurringDates(){
            if(recurringEnd <= mainOpportunity.CloseDate){
                UTIL_Exceptions.throwAuraHandledException('Recurring End Date cannot be earlier or same as main Opportunity Close Date');
            }

            recurringDates = new Set<Date>();

            switch on frequency{
                when 'Weekly'{
                    getDatesForWeekly();
                }
                when 'Monthly'{
                    getDatesForMonthly();
                }
                when 'Yearly'{
                    getDatesForYearly();
                }
            }
            return this;
        }

        private void getDatesForWeekly(){
            if(mainOpportunity.CloseDate.toStartOfWeek().daysBetween(mainOpportunity.CloseDate) + mainOpportunity.CloseDate.daysBetween(recurringEnd) < 7){
                UTIL_Exceptions.throwAuraHandledException('For Weekly frequency Recurring End Date cannot be the same week as main Opportunity Close Date');
            }

            Date tempDate = mainOpportunity.CloseDate;

            while (tempDate < recurringEnd) {
                tempDate = tempDate.addDays(7);
                recurringDates.add(tempDate);
            }
        }

        private void getDatesForMonthly(){
            Integer monthsBetween = mainOpportunity.CloseDate.monthsBetween(recurringEnd);

            if(monthsBetween == 0){
                UTIL_Exceptions.throwAuraHandledException('For Monthly frequency Recurring End Date cannot be the same month as main Opportunity Close Date');
            }

            for(Integer i = 1; i <= monthsBetween; i++){
                recurringDates.add(mainOpportunity.CloseDate.addMonths(i));
            }
        }

        private void getDatesForYearly(){
            Integer yearsBetween = recurringEnd.year() - mainOpportunity.CloseDate.year();

            if(yearsBetween == 0){
                UTIL_Exceptions.throwAuraHandledException('For Yearly frequency Recurring End Date cannot be the same year as main Opportunity Close Date');
            }

            for(Integer i = 1; i <= yearsBetween; i++){
                recurringDates.add(mainOpportunity.CloseDate.addYears(i));
            }
        }


        public RecurringOpportunityBuilder updateParentOpportunity(){
            mainOpportunity.Recurring_Type__c = 'Multiply';
            update mainOpportunity;

            return this;
        }
        
        public RecurringOpportunityBuilder createChildOpportunities(){
            recurringOpportunities = new List<Opportunity>();

            Integer recurringNumber = 1;

            for(Date recurringDate: recurringDates){
                Opportunity recurringOpportunity = new Opportunity();
                recurringOpportunity = mainOpportunity.clone();
                recurringOpportunity.Name = mainOpportunity.Name + ' [' +  String.valueOf(recurringNumber) + ']';
                recurringOpportunity.Is_this_a_recurring_opportunity__c = true;
                recurringOpportunity.Sync_Products_with_main_Opportunity__c = true;
                recurringOpportunity.Opportunity__c = mainOpportunity.Id;
                recurringOpportunity.CloseDate = recurringDate;
                recurringOpportunities.add(recurringOpportunity);
                recurringNumber++;
            }

            if(recurringOpportunities.size() > 0){
                insert recurringOpportunities;
            }

            return this;
        }

        public RecurringOpportunityBuilder copyProducts(){
            List<OpportunityLineItem> lineItemsToCopy = new List<OpportunityLineItem>();

            for(Opportunity recurringOpportunity: recurringOpportunities){
                for(OpportunityLineItem lineItem: mainOpportunity.OpportunityLineItems){
                    OpportunityLineItem OLI = new OpportunityLineItem();
                    OLI.OpportunityId = recurringOpportunity.Id;
                    OLI.Quantity = lineItem.Quantity;
                    OLI.UnitPrice = lineItem.UnitPrice;
                    OLI.PricebookEntryId = lineItem.PricebookEntryId;
                    lineItemsToCopy.add(OLI);
                }
            }

            if(lineItemsToCopy.size() > 0){
                insert lineItemsToCopy;
            }

            return this;
        }
    }

    @InvocableMethod(label='Update Stage' description='Update Stage for recurring Opportunities' category='Opportunity')
    public static void updateChildStage(List<String> recordIds) {
        Map<Id,Opportunity> mainOpportunitiesMap = new Map<Id,Opportunity>(
            [SELECT Id, StageName FROM Opportunity WHERE Id IN :recordIds]
        );

        List<Opportunity> recurringOpportunities = [
            SELECT Id, Opportunity__c 
            FROM Opportunity 
            WHERE Is_this_a_recurring_opportunity__c = true
            AND Opportunity__c IN :recordIds
        ];

        for(Opportunity opp: recurringOpportunities){
            opp.StageName = mainOpportunitiesMap.get(opp.Opportunity__c).StageName;
        }

        if(recurringOpportunities.size() > 0){
            update recurringOpportunities;
        }
    }
       
}