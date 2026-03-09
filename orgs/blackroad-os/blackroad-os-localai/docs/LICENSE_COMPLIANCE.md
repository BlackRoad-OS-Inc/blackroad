# License Compliance Documentation

## Open Source Core
**Component:** LocalAI
**License:** [See upstream LICENSE]
**Source:** https://github.com/[upstream]

### Compliance Requirements
- ✅ Original LICENSE file included
- ✅ Copyright notices preserved
- ✅ Modifications documented
- ✅ Attribution provided

## Proprietary Enhancement Layer
**Component:** BlackRoad Enhancement Layer
**License:** Proprietary
**Owner:** BlackRoad OS, Inc.
**Copyright:** © 2026 BlackRoad OS, Inc.

### What's Proprietary
- ✅ UI/UX layer (ui/)
- ✅ API Gateway (api/)
- ✅ Enterprise integrations
- ✅ Analytics & monitoring
- ✅ Mobile applications
- ✅ Commercial support

### What's Open Source
- ✅ Core application (upstream project)
- ✅ Public APIs (if any)
- ✅ Community contributions (if accepted upstream)

## Architecture Diagram

```
┌─────────────────────────────────────────────┐
│  🖤 BlackRoad Proprietary Layer (Closed)    │
│  • Enterprise UI                            │
│  • API Gateway                              │
│  • Integrations                             │
│  • Analytics                                │
├─────────────────────────────────────────────┤
│  🌐 Open Source Core (Original License)     │
│  • LocalAI                             │
│  • Upstream contributions                   │
│  • Community features                       │
└─────────────────────────────────────────────┘
```

## Legal Separation

The proprietary layer communicates with the open source core ONLY through:
- Standard APIs
- Network protocols
- Configuration files

This ensures clear legal separation and prevents derivative work issues.

## Customer Rights

Customers who purchase BlackRoad enhanced version receive:
- ✅ License to use proprietary layer
- ✅ Commercial support & SLA
- ✅ Access to all features
- ❌ Source code of proprietary layer (closed)
- ✅ Source code of open source core (available upstream)

## Contribution Policy

- Contributions to OPEN SOURCE CORE: Submit upstream
- Contributions to PROPRIETARY LAYER: Internal only
