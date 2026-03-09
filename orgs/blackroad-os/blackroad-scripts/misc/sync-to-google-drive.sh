#!/bin/bash
# 📁 Sync BlackRoad Documentation to Google Drive
# Syncs all product docs to blackroad.systems@gmail.com and amundsonalexa@gmail.com

echo "📁 BlackRoad Google Drive Documentation Sync"
echo "========================================="
echo ""

# Google Drive configuration
GOOGLE_DRIVE_EMAILS=(
    "blackroad.systems@gmail.com"
    "amundsonalexa@gmail.com"
)

# Create sync package directory
SYNC_DIR="$HOME/blackroad-docs-sync"
rm -rf "$SYNC_DIR"
mkdir -p "$SYNC_DIR"

echo "📋 Creating Documentation Package"
echo "========================================="
echo ""

# Master documentation files
MASTER_DOCS=(
    "CLERK_INTEGRATION_GUIDE.md"
    "clerk-config.json"
)

# Create directory structure
mkdir -p "$SYNC_DIR/master-guides"
mkdir -p "$SYNC_DIR/deployment-scripts"
mkdir -p "$SYNC_DIR/product-docs"
mkdir -p "$SYNC_DIR/integration-guides"

# Copy master documentation
echo "📚 Collecting Master Guides..."
for doc in "${MASTER_DOCS[@]}"; do
    if [ -f "$HOME/$doc" ]; then
        cp "$HOME/$doc" "$SYNC_DIR/master-guides/"
        echo "   ✅ $doc"
    fi
done
echo ""

# Copy deployment scripts
echo "🚀 Collecting Deployment Scripts..."
DEPLOYMENT_SCRIPTS=(
    "deploy-all-24-products.sh"
    "deploy-ai-to-huggingface.sh"
    "deploy-to-pi-cluster.sh"
    "deploy-all-to-pis.sh"
    "integrate-clerk-auth.sh"
)

for script in "${DEPLOYMENT_SCRIPTS[@]}"; do
    if [ -f "$HOME/$script" ]; then
        cp "$HOME/$script" "$SYNC_DIR/deployment-scripts/"
        echo "   ✅ $script"
    fi
done
echo ""

# Collect product-specific docs
echo "📦 Collecting Product Documentation..."

PRODUCTS=(
    "roadauth" "roadapi" "roadbilling"
    "blackroad-ai-platform" "blackroad-langchain-studio"
    "blackroad-admin-portal" "blackroad-meet" "blackroad-minio"
    "blackroad-docs-site" "blackroad-vllm" "blackroad-keycloak"
    "roadlog-monitoring" "roadvpn" "blackroad-localai"
    "roadnote" "roadscreen" "genesis-road"
    "roadgateway" "roadmobile" "roadcli"
    "roadauth-pro" "roadstudio" "roadmarket"
)

product_count=0
for product in "${PRODUCTS[@]}"; do
    product_dir="$HOME/$product"

    if [ ! -d "$product_dir" ]; then
        continue
    fi

    # Create product subdirectory
    mkdir -p "$SYNC_DIR/product-docs/$product"

    # Copy main HTML
    if [ -f "$product_dir/index.html" ]; then
        cp "$product_dir/index.html" "$SYNC_DIR/product-docs/$product/"
    fi

    # Copy README if exists
    if [ -f "$product_dir/README.md" ]; then
        cp "$product_dir/README.md" "$SYNC_DIR/product-docs/$product/"
    fi

    # Copy Clerk integration docs
    if [ -d "$product_dir/clerk-integration" ]; then
        mkdir -p "$SYNC_DIR/product-docs/$product/clerk-integration"
        cp -r "$product_dir/clerk-integration/"* "$SYNC_DIR/product-docs/$product/clerk-integration/" 2>/dev/null
    fi

    # Copy Pi deployment package
    if [ -d "$HOME/${product}-pi-deploy" ]; then
        mkdir -p "$SYNC_DIR/product-docs/$product/pi-deploy"
        cp -r "$HOME/${product}-pi-deploy/"* "$SYNC_DIR/product-docs/$product/pi-deploy/" 2>/dev/null
    fi

    ((product_count++))
    echo "   ✅ $product"
done
echo ""
echo "   Total products documented: $product_count"
echo ""

# Copy integration guides
echo "🔧 Collecting Integration Guides..."

if [ -d "$HOME/vllm-pi-edge" ]; then
    cp -r "$HOME/vllm-pi-edge" "$SYNC_DIR/integration-guides/"
    echo "   ✅ vLLM Edge AI"
fi

if [ -d "$HOME/minio-distributed" ]; then
    cp -r "$HOME/minio-distributed" "$SYNC_DIR/integration-guides/"
    echo "   ✅ MinIO Distributed Storage"
fi
echo ""

# Create master index
echo "📑 Creating Master Index..."

cat > "$SYNC_DIR/INDEX.md" <<'INDEX'
# BlackRoad Documentation Archive

**Generated:** $(date '+%Y-%m-%d %H:%M:%S')
**Sync Targets:**
- blackroad.systems@gmail.com
- amundsonalexa@gmail.com

## 📂 Directory Structure

```
blackroad-docs-sync/
├── master-guides/          # Master documentation & guides
├── deployment-scripts/     # Deployment automation scripts
├── product-docs/           # Individual product documentation (24 products)
├── integration-guides/     # Platform integration guides
└── INDEX.md               # This file
```

## 🚀 Products (24 Total)

### Core Services
1. **RoadAuth** - Authentication service (JWT, OAuth 2.0)
2. **RoadAPI** - Core API gateway
3. **RoadBilling** - Subscription billing & payments

### AI Platform
4. **BlackRoad AI Platform** - 6 models, 30K agents, 104 TOPS
5. **BlackRoad LangChain Studio** - Workflow orchestration
6. **BlackRoad vLLM** - High-performance inference (10x faster)
7. **BlackRoad LocalAI** - Self-hosted AI platform

### Enterprise Tools
8. **BlackRoad Admin Portal** - Admin dashboard
9. **BlackRoad Meet** - Video conferencing (Jitsi-based)
10. **BlackRoad MinIO** - Object storage
11. **BlackRoad Docs Site** - Documentation platform
12. **BlackRoad Keycloak** - Identity management
13. **RoadLog Monitoring** - System monitoring

### Infrastructure
14. **RoadVPN** - WireGuard VPN service

### Productivity
15. **RoadNote** - Professional note-taking
16. **RoadScreen** - Screen recording & video

### Development
17. **Genesis Road** - Game engine & development
18. **RoadGateway** - API management & dev platform
19. **RoadMobile** - Cross-platform mobile framework
20. **RoadCLI** - Command-line developer tool

### Enterprise Security
21. **RoadAuth Pro** - Zero-trust identity (Authelia-based)

### Creative Tools
22. **RoadStudio** - Video production & editing (4K/8K)

### Marketplace
23. **RoadMarket** - Digital product marketplace (0% fees)

## 🔐 Authentication (Clerk Integration)

All products integrated with Clerk enterprise authentication:
- Email/password authentication
- Social login (Google, GitHub, Apple)
- Multi-factor authentication (MFA)
- Passwordless sign-in
- Organization support (teams)

Configuration: `master-guides/clerk-config.json`
Guide: `master-guides/CLERK_INTEGRATION_GUIDE.md`

## 🥧 Raspberry Pi Deployment

8 backend services packaged for Pi cluster deployment:
- blackroad-ai-platform (lucidia:192.168.4.38)
- blackroad-vllm (blackroad-pi:192.168.4.64)
- blackroad-localai (lucidia-alt:192.168.4.99)
- roadapi, roadlog-monitoring, blackroad-minio
- roadauth, roadbilling

Plus: vLLM edge AI inference, MinIO distributed storage

Scripts: `deployment-scripts/deploy-to-pi-cluster.sh`

## 🤖 Hugging Face AI Products

4 AI products prepared for Hugging Face Spaces:
- blackroad-ai-platform
- blackroad-langchain-studio
- blackroad-vllm
- blackroad-localai

Script: `deployment-scripts/deploy-ai-to-huggingface.sh`

## 📊 Deployment Status

- ✅ **Cloudflare Pages**: 24/24 products live
- ✅ **GitHub**: 23/24 repos in BlackRoad-OS organization
- ⏳ **Hugging Face**: 4 AI products prepared (awaiting HF token)
- ⏳ **Raspberry Pi**: 8 packages ready (Pis currently offline)
- ✅ **Clerk Auth**: 23/23 products integrated

## 🌐 Live URLs

All products deployed to Cloudflare Pages:
- Format: `https://[hash].blackroad-[project].pages.dev`
- Custom domains: Configure via Cloudflare DNS

## 📝 Documentation Files

Each product includes:
- `index.html` - Main application
- `README.md` - Product documentation (where available)
- `clerk-integration/` - Authentication setup
- `pi-deploy/` - Raspberry Pi deployment package

## 🔧 Deployment Scripts

All deployment automation in `deployment-scripts/`:
- GitHub mass deployment
- Hugging Face AI deployment prep
- Pi cluster package creation
- Clerk authentication integration

## 🖤🛣️ BlackRoad OS

Enterprise software ecosystem built for scale, security, and simplicity.

**Contact:**
- blackroad.systems@gmail.com
- amundsonalexa@gmail.com

**GitHub**: BlackRoad-OS organization (66+ repositories)
**Website**: blackroad.io
INDEX

echo "   ✅ Master index created"
echo ""

# Create compressed archive
echo "📦 Creating Archive..."
cd "$HOME"
tar -czf blackroad-docs-sync.tar.gz blackroad-docs-sync/
archive_size=$(du -h blackroad-docs-sync.tar.gz | cut -f1)
echo "   ✅ Archive created: blackroad-docs-sync.tar.gz ($archive_size)"
echo ""

# Create Google Drive upload instructions
cat > "$SYNC_DIR/GOOGLE_DRIVE_UPLOAD.md" <<'UPLOAD'
# Google Drive Upload Instructions

## Method 1: Web Upload (Manual)

1. Visit [Google Drive](https://drive.google.com)
2. Sign in to:
   - blackroad.systems@gmail.com
   - amundsonalexa@gmail.com
3. Create folder: "BlackRoad Documentation"
4. Upload entire `blackroad-docs-sync/` folder
5. Share folder (view access) with both emails

## Method 2: Google Drive CLI (Automated)

### Install rclone

```bash
# macOS
brew install rclone

# Linux
curl https://rclone.org/install.sh | sudo bash
```

### Configure rclone

```bash
# Start configuration
rclone config

# Follow prompts:
# - n (new remote)
# - name: blackroad-systems
# - type: drive
# - client_id: (press Enter for defaults)
# - client_secret: (press Enter)
# - scope: 1 (full access)
# - service_account_file: (press Enter)
# - Edit advanced config: n
# - Use auto config: y (opens browser)
# - Sign in with blackroad.systems@gmail.com
# - Configure as team drive: n
# - Confirm: y

# Repeat for amundsonalexa@gmail.com
```

### Upload to Google Drive

```bash
# Upload to blackroad.systems@gmail.com
rclone copy ~/blackroad-docs-sync blackroad-systems:BlackRoad-Documentation -v

# Upload to amundsonalexa@gmail.com
rclone copy ~/blackroad-docs-sync amundsonalexa:BlackRoad-Documentation -v
```

### Sync (continuous updates)

```bash
# Sync changes only
rclone sync ~/blackroad-docs-sync blackroad-systems:BlackRoad-Documentation -v
```

## Method 3: Share Compressed Archive

```bash
# Archive already created at:
~/blackroad-docs-sync.tar.gz

# Email to:
# - blackroad.systems@gmail.com
# - amundsonalexa@gmail.com

# Or upload to:
# - WeTransfer
# - Dropbox
# - Google Drive web interface
```

## Folder Structure on Google Drive

```
BlackRoad Documentation/
├── master-guides/
├── deployment-scripts/
├── product-docs/
│   ├── roadauth/
│   ├── roadapi/
│   ├── ... (24 products total)
├── integration-guides/
└── INDEX.md
```

## Sharing Settings

**Recommended:**
- Folder visibility: Private
- Share with: blackroad.systems@gmail.com, amundsonalexa@gmail.com
- Permission: View/Download (read-only)

**For Team Access:**
- Create shared drive: "BlackRoad Team"
- Add members
- Upload to shared drive

## Automatic Sync (Optional)

Create a cron job for weekly syncs:

```bash
# Edit crontab
crontab -e

# Add weekly Sunday midnight sync
0 0 * * 0 ~/sync-to-google-drive.sh && rclone sync ~/blackroad-docs-sync blackroad-systems:BlackRoad-Documentation
```

🖤🛣️ Documentation synced to Google Drive
UPLOAD

echo "   ✅ Upload instructions created"
echo ""

# Create sync summary
echo "========================================="
echo "📊 Sync Package Summary"
echo "========================================="
echo ""
echo "📁 Sync Directory: $SYNC_DIR"
echo "📦 Archive: ~/blackroad-docs-sync.tar.gz ($archive_size)"
echo ""
echo "📚 Contents:"
echo "   - Master Guides: $(ls -1 $SYNC_DIR/master-guides 2>/dev/null | wc -l | tr -d ' ') files"
echo "   - Deployment Scripts: $(ls -1 $SYNC_DIR/deployment-scripts 2>/dev/null | wc -l | tr -d ' ') files"
echo "   - Products Documented: $product_count"
echo "   - Integration Guides: $(ls -1 $SYNC_DIR/integration-guides 2>/dev/null | wc -l | tr -d ' ') directories"
echo ""
echo "🎯 Target Emails:"
for email in "${GOOGLE_DRIVE_EMAILS[@]}"; do
    echo "   - $email"
done
echo ""
echo "📝 Next Steps:"
echo ""
echo "1. Review documentation package:"
echo "   open $SYNC_DIR"
echo ""
echo "2. Read upload instructions:"
echo "   cat $SYNC_DIR/GOOGLE_DRIVE_UPLOAD.md"
echo ""
echo "3. Choose upload method:"
echo "   A. Manual web upload (drag & drop)"
echo "   B. rclone CLI (automated)"
echo "   C. Email compressed archive"
echo ""
echo "4. Recommended: Install rclone for automated sync"
echo "   brew install rclone"
echo "   rclone config"
echo ""
echo "5. Upload to both Google Drive accounts:"
echo "   rclone copy ~/blackroad-docs-sync blackroad-systems:BlackRoad-Documentation"
echo "   rclone copy ~/blackroad-docs-sync amundsonalexa:BlackRoad-Documentation"
echo ""
echo "🖤🛣️ Documentation Package Ready!"
echo ""
echo "📊 Package Statistics:"
du -sh "$SYNC_DIR"
find "$SYNC_DIR" -type f | wc -l | xargs echo "Total files:"
echo ""
