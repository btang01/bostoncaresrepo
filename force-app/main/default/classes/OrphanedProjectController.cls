global class OrphanedProjectController {
    @AuraEnabled(cacheable=false)
    global static List<OrphanedProject__c> getOrphanedProjects() {
        return [SELECT Id, VolunteerOpportunity__r.Name, Location__r.Name, VolunteerLeaderEmail__c,
                Occurrence__r.HOC__Start_Date_Time__c, Occurrence__r.HOC__End_Date_Time__c
                FROM OrphanedProject__c];
    }
}
