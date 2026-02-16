trigger QuoteTrigger on Quote (After update) {
 if (Trigger.isAfter && Trigger.isUpdate) {
        QuoteDiscountTaskHandler.handlePresentedQuotes(
            Trigger.new,
            Trigger.oldMap
        );
    }
}