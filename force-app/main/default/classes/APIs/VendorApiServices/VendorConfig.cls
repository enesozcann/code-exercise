/**
 * Author: Enes Ozcan
 * @description VendorConfig
 * @Date 15 September 2025
 */
public with sharing class VendorConfig {
    private static Map<String, VendorConfig__mdt> vendorConfigCache;
    @TestVisible private static VendorConfig__mdt testConfig;

    /**
     * @description loadCache
     * @Date 15 September 2025
     * @return void
     */
    private static void loadCache() {
        if (vendorConfigCache == null) {
            vendorConfigCache = new Map<String, VendorConfig__mdt>();
            for (VendorConfig__mdt cfg : [
                SELECT MasterLabel,VendorId__c, Endpoint__c, AuthToken__c, AuthType__c, Timeout__c
                FROM VendorConfig__mdt
            ]) {
                vendorConfigCache.put(cfg.VendorId__c, cfg);
            }
        }
    }

    /**
     * @description getConfig
     * @Date 15 September 2025
     * @param vendorId Id
     * @return VendorConfig__mdt
     */
    public static VendorConfig__mdt getConfig(Id vendorId) {
        if (Test.isRunningTest() && testConfig != null) {
            return testConfig;
        }
        loadCache();
        return vendorConfigCache.get(String.valueOf(vendorId));
    }

    /**
     * @description refreshCache
     * @Date 15 September 2025
     * @return void
     */
    public static void refreshCache() {
        vendorConfigCache = null;
        loadCache();
    }
}