# BlackRoad Webhooks

Comprehensive webhooks event system for the BlackRoad ecosystem - 106 event types, HMAC-SHA256 signatures, retry logic.

## Live Endpoints

- **Dashboard**: https://blackroad-webhooks.amundsonalexa.workers.dev
- **Health**: https://blackroad-webhooks.amundsonalexa.workers.dev/health
- **Event Types**: https://blackroad-webhooks.amundsonalexa.workers.dev/events/types

## Features

- **106 Event Types** across 13 categories
- **HMAC-SHA256 Signature Verification** with timing-safe comparison
- **Automatic Retry Logic** (5 attempts with exponential backoff)
- **Webhook Management API** (create, list, test, delete)
- **Delivery Logs** with full request/response tracking
- **Test Mode** for development

## Event Categories

| Category | Events | Examples |
|----------|--------|----------|
| USER | 10 | user.created, user.login, user.role_changed |
| ORGANIZATION | 8 | organization.created, organization.member_added |
| DEPLOYMENT | 10 | deployment.started, deployment.succeeded, deployment.failed |
| AGENT | 11 | agent.started, agent.task_completed, agent.error |
| REPOSITORY | 7 | repository.created, repository.archived |
| PULL_REQUEST | 9 | pull_request.opened, pull_request.merged |
| ISSUE | 8 | issue.opened, issue.closed, issue.assigned |
| BILLING | 9 | billing.invoice_paid, billing.subscription_cancelled |
| SECURITY | 8 | security.vulnerability_detected, security.breach_detected |
| INFRASTRUCTURE | 9 | infrastructure.service_down, infrastructure.scaling_completed |
| DEVICE | 7 | device.connected, device.firmware_updated |
| API | 5 | api.rate_limit_exceeded, api.latency_spike |
| NOTIFICATION | 5 | notification.sent, notification.delivered |

## API Reference

### Create Webhook
```bash
curl -X POST https://blackroad-webhooks.amundsonalexa.workers.dev/webhooks \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://your-server.com/webhook",
    "events": ["user.created", "deployment.succeeded"],
    "description": "My webhook"
  }'
```

### List Webhooks
```bash
curl https://blackroad-webhooks.amundsonalexa.workers.dev/webhooks
```

### Test Webhook
```bash
curl -X POST https://blackroad-webhooks.amundsonalexa.workers.dev/webhooks/wh_xxx/test
```

### Trigger Event
```bash
curl -X POST https://blackroad-webhooks.amundsonalexa.workers.dev/events \
  -H "Content-Type: application/json" \
  -d '{
    "type": "user.created",
    "data": {
      "id": "usr_123",
      "email": "user@example.com"
    }
  }'
```

## Signature Verification

All webhook deliveries are signed with HMAC-SHA256. Verify signatures in your handler:

```javascript
const crypto = require('crypto');

function verifyWebhookSignature(payload, signatureHeader, secret) {
  const [timestampPart, hashPart] = signatureHeader.split(',');
  const timestamp = timestampPart.split('=')[1];
  const signature = hashPart.split('=')[1];

  const expectedSignature = crypto
    .createHmac('sha256', secret)
    .update(`${timestamp}.${payload}`)
    .digest('hex');

  return crypto.timingSafeEqual(
    Buffer.from(signature),
    Buffer.from(expectedSignature)
  );
}

// Express.js example
app.post('/webhook', (req, res) => {
  const signature = req.headers['x-blackroad-signature'];
  const payload = JSON.stringify(req.body);

  if (!verifyWebhookSignature(payload, signature, process.env.WEBHOOK_SECRET)) {
    return res.status(401).send('Invalid signature');
  }

  // Process event
  const event = req.body;
  console.log(`Received ${event.type}:`, event.data);

  res.status(200).send('OK');
});
```

## Webhook Payload Format

```json
{
  "id": "evt_abc123",
  "type": "user.created",
  "created_at": "2026-02-15T10:00:00Z",
  "data": {
    "id": "usr_123",
    "email": "user@example.com",
    "name": "New User"
  }
}
```

## Headers

Each webhook delivery includes:

| Header | Description |
|--------|-------------|
| `X-BlackRoad-Signature` | HMAC-SHA256 signature (t=timestamp,v1=hash) |
| `X-BlackRoad-Event` | Event type (e.g., user.created) |
| `X-BlackRoad-Delivery` | Unique delivery ID |
| `Content-Type` | application/json |

## Development

```bash
npm install
npm run dev      # Start local dev server
npm run deploy   # Deploy to Cloudflare
```

## License

Proprietary - BlackRoad OS, Inc.
