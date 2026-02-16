public class QuoteDiscountTaskHandler {

    private static final Decimal DISCOUNT_THRESHOLD = 10;
    private static final String PRESENTED_STATUS = 'Presented';

    public static void handlePresentedQuotes(
        List<Quote> newList,
        Map<Id, Quote> oldMap
    ) {
        Set<Id> presentedQuoteIds = new Set<Id>();

        // 1. Detect status change = Presented
        for (Quote q : newList) {
            Quote oldQ = oldMap.get(q.Id);

            if (q.Status == PRESENTED_STATUS && oldQ.Status != PRESENTED_STATUS) {
                presentedQuoteIds.add(q.Id);
            }
        }

        if (presentedQuoteIds.isEmpty()) return;

        // 2. Get Quote Numbers
        Map<Id, Quote> quoteMap = new Map<Id, Quote>([
            SELECT Id, QuoteNumber
            FROM Quote
            WHERE Id IN :presentedQuoteIds
        ]);

        // 3. Get discounted Quote Lines with BU
        List<QuoteLineItem> qlis = [
            SELECT QuoteId, Product2.BU__c
            FROM QuoteLineItem
            WHERE QuoteId IN :presentedQuoteIds
            AND Discount_Custom__c > :DISCOUNT_THRESHOLD
            AND Product2.BU__c != null
        ];

        // 4. Load BU → Owner metadata
        Map<String, BU_Task_Owner__mdt> buConfigMap = new Map<String, BU_Task_Owner__mdt>();
        for (BU_Task_Owner__mdt m : [SELECT BU__c, Owner__c FROM BU_Task_Owner__mdt]) {
            buConfigMap.put(m.BU__c, m);
        }

        // 5. Resolve Owners per Quote
        Map<Id, Set<Id>> quoteToOwnerMap = new Map<Id, Set<Id>>();
        for (QuoteLineItem qli : qlis) {
            BU_Task_Owner__mdt meta = buConfigMap.get(qli.Product2.BU__c);
            if (meta == null || meta.Owner__c == null) continue;

            if (!quoteToOwnerMap.containsKey(qli.QuoteId)) {
                quoteToOwnerMap.put(qli.QuoteId, new Set<Id>());
            }
            quoteToOwnerMap.get(qli.QuoteId).add((Id) meta.Owner__c);
        }

        if (quoteToOwnerMap.isEmpty()) return;

        // 6. Existing Tasks (prevent duplicates)
        Map<String, Task> existingTasks = new Map<String, Task>();
        for (Task t : [SELECT Id, WhatId, OwnerId FROM Task WHERE WhatId IN :presentedQuoteIds]) {
            existingTasks.put(t.WhatId + '-' + t.OwnerId, t);
        }

        // 7. Create Tasks
        List<Task> tasksToInsert = new List<Task>();
        for (Id quoteId : quoteToOwnerMap.keySet()) {
            Quote q = quoteMap.get(quoteId);

            for (Id ownerId : quoteToOwnerMap.get(quoteId)) {
                String key = quoteId + '-' + ownerId;
                if (existingTasks.containsKey(key)) continue;

                Task t = new Task();
                t.WhatId = quoteId;
                t.OwnerId = ownerId;
                t.Subject = 'Quote Approval : ' + q.QuoteNumber +'for more than 10% discount';
                t.Status = 'Not Started';
                t.Priority = 'High';

                tasksToInsert.add(t);
            }
        }

        if (!tasksToInsert.isEmpty()) {
            insert tasksToInsert;
        }
    }
}