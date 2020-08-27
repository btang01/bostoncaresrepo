/* Created By: Brian Tang
* Description: Test Coverage for OccurrenceEndPoint class
* There is wonky trigger functionality
* preventing me from kicking off the triggers
* that auto-creates Connections and updates existing Connections.
* Due to the fact that we cannot see inside the managed package,
* cannot guarantee auto-test coverage effectively tests 
* all scenarios
*/

@isTest
private class OccurrenceEndpointTest {

	public static ID eitcId = schema.SObjectType.Account.getRecordTypeInfosByName().get('EITC Site').getRecordTypeId();
	public static UserRole myUserRole = [SELECT Id FROM UserRole WHERE PortalType =: 'CustomerPortal' AND PortalRole = 'Worker'][0];
	public static String test2CustomerId = myUserRole.Id; 
	public static ID volOppEitcId = schema.SObjectType.HOC__Volunteer_Opportunity__c.getRecordTypeInfosByName().get('EITC Site').getRecordTypeId();
	public static Datetime testDatetime = System.now();

	@isTest static void testOccurrenceEndpointReassignOccurrence() {

			User emily = [SELECT Id FROM User WHERE CommunityNickname =: 'erackleff'][0];
			String emilyId = emily.Id;

			// Create an Organization
			Account acc = returnAccount(emilyId);
			insert acc;

			// Create Volunteers
			List<Contact> conList = new List<Contact>();

			Contact con = new Contact();
			con.HOC__Username__c = 'tester12365@bostoncares.org';
			con.HOC__Registration_Status__c = 'Registered';
			con.FirstName = 'Test';
			con.LastName = 'User1';
			con.AccountId = acc.id;
			con.HOC__Primary_Phoneno__c = 'Home';
			con.Email = 'test@bostoncares.org';
			con.HOC__Primary_Address__c = 'Home';
			con.MailingStreet = '234 Fake Street';
			con.MailingCity = 'Boston';
			con.MailingState = 'MA';
			con.MailingPostalCode = '02446';
			con.MailingCountry = 'USA';
			con.Birthdate = System.Today().addYears(-25);
			con.HOC__Orientation_Completed__c = TRUE;
			con.VL_Training_Completed__c = TRUE;
			con.HOC__Registration_Status__c = 'Registered';
			con.HOC__Contact_Login_Profile__c = 'Volunteer Leader';
			conList.add(con);

			Contact con2 = new Contact();
			con2.HOC__Username__c = 'tester12366@bostoncares.org';
			con2.HOC__Registration_Status__c = 'Registered';
			con2.FirstName = 'Test2';
			con2.LastName = 'User2';
			con2.AccountId = acc.id;
			con2.HOC__Primary_Phoneno__c = 'Home';
			con2.Email = 'test2@bostoncares.org';
			con2.HOC__Primary_Address__c = 'Home';
			con2.MailingStreet = '567 Fake Street';
			con2.MailingCity = 'Boston';
			con2.MailingState = 'MA';
			con2.MailingPostalCode = '02446';
			con2.MailingCountry = 'USA';
			con2.Birthdate = System.Today().addYears(-30);
			con2.HOC__Orientation_Completed__c = TRUE;
			con2.VL_Training_Completed__c = TRUE;
			con2.HOC__Registration_Status__c = 'Registered';
			conList.add(con2);

			insert conList;

			// You cannot simply insert a Contact with this value populated
			// HOC trigger only kicks in properly if you update the Contact
			con2.HOC__Contact_Login_Profile__c = 'Volunteer Leader';
			update con2;


			// **** START CREATE SUPER USER ****
			String uniqueUserName = 'standarduser' + DateTime.now().getTime() + '@testorg.com';
	        
	        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
	        
	        User superUser = new User(Alias = 'standt', Email='standarduser@testorg.com',
	        EmailEncodingKey = 'UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
	        LocaleSidKey = 'en_US', ProfileId = p.Id,
	        TimeZoneSidKey = 'America/Los_Angeles',
	        UserName = uniqueUserName);

	        insert superUser;
	        // **** END CREATE SUPER USER ****

			// Create a Zip Code
			HOC__ZipCode__c zipCodeRecord = new HOC__ZipCode__c();
			zipCodeRecord.Name = '02446';
			insert zipCodeRecord;

			// Create a Location
			HOC__Location__c locationRecord = returnLocationRecord(zipCodeRecord.id, acc.id);
			insert locationRecord;

			// Create a Volunteer Opportunity
			HOC__Volunteer_Opportunity__c voloppRecord = returnVolOppRecord(volOppEitcId, acc.Id, locationRecord.Id, con.Id);
			insert voloppRecord;

			// Create an Occurrence
			HOC__Occurrence__c occRecord = returnOccRecord(volOppRecord.Id, locationRecord.Id, 3, 4, con.Id, superUser.Id);
			insert occRecord;

			// Create a Connection
			HOC__Connection__c connectionRecord = returnConnectionRecord(volOppRecord.Id, occRecord.Id, con.Id, occRecord.HOC__Start_Date_Time__c);
			insert connectionRecord;

			// There is an HOC Trigger that prevents me from inserting a connection record
			// with Volunteer Leader Role - I can only update to VL - whatever.
			connectionRecord.HOC__Role__c = 'Volunteer Leader';
			update connectionRecord;

			List<OccurrenceEndpoint.OccurrenceReassignRequest> occReassignReqList = new List<OccurrenceEndpoint.OccurrenceReassignRequest>();

			// This is an occurrence to update
			OccurrenceEndpoint.OccurrenceReassignRequest occReassignReq1 = returnOccReassignReq(volOppRecord.Id, 'test2@bostoncares.org', 'Test Location', 3, 4);

			// This is an occurrence to insert
			OccurrenceEndpoint.OccurrenceReassignRequest occReassignReq2 = returnOccReassignReq(volOppRecord.Id, 'test2@bostoncares.org', 'Test Location', 5, 6);

			// This is a bad occurrence request
			OccurrenceEndpoint.OccurrenceReassignRequest myBadOccReassignReq = new OccurrenceEndpoint.OccurrenceReassignRequest();
			myBadOccReassignReq.newVLEmail = 'kapooey@badEmail923.com';
			myBadOccReassignReq.volOppId = volOppRecord.Id;
			myBadOccReassignReq.locationName = 'badLocation';
			myBadOCcReassignReq.startDatetime = System.now();

			occReassignReqList.add(occReassignReq1);
			occReassignReqList.add(occReassignReq2);
			occReassignReqList.add(myBadOccReassignReq);

			OccurrenceEndpoint.upsertOccurrence(occReassignReqList);

			List<HOC__Occurrence__c> resultOccurrences = new List<HOC__Occurrence__c>();

			resultOccurrences = [SELECT Id, HOC__Volunteer_Coordinator_Email__c, HOC__Start_Date_Time__c
									FROM HOC__Occurrence__c
									WHERE HOC__Volunteer_Opportunity__c =: voloppRecord.Id];

			Datetime compareDatetime = testDatetime.addDays(3);

			HOC__Occurrence__c updatedOccurrence = [SELECT Id, HOC__Volunteer_Coordinator_Email__c
													FROM HOC__Occurrence__c
													WHERE HOC__Volunteer_Opportunity__c =: voloppRecord.Id
													AND HOC__Start_Date_Time__c =: compareDatetime][0];

			// Verify that we now have 2 Occurrences instead of 1 for that Vol Opp
			System.assert(resultOccurrences.size() == 2, 'An occurrence was not created properly!');

            List<HOC__Connection__c> listOfVolLeaderConnections =
		        [SELECT Id, HOC__Start_Date_Time__c, HOC__Contact_Email__c,
		        	HOC__Role__c, HOC__Status__c, HOC__Attendance_Status__c,
		        	HOC__Occurrence__c
		          FROM HOC__Connection__c
		          WHERE HOC__Occurrence__c =: updatedOccurrence.Id];

		    System.debug(listOfVolLeaderConnections);
		    System.debug('New number of VL Connections: ' + listOfVolLeaderConnections.size());
		    System.debug(occReassignReq1);
		    System.debug('Number of Result Occurrences: ' + resultOccurrences.size());
		    System.debug(resultOccurrences);
		    System.debug(updatedOccurrence);

			// Verify that the existing occurrence's Volunteer Coordinator was updated
			System.assert(updatedOccurrence.HOC__Volunteer_Coordinator_Email__c == 'test2@bostoncares.org', 'The occurrence was not reassigned as expected!');
		}

		@isTest static void postVLSheetUpdates(){
			try{
				OccurrenceEndpoint.postVLSheetUpdates();
			} catch (Exception e){
				System.debug(e);
			}
		}


		public static Account returnAccount(String partnerApprovalManagerId){
			Account myAccount = new Account();

			myAccount.Name = 'Test Nonprofit 1';
			myAccount.RecordTypeId = eitcId;
			myAccount.HOC__Status__c = 'Active Partner';
			myAccount.Walk_in_or_Appointment_Only__c = 'Walk-in';
			myAccount.HOC__Primary_Address__c = 'Shipping';
			myAccount.HOC__Address_Visibility__c = 'City and Zip only';
			myAccount.ShippingStreet = '123 Fake Street';
			myAccount.ShippingCity = 'Fake City';
			myAccount.ShippingState = 'MA';
			myAccount.ShippingPostalCode = '02446';
			myAccount.ShippingCountry = 'USA';
			myAccount.HOC__Partner_Approval_Manager__c = partnerApprovalManagerId;
			myAccount.HOC__Impact_Area__c = 'Adult Education';

			return myAccount;
		}


		public static HOC__Location__c returnLocationRecord(String zipCodeRecordId, String accId){
			HOC__Location__c myLocationRecord = new HOC__Location__c();
			myLocationRecord.Name = 'Test Location';
			myLocationRecord.HOC__Street__c = 'Test Street';
			myLocationRecord.HOC__City__c = 'Test City';
			myLocationRecord.HOC__Zip_Postal_Code__c = zipCodeRecordId;
			myLocationRecord.HOC__Zip_Code__c = '02446';
			myLocationRecord.HOC__Country__c = 'USA';
			myLocationRecord.HOC__Organization__c = accId;
			return myLocationRecord;
		}


		public static HOC__Volunteer_Opportunity__c returnVolOppRecord(String myVolOppEitcId, String accId, String locationRecordId, String conId){

			HOC__Volunteer_Opportunity__c myVoloppRecord = new HOC__Volunteer_Opportunity__c();

			myVoloppRecord.Name = 'Test project';
			myVoloppRecord.HOC__Status__c = 'Pending';
			myVoloppRecord.HOC__Posting_Status__c = 'This is not published. Please submit for approval.';
			myVoloppRecord.RecordTypeId = myVolOppEitcId;
			myVoloppRecord.HOC__Type__c = 'Project';
			myVoloppRecord.HOC__Schedule_Type__c = 'Date & Time Specific';
			myVoloppRecord.HOC__Disaster_Opportunity_Type__c = 'Not Disaster Related';
			myVoloppRecord.HOC__Start_Date__c = System.Today().addDays(-30);
			myVoloppRecord.HOC__End_Date__c = System.Today().addDays(30);
			myVoloppRecord.HOC__Managed_By__c = 'Partner';
			myVoloppRecord.HOC__Organization_Served__c = accId;
			myVoloppRecord.HOC__Default_Location__c = locationRecordId;
			myVoloppRecord.HOC__Registration_Type__c = 'Sign Up';
			myVoloppRecord.HOC__Apply_Restrictions_to_Opportunity__c = 'Apply Restrictions';
			myVoloppRecord.HOC__Registration_Deadline__c = 1;
			myVoloppRecord.HOC__Maximum_Attendance__c = 2;
			myVoloppRecord.HOC__Minimum_Attendance__c = 1;
			myVoloppRecord.HOC__Opportunity_Coordinator__c = conId;
			myVoloppRecord.HOC__Minimum_Age_w_adult__c = 18;
			myVoloppRecord.HOC__Minimum_Age_w_o_adult__c = 18;
			myVoloppRecord.HOC__Orientation_Required__c = TRUE;
			myVoloppRecord.HOC__Skilled_Volunteer_Required__c = 'No';
			myVoloppRecord.HOC__Primary_Impact_Area__c = 'Adult Education';
			myVoloppRecord.HOC__Genders_Served__c = 'All Genders Served';
			myVoloppRecord.HOC__Impact_Area_Local__c = 'Boston Cares Programming & Support';
			myVoloppRecord.HOC__Program_Area_Local__c = 'Calendar';
			myVoloppRecord.HOC__Available_Languages__c = 'English';

			return myVoloppRecord;
		}


		public static HOC__Occurrence__c returnOccRecord(Id myVolOppId, Id myLocId, Integer startDateTimeAddDays, Integer stopDateTimeAddDays, Id conId, Id userId){
			HOC__Occurrence__c myOccRecord = new HOC__Occurrence__c();

			myOccRecord.HOC__Volunteer_Opportunity__c = myVolOppId;
			myOccRecord.HOC__Location__c = myLocId;
			myOccRecord.HOC__Start_Date_Time__c = testDatetime.addDays(startDateTimeAddDays);
			myOccRecord.HOC__End_Date_Time__c = testDatetime.addDays(stopDateTimeAddDays);
			myOccRecord.HOC__Posting_Status__c = 'This is not published. The Volunteer Opportunity is not active.';
			myOccRecord.HOC__Status__c = 'Active';
			//occRecord.HOC__Days_Times_Needed__c = 'Tuesday Afternoon';
			myOccRecord.HOC__Opportunity_Coordinator__c = conId;
			myOccRecord.OwnerId = userId;

			return myOccRecord;
		}


		public static HOC__Connection__c returnConnectionRecord(Id myVolOppId, Id myOccId, Id myConId, Datetime occStartDateTime){
			HOC__Connection__c myConnectionRecord = new HOC__Connection__c();

			myConnectionRecord.HOC__Volunteer_Opportunity__c = myVolOppId;
			myConnectionRecord.HOC__Occurrence__c = myOccId;
			myConnectionRecord.HOC__Contact__c = myConId;
			myConnectionRecord.HOC__Role__c = 'Volunteer';
			myConnectionRecord.HOC__Status__c = 'Confirmed';
			myConnectionRecord.HOC__Attendance_Status__c = 'Please Verify';
			myConnectionRecord.HOC__Start_Date_Time__c = occStartDateTime;

			return myConnectionRecord;
		}


		public static OccurrenceEndpoint.OccurrenceReassignRequest returnOccReassignReq(Id myVolOppId, String myNewVLEmail, String myNewLocName, Integer startDateTimeAddDays, Integer stopDateTimeAddDays){
			OccurrenceEndpoint.OccurrenceReassignRequest occReassignReq = new OccurrenceEndpoint.OccurrenceReassignRequest();
			occReassignReq.volOppId = myVolOppId;
			occReassignReq.startDatetime = testDatetime.addDays(startDateTimeAddDays);
			occReassignReq.stopDatetime = testDatetime.addDays(stopDateTimeAddDays);
			occReassignReq.newVLEmail = myNewVLEmail;
			occReassignReq.locationName = myNewLocName;

			return occReassignReq;
		}

}