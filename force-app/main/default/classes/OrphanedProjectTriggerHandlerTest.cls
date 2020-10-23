/**
 * Test class providing functional validation and code coverage for
 * the OrphanedProjectTriggerHandler class.
 */
@isTest(isParallel=false)
private class OrphanedProjectTriggerHandlerTest {
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

        System.runAs(u){
            List<User> portalUsers = TestDataFactory.newUsers(contacts);
            insert portalUsers;
        }

        HOC__ZipCode__c zipCodeRec = new HOC__ZipCode__c(Name = '02116');
        insert zipCodeRec;

        HOC__Location__c locationRec = TestDataFactory.newLocationRec(zipCodeRec.Id, a.Id);
        insert locationRec;

        // Create a Volunteer Opportunity w/o any child records
        HOC__Volunteer_Opportunity__c volOppStandAlone = TestDataFactory.newVolOppRec(a.Id, locationRec.Id, contacts[0].Id);
        insert volOppStandAlone;
        
        // Create a Volunteer Opportunity and its child Occurrence and Connection records (indicating who the current VL is)
        HOC__Volunteer_Opportunity__c volOppRec = TestDataFactory.newVolOppRec(a.Id, locationRec.Id, contacts[0].Id);
        insert volOppRec;
        
        HOC__Occurrence__c occRec = TestDataFactory.newOccurrenceRec(volOppRec, contacts[0].Id);
        insert occRec;

        HOC__Connection__c connectionRec = TestDataFactory.newConnection(occRec, contacts[0].Id);
        insert connectionRec;
        
        // There is an HOC Trigger that prevents me from inserting a connection record
        // with Volunteer Leader Role, hence update is needed after insert.
        connectionRec.HOC__Role__c = 'Volunteer Leader';
        update connectionRec;

        // inserting a VL Need record for the standalone Volunteer Opportunity
        OrphanedProject__c volOppVlNeed = TestDataFactory.newVLNeed(volOppStandAlone.Id, null, contacts[1].Id, 'Pending BC Approval');
        insert volOppVlNeed;

        // inserting a VL Need record for the Volunteer Opportunity with Occurrence and Connection children
        OrphanedProject__c OccVlNeed = TestDataFactory.newVLNeed(volOppRec.Id, occRec.Id, contacts[1].Id, 'Pending BC Approval');
        insert OccVlNeed;        
    }

    /* 
     * Ensure that when a pending VL need is rejected,
     * we revert the VL assignment.
    */ 
    @isTest
	private static void testRejectPendingVLNeeds() {
        OrphanedProject__c vlneed = [SELECT Id FROM OrphanedProject__c
                                     WHERE RecordTypeId =: RT_BY_NAME.get('Orphaned Opportunity').getRecordTypeId()];
        vlneed.Status__c = 'Rejected';
        update vlneed;

        vlneed = [SELECT Id, VolunteerLeader__c FROM OrphanedProject__c WHERE Id =: vlneed.Id];
        system.assertEquals(null, vlneed.VolunteerLeader__c);
    }

    /* 
     * Ensure that when a pending VL need related to a volunteer opportunity is approved,
     * we update the corresponding Volunteer Opportunity records.
    */ 
    @isTest
	private static void testApprovePendingVolOppVLNeed() {
        OrphanedProject__c vlneed = [SELECT Id, VolunteerOpportunity__c, VolunteerLeader__c, VolunteerLeader__r.Email
                                     FROM OrphanedProject__c 
                                     WHERE RecordTypeId =: RT_BY_NAME.get('Orphaned Opportunity').getRecordTypeId()];
        vlneed.Status__c = 'Approved';
        update vlneed;

        HOC__Volunteer_Opportunity__c voloppRec = [SELECT Id, HOC__Opportunity_Coordinator__c, HOC__Volunteer_Coordinator_Email__c
                                                   FROM HOC__Volunteer_Opportunity__c
                                                   WHERE Id =: vlneed.VolunteerOpportunity__c];
        system.assertEquals(vlneed.VolunteerLeader__c, voloppRec.HOC__Opportunity_Coordinator__c);
        system.assertEquals(vlneed.VolunteerLeader__r.Email, voloppRec.HOC__Volunteer_Coordinator_Email__c);
    }

    /* 
     * Ensure that when a pending VL need related to an occurrence is approved,
     * we update the corresponding Volunteer Opportunity records.
    */ 
    @isTest
	private static void testApprovePendingOccVLNeed() {
        Test.startTest();
        OrphanedProject__c vlneed = [SELECT Id, VolunteerOpportunity__c, VolunteerLeader__c, VolunteerLeader__r.Email
                                     FROM OrphanedProject__c
                                     WHERE RecordTypeId =: RT_BY_NAME.get('Orphaned Occurrence').getRecordTypeId()];
        vlneed.Status__c = 'Approved';
        update vlneed;
        Test.stopTest();

        HOC__Volunteer_Opportunity__c volOppRec = [SELECT Id, HOC__Opportunity_Coordinator__c, HOC__Volunteer_Coordinator_Email__c,
                                                   (SELECT Id, HOC__Volunteer_Coordinator_Email__c
                                                    FROM HOC__Occurence__r
                                                    WHERE HOC__Opportunity_Coordinator__c =: vlneed.VolunteerLeader__c),
                                                   (SELECT Id, HOC__Status__c, HOC__Attendance_Status__c
                                                    FROM HOC__Connection__r
                                                    WHERE HOC__Role__c = 'Volunteer Leader' AND HOC__Contact__c !=: vlneed.VolunteerLeader__c)
                                                   FROM HOC__Volunteer_Opportunity__c
                                                   WHERE Id =: vlneed.VolunteerOpportunity__c];
        system.assertEquals(vlneed.VolunteerLeader__c, volOppRec.HOC__Opportunity_Coordinator__c);
        system.assertEquals(vlneed.VolunteerLeader__r.Email, volOppRec.HOC__Volunteer_Coordinator_Email__c);
        system.assertEquals(1, volOppRec.HOC__Occurence__r.size());
        system.assertEquals(vlneed.VolunteerLeader__r.Email, volOppRec.HOC__Occurence__r[0].HOC__Volunteer_Coordinator_Email__c);
        system.assertEquals(1, volOppRec.HOC__Connection__r.size());
        system.assertEquals('Declined', volOppRec.HOC__Connection__r[0].HOC__Status__c);
        system.assertEquals('Declined', volOppRec.HOC__Connection__r[0].HOC__Attendance_Status__c);
    }
}
