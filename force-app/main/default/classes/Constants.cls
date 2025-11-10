public class Constants {

	/* Account */
	public static Approvals approval {
		get {
			if (approval == null) {
				approval = new Approvals();
			}
			return approval;
		}
		set;
	}

	public class Approvals {
		public final String APPROVED = 'Approved';
		public final String REJECTED = 'Rejected';
		public final String PENDING = 'Pending';
	}

    /* Account */
	public static Accounts account {
		get {
			if (account == null) {
				account = new Accounts();
			}
			return account;
		}
		set;
	}

    public class Accounts {
        public final String RECORD_TYPE_NACA = 'Account_NACA';
        public final String RECORD_TYPE_NACA_ID = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(RECORD_TYPE_NACA).getRecordTypeId();
		public final String RECORD_TYPE_EMEA = 'Account_EMEA';
		public final String RECORD_TYPE_EMEA_ID = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(RECORD_TYPE_EMEA).getRecordTypeId();

		public final String CUSTOMER_STATUS_CUSTOMER = 'Customer';

		public final String BRANCH_EMEA = 'PL00';
		public final String BRANCH_NACA = 'US00';
    }

	public static Cases caseConstants {
		get {
			if (caseConstants == null) {
				caseConstants = new Cases();
			}
			return caseConstants;
		}
		set;
	}

	public class Cases {
		public final String ORIGIN_EMAIL = 'Email';
		public final String ORIGIN_PHONE = 'Phone';
		public final String ORIGIN_WEB = 'Web';

		public final String STATUS_NEW = 'New';

		public final String PRIORITY_MEDIUM_RETURNS = 'Medium - Returns';

		public final String TYPE_ORDER_PLACEMENT = 'Order placement';
	}

	public static ForecastItems forecastItem {
		get {
			if (forecastItem == null) {
				forecastItem = new ForecastItems();
			}
			return forecastItem;
		}
		set;
	}

	public class ForecastItems {
		public final String ITEM_TYPE_CURRENT_ORDER = 'Current Order';
		public final String ITEM_TYPE_PREVIOUS_YEAR_ORDER = 'Previous Year Order';
		public final String ITEM_TYPE_ADJUSTMENT = 'Adjustment';
		public final String ITEM_TYPE_BASE = 'Base';
		public final String ITEM_TYPE_OPP_PRODUCT = 'Opportunity Product';

		public final String FULFILLMENT_DIRECT = 'Direct Shipment';
		public final String FULFILLMENT_LOCAL = 'Local Warehouse';

		public final String WAREHOUSE_DIRECT_CODE = '201';
	}

	/* Lead */
	public static Leads lead {
		get {
			if (lead == null) {
				lead = new Leads();
			}
			return lead;
		}
		set;
	}

	public class Leads {
		public final String RECORD_TYPE_NACA = 'Lead_NACA';
        public final String RECORD_TYPE_NACA_ID = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get(RECORD_TYPE_NACA).getRecordTypeId();
		public final String SOURCE_SOL_M_WEBPAGE = 'sol-m.com';
	}

    /* Opportunity */
	public static Opportunities opportunity {
		get {
			if (opportunity == null) {
				opportunity = new Opportunities();
			}
			return opportunity;
		}
		set;
	}

    public class Opportunities {
		public final String STAGE_CLOSED_LOST = 'Closed Lost';
		public final String STAGE_CLOSED_WON = 'Closed Won';
		public final String STAGE_DISQUALIFIED = 'Disqualified';
        public final String STAGE_PROSPECTING = 'Prospecting';
        public final String STAGE_NEGOTIATION = 'Sampling & Negotiation';
		public final String STAGE_FORECASTING = 'Forecasting';
		public final String STAGE_ANALYZING = 'Analyzing';

		public final String RECORD_TYPE_NACA = 'Opportunity_NACA';
		public final String RECORD_TYPE_NACA_ID = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get(RECORD_TYPE_NACA).getRecordTypeId();
		public final String RECORD_TYPE_EMEA = 'Opportunity_EMEA';
		public final String RECORD_TYPE_EMEA_ID = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get(RECORD_TYPE_EMEA).getRecordTypeId();
		public final String RECORD_TYPE_EMEA_TENDER = 'Opportunity_Tender_EMEA';
		public final String RECORD_TYPE_EMEA_TENDER_ID = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get(RECORD_TYPE_EMEA_TENDER).getRecordTypeId();
		public final String RECORD_TYPE_EMEA_TENDER_LOT = 'Opportunity_EMEA_LOT';
		public final String RECORD_TYPE_EMEA_TENDER_LOT_ID = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get(RECORD_TYPE_EMEA_TENDER_LOT).getRecordTypeId();
	}

    /* Orders */
	public static Orders order {
		get {
			if (order == null) {
				order = new Orders();
			}
			return order;
		}
		set;
	}

    public class Orders{
		public final String STATUS_OPEN = 'Open';
        public final String STATUS_CLOSED = 'Closed';
        public final String STATUS_CANCELED = 'Canceled';

        public final String RECORD_TYPE_NACA= 'Order_NACA';
        public final String RECORD_TYPE_NACA_ID = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get(RECORD_TYPE_NACA).getRecordTypeId();

		public final String RECORD_TYPE_EMEA= 'Order_EMEA';
		public final String RECORD_TYPE_EMEA_ID = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get(RECORD_TYPE_EMEA).getRecordTypeId();

        public final String TYPE_CRM = 'CRM';
		public final String TYPE_SAP = 'SAP';

		public final String NACA_SAP_PREFIX = 'NACA-';
		public final String EMEA_SAP_PREFIX = 'SMPL-';
	}

	/* Price Book Entry*/
	public static PricebookEntries pricebookEntry {
		get {
			if (pricebookEntry == null) {
				pricebookEntry = new PricebookEntries();
			}
			return pricebookEntry;
		}
		set;
	}

	public class PricebookEntries {
		public final Set <String> CURRENCIES = new Set <String> {'USD', 'PLN', 'EUR', 'GBP', 'CAD'};
	}

	/* Price Book */
	public static PriceBooks priceBook {
		get {
			if (priceBook == null) {
				priceBook = new PriceBooks();
			}
			return priceBook;
		}
		set;
	}

	public class PriceBooks {
		public final Id STANDARD_PRICEBOOK_ID = Test.isRunningTest() ? Test.getStandardPricebookId() : [SELECT Id FROM Pricebook2 WHERE IsStandard = TRUE LIMIT 1].Id;

		public final String RECORD_TYPE_NACA = 'Price_Book_NACA';
		public final String RECORD_TYPE_NACA_ID = Schema.SObjectType.Pricebook2.getRecordTypeInfosByDeveloperName().get(RECORD_TYPE_NACA).getRecordTypeId();

		public final String RECORD_TYPE_EMEA = 'Price_Book_EMEA';
		public final String RECORD_TYPE_EMEA_ID = Schema.SObjectType.Pricebook2.getRecordTypeInfosByDeveloperName().get(RECORD_TYPE_EMEA).getRecordTypeId();
		
	}

    /* Quote */
	public static Quotes quote {
		get {
			if (quote == null) {
				quote = new Quotes();
			}
			return quote;
		}
		set;
	}

    public class Quotes {
        public final String RECORD_TYPE_NACA= 'Quote_NACA';
        public final String RECORD_TYPE_NACA_ID = Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get(RECORD_TYPE_NACA).getRecordTypeId();

		public final String RECORD_TYPE_EMEA= 'Quote_EMEA';
		public final String RECORD_TYPE_EMEA_ID = Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get(RECORD_TYPE_EMEA).getRecordTypeId();

		public final Map<String, String> recordTypeIdByOpportunityRTId = new Map<String, String> {
				Constants.opportunity.RECORD_TYPE_NACA_ID => RECORD_TYPE_NACA_ID,
				Constants.opportunity.RECORD_TYPE_EMEA_ID => RECORD_TYPE_EMEA_ID,
				Constants.opportunity.RECORD_TYPE_EMEA_TENDER_ID => RECORD_TYPE_EMEA_ID
		};
    }

	public static Tasks task {
		get {
			if (task == null) {
				task = new Tasks();
			}
			return task;
		}
		set;
	}

	public class Tasks {
		public final String STATUS_OPEN = 'Open';
		public final String STATUS_COMPLETED = 'Completed';

		public final String CUSTOM_NOTIFICATION_TYPE_NAME = 'Task_notification';
	}
}