# Slack Compliance Alerts - Setup Guide

**BlackRoad OS, Inc. - Automated Compliance Deadline Notifications**

## Overview

The Compliance Slack Alert System sends automatic notifications for:
- **🔴 URGENT deadlines** (crypto custody migration, regulatory filings)
- **⚠️ Upcoming deadlines** (within 7-30 days)
- **📋 Daily compliance summaries**
- **🚨 Critical compliance violations**

---

## Quick Start (5 Minutes)

### Step 1: Create Slack Incoming Webhook

1. Go to: https://api.slack.com/apps
2. Click **"Create New App"** → **"From scratch"**
3. **App Name:** `BlackRoad Compliance Alerts`
4. **Workspace:** Select your Slack workspace
5. Click **"Create App"**

### Step 2: Enable Incoming Webhooks

1. In left sidebar, click **"Incoming Webhooks"**
2. Toggle **"Activate Incoming Webhooks"** to **ON**
3. Scroll down and click **"Add New Webhook to Workspace"**
4. Select channel: **#compliance** (or create a new #compliance-alerts channel)
5. Click **"Allow"**
6. **Copy the Webhook URL** (starts with `https://hooks.slack.com/services/...`)

### Step 3: Configure Compliance Alert System

```bash
cd /tmp/compliance-blackroadio
./scripts/compliance-slack-alerts.sh setup
```

When prompted, paste the Webhook URL you copied in Step 2.

### Step 4: Test the System

```bash
./scripts/compliance-slack-alerts.sh test
```

You should see a test message appear in your Slack channel!

---

## Features

### 1. URGENT Crypto Custody Deadline Alert

**Automatically sent when:**
- Crypto custody migration deadline is within 30 days
- Deadline: **February 4, 2026** (30 days from January 4, 2026)

**Alert includes:**
- Days remaining until deadline
- Current non-compliant holdings (ETH 2.5, SOL 100, BTC 0.1)
- Required actions (select custodian, transfer assets)
- Link to migration plan
- CCO contact information

**Example Alert:**
```
🔴 CRITICAL COMPLIANCE DEADLINE: Crypto Custody Migration

Deadline: February 4, 2026 (28 days remaining)

Issue: Current crypto holdings in consumer wallets violate SEC Custody Rule:
  • ETH: 2.5 (MetaMask) ❌ NON-COMPLIANT
  • SOL: 100 (Phantom) ❌ NON-COMPLIANT
  • BTC: 0.1 (Coinbase) ⚠️ VERIFY STATUS

Required Action:
  1. Select qualified custodian (Coinbase Custody recommended)
  2. Complete onboarding application
  3. Transfer assets from consumer wallets
  4. Verify custody with audit trail

Migration Plan: /tmp/compliance-blackroadio/docs/CRYPTO_CUSTODY_MIGRATION_PLAN.md
Contact CCO: Alexa Amundson - blackroad.systems@gmail.com
```

### 2. Repository Compliance Warnings

**Automatically sent for:**
- 99 out of 100 repos missing SECURITY.md, LICENSE, CODEOWNERS
- Actionable remediation steps included

**Example Alert:**
```
⚠️ Repository Compliance Issue

Status: 99 out of 100 repositories missing compliance files
Missing: SECURITY.md, LICENSE, CODEOWNERS
Impact: Regulatory vulnerability, lack of security disclosure process

Action Required:
  Run deployment script: `DRY_RUN=false /tmp/compliance-blackroadio/scripts/deploy-compliance-files.sh`

Estimated Time: 30 minutes (automated deployment to all repos)
```

### 3. Daily Compliance Summary

**Sent every morning at 9 AM (if configured in cron)**

**Example Summary:**
```
📋 Daily Compliance Summary - 2026-01-04

5 Core Policies: ✅ Complete (3,816 lines)
Repository: github.com/BlackRoad-OS/compliance-blackroadio
Entity: BlackRoad OS, Inc. (Delaware C-Corp)
Principal: Alexa Louise Amundson (CRD# 7794541)

Next Actions:
  1. 🔴 Crypto custody migration (30 days)
  2. ⚠️ Deploy compliance files to 99 repos
  3. 📝 Form ADV filing preparation

Run `~/compliance-monitor.sh report` for full compliance status.
```

### 4. Custom Regulatory Deadlines

**Automatically monitors deadlines from compliance database:**
- Form ADV annual amendments (90 days after fiscal year end)
- Code of Ethics distribution (annually)
- AML training completion (annually)
- Independent testing report (annually by March 31)

**Alerts sent:**
- **30 days before:** Warning notification
- **7 days before:** URGENT notification
- **Past deadline:** OVERDUE notification

---

## Usage Commands

### Check Deadlines (Manual)
```bash
cd /tmp/compliance-blackroadio
./scripts/compliance-slack-alerts.sh check
```

### Send Urgent Alert (Manual)
```bash
./scripts/compliance-slack-alerts.sh urgent "SAR filed for suspicious wire transfer - investigate immediately"
```

### Send Test Message
```bash
./scripts/compliance-slack-alerts.sh test
```

### Daily Automated Check
```bash
./scripts/compliance-slack-alerts.sh daily
```

---

## Automated Scheduling (Cron)

### Daily Check at 9 AM

Add to crontab:
```bash
crontab -e
```

Add this line:
```
0 9 * * * /tmp/compliance-blackroadio/scripts/compliance-slack-alerts.sh daily
```

### Hourly Check (for URGENT deadlines)

For more frequent monitoring during critical periods:
```
0 * * * * /tmp/compliance-blackroadio/scripts/compliance-slack-alerts.sh check
```

### Weekly Summary (Monday 9 AM)

```
0 9 * * 1 /tmp/compliance-blackroadio/scripts/compliance-slack-alerts.sh daily
```

---

## Alert Severity Levels

| Color | Severity | When Sent | Example |
|-------|----------|-----------|---------|
| 🔴 Red (Danger) | CRITICAL | Deadline ≤ 7 days or overdue | Crypto custody migration |
| 🟡 Yellow (Warning) | WARNING | Deadline 8-30 days | Form ADV amendment due |
| 🟢 Green (Good) | INFO | Daily summaries, confirmations | Policy creation complete |

---

## Adding Custom Deadlines

Use the compliance monitor to add regulatory deadlines:

```bash
~/compliance-monitor.sh add-deadline "2026-03-31" "SEC" "Form ADV annual amendment" "Alexa Amundson"
```

The Slack alert system will automatically notify you:
- 30 days before (warning)
- 7 days before (urgent)
- On deadline day (critical)

---

## Customizing Alerts

### Change Channel

To send alerts to a different channel:
1. Create new Incoming Webhook for that channel
2. Run: `./scripts/compliance-slack-alerts.sh setup`
3. Enter new webhook URL

### Multiple Channels

Create separate webhook URLs and modify the script to send to multiple channels:

```bash
# In compliance-slack-alerts.sh, add:
SLACK_CRITICAL_WEBHOOK="https://hooks.slack.com/services/XXX"  # #critical-alerts
SLACK_INFO_WEBHOOK="https://hooks.slack.com/services/YYY"      # #compliance-info
```

### Customize Messages

Edit message templates in `/tmp/compliance-blackroadio/scripts/compliance-slack-alerts.sh`:
- Search for `send_slack_message` function
- Modify the JSON payload as needed

---

## Integration with Memory System

All critical alerts are logged to [MEMORY] for agent collaboration:

```bash
~/memory-system.sh log urgent "compliance-crypto-deadline" \
    "URGENT: Crypto custody migration deadline in 28 days. MetaMask/Phantom wallets non-compliant with SEC Custody Rule." \
    "devereux-compliance"
```

Other Claude agents can see these alerts and take action if you lose continuity.

---

## Monitoring Slack Alert System

### Check Configuration
```bash
cat ~/.compliance-slack-config
```

### View Recent Alerts (Slack)
Go to your #compliance channel and filter by:
- `from:@BlackRoad Compliance Alerts`

### Test Webhook Manually
```bash
curl -X POST -H 'Content-type: application/json' \
    --data '{"text":"Test from command line"}' \
    YOUR_WEBHOOK_URL
```

---

## Troubleshooting

### Error: "Slack webhook not configured"
**Solution:** Run `./scripts/compliance-slack-alerts.sh setup` first

### Error: "Invalid webhook URL format"
**Solution:** Ensure URL starts with `https://hooks.slack.com/services/`

### No alerts appearing in Slack
**Solution:**
1. Check webhook URL is correct: `cat ~/.compliance-slack-config`
2. Test webhook: `./scripts/compliance-slack-alerts.sh test`
3. Verify channel permissions (bot must be invited to private channels)

### Cron job not running
**Solution:**
1. Check crontab: `crontab -l`
2. Check cron logs: `tail -f /var/log/cron` (Linux) or `log stream --predicate 'process == "cron"'` (macOS)
3. Ensure script path is absolute in crontab

---

## Security Considerations

### Webhook URL Protection
- Webhook URL stored in `~/.compliance-slack-config` with permissions `600` (owner read/write only)
- **NEVER commit webhook URL to Git**
- Rotate webhook URL if compromised (revoke in Slack, create new one)

### Sensitive Information
- SAR filings: **DO NOT send SAR details via Slack** (tipping off prohibited)
- Customer information: Alerts contain NO customer PII
- Only send compliance deadline reminders and policy status

### Compliance-Safe Alerts
The system is designed to:
- ✅ Notify about deadlines without revealing customer details
- ✅ Send policy completion status
- ✅ Alert about system compliance issues (missing repo files)
- ❌ Never reveal SAR filing details
- ❌ Never mention specific customer names or transactions

---

## Next Steps

1. **Setup Slack webhook** (5 minutes)
2. **Test the system** with `./scripts/compliance-slack-alerts.sh test`
3. **Add to cron** for daily automated checks
4. **Monitor #compliance channel** for critical alerts
5. **Add custom deadlines** via `~/compliance-monitor.sh add-deadline`

---

**Questions?**
Contact: Alexa Amundson (CCO)
Email: blackroad.systems@gmail.com

---

**Document Version:** 1.0
**Last Updated:** January 4, 2026
**Repository:** github.com/BlackRoad-OS/compliance-blackroadio
