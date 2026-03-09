public interface ISAP_ProductBuilder {
    void setProductName();
    void setSAPCode();
    void setProductCode();
    void setCategories();
    void setActive();
    void setCurrency();
    void setDimensions();
    void setSellingUnits();
    Product2 build(ISAP_PARSER wrapper);
}