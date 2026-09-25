global without sharing class CinemaInspectionArchiveBatch
    implements Database.Batchable<SObject> {

    global Database.QueryLocator start(
        Database.BatchableContext bc
    ) {
        return Database.getQueryLocator([
            SELECT
                Id,
                Name,
                Status__c,
                Outcome__c,
                Archived__c
            FROM Object_Inspection__c
            WHERE Status__c = 'Completed'
            AND Outcome__c IN ('Pass', 'Fail')
            AND Archived__c = false
        ]);
    }

    global void execute(
        Database.BatchableContext bc,
        List<Object_Inspection__c> scope
    ) {
        if (scope == null || scope.isEmpty()) {
            return;
        }

        for (Object_Inspection__c inspection : scope) {
            inspection.Archived__c = true;
        }

        Database.update(scope, false);
    }

    global void finish(
        Database.BatchableContext bc
    ) {
        System.debug(
            LoggingLevel.INFO,
            'Cinema Inspection Archive Batch completed.'
        );
    }
}