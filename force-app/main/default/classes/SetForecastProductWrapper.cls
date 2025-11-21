public with sharing class SetForecastProductWrapper {
	@AuraEnabled public Id opportunityLineItemId { get; set; }
	@AuraEnabled public Id productId { get; set; }
	@AuraEnabled public Id accountId { get; set; }
	@AuraEnabled public Id forecastOpportunityDirectId { get; set; }
	@AuraEnabled public Id forecastOpportunityLocalId { get; set; }
	@AuraEnabled public Id forecastProductId { get; set; }

	@AuraEnabled public String currencyIsoCode { get; set; }
	@AuraEnabled public String productName { get; set; }
	@AuraEnabled public String productLine { get; set; }
	@AuraEnabled public String productCode { get; set; }
	@AuraEnabled public String volume { get; set; }
	@AuraEnabled public Decimal caseQuantity { get; set; }
	@AuraEnabled public Boolean isDirectEnabled { get; set; }
	@AuraEnabled public Boolean isLocalEnabled { get; set; }
	@AuraEnabled public String directEnabled { get; set; }
	@AuraEnabled public String localEnabled { get; set; }
	@AuraEnabled public String comment { get; set; }
	@AuraEnabled public String commentDirect { get; set; }
	@AuraEnabled public String commentLocal { get; set; }
	@AuraEnabled public String fulfillment { get; set; }

	@AuraEnabled public List<SetForecastScheduleWrapper> scheduleWrappers { get; set; }

	public final String FULFILLMENT_DIRECT_SHIPMENT_COMBOBOX_VALUE = 'directShipment';
	public final String FULFILLMENT_LOCAL_WAREHOUSE_COMBOBOX_VALUE = 'localWarehouse';

	public final Map<String,String> FULFILLMENT_PICKLIST_BY_COMBOBOX_VALUE = new Map<String,String> {
			FULFILLMENT_DIRECT_SHIPMENT_COMBOBOX_VALUE => Constants.forecastItem.FULFILLMENT_DIRECT,
			FULFILLMENT_LOCAL_WAREHOUSE_COMBOBOX_VALUE => Constants.forecastItem.FULFILLMENT_LOCAL
	};

	public SetForecastProductWrapper buildWithoutForecastProductData(OpportunityLineItem oli, Id accountId, String quantityFieldAPINAme, String volume) {
		this.opportunityLineItemId = oli.Id;
		this.productId = oli.Product2Id;
		this.accountId = accountId;
		this.productName = oli.Product2?.Name;
		this.productLine = oli.Product2?.Product_Line__c;
		this.productCode = oli.Product2?.ProductCode;
		this.currencyIsoCode = oli.CurrencyIsoCode;
		this.caseQuantity = (Decimal) oli.Product2?.get(quantityFieldAPINAme);
		this.volume = volume;
		return this;
	}

	public SetForecastProductWrapper setFulfillmentByForecastProduct(Forecast_Product__c forecastProduct) {
		this.forecastProductId = forecastProduct.Id;
		if (forecastProduct.Local_Enabled__c) {
			this.isLocalEnabled = true;
			this.localEnabled = OpportunitySetForecastHandler.YES;
		} else {
			this.isLocalEnabled = false;
			this.localEnabled = OpportunitySetForecastHandler.NO;
		}
		if (forecastProduct.Direct_Enabled__c) {
			this.isDirectEnabled = true;
			this.directEnabled = OpportunitySetForecastHandler.YES;
		} else {
			this.isDirectEnabled = false;
			this.directEnabled = OpportunitySetForecastHandler.NO;
		}
		return this;
	}

	public SetForecastProductWrapper setForecastOpportunityData(Id forecastOppId, String comment, String fulfillment) {
		if(fulfillment == Constants.forecastItem.FULFILLMENT_DIRECT) {
			this.fulfillment = FULFILLMENT_DIRECT_SHIPMENT_COMBOBOX_VALUE;
			this.commentDirect = comment;
			this.forecastOpportunityDirectId = forecastOppId;
		} else {
			this.fulfillment = FULFILLMENT_LOCAL_WAREHOUSE_COMBOBOX_VALUE;
			this.commentLocal = comment;
			this.forecastOpportunityLocalId = forecastOppId;
		}
		return this;
	}

	public Id getForecastOpportunityIdByFulfillment() {
		if(this.fulfillment == FULFILLMENT_DIRECT_SHIPMENT_COMBOBOX_VALUE) {
			return this.forecastOpportunityDirectId;
		} else {
			return this.forecastOpportunityLocalId;
		}
	}

	public String getFulfillmentPicklistName() {
		return FULFILLMENT_PICKLIST_BY_COMBOBOX_VALUE.get(this.fulfillment);
	}
}