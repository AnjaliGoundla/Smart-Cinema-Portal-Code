global without sharing class CinemaPermitExpiryBatch
    implements Database.Batchable<SObject> {

    global Database.QueryLocator start(
        Database.BatchableContext bc
    ) {
        return Database.getQueryLocator([
            SELECT
                Id,
                Name,
                Status__c,
                Expiry_Date__c
            FROM Permit_Application__c
            WHERE Expiry_Date__c != null
            AND Expiry_Date__c < :System.today()
            AND Status__c NOT IN (
                'Closed',
                'Rejected'
            )
        ]);
    }

    global void execute(
        Database.BatchableContext bc,
        List<Permit_Application__c> scope
    ) {
        if (scope == null || scope.isEmpty()) {
            return;
        }

        for (Permit_Application__c permit : scope) {
            permit.Status__c = 'Closed';
        }

        Database.update(scope, false);
    }

    global void finish(
        Database.BatchableContext bc
    ) {
        System.debug(
            LoggingLevel.INFO,
            'Cinema Permit Expiry Batch completed.'
        );
    }
}