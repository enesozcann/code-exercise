/**
 * Author: Enes Ozcan
 * @description CaseService
 * @Date 14 September 2025
 */
public with sharing class CaseService {
    /**
     * @description Returns the set of Case Ids if have ≥ 1 CaseItem.
     * @Date 14 September 2025
     * @param caseIds Set<Id>
     * @return Set<Id>
     */
    public static Set<Id> getCasesIfHasCaseItemAgg(Set<Id> caseIds){
        System.debug('CaseService.getCasesIfHasCaseItemAgg called with ' + caseIds);
        Set<Id> casesWithCaseItems = new Set<Id>();
        // check caseIds is null
        if (caseIds == null || caseIds.isEmpty()) return casesWithCaseItems;
        
        for (AggregateResult ar : [
            SELECT Case__c cId, COUNT(Id) cnt
            FROM CaseItem__c
            WHERE Case__c IN :caseIds
            GROUP BY Case__c
            HAVING COUNT(Id) > 0
        ]) {
            casesWithCaseItems.add((Id) ar.get('cId'));
        }
        return casesWithCaseItems;
    }

    /**
     * @description Returns List of CaseItem__c by giving CaseIds
     * @Date 14 September 2025
     * @param caseIds Set<Id>
     * @return List<CaseItem__c>
     */
    public static List<CaseItem__c> getCaseItemsByCaseId(Set<Id> caseIds){
        System.debug('CaseService.getCaseItemsByCaseId called with ' + caseIds);
        return [SELECT Id, Case__c, Quantity__c, Product__c FROM CaseItem__c 
        WHERE Case__c IN :caseIds WITH SECURITY_ENFORCED];
    }

    /**
     * @description updateCaseStatusByCaseId
     * @Date 15 September 2025
     * @param caseIdStatus Map<Id, String>
     * @return void
     */
    public static void updateCaseStatusByCaseId(Map<Id, String> caseIdStatus){
        List<Case> cases = [SELECT Id, Status FROM Case WHERE Id IN :caseIdStatus.keySet() WITH SECURITY_ENFORCED];
        List<Case> casesForUpdate = new List<Case>();
        for (Case c : cases) {
            String newStatus = caseIdStatus.get(c.Id);
            if(c.Status != newStatus){
                c.Status = newStatus;
                casesForUpdate.add(c);
            }
        }
        Database.SaveResult[] results = Database.update(casesForUpdate,false);
        for (Integer i = 0; i < results.size(); i++) {
            if (!results[i].isSuccess()) {
                System.debug('Failed to update Case with Status: ' + results[i].getErrors()[0].getMessage());
            }
        }
    }

    public static void updateCase(List<Case> cases){
        if(cases == null || cases.isEmpty()) return;

        Database.SaveResult[] results = Database.update(cases,false);
        for (Integer i = 0; i < results.size(); i++) {
            if (!results[i].isSuccess()) {
                System.debug('Failed to update Case: ' + results[i].getErrors()[0].getMessage());
            }
        }
    }
}