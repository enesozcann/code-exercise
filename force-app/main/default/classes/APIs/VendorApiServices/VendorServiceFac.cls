/**
 * @description VendorServiceFac
 * @Date 15 September 2025
 */
public with sharing class VendorServiceFac {
    /**
     * @description getService
     * @Date 15 September 2025
     * @param vendorCode String
     * @return VendorService
     */
    public static VendorService getService(String vendorCode) {
        switch on vendorCode {
            when 'VendorX' { return new VendorXApi(); }
            when else { throw new VendorServiceFacException('Vendor is not supported!'); }
        }
    }

    public class VendorServiceFacException extends Exception{

    }
}

