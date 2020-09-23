trigger taskIdDuplicatePreventer on Project_Task__c (before insert, before update)
{
    Map<String, Project_Task__c> taskIdMap = new Map<String, Project_Task__c>();
    String projId = '';

    for (Project_Task__c pt : System.Trigger.new)
    {
    // for update don't check unless the value has changed
    if (System.Trigger.isInsert || (pt.task_id__c != System.Trigger.oldMap.get(pt.Id).task_id__c))
    {
        String taskId = pt.task_id__c;
        taskIdMap.put (taskId, pt);
        // we won't enforce this for a bulk load, need more features added for that
        // so if we encounter multiple project site visits just exit
        if (projId == '')
        {
            projId = pt.Project_Site_Visit__c;
        }
        else
        {
            return;
        }
    }
    }
    for (Project_Task__c pt : [ select task_id__c from Project_Task__c where task_id__c in :taskIdMap.KeySet() and Project_Site_Visit__c = :projId])
    {
    Project_Task__c badpt = taskIdMap.get (pt.task_id__c);
    badpt.Task_Number__c.addError ('Another task in this project has the same id.');
    }
}