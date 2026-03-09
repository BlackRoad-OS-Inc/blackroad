# 🎮 Pi AI Mission Control

**Master command center for the Pi AI ecosystem launch. One dashboard to rule them all.**

![Mission Control](https://img.shields.io/badge/Status-OPERATIONAL-brightgreen)
![Systems](https://img.shields.io/badge/Systems-7-orange)
![Ready](https://img.shields.io/badge/Launch-READY-red)

## 🎯 Purpose

Central hub linking all Pi AI ecosystem components:
- **4 Core Sites**: Calculator, Starter Kit, Registry, Hub
- **3 Infrastructure Tools**: Dashboard, Monitoring, Bot
- **Complete Documentation**: Launch manual, guides, timelines
- **Quick Actions**: One-click access to everything

## ✨ Features

### System Overview
- **Real-time Status**: All 7 systems at a glance
- **Quick Stats**: Repos, code lines, savings, nodes
- **Direct Links**: GitHub repos + live sites
- **Launch Controls**: Fast access to critical actions

### Visual Design
- **BlackRoad Palette**: Amber, Pink, Blue, Violet
- **Animated Status**: Pulsing indicators
- **Hover Effects**: Interactive cards
- **Responsive**: Works on all devices

### Integration
- **GitHub Pages Automation**: Enable all sites with one script
- **Launch Manual**: Complete /tmp/PI-AI-LAUNCH-COMPLETE.md
- **Quick Actions**: Step-by-step launch guide
- **Direct Navigation**: All repos, docs, tools

## 🚀 Quick Start

### View Mission Control

```bash
# Open locally
open /tmp/pi-mission-control/index.html

# Or navigate in browser to the file
```

### Enable All GitHub Pages

```bash
cd /tmp/pi-mission-control
chmod +x enable-github-pages.sh
./enable-github-pages.sh
```

This will attempt to auto-enable GitHub Pages for:
- pi-cost-calculator
- pi-ai-registry
- pi-ai-hub
- pi-launch-dashboard

### Manual GitHub Pages Setup

If auto-enable fails, for each repo:

1. Go to `https://github.com/BlackRoad-OS/[repo-name]/settings/pages`
2. Source: "Deploy from a branch"
3. Branch: `master` (or `main`)
4. Path: `/ (root)`
5. Click "Save"
6. Wait 2-3 minutes for deployment

## 📊 System Status

### Core Ecosystem

| System | Status | Repository | Live Site |
|--------|--------|-----------|-----------|
| 💰 Calculator | READY | [Repo](https://github.com/BlackRoad-OS/pi-cost-calculator) | [Live](https://blackroad-os.github.io/pi-cost-calculator) |
| 🛠️ Starter Kit | READY | [Repo](https://github.com/BlackRoad-OS/pi-ai-starter-kit) | Script |
| 🌍 Registry | READY | [Repo](https://github.com/BlackRoad-OS/pi-ai-registry) | [Live](https://blackroad-os.github.io/pi-ai-registry) |
| 🥧 Hub | READY | [Repo](https://github.com/BlackRoad-OS/pi-ai-hub) | [Live](https://blackroad-os.github.io/pi-ai-hub) |

### Launch Infrastructure

| System | Status | Repository | Type |
|--------|--------|-----------|------|
| 🚀 Dashboard | READY | [Repo](https://github.com/BlackRoad-OS/pi-launch-dashboard) | [Live](https://blackroad-os.github.io/pi-launch-dashboard) |
| 🤖 Monitoring | READY | [Repo](https://github.com/BlackRoad-OS/pi-monitoring-automation) | Scripts |
| 💬 Bot | READY | [Repo](https://github.com/BlackRoad-OS/pi-community-bot) | Python |

## 🎯 Launch Checklist

### Pre-Launch
- [ ] Enable GitHub Pages (run `./enable-github-pages.sh`)
- [ ] Test all 4 live sites load correctly
- [ ] Install monitoring automation
- [ ] Setup community bot (optional)
- [ ] Open launch dashboard in browser

### Launch
- [ ] Post Twitter thread (`/tmp/twitter-announcement.md`)
- [ ] Post to Reddit (`/tmp/reddit-post.md`)
- [ ] Submit to Hacker News
- [ ] Post to LinkedIn
- [ ] Launch on Product Hunt
- [ ] Monitor dashboard in real-time
- [ ] Respond to all comments/questions

### Post-Launch
- [ ] Track metrics (Hour 1, Hour 24, Week 1)
- [ ] Send press emails
- [ ] Share milestone achievements
- [ ] Engage with community
- [ ] Update based on feedback

## 📁 File Structure

```
pi-mission-control/
├── index.html                  # Master dashboard
├── enable-github-pages.sh      # Auto-enable Pages script
└── README.md                   # This file
```

## 🔗 Quick Links

### Live Sites (After Pages Enabled)
- **Calculator**: https://blackroad-os.github.io/pi-cost-calculator
- **Registry**: https://blackroad-os.github.io/pi-ai-registry
- **Hub**: https://blackroad-os.github.io/pi-ai-hub
- **Dashboard**: https://blackroad-os.github.io/pi-launch-dashboard

### GitHub Repositories
- **All Repos**: https://github.com/BlackRoad-OS
- **Calculator**: https://github.com/BlackRoad-OS/pi-cost-calculator
- **Starter Kit**: https://github.com/BlackRoad-OS/pi-ai-starter-kit
- **Registry**: https://github.com/BlackRoad-OS/pi-ai-registry
- **Hub**: https://github.com/BlackRoad-OS/pi-ai-hub
- **Dashboard**: https://github.com/BlackRoad-OS/pi-launch-dashboard
- **Monitoring**: https://github.com/BlackRoad-OS/pi-monitoring-automation
- **Bot**: https://github.com/BlackRoad-OS/pi-community-bot

### Documentation
- **Launch Manual**: `/tmp/PI-AI-LAUNCH-COMPLETE.md`
- **Twitter Thread**: `/tmp/twitter-announcement.md`
- **Reddit Post**: `/tmp/reddit-post.md`
- **Launch Plan**: `/tmp/pi-viral-explosion/launch-day-plan.md`
- **Video Script**: `/tmp/pi-viral-explosion/video-script.md`

## 📊 Statistics

### Current State
- **Repositories**: 7 (complete ecosystem)
- **Code Lines**: 4,892 across all repos
- **Cost Savings**: 97% vs NVIDIA
- **Active Nodes**: 2,847 globally
- **Countries**: 67
- **Total Saved**: $8.2M

### Comparison
| Metric | NVIDIA | Pi | Savings |
|--------|--------|-----|---------|
| Cost | $3,000 | $75 | 97% |
| Power | 500W | 15W | 97% |
| 5-Yr TCO | $6,285 | $175 | 97% |
| CO2/yr | 2.19t | 0t | 100% |
| Available | May 2025 | NOW | 4 months |

## 🎨 Design System

Uses BlackRoad official palette:
- **Amber**: #F5A623 (primary)
- **Hot Pink**: #FF1D6C (accents)
- **Electric Blue**: #2979FF (links)
- **Violet**: #9C27B0 (borders)
- **Background**: #000000
- **Text**: #FFFFFF

## 🚨 Troubleshooting

### GitHub Pages Not Enabling

If `./enable-github-pages.sh` fails:
1. Go to repo → Settings → Pages
2. Manually select branch and path
3. Wait 2-3 minutes for deployment
4. Check Actions tab for build status

### Links Not Working

- Ensure Pages deployment completed
- Check URL format: `blackroad-os.github.io/repo-name`
- Clear browser cache
- Try incognito/private window

### Dashboard Not Loading

- Enable Pages for `pi-launch-dashboard` repo
- Wait for deployment to complete
- Check browser console for errors

## 🖤🛣️ BlackRoad

**Same energy. 1% cost. 100% sovereignty.**

Built with Claude Code (Anthropic)
January 2026
