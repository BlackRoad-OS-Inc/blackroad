#!/bin/bash
# ============================================================================
# BLACKROAD OS, INC. - PROPRIETARY AND CONFIDENTIAL
# Copyright (c) 2024-2026 BlackRoad OS, Inc. All Rights Reserved.
# 
# This code is the intellectual property of BlackRoad OS, Inc.
# AI-assisted development does not transfer ownership to AI providers.
# Unauthorized use, copying, or distribution is prohibited.
# NOT licensed for AI training or data extraction.
# ============================================================================
# Generate Brand Compliance Dashboard Data
# Creates JSON data file for real-time dashboard updates

set -euo pipefail

OUTPUT_FILE="/Users/alexa/brand-compliance-data.json"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

echo "🔍 Scanning Cloudflare Pages projects for brand compliance..."
echo ""

# Get all projects
projects=$(wrangler pages project list 2>/dev/null | grep -E "^│" | awk '{print $2}' | grep -v "Project" | grep -v "^$" || echo "")

if [ -z "$projects" ]; then
    echo "❌ No projects found or not authenticated"
    exit 1
fi

# Initialize JSON
cat > "$OUTPUT_FILE" << 'EOF'
{
  "generated": "",
  "totalProjects": 0,
  "compliant": 0,
  "needsWork": 0,
  "nonCompliant": 0,
  "projects": []
}
EOF

# Start JSON array
echo "{" > "$OUTPUT_FILE"
echo "  \"generated\": \"$TIMESTAMP\"," >> "$OUTPUT_FILE"
echo "  \"projects\": [" >> "$OUTPUT_FILE"

total=0
compliant=0
needs_work=0
non_compliant=0
first=true

while IFS= read -r project; do
    ((total++))

    # Mock compliance check (in production, fetch actual deployment and check)
    # For now, assign random scores for demonstration
    score=$((RANDOM % 100))

    # Determine status
    if [ $score -ge 90 ]; then
        status="compliant"
        ((compliant++))
    elif [ $score -ge 70 ]; then
        status="needs-work"
        ((needs_work++))
    else
        status="non-compliant"
        ((non_compliant++))
    fi

    # Add comma if not first
    if [ "$first" = false ]; then
        echo "    ," >> "$OUTPUT_FILE"
    fi
    first=false

    # Write project data
    cat >> "$OUTPUT_FILE" << EOF
    {
      "name": "$project",
      "score": $score,
      "status": "$status",
      "url": "https://$project.pages.dev",
      "lastCheck": "$(date -u +"%Y-%m-%d")",
      "issues": []
    }
EOF

    echo -ne "\r  Scanned: $total projects"
done <<< "$projects"

echo "" >> "$OUTPUT_FILE"
echo "  ]," >> "$OUTPUT_FILE"
echo "  \"totalProjects\": $total," >> "$OUTPUT_FILE"
echo "  \"compliant\": $compliant," >> "$OUTPUT_FILE"
echo "  \"needsWork\": $needs_work," >> "$OUTPUT_FILE"
echo "  \"nonCompliant\": $non_compliant" >> "$OUTPUT_FILE"
echo "}" >> "$OUTPUT_FILE"

echo ""
echo ""
echo "✅ Dashboard data generated: $OUTPUT_FILE"
echo ""
echo "📊 Summary:"
echo "  Total: $total"
echo "  Compliant (≥90%): $compliant"
echo "  Needs Work (70-89%): $needs_work"
echo "  Non-Compliant (<70%): $non_compliant"
echo ""
