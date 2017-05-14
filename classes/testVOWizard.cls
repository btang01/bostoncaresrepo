@isTest
private class testVOWizard {
	
	@isTest static void test_VOWizard() {
		HOC__Volunteer_Opportunity__c vo = new HOC__Volunteer_Opportunity__c(name='Tester');
		ApexPages.StandardController sc = new ApexPages.standardController(vo);
		VOWizardController vow = new VOWizardController(sc);
		PageReference noVO = new PageReference('/' + null);
		PageReference getVO = vow.getBackToVO();
		System.assertEquals(getVO.getUrl(), noVO.getUrl());
	}
		
}