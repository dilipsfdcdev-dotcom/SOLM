public class ExceptionDataProcessor{
	public static final String STATUS_CODE = 'Status code: ';
	public static final String ERROR_MESSAGE = ', Error Message: ';
	public static final String FIELDS = ', Fields: ';
	public static final String IDENTIFIER = ', Identifier: ';

	public static List<String> getUpsertResultErrorDetails(Database.UpsertResult[] paramSaveResults, List<SObject> records, Schema.SObjectField identifierField){
		List<String> lstErrorDetails = new List<String>();
		for(Integer i = 0; i < paramSaveResults.size(); i++){
			Database.UpsertResult sr = paramSaveResults[i];
			SObject record = records[i];
			if (!sr.isSuccess()){
				for(Database.Error err : sr.getErrors()){
					String errorMessage = STATUS_CODE + err.getStatusCode() + ERROR_MESSAGE + err.getMessage() + FIELDS + err.getFields() + IDENTIFIER + record.get(identifierField);
					lstErrorDetails.add(errorMessage);
				}
			}
		}
		return lstErrorDetails;
	}

	public static List<String> getDeleteResultErrorDetails(Database.DeleteResult[] paramDeleteResults, List<SObject> records, Schema.SObjectField identifierField){
		List<String> lstErrorDetails = new List<String>();
		for(Integer i = 0; i < paramDeleteResults.size(); i++){
			Database.DeleteResult deleteResult = paramDeleteResults[i];
			SObject record = records[i];
			if (!deleteResult.isSuccess()){
				for(Database.Error err : deleteResult.getErrors()){
					String errorMessage = STATUS_CODE + err.getStatusCode() + ERROR_MESSAGE + err.getMessage() + FIELDS + err.getFields() + IDENTIFIER + record.get(identifierField);
					lstErrorDetails.add(errorMessage);
				}
			}
		}
		return lstErrorDetails;
	}

	public static List<String> getSaveResultErrorDetails(Database.SaveResult[] paramSaveResults, List<SObject> records, Schema.SObjectField identifierField){
		List<String> lstErrorDetails = new List<String>();
		for(Integer i = 0; i < paramSaveResults.size(); i++){
			Database.SaveResult sr = paramSaveResults[i];
			SObject record = records[i];
			if (!sr.isSuccess()){
				for(Database.Error err : sr.getErrors()){
					String errorMessage = STATUS_CODE + err.getStatusCode() + ERROR_MESSAGE + err.getMessage() + FIELDS + err.getFields() + IDENTIFIER + record.get(identifierField);
					lstErrorDetails.add(errorMessage);
				}
			}
		}
		return lstErrorDetails;
	}
}