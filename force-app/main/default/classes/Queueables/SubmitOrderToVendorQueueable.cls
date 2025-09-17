/**
 * Author: Enes Ozcan
 * @description IMPORTANT: chunkSize must be lower than 100 because of the HttpRequest limit!
 * @Date 14 September 2025
 */
public with sharing class SubmitOrderToVendorQueueable implements Queueable, Database.AllowsCallouts {
    List<Id> caseIds;
    Integer startIndex;
    Integer chunkSize;
    List<IntegrationLog__c> logsToInsert;
    static final String STATUS_SUBMIT_TO_VENDOR = 'Submit to Vendor';
    static final String SUBMISSION_SUBMITTED    = 'Submitted';
    static final String SUBMISSION_REJECTED     = 'Rejected by Vendor';
    static final String SUBMISSION_FAILED       = 'Failed';
    static final String CASE_STATUS_ESCALATED   = 'Escalated';

    public SubmitOrderToVendorQueueable(List<Id> caseIds, Integer startIndex, Integer chunkSize) {
        this.caseIds = caseIds;
        this.startIndex = startIndex;
        this.chunkSize = chunkSize;
        this.logsToInsert = new List<IntegrationLog__c>();
    }

    public void execute(QueueableContext context){   
        try {
            if(caseIds == null || caseIds.isEmpty()) return;
            // Create chunk to proccess
            Set<Id> currentChunk = new Set<Id>();
            Integer endIndex = Math.min(startIndex + chunkSize, caseIds.size());
            for (Integer i = startIndex; i < endIndex; i++) {
                currentChunk.add(caseIds[i]);
            }
            // end creation of chunk

            // get Map<Id,Case> of Cases to proccess, lock rows to avoid race conditions! 
            Map<Id, Case> cases = loadCases(currentChunk);

            // get List of Case Items, lock rows
            List<CaseItem__c> caseItems = loadCaseItems(cases.keyset());

            // group by case
            Map<Id, List<CaseItem__c>> caseItemsByCase = groupByCase(caseItems);

            // check records again before proccess. race condition
            List<Case> processableCases = filterProcessable(cases, caseItemsByCase);

            if(processableCases == null || processableCases.isEmpty()) return;

            // call vendor service and update cases
            Map<String,Case> updatedCasesWithOrderId = calloutVendorService(processableCases, caseItemsByCase);

            // create orders with updatedCases
            List<Order> createdOrders = OrderService.createOrders(updatedCasesWithOrderId);

            // create OrderItems with createdOrders
            List<OrderItem> createdOrderItems = OrderService.createOrderItems(createdOrders);

            // update Order's Status to Activate
            updateOrderStatus(createdOrders);

            // check if there is non processed ids and chain them with a new job
            if(endIndex < caseIds.size()){
                System.enqueueJob(new SubmitOrderToVendorQueueable(caseIds, endIndex, chunkSize));
            }

        } catch (Exception ex) {
            IntegrationLog__c globalLog = new IntegrationLog__c();
            globalLog.ErrorMessage__c   = 'Queueable failed: ' + ex.getMessage();
            globalLog.CompletedOn__c    = Datetime.now();
            logsToInsert.add(globalLog);
            System.debug('SubmitOrderToVendorQueueable failed: ' + ex.getMessage());
        }
        finally{
            Database.insert(logsToInsert,false);
        }
    }

    /**
     * @description updateOrderStatus
     * @Date 16 September 2025
     * @param orders List<Order>
     * @return void
     */
    private void updateOrderStatus(List<Order> orders){
        for (Order o : orders) {
            o.Status = 'Activated';
            o.ActivatedDate = Date.today();
        }
        OrderService.updateOrders(orders);
    }

    /**
     * @description calloutVendorService
     * @Date 16 September 2025
     * @param cases List<Case>
     * @param caseItemsByCase List<Id,CaseItem__c>
     * @return void
     */
    private Map<String,Case> calloutVendorService(List<Case> cases, Map<Id,List<CaseItem__c>> caseItemsByCase){
        Map<String,Case> successes = new Map<String,Case>();
        // call Vendor Service for each Case
        for (Case c : cases) {
            // create CorrelationId for HttpRequest
            String correlationId = String.valueOf(UUID.randomUUID());

            // get configs
            VendorConfig__mdt cfg = VendorConfig.getConfig(c.Vendor__c);
            if (cfg == null) {
                System.debug('No config for vendor ' + c.Vendor__c);
                continue;
            }

            // build log for integration
            IntegrationLog__c log = new IntegrationLog__c();
            log.Case__c = c.Id;
            log.CorrelationId__c = correlationId;
            log.RequestedOn__c = Datetime.now();

            try {
                VendorService service = VendorServiceFac.getService(cfg.MasterLabel);
                HttpRequest req = service.buildRequest(c, caseItemsByCase.get(c.Id), correlationId);
                
                Http http = new Http();
                // enrich log
                log.IntegrationName__c = String.valueOf(service);
                log.Endpoint__c = req.getEndpoint();
                log.RequestPayload__c = req.getBody();

                HttpResponse res = http.send(req);
                VendorResponseWrapper wrappedResponse = service.handleResponse(res, c.Id);
                System.debug(wrappedResponse);
                // enrich log
                log.HttpStatusCode__c = res.getStatusCode();
                log.ResponsePayload__c = res.getBody();
                log.CompletedOn__c = Datetime.now();

                if (wrappedResponse.isSuccess) {
                    c.VendorSubmissionStatus__c = SUBMISSION_SUBMITTED;
                    c.VendorSubmissionDate__c = Datetime.now();
                    // add case to map with orderId if it's succeed
                    successes.put(wrappedResponse.orderId,c);
                    System.debug(successes);
                } else {
                    c.VendorSubmissionStatus__c = SUBMISSION_REJECTED;
                    c.Status = CASE_STATUS_ESCALATED;
                    c.Description = (c.Description != null ? c.Description : '') +
                                    ' Vendor Comment: ' + wrappedResponse.errorMessage;
                }
            } catch (Exception ex) {
                // log Callout errors
                System.debug('Exception dustu');
                log.ErrorMessage__c = ex.getMessage();
                log.CompletedOn__c = Datetime.now();

                c.VendorSubmissionStatus__c = SUBMISSION_FAILED;
                c.Status = CASE_STATUS_ESCALATED;
                System.debug('Case ' + c.Id + ' failed: ' + ex.getMessage());
            }
            finally{
                logsToInsert.add(log);
            }
        }
        // update cases
        Database.update(cases, false);
        return successes;
    }

    /**
     * @description loadCases
     * @Date 16 September 2025
     * @param currentChunk Set<Id>
     * @return Map<Id, Case>
     */
    private Map<Id, Case> loadCases(Set<Id> currentChunk) {
        // get Map<Id,Case> of Cases to proccess, lock rows to avoid race conditions! 
        return new Map<Id, Case>([
            SELECT Id, AccountId, ContactId, Status,
                   Vendor__c,
                   VendorSubmissionStatus__c, VendorSubmissionDate__c, 
                   Account.Name, 
                   Account.BillingStreet, 
                   Account.BillingCity,
                   Account.BillingState, 
                   Account.BillingPostalCode, 
                   Account.BillingCountry,
                   Contact.FirstName, Contact.LastName, Contact.Phone
            FROM Case
            WHERE Id IN :currentChunk AND Status = :STATUS_SUBMIT_TO_VENDOR
            WITH SECURITY_ENFORCED
            FOR UPDATE
        ]);
    }

    /**
     * @description loadCaseItems
     * @Date 16 September 2025
     * @param caseIdSet Set<Id>
     * @return List<CaseItem__c>
     */
    private List<CaseItem__c> loadCaseItems(Set<Id> caseIdSet) {
        // get List of Case Items, lock rows
        return [
            SELECT Id, Case__c, Product__c, Product__r.ProductCode, Quantity__c
            FROM CaseItem__c
            WHERE Case__c IN :caseIdSet
            WITH SECURITY_ENFORCED
            FOR UPDATE
        ];
    }

    /**
     * @description groupByCase
     * @Date 16 September 2025
     * @param caseItems List<CaseItem__c>
     * @return Map<Id, List<CaseItem__c>>
     */
    private Map<Id, List<CaseItem__c>> groupByCase(List<CaseItem__c> caseItems) {
        // group by case
        Map<Id, List<CaseItem__c>> caseItemsByCase = new Map<Id, List<CaseItem__c>>();
        for (CaseItem__c caseItem : caseItems) {
            List<CaseItem__c> bucket = caseItemsByCase.get(caseItem.Case__c);
            if (bucket == null) { bucket = new List<CaseItem__c>(); caseItemsByCase.put(caseItem.Case__c, bucket); }
            bucket.add(caseItem);
        }
        return caseItemsByCase;
    }

    /**
     * @description filterProcessable
     * @Date 16 September 2025
     * @param cases Map<Id, Case>
     * @param caseItemsByCase Map<Id, List<CaseItem__c>>
     * @return List<Case>
     */
    private List<Case> filterProcessable(Map<Id, Case> cases, Map<Id, List<CaseItem__c>> caseItemsByCase) {
        // check records again before proccess. race condition
        List<Case> filtered = new List<Case>();
        for (Case c : cases.values()) {
            List<CaseItem__c> itemsOfCurrentCase = caseItemsByCase.get(c.Id);
            if(c.Status == 'Submit to Vendor' && itemsOfCurrentCase != null && !itemsOfCurrentCase.isEmpty()){
                filtered.add(c);
            }
        }
        return filtered;
    }
}