trigger OrphanedProjectTrigger on OrphanedProject__c (before update, after update) {
    new OrphanedProjectTriggerHandler().run();
}