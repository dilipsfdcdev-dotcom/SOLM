public with sharing class QuoteLineItemTriggerHandler {
	private static List<QuoteLineItem> filterQlisForQliHistorySnapshot (Map<Id, QuoteLineItem> oldQlisById, Map<Id, QuoteLineItem> newQlisById) {
		List<QuoteLineItem> filteredQlis = new List<QuoteLineItem>();
		for(QuoteLineItem oldQli : oldQlisById.values()) {
			QuoteLineItem newQli = newQlisById.get(oldQli.Id);
			if(oldQli.UnitPrice != newQli.UnitPrice
				|| oldQli.TotalPrice != newQli.TotalPrice
				|| oldQli.Quantity != newQli.Quantity) {
				filteredQlis.add(oldQli);
			}
		}
		return filteredQlis;
	}

	public static void createQlisHistory (Map<Id, QuoteLineItem> oldQlisById, Map<Id, QuoteLineItem> newQlisById) {
		List<QuoteLineItem> filteredQlis = filterQlisForQliHistorySnapshot(oldQlisById, newQlisById);
		List<Quote_Line_Item_History__c> qlisHistory = new List<Quote_Line_Item_History__c>();

		for(QuoteLineItem qli : filteredQlis) {
			qlisHistory.add(
				new Quote_Line_Item_History__c(
					Quote__c = qli.QuoteId,
					Quote_Line_Item__c = qli.Id,
					Sales_Price__c = qli.UnitPrice,
					Quantity__c = qli.Quantity,
					Total_Price__c = qli.TotalPrice
				)
			);
		}
		insert qlisHistory;
	}
}