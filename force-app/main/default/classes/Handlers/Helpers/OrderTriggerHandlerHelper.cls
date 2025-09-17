/**
 * Author: Enes Ozcan
 * @description OrderTriggerHandlerHelper
 * @Date 15 September 2025
 */
public inherited sharing class OrderTriggerHandlerHelper {
    /**
     * @description Get Orders If just Activated and ready to close Case
     * @Date 15 September 2025
     * @return List<Order>
     */
    public static List<Order> getActivatedOrdersIfExternalIdNotNull(List<Order> newList, Map<Id, Order> oldMap){
        List<Order> result = new List<Order>();
        for (Order order : newList) {
            Order oldOrder = oldMap.get(order.Id);
            if (order.Status == 'Activated' && !String.isBlank(order.ExternalOrderId__c)
                && (oldOrder == null || oldOrder.Status != 'Activated')) 
                {
                    result.add(order);
                }
        }
        return result;
    }
}