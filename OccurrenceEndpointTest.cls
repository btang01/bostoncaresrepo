@isTest
private class OccurrenceEndpointTest {

	@isTest static void testOccurrenceEndpoint() {

			// Get the RecordTypeId
			ID eitcId = schema.SObjectType.Account.getRecordTypeInfosByName().get('EITC Site').getRecordTypeId();

			ID volOppEitcId = schema.SObjectType.HOC__Volunteer_Opportunity__c.getRecordTypeInfosByName().get('EITC Site').getRecordTypeId();

			User emily = [SELECT Id FROM User WHERE CommunityNickname =: 'erackleff'][0];
			String emilyId = emily.Id;

			// Create an Organization
			Account acc = new Account();
			acc.Name = 'Test Nonprofit 1';
			acc.RecordTypeId = eitcId;
			acc.HOC__Status__c = 'Active Partner';
			acc.Walk_in_or_Appointment_Only__c = 'Walk-in';
			acc.HOC__Primary_Address__c = 'Shipping';
			acc.HOC__Address_Visibility__c = 'City and Zip only';
			acc.ShippingStreet = '123 Fake Street';
			acc.ShippingCity = 'Fake City';
			acc.ShippingState = 'MA';
			acc.ShippingPostalCode = '02446';
			acc.ShippingCountry = 'USA';
			acc.HOC__Partner_Approval_Manager__c = emilyId;
			acc.HOC__Impact_Area__c = 'Adult Education';
			insert acc;

			// Create Volunteers
			List<Contact> conList = new List<Contact>();

			Contact con = new Contact();
			con.HOC__Username__c = 'test@bostoncares.org';
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
			conList.add(con);

			Contact con2 = new Contact();
			con2.HOC__Username__c = 'test2@bostoncares.org';
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
			conList.add(con2);

			insert conList;

			// Create a Zip Code
			HOC__ZipCode__c zipCodeRecord = new HOC__ZipCode__c();
			zipCodeRecord.Name = '02446';
			insert zipCodeRecord;

			// Create a Location
			HOC__Location__c locationRecord = new HOC__Location__c();
			locationRecord.Name = 'Test Location';
			locationRecord.HOC__Street__c = 'Test Street';
			locationRecord.HOC__City__c = 'Test City';
			locationRecord.HOC__Zip_Postal_Code__c = zipCodeRecord.id;
			locationRecord.HOC__Zip_Code__c = '02446';
			locationRecord.HOC__Country__c = 'USA';
			locationRecord.HOC__Organization__c = acc.id;
			insert locationRecord;

			// Create a Volunteer Opportunity
			HOC__Volunteer_Opportunity__c voloppRecord = new HOC__Volunteer_Opportunity__c();
			voloppRecord.Name = 'Test project';
			voloppRecord.HOC__Status__c = 'Pending';
			voloppRecord.HOC__Posting_Status__c = 'This is not published. Please submit for approval.';
			voloppRecord.RecordTypeId = volOppEitcId;
			voloppRecord.HOC__Type__c = 'Project';
			voloppRecord.HOC__Schedule_Type__c = 'Date & Time Specific';
			voloppRecord.HOC__Disaster_Opportunity_Type__c = 'Not Disaster Related';
			voloppRecord.HOC__Start_Date__c = System.Today().addDays(-30);
			voloppRecord.HOC__End_Date__c = System.Today().addDays(30);
			voloppRecord.HOC__Managed_By__c = 'Partner';
			voloppRecord.HOC__Organization_Served__c = acc.id;
			voloppRecord.HOC__Default_Location__c = locationRecord.id;
			voloppRecord.HOC__Registration_Type__c = 'Sign Up';
			voloppRecord.HOC__Apply_Restrictions_to_Opportunity__c = 'Apply Restrictions';
			voloppRecord.HOC__Registration_Deadline__c = 1;
			voloppRecord.HOC__Maximum_Attendance__c = 2;
			voloppRecord.HOC__Minimum_Attendance__c = 1;
			voloppRecord.HOC__Opportunity_Coordinator__c = con.id;
			voloppRecord.HOC__Minimum_Age_w_adult__c = 18;
			voloppRecord.HOC__Minimum_Age_w_o_adult__c = 18;
			voloppRecord.HOC__Orientation_Required__c = TRUE;
			voloppRecord.HOC__Skilled_Volunteer_Required__c = 'No';
			voloppRecord.HOC__Primary_Impact_Area__c = 'Adult Education';
			voloppRecord.HOC__Genders_Served__c = 'All Genders Served';
			voloppRecord.HOC__Impact_Area_Local__c = 'Boston Cares Programming & Support';
			voloppRecord.HOC__Program_Area_Local__c = 'Calendar';
			voloppRecord.HOC__Available_Languages__c = 'English';
			insert voloppRecord;

			// Create an Occurrence
			HOC__Occurrence__c occRecord = new HOC__Occurrence__c();
			occRecord.HOC__Volunteer_Opportunity__c = volOppRecord.id;
			occRecord.HOC__Location__c = locationRecord.id;
			occRecord.HOC__Start_Date_Time__c = Datetime.newInstance(2017, 12, 1, 12, 30, 2);
			occRecord.HOC__End_Date_Time__c = Datetime.newInstance(2017, 12, 2, 12, 30, 2);
			occRecord.HOC__Posting_Status__c = 'This is not published. The Volunteer Opportunity is not active.';
			occRecord.HOC__Status__c = 'Active';
			//occRecord.HOC__Days_Times_Needed__c = 'Tuesday Afternoon';
			occRecord.HOC__Opportunity_Coordinator__c = con.id;
			occRecord.HOC__Volunteer_Coordinator_Email__c = 'test@bostoncares.org';
			insert occRecord;

			// Create a Connection
			HOC__Connection__c connectionRecord = new HOC__Connection__c();
			connectionRecord.HOC__Volunteer_Opportunity__c = voloppRecord.id;
			connectionRecord.HOC__Occurrence__c = occRecord.id;
			connectionRecord.HOC__Contact__c = con.id;
			connectionRecord.HOC__Role__c = 'Volunteer';
			connectionRecord.HOC__Status__c = 'Confirmed';
			connectionRecord.HOC__Attendance_Status__c = 'Attended (and Hours Verified)';
			insert connectionRecord;

			List<OccurrenceEndpoint.VolunteerLeaderVM> volVmList = new List<OccurrenceEndpoint.VolunteerLeaderVM>();

			// This is an occurrence to update
			OccurrenceEndpoint.VolunteerLeaderVM volVM1 = new OccurrenceEndpoint.VolunteerLeaderVM();
			volVM1.volOppId = volOppRecord.Id;
			volVM1.startDatetime = Datetime.newInstance(2017, 12, 1, 12, 30, 2);
			volVM1.stopDatetime = Datetime.newInstance(2017, 12, 2, 12, 30, 2);
			volVm1.newVLEmail = 'test2@bostoncares.org';
			volVm1.locationName = 'WhateverLocation';

			// This is an occurrence to insert
			OccurrenceEndpoint.VolunteerLeaderVM volVM2 = new OccurrenceEndpoint.VolunteerLeaderVM();
			volVM2.volOppId = volOppRecord.Id;
			volVM2.startDatetime = Datetime.newInstance(2017, 12, 5, 12, 30, 2);
			volVM2.stopDatetime = Datetime.newInstance(2017, 12, 6, 12, 30, 2);
			volVm2.newVLEmail = 'test2@bostoncares.org';
			volVm2.locationName = 'Test Location';

			volVmList.add(volVM1);
			volVmList.add(volVM2);

			OccurrenceEndpoint.upsertOccurrence(volVmList);

			List<HOC__Occurrence__c> resultOccurrences = new List<HOC__Occurrence__c>();

			resultOccurrences = [SELECT Id, HOC__Volunteer_Coordinator_Email__c
														FROM HOC__Occurrence__c
														WHERE HOC__Volunteer_Opportunity__c =: voloppRecord.Id];


			System.debug(resultOccurrences.size());
		}

}
