# BlackBox Huginn

> Open source agent automation system (Fork)

## Quick Reference

| Property | Value |
|----------|-------|
| **Upstream** | huginn/huginn |
| **Language** | Ruby |
| **Framework** | Rails |
| **License** | MIT |

## Tech Stack

```
Backend: Ruby on Rails
Database: PostgreSQL/MySQL
Queue: Sidekiq + Redis
Frontend: ERB + JavaScript
```

## Commands

```bash
bundle install      # Install dependencies
rails server        # Start development
rake db:migrate     # Run migrations
rake spec           # Run tests
```

## BlackRoad Integration

Sovereign fork for:
- Custom agent types
- BlackRoad event triggers
- IFTTT-style automation

## Key Concepts

- **Agents**: Autonomous tasks that monitor and act
- **Scenarios**: Groups of connected agents
- **Events**: Data passed between agents
- **Credentials**: Secure API key storage

## Agent Types

| Type | Description |
|------|-------------|
| Website | Scrape web pages |
| RSS | Monitor feeds |
| Email | Send/receive email |
| Webhook | HTTP triggers |
| JavaScript | Custom logic |

## Related Repos

- `blackbox-n8n` - n8n workflows
- `blackbox-activepieces` - No-code automation
- `blackroad-agents` - BlackRoad agents
