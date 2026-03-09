#!/bin/bash
# Test subdomain apps GitHub collaboration using SSH hosts

echo "🔗 Testing Subdomain Apps × GitHub × SSH Collaboration"
echo "====================================================="
echo ""

# Test SSH hosts
SSH_HOSTS=("lucidia@lucidia" "alice@alice" "aria64")

echo "1️⃣ Testing SSH Host Connectivity"
echo "--------------------------------"
for host in "${SSH_HOSTS[@]}"; do
    echo -n "  Testing $host: "
    if ssh -o ConnectTimeout=3 -o BatchMode=yes "$host" "echo OK" &>/dev/null; then
        echo "✅ Connected"
        
        # Check if git is installed
        if ssh "$host" "which git" &>/dev/null; then
            echo "    📦 Git installed"
        fi
        
        # Check disk space
        DISK=$(ssh "$host" "df -h / | tail -1 | awk '{print \$5}'" 2>/dev/null)
        echo "    💾 Disk usage: $DISK"
        
    else
        echo "❌ Connection failed"
    fi
done

echo ""
echo "2️⃣ Testing Subdomain Apps Deployment Workflow"
echo "--------------------------------------------"

SUBDOMAINS=(
    "creator.blackroad.io"
    "studio.blackroad.io"
    "research-lab.blackroad.io"
    "finance.blackroad.io"
    "legal.blackroad.io"
)

for subdomain in "${SUBDOMAINS[@]}"; do
    echo -n "  $subdomain: "
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" "https://$subdomain" 2>/dev/null || echo "000")
    
    if [ "$STATUS" = "200" ] || [ "$STATUS" = "301" ] || [ "$STATUS" = "302" ]; then
        echo "✅ Live (HTTP $STATUS)"
    else
        echo "⚠️ Status: $STATUS"
    fi
done

echo ""
echo "3️⃣ Proposing Distributed Deployment Strategy"
echo "------------------------------------------"
cat << 'EOFSTRATEGY'

STRATEGY: Use SSH hosts as deployment relay nodes

┌─────────────────────────────────────────────┐
│         GitHub (Source of Truth)            │
│     BlackRoad-OS/blackroad-os-brand         │
└──────────────┬──────────────────────────────┘
               │
               ├─→ Cloudflare Pages (Primary)
               │   ├─ brand.blackroad.io
               │   └─ Auto-deploy on push
               │
               ├─→ SSH Host: lucidia
               │   ├─ Pull latest
               │   ├─ Run local tests
               │   └─ Mirror for development
               │
               ├─→ SSH Host: alice
               │   ├─ CI/CD runner
               │   ├─ Build verification
               │   └─ Preview deployments
               │
               └─→ SSH Host: aria64
                   ├─ Monitoring agent
                   ├─ Health checks
                   └─ Deployment verification

BENEFITS:
✅ Cloudflare handles production
✅ SSH hosts provide redundancy
✅ Local testing before deploy
✅ Distributed monitoring
✅ Edge computing capabilities

IMPLEMENTATION:
1. Setup git hooks on each SSH host
2. Auto-pull on GitHub webhook
3. Run tests locally
4. Report status to dashboard
5. Cloudflare deploys automatically

EOFSTRATEGY

echo ""
echo "====================================================="
echo "✅ SSH × Subdomain collaboration test complete"
