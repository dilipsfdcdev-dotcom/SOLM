public with sharing class EMEA_SAP_Dictionary {
	public static final Map<Integer, String> GROUP_SAP_CODE_MAP = new Map<Integer, String>{
			103 => 'Local',
			107 => 'Interco',
			109 => 'Corporate',
			110 => 'Other'
	};

	public static final Map<String, String> ORGANIZATION_TYPE_SAP_CODE_MAP = new Map<String, String>{
			'-1' => 'Other',
			'1' => 'Company-Pharma',
			'2' => 'Company-MedDev',
			'3' => 'OEM-B2B-bulk',
			'4' => 'Distr-Hospital',
			'5' => 'Distr-Retail',
			'6' => 'Distr-Other',
			'7' => 'Distr-Lab',
			'8' => 'Distr-VET',
			'9' => 'GPO',
			'10' => 'IDN',
			'11' => 'State/Regional',
			'12' => 'Hosp-Public/MOH',
			'13' => 'Hosp-Private',
			'14' => 'Acute Care',
			'15' => 'Long Term Care',
			'16' => 'RTC',
			'17' => 'Hosp-Military',
			'18' => 'Home Care',
			'19' => 'Lab-Public',
			'20' => 'Lab-Private',
			'21' => 'Retail-Pharma',
			'22' => 'Retail-MassMark',
			'23' => 'Retail-E-comm',
			'24' => 'NGO',
			'25' => 'Private buyer'
	};
}