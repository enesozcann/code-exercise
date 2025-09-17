@isTest
private class CaseValidationHelperTest {
    @IsTest
    static void testBeforeUpdateValidator() {
        // create a new case with valid values
        List<Case> cases = TestDataFactory.createCaseBase(1, 'New', 'Web', false);
        insert cases;
        Map<Id, Case> oldMap = new Map<Id,Case>(cases);
        // update the case with invalid values
        for (Case c : cases) {
            c.Status = 'Submit to Vendor';
        }

        // update
        try {
            update cases;
        } catch (Exception ex) {
            System.debug(ex);
        }

        List<Case>  casesForTest = [SELECT Id, Status FROM Case WHERE Status = 'Submit to Vendor' LIMIT 1];

        // check that the case has errors
        System.assertEquals(0, casesForTest.size(), 'Status changed to Submit to Vendor!');
    }
}