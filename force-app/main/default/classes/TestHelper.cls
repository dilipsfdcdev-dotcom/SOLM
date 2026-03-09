@IsTest
public class TestHelper {

	private static String generateRandomString() {
		Integer len = 5;
		Blob blobKey = crypto.generateAesKey(128);
		String key = EncodingUtil.convertToHex(blobKey);
		return key.substring(0, len);
	}

    public class AccountRecord {
        private Account acc;

        public AccountRecord() {
            this.acc = new Account(
                Name = 'Test Account ' + TestHelper.generateRandomString()
            );
        }

        public AccountRecord setName(String accName) {
            acc.Name = accName;
            return this;
        }

        public AccountRecord asNACA() {
            acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
                .get(Constants.account.RECORD_TYPE_NACA)
                .getRecordTypeId();
            return this;
        }

		public AccountRecord asEMEA() {
			acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
					.get(Constants.account.RECORD_TYPE_EMEA)
					.getRecordTypeId();
			return this;
		}

        public AccountRecord setBillingCity(String billingCity) {
            acc.BillingCity = billingCity;
            return this;
        }

        public AccountRecord setBillingCountry(String billingCountry) {
            acc.BillingCountry = billingCountry;
            return this;
        }

        public AccountRecord setBillingPostalCode(String billingPostalCode) {
            acc.BillingPostalCode = billingPostalCode;
            return this;
        }

        public AccountRecord setBillingStreet(String billingStreet) {
            acc.BillingStreet = billingStreet;
            return this;
        }
        public AccountRecord setShippingCity(String shippingCity) {
            acc.ShippingCity = shippingCity;
            return this;
        }

        public AccountRecord setShippingCountry(String shippingCountry) {
            acc.ShippingCountry = shippingCountry;
            return this;
        }

        public AccountRecord setShippingPostalCode(String shippingPostalCode) {
            acc.ShippingPostalCode = shippingPostalCode;
            return this;
        }

        public AccountRecord setShippingStreet(String shippingStreet) {
            acc.ShippingStreet = shippingStreet;
            return this;
        }

        public AccountRecord setShippingSameAsBilling() {
            acc.ShippingCity = acc.billingCity;
            acc.ShippingCountry = acc.billingCountry;
            acc.ShippingPostalCode = acc.billingPostalCode;
            acc.ShippingStreet = acc.billingStreet;
            return this;
        }

		public AccountRecord setSAPCode(String sapCode){
			acc.SAP_Code__c = sapCode;
			return this;
		}

		public AccountRecord setForecasting(Boolean forecastEnabled){
			acc.Forecast_Enabled__c = forecastEnabled;
			return this;
		}

        public Account build() {
            return acc;
        }

        public Account save() {
            insert acc;
            return acc;
        }
    }

	public class ContactRecord {
		Contact cont;

		public ContactRecord() {
			this.cont = new Contact(
				FirstName = 'Test',
				LastName = 'Tester ' + TestHelper.generateRandomString()
			);
		}

		public ContactRecord setAccount(String accountId) {
			cont.AccountId = accountId;
			return this;
		}

		public ContactRecord setCurrencyIsoCode(String currencyValue) {
			cont.CurrencyIsoCode = currencyValue;
			return this;
		}


		public ContactRecord setEmail(String email) {
			cont.email = email;
			return this;
		}
        

		public ContactRecord setFirstName(String name) {
			cont.FirstName = name;
			return this;
		}

		public ContactRecord setLastName(String name) {
			cont.LastName = name;
			return this;
		}

		public ContactRecord setName(String firstName, String lastName) {
			cont.FirstName = firstName;
			cont.LastName = lastName == null ? cont.LastName : lastName;
			return this;
		}

		public ContactRecord setReportsToId(String reportsToId) {
			cont.ReportsToId = reportsToId;
			return this;
		}

		public Contact build() {
			return cont;
		}

		public Contact save() {
			insert cont;
			return cont;
		}
	}

	public class ForecastItemRecord {
		Forecast_Item__c forecastItem;

		public ForecastItemRecord(){
			this.forecastItem = new Forecast_Item__c(
				Quantity__c = 1000
			);
		}

		public ForecastItemRecord(String externalId, String itemType, Decimal quantity, Id forecastMonthId) {
			this.forecastItem = new Forecast_Item__c(
					External_Id__c = externalId,
					Item_Type__c = itemType,
					Quantity__c = quantity,
					Forecast__c = forecastMonthId
			);
		}

		public ForecastItemRecord setForecastMonth(String forecastMonth) {
			forecastItem.Forecast__c = forecastMonth;
			return this;
		}

		public ForecastItemRecord setForecastOpportunityId(String forecastOppId) {
			forecastItem.Forecast_Opportunity__c = forecastOppId;
			return this;
		}

		public ForecastItemRecord setForecastAdjustmentId(String adjustmentId) {
			forecastItem.Forecast_Adjustment__c = adjustmentId;
			return this;
		}

		public ForecastItemRecord setFulfillment(String fulfillment) {
			forecastItem.Fulfillment__c = fulfillment;
			return this;
		}

		public ForecastItemRecord setItemType(String itemType) {
			forecastItem.Item_Type__c = itemType;
			return this;
		}

		public ForecastItemRecord setQuantity(Decimal quantity) {
			forecastItem.Quantity__c = quantity;
			return this;
		}

		public ForecastItemRecord asLocal() {
			return setFulfillment(Constants.forecastItem.FULFILLMENT_LOCAL);
		}

		public ForecastItemRecord asDirect() {
			return setFulfillment(Constants.forecastItem.FULFILLMENT_DIRECT);
		}

		public ForecastItemRecord asBase() {
			return setItemType(Constants.forecastItem.ITEM_TYPE_BASE);
		}

		public ForecastItemRecord asAdjustment() {
			return setItemType(Constants.forecastItem.ITEM_TYPE_ADJUSTMENT);
		}

		public ForecastItemRecord asOpportunity() {
			return setItemType(Constants.forecastItem.ITEM_TYPE_OPP_PRODUCT);
		}

		public ForecastItemRecord setApproval(String approval) {
			forecastItem.BU_Approval__c = approval;
			return this;		
		}

		public Forecast_Item__c build() {
			return forecastItem;
		}

		public Forecast_Item__c save() {
			insert forecastItem;
			return forecastItem;
		}
	}

	public class ForecastAdjustmentRecord {
		Forecast_Adjustment__c forecastAdjustment;

		public ForecastAdjustmentRecord(String name) {
			this.forecastAdjustment = new Forecast_Adjustment__c(
					Name = name
			);
		}

		public ForecastAdjustmentRecord setForecastOpportunity(String oppId) {
			forecastAdjustment.Forecast_Opportunity__c = oppId;
			return this;
		}

		public Forecast_Adjustment__c build() {
			return forecastAdjustment;
		}

		public Forecast_Adjustment__c save() {
			insert forecastAdjustment;
			return forecastAdjustment;
		}
	}

	public class ForecastMonthRecord {
		Forecast_Month__c forecastMonth;

		public ForecastMonthRecord(Date month, String forecastProduct) {
			this.forecastMonth = new Forecast_Month__c(
					Month__c = month,
					Forecast_Product__c = forecastProduct
			);
		}

		public Forecast_Month__c build() {
			return forecastMonth;
		}

		public Forecast_Month__c save() {
			insert forecastMonth;
			return forecastMonth;
		}
	}

	public class ForecastProductRecord {
		Forecast_Product__c forecastProduct;

		public ForecastProductRecord(String accountId, String productId) {
			this.forecastProduct = new Forecast_Product__c(
					Account__c = accountId, 
					Product__c = productId,
					External_Id__c = ForecastUtil.getForecastProductExternalId(accountId, productId)
			);
		}

		public ForecastProductRecord setFulfillment(String fulfillment) {
			switch on fulfillment {
				when 'both' {
					this.forecastProduct.Local_Enabled__c = true;
					this.forecastProduct.Direct_Enabled__c = true;
				}
				when 'direct'{
					this.forecastProduct.Direct_Enabled__c = true;
				}
				when 'local'{
					this.forecastProduct.Local_Enabled__c = true;
				}
				when else {}
			}
			return this;
		}

		public ForecastProductRecord setWarehouse(Warehouse__c warehouse){
			this.forecastProduct.Local_Warehouse__c = warehouse.Id;
			return this;
		}

		public Forecast_Product__c build() {
			return forecastProduct;
		}

		public Forecast_Product__c save() {
			insert forecastProduct;
			return forecastProduct;
		}
	}

	public class ForecastOpportunityRecord {
		Forecast_Opportunity__c forecastOpportunity;

		public ForecastOpportunityRecord() {
			this(new OpportunityLineItemRecord().save().Id, Constants.forecastItem.FULFILLMENT_DIRECT);
		}

		public ForecastOpportunityRecord(Id oppLineItemId, String fulfillment) {
			this(oppLineItemId, ForecastUtil.getOpportunityForecastExternalId(fulfillment, oppLineItemId), fulfillment);
		}

		public ForecastOpportunityRecord(Id oppLineItemId, String externalId, String fulfillment) {
			this.forecastOpportunity = new Forecast_Opportunity__c(
					Opportunity_Product__c = oppLineItemId,
					External_Id__c = externalId,
					Fulfillment__c = fulfillment
			);
		}

		public ForecastOpportunityRecord setFulfillment(String fulfillment) {
			this.forecastOpportunity.Fulfillment__c = fulfillment;
			return this;
		}

		public ForecastOpportunityRecord setComment(String comment) {
			this.forecastOpportunity.Comment__c = comment;
			return this;
		}

		public Forecast_Opportunity__c build() {
			return forecastOpportunity;
		}

		public Forecast_Opportunity__c save() {
			insert forecastOpportunity;
			return forecastOpportunity;
		}
	}

    public class OpportunityRecord {
		public Opportunity opp;

		public OpportunityRecord() {
            this(new TestHelper.AccountRecord().save().Id);
		}

        public OpportunityRecord(Id accountId){
            opp = new Opportunity(
                AccountId = accountId,
                Name = 'Test Opportunity',
                StageName = Constants.opportunity.STAGE_PROSPECTING,
                CloseDate = System.today().addDays(6)
            );
        }

		public OpportunityRecord(String oppName, Id accountId, Id recordTypeId){
			opp = new Opportunity(
					AccountId = accountId,
					Name = oppName,
					StageName = Constants.opportunity.STAGE_PROSPECTING,
					CloseDate = System.today().addDays(6),
					RecordTypeId = recordTypeId
			);
		}

		public OpportunityRecord setAccountId(String accId) {
			opp.AccountId = accId == null ? opp.AccountId : accId;
			return this;
		}

		public OpportunityRecord setParent(Id parentOpp) {
			opp.Opportunity__c = parentOpp;
			return this;
		}

		public OpportunityRecord setName(String oppName) {
			opp.Name = oppName;
			return this;
		}

		public OpportunityRecord setPricebookId(String pricebookId) {
			opp.Pricebook2Id = pricebookId;
			return this;
		}

		public OpportunityRecord setCurrencyIsoCode(String currencyValue) {
			opp.CurrencyIsoCode = currencyValue;
			return this;
		}

		public OpportunityRecord setStage(String stage) {
			opp.StageName = stage;
			return this;
		}

		public OpportunityRecord setAmount(Decimal amount) {
			opp.Amount = amount;
			return this;
		}

		public OpportunityRecord asClosedLost(){
			opp.StageName = Constants.opportunity.STAGE_CLOSED_LOST;
			opp.Why_we_lost__c = 'Price';
			opp.NextStep = 'Test';
			return this;
		}

		public OpportunityRecord setCloseDate(Date closeDate) {
			opp.CloseDate = closeDate;
			return this;
		}

		public OpportunityRecord setPartner(String partnerId) {
			opp.Business_Partner__c = partnerId;
			return this;
		}

		public Opportunity build() {
			return opp;
		}

		public Opportunity save() {
			insert opp;
			return opp;
		}
	}

	public class PricebookRecord {
		Pricebook2 pb;

		public PricebookRecord() {
			this.pb = new Pricebook2(
				Name = 'Custom Pricebook' + Date.today(),
				Description = 'Custom Pricebook' + Date.today(),
				IsActive = true
			);
		}

		public PricebookRecord setName(String pricebookName) {
			pb.Name = pricebookName;
			return this;
		}

		public PricebookRecord setSAPCode(String sapCode) {
			pb.SAP_Code__c = sapCode;
			return this;
		}

		public Pricebook2 build() {
			return pb;
		}

		public Pricebook2 save() {
			insert pb;
			return pb;
		}
	}

	public class OpportunityLineItemRecord {
		public OpportunityLineItem oli;

		public OpportunityLineItemRecord() {
            this(
				new TestHelper.OpportunityRecord().save().Id,
                new TestHelper.PricebookEntryRecord().save().Id,
                new TestHelper.ProductRecord().save().Id
            );
		}

		public OpportunityLineItemRecord(Id oppId, Id entryId, Id productId) {
			this(oppId, entryId, productId, false);
		}

		public OpportunityLineItemRecord(Id oppId, Id entryId, Id productId, Boolean isResearch) {
			this.oli = new OpportunityLineItem(
					OpportunityId = oppId,
					UnitPrice = 10,
					Quantity = 1,
					PricebookEntryId = entryId,
					Product2Id = productId,
					Research__c = isResearch
			);
			if(isResearch) {
				this.oli.UnitPrice = 0;
			}
		}

		public OpportunityLineItemRecord setSalesPrice(Decimal salesPrice) {
			oli.UnitPrice = salesPrice;
			return this;
		}

		public OpportunityLineItemRecord setOpportunityId(Id oppId) {
			oli.OpportunityId = oppId;
			return this;
		}

		public OpportunityLineItemRecord setPricebookEntryId(Id pricebookEntryId) {
			oli.PricebookEntryId = pricebookEntryId;
			return this;
		}

		public OpportunityLineItemRecord setProductId(Id productId) {
			oli.Product2Id = productId;
			return this;
		}

        public OpportunityLineItem build() {
			return oli;
		}

		public OpportunityLineItem save() {
			insert oli;
			return oli;
		}
	}

	public class OrderItemRecord {
		public OrderItem orderItem;
		private Integer DEFAULT_ORDER_ITEM_QUANTITY = 1;
		private Double DEFAULT_UNIT_PRICE = 199;

		public OrderItemRecord() {
			this(
					new TestHelper.ProductRecord().save().Id,
					new TestHelper.OrderRecord().save().Id,
					new TestHelper.PricebookEntryRecord().save().Id
			);
		}

		public OrderItemRecord(Id productId, Id orderId, Id pricebookEntryId){
			orderItem = new OrderItem(
					Product2Id = productId,
					OrderId = orderId,
					PricebookEntryId = pricebookEntryId,
					Quantity = DEFAULT_ORDER_ITEM_QUANTITY,
					UnitPrice = DEFAULT_UNIT_PRICE
			);
		}

		public OrderItemRecord setQuantity(Integer quantity) {
			orderItem.Quantity = quantity;
			return this;
		}

		public OrderItemRecord setSAPCode(String sapCode) {
			orderItem.SAP_Code__c = sapCode;
			return this;
		}

		public OrderItemRecord setShipmentDate(Date shipmentDate) {
			orderItem.Shipment_Date__c = shipmentDate;
			return this;
		}

		public OrderItemRecord setUnitPrice(Double unitPrice) {
			orderItem.UnitPrice = unitPrice;
			return this;
		}

		public OrderItem build() {
			return orderItem;
		}

		public OrderItem save() {
			insert orderItem;
			return orderItem;
		}
	}

	public class OrderRecord {
		public Order order;

		public OrderRecord() {
			this(new TestHelper.AccountRecord().save().Id);
		}

		public OrderRecord(Id accountId){
			order = new Order(
					AccountId = accountId,
					Status = Constants.order.STATUS_OPEN,
					EffectiveDate = System.today().addDays(-6)
			);
		}

		public OrderRecord(Id accountId, Id recordTypeId){
			order = new Order(
					AccountId = accountId,
					Status = Constants.order.STATUS_OPEN,
					EffectiveDate = System.today().addDays(-6),
					RecordTypeId = recordTypeId
			);
		}

		public OrderRecord setAccountId(String accId) {
			order.AccountId = accId == null ? order.AccountId : accId;
			return this;
		}

		public OrderRecord setPricebookId(String pricebookId) {
			order.Pricebook2Id = pricebookId;
			return this;
		}

		public OrderRecord setCurrencyIsoCode(String currencyValue) {
			order.CurrencyIsoCode = currencyValue;
			return this;
		}

		public OrderRecord setSapCode(String sapCode) {
			order.SAP_Code__c = sapCode;
			return this;
		}

		public OrderRecord setStatus(String status) {
			order.Status = status;
			return this;
		}

		public Order build() {
			return order;
		}

		public Order save() {
			insert order;
			return order;
		}
	}

	public class PricebookEntryRecord {
		public PricebookEntry pbe;

		public PricebookEntryRecord() {
			this.pbe = new PricebookEntry(
				Pricebook2Id = new TestHelper.PricebookRecord().save().Id,
				Product2Id = new TestHelper.ProductRecord().save().Id,
				UnitPrice = 100.00,
				IsActive = true
			);
		}

		public PricebookEntryRecord(Id priceBookId, Id productId) {
			this.pbe = new PricebookEntry(
				Pricebook2Id = priceBookId,
				Product2Id = productId,
				UnitPrice = 100.00,
				IsActive = true,
				UseStandardPrice = false
			);
		}

		public PricebookEntryRecord(Id priceBookId, Id productId, String currencyIsoCode) {
			this(priceBookId, productId);
			this.pbe.CurrencyIsoCode = currencyIsoCode;
		}

		public PricebookEntryRecord setSAPCode(String sapCode) {
			pbe.SAP_Code__c = sapCode;
			return this;
		}

		public PricebookEntry save() {
			insert pbe;
			return pbe;
		}

		public PricebookEntry build() {
			return pbe;
		}
	}

    public class ProductRecord {
		Product2 product;

		public ProductRecord() {
			this.product = new Product2(
				Name = 'Test Product',
                IsActive = true,
				CanUseQuantitySchedule = true
			);
		}

		public ProductRecord enableQuantitySchedule() {
			product.CanUseQuantitySchedule = true;
			return this;
		}

		public ProductRecord setNACAQuantity(Integer quantity) {
			product.NACA_Active__c = true;
			product.NACA_Case_Qty__c = quantity;
			return this;
		}

		public ProductRecord setEMEAQuantity(Integer quantity) {
			product.EMEA_Active__c = true;
			product.EMEA_Case_Qty__c = quantity;
			return this;
		}

		public ProductRecord setFamily(String family) {
			product.Family = family;
			return this;
		}

		public ProductRecord setName(String productName) {
			product.Name = productName == null ? product.Name : productName;
			return this;
		}

		public ProductRecord setIsActive(Boolean isActive) {
			product.IsActive = isActive;
			return this;
		}

		public ProductRecord setProductCode(String productCode) {
			product.ProductCode = productCode;
			return this;
		}

		public ProductRecord setSAPCode(String sapCode) {
			product.SAP_Code__c = sapCode;
			return this;
		}

		public Product2 build() {
			return product;
		}

		public Product2 save() {
			insert product;
			return product;
		}
    }

	public class WarehouseRecord {
		public Warehouse__c warehouse;

		public WarehouseRecord() {
			this.warehouse = new Warehouse__c(
				Active__c = true
			);
		}

		public WarehouseRecord setRegions(String regions){
			return this;
		}

		public WarehouseRecord setCode(String code){
			warehouse.Name = code;
			return this;
		}

		public WarehouseRecord setActive(Boolean active) {
			warehouse.Active__c = active;
			return this;
		}

		public Warehouse__c save() {
			insert warehouse;
			return warehouse;
		}

		public Warehouse__c build() {
			return warehouse;
		}
	}
}