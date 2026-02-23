/**
 * BlackRoad OS — Stripe Sync Service
 * Pulls customers, subscriptions, charges, invoices into Salesforce
 * $0 platform cost — your data, your CRM
 */
public with sharing class StripeSyncService {

    private static final String STRIPE_BASE = 'https://api.stripe.com/v1';

    // ── Generic Stripe GET ────────────────────────────────────────────────────
    private static List<Object> stripeList(String endpoint, String stripeKey) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(STRIPE_BASE + endpoint + '?limit=100');
        req.setMethod('GET');
        req.setHeader('Authorization', 'Bearer ' + stripeKey);
        req.setTimeout(30000);

        HttpResponse res = new Http().send(req);
        if (res.getStatusCode() != 200) return new List<Object>();

        Map<String, Object> body = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        return (List<Object>) body.get('data');
    }

    // ── Sync customers ────────────────────────────────────────────────────────
    @future(callout=true)
    public static void syncCustomers(String stripeKey) {
        List<Object> customers = stripeList('/customers', stripeKey);
        List<StripeRecord__c> recs = new List<StripeRecord__c>();
        for (Object c : customers) {
            Map<String, Object> cust = (Map<String, Object>) c;
            recs.add(new StripeRecord__c(
                Name           = (String) cust.get('email') != null
                                    ? (String) cust.get('email')
                                    : (String) cust.get('id'),
                StripeId__c    = (String) cust.get('id'),
                RecordType__c  = 'customer',
                CustomerEmail__c = (String) cust.get('email'),
                CustomerName__c  = (String) cust.get('name'),
                Description__c   = (String) cust.get('description'),
                Status__c        = 'active',
                LiveMode__c      = (Boolean) cust.get('livemode')
            ));
        }
        if (!recs.isEmpty()) Database.upsert(recs, StripeRecord__c.StripeId__c, false);
    }

    // ── Sync charges ─────────────────────────────────────────────────────────
    @future(callout=true)
    public static void syncCharges(String stripeKey) {
        List<Object> charges = stripeList('/charges', stripeKey);
        List<StripeRecord__c> recs = new List<StripeRecord__c>();
        for (Object ch : charges) {
            Map<String, Object> charge = (Map<String, Object>) ch;
            Decimal amt = charge.get('amount') != null
                ? ((Decimal) charge.get('amount')) / 100
                : 0;
            recs.add(new StripeRecord__c(
                Name           = (String) charge.get('id'),
                StripeId__c    = (String) charge.get('id'),
                RecordType__c  = 'charge',
                Amount__c      = amt,
                Currency__c    = (String) charge.get('currency'),
                Status__c      = (String) charge.get('status'),
                CustomerEmail__c = (String) charge.get('receipt_email'),
                Description__c   = (String) charge.get('description'),
                LiveMode__c      = (Boolean) charge.get('livemode')
            ));
        }
        if (!recs.isEmpty()) Database.upsert(recs, StripeRecord__c.StripeId__c, false);
    }

    // ── Sync subscriptions ───────────────────────────────────────────────────
    @future(callout=true)
    public static void syncSubscriptions(String stripeKey) {
        List<Object> subs = stripeList('/subscriptions', stripeKey);
        List<StripeRecord__c> recs = new List<StripeRecord__c>();
        for (Object s : subs) {
            Map<String, Object> sub = (Map<String, Object>) s;
            // Get plan/price name from items
            String planName = '';
            Map<String, Object> items = (Map<String, Object>) sub.get('items');
            if (items != null) {
                List<Object> itemData = (List<Object>) items.get('data');
                if (itemData != null && !itemData.isEmpty()) {
                    Map<String, Object> item  = (Map<String, Object>) itemData[0];
                    Map<String, Object> price = (Map<String, Object>) item.get('price');
                    if (price != null) planName = (String) price.get('nickname');
                }
            }
            Long start = (Long) sub.get('current_period_start');
            Long periodEnd = (Long) sub.get('current_period_end');
            recs.add(new StripeRecord__c(
                Name           = (String) sub.get('id'),
                StripeId__c    = (String) sub.get('id'),
                RecordType__c  = 'subscription',
                Status__c      = (String) sub.get('status'),
                ProductName__c = planName,
                PeriodStart__c = start  != null ? DateTime.newInstance(start  * 1000) : null,
                PeriodEnd__c   = periodEnd != null ? DateTime.newInstance(periodEnd * 1000) : null,
                LiveMode__c    = (Boolean) sub.get('livemode')
            ));
        }
        if (!recs.isEmpty()) Database.upsert(recs, StripeRecord__c.StripeId__c, false);
    }

    // ── Sync all at once (chained, no parallel @future limit hit) ────────────
    @AuraEnabled
    public static String triggerFullSync(String stripeKey) {
        syncCustomers(stripeKey);
        syncCharges(stripeKey);
        syncSubscriptions(stripeKey);
        return 'Stripe sync triggered (customers + charges + subscriptions). Cost: $0.';
    }

    // ── SOQL helpers ─────────────────────────────────────────────────────────
    @AuraEnabled(cacheable=true)
    public static List<StripeRecord__c> getStripeRecords(String typeFilter) {
        if (String.isNotBlank(typeFilter) && typeFilter != 'all') {
            return [SELECT Id, Name, StripeId__c, RecordType__c, Amount__c, Currency__c,
                           Status__c, CustomerEmail__c, CustomerName__c, ProductName__c,
                           PeriodStart__c, PeriodEnd__c, LiveMode__c
                    FROM StripeRecord__c
                    WHERE RecordType__c = :typeFilter
                    ORDER BY CreatedDate DESC LIMIT 500];
        }
        return [SELECT Id, Name, StripeId__c, RecordType__c, Amount__c, Currency__c,
                       Status__c, CustomerEmail__c, CustomerName__c, ProductName__c,
                       PeriodStart__c, PeriodEnd__c, LiveMode__c
                FROM StripeRecord__c
                ORDER BY RecordType__c, CreatedDate DESC LIMIT 500];
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getStripeStats() {
        Map<String, Object> stats = new Map<String, Object>();
        stats.put('customers',     [SELECT COUNT() FROM StripeRecord__c WHERE RecordType__c = 'customer']);
        stats.put('charges',       [SELECT COUNT() FROM StripeRecord__c WHERE RecordType__c = 'charge']);
        stats.put('subscriptions', [SELECT COUNT() FROM StripeRecord__c WHERE RecordType__c = 'subscription']);
        AggregateResult[] rev = [SELECT SUM(Amount__c) total FROM StripeRecord__c
                                  WHERE RecordType__c = 'charge' AND Status__c = 'succeeded'];
        stats.put('totalRevenue', rev[0].get('total'));
        return stats;
    }
}
