# BlackRoad Slack App

Official Slack integration for BlackRoad OS - manage AI agents, deployments, and infrastructure from Slack.

## Features

### Slash Commands

| Command | Description |
|---------|-------------|
| `/blackroad status` | Show infrastructure status (orgs, repos, agents) |
| `/blackroad agents` | List AI agents with status and task counts |
| `/blackroad usage` | View usage statistics (API calls, compute, storage) |
| `/blackroad deploy <service>` | Trigger a deployment |
| `/blackroad help` | Show available commands |

### Interactive Messages

- Rich status cards with real-time data
- Agent management with quick actions
- Deployment notifications with progress tracking
- Usage alerts and billing notifications

## Installation

### Add to Slack

1. Go to [BlackRoad Slack App](https://blackroad.io/integrations/slack)
2. Click "Add to Slack"
3. Authorize the app for your workspace

### Manual Setup (Self-hosted)

```bash
# Set secrets
wrangler secret put SLACK_SIGNING_SECRET
wrangler secret put SLACK_BOT_TOKEN

# Deploy
npm run deploy
```

## Endpoints

| Endpoint | Purpose |
|----------|---------|
| `/health` | Health check |
| `/slack/commands` | Slash command handler |
| `/slack/interactions` | Interactive component handler |
| `/slack/events` | Event subscription handler |

## License

MIT © BlackRoad OS, Inc.
