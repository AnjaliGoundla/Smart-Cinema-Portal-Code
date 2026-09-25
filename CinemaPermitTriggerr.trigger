trigger CinemaPermitTriggerr on Permit_Application__c (
    
        after insert,
    after update
) {
    CinemaPermitTriggerrHandler.handle(
        Trigger.new,
        Trigger.oldMap,
        Trigger.isInsert,
        Trigger.isUpdate
    );

}