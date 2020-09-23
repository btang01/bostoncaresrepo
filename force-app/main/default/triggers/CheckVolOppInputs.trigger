trigger CheckVolOppInputs on Company_Agency_Match__c (before insert, before update)
{
    for (Company_Agency_Match__c cam: Trigger.new)
    {
        String forAgencyName = ''; // append to error in case not shown on page yet
        // check if Company is missing
        if (cam.Company__c == null)
        {
            List<Company_Intake__c> compInt = 
            [select Company__c from Company_Intake__c 
             where Id = :cam.Company_Intake__c];
            cam.Company__c = compInt.get(0).Company__c;
        }
        // check if Agency is missing
        if (cam.Agency__c == null)
        {
            List<Project_Site_Visit__c> projSv =
            [select Nonprofit_Agency__c from Project_Site_Visit__c 
             where Id = :cam.Project_Site_Visit__c];
            cam.Agency__c = projSv.get(0).Nonprofit_Agency__c;
            List<Account> agency = 
            [select Name from Account where ID = :cam.Agency__c];
            forAgencyName = ' for ' + agency.get(0).Name;
        }

        if (cam.Generate_on_Save__c == true)
        {
            // box is checked, Check if VO already exists if we are updating
            if (System.Trigger.isUpdate)
            {
                List<HOC__Volunteer_Opportunity__c> volopp = 
                [select Id from HOC__Volunteer_Opportunity__c 
                 where Company_Agency_Match__c = :cam.Id];
                if (! volopp.isEmpty())                            
                {
                    cam.Generate_on_Save__c.addError ('Uncheck this box until you remove existing Volunteer Opportunity.');
                }
            }
            // check for missing Gender or Age data from Nonprofit
            List<Account> agency = [Select Name,HOC__Impact_Area__c,
                HOC__Genders_Served__c,HOC__Age_Groups_Served__c
                from Account where Id = :cam.Agency__c];
            List<Project_Site_Visit__c> projsv =
                [Select Name,Project_Date__c,Project_End_Date__c,
                Minimum_Volunteer_Age__c,Min_Volunteer_Age_w_adult__c,
                Project_Location__c,Description__c,
                Primary_Impact_Area__c,Secondary_Impact_Area__c,Local_Impact_Area__c
                from Project_Site_Visit__c where Id = :cam.Project_Site_Visit__c];
            /* change, now we get opp coord directly from cam
            List<Project_Contact__c> primcont = [select Contact__c from Project_Contact__c
                where Project_Site_Visit__c = :cam.Project_Site_Visit__c
                and Primary_Project_Contact__c = true];
            List<Contact> oppcoord;
            if (! primcont.isEmpty())
            {
                oppcoord = [select Id,Name,HOC__Username__c from Contact
                    where Id = :primcont.get(0).Contact__c];
            }
            */
            String agencyErrors = '';
            if (agency.get(0).HOC__Genders_Served__c == null)
            {
                //cam.Agency__c.addError ('Genders Served not provided for Agency');
                agencyErrors += 'Genders-Served ';
            }
            if (agency.get(0).HOC__Age_Groups_Served__c == null)
            {
                //cam.Agency__c.addError ('Groups Served not provided for Agency');
                agencyErrors += 'Age-Groups-Served ';
            }
            if (agencyErrors.length() > 0)
            {
                cam.Agency__c.addError (agencyErrors + 'not provided in Agency data' + forAgencyName);
            }
            String projErrors = '';
            String agencyImpactAreas = agency.get(0).HOC__Impact_Area__c;
            List<String> impactAreaList = new List<String>();
            if (agencyImpactAreas != null)
            {
                agencyImpactAreas.split(';');
            }
            String impact1 = projsv.get(0).Primary_Impact_Area__c;
            if (impact1 == null)
            {
                // if primary impact not given on project site visit and there is only
                // one specified for the nonprofit, use that.
                if (impactAreaList.size() == 1)
                {
                    impact1 = impactAreaList.get(0);
                }
            }
            if (impact1 == null)
            {
                projErrors += 'Primary-Impact ';
            }
            if (projsv.get(0).Local_Impact_Area__c == null)
            {
                projErrors += 'Local-Impact-Area ';
            }
            if (projsv.get(0).Project_Location__c == null)
            {
                projErrors += 'Project-Location ';
            }
            if (projsv.get(0).Minimum_Volunteer_Age__c == null)
            {
                projErrors += 'Minimum-Volunteer-Age ';
            }
            if (projsv.get(0).Min_Volunteer_Age_w_adult__c == null)
            {
                projErrors += 'Minimum-Volunteer-Age-with-Adult ';
            }
            if (projsv.get(0).Description__c == null)
            {
                projErrors += 'Project-Description ';
            }
            /* old check
            if (primcont.size() == 0)
            {
                projErrors += 'Missing-Primary-Contact ';
            }
            else if (primcont.size() > 1)
            {
                projErrors += 'Multiple-Primary-Contacts ';
            }
            else
            {
                // we have 1 primary contact, check for username
                if (oppcoord.get(0).HOC__Username__c == null)
                {
                    cam.Generate_on_Save__c.addError ('Username not provided for primary contact: ' + oppcoord.get(0).Name);
                }
            }
            */
            /* need to change this now - confirm that default user is found in contacts
            if (cam.Opportunity_Coordinator__c == null)
            {
                cam.Opportunity_Coordinator__c.addError ('Opportunity Coordinator is required.');
            }
            */
            String oppcoordId = cam.Opportunity_Coordinator__c;
            if (oppcoordId == null)
                
            {
                // opp coord not explicitly given so check that we can use default
                List<Contact> oppcoord = [select Id,Name,HOC__Username__c from Contact
                    where name = :cam.Opportunity_Coordinator_Default__c];
                if (oppcoord.isEmpty())
                {
                    cam.Opportunity_Coordinator__c.addError ('default coordinator ' +
                        cam.Opportunity_Coordinator_Default__c + ' not found in Contacts. Look here or add to Contacts.');
                }
                else if (oppcoord.get(0).HOC__Username__c == null)
                {
                    cam.Opportunity_Coordinator__c.addError ('default coordinator ' +
                        cam.Opportunity_Coordinator_Default__c + ' lacks username in Contacts.');
                }
            }
            if (projErrors.length() > 0)
            {
                cam.Project_Site_Visit__c.addError (projErrors + 'not provided in Project Site Visit data.');
            }
            // look at items that can be overridden on the match page
            // start date (end date defaults to it so need not be checked)
            Date startDate = cam.Start_Date__c;
            if (startDate == null)
            {
                startDate = projsv.get(0).Project_Date__c;
            }
            if (startDate == null)
            {
                cam.Start_Date__c.addError ('Start Date must be provided here or on Project Site Visit.');
            }
            if (cam.First_Occurrence_Start__c == null && cam.Project_Start_Time__c == null)
            {
                cam.First_Occurrence_Start__c.addError ('Start Time must be provided here or on Project Site Visit.');
            }
            if (cam.First_Occurrence_End__c == null && cam.Project_End_Time__c == null)
            {
                cam.First_Occurrence_End__c.addError ('End Time must be provided here or on Project Site Visit.');
            }
            // likewise for min and max volunteers
            if (cam.Minimum_Volunteers__c == null && cam.Project_Max_Min_Volunteers__c == 0)
            {
                cam.Minimum_Volunteers__c.addError ('Minimum Volunteers must be provided here or on Project Site Visit.');
            }
            if (cam.Maximum_Volunteers__c == null && cam.Project_Max_Max_Volunteers__c == 0)
            {
                cam.Maximum_Volunteers__c.addError ('Maximum Volunteers must be provided here or on Project Site Visit.');
            }
            if (cam.Opportunity_Status__c == null)
            {
                cam.Opportunity_Status__c.addError ('Opportunity Status required.');
            }
        }
    }
}