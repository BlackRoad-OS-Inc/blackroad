# RoadMail

Transactional email service for the BlackRoad ecosystem.

## Features

- **Multi-Provider** - Resend, SendGrid, Mailgun support
- **Templates** - Mustache-style template rendering
- **Queue-based** - Cloudflare Queues for reliable delivery
- **Tracking** - Email status and delivery tracking
- **Webhooks** - Handle bounces and complaints
- **Bulk Sending** - Send to multiple recipients

## Quick Start

```bash
# Install
npm install

# Configure
export RESEND_API_KEY=re_xxx

# Deploy
wrangler deploy
```

## API Endpoints

### Send Email
```bash
POST /send
{
  "to": "user@example.com",
  "subject": "Hello!",
  "html": "<h1>Welcome</h1>"
}
```

### Send with Template
```bash
POST /send/template
{
  "to": "user@example.com",
  "template": "welcome",
  "data": {"name": "John", "company": "Acme"}
}
```

### Bulk Send
```bash
POST /bulk
{
  "emails": [
    {"to": "a@example.com", "subject": "Hi A", "html": "..."},
    {"to": "b@example.com", "subject": "Hi B", "html": "..."}
  ]
}
```

### Check Status
```bash
GET /status/:id
```

### Templates
- `GET /templates` - List templates
- `POST /templates` - Create template
- `GET /templates/:id` - Get template
- `DELETE /templates/:id` - Delete template

## Template Syntax

Use `{{variable}}` for dynamic content:

```html
<h1>Hello {{name}}!</h1>
<p>Welcome to {{company}}</p>
```

## Webhooks

Configure provider webhooks to:
- `POST /webhooks/resend`
- `POST /webhooks/sendgrid`
- `POST /webhooks/mailgun`

## License

Proprietary - BlackRoad OS, Inc.
