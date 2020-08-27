global class ContactConnectionsCalcBatch implements Database.Batchable<sObject>{
	String query;
    String attendanceStatus = 'Attended (and Hours Verified)';

    // Empty constructor
    global ContactConnectionsCalcBatch(){

    }

    global Database.QueryLocator start(Database.BatchableContext BC){
    	query = 'SELECT Id, Number_of_Projects_Attended_and_Verified__c, (SELECT Id FROM HOC__Connection__r WHERE HOC__Attendance_Status__c =: attendanceStatus) FROM Contact WHERE ID IN (SELECT HOC__Contact__c FROM HOC__Connection__c)';
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope){
        ContactUtilitiesClass.batchCalculateConnections((List<Contact>) scope);
    }

    global void finish(Database.BatchableContext BC){

    }
}
