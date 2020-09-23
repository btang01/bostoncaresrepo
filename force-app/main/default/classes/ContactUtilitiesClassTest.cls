@isTest
private class ContactUtilitiesClassTest
{
	// Get the RecordTypeId
	public static ID eitcId = schema.SObjectType.Account.getRecordTypeInfosByName().get('EITC Site').getRecordTypeId();
	public static ID volOppEitcId = schema.SObjectType.HOC__Volunteer_Opportunity__c.getRecordTypeInfosByName().get('EITC Site').getRecordTypeId();

	@isTest
	static void testContactConnectionCalculation()
	{
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

		// Create a Volunteer
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
		insert con;

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
		insert voloppRecord;

		// Create an Occurrence
		HOC__Occurrence__c occRecord = new HOC__Occurrence__c();
		occRecord.HOC__Volunteer_Opportunity__c = volOppRecord.id;
		occRecord.HOC__Location__c = locationRecord.id;
		occRecord.HOC__Start_Date_Time__c = System.Now().addDays(10);
		occRecord.HOC__End_Date_Time__c = System.Now().addDays(10).addHours(1);
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

		List<Contact> listOfCons = new List<Contact>([SELECT Id, Number_of_Projects_Attended_and_Verified__c, (SELECT Id FROM HOC__Connection__r WHERE HOC__Attendance_Status__c =: 'Attended (and Hours Verified)') FROM Contact WHERE ID IN (SELECT HOC__Contact__c FROM HOC__Connection__c)]);
		ContactUtilitiesClass.calculateConnections();
		ContactUtilitiesClass.batchCalculateConnections(listOfCons);
	}
}
