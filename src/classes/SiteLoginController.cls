/**
 * An apex page controller that exposes the site login functionality
 */
global class SiteLoginController {

    public SiteLoginController(controllerAffiliate controller) {

    }
    private transient String strMsg = '';
    global String username {get; set;}
    global String password {get; set;}
    global String propMessage  { get {return strMsg;} set{strMsg = value;} } 

    global PageReference login() 
    {
        String startUrl = System.currentPageReference().getParameters().get('startURL');
        //Select u.Profile.Name From User u WHERE u.Id =: UserInfo.getUserId()
        String strSuccLogin = '/home/home.jsp';
//        System.Debug('############   '+Site.login(username, password, strSuccLogin));
//        PageReference tempPR = Site.login(username, password, strSuccLogin);
//        if(tempPR.getUrl().contains('https://dev-hoc-v1-developer-edition.na7.force.com/AffiliateHome?refURL='))
//            tempPR = new PageReference('/apex/AffiliateHome'); 
        
        PageReference pr = Site.login(username, password, strSuccLogin);
        //PageReference pr = Site.login(username, password, startUrl);
        if(ApexPages.hasMessages())
        {
             ApexPages.Message [] apm = ApexPages.getMessages();
             for(ApexPages.Message am : apm)
             {
                 if(strMsg != null && strMsg != '')
                     strMsg = strMsg + '  ' + am.getSummary();
                 else
                     strMsg = am.getSummary();
             }
        }
        else
        {
            strMsg = '';
        } 
        username = '';
        password = ''; 
        return pr;
    }
    
    global SiteLoginController () {}
    
    global static testMethod void testSiteLoginController () {
        // Instantiate a new controller with all parameters in the page
        SiteLoginController controller = new SiteLoginController ();
        controller.username = 'test@salesforce.com';
        controller.password = '123456'; 
                
        System.assertEquals(controller.login(),null);                           
    }    
}