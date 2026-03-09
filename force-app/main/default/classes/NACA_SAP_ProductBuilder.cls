public class NACA_SAP_ProductBuilder implements ISAP_ProductBuilder{
    private NACA_SAP_PARSER_Product wrapper;
    private Product2 product;

    public Product2 build(ISAP_PARSER wrapper){
        this.wrapper = (NACA_SAP_PARSER_Product) wrapper;
        this.product = new Product2();

        setProductName();
        setSAPCode();
        setProductCode();
        setCategories();
        setActive();
        setCurrency();
        setSellingUnits();

        return product;
    }

    public void setProductName(){
        product.Name = wrapper.ItemName;
    }

    public void setSAPCode(){
        product.SAP_Code__c = wrapper.ItemCode;
    }

    public void setProductCode(){
        product.ProductCode = wrapper.OldItemCode;
    }

    public void setCategories(){
        product.Family = wrapper.ItmsGrpNam;
        if( wrapper.Segment != null) product.Segment__c = wrapper.Segment;
        if( wrapper.ProductLine != null) product.Product_Line__c = wrapper.ProductLine;
        if( wrapper.Material != null) product.Material__c = wrapper.Material;
        if( wrapper.Branding != null)  product.Branding__c = wrapper.Branding;
        if( wrapper.Category != null) product.Category__c = wrapper.Category;
        if( wrapper.SubCategory != null) product.SubCategory__c = wrapper.SubCategory;
    }

    public void setActive(){
        product.IsActive = true;

        switch on wrapper.Active {
            when 'Y'{
                product.NACA_Active__c = true;
            }
            when else {
                product.NACA_Active__c = false;
            }
        }
    }

    public void setCurrency(){
        product.CurrencyIsoCode = 'USD';
    }

    public void setDimensions(){}

    public void setSellingUnits(){
        product.NACA_Case_Qty__c = Integer.valueOf(wrapper.NumInSale);
        product.NACA_Box_Quantity__c = !String.isBlank(wrapper.U_box_Qty) && wrapper.U_box_Qty.isNumeric() ? Integer.valueOf(wrapper.U_box_Qty) : null;
        product.UoM__c = wrapper.SalUnitMsr; //used in NACA quote template
    }
}