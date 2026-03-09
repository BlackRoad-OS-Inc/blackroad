# BlackRoad Zapier Integration

**Official Zapier app for BlackRoad OS automation**

## Overview

Connect BlackRoad OS to 5,000+ apps through Zapier automation.

## Triggers

| Trigger | Description |
|---------|-------------|
| New User Created | Fires when a new user signs up |
| Deployment Complete | Fires when a deployment finishes |
| Error Occurred | Fires on system errors |
| Task Completed | Fires when a task is done |
| Agent Status Change | Fires when agent status changes |

## Actions

| Action | Description |
|--------|-------------|
| Deploy Product | Deploy a BlackRoad product |
| Create User | Create new user account |
| Update Config | Update system configuration |
| Run Agent | Execute an AI agent task |
| Send Notification | Send via BlackRoad channels |

## Example Zaps

### Slack + BlackRoad
1. **Trigger:** New message in Slack channel
2. **Action:** Run BlackRoad AI agent on message

### GitHub + BlackRoad
1. **Trigger:** New PR opened
2. **Action:** Deploy review environment

### Stripe + BlackRoad
1. **Trigger:** Payment successful
2. **Action:** Provision user account

## Authentication

OAuth 2.0 with BlackRoad API credentials.

```json
{
  "type": "oauth2",
  "client_id": "{{BLACKROAD_CLIENT_ID}}",
  "client_secret": "{{BLACKROAD_CLIENT_SECRET}}",
  "authorization_url": "https://api.blackroad.io/oauth/authorize",
  "token_url": "https://api.blackroad.io/oauth/token"
}
```

## API Endpoints

- `POST /api/v1/zapier/deploy` - Deploy product
- `POST /api/v1/zapier/users` - Create user
- `PUT /api/v1/zapier/config` - Update config
- `POST /api/v1/zapier/agents/run` - Run agent

## Installation

1. Go to [Zapier](https://zapier.com)
2. Search for "BlackRoad OS"
3. Connect your account
4. Start building Zaps!

---

*BlackRoad OS - Connect Everything*
