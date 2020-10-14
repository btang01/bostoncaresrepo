public class OrphanedProjectTriggerHandler extends TriggerHandler {
    private static final Map<Id, Schema.RecordTypeInfo> RT_BY_ID = Schema.SObjectType.OrphanedProject__c.getRecordTypeInfosById();
    public override void afterUpdate() {
        approvePendingVLNeeds((List<OrphanedProject__c>) Trigger.New, (Map<Id, OrphanedProject__c>) Trigger.oldMap);
    }

    private void approvePendingVLNeeds(List<OrphanedProject__c> newVLNeeds, Map<Id, OrphanedProject__c> oldMap) {
        Map<Id, OrphanedProject__c> oppsToReassign = new Map<Id, OrphanedProject__c>();
        Map<Id, OrphanedProject__c> occurrencesToReassign = new Map<Id, OrphanedProject__c>();
        Set<Id> volunteerLeaderIds = new Set<Id>();
        List<SObject> objectsToUpdate = new List<SObject>();

        for(OrphanedProject__c vlneed : newVLNeeds) {
            if(vlneed.Status__c != oldMap.get(vlneed.Id).Status__c &&
               vlneed.Status__c == 'Approved'){
                String recTypeName = RT_BY_ID.get(vlneed.RecordTypeId).getDeveloperName();
                if(recTypeName == 'OrphanedOpportunity') {
                    oppsToReassign.put(vlneed.VolunteerOpportunity__c, vlneed);
                } else if(recTypeName == 'OrphanedOccurrence') {
                    occurrencesToReassign.put(vlneed.Occurrence__c, vlneed);
                }
            }
        }

        Map<Id, Contact> volunteerLeaders = new Map<Id, Contact>([SELECT Id, Email FROM Contact WHERE Id IN: volunteerLeaderIds]);

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
                c.HOC__Status__c = 'Declined';
                c.HOC__Attendance_Status__c = 'Declined';
                objectsToUpdate.add(c);
            // Bulk decline any Connections tied to the parent Occurrence that is being approved for the new VL
            } else if(occurrencesToReassign.containsKey(c.HOC__Occurrence__c) &&
                      c.HOC__Contact__c != occurrencesToReassign.get(c.HOC__Occurrence__c).VolunteerLeader__c){ 
                c.HOC__Status__c = 'Declined';
                c.HOC__Attendance_Status__c = 'Declined';
                objectsToUpdate.add(c);
            }
        }

        update objectsToUpdate;
    }
}
