public virtual with sharing class SAP_OrderBuilder implements ISAP_OrderBuilder{
    public Order order;
    public List<OrderItem> orderProducts;
    public SAP_PARSER_Order wrapper;
    public String pricebookExternalId;

    public virtual void init(ISAP_PARSER wrapper){
        this.orderProducts = new List<OrderItem>();
        this.wrapper = (SAP_PARSER_Order) wrapper;

        if(Test.isRunningTest()) {
            this.pricebookExternalId = 'TEST';
        } else {
            this.pricebookExternalId = 'STANDARD';
        }
    }

    public virtual void setSAPCode(){
        order.Document_Number__c = String.valueOf(wrapper.DocNum);
        order.Customer_PO__c = String.valueOf(wrapper.NumAtCard);
    }

    public virtual String getSalesPersonCode(){
        return String.valueOf(wrapper.SlpCode);
    }

    public virtual void setAccount(){
        return;
    }

    public virtual void setCurrency(){
        if(String.isBlank(wrapper.DocCur)) {
            order.CurrencyIsoCode = UserInfo.getDefaultCurrency();
            return;
        }

        switch on wrapper.DocCur {
            when '##' {
                order.CurrencyIsoCode = 'EUR';
            }
            when '$' {
                order.CurrencyIsoCode = 'USD';
            }
            when else {
                order.CurrencyIsoCode = wrapper.DocCur;
            }
        }
    }

    public virtual void setDates(){
        order.EffectiveDate = Date.valueOf(wrapper.DocDate);
        if(order.EffectiveDate <= Date.valueOf(wrapper.DocDueDate)) {
            order.EndDate = Date.valueOf(wrapper.DocDueDate);
        }
    }

    public virtual void setStatus(){
        if(wrapper.CANCELED == 'Y'){
            order.Status = Constants.order.STATUS_CANCELED;
        }else if(wrapper.DocStatus == 'C'){
            order.Status = Constants.order.STATUS_CLOSED;
        }else if(wrapper.DocStatus == 'O'){
            order.Status = Constants.order.STATUS_OPEN;
        }
    }

    public virtual void setOrderType(){
        order.Type = Constants.order.TYPE_SAP;
    }

    public virtual void setOrderAddresses(){
        order.Bill_To_Code__c = wrapper.PayToCode;
        order.Ship_To_Code__c = wrapper.ShipToCode;
    }

    public virtual void setPricebook(){
        Pricebook2 priceBookReference = new Pricebook2(SAP_Code__c = pricebookExternalId);
        order.Pricebook2 = priceBookReference;
    }

    public virtual void setAdditionalInformation(){
        order.Description = wrapper.Comments;
    }

    public virtual Order buildOrder(){
        setSAPCode();
        setAccount();
        setCurrency();
        setDates();
        setStatus();
        setOrderType();
        setOrderAddresses();
        setPricebook();
        setAdditionalInformation();
        return order;
    }

    public virtual List<OrderItem> buildOrderProducts(){
        if(wrapper.Itens == null) {
            return orderProducts;
        }

        for(SAP_PARSER_Order.Itens item: wrapper.Itens){
            orderProducts.add(
                new OrderProductBuilder(order, item, pricebookExternalId)
                    .setSAPCode()
                    .setPriceBookEntry()
                    .setStatus()
                    .setShipmentDate()
                    .setQuantity()
                    .setPrice() 
                    .build()
            );
        }
        return orderProducts;
    }

    public virtual class OrderProductBuilder{
        private Order order;
        private SAP_PARSER_Order.Itens wrapper;
        private OrderItem orderProduct;
        private String pricebookExternalId;

        public OrderProductBuilder(Order order, SAP_PARSER_Order.Itens wrapper, String pricebookExternalId){
            this.orderProduct = new OrderItem(Order = new Order(SAP_Code__c = order.SAP_Code__c));
            this.wrapper = wrapper;
            this.order = order;
            this.pricebookExternalId = pricebookExternalId;
        }

        public OrderProductBuilder setSAPCode(){
            orderProduct.SAP_Code__c = order.SAP_Code__c + '-' + wrapper.LineNum;
            return this;
        }

        public OrderProductBuilder setPriceBookEntry(){
            orderProduct.PricebookEntry = new PricebookEntry(
                    SAP_Code__c = wrapper.ItemCode + pricebookExternalId + order.CurrencyIsoCode
            );
            return this;
        }

        public OrderProductBuilder setStatus(){
            if(wrapper.LineStatus == 'C'){
                orderProduct.Status__c = Constants.order.STATUS_CLOSED;
            }else if(wrapper.LineStatus == 'O'){
                orderProduct.Status__c = Constants.order.STATUS_OPEN;
            }
            return this;
        }

        public OrderProductBuilder setShipmentDate(){
            if(wrapper.ShipDate != ''){
                orderProduct.Shipment_Date__c = Date.valueOf(wrapper.ShipDate);
            }
            return this;
        }

        public OrderProductBuilder setQuantity(){
            orderProduct.Quantity = Decimal.valueOf(wrapper.Quantity).round(System.RoundingMode.FLOOR);
            return this;
        }

        public OrderProductBuilder setPrice(){
            orderProduct.UnitPrice = Decimal.valueOf(wrapper.Price);
            return this;
        }

        public OrderItem build(){
            return orderProduct;
        }
    }
}