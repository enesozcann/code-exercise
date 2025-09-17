/**
 * Author: Enes Ozcan
 * @description CaseValidationHelper
 * @Date 14 September 2025
 */
public with sharing class CaseValidationHelper {
    private final static string SubmitStatus = 'Submit to Vendor';
    /**
     * @description beforeUpdateValidator
     * @Date 14 September 2025
     * @param newList List<Case>
     * @param oldMap Map<Id, Case>
     * @return void
     */
    public static void beforeUpdateValidator(List<Case> newList,Map<Id, Case> oldMap){
        if (newList == null || newList.isEmpty()) return;

        // validate new records
        // get Ids if Status updated to "Submit to Vendor"
        Set<Id> prepareCaseIds = new Set<Id>();
        for (Case c : newList) {
            // get Cases if just changed to Submit to Vendor
            Case oldCase = oldMap != null ? oldMap.get(c.Id) : null;
            if (c.Status == SubmitStatus && (oldCase == null || oldCase.Status != SubmitStatus)) {
                prepareCaseIds.add(c.Id);
            }

        }
        if (prepareCaseIds.isEmpty()) return;

        // get Case Ids if has atleast one Case Item
        Set<Id> casesWithCaseItems = CaseService.getCasesIfHasCaseItemAgg(prepareCaseIds);

        // block if Case doesn't have any Case Item
        Set<Id> blockIds = new Set<Id>(prepareCaseIds);
        blockIds.removeAll(casesWithCaseItems);

        // block invalid ones
        if (!blockIds.isEmpty()) {
            for (Case c : newList) {
                if (blockIds.contains(c.Id)) {
                    c.addError('You can not choose Submit to Vendor while Case Items are empty.');
                }
            }
        }
    }
}
