@IsTest public class TestProjTask
{
    static testMethod void testDupId()
    {
        RecordType rectype = [select Id from RecordType where Name = 'Nonprofit'];
        Account agency = new Account();
        agency.RecordTypeId = rectype.Id;
        agency.Name = 'Pine St Inn';
        agency.HOC__Genders_Served__c = 'Female';
        agency.HOC__Impact_Area__c = 'Hunger & Homelessness';
        agency.HOC__Age_Groups_Served__c = 'All ages';
        insert agency;
        List<Account> agencyList = [select Id from Account where Name = 'Pine St Inn'];
        System.assertEquals (agencyList.size(), 1, 'Pine St Inn insert failed.');
        // proj
        Project_Site_Visit__c psv = new Project_Site_Visit__c();
        psv.Name = 'Serve Dinner';
        Date projDate = Date.newInstance (2015, 3, 16);
        psv.Project_Date__c = projDate;
        psv.Nonprofit_Agency__c = agencyList.get(0).Id;
        psv.Minimum_Volunteer_Age__c = 18;
        psv.Min_Volunteer_Age_w_adult__c = 17;
        psv.Description__c = 'a cool project';
        insert psv;
        List<Project_Site_Visit__c> psvList = [select Id from Project_Site_Visit__c where Name = 'Serve Dinner'];
        System.assertEquals (psvList.size(), 1, 'Serve Dinner insert failed.');
        // task
        Project_Task__c task = new Project_Task__c();
        task.Task_Number__c = 1;
        task.Name = 'Fill Dumpster';
        task.Project_Site_Visit__c = psvList.get(0).Id;
        insert task;
        // test 1 insert same numbered task in same project
        task = new Project_Task__c();
        task.Task_Number__c = 1;
        task.Name = 'Empty Dumpster';
        task.Project_Site_Visit__c = psvList.get(0).Id;
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
        task.Project_Site_Visit__c = psvList.get(0).Id;
        insert task;
        // test 3 apply the same task to diff proj
        // proj 2
        Project_Site_Visit__c psv2 = new Project_Site_Visit__c();
        psv2.Name = 'Serve Lunch';
        psv2.Project_Date__c = projDate;
        psv2.Nonprofit_Agency__c = agencyList.get(0).Id;
        insert psv2;
        // try retrieve without list
        Project_Site_Visit__c psv2Single = [select Id from Project_Site_Visit__c where Name = 'Serve Lunch'];
        System.assertNotEquals (psv2Single, null, 'Serve Lunch insert failed.');
        task = new Project_Task__c();
        task.Task_Number__c = 1;
        //task.Contingency_Plan__c = false;
        task.Name = 'Make Doughnuts';
        task.Project_Site_Visit__c = psv2Single.Id;
        insert task;
    }
}