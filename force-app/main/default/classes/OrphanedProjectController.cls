global class OrphanedProjectController {
    /*
     * This custom object should be used, when/if OWD for HOC__Volunteer_Opportunity__c
     * has to remain Private. 
     * Assumptions: 
     * 1. Given an OrphanedProject__c record, there are 2 possibilities: 
     *    (1) VolunteerOpportunity__c is populated, while Occurrence__c is not. This is used
     *        to track projects that should/could be claimed as a whole. 
     *    (2) Both VolunteerOpportunity__c and Occurrence__c are populated. This is used to 
     *        track orphaned project occurrences that should/could be claimed individually. 
     * 2. Consider building flags and trigger logic to quickly enable BostonCares staff
     *    to quickly generate an Orphaned Project record on the volunteer opportunity level, 
     *    or to quickly generate an Orphaned Project record for each Ocurrence records under a 
     *    given volunteer opportunity.
    */
    @AuraEnabled(cacheable=false)
    global static List<OrphanedProject__c> getOrphanedProjects() {
        return [SELECT Id, VolunteerOpportunity__r.Name, Location__r.Name, VolunteerLeader__c, VolunteerLeader__r.Name,
                Level__c, StartDateTime__c, EndDateTime__c
                FROM OrphanedProject__c];
    }

    /*
     * Method used to retrieve volunteer opportunities that are currently unclaimed/orphaned,
     * as indicated by the HOC__Opportunity_Coordinator__c field being null.
     * TODO: confirm assumption that HOC__Opportunity_Coordinator__c & HOC__Volunteer_Coordinator_Email__c
     * are indeed being used to track Volunteer Leaders on a Volunteer Opportunity level.
     * TODO: confirm whether OWD for HOC__Volunteer_Opportunity__c can be changed to Public Read/Write.
     * It is currently set to Private, so likely not.
     */
    @AuraEnabled(cacheable=false)
    global static List<HOC__Volunteer_Opportunity__c> getOrphanedVolOpps() {
        return [SELECT Id, Name, HOC__Default_Location__r.Name, HOC__Volunteer_Coordinator_Email__c,
                HOC__Start_Date__c, HOC__End_Date__c, HOC__Schedule_Type__c, HOC__Organization_Served__r.Name,
                (SELECT Id, HOC__Start_Date_Time__c, HOC__End_Date_Time__c,
                 HOC__Opportunity_Coordinator__c, HOC__Volunteer_Coordinator_Email__c
                 FROM HOC__Occurence__r),
                (SELECT Id, HOC__Start_Date_Time__c, HOC__Contact_Email__c, HOC__Volunteer_Opportunity__c
                 FROM HOC__Connection__r
                 WHERE HOC__Role__c = 'Volunteer Leader' AND
                       HOC__Status__c = 'Confirmed' AND
                       HOC__Attendance_Status__c = 'Please Verify')
                FROM HOC__Volunteer_Opportunity__c WHERE HOC__Opportunity_Coordinator__c = NULL];
    }

    class orphanedProject {
        
    }
}
