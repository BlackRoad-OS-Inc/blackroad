# 🤖 Pi AI Monitoring Automation

**Automated monitoring system for tracking Pi AI ecosystem metrics across all platforms.**

![Auto-Monitor](https://img.shields.io/badge/Monitoring-Automated-brightgreen)
![Interval](https://img.shields.io/badge/Interval-5min-blue)
![Platforms](https://img.shields.io/badge/Platforms-Multiple-orange)

## 🎯 Purpose

Automatically track and report on:
- **GitHub**: Stars, forks, watchers (5 repos)
- **Milestones**: Automatic notifications when goals are hit
- **Trends**: Historical data tracking
- **Alerts**: Discord/Slack notifications

## ✨ Features

### Automated Tracking
- **Cron Job**: Runs every 5 minutes locally
- **GitHub Actions**: Runs every 15 minutes in CI
- **State Persistence**: Tracks changes over time
- **JSON Export**: Machine-readable stats

### Milestone Notifications
- **10 stars**: First milestone 🎯
- **50 stars**: Growing momentum ✨
- **100 stars**: Major milestone 🎉
- **500 stars**: Viral success 🚀
- **1000+ stars**: Legendary status 🏆

### Integration
- **Discord Webhooks**: Real-time notifications
- **Slack Webhooks**: Team alerts
- **JSON API**: Export for dashboards
- **Log Files**: Historical tracking

## 🚀 Quick Start

### Installation

```bash
# Clone the monitoring repo
git clone https://github.com/BlackRoad-OS/pi-monitoring-automation.git
cd pi-monitoring-automation

# Run setup
chmod +x setup-monitoring.sh
./setup-monitoring.sh

# Test it
~/bin/pi-monitoring/monitor-github.sh
```

### Manual Usage

```bash
# Check stats now
~/bin/pi-monitoring/monitor-github.sh

# View logs
tail -f ~/.pi-monitor.log

# View JSON stats
cat /tmp/pi-github-stats.json | jq
```

### Automated Usage

After running `setup-monitoring.sh`, the system automatically:
1. Checks GitHub every 5 minutes
2. Logs to `~/.pi-monitor.log`
3. Exports JSON to `/tmp/pi-github-stats.json`
4. Sends Discord notifications on milestones

## 🔔 Discord Notifications

### Setup

1. Create webhook in Discord server:
   - Server Settings → Integrations → Webhooks → New Webhook
   - Copy webhook URL

2. Add to your shell profile (`~/.zshrc` or `~/.bashrc`):

```bash
export DISCORD_WEBHOOK_URL='https://discord.com/api/webhooks/...'
```

3. Reload shell:

```bash
source ~/.zshrc  # or source ~/.bashrc
```

### Notification Types

**Repository Milestones:**
```
🎯 pi-cost-calculator reached 50 stars!
```

**Combined Milestones:**
```
🏆 MILESTONE: 1,000+ total stars!
```

**Growth Alerts:**
```
📈 +47 total stars in last hour!
```

## 📊 Stats Export Format

```json
{
  "total_stars": 247,
  "total_forks": 83,
  "total_watchers": 156,
  "total_issues": 12,
  "timestamp": "2026-01-10T18:30:00Z",
  "repos": {
    "BlackRoad-OS/pi-cost-calculator": {
      "stars": 64,
      "forks": 18,
      "watchers": 32
    },
    "BlackRoad-OS/pi-ai-starter-kit": {
      "stars": 89,
      "forks": 31,
      "watchers": 54
    },
    "BlackRoad-OS/pi-ai-registry": {
      "stars": 43,
      "forks": 12,
      "watchers": 28
    },
    "BlackRoad-OS/pi-ai-hub": {
      "stars": 38,
      "forks": 15,
      "watchers": 31
    },
    "BlackRoad-OS/pi-launch-dashboard": {
      "stars": 13,
      "forks": 7,
      "watchers": 11
    }
  }
}
```

## 🔄 GitHub Actions

The included workflow runs automatically:

- **Schedule**: Every 15 minutes
- **Manual**: Via Actions tab → "Run workflow"
- **Commits**: Auto-commits stats to `stats/` directory
- **Artifacts**: Uploads JSON for 30 days

### Secrets Required

Add to repository secrets (Settings → Secrets):
- `GITHUB_TOKEN`: Auto-provided by GitHub
- `DISCORD_WEBHOOK_URL`: Your Discord webhook (optional)

## 📈 Dashboard Integration

The monitoring system exports data that the launch dashboard can use:

```javascript
// In launch dashboard
async function updateFromMonitoring() {
    const response = await fetch('/tmp/pi-github-stats.json');
    const stats = await response.json();

    updateTwitter(stats.twitter?.impressions || 0);
    updateReddit(stats.reddit?.upvotes || 0);
    updateHN(stats.hn?.points || 0);

    // Auto-update GitHub totals
    document.getElementById('github-stars-24').textContent =
        stats.total_stars.toLocaleString();
}

setInterval(updateFromMonitoring, 30000);  // Every 30s
```

## 🛠️ Customization

### Change Monitoring Interval

Edit cron job:
```bash
crontab -e

# Change from every 5 minutes to every 10:
*/10 * * * * ~/bin/pi-monitoring/monitor-github.sh >> ~/.pi-monitor.log 2>&1
```

### Add More Repos

Edit `monitor-github.sh`:
```bash
REPOS=(
    "BlackRoad-OS/pi-cost-calculator"
    "BlackRoad-OS/pi-ai-starter-kit"
    "BlackRoad-OS/pi-ai-registry"
    "BlackRoad-OS/pi-ai-hub"
    "BlackRoad-OS/pi-launch-dashboard"
    "YourOrg/your-new-repo"  # Add here
)
```

### Custom Milestones

Edit notification thresholds in `monitor-github.sh`:
```bash
if [ $stars -ge 250 ] && [ $prev_stars -lt 250 ]; then
    send_notification "🎊 $repo_name reached 250 stars!"
fi
```

## 📁 File Structure

```
pi-monitoring-automation/
├── README.md                    # This file
├── monitor-github.sh            # Main monitoring script
├── setup-monitoring.sh          # Installation script
├── .github/
│   └── workflows/
│       └── monitor.yml          # GitHub Actions workflow
└── stats/                       # Auto-generated (via Actions)
    ├── latest.json              # Most recent stats
    └── stats-*.json             # Historical snapshots
```

## 🔍 Monitoring Checklist

- [ ] Install monitoring scripts (`setup-monitoring.sh`)
- [ ] Verify cron job installed (`crontab -l`)
- [ ] Test manual run (`~/bin/pi-monitoring/monitor-github.sh`)
- [ ] Configure Discord webhook (optional)
- [ ] Enable GitHub Actions workflow
- [ ] Check logs regularly (`tail -f ~/.pi-monitor.log`)
- [ ] Monitor milestone notifications

## 🎯 Launch Day Usage

1. **Before Launch**: Run `setup-monitoring.sh`
2. **During Launch**: Monitor in real-time:
   ```bash
   watch -n 30 ~/bin/pi-monitoring/monitor-github.sh
   ```
3. **Post-Launch**: Review logs and historical data:
   ```bash
   cat ~/.pi-monitor.log | grep "MILESTONE"
   ```

## 📊 Stats Analysis

### View Growth Over Time

```bash
# See all stats files
ls -lh stats/

# Compare first vs latest
diff <(jq . stats/stats-20260110-*.json | head -1) <(jq . stats/latest.json)

# Calculate total growth
jq -r '.total_stars' stats/latest.json
```

### Generate Report

```bash
# Stars per repo
jq -r '.repos | to_entries[] | "\(.key): \(.value.stars) stars"' /tmp/pi-github-stats.json

# Total engagement
jq -r '"Total: \(.total_stars) stars, \(.total_forks) forks, \(.total_watchers) watchers"' /tmp/pi-github-stats.json
```

## 🚨 Troubleshooting

### Cron Job Not Running

```bash
# Check cron status
crontab -l

# Check logs
tail -f ~/.pi-monitor.log

# Run manually to debug
~/bin/pi-monitoring/monitor-github.sh
```

### GitHub API Rate Limits

- **Unauthenticated**: 60 requests/hour
- **Authenticated** (via `gh`): 5,000 requests/hour
- Ensure `gh auth login` is configured

### Discord Notifications Not Working

```bash
# Test webhook manually
curl -X POST "$DISCORD_WEBHOOK_URL" \
    -H "Content-Type: application/json" \
    -d '{"content": "Test from Pi Monitor"}'

# Verify env var is set
echo $DISCORD_WEBHOOK_URL
```

## 🔗 Related Projects

- [Pi Launch Dashboard](https://github.com/BlackRoad-OS/pi-launch-dashboard) - Real-time launch tracking
- [Pi Cost Calculator](https://github.com/BlackRoad-OS/pi-cost-calculator) - Savings calculator
- [Pi AI Starter Kit](https://github.com/BlackRoad-OS/pi-ai-starter-kit) - Installation kit
- [Pi AI Registry](https://github.com/BlackRoad-OS/pi-ai-registry) - Global directory
- [Pi AI Hub](https://github.com/BlackRoad-OS/pi-ai-hub) - Landing page

## 🖤🛣️ BlackRoad

**Same energy. 1% cost. 100% sovereignty.**

Built with Claude Code (Anthropic)
January 2026
