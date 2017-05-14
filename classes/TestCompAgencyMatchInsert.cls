@IsTest(SeeAllData=true) public class TestCompAgencyMatchInsert
{
    // because we could not create a Location object try this approach
    // using existing data instead of creating from scratch.
    // already wrote most of it just try using an existing location,
    // actually that won't work as the ids will require consistently
    // using existing data.
    static testMethod void testGenTriggers3()
    {
        List<Account> company = [select Id,Name from Account where Name = 'EMC'];
        System.assertEquals (company.size(), 1, 'EMC not found.');
        List<Company_Intake__c> ci = [select Id from Company_Intake__c where Name = 'intake000000'];
        System.assertEquals (ci.size(), 1, 'company intake 1 not found');
        List<Account> agency = [Select Name,HOC__Impact_Area__c,
            HOC__Genders_Served__c,HOC__Age_Groups_Served__c
            from Account where Name = 'Massachusetts Audubon Society - Drumlin Farms'];
        System.assertEquals (agency.size(), 1, 'Drumlin Account not found.');
        List<HOC__Location__c> locList = [Select Id from HOC__Location__c where Name = 'Drumlin Farm, Nature Center'];
        System.assertEquals (locList.size(), 1, 'Drumlin location not found.');
        List<Project_Site_Visit__c> projsv =
            [Select Name,Project_Date__c,Project_End_Date__c,
             Minimum_Volunteer_Age__c,Min_Volunteer_Age_w_adult__c,
             Project_Location__c,Description__c,
             Primary_Impact_Area__c,Secondary_Impact_Area__c,Local_Impact_Area__c
             from Project_Site_Visit__c where Name = 'Drumlin Farms Site Visit'];
        System.assertEquals (projsv.size(), 1, 'Drumlin Proj not found.');

        // insert a minimal company agency match
        Company_Agency_Match__c cam = new Company_Agency_Match__c();
        cam.Company_Intake__c = ci.get(0).Id;
        cam.Project_Site_Visit__c = projsv.get(0).Id;
        cam.Generate_on_Save__c = true;
        insert cam;
    }
}