/*
 * Title: OccurrenceEndpoint
 * Created By: Phil Currier
 * Description: Volunteer Leaders can POST to this endpoint to create Occurrences
 *   (along with any needed parent objects) in the system.
 */

@RestResource(urlMapping='/HOC__Occurrence__c/*')
global with sharing class OccurrenceEndpoint {
    public static ID nonprofitId = schema.SObjectType.Account.getRecordTypeInfosByName().get('Nonprofit').getRecordTypeId();

    @HttpPost
    // Going with parameters - request was to not worry about order
    // Not using JSON since downside of JSON is that the structure is inflexible :(
    global static void postVLSheetUpdates(String accountName, String bosCaresAccountOwnerName, String nonProfitId, String volOppName, String locationName, Datetime occStartTime, Datetime occEndTime, String status, String postingStatus, String bosCaresOppCoordinatorName, Integer minAttendance, Integer maxAttendance) {

      // Call other methods to get the right ids in Salesforce
      // NEED TO FIGURE OUT HOW TO GET THESE INTO ANOTHER CLASS CAUSE THIS WONT WORK
      Boolean orgExists = checkOrgExists(accountName);
      String bosCaresStaffId = getBostonCaresStaffUserId(bosCaresAccountOwnerName);
      String volunteerOppId = getVolunteerOppId(volOppName);
      String locationId = getLocationId(locationName);
      String oppCoordinatorId = getOppCoordinatorId(bosCaresOppCoordinatorName);
      String oppCoordinatorEmail = getOppCoordinatorEmail(bosCaresOppCoordinatorName);

      // Move all Org creation POST logic into another Class called RESTAccountController
      // Have Google sheets call it separately
      if (!orgExists) {
        try {
          createOrganization(accountName, nonProfitId, bosCaresStaffId);
        } catch(Exception e) {
          System.debug(e);
        }
      }

      createOccurrence(volunteerOppId, locationId, occStartTime, occEndTime, status, postingStatus, oppCoordinatorId, oppCoordinatorEmail, minAttendance, maxAttendance);

      //String orgName = req.params.get('orgName');
      //User hocAdmin = [SELECT Id FROM User WHERE Name =: '0005 HOC Admin'][0];
      //String hocId = hocAdmin.Id;
      //createOrganization(hocId, nonprofitId, orgName);
      // RestContext.response.addHeader('Content-Type', 'application/json');
      // RestContext.response.responseBody = Blob.valueOf('{ "value" : "Hello" }');
      //return '{}';
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


    public static String getOppCoordinatorId(String myOppCoordinatorName){
      User myUser = [SELECT Id FROM User WHERE CommunityNickname =: myOppCoordinatorName][0];
      if(myUser != null){
  		    String myUserId = myUser.Id;
          return myUserId;
      } else {
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
