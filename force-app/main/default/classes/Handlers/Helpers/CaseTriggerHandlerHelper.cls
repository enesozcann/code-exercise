/**
 * Author Enes Ozcan
 * @description CaseTriggerHandlerHelper
 * @Date 14 September 2025
 */
public inherited sharing class CaseTriggerHandlerHelper {

    /**
     * @description getCaseIdsByNewStatus
     * @Date 14 September 2025
     * @param newList List<Case>
     * @param oldMap Map<Id, Case>
     * @param newStatus String
     * @return Set<Id>
     */
    public static Set<Id> getCaseIdsByNewStatus(List<Case> newList, Map<Id, Case> oldMap, String newStatus){
            Set<Id> ids = new Set<Id>();
            
            // null check
            if(newList == null || oldMap == null || String.isBlank(newStatus)) return ids;
            
            for (Case c : newList) {
                Case oldC = oldMap.get(c.Id);
                Boolean statusChangedToSubmit = c.Status == newStatus &&
                    (oldC == null || oldC.Status != newStatus);
                if (statusChangedToSubmit) {
                    ids.add(c.Id);
                }
            }
            return ids;
    }

    /**
     * @description setVendorSubmissionStatusByStatus
     * @Date 14 September 2025
     * @param newList List<Case>
     * @param oldMap Map<Id,Case>
     * @param status String
     * @param vendorStatus String
     * @return void
     */
    public static void setVendorSubmissionStatusByStatus(List<Case> newList, Map<Id,Case> oldMap,String status, String vendorStatus){

        if(newList == null || oldMap == null || String.isBlank(status) || String.isBlank(vendorStatus)) return;

        for (Case c : newList) {
            if(c.Status == status && c.Status != oldMap.get(c.Id).Status){
                c.VendorSubmissionStatus__c = vendorStatus;
            }
        }
    }
}