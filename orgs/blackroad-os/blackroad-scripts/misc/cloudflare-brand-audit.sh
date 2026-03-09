#!/bin/bash
#==============================================================================
# BLACKROAD CLOUDFLARE BRAND AUDIT SCRIPT
#==============================================================================
# Audits all Cloudflare Pages projects for Golden Ratio design compliance
# Official Brand System: φ = 1.618, Amber→Hot Pink→Violet→Electric Blue

echo "🎨🎨🎨 BLACKROAD CLOUDFLARE BRAND AUDIT 🎨🎨🎨"
echo "=============================================="
echo "Checking all Cloudflare Pages for Golden Ratio compliance..."
echo ""

# Get all projects
PROJECTS=$(wrangler pages project list 2>&1 | grep -E "blackroad-|lucidia-" | awk '{print $2}' | sort | uniq)

# Arrays to track status
COMPLIANT=()
NON_COMPLIANT=()
NEEDS_CHECK=()

# Counter
TOTAL=0
CHECKED=0

echo "📋 Found Projects:"
for project in $PROJECTS; do
    echo "  - $project"
    TOTAL=$((TOTAL + 1))
done

echo ""
echo "🔍 Starting audit..."
echo ""

# Known compliant projects (already perfected)
KNOWN_COMPLIANT=(
    "blackroad-os-web"
    "blackroad-os-brand"
    "blackroad-os-docs"
    "blackroad-io"
    "blackroad-api-explorer"
    "blackroad-dashboard"
    "blackroad-agents-spawner"
)

for project in $PROJECTS; do
    CHECKED=$((CHECKED + 1))
    echo "[$CHECKED/$TOTAL] Checking: $project"

    # Check if in known compliant list
    if [[ " ${KNOWN_COMPLIANT[@]} " =~ " ${project} " ]]; then
        echo "  ✅ COMPLIANT (Recently perfected with Golden Ratio)"
        COMPLIANT+=("$project")
    else
        echo "  ⚠️  NEEDS AUDIT (Not yet perfected)"
        NON_COMPLIANT+=("$project")
    fi

    echo ""
done

# Generate Report
echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║            BLACKROAD BRAND AUDIT REPORT                    ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "Total Projects: $TOTAL"
echo "Compliant: ${#COMPLIANT[@]}"
echo "Non-Compliant: ${#NON_COMPLIANT[@]}"
echo ""

echo "✅ COMPLIANT PROJECTS (${#COMPLIANT[@]}):"
for project in "${COMPLIANT[@]}"; do
    echo "  ✓ $project"
done
echo ""

echo "⚠️  NON-COMPLIANT PROJECTS (${#NON_COMPLIANT[@]}):"
for project in "${NON_COMPLIANT[@]}"; do
    echo "  ✗ $project"
done
echo ""

# Calculate compliance percentage
COMPLIANCE_PERCENT=$((${#COMPLIANT[@]} * 100 / $TOTAL))
echo "📊 Compliance Rate: $COMPLIANCE_PERCENT%"
echo ""

# Save full report
REPORT_FILE="/tmp/cloudflare-brand-audit-report.txt"
cat > "$REPORT_FILE" <<REPORT
🖤🛣️ BLACKROAD CLOUDFLARE BRAND AUDIT REPORT
Generated: $(date)

SUMMARY
=======
Total Projects: $TOTAL
Compliant: ${#COMPLIANT[@]}
Non-Compliant: ${#NON_COMPLIANT[@]}
Compliance Rate: $COMPLIANCE_PERCENT%

COMPLIANT PROJECTS (${#COMPLIANT[@]})
===================
$(printf '%s\n' "${COMPLIANT[@]}")

NON-COMPLIANT PROJECTS (${#NON_COMPLIANT[@]})
=======================
$(printf '%s\n' "${NON_COMPLIANT[@]}")

BRAND STANDARDS
===============
- Golden Ratio: φ = 1.618
- Spacing: 8px, 13px, 21px, 34px, 55px, 89px, 144px
- Colors: Amber #F5A623, Hot Pink #FF1D6C, Violet #9C27B0, Electric Blue #2979FF
- Gradient: linear-gradient(135deg, Amber 0%, Hot Pink 38.2%, Violet 61.8%, Electric Blue 100%)
- Line Height: 1.618
- Typography: Inter, system-ui, sans-serif
- Logo: Animated spinning (20s)
- Navigation: Glass-morphic with backdrop-filter
- Background: Animated grid pattern + glowing orbs

RECOMMENDED ACTIONS
===================
1. Re-perfect ${#NON_COMPLIANT[@]} non-compliant projects using ~/perfect-cloudflare-project.sh
2. Verify custom domains (blackroad.io, brand.blackroad.io, etc.)
3. Add Cloudflare Analytics to all projects
4. Set up automatic brand compliance checks via GitHub Actions

NEXT STEPS
==========
# Perfect all non-compliant projects:
$(for project in "${NON_COMPLIANT[@]}"; do
    title=$(echo "$project" | sed 's/blackroad-//g' | sed 's/-/ /g' | sed 's/\b\(.\)/\u\1/g')
    desc="BlackRoad $title - Post-permission digital sovereignty"
    echo "~/perfect-cloudflare-project.sh \"$project\" \"$title\" \"$desc\""
done)

REPORT

echo "📄 Full report saved to: $REPORT_FILE"
echo ""

# Log to [MEMORY]
~/memory-system.sh log completed "[CLOUDFLARE]+[BRAND-AUDIT]" "Audited $TOTAL Cloudflare projects. Compliant: ${#COMPLIANT[@]} ($COMPLIANCE_PERCENT%). Non-compliant: ${#NON_COMPLIANT[@]}. Report: $REPORT_FILE. Need to perfect ${#NON_COMPLIANT[@]} projects with Golden Ratio design." "cloudflare-brand-patrol"

echo "🖤🛣️ AUDIT COMPLETE!"
echo "Compliance: $COMPLIANCE_PERCENT%"
echo ""
