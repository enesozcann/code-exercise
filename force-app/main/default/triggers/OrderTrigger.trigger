trigger OrderTrigger on Order (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    switch on Trigger.operationType {
        when AFTER_UPDATE {
                OrderTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}
