@isTest
global class VendorHttpMockSuccess implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setStatusCode(200);
        res.setBody('{"Order_Id": "801Ea00000mablPIAQ"}');
        return res;
    }
}