#!/usr/bin/env node
// BlackRoad Salesforce → Pi Agent Integration
// Deploys webhook listener that forwards SF events to Pi agent fleet

const PI_GATEWAY = process.env.PI_GATEWAY || 'http://192.168.4.38:4010';
const GEMATRIA_GATEWAY = process.env.GEMATRIA_GATEWAY || 'https://api.blackroad.io';
const SF_WEBHOOK_SECRET = process.env.SF_WEBHOOK_SECRET || '';

// Salesforce outbound message handler
async function handleSalesforceEvent(event) {
  const payload = {
    source: 'salesforce',
    event_type: event.type,
    object: event.object,
    data: event.data,
    timestamp: new Date().toISOString(),
    agent: 'ALICE'  // DevOps agent handles SF events
  };

  // Route to Pi agent
  const targets = [
    `${PI_GATEWAY}/webhooks/salesforce`,
    `${GEMATRIA_GATEWAY}/webhooks/salesforce`
  ];

  for (const url of targets) {
    try {
      const res = await fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'X-BlackRoad-Source': 'salesforce' },
        body: JSON.stringify(payload),
        signal: AbortSignal.timeout(5000)
      });
      if (res.ok) {
        console.log(`✅ SF event forwarded to ${url}`);
        return await res.json();
      }
    } catch (e) {
      console.error(`⚠️ ${url} failed: ${e.message}`);
    }
  }
}

// Salesforce Platform Event listener (LWC component)
const APEX_TRIGGER = `
// BlackRoad Pi Integration Trigger
trigger BlackRoadPiSync on Task (after insert, after update) {
    BlackRoadPiService.syncToAgents(Trigger.new);
}
`;

const APEX_CLASS = `
public class BlackRoadPiService {
    static final String PI_ENDPOINT = '${PI_GATEWAY}/webhooks/salesforce';
    static final String GEMATRIA_ENDPOINT = '${GEMATRIA_GATEWAY}/webhooks/salesforce';
    
    @future(callout=true)
    public static void syncToAgents(List<SObject> records) {
        String payload = JSON.serialize(records);
        
        // Try Pi first, fallback to Gematria
        for (String endpoint : new String[]{PI_ENDPOINT, GEMATRIA_ENDPOINT}) {
            try {
                HttpRequest req = new HttpRequest();
                req.setEndpoint(endpoint);
                req.setMethod('POST');
                req.setHeader('Content-Type', 'application/json');
                req.setHeader('X-BlackRoad-Source', 'salesforce');
                req.setBody(payload);
                req.setTimeout(5000);
                
                HttpResponse res = new Http().send(req);
                if (res.getStatusCode() == 200) return;
            } catch(Exception e) {
                System.debug('BlackRoad Pi sync failed: ' + e.getMessage());
            }
        }
    }
}
`;

console.log('BlackRoad Salesforce → Pi Integration');
console.log('Pi Gateway:', PI_GATEWAY);
console.log('Gematria Gateway:', GEMATRIA_GATEWAY);
console.log('');
console.log('Deploy Apex Trigger:');
console.log(APEX_TRIGGER);
console.log('Deploy Apex Class:');
console.log(APEX_CLASS.substring(0, 200) + '...');

module.exports = { handleSalesforceEvent };
