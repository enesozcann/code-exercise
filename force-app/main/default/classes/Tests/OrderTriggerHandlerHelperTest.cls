@isTest
private class OrderTriggerHandlerHelperTest {

@IsTest
private static void getActivatedOrdersIfExternalIdNotNullTest(){
        List<Order> orders = OrderTriggerHandlerHelper.getActivatedOrdersIfExternalIdNotNull(new List<Order>{new Order(Status = 'Activated', ExternalOrderId__c = '12345')}, new Map<Id, Order>());
        System.assertEquals(1, orders.size());
    }
}