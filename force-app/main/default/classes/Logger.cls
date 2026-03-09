public class Logger {
    private final String TYPE_ERROR = 'Error';

    public String message;
    public String errorMessage;
    public String stack;
    public String typeName;
    public String objectType;
    public String area;
    public String market;

    public Logger(){}

    public Logger(String objectType, String area){
        this.objectType = objectType;
        this.area = area;
    }

    public Logger(String objectType, String area, String market){
        this(objectType, area);
        this.market = market;
    }
    
    public Logger error(Exception ex) {
        return error(ex.getMessage(), ex.getStackTraceString());
    }
	
    public Logger errorString(String paramMessage, String paramStackTrace) {
        return error(paramMessage, paramStackTrace);
    }

    private Logger error(String paramMessage, String paramStackTrace){
        this.message = paramMessage.length() > 255 ? paramMessage.substring(0, 255) : paramMessage;
        this.errorMessage = paramMessage;
        this.stack = paramStackTrace.length() > 255 ? paramStackTrace.substring(0, 255) : paramStackTrace;
        this.typeName = TYPE_ERROR;
        return this;
    }
	
	public void create() {
		try {
			Debug_Log__e logEvent = new Debug_Log__e(
				Message__c = message,
                Error_Message__c = errorMessage,
				Stack_Trace__c = stack,
				Type__c = typeName,
                Object_Type__c = objectType,
                Area__c = area,
                Market__c = market
			);
			EventBus.publish(logEvent);
		} catch (DMLException ex) {
			System.debug(LoggingLevel.ERROR, 'Failed to create log:' + ex.getMessage());
		}
	}
}