@isTest
public class MOCK_SAP_NoAuthResponse implements HttpCalloutMock{
    public HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('No Auth');
        res.setStatusCode(HttpStatusCode.BAD_REQUEST);
        return res;
    }
}