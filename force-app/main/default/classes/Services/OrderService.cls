/**
 * Author: Enes Ozcan
 * @description OrderService
 * @Date 15 September 2025
 */
public with sharing class OrderService {
    /**
     * @description Create order from giving case
     * @Date 15 September 2025
     * @param cases List<Case>
     * @return List<Order>
     */
    public static List<Order> createOrders(Map<String,Case> casesWithOrderId){
        if(casesWithOrderId == null || casesWithOrderId.isEmpty()) throw new OrderServiceException('You must pass cases for the create orders');

        Id standardPricebookId;

        if (Test.isRunningTest()) {
            standardPricebookId = Test.getStandardPricebookId();
        } else {
            standardPricebookId = [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1].Id;
        }        
        List<Order> ordersToCreate = new List<Order>();
        for (String orderId : casesWithOrderId.keySet()) {
            Case c = casesWithOrderId.get(orderId);
            // for order only fill required fields in this case!
            Order orderToCreate = new Order();
            orderToCreate.Case__c = c.Id;
            orderToCreate.AccountId = c.AccountId;
            orderToCreate.Vendor__c = c.Vendor__c;
            orderToCreate.Status = 'Draft';
            orderToCreate.EffectiveDate = Date.today();
            orderToCreate.CustomerAuthorizedById = c.ContactId;
            orderToCreate.Pricebook2Id = standardPricebookId;
            // set Shipping
            orderToCreate.ShippingCity = c.Account.BillingCity;
            orderToCreate.ShippingCountry = c.Account.BillingCountry;
            orderToCreate.ShippingState = c.Account.BillingState;
            orderToCreate.ShippingStreet = c.Account.BillingStreet;
            orderToCreate.ShippingPostalCode = c.Account.BillingPostalCode;
            // set Billing
            orderToCreate.BillingCity = c.Account.BillingCity;
            orderToCreate.BillingCountry = c.Account.BillingCountry;
            orderToCreate.BillingState = c.Account.BillingState;
            orderToCreate.BillingStreet = c.Account.BillingStreet;
            orderToCreate.BillingPostalCode = c.Account.BillingPostalCode;
            // set order id
            orderToCreate.ExternalOrderId__c = orderId;
            // add to list
            ordersToCreate.add(orderToCreate);         
        }
        // create orders
        if(!ordersToCreate.isEmpty()){
            Database.SaveResult[] results = Database.insert(ordersToCreate, false);
            for (Integer i = 0; i < results.size(); i++) {
                if (!results[i].isSuccess()) {
                    System.debug('Failed to insert Order: ' + results[i].getErrors()[0].getMessage());
                }
            }
        }
        return ordersToCreate;
        
    }

    /**
     * @description Create Order Items by giving Orders. Order Items fetch from CaseItem__c
     * @Date 15 September 2025
     * @param orders List<Order>
     * @return List<OrderItems>
     */
    public static List<OrderItem> createOrderItems(List<Order> orders) {
        if (orders == null || orders.isEmpty()) throw new OrderServiceException('You must pass orders for the create order items');

         // get CaseIds
        Set<Id> caseIds = new Set<Id>();
        Map<Id, Order> orderByCaseId = new Map<Id, Order>();

        for (Order o : orders) {
            if (o.Case__c != null) {
                caseIds.add(o.Case__c);
                orderByCaseId.put(o.Case__c, o);
            }
        }
            
        if (caseIds.isEmpty()) throw new OrderServiceException('We couldn\'t get any cases related to orders');
        System.debug('Get CaseIds for createOrderItems. Total Case:'+caseIds.size());
        // get CaseItems
        List<CaseItem__c> caseItems = CaseService.getCaseItemsByCaseId(orderByCaseId.keySet());
        
        if(caseItems.isEmpty()) throw new OrderServiceException('We couldn\'t get any case items related to cases');
        System.debug('Get CaseItems for createOrderItems. Total CaseItems:'+caseItems.size());

        // get ProductIds
        Set<Id> productIds = new Set<Id>();
        for (CaseItem__c ci : caseItems) {
            productIds.add(ci.Product__c);
        }

        // get PricebookEntries !n move it to Pricebook service later
        Map<Id, PricebookEntry> pbeMap = new Map<Id, PricebookEntry>();

        for (PricebookEntry pbe : [
            SELECT Id, Product2Id, UnitPrice
            FROM PricebookEntry
            WHERE Product2Id IN :productIds
            AND IsActive = true
            AND Pricebook2.IsActive = true
        ]) {
            // set map id as Product2Id
            pbeMap.put(pbe.Product2Id, pbe);
        }

        System.debug('Get PricebookEntries for createOrderItems. Total PricebookEntries:'+pbeMap.size());

        List<OrderItem> orderItemsToInsert = new List<OrderItem>();
        for (CaseItem__c caseItem : caseItems) {
            Order rOrder = orderByCaseId.get(caseItem.Case__c);
            System.debug('rOrder: ' + (rOrder != null ? rOrder.Id : 'NULL'));

            if (rOrder != null && rOrder.Id != null) {
                PricebookEntry pbe = pbeMap.get(caseItem.Product__c);
                System.debug('PricebookEntry: ' + pbe);
                if (pbe != null) {
                    OrderItem oItem = new OrderItem();
                    oItem.OrderId = rOrder.Id;
                    oItem.PricebookEntryId = pbe.Id;
                    oItem.Quantity = caseItem.Quantity__c;
                    oItem.UnitPrice = pbe.UnitPrice;
                    orderItemsToInsert.add(oItem);
                }
            }
        }
        
        System.debug('Total OrderItems count to insert:'+orderItemsToInsert.size());
        // insert
        if (orderItemsToInsert != null || !orderItemsToInsert.isEmpty()) {
            Database.SaveResult[] results = Database.insert(orderItemsToInsert, false);
            for (Integer i = 0; i < results.size(); i++) {
                if (!results[i].isSuccess()) {
                    System.debug('Failed to insert OrderItem: ' + results[i].getErrors()[0].getMessage());
                }
            }
        }
        return orderItemsToInsert;
    }

    
    /**
     * @description Update Order. Orders must have Id
     * @Date 15 September 2025
     * @param orders List<Order>
     * @return void
     */
    public static void updateOrders(List<Order> orders){
        if(orders == null || orders.isEmpty()) return;

        Database.SaveResult[] results = Database.update(orders);
        for (Integer i = 0; i < results.size(); i++) {
            if (!results[i].isSuccess()) {
                System.debug('Failed to update Order: ' + results[i].getErrors()[0].getMessage());
            }
        }
    }

    /**
     * @description getOrdersByOrderIdAndStatus
     * @Date 15 September 2025
     * @param orderIds Set<Id>
     * @param status String
     * @return List<Order>
     */
    public static List<Order> getOrdersByOrderIdAndStatus(Set<Id> orderIds, String status){
        return  [
                SELECT Id, Status 
                FROM Order 
                WHERE Id IN :orderIds
                AND Status = :status
        ];
    }

    private class OrderServiceException extends Exception{}
}