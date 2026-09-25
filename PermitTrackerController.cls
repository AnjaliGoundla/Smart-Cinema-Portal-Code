public with sharing class PermitTrackerController {

    @AuraEnabled(cacheable=true)
    public static Permit_Application__c getPermitApplication(
        Id permitApplicationId
    ) {
        return [
            SELECT
                Id,
                Name,
                Status__c,
                Application_Progress__c,
                Permit_Type__c,
                Application_Category__c,
                Permit_Description__c,
                Proposed_Operating_Start_Date__c,
                Expiry_Date__c
            FROM Permit_Application__c
            WHERE Id = :permitApplicationId
            LIMIT 1
        ];
    }
}