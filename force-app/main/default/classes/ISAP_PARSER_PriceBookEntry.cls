public interface ISAP_PARSER_PriceBookEntry {
	List<ISAP_PARSER_PriceBookEntry> parse(String json);

    Decimal getPrice();
	String getPriceBookCode();
    String getProduct2Code();
    String getPriceBookEntryCode();
    Boolean getIsActive();
}