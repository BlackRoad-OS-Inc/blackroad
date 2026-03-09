# @blackroad/sdk

Official TypeScript/JavaScript SDK for BlackRoad APIs.

## Installation

```bash
npm install @blackroad/sdk
# or
yarn add @blackroad/sdk
# or
pnpm add @blackroad/sdk
```

## Quick Start

```typescript
import { BlackRoad } from '@blackroad/sdk';

const client = new BlackRoad({ apiKey: 'your-api-key' });

// Get infrastructure stats
const stats = await client.getStats();
console.log(`${stats.repositories} repositories across ${stats.githubOrgs} orgs`);

// List agents
const agents = await client.getAgents();
console.log(`${agents.length} active agents`);

// Deploy a service
const deployment = await client.deploy('my-service', 'PRODUCTION');
console.log(`Deployment ${deployment.id} started`);
```

## Features

- **GraphQL Client** - Full access to BlackRoad GraphQL API
- **Webhooks Client** - Create and manage webhook subscriptions
- **Email Client** - Send transactional and marketing emails
- **TypeScript** - Full type definitions included
- **Zero Dependencies** - Uses native fetch

## API Reference

### BlackRoad Client

```typescript
const client = new BlackRoad({
  apiKey: 'your-api-key',           // Optional API key
  graphqlUrl: 'https://...',        // Custom GraphQL endpoint
  webhooksUrl: 'https://...',       // Custom webhooks endpoint
  emailUrl: 'https://...',          // Custom email endpoint
});
```

### GraphQL Client

```typescript
// Raw queries
const result = await client.graphql.query(`
  query { infrastructureStats { repositories activeAgents } }
`);

// With variables
const agents = await client.graphql.query(`
  query($status: AgentStatus) { agents(status: $status) { id name } }
`, { status: 'ONLINE' });

// Convenience methods
const stats = await client.graphql.getInfrastructureStats();
const agents = await client.graphql.getAgents({ status: 'ONLINE', limit: 10 });
const deployments = await client.graphql.getDeployments({ service: 'my-app' });
const deployment = await client.graphql.deploy({ service: 'my-app', environment: 'PRODUCTION' });
```

### Webhooks Client

```typescript
// List webhooks
const webhooks = await client.webhooks.list();

// Create webhook
const webhook = await client.webhooks.create({
  url: 'https://example.com/webhook',
  events: ['deployment.succeeded', 'agent.error'],
  description: 'My webhook',
});
console.log('Secret:', webhook.secret); // Save this!

// Test webhook
await client.webhooks.test(webhook.id);

// Trigger event
await client.webhooks.trigger({
  type: 'user.created',
  data: { id: 'usr_123', email: 'user@example.com' },
});

// Get event types (106 available)
const types = await client.webhooks.getEventTypes();
```

### Email Client

```typescript
// Send email using template
await client.email.send({
  to: 'user@example.com',
  template: 'welcome',
  data: { name: 'John Doe' },
});

// Convenience methods
await client.email.sendWelcome('user@example.com', { name: 'John' });
await client.email.sendDeploymentSuccess('user@example.com', {
  name: 'John',
  service: 'my-app',
  version: 'v1.0.0',
});

// List templates
const templates = await client.email.getTemplates();

// Preview template HTML
const html = await client.email.previewTemplate('welcome');
```

## Types

```typescript
import {
  BlackRoad,
  BlackRoadConfig,
  BlackRoadError,
  GraphQLClient,
  WebhooksClient,
  EmailClient,
  Agent,
  AgentStatus,
  AgentType,
  Deployment,
  DeploymentStatus,
  Environment,
  InfrastructureStats,
  Webhook,
  WebhookEventType,
  EmailTemplate,
} from '@blackroad/sdk';
```

## Error Handling

```typescript
import { BlackRoadError } from '@blackroad/sdk';

try {
  await client.deploy('my-service');
} catch (error) {
  if (error instanceof BlackRoadError) {
    console.error(`API Error: ${error.message} (${error.statusCode})`);
  }
}
```

## Live API Endpoints

- **GraphQL**: https://blackroad-graphql-gateway.amundsonalexa.workers.dev/graphql
- **Webhooks**: https://blackroad-webhooks.amundsonalexa.workers.dev
- **Email**: https://blackroad-email.amundsonalexa.workers.dev

## License

MIT - BlackRoad OS, Inc.
