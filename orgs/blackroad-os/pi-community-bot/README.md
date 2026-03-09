# 🤖 Pi AI Community Bot

**Discord bot for managing the Pi AI ecosystem community. Welcomes members, tracks stats, celebrates milestones, and coordinates the revolution!**

![Discord Bot](https://img.shields.io/badge/Discord-Bot-5865F2)
![Python](https://img.shields.io/badge/Python-3.9+-blue)
![Auto-Monitor](https://img.shields.io/badge/Monitoring-Automated-brightgreen)

## 🎯 Purpose

Manage Pi AI Discord communities with:
- **Auto-welcome** new members with links to resources
- **Real-time stats** from GitHub, registry, calculator
- **Milestone celebrations** when repos hit star goals
- **Quick commands** for common questions
- **Automated monitoring** every 15 minutes

## ✨ Features

### Welcome System
Automatically greets new members with:
- Links to starter kit, calculator, registry
- Quick start guide
- Community guidelines

### Command System
Prefix: `!pi`

- `!pi stats` - Show ecosystem statistics
- `!pi calculator` - Link to cost calculator
- `!pi install` - Installation instructions
- `!pi register` - Join the global registry
- `!pi compare` - NVIDIA vs Pi comparison
- `!pi repos` - List all repositories
- `!pi help` - Show available commands

### Milestone Announcements
Automatically announces when repos hit:
- 🎯 10 stars - First milestone
- ✨ 25 stars - Growing
- 🚀 50 stars - Momentum
- 🎉 100 stars - Major
- 🌟 250 stars - Trending
- 🏆 500 stars - Viral
- 🔥 1,000 stars - Legendary

### Auto-Monitoring
Every 15 minutes:
- Fetches latest GitHub stats
- Updates internal cache
- Checks for new milestones
- Announces achievements

## 🚀 Quick Start

### 1. Create Discord Bot

1. Go to [Discord Developer Portal](https://discord.com/developers/applications)
2. Click "New Application"
3. Give it a name: "Pi AI Bot"
4. Go to "Bot" section
5. Click "Add Bot"
6. Copy the bot token (you'll need this later)

### 2. Invite Bot to Server

Generate invite URL:
```
https://discord.com/api/oauth2/authorize?client_id=YOUR_CLIENT_ID&permissions=8&scope=bot
```

Replace `YOUR_CLIENT_ID` with your bot's client ID from Developer Portal.

Permissions needed:
- Read Messages
- Send Messages
- Embed Links
- Manage Messages
- Read Message History

### 3. Install & Run

```bash
# Clone the repo
git clone https://github.com/BlackRoad-OS/pi-community-bot.git
cd pi-community-bot

# Run setup
chmod +x setup.sh run.sh
./setup.sh

# Edit .env with your bot token
nano .env  # or vim .env

# Run the bot
./run.sh
```

## 📋 Setup Details

### Install Dependencies

```bash
# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install packages
pip install -r requirements.txt
```

### Configure Environment

Create `.env` file:
```bash
DISCORD_BOT_TOKEN=your_discord_bot_token_here
```

### Run Bot

```bash
# Make scripts executable
chmod +x run.sh

# Start bot
./run.sh
```

## 🎨 Discord Server Setup

For best results, create these channels:

### Required Channels
- **#welcome** - Bot sends welcome messages here
- **#announcements** - Milestone announcements
- **#general** - Fallback for announcements

### Recommended Channels
- **#support** - Help & questions
- **#showcase** - Community Pi setups
- **#success-stories** - Real-world deployments
- **#off-topic** - General chat

### Roles (Optional)
- **Pi Pioneer** - Launched first node
- **Pi Champion** - 10+ nodes
- **Pi Master** - 100+ nodes
- **Contributor** - GitHub contributions

## 📊 Commands Reference

### Stats Commands

**!pi stats**
```
Shows real-time statistics:
- GitHub stars across all repos
- Total forks & watchers
- Active nodes (2,847+)
- Countries (67)
- Total savings ($8.2M)
```

**!pi repos**
```
Lists all repositories with star counts:
- Cost Calculator
- Starter Kit
- Registry
- Hub
- Launch Dashboard
- Monitoring Automation
```

### Resource Commands

**!pi calculator**
```
Links to interactive cost calculator
Shows 5-year TCO comparison
```

**!pi install**
```
One-command installation guide
Lists what gets installed
Links to full documentation
```

**!pi register**
```
Links to global registry
Shows success stories
Explains how to add your node
```

### Comparison Commands

**!pi compare**
```
Side-by-side NVIDIA vs Pi:
- Cost ($3,000 vs $75)
- Availability (May 2025 vs NOW)
- Power (500W vs 15W)
- CO2 (2.19 tons vs 0)
- Sovereignty (0% vs 100%)
- 5-Year TCO ($6,285 vs $175)
```

## 🔧 Customization

### Modify Welcome Message

Edit `bot.py`, function `on_member_join()`:

```python
embed = discord.Embed(
    title="🥧 Your Custom Title",
    description=f"Custom welcome for {member.mention}!",
    color=COLOR_AMBER
)
```

### Add New Commands

```python
@bot.command(name='mycommand')
async def my_command(ctx):
    """Command description"""
    embed = discord.Embed(
        title="My Command",
        description="Command content",
        color=COLOR_BLUE
    )
    await ctx.send(embed=embed)
```

### Change Monitoring Interval

Edit `monitor_github` task decorator:

```python
@tasks.loop(minutes=15)  # Change to desired interval
async def monitor_github():
    # ...
```

### Add More Milestones

Edit `check_milestone()`:

```python
milestones = [10, 25, 50, 100, 250, 500, 1000, 2500, 5000]
```

## 🎨 Design System

Uses BlackRoad color palette:

```python
COLOR_AMBER = 0xF5A623   # Primary
COLOR_PINK = 0xFF1D6C    # Accents
COLOR_BLUE = 0x2979FF    # Links
COLOR_VIOLET = 0x9C27B0  # Borders
```

All embeds follow consistent styling:
- Bold titles
- Organized fields
- Footer with tagline
- Branded colors

## 📈 Monitoring & Stats

### GitHub API Integration
- Fetches stats every 15 minutes
- Caches results to reduce API calls
- Rate limit: 5,000 requests/hour (authenticated)

### Tracked Repositories
1. pi-cost-calculator
2. pi-ai-starter-kit
3. pi-ai-registry
4. pi-ai-hub
5. pi-launch-dashboard
6. pi-monitoring-automation

### Cached Data
```python
bot.stats_cache = {
    'BlackRoad-OS/pi-cost-calculator': {
        'stars': 64,
        'forks': 18,
        'watchers': 32
    },
    # ... other repos
}
```

## 🚨 Troubleshooting

### Bot Not Responding

1. Check bot token in `.env`
2. Verify bot has permissions in server
3. Check bot is online in Discord
4. View logs for errors

### Commands Not Working

1. Ensure command prefix is `!pi` (with space)
2. Check bot has "Read Messages" permission
3. Verify channel permissions

### Milestones Not Announcing

1. Create `#announcements` or `#general` channel
2. Give bot "Send Messages" permission
3. Check milestone wasn't already announced

### GitHub Stats Not Updating

1. Verify internet connection
2. Check GitHub API status
3. Review rate limits (5,000/hour)

## 🔐 Security

### Best Practices
- ✅ Keep bot token secret (never commit `.env`)
- ✅ Use minimal required permissions
- ✅ Regularly update dependencies
- ✅ Monitor bot activity logs

### Token Safety
```bash
# Add to .gitignore
echo ".env" >> .gitignore
echo "venv/" >> .gitignore
```

## 🚀 Deployment

### Local Development
```bash
./run.sh
```

### Production (systemd)

Create `/etc/systemd/system/pi-bot.service`:
```ini
[Unit]
Description=Pi AI Community Bot
After=network.target

[Service]
Type=simple
User=your_user
WorkingDirectory=/path/to/pi-community-bot
ExecStart=/path/to/pi-community-bot/run.sh
Restart=always

[Install]
WantedBy=multi-user.target
```

Enable & start:
```bash
sudo systemctl enable pi-bot
sudo systemctl start pi-bot
sudo systemctl status pi-bot
```

### Production (Docker)

Create `Dockerfile`:
```dockerfile
FROM python:3.11-slim

WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt

COPY . .

CMD ["python3", "bot.py"]
```

Run:
```bash
docker build -t pi-community-bot .
docker run -d --env-file .env --name pi-bot pi-community-bot
```

### Railway Deployment

```bash
# Install Railway CLI
npm install -g @railway/cli

# Login
railway login

# Deploy
railway init
railway up
```

Add `DISCORD_BOT_TOKEN` in Railway dashboard.

## 📊 Analytics

### Track Usage
Bot logs to stdout:
```
🚀 Pi AI Bot is ready!
📊 Connected to 3 servers
👥 Serving 1,247 members
✅ Background tasks started
```

### Monitor Commands
Add logging in commands:
```python
@bot.command(name='stats')
async def stats(ctx):
    print(f"📊 Stats command used by {ctx.author} in {ctx.guild}")
    # ... rest of command
```

## 🔗 Related Projects

- [Pi Launch Dashboard](https://github.com/BlackRoad-OS/pi-launch-dashboard) - Real-time analytics
- [Pi Monitoring](https://github.com/BlackRoad-OS/pi-monitoring-automation) - GitHub tracking
- [Pi Cost Calculator](https://github.com/BlackRoad-OS/pi-cost-calculator) - Savings calculator
- [Pi AI Starter Kit](https://github.com/BlackRoad-OS/pi-ai-starter-kit) - Installation
- [Pi AI Registry](https://github.com/BlackRoad-OS/pi-ai-registry) - Global directory
- [Pi AI Hub](https://github.com/BlackRoad-OS/pi-ai-hub) - Landing page

## 🤝 Contributing

Contributions welcome! Ideas:

- [ ] Reddit integration (track upvotes)
- [ ] Twitter integration (track mentions)
- [ ] Hacker News integration (track points)
- [ ] Calculator usage stats
- [ ] Registry node tracking
- [ ] Success story showcases
- [ ] Weekly summaries
- [ ] Leaderboards

## 📝 License

Proprietary - BlackRoad OS, Inc.

For non-commercial use only. See LICENSE file.

## 🖤🛣️ BlackRoad

**Same energy. 1% cost. 100% sovereignty.**

Built with Claude Code (Anthropic)
January 2026

---

Questions? Join the Discord! Commands list with `!pi help`
