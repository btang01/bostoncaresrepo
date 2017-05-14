/**
 * An apex page controller that exposes the site forgot password functionality
 */
public class ForgotPasswordController {

    public ForgotPasswordController(controllerAffiliate controller) {

    }


    public String propUsername {get; set;}   
       
    public ForgotPasswordController() {}
    
    public PageReference forgotPassword() {
        boolean success = Site.forgotPassword(propUsername);
        PageReference pr = Page.ForgotPasswordConfirm;
        pr.setRedirect(true);
        
        if (success) {              
            return pr;
        }
        return null;
    }
    
     public static testMethod void testForgotPasswordController() {
        // Instantiate a new controller with all parameters in the page
        ForgotPasswordController controller = new ForgotPasswordController();
        controller.propUsername = 'test@salesforce.com';        
    
        System.assertEquals(controller.forgotPassword(),null); 
    }
}