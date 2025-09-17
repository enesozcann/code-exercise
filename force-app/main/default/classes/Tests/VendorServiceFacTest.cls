/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an org are executed whenever Apex code is deployed
 * to a production org to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production org. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the org size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@IsTest
private class VendorServiceFacTest {

    @IsTest
    static void testGetServiceWithValidVendor() {
        // call factory with supported vendor
        VendorService service = VendorServiceFac.getService('VendorX');

        System.assertNotEquals(null, service, 'Service should not be null for VendorX');
        System.assertEquals('VendorXApi:[]', String.valueOf(String.valueOf(service)), 'Should return VendorXApi implementation');
    }

    @IsTest
    static void testGetServiceWithInvalidVendor() {
        try {
            // call factory with unsupported vendor
            VendorServiceFac.getService('UnknownVendor');
            System.assert(false, 'Exception should have been thrown for invalid vendor');
        } catch (VendorServiceFac.VendorServiceFacException ex) {
            System.assertEquals('Vendor is not supported!', ex.getMessage(), 'Exception message should match');
        }
    }
}
