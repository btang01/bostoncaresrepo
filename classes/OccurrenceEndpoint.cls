/*
 * Title: OccurrenceEndpoint
 * Created By: Phil Currier
 * Description: Volunteer Leaders can POST to this endpoint to create Occurrences
 *   (along with any needed parent objects) in the system.
 */

@RestResource(urlMapping='/HOC__Occurrence__c/*')
global with sharing class OccurrenceEndpoint {

    public static Map<String, String> mapVlvmSuccessError;
    public static String dateDelim = '\\|';
    public static String timeDelim = '-';
    public static String rowDelim = '\\<\\<\\|';
    public static String fieldDelim = '\\>\\>\\|';

    public static String OPP_ID = 'ID';
    public static String VL_EMAIL = 'VL Email';
    public static String START_DATE = 'Start Time';
    public static String END_DATE = 'End Time';

    public static Map<String, Integer> fieldPositionMap = new Map<String, Integer>();
    public static ID nonprofitId = schema.SObjectType.Account.getRecordTypeInfosByName().get('Nonprofit').getRecordTypeId();


    public static Id managedConnectionRecordTypeId = Schema.SObjectType.HOC__Connection__c.getRecordTypeInfosByName().get('Managed').getRecordTypeId();


    public static String getFld(String name, String[] fields) {
      return fields[fieldPositionMap.get(name)];
    }


    public static String getSyntheticOccurrenceId(String id, Datetime d) {
      //return id + '_' + d.format('YYYY-MM-dd HH:mm:ss', 'America/New_York');
      return id + '_' + d.format('YYYY-MM-dd', 'America/New_York');
    }


    public class VolunteerLeaderVM{
        public String vlvmId;
        public String volOppId;
        public Datetime startDatetime;
        public Datetime stopDatetime;
        public String newVLEmail;
        public String locationName;
        public Boolean found = FALSE;
        public Boolean successfulUpsert = FALSE;
    }


    // The following method is used to reassign owner of an occurrence
    public static Map<String, String> upsertOccurrence(List<VolunteerLeaderVM> volVmList){
      mapVlvmSuccessError = new Map<String, String>();

      // ***** BUILD A LIST OF RELEVANT VOLUNTEER OP IDs *****
      List<String> relevantVolOppIds = new List<String>();
      // ***** BUILD A LIST OF RELEVANT Contacts *****
      List<String> relevantEmails = new List<String>();

      // Create Ids for the volVmList records
      for(VolunteerLeaderVM vlvm : volVmList){
        vlvm.vlvmId = getSyntheticOccurrenceId(vlvm.volOppId, vlvm.startDatetime);
      }

      for(VolunteerLeaderVM volVM : volVmList){
        relevantVolOppIds.add(volVM.volOppId);
        relevantEmails.add(volVM.newVLEmail);
      }

      List<Contact> existingContacts = [SELECT Id, Email FROM Contact WHERE Email IN: relevantEmails];

      List<HOC__Occurrence__c> existingOccs = returnExistingOccurrences(relevantVolOppIds);
      List<HOC__Volunteer_Opportunity__c> existingVolOpps = returnExistingVolOpps(relevantVolOppIds);

      // NEED TO BUILD A MAP OF VOL OPP AND LOCATION FOR INSERTING NEW OCCs
      Map<Id, List<String>> mapKeyVolOppIdValueLocationId = returnVolOppLocationMap(existingVolOpps);

      List<HOC__Occurrence__c> listOfOccurrencesToUpdate = returnListOfOccsToUpdate(volVmList, existingOccs, existingContacts);

      List<HOC__Occurrence__c> listOfOccurrencesToInsert = returnListOfOccsToInsert(volVmList, existingOccs, existingContacts, mapKeyVolOppIdValueLocationId);

      // *** START BUILDING LIST OF OCCURRENCES TO UPSERT
      // list of Occurrences to Update + list of Occurrences to Insert
      List<HOC__Occurrence__c> allOccurrencesToUpsert = new List<HOC__Occurrence__c>();
      
      if(listOfOccurrencesToUpdate != null && !listOfOccurrencesToUpdate.isEmpty()){
        allOccurrencesToUpsert.addAll(listOfOccurrencesToUpdate);
      }

      if(listOfOccurrencesToInsert != null && !listOfOccurrencesToInsert.isEmpty()){
          allOccurrencesToUpsert.addAll(listOfOccurrencesToInsert);
      }
      // *** DONE BUILDING LIST OF OCCURRENCES TO UPSERT ***

      if(allOccurrencesToUpsert != null && !allOccurrencesToUpsert.isEmpty()){
        mapVlvmSuccessError = upsertOccsAndReturnResult(allOccurrencesToUpsert, HOC__Occurrence__c.Id, true, volVmList);

        declineExistingVolLeaderConnections(volVmList, allOccurrencesToUpsert);
      }
      return mapVlvmSuccessError;
    }


    public static List<HOC__Occurrence__c> returnExistingOccurrences(List<String> myVolOppIds){
      List<HOC__Occurrence__c> myExistingOccs = [
          SELECT Id, HOC__Start_Date_Time__c, HOC__End_Date_Time__c,
          HOC__Volunteer_Opportunity__c, HOC__Opportunity_Coordinator__c
          FROM HOC__Occurrence__c
          WHERE HOC__Start_Date_Time__c >: System.Now()
          AND HOC__Volunteer_Opportunity__r.Id IN: myVolOppIds];

      return myExistingOccs;
    }


    public static List<HOC__Volunteer_Opportunity__c> returnExistingVolOpps(List<String> myExistingVolOppIds){
      List<HOC__Volunteer_Opportunity__c> myExistingVolOpps = [
        SELECT Id, HOC__Default_Location__r.Id
        FROM HOC__Volunteer_Opportunity__c
        WHERE Id IN: myExistingVolOppIds
      ];

      return myExistingVolOpps;
    }


    public static Map<String, String> upsertOccsAndReturnResult(List<HOC__Occurrence__c> myOccsToUpsert, Schema.SObjectField myMatchingIdField, Boolean allOrNoneFlag, List<VolunteerLeaderVM> volVmListParam){

      Map<String, String> returnSuccessErrorMessage = new Map<String, String>();

      List<Database.upsertResult> srList = Database.upsert(myOccsToUpsert, myMatchingIdField, allOrNoneFlag);
      List<HOC__Occurrence__c> successOccurrencesList = new List<HOC__Occurrence__c>();

      Set<Id> updatedOccsIdSet = new Set<Id>();
      Set<Id> createdOccsIdSet = new Set<Id>();

      if(myOccsToUpsert != null && !myOccsToUpsert.isEmpty()){
        for(Database.upsertResult sr : srList){
          if(sr.isSuccess()){
            String successId = sr.getId();

            for(VolunteerLeaderVM vlvm : volVmListParam){
              for(HOC__Occurrence__c myOcc : myOccsToUpsert){
                if(myOcc.Id == successId &&
                    vlvm.vlvmId == getSyntheticOccurrenceId(myOcc.HOC__Volunteer_Opportunity__c, myOcc.HOC__Start_Date_Time__c)){
                    successOccurrencesList.add(myOcc);
                    returnSuccessErrorMessage.put(vlvm.vlvmId, 'SUCCESS');
                }
              }
            }
          }
        }

        for(VolunteerLeaderVM vlvm : volVmListParam){
            for(HOC__Occurrence__c goodOccs : successOccurrencesList){
                if(vlvm.vlvmId == getSyntheticOccurrenceId(goodOccs.HOC__Volunteer_Opportunity__c, goodOccs.HOC__Start_Date_Time__c)){
                    vlvm.successfulUpsert = true;
                }
            }
        }

        for(VolunteerLeaderVM vlvm : volVmListParam){
            if(vlvm.successfulUpsert == false){
                returnSuccessErrorMessage.put(vlvm.vlvmId, 'ERROR');
            }
        }

        return returnSuccessErrorMessage;

      } else {
          System.debug('Nothing valid to upsert!');
          for(VolunteerLeaderVM vlvm : volVmListParam){
              returnSuccessErrorMessage.put(vlvm.vlvmId, 'ERROR');
          }
          return returnSuccessErrorMessage;
      }
    }


    public static Map<Id, List<String>> returnVolOppLocationMap(List<HOC__Volunteer_Opportunity__c> myVolOpps){

      Map<Id, List<String>> myVolOppLocationMap = new Map<Id, List<String>>();

      for(HOC__Volunteer_Opportunity__c vOpp : myVolOpps){
          if(myVolOppLocationMap.containsKey(vOpp.Id)){
              List<String> innerList = myVolOppLocationMap.get(vOpp.Id);
              innerList.add(vOpp.HOC__Default_Location__r.Id);
          } else {
              List<String> innerList = new List<String>();
              innerList.add(vOpp.HOC__Default_Location__r.Id);
              myVolOppLocationMap.put(vOpp.Id, innerList);
          }
      }

      return myVolOppLocationMap;
    }


    public static List<HOC__Occurrence__c> returnListOfOccsToUpdate(List<VolunteerLeaderVM> myVolVMList, List<HOC__Occurrence__c> myOccList, List<Contact> myContactList){

        // Add to this list and update these Occurrences
        List<HOC__Occurrence__c> myOccListToUpdate = new List<HOC__Occurrence__c>();

        for(VolunteerLeaderVM volVM : myVolVMList){
            if(!myOccList.isEmpty()){
                // Match Occurrence record to the info in the VL VM
                // Using a combination of Volunteer Opportunity ID and Start Date
                for(HOC__Occurrence__c occ : myOccList){
                    if((occ.HOC__Start_Date_Time__c != null &&
                        (occ.HOC__Start_Date_Time__c.date() == volVM.startDatetime.date())) &&
                        (occ.HOC__Volunteer_Opportunity__c != null &&
                        (occ.HOC__Volunteer_Opportunity__c == volVM.VolOppId))){

                        // Great success, I've found my occurrence!
                        // Now reassign the Volunteer Coordinator
                        for(Contact myCon : myContactList){
                            if(volVM.newVLEmail == myCon.Email){
                                occ.HOC__Opportunity_Coordinator__c = myCon.Id;
                                occ.HOC__Volunteer_Coordinator_Email__c = myCon.Email;
                                myOccListToUpdate.add(occ);
                            } else {
                                System.debug('Existing Contact cannot be found with this Email!');
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


    public static List<HOC__Occurrence__c> returnListOfOccsToInsert(List<VolunteerLeaderVM> myVolVMList, List<HOC__Occurrence__c> myOccList, List<Contact> myContactList, Map<Id, List<String>> myVolOppLocMap){
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
                (occ.HOC__Start_Date_Time__c.date() == volVM.startDatetime.date())) &&
                (occ.HOC__Volunteer_Opportunity__c != null &&
                (occ.HOC__Volunteer_Opportunity__c == volVM.VolOppId))){

                volVM.found = TRUE;
            }
          }
        }
      }

      for(VolunteerLeaderVM volVMUpdated : myVolVMList){
          if(!volVMUpdated.found){
              nonMatchingVLVMList.add(volVMUpdated);
          }
      }

      myOccListInsert = buildOccurrencesToInsertList(nonMatchingVLVMList, myContactList, myVolOppLocMap, 'Active', 'This is approved and published for volunteers to sign-up.');
      return myOccListInsert;
    }


    // This method creates Occurrences
    public static List<HOC__Occurrence__c> buildOccurrencesToInsertList(List<VolunteerLeaderVM> volLeaderVMList, List<Contact> oppCoordinatorList, Map<Id, List<String>> myVolOppLocationMap, String status, String postingStatus){

        List<HOC__Occurrence__c> myOccurrenceList = new List<HOC__Occurrence__c>();

        for(VolunteerLeaderVM myVolLeaderVM : volLeaderVMList){
            Boolean createThisOccurrence = false;

            HOC__Occurrence__c occRecord = new HOC__Occurrence__c();
            occRecord.HOC__Volunteer_Opportunity__c = myVolLeaderVM.volOppId;
            occRecord.HOC__Start_Date_Time__c = myVolLeaderVM.startDatetime;
            occRecord.HOC__End_Date_Time__c = myVolLeaderVM.stopDatetime;
            occRecord.HOC__Status__c = status;
            occRecord.HOC__Posting_Status__c = postingStatus;

            for(Id volOppId : myVolOppLocationMap.keySet()){
                String locationIdString = myVolOppLocationMap.get(volOppId)[0];
                if(volOppId == occRecord.HOC__Volunteer_Opportunity__c){
                    occRecord.HOC__Location__c = locationIdString;
                } else {
                    System.debug('No Location found for this vm!');
                }
            }

            for(Contact oppCoordinator : oppCoordinatorList){
                if(oppCoordinator.Email == myVolLeaderVM.newVLEmail){
                    occRecord.HOC__Opportunity_Coordinator__c = oppCoordinator.Id;
                    occRecord.HOC__Volunteer_Coordinator_Email__c = oppCoordinator.Email;

                    createThisOccurrence = true;
                }
            }

            if(createThisOccurrence == true){
                myOccurrenceList.add(occRecord);
            } else {
                System.debug('No matching Contact found so did not add Occurrence to insert list!');
            }
        }
        return myOccurrenceList;
    }


    public static void declineExistingVolLeaderConnections(List<VolunteerLeaderVM> listOfVlvm, List<HOC__Occurrence__c> myOccsToUpsert){
      List<HOC__Connection__c> connectionsToDecline = returnConnectionsToDecline(listOfVlvm, myOccsToUpsert);

      if(connectionsToDecline != null && connectionsToDecline.size()>0){
        for(HOC__Connection__c connection : connectionsToDecline){
          connection.HOC__Status__c = 'Declined';
          connection.HOC__Attendance_Status__c = 'Declined';
        }

        try{
          update connectionsToDecline;
        } catch (Exception e){
          System.debug(e);
        }
      }
    }
    

    public static List<HOC__Connection__c> returnConnectionsToDecline(List<VolunteerLeaderVM> myVlvms, List<HOC__Occurrence__c> occList){

      List<HOC__Connection__c> listOfConnectionsToDecline = new List<HOC__Connection__c>();
      Set<Id> relevantOccIds = new Set<Id>();

      for(HOC__Occurrence__c occ : occList){
        relevantOccIds.add(occ.Id);
      }

      List<HOC__Connection__c> listOfVolLeaderConnections = 
        [SELECT Id, HOC__Start_Date_Time__c, HOC__Contact_Email__c
          FROM HOC__Connection__c
          WHERE HOC__Occurrence__c IN: relevantOccIds
          AND HOC__Role__c = 'Volunteer Leader'
          AND HOC__Status__c = 'Confirmed'
          AND HOC__Attendance_Status__c = 'Please Verify'];

      for(VolunteerLeaderVM volVm : myVlvms){
        for(HOC__Connection__c relevantConnection : listOfVolLeaderConnections){
          if(volVM.startDatetime == relevantConnection.HOC__Start_Date_Time__c
            && volVM.newVLEmail != relevantConnection.HOC__Contact_Email__c){
            listOfConnectionsToDecline.add(relevantConnection);
          }
        }
      }
      return listOfConnectionsToDecline;
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

      List<VolunteerLeaderVM> occurrences = new List<VolunteerLeaderVM>();

      // Go through the records we received
      for (Integer i = 1; i < rows.size(); i++) {
        String[] fields = rows[i].split(fieldDelim);
        String oppId = getFld(OPP_ID, fields);
        String vlEmail = getFld(VL_EMAIL, fields);
        String sd = getFld(START_DATE, fields);
        String[] sp = sd.split('[ \\/\\-:]');
        String ed = getFld(END_DATE, fields);
        String[] ep = ed.split('[ \\/\\-:]');
        VolunteerLeaderVM newocc = new VolunteerLeaderVM();
        newocc.volOppId = oppId;
        newocc.newVLEmail = vlEmail;
        newocc.startDateTime = DateTime.newInstance(
            Integer.valueOf(sp[0]),
            Integer.valueOf(sp[1]),
            Integer.valueOf(sp[2]),
            Integer.valueOf(sp[3]),
            Integer.valueOf(sp[4]),
            0
        );
        newocc.stopDateTime = DateTime.newInstance(
            Integer.valueOf(ep[0]),
            Integer.valueOf(ep[1]),
            Integer.valueOf(ep[2]),
            Integer.valueOf(ep[3]),
            Integer.valueOf(ep[4]),
            0
        );
        occurrences.add(newocc);
        //dt.substring(0, 4)

        upsertOccurrence(occurrences);
      }

      Integer i = 0;
      for (String key : mapVlvmSuccessError.keySet()) {
        String result = mapVlvmSuccessError.get(key);
        if (i > 0) {
          response += rowDelim.replace('\\', '');
        }
        response += key + fieldDelim.replace('\\', '') + result;
        i++;
      }
      RestContext.response.responseBody = Blob.valueOf(response);
    }
}