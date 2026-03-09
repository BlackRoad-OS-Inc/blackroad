# BlackRoad OS Hub

**Meta-CRM Platform** - A CRM that manages CRMs.

## The $330/Month Enterprise Backend

> **See [ARCHITECTURE_BREAKTHROUGH.md](./ARCHITECTURE_BREAKTHROUGH.md) for the full story.**

Salesforce thinks they're selling CRM seats. We're buying enterprise backend infrastructure.

```
30,000,000,000 users
        ↓
   BlackRoad UI / API (Cloudflare edge)
        ↓
   1,000+ agents (on Pi cluster: 78 TOPS)
        ↓
   Salesforce API (1 seat @ $330/mo)
        ↓
   Unlimited records, automation, Einstein AI
```

**Their pricing model cannot comprehend agent swarms.**

## Full Stack Architecture

```
┌──────────────────────────────────────────────────────────────────────────┐
│                         30,000,000,000 USERS                             │
│                    (apps, web, IoT devices you sell)                     │
└────────────────────────────────────┬─────────────────────────────────────┘
                                     ↓
┌────────────────────────────────────┴─────────────────────────────────────┐
│                            CLOUDFLARE                                    │
│         19 domains, DNS, CDN, DDoS protection, Workers, edge cache       │
└────────────────────────────────────┬─────────────────────────────────────┘
                                     ↓
┌────────────────────────────────────┴─────────────────────────────────────┐
│                         SHELLFISH (Digital Ocean)                        │
│                    Public-facing API gateway / ingress                   │
└────────────────────────────────────┬─────────────────────────────────────┘
                                     ↓
┌────────────────────────────────────┴─────────────────────────────────────┐
│                         TAILSCALE MESH                                   │
│              Encrypted private network connecting everything             │
└────────────────────────────────────┬─────────────────────────────────────┘
                                     ↓
┌────────────────────────────────────┴─────────────────────────────────────┐
│                        LOCAL PI CLUSTER                                  │
│                                                                          │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐    │
│  │   LUCIDIA    │ │    ARIA      │ │   OCTAVIA    │ │    ALICE     │    │
│  │    Pi 5      │ │    Pi 5      │ │    Pi 5      │ │   Pi 400     │    │
│  │  Hailo-8     │ │  Hailo-8     │ │              │ │              │    │
│  │  26 TOPS     │ │  26 TOPS     │ │              │ │              │    │
│  └──────────────┘ └──────────────┘ └──────────────┘ └──────────────┘    │
│                     + Jetson Orin Nano + more Pis                        │
│                          78 TOPS AI inference                            │
└────────────────────────────────────┬─────────────────────────────────────┘
                                     ↓
┌────────────────────────────────────┴─────────────────────────────────────┐
│                      BACKEND SERVICES                                    │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐        │
│  │ SALESFORCE  │ │   GITHUB    │ │  ROADCHAIN  │ │    OTHER    │        │
│  │  1 seat     │ │ 15 orgs     │ │ blockchain  │ │   APIs      │        │
│  │  $330/mo    │ │ enterprise  │ │ audit trail │ │             │        │
│  └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘        │
└──────────────────────────────────────────────────────────────────────────┘
```

## The Math

| Traditional Model | BlackRoad Model |
|-------------------|-----------------|
| 1 user = $330/mo | 30B users = $330/mo |
| Human clicking buttons | Agents calling APIs |
| Scale seats with users | Scale hardware, not seats |
| $3.96M/year for 1000 users | $3,960/year for unlimited |

**Total infrastructure for "unlimited" scale: ~$500-800/month**

---

## Hub Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    BLACKROAD OS HUB                             │
│                (Salesforce - Master Control)                    │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐             │
│  │ Connected   │  │ Connected   │  │ Connected   │             │
│  │ CRM #1      │  │ CRM #2      │  │ CRM #3      │             │
│  │ (FA CRM)    │  │ (Agency)    │  │ (Client X)  │             │
│  └─────────────┘  └─────────────┘  └─────────────┘             │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │              UNIFIED DATA LAYER                          │   │
│  │   • Cross-CRM Search    • Sync Status                   │   │
│  │   • Audit Logs          • Health Monitoring             │   │
│  │   • Template Library    • Workflow Engine               │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

## Custom Objects

### Hub Layer
| Object | Description |
|--------|-------------|
| `Connected_CRM__c` | Connected CRM instances managed by the hub |
| `CRM_Product__c` | CRM product templates (Financial Advisor CRM, etc.) |

### Financial Advisor CRM
| Object | Description |
|--------|-------------|
| `Client_Household__c` | Unified household view |
| `Financial_Account__c` | Individual financial accounts (IRA, brokerage, etc.) |
| `Distribution_Request__c` | Distribution/withdrawal workflows |
| `Mortality_Event__c` | Death/estate processing |
| `Liquidity_Event__c` | Business sales, large transfers |
| `Compliance_Log__c` | FINRA-compliant audit trail |

## Reports & Dashboard

Custom Report Types deployed:
- `Client_Households` - for household reporting
- `Distribution_Requests` - for distribution workflows
- `Mortality_Events` - for estate processing
- `Compliance_Logs` - for audit trails

## Apex Classes

| Class | Description |
|-------|-------------|
| `BlackRoadHubController` | Hub dashboard controller |
| `FinancialAdvisorService` | FA CRM business logic |

## Lightning Components

| Component | Description |
|-----------|-------------|
| `blackroadHubDashboard` | Main hub command center |

## Deployment

```bash
# Authenticate to your org
sf org login web --alias blackroad-hub

# Deploy
sf project deploy start --target-org blackroad-hub

# Assign permission set
sf org assign permset --name BlackRoad_Hub_Admin --target-org blackroad-hub
```

## Target Org

- **Org:** securianfinancial-4e-dev-ed
- **URL:** https://securianfinancial-4e-dev-ed.develop.my.salesforce.com

## OAuth Credentials

Stored in Cloudflare Worker secrets:
- `SALESFORCE_CONSUMER_KEY`
- `SALESFORCE_CONSUMER_SECRET`

---

**BlackRoad OS** | Building compliance-first automation for regulated industries

*$330/month. Unlimited scale. The future of SaaS arbitrage.*
