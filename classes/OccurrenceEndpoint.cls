/*
 * Title: OccurrenceEndpoint
 * Created By: Phil Currier
 * Description: Volunteer Leaders can POST to this endpoint to create Occurrences
 *   (along with any needed parent objects) in the system.
 */

@RestResource(urlMapping='/HOC__Occurrence__c/*')
global with sharing class OccurrenceEndpoint {

    public static String dateDelim = '\\|';
    public static String timeDelim = '-';
    public static String rowDelim = '\\<\\<\\|';
    public static String fieldDelim = '\\>\\>\\|';

    public static String ORG_NAME = 'Name of Organization';
    public static String EVENT_NAME = 'Name of Event';
    public static String VL_EMAIL = 'Volunteer Leader';
    public static String DATES_CLAIMED = 'Dates Claimed';
    public static String EVENT_TIME = 'Time of Event';

    public static Map<String, Integer> fieldPositionMap = new Map<String, Integer>();
    public static ID nonprofitId = schema.SObjectType.Account.getRecordTypeInfosByName().get('Nonprofit').getRecordTypeId();

    public static String getFld(String name, String[] fields) {
      return fields[fieldPositionMap.get(name)];
    }


    public class VolunteerLeaderVM{
        String volOppId;
        Datetime startDatetime;
        Datetime stopDatetime;
        String newVLEmail;
        String locationName;
        Boolean found;
    }

    // The following method is used to reassign owner of an occurrence
    public static void upsertOccurrence(List<VolunteerLeaderVM> volVmList){

        // ***** BUILD A LIST OF RELEVANT VOLUNTEER OP IDs *****
        List<String> relevantVolOppIds = new List<String>();
        // ***** BUILD A LIST OF RELEVANT USERS *****
        List<String> relevantEmails = new List<String>();
        // **** BUILD A LIST OF RELEVANT LOCATIONS ****
        List<String> relevantLocationNames = new List<String>();

        for(VolunteerLeaderVM volVM : volVmList){
            relevantVolOppIds.add(volVM.volOppId);
            relevantEmails.add(volVM.newVLEmail);
            relevantLocationNames.add(volVM.locationName);
        }

        List<User> existingUsers = [SELECT Id, Email FROM User WHERE Email IN: relevantEmails];

        List<HOC__Occurrence__c> existingOccs = [
            SELECT Id, HOC__Start_Date_Time__c, HOC__End_Date_Time__c,
            HOC__Volunteer_Opportunity__c, HOC__Opportunity_Coordinator__c
            FROM HOC__Occurrence__c
            WHERE HOC__Volunteer_Opportunity__r.Id IN: relevantVolOppIds];


        List<HOC__Location__c> existingLocations = [SELECT Id, Name
                                                    FROM HOC__Location__c
                                                    WHERE Name IN: relevantLocationNames];

        List<HOC__Occurrence__c> listOfOccurrencesToUpdate = returnListOfOccsToUpdate(volVmList, existingOccs, existingUsers);

        List<HOC__Occurrence__c> listOfOccurrencesToInsert = returnListOfOccsToInsert(volVmList, existingOccs, existingUsers, existingLocations);

        try{
            update listOfOccurrencesToUpdate;
        } catch(Exception e){
            System.debug(e);
        }

        try{
            insert listOfOccurrencesToInsert;
        } catch(Exception e){
            System.debug(e);
        }
    }


    public static List<HOC__Occurrence__c> returnListOfOccsToUpdate(List<VolunteerLeaderVM> myVolVMList, List<HOC__Occurrence__c> myOccList, List<User> myUserList){

        // Add to this list and update these Occurrences
        List<HOC__Occurrence__c> myOccListToUpdate = new List<HOC__Occurrence__c>();

        for(VolunteerLeaderVM volVM : myVolVMList){
            if(!myOccList.isEmpty()){
                // Match Occurrence record to the info in the VL VM
                // Using a combination of Volunteer Opportunity ID and Start Date
                for(HOC__Occurrence__c occ : myOccList){
                    if((occ.HOC__Start_Date_Time__c != null &&
                        (occ.HOC__Start_Date_Time__c == volVM.startDatetime)) &&
                        (occ.HOC__Volunteer_Opportunity__c != null &&
                        (occ.HOC__Volunteer_Opportunity__c == volVM.VolOppId))){

                        // Great success, I've found my occurrence!
                        // Now reassign the Volunteer Coordinator
                        for(User myUser : myUserList){
                            if(volVM.newVLEmail == myUser.Email){
                                occ.HOC__Opportunity_Coordinator__c = myUser.Id;
                                occ.HOC__Volunteer_Coordinator_Email__c = myUser.Email;
                                myOccListToUpdate.add(occ);
                            } else {
                                System.debug('Existing user cannot be found with this Email!');
                            }
                        }
                    }
                }
            } else {
                System.debug('No existing Occurrences found under the Volunteer Opp Id provided!');
            }
        }
        return myOccListToUpdate;
    }


    public static List<HOC__Occurrence__c> returnListOfOccsToInsert(List<VolunteerLeaderVM> myVolVMList, List<HOC__Occurrence__c> myOccList, List<User> myUserList, List<HOC__Location__c> myLocationList){

        // Add to this list and update these Occurrences
        List<HOC__Occurrence__c> myOccListInsert = new List<HOC__Occurrence__c>();
        List<VolunteerLeaderVM> nonMatchingVLVMList = new List<VolunteerLeaderVM>();

        for(VolunteerLeaderVM volVM : myVolVMList){
            // If there are occurrences, make sure that these occs are not in that list
            if(!myOccList.isEmpty()){
                // Match Occurrence record to the info in the VL VM
                // Using a combination of Volunteer Opportunity ID and Start Date
                for(HOC__Occurrence__c occ : myOccList){
                    if((occ.HOC__Start_Date_Time__c != null &&
                        (occ.HOC__Start_Date_Time__c == volVM.startDatetime)) &&
                        (occ.HOC__Volunteer_Opportunity__c != null &&
                        (occ.HOC__Volunteer_Opportunity__c == volVM.VolOppId))){

                        // Great success, I can't find an occurrence!
                        // Build List of nonMatching VLVMs
                        volVM.found = TRUE;
                    }
                }
            } else {
                volVM.found = FALSE;
            }
        }

        for(VolunteerLeaderVM volVMUpdated : myVolVMList){
            if(!volVMUpdated.found){
                nonMatchingVLVMList.add(volVMUpdated);
            }
        }

        myOccListInsert = buildOccurrencesList(nonMatchingVLVMList, myUserList, 'Active', 'Active');
        return myOccListInsert;
    }


    @HttpPost
    global static void postVLSheetUpdates() {
      RestRequest request = RestContext.request;
      String response = '';
      String body = request.requestBody.toString();
      String[] rows = body.split(rowDelim);

      // Build a map of field names to positions
      String[] header = rows[0].split(fieldDelim);
      for (Integer i = 0; i < header.size(); i++) {
        fieldPositionMap.put(header[i], i);
      }

      // Go through the records we received
      for (Integer i = 1; i < rows.size(); i++) {
        String[] fields = rows[i].split(fieldDelim);
        String vlEmail = getFld(VL_EMAIL, fields);
        String orgName = getFld(ORG_NAME, fields);
        String eventName = getFld(EVENT_NAME, fields);
        String[] dates = getFld(DATES_CLAIMED, fields).split(dateDelim);
        String[] times = getFld(EVENT_TIME, fields).split(timeDelim);
        List<DateTime[]> occurrences = new List<DateTime[]>();
        for (String dt : dates) {
          DateTime[] occ = new DateTime[2];
          occ[0] = DateTime.newInstance(
            Integer.valueOf(dt.substring(0, 4)),
            Integer.valueOf(dt.substring(4, 6)),
            Integer.valueOf(dt.substring(6, 8)),
            Integer.valueOf(times[0].substring(0, 2)),
            Integer.valueOf(times[0].substring(2, 4)),
            Integer.valueOf(times[0].substring(4, 6))
          );
          occ[1] = DateTime.newInstance(
            Integer.valueOf(dt.substring(0, 4)),
            Integer.valueOf(dt.substring(4, 6)),
            Integer.valueOf(dt.substring(6, 8)),
            Integer.valueOf(times[1].substring(0, 2)),
            Integer.valueOf(times[1].substring(2, 4)),
            Integer.valueOf(times[1].substring(4, 6))
          );
          occurrences.add(occ);
          //CreateObjects(vlEmail, orgName, eventName, occurrences, ...);
          response = response + 'got date|';
        }
      }

      RestContext.response.responseBody = Blob.valueOf(response);

      // Call other methods to get the right ids in Salesforce
      // NEED TO FIGURE OUT HOW TO GET THESE INTO ANOTHER CLASS CAUSE THIS WONT WORK
      //Boolean orgExists = checkOrgExists(accountName);
      //String bosCaresStaffId = getBostonCaresStaffUserId(bosCaresAccountOwnerName);
      //String volunteerOppId = getVolunteerOppId(volOppName);
      //String locationId = getLocationId(locationName);
      //String oppCoordinatorId = getOppCoordinatorId(bosCaresOppCoordinatorName);
      //String oppCoordinatorEmail = getOppCoordinatorEmail(bosCaresOppCoordinatorName);

      // Move all Org creation POST logic into another Class called RESTAccountController
      // Have Google sheets call it separately
      //if (!orgExists) {
      //  try {
      //    createOrganization(accountName, nonProfitId, bosCaresStaffId);
      //  } catch(Exception e) {
      //    System.debug(e);
      //  }
      //}

      //createOccurrence(volunteerOppId, locationId, occStartTime, occEndTime, status, postingStatus, oppCoordinatorId, oppCoordinatorEmail, minAttendance, maxAttendance);

      //String orgName = req.params.get('orgName');
      //User hocAdmin = [SELECT Id FROM User WHERE Name =: '0005 HOC Admin'][0];
      //String hocId = hocAdmin.Id;
      //createOrganization(hocId, nonprofitId, orgName);
      // RestContext.response.addHeader('Content-Type', 'application/json');
      // RestContext.response.responseBody = Blob.valueOf('{ "value" : "Hello" }');
      //return '{}';
    }


    // This method creates Occurrences
    public static List<HOC__Occurrence__c> buildOccurrencesList(List<VolunteerLeaderVM> volLeaderVMList, List<User> oppCoordinatorList, String status, String postingStatus){

        List<HOC__Occurrence__c> myOccurrenceList = new List<HOC__Occurrence__c>();

        for(VolunteerLeaderVM myVolLeaderVM : volLeaderVMList){
            HOC__Occurrence__c occRecord = new HOC__Occurrence__c();
            occRecord.HOC__Volunteer_Opportunity__c = myVolLeaderVM.volOppId;
            occRecord.HOC__Location__c = myVolLeaderVM.locationName;
            occRecord.HOC__Start_Date_Time__c = myVolLeaderVM.startDatetime;
            occRecord.HOC__End_Date_Time__c = myVolLeaderVM.stopDatetime;
            occRecord.HOC__Posting_Status__c = postingStatus;
            occRecord.HOC__Status__c = status;

            for(User oppCoordinator : oppCoordinatorList){
                if(oppCoordinator.Email == myVolLeaderVM.newVLEmail){
                    occRecord.HOC__Opportunity_Coordinator__c = oppCoordinator.Id;
                    occRecord.HOC__Volunteer_Coordinator_Email__c = oppCoordinator.Email;
                }
            }
            myOccurrenceList.add(occRecord);
        }
        return myOccurrenceList;
    }
}
