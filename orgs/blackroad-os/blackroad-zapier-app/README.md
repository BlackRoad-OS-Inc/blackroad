# BlackRoad Zapier App

Official Zapier integration for BlackRoad OS - connect AI infrastructure to 5000+ apps.

## Features

### Triggers (Start a Zap when...)
| Trigger | Description |
|---------|-------------|
| New User | A new user signs up |
| Deployment Complete | A deployment finishes |
| Error Occurred | An error is detected |
| Agent Status Change | An AI agent's status changes |
| Usage Threshold | Usage exceeds your limit |

### Actions (Do this...)
| Action | Description |
|--------|-------------|
| Deploy Product | Trigger a deployment |
| Create User | Add a new user |
| Update Config | Change configuration |
| Send Notification | Send alerts (Slack/email) |
| Scale Agents | Scale AI agents up/down |

### Searches (Find...)
| Search | Description |
|--------|-------------|
| Find User | Search by email or ID |
| Find Deployment | Search by ID or service |

## Installation

1. Go to [Zapier](https://zapier.com/apps/blackroad/integrations)
2. Click "Connect BlackRoad"
3. Enter your API key from https://blackroad.io/settings/api

## Example Zaps

- **Slack + BlackRoad**: Get Slack notifications when deployments complete
- **Email + BlackRoad**: Email team when errors occur
- **Google Sheets + BlackRoad**: Log new users to a spreadsheet
- **Airtable + BlackRoad**: Track agent status changes
- **PagerDuty + BlackRoad**: Alert on-call when critical errors occur

## Development

```bash
# Install dependencies
npm install

# Test locally
npm test

# Validate app
npm run validate

# Push to Zapier
npm run push
```

## API Base URL

`https://api.blackroad.io/v1/`

## License

MIT © BlackRoad OS, Inc.
