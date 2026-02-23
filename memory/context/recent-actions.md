# BlackRoad OS — Session Context
Last updated: 2026-02-23

## Pi Tunnel Status (tunnel: 52915859)
- Host: alice@192.168.4.49, nginx on :80
- **18+/20 domains → 200 OK**
- blackroad.me → 522 (needs CF dashboard: verify CNAME in blackroad.me zone)
- roadcoin.io → 525 (needs CF dashboard: SSL/TLS → set to Flexible)

## Salesforce (blackroad-hub org)
- URL: securianfinancial-4e-dev-ed.develop.my.salesforce.com
- Deployed: AgentTrainingEvent__e, Flows, CaseTrigger, GitHubRepo__c, OrgRegistry__c, StripeRecord__c, agentDashboard LWC
- sf.blackroad.io → Pi tunnel → nginx proxy → SF org

## Agent SSH Fleet
| Node | IP | Tunnel | Status |
|------|----|--------|--------|
| aria | 192.168.4.38 | 93a03772 | up, cert works |
| octavia | ? | 0447556b | up |
| lucidia | ? | b7e9f25e | up |
| alice | 192.168.4.49 | **52915859 (main)** | up, nginx:80 |

## Collaboration DMs sent
- ARIA: verify blackroad.me CNAME
- OCTAVIA: roadcoin.io SSL → Flexible
- ALICE: nginx wildcard vhosts added
- LUCIDIA: SF domain context
