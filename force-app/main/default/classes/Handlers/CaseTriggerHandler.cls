/**
 * Author: Enes Ozcan
 * @description CaseTriggerHandler
 * @note For future extend from Trigger Framework
 * @Date 13 September 2025
 */
public with sharing class CaseTriggerHandler {
    // static variable to prevent recursion across multiple trigger executions
    @TestVisible private static Boolean beforeUpdateRunning = false;
    @TestVisible private static Boolean afterUpdateRunning  = false;
    @TestVisible private static Boolean disableBeforeUpdate = false;
    /**
     * @description handleBeforeUpdate
     * @Date 13 September 2025
     * @param newList List<Case>
     * @param oldMap Map<Id, Case>
     * @return void
     */
    public static void handleBeforeUpdate(List<Case> newList, Map<Id, Case> oldMap){ 
        if (beforeUpdateRunning) return;          
        beforeUpdateRunning = true;     
        try {
            // Set VendorSubmissionStatus if Status changed to Submit to Vendor!
            CaseTriggerHandlerHelper.setVendorSubmissionStatusByStatus(newList, oldMap,'Submit to Vendor' ,'Submission in Progress');        
            // handle beforeUpdate validations
            CaseValidationHelper.beforeUpdateValidator(newList, oldMap); 
        } finally {
            beforeUpdateRunning = false;
        }
    }


    /**
     * @description handleAfterUpdate
     * @Date 13 September 2025
     * @param newList List<Case>
     * @param oldMap Map<Id, Case>
     * @return void
     */
    public static void handleAfterUpdate(List<Case> newList, Map<Id, Case> oldMap) {
        // prevent recursion in the same transaction
        if (afterUpdateRunning) return;   
        if(disableBeforeUpdate) return;     
        afterUpdateRunning = true;
        
        try {
            // get cases if status changed to "Submit to Vendor"
            List<Id> candidateIds = new List<Id>(CaseTriggerHandlerHelper.getCaseIdsByNewStatus(newList, oldMap, 'Submit to Vendor'));
            if(!candidateIds.isEmpty()){
            System.enqueueJob(new SubmitOrderToVendorQueueable(
                            candidateIds, 0, 90
                        ));
            }
        } finally {
            afterUpdateRunning = false;
        }
    }
}