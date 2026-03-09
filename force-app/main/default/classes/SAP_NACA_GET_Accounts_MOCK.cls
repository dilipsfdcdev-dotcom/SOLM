@isTest
global class SAP_NACA_GET_Accounts_MOCK implements HttpCalloutMock{

    private String response;

    public SAP_NACA_GET_Accounts_MOCK(){
        response = prepareBaseBody();
    }

    public SAP_NACA_GET_Accounts_MOCK(String requestType){
        switch on requestType{
            when 'SKIP' {
                response = prepareSkipBody();
            }
            when else{
                response = prepareBaseBody();
            }
        }
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
                '"U_ExternalID": "SAP",' +
                '"CardCode": "C0100",' +
                '"CardName": "Test Account 1",' +
                '"CardFName": "Test Account 1",' +
                '"Series": 59,' +
                '"CardType": "C",' +
                '"GroupCode": 123,' +
                '"Currency": "$",' +
                '"E_Mail": "",' +
                '"Phone1": "(123) 456-789",' +
                '"Phone2": "",' +
                '"Cellular": "",' +
                '"CompanyPrivate": "cCompany",' +
                '"Notes": "",' +
                '"Territory": "0",' +
                '"CreditLine": 0.000000,' +
                '"GroupNum": 13,' +
                '"PymntGroup": "100% COD",' +
                '"ContactEmployees": ['+
                    '{' +
                        '"Name": "Billing Agent",' +
                        '"FirstName": "Joe",' +
                        '"MiddleName": "",' +
                        '"LastName": "Doe",' +
                        '"Tel1": "123 456 789",' +
                        '"E_MailL": "billing@gmail.com"' +
                    '},' +
                    '{' +
                        '"Name": "Purchasing Agent",' +
                        '"FirstName": "Kelly",' +
                        '"MiddleName": "",' +
                        '"LastName": "Mark",' +
                        '"Tel1": "123 456 789",' +
                        '"E_MailL": "purchasing@gmail.com"' +
                    '}' +
                '],' +
                '"BPAddresses": [' +
                    '{' +
                        '"AddressName": "Test Account 1",' +
                        '"County": "",' +
                        '"AddrType": "B",' +
                        '"Street": "Test",' +
                        '"StreetNo": "",' +
                        '"Building": "",' +
                        '"ZipCode": "",' +
                        '"Block": "",' +
                        '"City": "Chicago",' +
                        '"State": "",' +
                        '"Country": "US",' +
                        '"AdressType": "S",' +
                        '"GlobalLocationNumber": "",' +
                        '"U_CReceiver": "",' +
                        '"U_CDesignation": "",' +
                        '"U_CCarrierName": "",' +
                        '"U_CAccount": "",' +
                        '"U_CDock": "",' +
                        '"U_CMaxPaletHeight": "",' +
                        '"U_CReceivingHours": "",' +
                        '"U_CEmail2": "",' +
                        '"U_CPhone4": ""' +
                    '},' +
                    '{' +
                        '"AddressName": "Test Account 1",' +
                        '"County": "",' +
                        '"AddrType": "S",' +
                        '"Street": "TEST",' +
                        '"StreetNo": "",' +
                        '"Building": "",' +
                        '"ZipCode": "",' +
                        '"Block": "",' +
                        '"City": "Chicago",' +
                        '"State": "",' +
                        '"Country": "US",' +
                        '"AdressType": "S",' +
                        '"GlobalLocationNumber": "12345",' +
                        '"U_CReceiver": "",' +
                        '"U_CDesignation": "",' +
                        '"U_CCarrierName": "",' +
                        '"U_CAccount": "",' +
                        '"U_CDock": "",' +
                        '"U_CMaxPaletHeight": "",' +
                        '"U_CReceivingHours": "",' +
                        '"U_CEmail2": "",' +
                        '"U_CPhone4": ""' +
                    '}' +
                '],' +
                '"BPPaymentMethods": [],' +
                '"SlpCode": 19,' +
                '"SlpName": "Aga Doe",' +
                '"CustomerOwnershipType": "Non- Profit Corporation",' +
                '"InBusinessSince": "1971",' +
                '"TaxExemptAccount": "N",' +
                '"FederalTaxIdNumber": "00-1111",' +
                '"OrderConfirmationEmail": "purchasing@gmail.com",' +
                '"SendingInvoicesEmail": "purchasing@gmail.com"' +
            '},'+
            '{' + 
            '"U_ExternalID": "SAP",' +
            '"CardCode": "C0101",' +
            '"CardName": "Test Account 2",' +
            '"CardFName": "Test Account 2",' +
            '"Series": 59,' +
            '"CardType": "C",' +
            '"GroupCode": 123,' +
            '"Currency": "$",' +
            '"E_Mail": "",' +
            '"Phone1": "(919) 544-7040",' +
            '"Phone2": "",' +
            '"Cellular": "",' +
            '"CompanyPrivate": "cCompany",' +
            '"Notes": "",' +
            '"Territory": "0",' +
            '"CreditLine": 0.000000,' +
            '"GroupNum": 13,' +
            '"PymntGroup": "100% COD",' +
            '"ContactEmployees": [],' +
            '"BPAddresses": [],' +
            '"BPPaymentMethods": [],' +
            '"SlpCode": 19,' +
            '"SlpName": "Aga Doe",' +
            '"CustomerOwnershipType": "Non- Profit Corporation",' +
            '"InBusinessSince": "1971",' +
            '"TaxExemptAccount": "N",' +
            '"FederalTaxIdNumber": "00-2222",' +
            '"OrderConfirmationEmail": "purchasing2@gmail.com",' +
            '"SendingInvoicesEmail": "purchasing2@gmail.com",' +
            '"DeliveryNotificationEmail": "",' +
            '"SPSSendPOAck": "N",' +
            '"SPSSendInvoice": "N",' +
            '"SPSSendASN": "N",' +
            '"SPSOrderStandAlone": "N"' +
            '}' + 
        ']';
    }

    private string prepareSkipBody(){
        return '[' +
                    '{' + 
                    '"U_ExternalID": "SAP",' +
                    '"CardCode": "C0101",' +
                    '"CardName": "Test Account 2",' +
                    '"CardFName": "Test Account 2",' +
                    '"Series": 59,' +
                    '"CardType": "C",' +
                    '"GroupCode": 123,' +
                    '"Currency": "$",' +
                    '"E_Mail": "",' +
                    '"Phone1": "(919) 544-7040",' +
                    '"Phone2": "",' +
                    '"Cellular": "",' +
                    '"CompanyPrivate": "cCompany",' +
                    '"Notes": "",' +
                    '"Territory": "0",' +
                    '"CreditLine": 0.000000,' +
                    '"GroupNum": 13,' +
                    '"PymntGroup": "100% COD",' +
                    '"ContactEmployees": [],' +
                    '"BPAddresses": [],' +
                    '"BPPaymentMethods": [],' +
                    '"SlpCode": 30,' +
                    '"SlpName": "Aga Doe",' +
                    '"CustomerOwnershipType": "Non- Profit Corporation",' +
                    '"InBusinessSince": "1971",' +
                    '"TaxExemptAccount": "N",' +
                    '"FederalTaxIdNumber": "00-2222",' +
                    '"OrderConfirmationEmail": "purchasing2@gmail.com",' +
                    '"SendingInvoicesEmail": "purchasing2@gmail.com",' +
                    '"DeliveryNotificationEmail": "",' +
                    '"SPSSendPOAck": "N",' +
                    '"SPSSendInvoice": "N",' +
                    '"SPSSendASN": "N",' +
                    '"SPSOrderStandAlone": "N"' +
                    '}' + 
                ']';
    }
}