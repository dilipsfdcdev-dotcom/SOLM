public interface ISAP_PriceBookBuilder {
    void setName();

    void setActive();

    void setSAPCode();

    Pricebook2 build(ISAP_PARSER wrapper);
}