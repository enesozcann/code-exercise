public with sharing class VendorXApi implements VendorService {
    /**
     * @param Case Send Case with Address and Contact informations
     * @param List<CaseItem> Send list of related Case Item
     */
    public HttpRequest buildRequest(Case c, List<CaseItem__c> caseItems, String correlationId){
        HttpRequest req = new HttpRequest();

        VendorConfig__mdt cfg = VendorConfig.getConfig(c.Vendor__c);

        req.setEndpoint(cfg.Endpoint__c);
        req.setMethod('POST');
        req.setHeader('Authorization', cfg.AuthType__c + cfg.AuthToken__c);
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('X-Correlation-Id', correlationId);
        
        // even address informations null continue process
        if(String.isBlank(c.Account.Name) || String.isBlank(c.Account.BillingStreet)
        || String.isBlank(c.Account.BillingCity) || String.isBlank(c.Account.BillingState)
        || String.isBlank(c.Account.BillingPostalCode) || String.isBlank(c.Account.BillingCountry)
        ) System.debug('Account Address informations are null!');

        try {
            //build address sent data even Contact informations are null!
            Map<String, Object> address = new Map<String, Object>();
            address.put('CompanyName', c.Account.Name);
            address.put('FirstName', c.Contact?.FirstName ?? '');
            address.put('LastName', c.Contact?.LastName ?? '');
            address.put('Phone', c.Contact?.Phone ?? '');
            address.put('Street', c.Account.BillingStreet);
            address.put('City', c.Account.BillingCity);
            address.put('State', c.Account.BillingState);
            address.put('PostalCode', c.Account.BillingPostalCode);
            address.put('Country', c.Account.BillingCountry);
            
            // build Case Items
            List<Map<String, Object>> items = new List<Map<String,  Object>>();
            for (CaseItem__c caseItem : caseItems) {
                Map<String, Object> itemMap = new Map<String, Object>();
                itemMap.put('ProductCode', caseItem.Product__r.ProductCode);
                itemMap.put('Quantity', Integer.valueOf(caseItem.Quantity__c));
                items.add(itemMap);
            }

            // build payload
            Map<String, Object> payload = new Map<String, Object>();
            payload.put('Address', address);
            payload.put('Items', items);


            req.setBody(JSON.serialize(payload));
        } catch (Exception ex) {
            throw new VendorXApiException(ex.getMessage());
        }
        return req;
    }

    public VendorResponseWrapper handleResponse(HttpResponse res, Id caseId){
        VendorResponseWrapper wrapper = new VendorResponseWrapper();
        if(res.getStatusCode() == 200) {
            Map<String,Object> body = (Map<String,Object>)JSON.deserializeUntyped(res.getBody());
            String orderId = (String) body.get('Order_Id');
            wrapper.orderId = orderId;
            wrapper.isSuccess = true;
            return wrapper;
        // add different responses for Http Status code
        } else {
            // log
            wrapper.errorMessage = 'An error occurred while making request to VendorApi';
            wrapper.isSuccess= false;
        }
        return wrapper;
    }

    private class VendorXApiException extends Exception{}
}