public class VoWizardController {
	public VoWizardController(ApexPages.StandardController stdController) {}
    public Flow.Interview.Volunteer_Opportunity_Wizard_Flow VOWizardFLow{get;set;}

    public String returnId;

    public PageReference getBackToVO(){

        if(VOWizardFLow != null) returnId = (String) VOWizardFLow.getVariableValue('VAR_Volunteer_Opp_ID');

        PageReference send = new PageReference('/' + returnId);
        send.setRedirect(true);
        return send;

    }
}