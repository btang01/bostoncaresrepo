@IsTest(SeeAllData=true)
private class TestCompAgencyMatchInsert
{
    public static ID eitcId = schema.SObjectType.Account.getRecordTypeInfosByName().get('Nonprofit').getRecordTypeId();
    public static ID busId = schema.SObjectType.Account.getRecordTypeInfosByName().get('Business').getRecordTypeId();

    @isTest
  	static void testGenTrigger3()
    {
      List<Profile> profileList = [SELECT Id, Name FROM Profile WHERE Name =: 'System Administrator'];
      String prof = null;

      if(profileList.size() > 0){
        prof = profileList[0].id;
      }

      System.debug('Profile Name: ' + prof);

      User emily = new User();
      emily.firstName = 'Emily';
      emily.lastName = 'Rackleff';
      emily.Alias = 'erack';
      emily.CommunityNickname = 'erackleffwackawackawacka';
      emily.Email = 'erackleff@testgmail.com';
      emily.Username = 'erackleff@testgmail.com';
      emily.LanguageLocaleKey='en_US';
      emily.LocaleSidKey='en_US';
      emily.TimeZoneSidKey='America/Los_Angeles';
      emily.EmailEncodingKey = 'UTF-8';
      emily.ProfileId=prof;
      insert emily;
      System.debug(emily);
      String emilyId = emily.Id;

      // Create an Organization
  		Account busAcc = new Account();
  		busAcc.Name = 'Test Business 1';
  		busAcc.RecordTypeId = busId;
  		busAcc.HOC__Status__c = 'Active Partner';
  		busAcc.Walk_in_or_Appointment_Only__c = 'Walk-in';
  		busAcc.HOC__Primary_Address__c = 'Shipping';
  		busAcc.HOC__Address_Visibility__c = 'City and Zip only';
  		busAcc.ShippingStreet = '123 Fake Street';
  		busAcc.ShippingCity = 'Fake City';
  		busAcc.ShippingState = 'MA';
  		busAcc.ShippingPostalCode = '02446';
  		busAcc.ShippingCountry = 'USA';
  		busAcc.HOC__Partner_Approval_Manager__c = emilyId;
  		busAcc.HOC__Impact_Area__c = 'Adult Education';
      busAcc.HOC__Genders_Served__c = 'All Genders Served';
      busAcc.HOC__Age_Groups_Served__c = 'All ages';
  		insert busAcc;
      System.debug('Business Account: ' + busAcc);

      // Create a Volunteer
  		Contact vol = new Contact();
  		vol.HOC__Username__c = 'test@bostoncares.org222';
  		vol.HOC__Registration_Status__c = 'Registered';
  		vol.FirstName = 'Test';
  		vol.LastName = 'User1';
  		vol.HOC__Primary_Phoneno__c = 'Home';
  		vol.Email = 'test@bostoncares.org222';
  		vol.HOC__Primary_Address__c = 'Home';
  		vol.MailingStreet = '234 Fake Street';
  		vol.MailingCity = 'Boston';
  		vol.MailingState = 'MA';
  		vol.MailingPostalCode = '02446';
  		vol.MailingCountry = 'USA';
  		vol.Birthdate = System.Today().addYears(-25);
  		vol.HOC__Orientation_Completed__c = TRUE;
  		vol.VL_Training_Completed__c = TRUE;
  		insert vol;

      // Create an Organization
  		Account acc = new Account();
  		acc.Name = 'Boston Cares';
  		acc.RecordTypeId = eitcId;
  		acc.HOC__Status__c = 'Active Partner';
      acc.Type = 'Nonprofit';
  		acc.HOC__Primary_Address__c = 'Shipping';
  		acc.HOC__Address_Visibility__c = 'City and Zip only';
  		acc.HOC__Partner_Approval_Manager__c = emilyId;
  		acc.HOC__Impact_Area__c = 'Animals';
      acc.HOC__Genders_Served__c = 'All Genders Served';
      acc.HOC__Age_Groups_Served__c = 'All ages';
      acc.Description = 'Test Description';
  		insert acc;
      System.debug('Boston Cares Account: ' + acc);

      vol.AccountId = acc.id;
      update vol;

      acc.HOC__Primary_Contact__c = vol.id;
      update acc;

      // Create a Zip Code
  		HOC__ZipCode__c zipCodeRecord = new HOC__ZipCode__c();
  		zipCodeRecord.Name = '02446';
  		insert zipCodeRecord;
      System.debug('Zip Code Record: ' + zipCodeRecord);

  		// Create a Location
  		HOC__Location__c locationRecord = new HOC__Location__c();
  		locationRecord.Name = 'Drumlin Farm, Nature Center';
  		locationRecord.HOC__Street__c = 'Test Street';
  		locationRecord.HOC__City__c = 'Test City';
  		locationRecord.HOC__Zip_Postal_Code__c = zipCodeRecord.id;
  		locationRecord.HOC__Zip_Code__c = '02446';
  		locationRecord.HOC__Country__c = 'USA';
  		locationRecord.HOC__Organization__c = acc.id;
  		insert locationRecord;
      System.debug('Location Record: ' + locationRecord);

      Project_Site_Visit__c projsv = new Project_Site_Visit__c();
      projsv.Name = 'Test Project Site Visit';
      projsv.Nonprofit_Agency__c = acc.id;
      projsv.Primary_Impact_Area__c = 'Adult Education';
      projsv.Local_Impact_Area__c = 'Basic Needs';
      projsv.Project_Location__c = locationRecord.id;
      projsv.Min_Volunteer_Age_w_adult__c = 18;
      projsv.Minimum_Volunteer_Age__c = 18;
      projsv.Description__c = 'Test Description';
      projsv.Start_Time__c = '8:00 AM';
      projsv.End_Time__c = '9:00 AM';
      insert projsv;
      System.debug('Project Site Visit: ' + projsv);

      // Insert a Company Intake
      Company_Intake__c compIntake = new Company_Intake__c();
      compIntake.Company__c = busAcc.id;
      insert compIntake;
      System.debug('Company Intake: ' + compIntake);

      Contact con = new Contact();
  		con.HOC__Username__c = 'test91000@bostoncaresisdabest.org';
  		con.HOC__Registration_Status__c = 'Registered';
  		con.FirstName = 'Test';
  		con.LastName = 'User1';
  		con.AccountId = acc.id;
  		con.HOC__Primary_Phoneno__c = 'Home';
  		con.Email = 'test91000@bostoncaresisdabest.org';
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
      System.debug('Contact: ' + con);

      // insert a minimal company agency match
      Company_Agency_Match__c cam = new Company_Agency_Match__c();
      cam.Company_Intake__c = compIntake.Id;
      cam.Project_Site_Visit__c = projsv.Id;
      cam.Generate_on_Save__c = true;
      cam.Opportunity_Coordinator__c = con.id;
      cam.Start_Date__c = System.Today().addDays(10);
      cam.End_Date__c = System.Today().addDays(10);
      cam.Minimum_Volunteers__c = 1;
      cam.Maximum_Volunteers__c = 3;
      cam.Agency__c = acc.id;
      cam.Company__c = busAcc.id;
      insert cam;
      System.debug('Company Agency Match: ' + cam);
    }
}