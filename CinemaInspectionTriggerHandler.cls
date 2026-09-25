public without sharing class CinemaInspectionTriggerHandler {

    private static Set<Id> processedInspectionIds =
        new Set<Id>();

    public static void beforeUpdate(
        List<Object_Inspection__c> newRecords,
        Map<Id, Object_Inspection__c> oldMap
    ) {

        if (newRecords == null || newRecords.isEmpty()) {
            return;
        }

        Set<Id> permitIds = new Set<Id>();

        for (Object_Inspection__c inspection : newRecords) {
            if (inspection.Permit_Application__c != null) {
                permitIds.add(
                    inspection.Permit_Application__c
                );
            }
        }

        Map<Id, Permit_Application__c> permits =
            new Map<Id, Permit_Application__c>();

        if (!permitIds.isEmpty()) {

            permits = new Map<Id, Permit_Application__c>([
                SELECT
                    Id,
                    Cinema_Account__c
                FROM Permit_Application__c
                WHERE Id IN :permitIds
            ]);
        }

        for (Object_Inspection__c inspection : newRecords) {

            /*
             * Automatically find the matching Planned Visit
             * when Visit is blank.
             */
            if (
                inspection.Visit__c == null &&
                inspection.Permit_Application__c != null &&
                permits.containsKey(
                    inspection.Permit_Application__c
                ) &&
                inspection.Schedule_Date__c != null
            ) {

                Permit_Application__c permit =
                    permits.get(
                        inspection.Permit_Application__c
                    );

                if (permit.Cinema_Account__c != null) {

                    Date startDate =
                        inspection.Schedule_Date__c;

                    Date endDate =
                        startDate.addDays(1);

                    DateTime startDateTime =
                        DateTime.newInstance(
                            startDate,
                            Time.newInstance(0, 0, 0, 0)
                        );

                    DateTime endDateTime =
                        DateTime.newInstance(
                            endDate,
                            Time.newInstance(0, 0, 0, 0)
                        );

                    List<Visit> visits = [
                        SELECT
                            Id,
                            AccountId,
                            Status,
                            PlannedVisitStartTime
                        FROM Visit
                        WHERE AccountId =
                            :permit.Cinema_Account__c
                        AND Status = 'Planned'
                        AND PlannedVisitStartTime >=
                            :startDateTime
                        AND PlannedVisitStartTime <
                            :endDateTime
                        ORDER BY PlannedVisitStartTime ASC
                        LIMIT 1
                    ];

                    if (!visits.isEmpty()) {

                        inspection.Visit__c =
                            visits[0].Id;
                    }
                }
            }

            /*
             * When Outcome changes to Fail:
             * Status = Remediation Required
             * Completed Date = Today if blank
             */
            Object_Inspection__c oldInspection =
                oldMap.get(inspection.Id);

            if (oldInspection == null) {
                continue;
            }

            Boolean newlyFailed =
                inspection.Outcome__c == 'Fail' &&
                oldInspection.Outcome__c != 'Fail';

            if (newlyFailed) {

                inspection.Status__c =
                    'Remediation Required';

                if (inspection.Completed_Date__c == null) {

                    inspection.Completed_Date__c =
                        System.now().date();
                }
            }
        }
    }


    public static void afterUpdate(
        List<Object_Inspection__c> newRecords,
        Map<Id, Object_Inspection__c> oldMap
    ) {

        if (newRecords == null || newRecords.isEmpty()) {
            return;
        }

        Set<Id> failedInspectionIds =
            new Set<Id>();

        for (Object_Inspection__c inspection : newRecords) {

            if (
                processedInspectionIds.contains(
                    inspection.Id
                )
            ) {
                continue;
            }

            Object_Inspection__c oldInspection =
                oldMap.get(inspection.Id);

            if (oldInspection == null) {
                continue;
            }

            Boolean newlyFailed =
                inspection.Outcome__c == 'Fail' &&
                oldInspection.Outcome__c != 'Fail';

            if (newlyFailed) {

                failedInspectionIds.add(
                    inspection.Id
                );

                processedInspectionIds.add(
                    inspection.Id
                );
            }
        }

        if (failedInspectionIds.isEmpty()) {
            return;
        }

        Map<Id, Object_Inspection__c> inspections =
            new Map<Id, Object_Inspection__c>([
                SELECT
                    Id,
                    Name,
                    Outcome__c,
                    Status__c,
                    Failure_Reason__c,
                    Findings__c,
                    Inspector__c,
                    Permit_Application__c,
                    Visit__c
                FROM Object_Inspection__c
                WHERE Id IN :failedInspectionIds
            ]);

        Set<Id> visitIds =
            new Set<Id>();

        for (
            Object_Inspection__c inspection :
            inspections.values()
        ) {

            if (inspection.Visit__c != null) {
                visitIds.add(
                    inspection.Visit__c
                );
            }
        }

        if (visitIds.isEmpty()) {
            return;
        }

        /*
         * Find Cinema Fire Safety Remediations template.
         */
        List<ActionPlanTemplate> templates = [
            SELECT
                Id,
                Name,
                ActionPlanType,
                TargetEntityType
            FROM ActionPlanTemplate
            WHERE Name =
                'Cinema Fire Safety Remediations'
            LIMIT 1
        ];

        if (templates.isEmpty()) {
            return;
        }

        ActionPlanTemplate template =
            templates[0];

        /*
         * Find Final template version.
         */
        List<ActionPlanTemplateVersion> versions = [
            SELECT
                Id,
                ActionPlanTemplateId,
                Status,
                Version
            FROM ActionPlanTemplateVersion
            WHERE ActionPlanTemplateId =
                :template.Id
            AND Status = 'Final'
            ORDER BY Version DESC
            LIMIT 1
        ];

        if (versions.isEmpty()) {
            return;
        }

        ActionPlanTemplateVersion templateVersion =
            versions[0];

        /*
         * Prevent duplicate Action Plans.
         */
        Map<Id, ActionPlan> existingPlansByVisit =
            new Map<Id, ActionPlan>();

        for (ActionPlan plan : [
            SELECT
                Id,
                Name,
                TargetId,
                ActionPlanTemplateVersionId
            FROM ActionPlan
            WHERE TargetId IN :visitIds
            AND ActionPlanTemplateVersionId =
                :templateVersion.Id
        ]) {

            existingPlansByVisit.put(
                plan.TargetId,
                plan
            );
        }

        List<ActionPlan> plansToCreate =
            new List<ActionPlan>();

        for (
            Object_Inspection__c inspection :
            inspections.values()
        ) {

            if (inspection.Visit__c == null) {
                continue;
            }

            if (
                existingPlansByVisit.containsKey(
                    inspection.Visit__c
                )
            ) {
                continue;
            }

            ActionPlan remediationPlan =
                new ActionPlan();

            remediationPlan.Name =
                'Cinema Fire Safety Remediation - ' +
                inspection.Name;

            remediationPlan.ActionPlanTemplateVersionId =
                templateVersion.Id;

            remediationPlan.ActionPlanType =
                template.ActionPlanType;

            remediationPlan.ActionPlanState =
                'In Progress';

            remediationPlan.StartDate =
                System.today();

            remediationPlan.TargetId =
                inspection.Visit__c;

            plansToCreate.add(
                remediationPlan
            );
        }

        if (!plansToCreate.isEmpty()) {

            Database.insert(
                plansToCreate,
                false
            );
        }
    }
}