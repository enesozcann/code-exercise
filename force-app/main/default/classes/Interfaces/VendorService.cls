public interface VendorService {
    HttpRequest buildRequest(Case c, List<CaseItem__c> caseItems, String correlationId);
    VendorResponseWrapper handleResponse(HttpResponse res, Id caseId);
}