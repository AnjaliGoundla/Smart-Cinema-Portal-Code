public without sharing class CinemaPermitTriggerrHandler {

    private static Set<Id> processedPermitIds = new Set<Id>();

    public static void handle(
        List<Permit_Application__c> newRecords,
        Map<Id, Permit_Application__c> oldMap,
        Boolean isInsert,
        Boolean isUpdate
    ) {

        if (newRecords == null || newRecords.isEmpty()) {
            return;
        }

        Set<Id> permitIdsToShare = new Set<Id>();

        for (Permit_Application__c permit : newRecords) {

            if (permit.Id == null ||
                processedPermitIds.contains(permit.Id)) {
                continue;
            }

            Boolean shouldShare = false;

            if (isInsert) {
                shouldShare = permit.Status__c == 'Submitted';
            }

            if (isUpdate && oldMap != null) {
                Permit_Application__c oldPermit = oldMap.get(permit.Id);

                shouldShare =
                    permit.Status__c == 'Submitted' &&
                    oldPermit != null &&
                    (
                        oldPermit.Status__c != 'Submitted' ||
                        permit.Inspector__c != oldPermit.Inspector__c
                    ) &&
                    permit.Inspector__c != null;
            }

            if (shouldShare) {
                permitIdsToShare.add(permit.Id);
                processedPermitIds.add(permit.Id);
            }
        }

        if (permitIdsToShare.isEmpty()) {
            return;
        }

        Map<Id, Permit_Application__c> permitMap =
            new Map<Id, Permit_Application__c>([
                SELECT Id, OwnerId, Inspector__c
                FROM Permit_Application__c
                WHERE Id IN :permitIdsToShare
            ]);

        Set<Id> inspectorIds = new Set<Id>();

        for (Permit_Application__c permit : permitMap.values()) {
            if (permit.Inspector__c != null) {
                inspectorIds.add(permit.Inspector__c);
            }
        }

        if (inspectorIds.isEmpty()) {
            return;
        }

        Map<String, Boolean> existingShares =
            new Map<String, Boolean>();

        for (Permit_Application__Share share : [
            SELECT ParentId, UserOrGroupId
            FROM Permit_Application__Share
            WHERE ParentId IN :permitIdsToShare
            AND UserOrGroupId IN :inspectorIds
            AND RowCause = 'Manual'
        ]) {
            existingShares.put(
                String.valueOf(share.ParentId) + '-' +
                String.valueOf(share.UserOrGroupId),
                true
            );
        }

        List<Permit_Application__Share> sharesToCreate =
            new List<Permit_Application__Share>();

        for (Permit_Application__c permit : permitMap.values()) {

            Id inspectorId = permit.Inspector__c;

            if (inspectorId == null || permit.OwnerId == inspectorId) {
                continue;
            }

            String key =
                String.valueOf(permit.Id) + '-' +
                String.valueOf(inspectorId);

            if (existingShares.containsKey(key)) {
                continue;
            }

            Permit_Application__Share permitShare =
                new Permit_Application__Share();

            permitShare.ParentId = permit.Id;
            permitShare.UserOrGroupId = inspectorId;
            permitShare.AccessLevel = 'Read';
            permitShare.RowCause =
                Schema.Permit_Application__Share.RowCause.Manual;

            sharesToCreate.add(permitShare);
        }

        if (!sharesToCreate.isEmpty()) {
            Database.insert(sharesToCreate, false);
        }
    }
}