/*
 * Set of static methods used to instantiate test data for all Apex
 * test classes.
 */
@isTest
public class TestDataFactory {
    /* Create a test Parnter Account
     * @param u admin user with a role
     * @return a new Partner Account
     */
    public static Account newAccount(User u){
        return new Account(Name = 'Test Account',
                           RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('EITC Site').getRecordTypeId(),
                           HOC__Status__c = 'Active Partner',
                           Walk_in_or_Appointment_Only__c = 'Walk-in',
                           HOC__Primary_Address__c = 'Shipping',
                           HOC__Address_Visibility__c = 'City and Zip only',
                           ShippingStreet = '223 Main Street',
                           ShippingCity = 'Boston',
                           ShippingState = 'MA',
                           ShippingPostalCode = '02116',
                           ShippingCountry = 'USA',
                           HOC__Partner_Approval_Manager__c = u.Id,
                           HOC__Impact_Area__c = 'Adult Education');
    }

    /* Create test Contacts
     * @param numOfRecs Indicates the number of Contacts to be returned
     * @param acountId the Id of the parent Account
     * @return New Contacts 
     */
    public static List<Contact> newContacts(Integer numOfRecs, Id accountId){
        List<Contact> contacts = new List<Contact>();
        for(Integer i = 0; i < numOfRecs; i++) {
            Contact con = new Contact(FirstName = 'Test', 
                                      LastName = 'User' + i,
                                      AccountId = accountId, 
                                      HOC__Primary_Phoneno__c = 'Home',
                                      Email = 'test@bostoncares.org', 
                                      HOC__Primary_Address__c = 'Home',
                                      HOC__Username__c = 'test' + i + '@bostoncares.org',
                                      MailingStreet = '123 Main Street',
                                      MailingCity = 'Boston',
                                      MailingState = 'MA',
                                      MailingPostalCode = '02116',
                                      MailingCountry = 'USA',
                                      Birthdate = System.Today().addYears(-30),
                                      HOC__Orientation_Completed__c = true,
                                      VL_Training_Completed__c = true, 
                                      HOC__Registration_Status__c = 'Registered');
            contacts.add(con);
        }
        return contacts;
    }

    /* Create test Community Users
     * @param contacts the parent Contacts
     * @return New Users
     */
    public static List<User> newUsers(List<Contact> contacts){
        List<User> users = new List<User>();
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Volunteer Leader'];
        for(Integer i = 0; i < contacts.size(); i++) {
            User u = new User(FirstName = 'Test', 
                            LastName = 'User',
                            ContactId = contacts[i].Id, 
                            Email = 'test' + i + '@bostoncares.org', 
                            Username = 'test' + i +'@bostoncares.org',
                            ProfileId = p.Id,
                            Alias = 'stand' + i,
                            EmailEncodingKey = 'UTF-8', 
                            LanguageLocaleKey='en_US',
                            LocaleSidKey = 'en_US', 
                            TimeZoneSidKey = 'America/Los_Angeles'
                            );
            users.add(u);
        }
        

        return users;
    }

    /* Create a new Location record 
     * @param zipCodeRecdId ID of the HOC__ZipCode__c object, corresponding to the zip code value 
     * @param acountId the Id of the parent Organization/Account
     * @return a new Location record  
     */
    public static HOC__Location__c newLocationRec(String zipCodeRecdId, String accountId){
        return new HOC__Location__c(Name = 'Test Location',
                                    HOC__Street__c = '223 Main Street',
                                    HOC__City__c = 'Boston',
                                    HOC__Zip_Postal_Code__c = zipCodeRecdId,
                                    HOC__Zip_Code__c = '02116',
                                    HOC__Country__c = 'USA',
                                    HOC__Organization__c = accountId);
    }

    /* Create a new Volunteer Opportunity record 
     * @param acountId the Id of the parent Organization/Account
     * @param locationRecId the Id of the Location record
     * @param oppCoordinatorContactId the Id of the Contact record that will be marked as the oppty coordinator
     * @return a new Volunteer Opportunity record
     */
    public static HOC__Volunteer_Opportunity__c newVolOppRec(Id accountId, Id locationRecId, String oppCoordinatorContactId){
        HOC__Volunteer_Opportunity__c volOpp = new HOC__Volunteer_Opportunity__c(
                                                Name = 'Test Project',
                                                HOC__Description__c = 'Sample Description',
                                                HOC__Status__c = 'Pending',
                                                //HOC__Posting_Status__c = 'This is not published. Please submit for approval.',
                                                RecordTypeId = Schema.SObjectType.HOC__Volunteer_Opportunity__c.getRecordTypeInfosByName().get('EITC Site').getRecordTypeId(),
                                                HOC__Type__c = 'Project',
                                                HOC__Schedule_Type__c = 'Date & Time Specific',
                                                HOC__Start_Date__c = System.Today().addDays(-30),
                                                HOC__End_Date__c = System.Today().addDays(30),
                                                HOC__Managed_By__c = 'Partner',
                                                HOC__Organization_Served__c = accountId,
                                                HOC__Default_Location__c = locationRecId,
                                                HOC__Opportunity_Coordinator__c = oppCoordinatorContactId,
                                                HOC__Registration_Type__c = 'Sign Up',
                                                HOC__Apply_Restrictions_to_Opportunity__c = 'Apply Restrictions',
                                                HOC__Registration_Deadline__c = 1,
                                                HOC__Maximum_Attendance__c = 2,
                                                HOC__Minimum_Attendance__c = 1,
                                                HOC__Primary_Impact_Area__c = 'Adult Education',
                                                HOC__Disaster_Opportunity_Type__c = 'Not Disaster Related',
                                                HOC__Minimum_Age_w_o_adult__c = 18,
                                                HOC__Minimum_Age_w_adult__c = 18,
                                                HOC__Impact_Area_Local__c = 'Boston Cares Programming & Support',
                                                HOC__Program_Area_Local__c = 'Calendar',
                                                HOC__Available_Languages__c = 'English',
                                                HOC__Genders_Served__c = 'All Genders Served',
                                                HOC__Skilled_Volunteer_Required__c = 'No',
                                                HOC__Orientation_Required__c = true
                                               );

        return volOpp;
    }

    /* Create a new Occurrence record 
     * @param volOpp the parent Volunteer Opportunity
     * @param oppCoordinatorContactId the Id of the Contact record that will be marked as the oppty coordinator
     * @return a new Occurrence record
     */
    public static HOC__Occurrence__c newOccurrenceRec(HOC__Volunteer_Opportunity__c volOpp, Id oppCoordinatorContactId){
        HOC__Occurrence__c newOccurrence = new HOC__Occurrence__c(
                                            HOC__Volunteer_Opportunity__c = volOpp.Id,
                                            HOC__Location__c = volOpp.HOC__Default_Location__c, 
                                            HOC__Opportunity_Coordinator__c = oppCoordinatorContactId,
                                            HOC__Start_Date_Time__c = System.Now().addHours(1),
                                            HOC__End_Date_Time__c = System.Now().addHours(2),
                                            HOC__Status__c = 'Active'
                                            //OwnerId = u.Id
                                            //HOC__Posting_Status__c = 'This is not published. The Volunteer Opportunity is not active.'
                                         );

        return newOccurrence;
    }

    /* Create a new Connection record 
     * @param occurrence the Occurrence record
     * @param contactId the Id of the associated Contact record
     * @return a new Connection record
     */
    public static HOC__Connection__c newConnection(HOC__Occurrence__c occurrence, Id contactId){
        HOC__Connection__c connection = new HOC__Connection__c(
                                            HOC__Volunteer_Opportunity__c = occurrence.HOC__Volunteer_Opportunity__c,
                                            HOC__Occurrence__c = occurrence.Id,
                                            HOC__Start_Date_Time__c = occurrence.HOC__Start_Date_Time__c,
                                            HOC__Contact__c = contactId,
                                            HOC__Role__c = 'Volunteer',
                                            HOC__Status__c = 'Confirmed',
                                            HOC__Attendance_Status__c = 'Please Verify'
                                        );
        return connection;
    }

    /* Create a new VL Need record 
     * @param volOppId the Id of the Volunteer Opportunity record
     * @param occId the Id of the Occurrence record. This is an optional parameter.
     * @param contactId the Id of the associated Contact record
     * @param status the status value we'd like
     * @return a new VL Need record
     */
    public static OrphanedProject__c newVLNeed(Id volOppId, Id occId, Id contactId, String status) {
        OrphanedProject__c vlneed = new OrphanedProject__c(
                                        VolunteerOpportunity__c = volOppId,
                                        VolunteerLeader__c = contactId,
                                        Status__c = status,
                                        RecordTypeId = Schema.SObjectType.OrphanedProject__c.getRecordTypeInfosByName().get('Orphaned Opportunity').getRecordTypeId()
                                    );
        if(occId != null) {
            vlneed.Occurrence__c = occId;
            vlneed.RecordTypeId = Schema.SObjectType.OrphanedProject__c.getRecordTypeInfosByName().get('Orphaned Occurrence').getRecordTypeId();
        }
        return vlneed;
    }
}
