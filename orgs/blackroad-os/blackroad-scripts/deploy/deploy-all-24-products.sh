#!/bin/bash
# 🌸 Willow's 24-Product GitHub Deployment Script
# Deploys all products to BlackRoad-OS organization

echo "🚀 Starting deployment of 24 products to GitHub..."

# Array of all 24 products
products=(
    "roadauth"
    "roadapi"
    "roadbilling"
    "blackroad-ai-platform"
    "blackroad-langchain-studio"
    "roadsupport"
    "blackroad-admin-portal"
    "blackroad-meet"
    "blackroad-minio"
    "blackroad-docs-site"
    "blackroad-vllm"
    "blackroad-keycloak"
    "roadlog-monitoring"
    "roadvpn"
    "blackroad-localai"
    "roadnote"
    "roadscreen"
    "genesis-road"
    "roadgateway"
    "roadmobile"
    "roadcli"
    "roadauth-pro"
    "roadstudio"
    "roadmarket"
)

success_count=0
fail_count=0
skipped_count=0

for product in "${products[@]}"; do
    echo ""
    echo "========================================="
    echo "📦 Processing: $product"
    echo "========================================="

    if [ ! -d "$HOME/$product" ]; then
        echo "⚠️  Directory not found: $HOME/$product - SKIPPING"
        ((skipped_count++))
        continue
    fi

    cd "$HOME/$product" || continue

    # Check if repo already exists on GitHub
    if gh repo view "BlackRoad-OS/$product" &>/dev/null; then
        echo "✓ Repo already exists: BlackRoad-OS/$product"
        echo "🔄 Pushing updates..."

        # Add remote if not exists
        if ! git remote get-url origin &>/dev/null; then
            git remote add origin "https://github.com/BlackRoad-OS/$product.git"
        fi

        # Push to GitHub
        if git push -u origin master 2>&1; then
            echo "✅ Successfully pushed updates to BlackRoad-OS/$product"
            ((success_count++))
        else
            echo "❌ Failed to push to BlackRoad-OS/$product"
            ((fail_count++))
        fi
    else
        echo "📝 Creating new repo: BlackRoad-OS/$product"

        # Create repo in BlackRoad-OS organization
        if gh repo create "BlackRoad-OS/$product" --public --source=. --remote=origin --push 2>&1; then
            echo "✅ Successfully created and pushed BlackRoad-OS/$product"
            ((success_count++))
        else
            echo "❌ Failed to create BlackRoad-OS/$product"
            ((fail_count++))
        fi
    fi
done

echo ""
echo "========================================="
echo "📊 Deployment Summary"
echo "========================================="
echo "✅ Success: $success_count"
echo "❌ Failed: $fail_count"
echo "⏭️  Skipped: $skipped_count"
echo "📦 Total: ${#products[@]}"
echo ""
echo "🖤🛣️ Deployment complete!"
