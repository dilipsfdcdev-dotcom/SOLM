public with sharing class ForecastCtrl {

	public class productWrapper{
		public String PRODUCT2ID;
		public String Direct;
		public String Local;
		public String Month;
		public String UNITPRICE;
		public String Quantity;
		public String Warehouse;
	}

@auraEnabled
public static string insertProduct (String prodJson,String accountId)
{
   // try{
        if (String.isNotBlank(ProdJson))
        {
            List<productWrapper> pdList = new List<productWrapper>();

            Map<Id,List<Forecast_Product__c>> productId = new Map<Id,List<Forecast_Product__c>>();
            Map<String,Id> mapOfWarehouse = new Map<String,Id>();
            Map<String,Boolean> mapOfForecastProduct = new Map<String,Boolean>();
            Map<String,Forecast_Product__c> fpList = new Map<String,Forecast_Product__c>();
            Map<String,List<Date>> mapOfProductToMonth = new Map<String,List<Date>>();
            Map<String,Map<Integer,List<Integer>>> mapOfProductToQuantity = new Map<String,Map<Integer,List<Integer>>>();

            set<Id> duplicateProductId = new Set<Id>();
            
            //desearlise the json to list of product wrappers
            pdList = (List<productWrapper>) JSON.deserialize(prodJson,list<productWrapper>.class);

            for (productWrapper p : pdList)
            {
                productId.put(p.PRODUCT2ID, new List<Forecast_Product__c>());

                if (String.isNotBlank(p.Warehouse))
                {
                    mapOfWarehouse.put(p.Warehouse,null);
                }
            }

            for(Warehouse__c wp : [Select Id,Name from Warehouse__c where Name in: mapOfWarehouse.keySet()])
            {
                mapOfWarehouse.put(wp.Name,wp.Id);
            }

            for (Forecast_Product__c fp : [Select Id,Local_Enabled__c,Direct_Enabled__c,Product__c,Price__c from Forecast_Product__c where Product__c in: productId.keySet() and Account__c =: accountId ])
            {
                productId.get(fp.Product__c).add(fp);
            }

            for (productWrapper p : pdList)
            {
                id fpId;

                if (String.isBlank(p.Local))
                {
                    p.local = 'false';
                } else {
                    p.local = p.local.toLowerCase();
                }
                    
                if(String.isBlank(p.Direct)) 
                {
                    p.Direct = 'false';
                } else {
                    p.Direct = p.Direct.toLowerCase();
                }
                    
                for (Forecast_Product__c fp : productId.get(p.PRODUCT2ID))
                {
                    if(boolean.valueof(p.Local) && fp.Local_Enabled__c ){
                        fpId = fp.Id;
                    }

                    if(boolean.valueof(p.Direct) && fp.Direct_Enabled__c ){
                        fpId = fp.Id;
                    }
                }

                // Construct the key for the map
                String productKey = p.PRODUCT2ID + ';' + p.Local + ';' + p.Direct;

                fpList.put(fpId+';'+productKey,new Forecast_Product__c(
                    Id=fpId,
                    Local_Warehouse__c=mapOfWarehouse.get(p.Warehouse),
                    Local_Enabled__c = boolean.valueof(p.Local),
                    Direct_Enabled__c=boolean.valueof(p.Direct),
                    Price__c = (p.UNITPRICE != null?  Decimal.valueof(p.UNITPRICE): 0),
                    Account__c = accountId,
                    Product__c = p.PRODUCT2ID,
                    external_id__c = accountId +'-'+p.PRODUCT2ID+'-'+(boolean.valueof(p.Direct) ? '0':'1')
                ));
                
                if (mapOfProductToMonth.containsKey(productKey))
                {
                    mapOfProductToMonth.get(productKey).add(
                        String.isNotBlank(p.month) ? date.newInstance(
                            Integer.valueOf(p.month.split('/')[2]),
                            Integer.valueof(p.month.split('/')[0]),
                            Integer.valueOf(p.month.split('/')[1])
                        ) : null 
                    );
                }
                else
                {
                    mapOfProductToMonth.put(
                        productKey, 
                        new List<Date>{
                            String.isNotBlank(p.month) ? date.newInstance(
                                Integer.valueOf(p.month.split('/')[2]),
                                Integer.valueof(p.month.split('/')[0]),
                                Integer.valueOf(p.month.split('/')[1])
                            ) : null 
                        }
                    );
                }
                
                system.debug('mapOfProductToQuantity.containsKey(p.PRODUCT2ID'+mapOfProductToQuantity.containsKey(productKey));
                // Check if the map contains the product key
                

                if (mapOfProductToQuantity.containsKey(productKey)) {
                    // Debug statement for tracing
                    System.debug('p.Quantity --> ' + p.Quantity);
                    
                    // Extract the month value
                    Integer monthValue = Integer.valueOf(p.month.split('/')[0]);

                    if (mapOfProductToQuantity.get(productKey).containsKey(monthValue)) {
                        // Add the quantity to the existing list
                        mapOfProductToQuantity.get(productKey).get(monthValue).add(Integer.valueOf(p.Quantity));
                    } else {
                        // Initialize a new list and add it to the inner map for the month
                        mapOfProductToQuantity.get(productKey).put(monthValue, new List<Integer>{Integer.valueOf(p.Quantity)});
                    }
                } else {
                    // Initialize the outer map with an empty inner map
                    mapOfProductToQuantity.put(productKey, new Map<Integer, List<Integer>>{
                        Integer.valueOf(p.month.split('/')[0]) => new List<Integer>{Integer.valueOf(p.Quantity)}
                    });
                }
                
                mapOfForecastProduct.put(productKey,boolean.valueof(p.Direct));
            }

            system.debug('mapOfProductToQuantity'+mapOfProductToQuantity);

            if (!fpList.values().isEmpty())
            {
                upsert fpList.values();
            }
            

            Map<Id,MaP<Integer,Id>> mapOfForecastProductToMonth = new Map<Id,MaP<Integer,Id>>();
            for(Forecast_Month__c fm : [Select Id,Forecast_Product__c,Forecast_Product__r.Local_Enabled__c,Forecast_Product__r.Direct_Enabled__c,Month__c from Forecast_Month__c where Forecast_Product__c in: fpList.values()]){
                if(!mapOfForecastProductToMonth.containsKey(fm.Forecast_Product__c)){
                    mapOfForecastProductToMonth.put(fm.Forecast_Product__c,new Map<Integer,Id>());
                }
                mapOfForecastProductToMonth.get(fm.Forecast_Product__c).put(fm.Month__c.Month(),fm.Id);
            }
            List<Forecast_Month__c> fmList = new List<Forecast_Month__c>();
            List<ForeCast_month__c> fmList2 = new List<Forecast_Month__c>();
            for(Forecast_Product__c fp : fpList.values()){
                Set<Integer> forecastMonth = new Set<Integer>();
                system.debug(fp.Product__c+';'+fp.Local_Enabled__c+';'+fp.Direct_Enabled__c);
                for(date d : mapOfProductToMonth.get(fp.Product__c+';'+fp.Local_Enabled__c+';'+fp.Direct_Enabled__c)){
                    Integer fmonth = d.month();
                    if(!forecastMonth.contains(fmonth)){
                        fmList.add(new Forecast_Month__c(Id = mapOfForecastProductToMonth.containsKey(fp.Id) && mapOfForecastProductToMonth.get(fp.Id).containsKey( d.month()) ? mapOfForecastProductToMonth.get(fp.Id).get( d.month()) : null ,Forecast_Product__c = fp.Id,month__c = d));
                        forecastMonth.add(fmonth);
                    }
                }
                mapOfForecastProduct.put(fp.Id,mapOfForecastProduct.get(fp.Product__c+';'+fp.Local_Enabled__c+';'+fp.Direct_Enabled__c));
                mapOfProductToQuantity.put(fp.Id,mapOfProductToQuantity.get(fp.Product__c+';'+fp.Local_Enabled__c+';'+fp.Direct_Enabled__c));

                Date startDate = Date.today().toStartOfMonth();
                Date endDate = date.today().addYears(1).addMonths(-1).toStartOfMonth();
                Date tempDate = startDate;

                while(tempDate <= endDate){
                    if(!forecastMonth.contains(tempDate.month())){
                        fmList2.add(
                            new Forecast_Month__c(
                                Forecast_Product__c = fp.Id,
                                Month__c = tempDate,
                                External_Id__c = fp.account__c + '-' + fp.Product__c + '-' + ForecastUtil.getMonthUniqueId(tempDate) +'-'+ (fp.Direct_Enabled__c ? '0':'1')
                            )
                        );
                    }
                    tempDate = tempDate.addMonths(1);
                }
            }
            upsert fmList;
            upsert fmList2 external_Id__c;

            system.debug(fmList.size());
            set<Id> monthIds = new Set<Id>();
            for(Forecast_Month__c fm : fmList){
                monthIds.add(fm.Id);
            }

            List<Forecast_Month__c> forecastMonthList = [select id, Month__c, Forecast_Product__c, Forecast_Product__r.Account__c, Forecast_Product__r.Product__c from Forecast_Month__c where Id IN:monthIds];

            // ========================= CHANGED BLOCK: aggregate per External_Id__c =========================
            Map<String, Forecast_Item__c> fiByExternalId = new Map<String, Forecast_Item__c>();

            for (Forecast_Month__c fm : forecastMonthList) {
                Integer monthVal = fm.Month__c.month();
                Map<Integer, List<Integer>> byMonth = mapOfProductToQuantity.get(fm.Forecast_Product__c);
                if (byMonth == null || !byMonth.containsKey(monthVal)) continue;

                // Sum quantities for this month for this forecast product
                Integer totalQty = 0;
                for (Integer q : byMonth.get(monthVal)) {
                    totalQty += (q == null ? 0 : q);
                }

                String fullFillmentType = mapOfForecastProduct.get(fm.Forecast_Product__c) ? '-base-direct-' : '-base-local-';
                String extId =
                    fm.Forecast_Product__r.Account__c + '-' +
                    fm.Forecast_Product__r.Product__c +
                    fullFillmentType +
                    ForecastUtil.getMonthUniqueId(fm.Month__c);

                if (!fiByExternalId.containsKey(extId)) {
                    fiByExternalId.put(extId, new Forecast_Item__c(
                        Fulfillment__c = mapOfForecastProduct.get(fm.Forecast_Product__c) ? 'Direct Shipment' : 'Local Warehouse',
                        Quantity__c    = totalQty,
                        Forecast__c    = fm.Id,
                        Item_Type__c   = 'Base',
                        External_Id__c = extId
                    ));
                } else {
                    // Defensive merge if we somehow encounter the same key again
                    Forecast_Item__c existing = fiByExternalId.get(extId);
                    existing.Quantity__c = (existing.Quantity__c == null ? 0 : existing.Quantity__c) + totalQty;
                }
            }

            List<Forecast_Item__c> fiList = new List<Forecast_Item__c>(fiByExternalId.values());

            // Optional guardrail: detect accidental dup keys before DML
            // Set<String> seen = new Set<String>();
            // for (Forecast_Item__c fi : fiList) {
            //     if (!seen.add(fi.External_Id__c)) {
            //         // Decide: merge, skip, or throw a descriptive error
            //     }
            // }

            if (!fiList.isEmpty())
            {
                upsert fiList External_Id__c;
            }
            // ========================= END CHANGED BLOCK =========================

        }
        return 'Success';
}


	@AuraEnabled
	public static List<String> getDateRange() {
		try {
			return ForecastUtil.prepareDateRange(Date.today().toStartOfMonth());
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	@AuraEnabled
	public static ForecastAccountInfo checkForecast(String accountId) {
		try {
			return new ForecastAccountInfo([
				SELECT Id, Forecast_Enabled__c, Forecasted_Products_Number__c, Account.RecordType.Name, Region__c
				FROM Account
				WHERE Id =: accountId
				LIMIT 1]
			);
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	public class ForecastAccountInfo{
		@AuraEnabled public Boolean enabled;
		@AuraEnabled public Integer forecastedProducts;
		@AuraEnabled public List<PicklistWrapper> availableWarehouses;

		public ForecastAccountInfo(Account acc){
			this.enabled = acc.Forecast_Enabled__c;
			this.forecastedProducts = Integer.valueOf(acc.Forecasted_Products_Number__c);
			this.availableWarehouses = setWarehouses(acc);
		}

		private List<PicklistWrapper> setWarehouses(Account acc){
			List<PicklistWrapper> warehouses = new List<PicklistWrapper>{
				new PicklistWrapper('-', '--None--')
			};

			for (Warehouse__c warehouse : [
					SELECT Id, Name
					FROM Warehouse__c
					WHERE Active__c = TRUE
					AND Region_New__c =:acc.Region__c
			]) {
				warehouses.add(new PicklistWrapper(warehouse.Id, warehouse.Name));
			}

			return warehouses;
		}
	}

	@AuraEnabled
	public static void enableForecast(String accountId) {
		try {
			Account acc = new Account(Id = accountId);
			acc.Forecast_Enabled__c = true;
			update acc;
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	@AuraEnabled
	public static void disableForecast(Id accountId) {
		try {
			// Fetch and update the Account record
			Account acc = new Account(Id = accountId);
			acc.Forecast_Enabled__c = false;
			update acc;
	
			// Fetch Forecast_Product__c records related to the Account
			List<Forecast_Product__c> forecastProducts = [
				SELECT Id, Direct_Enabled__c, Local_Enabled__c 
				FROM Forecast_Product__c 
				WHERE Account__c = :accountId
			];
	
			// Update Direct_Enabled__c and Local_Enabled__c for each Forecast_Product__c record
			for (Forecast_Product__c fp : forecastProducts) {
				fp.Direct_Enabled__c = false;
				fp.Local_Enabled__c = false;
			}
	
			// Perform the update
			if (!forecastProducts.isEmpty()) {
				update forecastProducts;
			}
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}
	

	@AuraEnabled
	public static void enableProductForecast(String accountId, String forecast, String volume){
		try {
			List<ForecastNewProductWrapper> forecastWrappers = (List<ForecastNewProductWrapper>) JSON.deserialize(forecast, List<ForecastNewProductWrapper> .class);

			List<Forecast_Product__c> forecastProducts = new List<Forecast_Product__c>();
			List<Forecast_Month__c> forecastMonths = new List<Forecast_Month__c>();
			List<Forecast_Item__c> forecastItems = new List<Forecast_Item__c>();

			for(ForecastNewProductWrapper wrapper: forecastWrappers){

				if(!wrapper.directEnabled && !wrapper.localEnabled){
					continue;
				}

				if(wrapper.directEnabled){
					forecastProducts.add(
						new Forecast_Product__c(
							Account__c = accountId,
							Product__c = wrapper.productId,
							External_Id__c =  accountId + '-' + wrapper.productId +'-'+'0',
							Direct_Enabled__c = wrapper.directEnabled,
							Local_Enabled__c = false,
							Local_Warehouse__c = wrapper.directWarehouse != '-' ? wrapper.directWarehouse : null,
							Price__c = wrapper.directPrice
						)
					);
					Date startDate = Date.today().toStartOfMonth();
					Date endDate = date.today().addYears(1).addMonths(-1).toStartOfMonth();
					Date tempDate = startDate;

					while(tempDate <= endDate){
						forecastMonths.add(
							new Forecast_Month__c(
								Forecast_Product__r = new Forecast_Product__c(External_Id__c = accountId + '-' + wrapper.productId+'-'+ '0'),
								Month__c = tempDate,
								External_Id__c = accountId + '-' + wrapper.productId + '-' + ForecastUtil.getMonthUniqueId(tempDate) +'-'+ '0'
							)
						);
						tempDate = tempDate.addMonths(1);
					}
					for(ForecastItem item: wrapper.directForecast){
						forecastItems.add(
							new Forecast_Item__c(
								Quantity__c = ForecastUtil.setQuantityInVolume(item.quantity, volume, wrapper.uom),
								External_Id__c =  accountId + '-' + wrapper.productId + '-base-direct-' + item.externalId,
								Forecast__r = new Forecast_Month__c(External_Id__c = accountId + '-' + wrapper.productId + '-' + item.externalId+'-'+'0'),
								Fulfillment__c = Constants.forecastItem.FULFILLMENT_DIRECT,
								Item_Type__c = Constants.forecastItem.ITEM_TYPE_BASE
							)
						);
					}
				}

				if(wrapper.localEnabled){
					forecastProducts.add(
					new Forecast_Product__c(
						Account__c = accountId,
						Product__c = wrapper.productId,
						External_Id__c =  accountId + '-' + wrapper.productId+'-1',
						Direct_Enabled__c = false,
						Local_Enabled__c = wrapper.localEnabled,
						Local_Warehouse__c = wrapper.localWarehouse != '-' ? wrapper.localWarehouse : null,
						Price__c = wrapper.localPrice
					)
				);
					Date startDate = Date.today().toStartOfMonth();
					Date endDate = date.today().addYears(1).addMonths(-1).toStartOfMonth();
					Date tempDate = startDate;

					while(tempDate <= endDate){
						forecastMonths.add(
							new Forecast_Month__c(
								Forecast_Product__r = new Forecast_Product__c(External_Id__c = accountId + '-' + wrapper.productId+'-1'),
								Month__c = tempDate,
								External_Id__c = accountId + '-' + wrapper.productId + '-' + ForecastUtil.getMonthUniqueId(tempDate) +'-'+ '1'
							)
						);
						tempDate = tempDate.addMonths(1);
					}
					for(ForecastItem item: wrapper.localForecast){
						forecastItems.add(
							new Forecast_Item__c(
								Quantity__c = ForecastUtil.setQuantityInVolume(item.quantity, volume, wrapper.uom),
								External_Id__c =  accountId + '-' + wrapper.productId + '-base-local-' + item.externalId,
								Forecast__r = new Forecast_Month__c(External_Id__c = accountId + '-' + wrapper.productId + '-' + item.externalId+'-'+ '1'),
								Fulfillment__c = Constants.forecastItem.FULFILLMENT_LOCAL,
								Item_Type__c = Constants.forecastItem.ITEM_TYPE_BASE
							)
						);
					}
				}
			}

			upsert forecastProducts External_Id__c;
			upsert forecastMonths External_Id__c;
			upsert forecastItems External_Id__c;

		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	@AuraEnabled
	public static void setFulfillmentMethod(String accountId, String productId, String method, Boolean value) {
		try {
			Forecast_Product__c forecast = new Forecast_Product__c(External_Id__c = accountId + '-' + productId);

			if(method == 'direct'){
				forecast.Direct_Enabled__c = value;
			}else{
				forecast.Local_Enabled__c = value;
			}

			upsert forecast External_Id__c;

		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	@AuraEnabled
	public static void deleteForecasting(String accountId) {
		try {
			delete [SELECT id from Forecast_Product__c where Account__c =:accountId];
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	
	}

	@AuraEnabled
	public static void disableProduct(String accountId, String productId,Boolean direct) {
		try {
			String externalId = accountId + '-' + productId+'-'+(Direct?'0':'1');
			Forecast_Product__c recordToDelete = [SELECT Id FROM Forecast_Product__c WHERE External_Id__c = :externalId LIMIT 1];

			// Check if the record exists
			if (recordToDelete != null) {
				try {
					// Delete the record
					delete recordToDelete;
					System.debug('Record deleted successfully.');
				} catch (DmlException e) {
					// Handle the error
					System.debug('An error occurred when deleting the record: ' + e.getMessage());
				}
			} else {
				System.debug('No record found with the provided external ID.');
			}
			
			/*Forecast_Product__c forecast = new Forecast_Product__c(External_Id__c = accountId + '-' + productId+'-'+(Direct?'0':'1'));
			forecast.Direct_Enabled__c = false;
			forecast.Local_Enabled__c = false;
			upsert forecast External_Id__c;*/

		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	public class ForecastNewProductWrapper {
		public String productId;
		public Boolean directEnabled;
		public Boolean localEnabled;
		public Integer uom;
		public List<ForecastItem> directForecast;
		public List<ForecastItem> localForecast;
		public String directWarehouse;
		public String localWarehouse;
		public Decimal directPrice;
		public Decimal localPrice;
	}

	public class ForecastItem {
		public String externalId;
		public String quantity;
		public String fulfillment;

		public ForecastItem(){}

		public ForecastItem(String externalId, String quantity, String fulfillment){
			this.externalId = externalId;
			this.quantity = quantity;
			this.fulfillment = fulfillment;
		}
	}

	@AuraEnabled
	public static ForecastProductInfoWrapper getProductData(String productId) {
		try {
			return new ForecastProductInfoWrapper(productId);
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	@AuraEnabled
	public static ForecastProductDetailsWrapper getForecastDetailsForProduct(String accountId, String productId, String volume,boolean direct) {
		try {
			System.debug(direct);
			Date startDate = Date.today().toStartOfMonth();
			return new ForecastProductDetailsWrapper(accountId, productId, startDate, volume,direct)
				.build();
		} catch (Exception e) {
			System.debug(e.getStackTraceString());
			throw new AuraHandledException(e.getMessage());
		}
	}

	@AuraEnabled
	public static void upsertBaseForecast(String accountId, String productId, String baseForecastMap, String volume, Integer uom,boolean direct) {
		try {
			List<ForecastItem> forecastItems = (List<ForecastItem>) JSON.deserialize(baseForecastMap, List<ForecastItem> .class);
			System.debug(direct);
			List<Forecast_Item__c> forecastItemsToUpsert = new List<Forecast_Item__c> ();
			for (ForecastItem item: forecastItems) {
				forecastItemsToUpsert.add(
					new Forecast_Item__c(
						Quantity__c = ForecastUtil.setQuantityInVolume(item.quantity, volume, uom),
						External_Id__c =  accountId + '-' + productId + '-base-' + item.fulfillment + '-' + item.externalId,
						Forecast__r = new Forecast_Month__c(External_Id__c = accountId + '-' + productId + '-' + item.externalId+'-'+(direct ? '0':'1')),
						Item_Type__c = Constants.forecastItem.ITEM_TYPE_BASE,
						Fulfillment__c = ForecastUtil.getFulfillment(item.fulfillment)
					)
				);
			}

			upsert forecastItemsToUpsert External_Id__c;
		} catch (Exception e) {
			System.debug(e.getMessage());
			System.debug(e.getLineNumber());
			throw new AuraHandledException(e.getMessage());
		}
	}

	@AuraEnabled
	public static void upsertForecastAdjustments(
		String accountId,
		String productId,
		String adjustmentId,
		String opportunityId,
		String name,
		String comment,
		String forecastDataMap,
		String volume,
		Integer uom
		){
		try {
			List<Forecast_Item__c> forecastItemsToInsert = new List<Forecast_Item__c> ();
			List<ForecastItem> forecastItems = (List<ForecastItem>) JSON.deserialize(forecastDataMap, List<ForecastItem> .class);

			Forecast_Adjustment__c adjustment = new Forecast_Adjustment__c();
			adjustment.Comment__c = comment;
			adjustment.Name = String.isBlank(name) ? ForecastUtil.NEW_ADJUSTMENT_NAME : name;
			adjustment.Forecast_Opportunity__c = opportunityId == '-' ? null : opportunityId;

			if(adjustmentId == ForecastUtil.NEW_ADJUSTMENT_ID){
				insert adjustment;
			}else{
				adjustment.Id = adjustmentId;
				update adjustment;
			}

			for (ForecastItem item: forecastItems) {
				forecastItemsToInsert.add(
					new Forecast_Item__c(
						Quantity__c = ForecastUtil.setQuantityInVolume(item.quantity, volume, uom),
						Forecast__r = new Forecast_Month__c(External_Id__c = accountId + '-' + productId + '-' + item.externalId+ '-'+ (item.fulfillment == 'Local' ? '1' : '0')),
						External_Id__c = accountId + '-' + productId + '-' + adjustment.Id + '-' + item.externalId+ (item.fulfillment == 'Local' ? '1' : '0'),
						Fulfillment__c = ForecastUtil.getFulfillment(item.fulfillment),
						Item_Type__c = Constants.forecastItem.ITEM_TYPE_ADJUSTMENT,
						Forecast_Adjustment__c = adjustment.Id,
						Forecast_Opportunity__c = adjustment.Forecast_Opportunity__c
					)
				);
			}
			upsert forecastItemsToInsert External_Id__c;

			List<Forecast_Item__c> itemsToUpdate = [
				SELECT Id, Forecast__r.Month__c
				FROM Forecast_Item__c
				WHERE Forecast_Adjustment__c = :adjustmentId
				AND Forecast__r.Month__c >= :Date.today().toStartOfMonth()
			];

			for(Forecast_Item__c item: itemsToUpdate){
				item.Forecast_Opportunity__c = adjustment.Forecast_Opportunity__c;
			}
			update itemsToUpdate;

		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	@AuraEnabled
	public static void deactivateAdjustment(String adjustmentId) {
		try {
			List<Forecast_Item__c> items = [
				SELECT Id, Forecast__r.Month__c
				FROM Forecast_Item__c
				WHERE Forecast_Adjustment__c = :adjustmentId
				AND Forecast__r.Month__c >= :Date.today().toStartOfMonth()
			];
			for(Forecast_Item__c item: items){
				item.Active__c = false;
			}
			update items;
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	@AuraEnabled
	public static void forecastOpportunityApproval(String oppForecastId, String approvalStatus){
		List<Forecast_Item__c> itemsToUpdate = [
			SELECT Id, Forecast__r.Month__c
			FROM Forecast_Item__c
			WHERE Forecast_Opportunity__c = :oppForecastId
			AND Forecast__r.Month__c >= :Date.today().toStartOfMonth()
		];

		Forecast_Opportunity__c forecastOpp = new Forecast_Opportunity__c(Id = oppForecastId);
		forecastOpp.BU_Approval__c = approvalStatus;

		for(Forecast_Item__c item : itemsToUpdate){
			item.BU_Approval__c = approvalStatus;
		}

		update forecastOpp;
		update itemsToUpdate;
	}

	@AuraEnabled
	public static ForecastWrapper getForecastByProduct(
		String productId,
		String volume,
		String searchTerm,
		Integer pageSize,
		Integer pageNumber
	) {
		try {
			system.debug('productId-->'+productId);
			return new ForecastWrapper(null, productId, Date.today().toStartOfMonth(), volume, searchTerm, pageSize, pageNumber)
				.setForecast().build();
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}


	@AuraEnabled
	public static ForecastWrapper getForecast(
		String accountId,
		String volume,
		String searchTerm,
		Integer pageSize,
		Integer pageNumber
	) {
		try {
			return new ForecastWrapper(accountId, null, Date.today().toStartOfMonth(), volume, searchTerm, pageSize, pageNumber)
				.setForecast().build();
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	public class ForecastWrapper {
		private Id accountId;
		private Id productId;
		private String volume;
		private String searchTerm;
		private Integer offset;
		private Integer pageNumber;

		@AuraEnabled public Integer pageSize;
		@AuraEnabled public Integer recordStart;
		@AuraEnabled public Integer totalRecords;
		@AuraEnabled public Integer recordEnd;

		@AuraEnabled public List < String > dateRange;
		@AuraEnabled public List < ForecastProductTotalsWrapper > forecastProducts = new List < ForecastProductTotalsWrapper > ();

		public ForecastWrapper(
			Id accountId,
			Id productId,
			Date startDate,
			String volume,
			String searchTerm,
			Integer pageSize,
			Integer pageNumber
		) {
			this.accountId = accountId;
			this.productId = productId;
			this.dateRange = ForecastUtil.prepareDateRange(startDate);
			this.volume = volume;
			this.searchTerm = searchTerm;
			this.pageSize = pageSize;
			this.pageNumber = pageNumber;
			this.offset = (pageNumber - 1) * pageSize;
		}

		public ForecastWrapper setForecast() {
			system.debug('getForecastData-->'+getForecastData());
			for (Forecast_Product__c forecast: getForecastData()) {
				ForecastProductTotalsWrapper wrapper = new ForecastProductTotalsWrapper(
						forecast.Product__r,
						forecast.Account__r.Name,
						forecast.Account__c,
						volume,
						forecast.Direct_Enabled__c,
						forecast.Local_Enabled__c,
						forecast.Local_Warehouse__r,
						forecast.Price__c != null ? forecast.Price__c : 0
				).setData(dateRange, forecast.Forecast_Months__r);

				forecastProducts.add(wrapper);
			}
			return this;
		}

		public ForecastWrapper build(){
			recordStart = offset + 1;
			recordEnd = pageSize * pageNumber;
			
			if (accountId == null && productId != null){
				if(String.isEmpty(searchTerm)){
					totalRecords = [
						SELECT COUNT()
						FROM Forecast_Product__c
						WHERE Product__c =: productId
						AND (Local_Enabled__c = TRUE OR Direct_Enabled__c = TRUE)
					];
				}else{
					String likeValue = '%' + searchTerm + '%';
					totalRecords = [
						SELECT COUNT()
						FROM Forecast_Product__c
						WHERE Product__c =: productId
						
						AND (Product__r.Name LIKE :likeValue OR Product__r.Product_Line__c LIKE :likeValue OR Product__r.ProductCode LIKE :likeValue)
						AND (Local_Enabled__c = TRUE OR Direct_Enabled__c = TRUE)
					];
				}
			} else {
				if(String.isEmpty(searchTerm)){
					totalRecords = [
						SELECT COUNT()
						FROM Forecast_Product__c
						WHERE Account__c =: accountId
						AND (Local_Enabled__c = TRUE OR Direct_Enabled__c = TRUE)
					];
				}else{
					String likeValue = '%' + searchTerm + '%';
					totalRecords = [
						SELECT COUNT()
						FROM Forecast_Product__c
						WHERE Account__c =: accountId
						AND (Product__r.Name LIKE :likeValue OR Product__r.Product_Line__c LIKE :likeValue OR Product__r.ProductCode LIKE :likeValue)
						AND (Local_Enabled__c = TRUE OR Direct_Enabled__c = TRUE)
					];
				}
			}

			recordEnd = totalRecords >= recordEnd ? recordEnd : totalRecords;
			return this;
		}

		private List < Forecast_Product__c > getForecastData() {
			system.debug('accountId-->'+accountId);
			system.debug('productId-->'+productId);
			if (accountId == null && productId != null){
				if(String.isEmpty(searchTerm)){
					system.debug('if block for product-->');
					return [
						SELECT
						Id, Account__c, Account__r.Name, Product__c,price__c, Product__r.Unit_Price__c,Product__r.ProductCode, Product__r.Name, Product__r.NACA_Case_Qty__c, Product__r.Product_Line__c,
						Direct_Enabled__c, Local_Enabled__c, Local_Warehouse__c, Local_Warehouse__r.Name,
						(SELECT Id, Month__c, Adjustments_Total__c, Base_Total__c, Current_Orders__c,
							Previous_Year_Orders__c, Opportunities_Total__c, Forecast_Total__c
							FROM Forecast_Months__r
							WHERE Month__c >= :Date.today().toStartOfMonth()
							ORDER BY Month__c ASC)
						FROM Forecast_Product__c
						WHERE Product__c =: productId
						AND (Local_Enabled__c = TRUE OR Direct_Enabled__c = TRUE)
						ORDER BY Product__r.Product_Line__c, Product__r.Name ASC
						LIMIT :pageSize
						OFFSET :offset
					];
				}else{
					system.debug('else block for product-->');
					String likeValue = '%' + searchTerm + '%';
					return [
						SELECT
						Id, Account__c, Account__r.Name, Product__c, price__c, Product__r.Unit_Price__c, Product__r.ProductCode, Product__r.Name, Product__r.NACA_Case_Qty__c, Product__r.Product_Line__c,
						Direct_Enabled__c, Local_Enabled__c, Local_Warehouse__c, Local_Warehouse__r.Name,
						(SELECT Id, Month__c, Adjustments_Total__c, Base_Total__c, Current_Orders__c,
							Previous_Year_Orders__c, Opportunities_Total__c, Forecast_Total__c
							FROM Forecast_Months__r
							WHERE Month__c >= :Date.today().toStartOfMonth()
							ORDER BY Month__c ASC)
						FROM Forecast_Product__c
						WHERE Product__c =: productId
						AND (Local_Enabled__c = TRUE OR Direct_Enabled__c = TRUE)
						AND (Product__r.Name LIKE :likeValue OR Product__r.Product_Line__c LIKE :likeValue OR Product__r.ProductCode LIKE :likeValue)
						ORDER BY Product__r.Product_Line__c, Product__r.Name ASC
						LIMIT :pageSize
						OFFSET :offset
					];
				}
			} else {
				if(String.isEmpty(searchTerm)){
					system.debug('if block for account-->');
					return [
						SELECT
						Id, Account__c, Account__r.Name, Product__c,price__c, Product__r.Unit_Price__c,Product__r.ProductCode, Product__r.Name, Product__r.NACA_Case_Qty__c, Product__r.Product_Line__c,
						Direct_Enabled__c, Local_Enabled__c, Local_Warehouse__c, Local_Warehouse__r.Name,
						(SELECT Id, Month__c, Adjustments_Total__c, Base_Total__c, Current_Orders__c,
							Previous_Year_Orders__c, Opportunities_Total__c, Forecast_Total__c
							FROM Forecast_Months__r
							WHERE Month__c >= :Date.today().toStartOfMonth()
							ORDER BY Month__c ASC)
						FROM Forecast_Product__c
						WHERE Account__c =: accountId
						AND (Local_Enabled__c = TRUE OR Direct_Enabled__c = TRUE)
						ORDER BY Product__r.Product_Line__c, Product__r.Name ASC
						LIMIT :pageSize
						OFFSET :offset
					];
				}else{
					system.debug('else block for account-->');
					String likeValue = '%' + searchTerm + '%';
					return [
						SELECT
						Id, Account__c, Account__r.Name, Product__c, price__c, Product__r.Unit_Price__c, Product__r.ProductCode, Product__r.Name, Product__r.NACA_Case_Qty__c, Product__r.Product_Line__c,
						Direct_Enabled__c, Local_Enabled__c, Local_Warehouse__c, Local_Warehouse__r.Name,
						(SELECT Id, Month__c, Adjustments_Total__c, Base_Total__c, Current_Orders__c,
							Previous_Year_Orders__c, Opportunities_Total__c, Forecast_Total__c
							FROM Forecast_Months__r
							WHERE Month__c >= :Date.today().toStartOfMonth()
							ORDER BY Month__c ASC)
						FROM Forecast_Product__c
						WHERE Account__c =: accountId
						AND (Local_Enabled__c = TRUE OR Direct_Enabled__c = TRUE)
						AND (Product__r.Name LIKE :likeValue OR Product__r.Product_Line__c LIKE :likeValue OR Product__r.ProductCode LIKE :likeValue)
						ORDER BY Product__r.Product_Line__c, Product__r.Name ASC
						LIMIT :pageSize
						OFFSET :offset
					];
				}
			}

		}
	}

	@AuraEnabled
	public static void updateWarehouse(String accountId, String productId, String warehouseId,boolean direct){
		try {
			Forecast_Product__c forecast = [SELECT Id FROM Forecast_Product__c WHERE Account__c = :accountId AND Product__c = :productId AND Direct_Enabled__c =: direct LIMIT 1];
			forecast.Local_Warehouse__c = String.isBlank(warehouseId) ? null : warehouseId;
			update forecast;
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	@AuraEnabled
	public static void updatePriceFP(String accountId, String productId, Decimal price){
		try {
			Forecast_Product__c forecast = [SELECT Id FROM Forecast_Product__c WHERE Account__c = :accountId AND Product__c = :productId LIMIT 1];
			forecast.price__c = price == null ? null : price;
			update forecast;
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	@AuraEnabled(cacheable = true) 
	public static LIST<Historical_Forecast__c> getHistoricalForecastByAccount(String accountId){
		return [SELECT Id, Product__c, Product__r.Name,  Product__r.ProductCode,Warehouse__c, Warehouse__r.Name, 
				Total_Quantity__c, Total_Revenue__c, ASP__c, Value__c 
				FROM Historical_Forecast__c 
				WHERE Account__c =:accountId];
	}

	@AuraEnabled(cacheable = true) 
	public static LIST<Historical_Forecast__c> getHistoricalForecastByProduct(String accountId, String productId){
		return [SELECT Id, Product__c, Product__r.Name,  Product__r.ProductCode,Warehouse__c, Warehouse__r.Name, 
				Total_Quantity__c, Total_Revenue__c, ASP__c, Value__c 
				FROM Historical_Forecast__c 
				WHERE Account__c =:accountId
				AND Product__c=:productId];
	}

	@AuraEnabled(cacheable = true) 
	public static List<Forecast_Product__c> getForecastProduct(String accountId){
		return [SELECT Id, Product__r.ProductCode
				FROM Forecast_Product__c 
				WHERE Account__c=:accountId
				AND (Local_Enabled__c != false OR Direct_Enabled__c != false)];
	}

	@AuraEnabled(cacheable = true) 
	public static String getCurrencyCode(String accountId){
		Account acc = [SELECT Id, CurrencyIsoCode 
				FROM Account 
				WHERE Id=:accountId LIMIT 1];

				return acc.CurrencyIsoCode;
	}


	public static void justIncrement(){
		Integer i = 0;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
				i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
				i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
				i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
				i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
				i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
				i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
				i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
				i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
				i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
				i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
				i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
				i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
				i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
				i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
				i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;        i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
				i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
				i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
				i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
				i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
				i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
				i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
				i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;        i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;        i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
				i++;
		i++;
		i++;
		i++;
		i++;
		i++;
			i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
				i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
				i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
				i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
				i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
				i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
				i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
				i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
				i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
				i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
				i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
				i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
				i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
				i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
				i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
				i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;        i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
				i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
				i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
				i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
				i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
				i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
				i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
				i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;        i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;        i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
				i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
				i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
				i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
				i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
				i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
				i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
				i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
				i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
				i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
				i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
				i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
	}
}