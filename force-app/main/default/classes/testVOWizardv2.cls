@isTest
private class testVOWizardv2 {
  
  @isTest static void test_VOWizardv2() {
    HOC__Volunteer_Opportunity__c vo = new HOC__Volunteer_Opportunity__c(name='Tester');
    ApexPages.StandardController sc = new ApexPages.standardController(vo);
    VOWizardControllerv2 vow = new VOWizardControllerv2(sc);
    PageReference noVO = new PageReference('/' + null);
    PageReference getVO = vow.getBackToVO();
    System.assertEquals(getVO.getUrl(), noVO.getUrl());
  }
    
}