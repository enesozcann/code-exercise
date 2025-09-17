/**
 * Author: Enes Ozcan
 * @description CaseTriggerHandler
 * @note For future extend from Trigger Framework
 * @Date 15 September 2025
 */
public with sharing class OrderTriggerHandler {
    @TestVisible private static Boolean afterInsertRunning = false;
    @TestVisible private static Boolean afterUpdateRunning = false;

    /**
     * @description handleAfterUpdate
     * @Date 15 September 2025
     * @param newList List<Order>
     * @param oldMap Map<Id,Order>
     * @return void
     */
    public static void handleAfterUpdate(List<Order> newList, Map<Id,Order> oldMap){
        if (afterUpdateRunning) return;
        afterUpdateRunning = true;
        try {
            // update Case Status to Order Created
            List<Order> ordersToSetCaseStatus = OrderTriggerHandlerHelper.getActivatedOrdersIfExternalIdNotNull(newList, oldMap);
            Map<Id, String> caseIdStatus = new Map<Id, String>();
            if(!ordersToSetCaseStatus.isEmpty()){
                for (Order order : ordersToSetCaseStatus) {
                    caseIdStatus.put(order.Case__c, 'Order Created');
                }
            }
            CaseService.updateCaseStatusByCaseId(caseIdStatus);
        } finally {
            afterUpdateRunning = false;
        }
    }
}