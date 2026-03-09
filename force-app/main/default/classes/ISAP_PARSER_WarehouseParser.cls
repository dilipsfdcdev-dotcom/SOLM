public interface ISAP_PARSER_WarehouseParser {
	List<ISAP_PARSER_WarehouseParser> parse(String json);

    String getRegion();
	String getWhsCode();
}