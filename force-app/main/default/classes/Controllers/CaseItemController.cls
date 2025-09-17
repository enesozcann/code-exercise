/**
 * Author: Enes Ozcan
 * @description CaseItemController
 * @Date 16 September 2025
 */
public with sharing class CaseItemController {
    @AuraEnabled(cacheable=true)
    /**
     * @description listCaseItems
     * @Date 16 September 2025
     * @param caseId Id
     * @return List<CaseItem__c>
     */
    public static List<CaseItem__c> listCaseItems(Id caseId) {
        return [
            SELECT Id, Case__c, Product__c, Product__r.Name, Product__r.ProductCode, Quantity__c
            FROM CaseItem__c
            WHERE Case__c = :caseId
            ORDER BY CreatedDate DESC
        ];
    }
}
