# Cloudflare Workers

> 82 edge workers deployed globally

## Core Infrastructure

| Worker | Purpose | Last Modified |
|--------|---------|---------------|
| blackroad-io | Main website | 2026-01-26 |
| blackroad-io-production | Production site | 2026-01-26 |
| blackroad-api | API gateway | 2026-01-12 |
| blackroad-api-gateway | API routing | 2025-12-11 |
| blackroad-continuity-api | Cross-session state | 2026-01-23 |
| blackroad-operator | Operations | 2026-01-12 |

## AI & Agents

| Worker | Purpose |
|--------|---------|
| lucidia | AI core |
| lucidia-core | Lucidia engine |
| lucidia-evolution | AI evolution |
| lucidia-platform | Platform services |
| blackroad-agents | Agent orchestration |
| cece | Claude integration |

## Payments & Billing

| Worker | Purpose |
|--------|---------|
| blackroad-payment-gateway | Stripe integration |
| blackroad-stripe-billing | Billing management |
| blackroad-stripe-checkout | Checkout flows |
| blackroad-stripe-webhooks | Webhook handlers |
| blackroad-billing | Billing core |
| blackroad-gateway-billing | Gateway billing |

## Routing & Network

| Worker | Purpose |
|--------|---------|
| blackroad-router | Main router |
| blackroad-domain-router | Domain routing |
| blackroad-subdomain-router | Subdomain routing |
| blackroad-network-router | Network routing |
| blackroad-edge-gateway | Edge gateway |
| blackroad-gateway | Gateway core |
| blackroad-gateway-v2 | Gateway v2 |

## Data & Storage

| Worker | Purpose |
|--------|---------|
| blackroad-d1-api | D1 database API |
| blackroad-kv-manager | KV management |
| blackroad-do-manager | Durable Objects |
| blackroad-logs | Logging |
| blackroad-telemetry | Telemetry |

## Security & Auth

| Worker | Purpose |
|--------|---------|
| blackroad-auth | Authentication |
| blackroad-identity | Identity management |
| blackroad-intercept | Request interception |
| blackroad-cipher | Encryption |
| blackroad-sovereignty | Data sovereignty |
| blackroad-ratelimit | Rate limiting |

## Specialized

| Worker | Purpose |
|--------|---------|
| blackroad-crm | CRM functions |
| blackroad-crm-autotagging | Auto-tagging |
| blackroad-quantum-memory | Quantum memory |
| blackroad-mesh | Service mesh |
| blackroad-watcher | Monitoring |
| blackroad-helper | Helper functions |

## Domain-Specific Routers

| Worker | Domain |
|--------|--------|
| lucidia-earth-router | lucidia.earth |
| lucidia-studio-router | lucidia.studio |
| blackroadai-router | blackroad.ai |
| blackroadquantum-router | blackroadquantum.* |
| blackroad-systems-router | systems.* |

## Full List (82 workers)

```
applier-api
apollo-signaling-server
blackroad-agents
blackroad-api
blackroad-api-gateway
blackroad-api-preview
blackroad-asana-manager
blackroad-auth
blackroad-billing
blackroad-cipher
blackroad-cli
blackroad-container
blackroad-continuity-api
blackroad-crm
blackroad-crm-autotagging
blackroad-d1-api
blackroad-deploy-dispatcher
blackroad-dns-manager
blackroad-do-manager
blackroad-domain-router
blackroad-edge-gateway
blackroad-gateway
blackroad-gateway-billing
blackroad-gateway-v2
blackroad-github-deploy
blackroad-helper
blackroad-identity
blackroad-intercept
blackroad-io
blackroad-io-production
blackroad-kv-manager
blackroad-landing-worker
blackroad-live-hub
blackroad-logs
blackroad-mesh
blackroad-messaging-backend
blackroad-network-router
blackroad-operator
blackroad-os-core
blackroad-os-docs
blackroad-os-infra
blackroad-os-legal-cloudflare-worker-project
blackroad-os-operator-cloudflare-worker-project
blackroad-operator-cloudflare-worker-project
blackroad-payment-gateway
blackroad-prism-console
blackroad-prism-console-test
blackroad-quantum-memory
blackroad-ratelimit
blackroad-router
blackroad-salesforce-webhook
blackroad-sandbox
blackroad-sovereignty
blackroad-status
blackroad-stripe-billing
blackroad-stripe-checkout
blackroad-stripe-webhooks
blackroad-subdomain-router
blackroad-telemetry
blackroad-tools
blackroad-watcher
blackroad-webhooks
blackroadai-router
blackroadquantum-router
blackroad-systems-router
cece
chanfana-openapi-template
containers-template
fragrant-lake-ef96
hello-ai
java-blackroad
lucidia
lucidia-core
lucidia-earth-router
lucidia-evolution
lucidia-platform
lucidia-studio-router
orange-dream-ac28
patient-sun-0807
proud-cake-3a70
remotejobs-platform
test
```
