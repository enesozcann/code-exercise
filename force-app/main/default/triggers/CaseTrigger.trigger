trigger CaseTrigger on Case (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    switch on Trigger.operationType {
        when BEFORE_UPDATE {
            CaseTriggerHandler.handleBeforeUpdate(Trigger.new, Trigger.oldMap);
        }
        when AFTER_UPDATE {
            CaseTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}