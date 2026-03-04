/**
 * StripeIntegration - Connect Stripe account to Salesforce
 * Setup: Add STRIPE_SECRET_KEY to Named Credentials
 */
public class StripeIntegration {
    
    private static final String STRIPE_API = 'https://api.stripe.com/v1';
    
    @AuraEnabled
    public static Map<String, Object> getBalance() {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(STRIPE_API + '/balance');
        req.setMethod('GET');
        req.setHeader('Authorization', 'Bearer ' + getStripeKey());
        
        Http http = new Http();
        HttpResponse res = http.send(req);
        
        if (res.getStatusCode() == 200) {
            return (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        }
        throw new AuraHandledException('Stripe API error: ' + res.getBody());
    }
    
    @AuraEnabled
    public static Map<String, Object> createPaymentIntent(Decimal amount, String currency) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(STRIPE_API + '/payment_intents');
        req.setMethod('POST');
        req.setHeader('Authorization', 'Bearer ' + getStripeKey());
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        req.setBody('amount=' + Integer.valueOf(amount * 100) + '&currency=' + currency);
        
        Http http = new Http();
        HttpResponse res = http.send(req);
        return (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
    }
    
    private static String getStripeKey() {
        // Uses BlackRoad_Config__c custom setting for the Stripe key.
        // Setup: Setup → Custom Settings → BlackRoad Config → Stripe_Secret_Key__c
        BlackRoad_Config__c config = BlackRoad_Config__c.getInstance();
        if (config == null || String.isBlank(config.Stripe_Secret_Key__c)) {
            throw new AuraHandledException(
                'Stripe API key not configured. Go to Setup → Custom Settings → BlackRoad Config and set Stripe_Secret_Key__c.'
            );
        }
        return config.Stripe_Secret_Key__c;
    }
}
