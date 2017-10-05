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

  public class OccurrenceData {
    public DateTime startDate;
    public DateTime endDate;
    public OccurrenceData(DateTime sd, DateTime ed) {
      this.startDate = sd;
      this.endDate = ed;
    }
  }

  // The following method is used to reassign owner of an occurrence
  @HttpPatch
  global static String reassignOccurrence(String volunteerOppId, Datetime startDate, Datetime endDate, String newVLeaderEmail){

    List<HOC__Occurrence__c> occList = [SELECT Id, HOC__Volunteer_Opportunity__c, HOC__Opportunity_Coordinator__c
                                            FROM HOC__Occurrence__c
                                            WHERE HOC__Volunteer_Opportunity__r.Id =: volunteerOppId
                                            AND HOC__Start_Date_Time__c =: startDate
                                            AND HOC__End_Date_Time__c =: endDate];

    if(!occList.isEmpty()){
      HOC__Occurrence__c occ = occList[0];

      User newVLeader = getOppCoordinator(newVLeaderEmail);
      occ.HOC__Opportunity_Coordinator__c = newVLeader.Id;

      try{
        update occ;
        return 'Occurrence Updated! New Opportunity Coordinator assigned!';
      } catch(Exception e){
        System.debug(e);
        return 'Error! Occurrence was not updated!';
      }
    } else {
      System.debug('No occurrence was found with the inputted Start Date, End Date, and Volunteer Opportunity Id!');
      return null;
    }
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

  public static void CreateObjects(String vlEmail, String orgName, String eventName, List<DateTime[]> occurrences) {
    // These calls get the details (like internal identifiers, etc) of each object, creating the object if necessary.
    // Maybe these aren't new classes, but just the built-in classes like User, Account, etc?

    // Commented out because these classes don't exist yet.
    //AccountInfo acct = new AccountInfo(orgName);
    //VolunteerInfo user = new VolunteerInfo(vlEmail);
    //LocationInfo loc = new LocationInfo(); //need address in here etc
    //OpportunityInfo opp = new OpportunityInfo(acct, loc);

    //List<OccurrenceInfo> newOccurrences = new List<OccurrenceInfo>();
    //List<ConnectionInfo> newConnections = new List<ConnectionInfo>();
    //for (OccurrenceData occurrence : occurrences) {
    //  OccurrenceInfo occ = new OccurrenceInfo(opp, user, loc, occurrence);
    //  newOccurrences.add(occ);
    //  newConnections.add(new ConnectionInfo(opp, user, occ));
    //}
  }

    // Creates an organization if it does not already exist
    // @future method since it could be a long running operation
    @future
    public static void createOrganization(String myOrgName, String nonprofitId, String staffId) {

      Account acc = new Account();
      acc.Name = myOrgName;
      acc.OwnerId = staffId;
      acc.RecordTypeId = nonprofitId;
      acc.Type = 'Type';
      acc.HOC__Status__c = 'Active Partner';
      acc.Walk_in_or_Appointment_Only__c = 'Walk-in';
      acc.HOC__Primary_Address__c = 'Shipping';
      acc.HOC__Address_Visibility__c = 'City and Zip only';
      acc.ShippingStreet = '123 Fake Street';
      acc.ShippingCity = 'Fake City';
      acc.ShippingState = 'MA';
      acc.ShippingPostalCode = '02446';
      acc.ShippingCountry = 'USA';
      acc.HOC__Partner_Approval_Manager__c = staffId;
      acc.HOC__Impact_Area__c = 'Adult Education';
      try{
        insert acc;
      } catch(Exception e){
        System.debug(e);
      }
    }


    // This method checks to see if an Org exists, based on the name
    public static Boolean checkOrgExists(String orgName){
      Boolean orgExistsVar;

      List<Account> myOrg = new List<Account>();
      myOrg = [SELECT id FROM Account WHERE Name =: orgName];

      if(myOrg.size()>0){
        orgExistsVar = true;
        return orgExistsVar;
      } else {
        return false;
      }
    }


    // This method returns the id of the user whose CommunityNickname matches
    public static String getBostonCaresStaffUserId(String bosCaresStaffName){
      User myUser = [SELECT Id FROM User WHERE CommunityNickname =: bosCaresStaffName][0];
      if(myUser != null){
            String myUserId = myUser.Id;
          return myUserId;
      } else {
        return null;
      }
    }


    public static String getVolunteerOppId(String myVolOppName){
      HOC__Volunteer_Opportunity__c myVolOpp = [SELECT Id FROM HOC__Volunteer_Opportunity__c WHERE Name =: myVolOppName][0];
      if(myVolOpp != null){
            String myVolunteerOppId = myVolOpp.Id;
          return myVolunteerOppId;
      } else {
        return null;
      }
    }


    public static String getLocationId(String myLocationName){
      HOC__Location__c myLocation = [SELECT Id FROM HOC__Location__c WHERE Name =: myLocationName][0];
      if(myLocation != null){
            String myLocationId = myLocation.Id;
          return myLocationId;
      } else {
        return null;
      }
    }


    public static User getOppCoordinator(String oppCoordinatorEmail){
      User myUser = [SELECT Id FROM User WHERE Email =: oppCoordinatorEmail][0];
      if(myUser != null){
          return myUser;
      } else {
        System.debug('No user with this email was found!');
        return null;
      }
    }


    public static String getOppCoordinatorEmail(String myOppCoordinatorName){
      User myUser = [SELECT Email FROM User WHERE CommunityNickname =: myOppCoordinatorName][0];
      if(myUser != null){
            String myUserEmail = myUser.Email;
          return myUserEmail;
      } else {
        return null;
      }
    }

    // This method creates Occurrences
    @future
    public static void createOccurrence(String volunteerOppId, String locationId, Datetime startTime, Datetime endTime, String status, String postingStatus, String oppCoordinatorId, String oppCoordinatorEmail, Integer minAttendance, Integer maxAttendance){
      HOC__Occurrence__c occRecord = new HOC__Occurrence__c();
        occRecord.HOC__Volunteer_Opportunity__c = volunteerOppId;
        occRecord.HOC__Location__c = locationId;
        occRecord.HOC__Start_Date_Time__c = startTime;
        occRecord.HOC__End_Date_Time__c = endTime;
        occRecord.HOC__Posting_Status__c = postingStatus;
        occRecord.HOC__Status__c = status;
        //occRecord.HOC__Days_Times_Needed__c = 'Tuesday Afternoon';
        occRecord.HOC__Opportunity_Coordinator__c = oppCoordinatorId;
        occRecord.HOC__Volunteer_Coordinator_Email__c = oppCoordinatorEmail;
        insert occRecord;
    }
}
