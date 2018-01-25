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

        List<HOC__Occurrence__c> existingOccs = [
            SELECT Id, HOC__Start_Date_Time__c, HOC__End_Date_Time__c,
            HOC__Volunteer_Opportunity__c, HOC__Opportunity_Coordinator__c
            FROM HOC__Occurrence__c
            WHERE HOC__Start_Date_Time__c >: System.Now()
            AND HOC__Volunteer_Opportunity__r.Id IN: relevantVolOppIds];

        List<HOC__Volunteer_Opportunity__c> existingVolOpps = [
            SELECT Id, HOC__Default_Location__r.Id
            FROM HOC__Volunteer_Opportunity__c
            WHERE Id IN: relevantVolOppIds];

        // NEED TO BUILD A MAP OF VOL OPP AND LOCATION FOR INSERTING NEW OCCs
        Map<Id, List<String>> mapKeyVolOppIdValueLocationId = new Map<Id, List<String>>();

        for(HOC__Volunteer_Opportunity__c vOpp : existingVolOpps){
            if(mapKeyVolOppIdValueLocationId.containsKey(vOpp.Id)){
                List<String> innerList = mapKeyVolOppIdValueLocationId.get(vOpp.Id);
                innerList.add(vOpp.HOC__Default_Location__r.Id);
            } else {
                List<String> innerList = new List<String>();
                innerList.add(vOpp.HOC__Default_Location__r.Id);
                mapKeyVolOppIdValueLocationId.put(vOpp.Id, innerList);
            }
        }

        List<HOC__Occurrence__c> listOfOccurrencesToUpdate = returnListOfOccsToUpdate(volVmList, existingOccs, existingContacts);

        List<HOC__Occurrence__c> listOfOccurrencesToInsert = returnListOfOccsToInsert(volVmList, existingOccs, existingContacts, mapKeyVolOppIdValueLocationId);

        List<HOC__Occurrence__c> allOccurrencesToUpsert = new List<HOC__Occurrence__c>();

        if(listOfOccurrencesToUpdate != null && !listOfOccurrencesToUpdate.isEmpty()){
            allOccurrencesToUpsert.addAll(listOfOccurrencesToUpdate);
        }

        if(listOfOccurrencesToInsert != null && !listOfOccurrencesToInsert.isEmpty()){
            allOccurrencesToUpsert.addAll(listOfOccurrencesToInsert);
        }

        List<HOC__Occurrence__c> successOccurrencesList = new List<HOC__Occurrence__c>();

        if(allOccurrencesToUpsert != null && !allOccurrencesToUpsert.isEmpty()){

            // BUILD SUCCESS LIST OF VMs
            List<Database.upsertResult> srList = Database.upsert(allOccurrencesToUpsert, HOC__Occurrence__c.Id, true);

            for(Database.upsertResult sr : srList){
                if(sr.isSuccess()){
                    String successId = sr.getId();

                    for(VolunteerLeaderVM vlvm : volVmList){
                        for(HOC__Occurrence__c myOcc : allOccurrencesToUpsert){

                            if(myOcc.Id == successId &&
                                vlvm.vlvmId == getSyntheticOccurrenceId(myOcc.HOC__Volunteer_Opportunity__c, myOcc.HOC__Start_Date_Time__c)){
                                successOccurrencesList.add(myOcc);
                                mapVlvmSuccessError.put(vlvm.vlvmId, 'SUCCESS');
                            }
                        }
                    }
                }
            }

            // BUILD ERROR LIST OF VMs
            for(VolunteerLeaderVM vlvm : volVmList){
                for(HOC__Occurrence__c goodOccs : successOccurrencesList){
                    if(vlvm.vlvmId == getSyntheticOccurrenceId(goodOccs.HOC__Volunteer_Opportunity__c, goodOccs.HOC__Start_Date_Time__c)){
                        vlvm.successfulUpsert = true;
                    }
                }
            }

            for(VolunteerLeaderVM vlvm : volVmList){
                if(vlvm.successfulUpsert == false){
                    mapVlvmSuccessError.put(vlvm.vlvmId, 'ERROR');
                }
            }

            return mapVlvmSuccessError;

        } else {
            System.debug('Nothing valid to upsert!');
            mapVlvmSuccessError.put('defaultResult', 'ERROR');
            return mapVlvmSuccessError;
        }
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

        myOccListInsert = buildOccurrencesList(nonMatchingVLVMList, myContactList, myVolOppLocMap, 'Active');
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
      System.debug('phil response ' + response);
      RestContext.response.responseBody = Blob.valueOf(response);
    }


    // This method creates Occurrences
    public static List<HOC__Occurrence__c> buildOccurrencesList(List<VolunteerLeaderVM> volLeaderVMList, List<Contact> oppCoordinatorList, Map<Id, List<String>> myVolOppLocationMap, String status){

        List<HOC__Occurrence__c> myOccurrenceList = new List<HOC__Occurrence__c>();

        for(VolunteerLeaderVM myVolLeaderVM : volLeaderVMList){
            Boolean createThisOccurrence = false;

            HOC__Occurrence__c occRecord = new HOC__Occurrence__c();
            occRecord.HOC__Volunteer_Opportunity__c = myVolLeaderVM.volOppId;
            occRecord.HOC__Start_Date_Time__c = myVolLeaderVM.startDatetime;
            occRecord.HOC__End_Date_Time__c = myVolLeaderVM.stopDatetime;
            occRecord.HOC__Status__c = status;

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

}
