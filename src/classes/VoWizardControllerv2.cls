public class VoWizardControllerv2 {
  public VoWizardControllerv2(ApexPages.StandardController stdController) {}
    public Flow.Interview.Vounteer_Opportunity_Wizard VOWizardFLow2{get;set;}

    public String returnId;

    public PageReference getBackToVO(){

        if(VOWizardFLow2 != null) returnId = (String) VOWizardFLow2.getVariableValue('VAR_Volunteer_Opp_ID');

        PageReference send = new PageReference('/' + returnId);
        send.setRedirect(true);
        return send;

    }
}