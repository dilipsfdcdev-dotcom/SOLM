@isTest
global class SAP_EMEA_GET_Accounts_MOCK implements HttpCalloutMock{

    private String response;

    public SAP_EMEA_GET_Accounts_MOCK(){
        response = prepareBaseBody();
    }

    public SAP_EMEA_GET_Accounts_MOCK(String requestType){
			response = prepareBaseBody();
    }

    global HTTPResponse respond(HTTPRequest req) {

		HttpResponse res = new HttpResponse();
		res.setHeader('Content-Type', 'application/json');
		res.setBody(response);
		res.setStatusCode(200);
		return res;
	}

    private string prepareBaseBody(){
        return '[' +
            '{' +
                '"CardCode": "C0100",' +
                '"CardName": "Test Account 1",' +
				'"GroupCode": 103,'+
				'"Currency": "$",' +
                '"E_Mail": "",' +
                '"Phone1": "(123) 456-789",' +
                '"PymntGroup": "100% COD",' +
                '"BPAddresses": [' +
                    '{' +
						'"AddressName": "Tower Business Park, Loughtagalla, Thurles",' +
						'"Zone": "",' +
						'"AddrType": "B",' +
                        '"Street": "Test",' +
                        '"ZipCode": "",' +
                        '"City": "Chicago",' +
                        '"Country": "US",' +
                        '"AdressType": "B"' +
                    '},' +
                    '{' +
						'"AddressName": "Tower Business Park, Loughtagalla, Thurles",' +
						'"Zone": "",' +
						'"AddrType": "S",' +
                        '"Street": "TEST",' +
                        '"ZipCode": "",' +
                        '"City": "Chicago",' +
                        '"Country": "US",' +
						'"AdressType": "S"' +
                    '}' +
                '],' +
                '"BPPaymentMethods": [],' +
                '"SlpCode": 19,' +
				'"LicTradNum": "IE9819880E",' +
				'"Incoterms": "EXW",' +
				'"OrderRealizationEmail": "Martine.Visch@alk.net; PRODK@ALK.NET; mariandevries@artuvet.com",' +
				'"InvoicingEmail": "accounting-nl@alk.net",' +
				'"QualityRegulatoryEmail": "",' +
				'"MarketingEmail": "",' +
				'"Industry": "1",' +
				'"Active": "Y",' +
				'"BillToDef": "Tower Business Park, Loughtagalla, Thurles",' +
				'"ShipToDef": "Tower Business Park, Loughtagalla, Thurles" ' +
            '},'+
            '{' + 
            '"CardCode": "C0101",' +
            '"CardName": "Test Account 2",' +
			'"GroupCode": 103,'+
            '"Currency": "$",' +
            '"E_Mail": "",' +
            '"Phone1": "(919) 544-7040",' +
            '"PymntGroup": "100% COD",' +
            '"BPAddresses": [],' +
            '"BPPaymentMethods": [],' +
            '"SlpCode": 19,' +
			'"SlpName": "Nicolas Decock",' +
			'"LicTradNum": "NL005302766B01",' +
			'"Incoterms": "EXW",' +
			'"OrderRealizationEmail": "Martine.Visch@alk.net; PRODK@ALK.NET; mariandevries@artuvet.com",' +
			'"InvoicingEmail": "accounting-nl@alk.net",' +
			'"QualityRegulatoryEmail": "",' +
			'"MarketingEmail": "",' +
			'"Industry": "1",' +
			'"Active": "Y",' +
			'"BillToDef": "",' +
			'"ShipToDef": "" ' +
            '}' +
        ']';
    }
}