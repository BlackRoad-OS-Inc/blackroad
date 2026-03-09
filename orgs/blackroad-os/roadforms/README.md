# RoadForms

Form builder platform for the BlackRoad ecosystem.

## Features

- **Form Builder** - Create forms with multiple field types
- **Field Types** - Text, email, phone, number, select, radio, checkbox, date, file
- **Validation** - Required fields, patterns, min/max
- **Conditional Logic** - Show/hide fields based on answers
- **Submissions** - Store and manage responses
- **Webhooks** - Send data to external services
- **Embed** - Generate embeddable form HTML
- **Export** - Download submissions as CSV
- **Analytics** - Submission stats by day and country

## Quick Start

```bash
npm install
wrangler deploy
```

## API Endpoints

### Forms
- `GET /forms` - List all forms
- `POST /forms` - Create form
- `GET /forms/:id` - Get form
- `PUT /forms/:id` - Update form
- `DELETE /forms/:id` - Delete form
- `POST /forms/:id/publish` - Publish form
- `POST /forms/:id/unpublish` - Unpublish form

### Submissions
- `POST /forms/:id/submit` - Submit form
- `GET /forms/:id/submissions` - List submissions
- `GET /forms/:id/submissions/:subId` - Get submission
- `DELETE /forms/:id/submissions/:subId` - Delete submission
- `GET /forms/:id/export` - Export as CSV

### Embed & Analytics
- `GET /forms/:id/embed` - Get embeddable HTML
- `GET /forms/:id/analytics` - Get analytics

## Form Schema

```json
{
  "name": "Contact Form",
  "description": "Get in touch",
  "fields": [
    {
      "id": "name",
      "type": "text",
      "label": "Your Name",
      "required": true
    },
    {
      "id": "email",
      "type": "email",
      "label": "Email Address",
      "required": true
    },
    {
      "id": "message",
      "type": "textarea",
      "label": "Message",
      "required": true
    }
  ],
  "settings": {
    "submitButton": "Send Message",
    "successMessage": "Thanks! We'll be in touch.",
    "webhookUrl": "https://api.example.com/form-webhook"
  }
}
```

## License

Proprietary - BlackRoad OS, Inc.
