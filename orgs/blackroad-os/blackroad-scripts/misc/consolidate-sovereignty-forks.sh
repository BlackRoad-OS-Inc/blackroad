#!/bin/bash
# BlackRoad Sovereignty Stack - Organization Consolidator
# Distributes forked repos across BlackRoad organizations strategically

echo "╔═══════════════════════════════════════════════════════╗"
echo "║  🌌 BLACKROAD SOVEREIGNTY CONSOLIDATION              ║"
echo "╚═══════════════════════════════════════════════════════╝"
echo ""

# Function to transfer repo
transfer_repo() {
    local current_org="$1"
    local repo_name="$2"
    local target_org="$3"

    echo "  📦 Transferring: $repo_name → $target_org"
    gh repo transfer "$current_org/$repo_name" "$target_org" --yes 2>&1 || echo "    ⚠️  Transfer may require additional permissions"
}

# Function to rename repo (remove -1 suffix)
rename_repo() {
    local org="$1"
    local old_name="$2"
    local new_name="$3"

    echo "  ✏️  Renaming: $old_name → $new_name"
    gh repo rename "$org/$old_name" "$new_name" --yes 2>&1 || echo "    ℹ️  Name may already be in use"
}

# Option 1: Distribute AI repos to BlackRoad-AI
consolidate_ai() {
    echo "🤖 CONSOLIDATING AI STACK TO BlackRoad-AI"
    echo ""

    # AI Runtime & Agents
    transfer_repo "BlackRoad-OS" "vllm-1" "BlackRoad-AI"
    transfer_repo "BlackRoad-OS" "ollama-1" "BlackRoad-AI"
    transfer_repo "BlackRoad-OS" "LocalAI-1" "BlackRoad-AI"
    transfer_repo "BlackRoad-OS" "langchain-1" "BlackRoad-AI"
    transfer_repo "BlackRoad-OS" "haystack-1" "BlackRoad-AI"
    transfer_repo "BlackRoad-OS" "crewAI-1" "BlackRoad-AI"

    # AI Media
    transfer_repo "BlackRoad-OS" "ComfyUI" "BlackRoad-AI"
    transfer_repo "BlackRoad-OS" "krita" "BlackRoad-AI"
    transfer_repo "BlackRoad-OS" "obs-studio" "BlackRoad-AI"
    transfer_repo "BlackRoad-OS" "blender" "BlackRoad-AI"

    # AI Speech
    transfer_repo "BlackRoad-OS" "whisper" "BlackRoad-AI"
    transfer_repo "BlackRoad-OS" "vosk-api" "BlackRoad-AI"
    transfer_repo "BlackRoad-OS" "TTS" "BlackRoad-AI"

    # AI Training
    transfer_repo "BlackRoad-OS" "pytorch" "BlackRoad-AI"
    transfer_repo "BlackRoad-OS" "jax" "BlackRoad-AI"
    transfer_repo "BlackRoad-OS" "ray" "BlackRoad-AI"

    echo "✅ AI Stack consolidated"
}

# Option 2: Distribute Cloud/DevOps to BlackRoad-Cloud
consolidate_cloud() {
    echo "☁️  CONSOLIDATING CLOUD STACK TO BlackRoad-Cloud"
    echo ""

    # Containers
    transfer_repo "BlackRoad-OS" "kubernetes" "BlackRoad-Cloud"
    transfer_repo "BlackRoad-OS" "nomad" "BlackRoad-Cloud"

    # CI/CD
    transfer_repo "BlackRoad-OS" "woodpecker" "BlackRoad-Cloud"
    transfer_repo "BlackRoad-OS" "harness" "BlackRoad-Cloud"

    # IaC
    transfer_repo "BlackRoad-OS" "opentofu" "BlackRoad-Cloud"
    transfer_repo "BlackRoad-OS" "pulumi" "BlackRoad-Cloud"

    # Monitoring
    transfer_repo "BlackRoad-OS" "prometheus" "BlackRoad-Cloud"
    transfer_repo "BlackRoad-OS" "grafana" "BlackRoad-Cloud"
    transfer_repo "BlackRoad-OS" "loki" "BlackRoad-Cloud"

    # Storage
    transfer_repo "BlackRoad-OS" "minio-1" "BlackRoad-Cloud"
    transfer_repo "BlackRoad-OS" "ceph-1" "BlackRoad-Cloud"

    echo "✅ Cloud Stack consolidated"
}

# Option 3: Distribute Security to BlackRoad-Security
consolidate_security() {
    echo "🔒 CONSOLIDATING SECURITY STACK TO BlackRoad-Security"
    echo ""

    # Crypto
    transfer_repo "BlackRoad-OS" "libsodium" "BlackRoad-Security"
    transfer_repo "BlackRoad-OS" "openssl" "BlackRoad-Security"
    transfer_repo "BlackRoad-OS" "liboqs" "BlackRoad-Security"

    # Secrets
    transfer_repo "BlackRoad-OS" "openbao" "BlackRoad-Security"
    transfer_repo "BlackRoad-OS" "sops" "BlackRoad-Security"
    transfer_repo "BlackRoad-OS" "age" "BlackRoad-Security"

    # Policy & Runtime Security
    transfer_repo "BlackRoad-OS" "opa" "BlackRoad-Security"
    transfer_repo "BlackRoad-OS" "falco" "BlackRoad-Security"
    transfer_repo "BlackRoad-OS" "firejail" "BlackRoad-Security"

    # DNS Security
    transfer_repo "BlackRoad-OS" "unbound" "BlackRoad-Security"
    transfer_repo "BlackRoad-OS" "pdns" "BlackRoad-Security"
    transfer_repo "BlackRoad-OS" "knot" "BlackRoad-Security"

    echo "✅ Security Stack consolidated"
}

# Option 4: Distribute Media to BlackRoad-Media
consolidate_media() {
    echo "🎨 CONSOLIDATING MEDIA STACK TO BlackRoad-Media"
    echo ""

    # Social
    transfer_repo "BlackRoad-OS" "mastodon" "BlackRoad-Media"

    # Video
    transfer_repo "BlackRoad-OS" "PeerTube" "BlackRoad-Media"
    transfer_repo "BlackRoad-OS" "owncast" "BlackRoad-Media"

    # Publishing
    transfer_repo "BlackRoad-OS" "Ghost" "BlackRoad-Media"
    transfer_repo "BlackRoad-OS" "writefreely" "BlackRoad-Media"
    transfer_repo "BlackRoad-OS" "hugo" "BlackRoad-Media"

    # Maps
    transfer_repo "BlackRoad-OS" "maplibre-gl-js" "BlackRoad-Media"
    transfer_repo "BlackRoad-OS" "tileserver-gl" "BlackRoad-Media"

    echo "✅ Media Stack consolidated"
}

# Option 5: Rename repos to remove -1 suffix
rename_all() {
    echo "✏️  RENAMING REPOS (removing -1 suffix)"
    echo ""

    rename_repo "BlackRoad-OS" "keycloak-1" "keycloak"
    rename_repo "BlackRoad-OS" "authelia-1" "authelia"
    rename_repo "BlackRoad-OS" "aries-1" "aries"
    rename_repo "BlackRoad-OS" "headscale-1" "headscale"
    rename_repo "BlackRoad-OS" "netbird-1" "netbird"
    rename_repo "BlackRoad-OS" "nebula-1" "nebula"
    rename_repo "BlackRoad-OS" "innernet-1" "innernet"
    rename_repo "BlackRoad-OS" "netmaker-1" "netmaker"

    # Add more as needed...

    echo "✅ Repos renamed"
}

# Main menu
case "${1:-help}" in
    ai)
        consolidate_ai
        ;;
    cloud)
        consolidate_cloud
        ;;
    security)
        consolidate_security
        ;;
    media)
        consolidate_media
        ;;
    rename)
        rename_all
        ;;
    all)
        echo "🚀 FULL CONSOLIDATION"
        consolidate_ai
        echo ""
        consolidate_cloud
        echo ""
        consolidate_security
        echo ""
        consolidate_media
        echo ""
        rename_all
        ;;
    *)
        cat <<HELP
BlackRoad Sovereignty Stack - Organization Consolidator

Usage:
  $0 ai         - Move all AI repos to BlackRoad-AI
  $0 cloud      - Move all Cloud/DevOps to BlackRoad-Cloud
  $0 security   - Move all Security to BlackRoad-Security
  $0 media      - Move all Media to BlackRoad-Media
  $0 rename     - Rename all repos (remove -1 suffix)
  $0 all        - Run all consolidations

Note: Transfers require org admin permissions.
Test with a single repo first!

Examples:
  $0 ai         # Consolidate AI stack
  $0 all        # Full reorganization
HELP
        ;;
esac
