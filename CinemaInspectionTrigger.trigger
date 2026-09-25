trigger CinemaInspectionTrigger on Object_Inspection__c (
    before update,
    after update
) {

    if (Trigger.isBefore && Trigger.isUpdate) {

        CinemaInspectionTriggerHandler.beforeUpdate(
            Trigger.new,
            Trigger.oldMap
        );
    }

    if (Trigger.isAfter && Trigger.isUpdate) {

        CinemaInspectionTriggerHandler.afterUpdate(
            Trigger.new,
            Trigger.oldMap
        );
    }
}