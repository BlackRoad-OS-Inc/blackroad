# Stripe Integration — BlackRoad OS

> Account: `acct_1S70Zn3e5FMFdlFw` | Display: **BlackRoad**
> Dashboard: https://dashboard.stripe.com/acct_1S70Zn3e5FMFdlFw/apikeys

## Core Plans — Payment Links (LIVE)

| Plan | Price | Payment Link |
|------|-------|-------------|
| **Rider** | $29/mo | https://buy.stripe.com/aFadR27Je7tP0m78Mk4Vy0p |
| **Paver** | $99/mo | https://buy.stripe.com/cNi8wI3sY15rgl5aUs4Vy0q |
| **Enterprise** | $299/mo | https://buy.stripe.com/cNidR25B67tP3yj9Qo4Vy0r |

## Product Payment Links

| Product | Price | Payment Link |
|---------|-------|-------------|
| **Lucidia Creator** | $29/mo | https://buy.stripe.com/28E9AM3sYcO91qb4w44Vy0s |
| **RoadWork Tutoring** | $19/mo | https://buy.stripe.com/3cI9AM8Ni8xTgl5e6E4Vy0t |
| **RoadSearch** | $5/mo | https://buy.stripe.com/dRm5kw0gM7tP8SD8Mk4Vy0u |

## All Stripe Products (18 total)

### Core Plans (NEW)
| Product | ID | Price/mo |
|---------|-----|---------|
| Rider Plan | prod_UBwNBW5pQzO7CF | $29 |
| Paver Plan | prod_UBwNsYA5u8DBMR | $99 |
| Enterprise Plan | prod_UBwNXTiGk2STvJ | $299 |

### Vertical Products (NEW)
| Product | ID | Price/mo |
|---------|-----|---------|
| Lucidia Creator | prod_UBwN75PBFesOya | $29 |
| RoadWork Tutoring | prod_UBwNl5jAGpgZcM | $19 |
| RoadCoin Payments | prod_UBwNWRI1xMQCd7 | TBD |
| BlackBox Dev Tools | prod_UBwNubbP8nUN0d | TBD |
| RoadSearch | prod_UBwNZpx7sYZXsk | $5 |

### Org Products (EXISTING)
| Product | ID | Price/mo | Price/yr |
|---------|-----|---------|---------|
| RoadChain Blockchain | prod_UBw8N2aCsZx5rj | $99 | $990 |
| Archive Vault | prod_UBw8HsLIGLeFLE | $15 | $150 |
| Labs Sandbox | prod_UBw8QILFiVXR6V | $29 | $290 |
| Ventures Toolkit | prod_UBw8lEVWLYqRl5 | $49 | $490 |
| Foundation Research | prod_UBw8M4N23MJ1ys | $9 | $90 |
| Gov Compliance | prod_UBw8yDw6vIzFhg | — | — |
| Media RoadCast | prod_UBw88UbcaEuTRG | — | — |
| Interactive RoadWorld | prod_UBw8Z6hw2vNpcz | — | — |
| Security RoadGuard | prod_UBw8tpyszftJqp | — | — |
| Cloud RoadHost | prod_UBw71r8M7E0Sft | — | — |

## Integration Points
- **blackroad-stripe** CF Worker — webhook handler
- **RoadPay** (`roadpay` repo) — billing system
- **pay.blackroad.io** — checkout flow
- Secrets: `STRIPE_API_KEY`, `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET` in CF Worker env

---
*BlackRoad OS, Inc. — PROPRIETARY.*
