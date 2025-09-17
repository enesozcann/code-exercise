/**
 * Author: Enes Ozcan
 * @description TestDataFactory
 * @Date 15 September 2025
 */
@isTest
public with sharing class TestDataFactory {
    static Integer count = 0;
    /**
     * @description getFakeId by giving Schema.SObjectType
     * @Date 15 September 2025
     * @param objectType Schema.SObjectType
     * @return String
     */    
    public static String getFakeId(Schema.SObjectType objectType){
        // example Case.Id format  500 + 0000000000 + num(3 digits <0) + AAA
        String idNum = String.valueOf(count++);
        String suffix = '0'.repeat(12-idNum.length()) + idNum;
        return objectType.getDescribe().getKeyPrefix() + suffix;
    }

    public static List<Case> createCaseBase(Integer count, String status, String origin, Boolean fakeId){
        List<Case> cases = new List<Case>();
        for (Integer i = 0; i < count; i++) {
            cases.add(new Case(
                Id = fakeId ? (Id) TestDataFactory.getFakeId(Case.getSObjectType()) : null,
                Status = status,
                Origin = origin,
                VendorSubmissionStatus__c = null
            ));
        }
        return cases;
    }

    public static List<CaseItem__c> createCaseItem(Integer count, Id caseId, Integer quantity, Id product2Id, Boolean fakeId){
        List<CaseItem__c> caseItems = new List<CaseItem__c>();
        for (Integer i = 0; i < count; i++) {
            caseItems.add(
                new CaseItem__c (
                    Id = fakeId ? (Id) TestDataFactory.getFakeId(CaseItem__c.getSObjectType()) : null,
                    Case__c = caseId,
                    Product__c = product2Id,
                    Quantity__c = quantity
                )
            );
        }
        return caseItems;
    }

    public static List<Account> createAccountBase(Integer count, String name, String type, Boolean fakeId){
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < count; i++) {
            accounts.add(
                new Account(
                    Id = fakeId ? (Id) getFakeId(Account.getSObjectType()) : null,
                    Name = name,
                    Type = type
                )
            );
        }
        return accounts;
    }   

    public static List<Contact> createContactBase(Integer count, String lastName, String accountId, Boolean fakeId){
        List<Contact> accounts = new List<Contact>();
        for (Integer i = 0; i < count; i++) {
            accounts.add(
                new Contact(
                    Id = fakeId ? (Id) getFakeId(Contact.getSObjectType()) : null,
                    LastName = lastName,
                    AccountId = accountId
                )
            );
        }
        return accounts;
    }  
    
    public static Product2 createProduct(String name){
        Product2 p = new Product2(Name = name, ProductCode = 'P-' + String.valueOf(Math.random()), isActive = true);
        insert p;
        return p;
    }

    public static PricebookEntry createPricebookEntry(Product2 product, Id pricebookId, Decimal unitPrice){
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id = product.Id,
            UnitPrice = unitPrice,
            IsActive = true
        );
        insert pbe;
        return pbe;
    }
}