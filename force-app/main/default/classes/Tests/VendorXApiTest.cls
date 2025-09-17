@isTest
private class VendorXApiTest {
    @IsTest
    static void testHandleResponse() {
        Test.startTest();
        VendorXApi api = new VendorXApi();
        HttpResponse res = new HttpResponse();
        res.setStatusCode(200);
        res.setBody('{"Order_Id": "12345"}');
        VendorResponseWrapper wrapper = api.handleResponse(res, null);
        Test.stopTest();

        System.assertEquals('12345', wrapper.orderId);
        System.assertEquals(true, wrapper.isSuccess);
    }
}