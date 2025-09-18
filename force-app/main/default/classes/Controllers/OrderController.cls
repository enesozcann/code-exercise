public with sharing class OrderController {
    @AuraEnabled(cacheable=true)
    public static Order getOrderByCase(Id caseId) {
        return [
            SELECT Id, OrderNumber, Status
            FROM Order
            WHERE Case__c = :caseId
            LIMIT 1
        ];
    }
}
