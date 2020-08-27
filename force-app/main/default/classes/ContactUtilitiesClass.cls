/*
* Title: ContactUtilitiesClass
* Created By: Brian Tang
* Description: This is used by the Contact Utilities Page to execute actions
* to manage Contacts in the Boston Cares SF environment.
*
*/

global class ContactUtilitiesClass {

    // This method is initiated from the Calculate Volunteer Connections button on the Contact Utilities Page
    // It calls the ContactConnectionsCalcBatch to initiate calculating the number of
    // Connections where Attendance = "Attended (and Hours Verified)" under that Contact
    public static void calculateConnections(){
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM,'The volunteer connections calculation has been initiated for all volunteers! Please wait about an 30 minutes for this process to complete.'));

        ContactConnectionsCalcBatch batch = new ContactConnectionsCalcBatch();
        Database.executeBatch(batch, 200);
    }


    // After calculateConnections() initiates ContactConnectionsCalcBatch,
    // ContactConnectionsCalcBatch will use this method to actually perform the updates to the Contacts
    public static void batchCalculateConnections(List<Contact> listOfContacts){
        List<Contact> conToUpdateList = new List<Contact>();

        for(Contact con : listOfContacts){
            con.Number_of_Projects_Attended_and_Verified__c = con.HOC__Connection__r.size();
            conToUpdateList.add(con);
        }

        update conToUpdateList;
    }
 }
