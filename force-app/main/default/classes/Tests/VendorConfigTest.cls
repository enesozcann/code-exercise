@IsTest(SeeAllData=true)
/**
 * @description VendorConfigTest
 * @Date 15 September 2025
 */
private class VendorConfigTest {

    @IsTest
    static void testGetConfigAndCache() {
        // query sample vendor config metadata
        VendorConfig__mdt cfg = [
            SELECT VendorId__c, Endpoint__c 
            FROM VendorConfig__mdt 
            LIMIT 1
        ];

        Test.startTest();
        // call first time to trigger cache load
        VendorConfig__mdt firstCall = VendorConfig.getConfig(cfg.VendorId__c);
        
        // call second time should come from cache
        VendorConfig__mdt secondCall = VendorConfig.getConfig(cfg.VendorId__c);
        Test.stopTest();

        System.assertEquals(firstCall, secondCall, 'config should be consistent from cache');
    }

    @IsTest
    static void testRefreshCache() {
        // query sample vendor config metadata
        VendorConfig__mdt cfg = [
            SELECT VendorId__c 
            FROM VendorConfig__mdt 
            LIMIT 1
        ];

        // load config before refresh
        VendorConfig__mdt beforeRefresh = VendorConfig.getConfig(cfg.VendorId__c);
        
        // refresh cache
        VendorConfig.refreshCache();
        
        // load config after refresh
        VendorConfig__mdt afterRefresh = VendorConfig.getConfig(cfg.VendorId__c);
        
        System.assertEquals(beforeRefresh, afterRefresh, 'config should be same after refresh');
    }

    @IsTest
    static void testInvalidVendorId() {
        Id fakeId = '001000000000000AAA'; 
        
        VendorConfig__mdt result = VendorConfig.getConfig(fakeId);
        System.assertEquals(null, result, 'should return null for non-existing vendor id');
    }

}
