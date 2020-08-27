trigger addVolOpp on Company_Agency_Match__c (after insert, after update) 
{
    List<HOC__Volunteer_Opportunity__c> vo = new List<HOC__Volunteer_Opportunity__c>();                                 
    for (Company_Agency_Match__c cam: Trigger.new)
    {
        if (cam.Generate_on_Save__c == false)
        {
            return;
        }

        List<HOC__Volunteer_Opportunity__c> existingvo =
            [select Name from HOC__Volunteer_Opportunity__c where Company_Agency_Match__c = :cam.id];
        // if there is already one generated then do not create another until deleted
        if (! existingvo.isEmpty())
        {
            return;
        }

        // lookup related info for populating the Vol Opp
        List<Account> company = [select Name from Account where Id = :cam.Company__c];
        List<Account> agency = [Select Name,HOC__Impact_Area__c,
            HOC__Genders_Served__c,HOC__Age_Groups_Served__c
            from Account where Id = :cam.Agency__c];
        List<Account> boscares = [Select Id from Account where Name = 'Boston Cares'];
        List<Project_Site_Visit__c> projsv =
            [Select Name,Project_Date__c,Project_End_Date__c,
             Minimum_Volunteer_Age__c,Min_Volunteer_Age_w_adult__c,
             Project_Location__c,Description__c,
             Primary_Impact_Area__c,Secondary_Impact_Area__c,Local_Impact_Area__c
             from Project_Site_Visit__c where Id = :cam.Project_Site_Visit__c];
        /*List<Project_Contact__c> primcont = [select Contact__c from Project_Contact__c
            where Project_Site_Visit__c = :cam.Project_Site_Visit__c
            and Primary_Project_Contact__c = true];*/
        //List<Contact> oppcoord = [select Id from Contact
        //    where Id = :primcont.get(0).Contact__c];
        //defaults to current user, can override with supplied opp coord
        String oppCoordDefaultName = cam.Opportunity_Coordinator_Default__c;
        List<Contact> oppcoord = new List<Contact>();
        String oppcoordId = cam.Opportunity_Coordinator__c;
        if (oppcoordId == null)
        {
            oppcoord = [select Id from Contact
                where name = :oppCoordDefaultName];
            // TODO insert checking here or do lookup based in first/last names
            oppcoordId = oppcoord.get(0).Id;
        }
        String agencyImpactAreas = agency.get(0).HOC__Impact_Area__c;
        List<String> impactAreaList = agencyImpactAreas.split(';');
        // first impact area is: impactAreaList.get(0)
        String impact1 = projsv.get(0).Primary_Impact_Area__c;
        String impact2;
        if (impact1 == null)
        {
            // if primary impact not given on project site visit and there is only
            // one specified for the nonprofit, use that.
            if (impactAreaList.size() == 1)
            {
                impact1 = impactAreaList.get(0);
            }
        }
        // only grab the secondary impact area if the primary is specified
        // on the project site visit
        else
        {
            impact2 = projsv.get(0).Secondary_Impact_Area__c;
        }

        // construct the opportunity name in the style they currently use
        String oppName = 'HAW: ' + company.get(0).Name + ' at ' + agency.get(0).name;
        // for start date look first to see if specified with match record.
        // if not look to the proj site visit record.
        Date startDate = cam.Start_Date__c;
        if (startDate == null)
        {
            startDate = projsv.get(0).Project_Date__c;
        }
        // similarly for end date look first at the match then at the proj site visit.
        // additionally if neither of those given assume it's a one-day project
        Date endDate = cam.End_Date__c;
        if (endDate == null)
        {
            endDate = projsv.get(0).Project_End_Date__c;
        }
        if (endDate == null)
        {
            endDate = startDate;
        }
        // likewise for min and max volunteers
        Decimal minvols = cam.Minimum_Volunteers__c;
        if (minvols == null)
        {
            minvols = cam.Project_Max_Min_Volunteers__c;
        }
        Decimal maxvols = cam.Maximum_Volunteers__c;
        if (maxvols == null)
        {
            maxvols = cam.Project_Max_Max_Volunteers__c;
        }
        // default location, check proj site visit if not directly in cam
        // removed default for now just use proj site visit
        String defloc = projsv.get(0).Project_Location__c;
        vo.add(
            new HOC__Volunteer_Opportunity__c(
                HOC__Status__c = cam.Opportunity_Status__c,
                HOC__Start_Date__c = startDate,
                HOC__End_Date__c = endDate,
                HOC__Schedule_Type__c = 'Date & Time Specific',
                Name = oppName,
                Company_Agency_Match__c = cam.Id,
                HOC__Type__c = 'Project',
                HOC__Disaster_Opportunity_Type__c = 'Not Disaster Related',
                HOC__Managed_By__c = 'Affiliate',           
                HOC__Managing_Organization__c = boscares.get(0).Id,
                HOC__Organization_Served__c = cam.Agency__c,
                HOC__Requires_Invitation_From__c = cam.Company__c,
                HOC__Registration_Type__c = 'Sign Up',    
                HOC__Default_Location__c = projsv.get(0).Project_Location__c,
                HOC__Minimum_Attendance__c = minvols,
                HOC__Maximum_Attendance__c = maxvols,
                HOC__Genders_Served__c = agency.get(0).HOC__Genders_Served__c,
                HOC__Age_Groups_Served__c = agency.get(0).HOC__Age_Groups_Served__c,
                HOC__Primary_Impact_Area__c = impact1,
                HOC__Secondary_Impact_Area__c = impact2,
                HOC__Minimum_Age_w_o_adult__c = projsv.get(0).Minimum_Volunteer_Age__c,
                HOC__Minimum_Age_w_adult__c = projsv.get(0).Min_Volunteer_Age_w_adult__c,
                HOC__Description__c = projsv.get(0).Description__c,
                HOC__Opportunity_Coordinator__c = oppcoordId,
                HOC__Program_Area_Local__c = 'Hands at Work',
                HOC__Impact_Area_Local__c = projsv.get(0).Local_Impact_Area__c
            )
        );   
    }
    insert vo;
    // work on Occurrence
    List<HOC__Occurrence__c> occ = new List<HOC__Occurrence__c>();
    for (Company_Agency_Match__c cam: Trigger.new)
    {
        List<HOC__Volunteer_Opportunity__c> volist =
            [select Id,HOC__Default_Location__c,HOC__Status__c,
             HOC__Start_Date__c,HOC__End_Date__c
             from HOC__Volunteer_Opportunity__c
             where Company_Agency_Match__c = :cam.Id];
        DateTime occStart = cam.First_Occurrence_Start__c;
        if (occStart == null)
        {
            occStart = DateTime.parse(volist.get(0).HOC__Start_Date__c.format() +
                                      ' ' + cam.Project_Start_Time__c);
        }
        DateTime occEnd = cam.First_Occurrence_End__c;
        if (occEnd == null)
        {
            occEnd = DateTime.parse(volist.get(0).HOC__End_Date__c.format() +
                                      ' ' + cam.Project_End_Time__c);
        }
        occ.add(
            new HOC__Occurrence__c(
                HOC__Volunteer_Opportunity__c = volist.get(0).Id,
                HOC__Location__c = volist.get(0).HOC__Default_Location__c,
                HOC__Status__c = volist.get(0).HOC__Status__c,
                HOC__Start_Date_Time__c = occStart,
                HOC__End_Date_Time__c = occEnd
            )
        );
    }
    insert occ;
}