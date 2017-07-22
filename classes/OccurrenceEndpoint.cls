/*
 * Title: OccurrenceEndpoint
 * Created By: Phil Currier
 * Description: Volunteer Leaders can POST to this endpoint to create Occurrences
 *   (along with any needed parent objects) in the system.
 */

@RestResource(urlMapping='/Occurrence/*')
global with sharing class OccurrenceEndpoint {
    public static ID nonprofitId = schema.SObjectType.Account.getRecordTypeInfosByName().get('Nonprofit').getRecordTypeId();

    @HttpPost
    global static void createOccurrence() {
        RestRequest req = RestContext.request;
        //String orgName = req.params.get('orgName');

        //User hocAdmin = [SELECT Id FROM User WHERE Name =: '0005 HOC Admin'][0];
        //String hocId = hocAdmin.Id;

        //createOrganization(hocId, nonprofitId, orgName);
        RestContext.response.addHeader('Content-Type', 'application/json');
        RestContext.response.responseBody = Blob.valueOf('{ "value" : "Hello" }');
        //return '{}';
    }

    // Creates an organization if it does not already exist
    static void createOrganization(ID hocId, ID nonprofitId, String orgName) {
        List<Account> matches = [
            select Id
            from Account
            where Name =: orgName
        ];

        if (matches.size() == 0) {
            Account acc = new Account();
            acc.Name = orgName;
            //acc.Owner = hocId;
            acc.RecordTypeId = nonprofitId;
            //acc.TypeId = nonprofitId;
            acc.HOC__Status__c = 'Active Partner';
            acc.Walk_in_or_Appointment_Only__c = 'Walk-in';
            acc.HOC__Primary_Address__c = 'Shipping';
            acc.HOC__Address_Visibility__c = 'City and Zip only';
            acc.ShippingStreet = '123 Fake Street';
            acc.ShippingCity = 'Fake City';
            acc.ShippingState = 'MA';
            acc.ShippingPostalCode = '02446';
            acc.ShippingCountry = 'USA';
            acc.HOC__Partner_Approval_Manager__c = hocId;
            acc.HOC__Impact_Area__c = 'Adult Education';
            insert acc;
        }
    }
}