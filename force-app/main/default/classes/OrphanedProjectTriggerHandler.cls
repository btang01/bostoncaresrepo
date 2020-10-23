public class OrphanedProjectTriggerHandler extends TriggerHandler {
    private static final Map<Id, Schema.RecordTypeInfo> RT_BY_ID = Schema.SObjectType.OrphanedProject__c.getRecordTypeInfosById();
    
    public override void beforeUpdate() {
        rejectPendingVLNeeds((List<OrphanedProject__c>) Trigger.New, (Map<Id, OrphanedProject__c>) Trigger.oldMap);
    }

    public override void afterUpdate() {
        approvePendingVLNeeds((List<OrphanedProject__c>) Trigger.New, (Map<Id, OrphanedProject__c>) Trigger.oldMap);
    }

    private void rejectPendingVLNeeds(List<OrphanedProject__c> newVLNeeds, Map<Id, OrphanedProject__c> oldMap) {
        for(OrphanedProject__c vlneed : newVLNeeds) {
            if(vlneed.Status__c != oldMap.get(vlneed.Id).Status__c &&
               vlneed.Status__c == 'Rejected' &&
               oldMap.get(vlneed.Id).Status__c == 'Pending BC Approval'){
                vlneed.VolunteerLeader__c = null; 
            }
        }
    }


    private void approvePendingVLNeeds(List<OrphanedProject__c> newVLNeeds, Map<Id, OrphanedProject__c> oldMap) {
        Map<Id, OrphanedProject__c> oppsToReassign = new Map<Id, OrphanedProject__c>();
        Map<Id, OrphanedProject__c> occurrencesToReassign = new Map<Id, OrphanedProject__c>();
        Set<Id> volunteerLeaderIds = new Set<Id>();
        List<SObject> objectsToUpdate = new List<SObject>();
        Set<Id> connectionsToUpdate = new Set<Id>();

        for(OrphanedProject__c vlneed : newVLNeeds) {
            if(vlneed.Status__c != oldMap.get(vlneed.Id).Status__c &&
               vlneed.Status__c == 'Approved' &&
               oldMap.get(vlneed.Id).Status__c == 'Pending BC Approval'){
                String recTypeName = RT_BY_ID.get(vlneed.RecordTypeId).getDeveloperName();
                if(recTypeName == 'OrphanedOpportunity') {
                    oppsToReassign.put(vlneed.VolunteerOpportunity__c, vlneed);
                } else if(recTypeName == 'OrphanedOccurrence') {
                    occurrencesToReassign.put(vlneed.Occurrence__c, vlneed);
                }
                volunteerLeaderIds.add(vlneed.VolunteerLeader__c);
            }
        }

        Map<Id, Contact> volunteerLeaders = new Map<Id, Contact>([SELECT Id, Email FROM Contact WHERE Id IN: volunteerLeaderIds]);
        system.debug(volunteerLeaders);

        for(Id oppId: oppsToReassign.keySet()) {
            HOC__Volunteer_Opportunity__c opp = new HOC__Volunteer_Opportunity__c(
                                                    Id = oppId,
                                                    HOC__Opportunity_Coordinator__c = oppsToReassign.get(oppId).VolunteerLeader__c,
                                                    HOC__Volunteer_Coordinator_Email__c = volunteerLeaders.get(oppsToReassign.get(oppId).VolunteerLeader__c).Email
                                                );
            objectsToUpdate.add(opp);
            //TODO: determine whether new Occurrences would need to be automatically created or not.
        }

        for(Id occId: occurrencesToReassign.keySet()){
            HOC__Occurrence__c occ = new HOC__Occurrence__c(
                                        Id = occId,
                                        HOC__Opportunity_Coordinator__c = occurrencesToReassign.get(occId).VolunteerLeader__c,
                                        HOC__Volunteer_Coordinator_Email__c = volunteerLeaders.get(occurrencesToReassign.get(occId).VolunteerLeader__c).Email
                                     );
            objectsToUpdate.add(occ);
        }

        for(HOC__Connection__c c: [SELECT Id, HOC__Contact__c, HOC__Volunteer_Opportunity__c, HOC__Occurrence__c
                                   FROM HOC__Connection__c
                                   WHERE 
                                   (HOC__Occurrence__c IN: occurrencesToReassign.keySet() OR
                                   HOC__Volunteer_Opportunity__c IN: oppsToReassign.keySet()) AND
                                   HOC__Role__c = 'Volunteer Leader' AND
                                   HOC__Status__c = 'Confirmed' AND
                                   HOC__Attendance_Status__c = 'Please Verify']){
            // Bulk decline any Connections tied to the parent Volunteer Opportunity that is being approved for the new VL
            if(oppsToReassign.containsKey(c.HOC__Volunteer_Opportunity__c) &&
               c.HOC__Contact__c != oppsToReassign.get(c.HOC__Volunteer_Opportunity__c).VolunteerLeader__c) {
                connectionsToUpdate.add(c.Id);
            // Bulk decline any Connections tied to the parent Occurrence that is being approved for the new VL
            } else if(occurrencesToReassign.containsKey(c.HOC__Occurrence__c) &&
                      c.HOC__Contact__c != occurrencesToReassign.get(c.HOC__Occurrence__c).VolunteerLeader__c){ 
                connectionsToUpdate.add(c.Id);
            }
        }

        update objectsToUpdate;
        updateConnections(connectionsToUpdate);
    }

    /*
     * a future method created such that we avoid hitting SOQL Query 101 errors 
    */ 
    @future
    public static void updateConnections(Set<Id> connectionIds) {
        List<HOC__Connection__c> connectionsToUpdate = new List<HOC__Connection__c>();
        for(Id connectionId : connectionIds) {
            connectionsToUpdate.add(new HOC__Connection__c(Id = connectionId, 
                                                           HOC__Status__c = 'Declined',
                                                           HOC__Attendance_Status__c = 'Declined'));
        }

        update connectionsToUpdate;
    }
}
