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
     * 3. Here are the assumptions around which Salesforce field(s) correspond to the
     *    excel columns:
     *    (1) Orgnization Served = VolunteerOpportunity__r.HOC__Organization_Served_Name__c
     *    (2) Activity = VolunteerOpportunity__r.Name
     *    (3) Location = Location__c
          (4) Monthly Days = ?
          (5) Time = ?
          (6) Volunteer Leader = VolunteerLeader__r.Name
          (7) Alternate Volunteer Leader = ?
          (8) Partner Staff as VL = ?

    * 4. Going forward, in order for BC to open up an Occurrence for VL to claim, BC would need to 
         create an Occurrence record first, and then use the NewVolunteerLeaderNeeds flow to generate VL Needs.
         This is a change compared to how the Google Sheet works. 
    * 5. Given a Volunteer Opportunity, BC would decide to either share the entire Volunteer Opportunity for VLs to grab,
         or share the occurrences for VLs to grab, but it would never be both.
    */
    @AuraEnabled(cacheable=false)
    global static List<OrphanedProject__c> getOrphanedProjects() {
        return [SELECT Id, VolunteerOpportunity__r.Name,
                VolunteerLeader__c, VolunteerLeader__r.Name,
                Level__c, StartDateTime__c, EndDateTime__c,
                Location__c
                FROM OrphanedProject__c];
    }
}