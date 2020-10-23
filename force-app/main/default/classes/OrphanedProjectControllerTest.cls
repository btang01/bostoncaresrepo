/**
 * Test class providing functional validation and code coverage for
 * the OrphanedProjectController class.
 */
@isTest(isParallel=false)
private class OrphanedProjectControllerTest {
    private static final Map<String, Schema.RecordTypeInfo> RT_BY_NAME = Schema.SObjectType.OrphanedProject__c.getRecordTypeInfosByName();

    /**
     * Create all test data required for this test class.
     */
    @testSetup
    private static void setup() {
        User u = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND UserRoleId != NULL AND IsActive = TRUE LIMIT 1];
        Account a = TestDataFactory.newAccount(u);
        insert a; 
        
        List<Contact> contacts = TestDataFactory.newContacts(2, a.Id);
        insert contacts;

        // You cannot simply insert a Contact with this value populated
		// HOC trigger only kicks in properly if you update the Contact
        for(Contact c: contacts){
            c.HOC__Contact_Login_Profile__c = 'Volunteer Leader';
        }
        update contacts;

        HOC__ZipCode__c zipCodeRec = new HOC__ZipCode__c(Name = '02116');
        insert zipCodeRec;

        HOC__Location__c locationRec = TestDataFactory.newLocationRec(zipCodeRec.Id, a.Id);
        insert locationRec;

        // Create a Volunteer Opportunity w/o any child records
        HOC__Volunteer_Opportunity__c volOppStandAlone = TestDataFactory.newVolOppRec(a.Id, locationRec.Id, contacts[0].Id);
        insert volOppStandAlone;

        // inserting a VL Need record for the standalone Volunteer Opportunity
        OrphanedProject__c volOppVlNeed = TestDataFactory.newVLNeed(volOppStandAlone.Id, null, contacts[1].Id, 'Pending BC Approval');
        insert volOppVlNeed;
    }


    /* 
     * Ensure that the retrieval SOQL is functioning as expected.
    */ 
    @isTest
	private static void testGetOrphanedProjects() {
        List<OrphanedProject__c> vlneeds = [SELECT Id, VolunteerOpportunity__r.Name,
                                            VolunteerLeader__c, VolunteerLeader__r.Name,
                                            Level__c, StartDateTime__c, EndDateTime__c,
                                            Location__c
                                            FROM OrphanedProject__c];

        List<OrphanedProject__c> retrieved = OrphanedProjectController.getOrphanedProjects();
        
        system.assertEquals(vlneeds.size(), retrieved.size());
    }
}
