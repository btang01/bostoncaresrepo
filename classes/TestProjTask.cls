@IsTest public class TestProjTask
{
  public static ID nonprofit = schema.SObjectType.Account.getRecordTypeInfosByName().get('Nonprofit').getRecordTypeId();

    static testMethod void testDupId()
    {
        Account agency = new Account();
        agency.RecordTypeId = nonprofit;
        agency.Name = 'Pine St Inn';
        agency.Walk_in_or_Appointment_Only__c = 'Walk-in';
        agency.HOC__Primary_Address__c = 'Shipping';
        agency.HOC__Address_Visibility__c = 'City and Zip only';
        agency.HOC__Status__c = 'Active Partner';
        agency.HOC__Genders_Served__c = 'Female';
        agency.HOC__Impact_Area__c = 'Hunger & Homelessness';
        agency.HOC__Age_Groups_Served__c = 'All ages';
        agency.ShippingStreet = '123 Fake Street';
  			agency.ShippingCity = 'Fake City';
  			agency.ShippingState = 'MA';
  			agency.ShippingPostalCode = '02446';
  			agency.ShippingCountry = 'USA';

        try{
            insert agency;
        } catch (Exception e){
            System.debug(e);
        }

        // List<Account> agencyList = [select Id from Account where Name = 'Pine St Inn'];
        // System.assertEquals (agencyList.size(), 1, 'Pine St Inn insert failed.');

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
    		locationRecord.HOC__Organization__c = agency.id;
    		insert locationRecord;

        Project_Site_Visit__c projsv = new Project_Site_Visit__c();
        Date projDate = Date.newInstance (2015, 3, 16);
        projsv.Project_Date__c = projDate;
        projsv.Name = 'Serve Dinner';
        projsv.Nonprofit_Agency__c = agency.id;
        projsv.Primary_Impact_Area__c = 'Adult Education';
        projsv.Local_Impact_Area__c = 'Basic Needs';
        projsv.Project_Location__c = locationRecord.id;
        projsv.Min_Volunteer_Age_w_adult__c = 18;
        projsv.Minimum_Volunteer_Age__c = 18;
        projsv.Description__c = 'Test Description';
        projsv.Start_Time__c = '8:00 AM';
        projsv.End_Time__c = '9:00 AM';
        insert projsv;

        // List<Project_Site_Visit__c> psvList = [select Id from Project_Site_Visit__c where Name = 'Serve Dinner'];
        // System.assertEquals (psvList.size(), 1, 'Serve Dinner insert failed.');

        // task
        Project_Task__c task = new Project_Task__c();
        task.Task_Number__c = 1;
        task.Name = 'Fill Dumpster';
        task.Project_Site_Visit__c = projsv.Id;
        insert task;
        // test 1 insert same numbered task in same project
        task = new Project_Task__c();
        task.Task_Number__c = 1;
        task.Name = 'Empty Dumpster';
        task.Project_Site_Visit__c = projsv.Id;
        try
        {
            insert task;
        }
        catch (Exception e)
        {
            system.debug (Logginglevel.INFO, e.getMessage());
            system.assert (e.getMessage().contains('Another task'));
        }
        // test 2 apply the contingency flag making it a diff task
        task = new Project_Task__c();
        task.Task_Number__c = 1;
        task.Contingency_Plan__c = true;
        task.Name = 'Wash Floors';
        task.Project_Site_Visit__c = projsv.Id;
        insert task;
        // test 3 apply the same task to diff proj
        // proj 2
        Project_Site_Visit__c psv2 = new Project_Site_Visit__c();
        psv2.Name = 'Serve Lunch';
        psv2.Project_Date__c = projDate;
        psv2.Nonprofit_Agency__c = agency.Id;
        insert psv2;
        // try retrieve without list
        // Project_Site_Visit__c psv2Single = [select Id from Project_Site_Visit__c where Name = 'Serve Lunch'];
        // System.assertNotEquals (psv2Single, null, 'Serve Lunch insert failed.');
        task = new Project_Task__c();
        task.Task_Number__c = 1;
        //task.Contingency_Plan__c = false;
        task.Name = 'Make Doughnuts';
        task.Project_Site_Visit__c = psv2.Id;
        insert task;

    }
}
