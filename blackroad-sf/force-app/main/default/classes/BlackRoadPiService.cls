public class BlackRoadPiService {
    static final String PI_ENDPOINT = 'https://agents.blackroad.io/webhooks/salesforce';
    static final String GEMATRIA_ENDPOINT = 'https://api.blackroad.io/webhooks/salesforce';
    
    @future(callout=true)
    public static void syncToAgents(String payload) {
        for (String endpoint : new String[]{PI_ENDPOINT, GEMATRIA_ENDPOINT}) {
            try {
                HttpRequest req = new HttpRequest();
                req.setEndpoint(endpoint);
                req.setMethod('POST');
                req.setHeader('Content-Type', 'application/json');
                req.setHeader('X-BlackRoad-Source', 'salesforce');
                req.setHeader('X-BlackRoad-Agent', 'ALICE');
                req.setBody(payload);
                req.setTimeout(10000);
                HttpResponse res = new Http().send(req);
                if (res.getStatusCode() >= 200 && res.getStatusCode() < 300) return;
            } catch(Exception e) {
                System.debug('BlackRoad sync failed: ' + e.getMessage());
            }
        }
    }
    
    public static void notifyAgents(String eventType, String objectType, String recordId) {
        String payload = JSON.serialize(new Map<String, String>{
            'event_type' => eventType,
            'object_type' => objectType,
            'record_id' => recordId,
            'timestamp' => String.valueOf(System.now()),
            'agent' => 'ALICE'
        });
        syncToAgents(payload);
    }
}
