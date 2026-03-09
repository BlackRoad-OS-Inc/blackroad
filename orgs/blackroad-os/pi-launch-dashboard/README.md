# 🚀 Pi AI Launch Dashboard

**Real-time analytics dashboard for tracking the Pi AI ecosystem launch across all platforms.**

![Dashboard](https://img.shields.io/badge/Status-LIVE-brightgreen)
![Auto-Refresh](https://img.shields.io/badge/Refresh-30s-blue)
![Platforms](https://img.shields.io/badge/Platforms-7-orange)

## 🎯 Purpose

Track every metric during the coordinated multi-platform launch:
- **Twitter** impressions & engagement
- **Reddit** upvotes across subreddits
- **Hacker News** points & comments
- **GitHub** stars, forks, watchers (4 repos)
- **Calculator** usage statistics
- **Registry** new node registrations
- **Media** mentions & coverage

## ✨ Features

### Real-Time Tracking
- **Auto-refresh**: GitHub stats via API every 30 seconds
- **Live activity feed**: See changes as they happen
- **Progress bars**: Visual goal tracking for Hour 1 & Hour 24
- **Timeline**: Launch sequence with status indicators

### Manual Updates
Use browser console commands during launch:

```javascript
// Update metrics
updateTwitter(1250)        // Twitter impressions
updateReddit(127)          // Combined Reddit upvotes
updateHN(45)               // Hacker News points
updateCalculator(89)       // Calculator uses
updateNodes(2870)          // Total nodes (2,847 baseline)
updateMedia(3)             // Media mentions

// Update timeline
markTimelineActive('twitter')     // Mark stage as in progress
markTimelineComplete('twitter')   // Mark stage as done
```

### Tracked Goals

**Hour 1 Goals:**
- ✅ 100+ Twitter impressions
- ✅ 50+ Reddit upvotes
- ✅ 10+ HN points
- ✅ 5+ Calculator uses

**Hour 24 Goals:**
- ✅ 10,000+ Twitter impressions
- ✅ 500+ Reddit upvotes
- ✅ 100+ GitHub stars (combined)
- ✅ 10+ new nodes
- ✅ 1+ media mention

**Week 1 Goals:**
- ✅ 100,000+ Twitter impressions
- ✅ 2,000+ Reddit upvotes
- ✅ 1,000+ GitHub stars
- ✅ 500+ Calculator uses
- ✅ 50+ new nodes
- ✅ 5+ media articles

## 🚀 Usage

### During Launch

1. **Open dashboard** in browser (keep it visible)
2. **GitHub stats auto-update** every 30 seconds
3. **Manually update** other metrics via console
4. **Track timeline** as you complete each stage

### Installation

```bash
# Clone the repo
git clone https://github.com/BlackRoad-OS/pi-launch-dashboard.git
cd pi-launch-dashboard

# Open in browser
open index.html

# Or serve locally
python3 -m http.server 8000
# Visit http://localhost:8000
```

### GitHub Pages Deployment

```bash
# Enable GitHub Pages
# Settings → Pages → Source: main branch

# Dashboard will be live at:
# https://blackroad-os.github.io/pi-launch-dashboard
```

## 📊 Metrics Tracked

### Social Media
- **Twitter**: Impressions, engagement, thread performance
- **Reddit**: Upvotes across r/raspberry_pi, r/selfhosted, r/LocalLLaMA
- **Hacker News**: Points, comments, front page status
- **LinkedIn**: Views, reactions, shares
- **Product Hunt**: Upvotes, comments, rank

### Technical
- **GitHub Stars**: Across all 4 repositories
- **GitHub Forks**: Community engagement
- **GitHub Watchers**: Long-term interest
- **Calculator Uses**: Page views/interactions
- **Registry Nodes**: New registrations

### Business
- **Media Mentions**: TechCrunch, The Verge, Ars Technica, etc.
- **Geographic Reach**: Countries with new nodes
- **Cost Savings**: Calculated from new deployments

## 🎨 Design

Built with BlackRoad design system:
- **Amber**: #F5A623 (primary)
- **Hot Pink**: #FF1D6C (accents)
- **Electric Blue**: #2979FF (links)
- **Violet**: #9C27B0 (borders)
- **Background**: #000000
- **Text**: #FFFFFF

## 🔗 Related Projects

- [Pi Cost Calculator](https://github.com/BlackRoad-OS/pi-cost-calculator) - Interactive savings calculator
- [Pi AI Starter Kit](https://github.com/BlackRoad-OS/pi-ai-starter-kit) - One-command installation
- [Pi AI Registry](https://github.com/BlackRoad-OS/pi-ai-registry) - Global node directory
- [Pi AI Hub](https://github.com/BlackRoad-OS/pi-ai-hub) - Master landing page

## 📱 Console Commands Reference

Open browser console (F12) and use these commands:

```javascript
// Metrics
updateTwitter(1000)
updateReddit(50)
updateHN(10)
updateCalculator(5)
updateNodes(2850)
updateMedia(1)

// Timeline
markTimelineActive('twitter')
markTimelineActive('reddit')
markTimelineActive('hn')
markTimelineActive('linkedin')
markTimelineActive('producthunt')
markTimelineActive('blog')

markTimelineComplete('twitter')
markTimelineComplete('reddit')
// etc.
```

## 🎯 Launch Sequence

**T+0:00** - Twitter thread blast
**T+0:15** - Reddit posts
**T+0:30** - Hacker News
**T+1:00** - LinkedIn
**T+2:00** - Product Hunt
**T+4:00** - Dev.to/Hashnode

Dashboard tracks completion in real-time.

## 🛠️ Technical Details

- **Pure HTML/CSS/JS**: No dependencies, no build step
- **GitHub API Integration**: Auto-fetch repo stats
- **Responsive Design**: Works on all devices
- **Real-time Updates**: 30-second refresh cycle
- **Manual Override**: Console commands for other platforms
- **Activity Feed**: Last 20 events visible

## 📈 Success Metrics

The dashboard shows you're winning when:
- All Hour 1 progress bars are green
- Activity feed shows consistent growth
- GitHub stats climbing steadily
- Timeline stages turning green
- Media mentions appearing

## 🖤🛣️ BlackRoad

**Same energy. 1% cost. 100% sovereignty.**

Built with Claude Code (Anthropic)
January 2026
