trigger OrphanedProjectTrigger on OrphanedProject__c (after update) {
    new OrphanedProjectTriggerHandler().run();
}