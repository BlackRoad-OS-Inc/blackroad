# BlackRoad Vault - Quick Start

**Your secrets are now stored in:** https://github.com/BlackRoad-OS/blackroad-os-vault (PRIVATE)

**Local vault:** `~/blackroad-vault/`

---

## 🚀 Quick Setup (5 minutes)

### 1. Add Your API Keys

```bash
cd ~/blackroad-vault/api-keys

# Copy examples to real files
cp anthropic.env.example anthropic.env
cp openai.env.example openai.env
cp huggingface.env.example huggingface.env

# Edit with your real keys
nano anthropic.env
nano openai.env
nano huggingface.env
```

**Where to get API keys:**
- **Anthropic Claude:** https://console.anthropic.com/ → API Keys
- **OpenAI GPT-4:** https://platform.openai.com/api-keys
- **HuggingFace:** https://huggingface.co/settings/tokens

### 2. Deploy to Cloudflare Workers

```bash
cd ~/blackroad-vault
./deploy-secrets.sh
```

This will:
- Load all your API keys from vault
- Deploy them as secrets to Cloudflare Workers
- Enable real AI responses in @blackroad-agents

### 3. Test It Works

```bash
# Test worker endpoint
curl https://blackroad-agents.amundsonalexa.workers.dev

# Test in a real repo
# Go to any BlackRoad-OS repo, create issue, comment:
# @blackroad-agents hello!
```

---

## 📂 Vault Structure

```
~/blackroad-vault/
├── api-keys/
│   ├── anthropic.env          # ← Add your Anthropic key here
│   ├── openai.env              # ← Add your OpenAI key here
│   ├── huggingface.env         # ← Add your HuggingFace key here
│   ├── cloudflare.env          # ← Add Cloudflare tokens here
│   ├── github.env              # ← Add GitHub tokens here
│   └── *.example               # Templates (don't edit these)
│
├── credentials/
│   └── README.md               # Store other credentials
│
├── config/
│   └── (secure configs)
│
├── deploy-secrets.sh           # ← Deploy to Cloudflare
└── VAULT_SETUP.md              # Full documentation
```

---

## 🔒 Security

**What's safe:**
- ✅ `.env.example` files are committed (templates only)
- ✅ `.gitignore` prevents real secrets from being committed
- ✅ Repo is PRIVATE (only you can see it)

**What to NEVER do:**
- ❌ Don't commit `.env` files with real keys
- ❌ Don't make this repo public
- ❌ Don't share API keys in Slack/email

---

## 🛠️ Common Commands

### Add a new API key:
```bash
cd ~/blackroad-vault/api-keys
nano my-service.env
git add my-service.env.example  # Only commit example!
git commit -m "Add my-service template"
git push
```

### Load keys in your scripts:
```bash
source ~/blackroad-vault/api-keys/anthropic.env
echo $ANTHROPIC_API_KEY
```

### Update Cloudflare secrets:
```bash
cd ~/blackroad-vault
./deploy-secrets.sh
```

### Pull latest vault:
```bash
cd ~/blackroad-vault
git pull
```

### Backup vault:
```bash
tar -czf ~/blackroad-vault-backup.tar.gz ~/blackroad-vault
```

---

## 🎯 What's Already Set Up

✅ **Private GitHub repo created**
✅ **Cloned to ~/blackroad-vault**
✅ **Directory structure ready**
✅ **Example files for all services**
✅ **Deployment script ready**
✅ **.gitignore configured**

**What you need to do:**
1. Add your real API keys to the `.env` files
2. Run `./deploy-secrets.sh`
3. Test @blackroad-agents in any repo!

---

## 📖 Full Documentation

- **This Guide:** ~/BLACKROAD_VAULT_QUICKSTART.md
- **Vault Setup:** ~/blackroad-vault/VAULT_SETUP.md
- **API Keys:** ~/blackroad-vault/api-keys/README.md
- **Credentials:** ~/blackroad-vault/credentials/README.md

---

**Vault URL:** https://github.com/BlackRoad-OS/blackroad-os-vault (PRIVATE)
**Local Path:** ~/blackroad-vault/
**Deploy Script:** ~/blackroad-vault/deploy-secrets.sh

🖤🛣️ Keep your secrets safe with BlackRoad Vault
