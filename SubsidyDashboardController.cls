public with sharing class SubsidyDashboardController {

    @AuraEnabled(cacheable=true)
    public static List<Subsidy_Assignment__c> getSubsidies() {

        return [
            SELECT
                Id,
                Name,
                Request_Type__c,
                Requested_Amount__c,
                Approved_Amount__c,
                Status__c,
                Eligibility__c,
                Approval_Date__c,
                Notes__c,
                Permit_Application__c
            FROM Subsidy_Assignment__c
            ORDER BY CreatedDate DESC
        ];
    }
}