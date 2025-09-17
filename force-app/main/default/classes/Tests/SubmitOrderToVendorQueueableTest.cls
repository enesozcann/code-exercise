@isTest
public class SubmitOrderToVendorQueueableTest {
    @TestSetup
    static void makeData(){
        // activate Pricebook
        Id standardPricebookId = Test.getStandardPricebookId();
        Pricebook2 standardPricebook = new Pricebook2(Id = standardPricebookId, IsActive = true);
        
        update standardPricebook;

        // create account + contact
        Account vendorAcc = TestDataFactory.createAccountBase(1,'VendorX','Vendor',false)[0];
        insert vendorAcc;

        Account acc = TestDataFactory.createAccountBase(1, 'AccTest', 'Customer', false)[0];
        insert acc;

        Contact con = TestDataFactory.createContactBase(1, 'ContTest', acc.Id, false)[0];
        insert con;

        // Case
        Case c = TestDataFactory.createCaseBase(1, 'New', 'Phone', false)[0];
        c.AccountId = acc.Id;
        c.ContactId = con.Id;
        c.Vendor__c = vendorAcc.Id;
        insert c;

        // create Product + Pricebook        
        Product2 p = TestDataFactory.createProduct('Test Product');
        PricebookEntry pbe = TestDataFactory.createPricebookEntry(p, standardPricebookId, 100);

        // create CaseItem
        CaseItem__c ci = TestDataFactory.createCaseItem(1, c.Id, 2, p.Id, false)[0];
        insert ci;
    }

    // create test for negative and bulky scenarios. 
    @isTest
    static void testQueueableSuccess() {
        // disable trigger to prevent multiple enqueueJobs
        CaseTriggerHandler.disableBeforeUpdate = true;
        
        // get Case

        Case c= [SELECT Id, Status, Vendor__c, VendorSubmissionDate__c, VendorSubmissionStatus__c, AccountId, ContactId FROM Case LIMIT 1][0];
        c.Status = 'Submit to Vendor';
        update c;

        // VendorConfig override
        VendorConfig.testConfig = (VendorConfig__mdt) JSON.deserialize(
            JSON.serialize(new Map<String, Object>{
                'MasterLabel' => 'VendorX',
                'VendorId__c' => c.Vendor__c,
                'Endpoint__c' => 'https://mock.endpoint',
                'AuthToken__c' => 'x1223fdfsdf',
                'AuthType__c'  => 'Bearer',
                'Timeout__c'   => 120
            }),
            VendorConfig__mdt.class
        );
        
        // run Queueable
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new VendorHttpMockSuccess());
        System.enqueueJob(new SubmitOrderToVendorQueueable(new List<Id>{c.Id}, 0, 50));
        Test.stopTest();

        // assert Case updated
        c = [SELECT VendorSubmissionStatus__c FROM Case WHERE Id = :c.Id];
        System.assertEquals('Submitted', c.VendorSubmissionStatus__c);

        // assert Order
        Order o = [SELECT Id, Status, ExternalOrderId__c FROM Order WHERE Case__c = :c.Id LIMIT 1];
        System.assertEquals('Activated', o.Status);
        System.assertNotEquals(null, o.ExternalOrderId__c);

        // assert OrderItem
        System.assertEquals(1, [SELECT COUNT() FROM OrderItem WHERE OrderId = :o.Id]);

        // assert Integration Log
        System.assertEquals(1, [SELECT COUNT() FROM IntegrationLog__c WHERE Case__c = :c.Id]);
    }
}


