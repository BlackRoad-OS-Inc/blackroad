#!/bin/bash
# BlackRoad Status Dashboard
# Real-time monitoring and status display
# Version: 1.0.0

set -euo pipefail

# ============================================================================
# CONFIGURATION
# ============================================================================

CLOUDFLARE_TOKEN="${CF_TOKEN:-yP5h0HvsXX0BpHLs01tLmgtTbQurIKPL4YnQfIwy}"
CLOUDFLARE_ACCOUNT_ID="463024cf9efed5e7b40c5fbe7938e256"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Status symbols
CHECK="✅"
CROSS="❌"
WARN="⚠️"
INFO="ℹ️"

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

print_header() {
    local text="$1"
    local width=70
    local padding=$(( (width - ${#text}) / 2 ))

    echo ""
    echo -e "${BLUE}╔$(printf '═%.0s' $(seq 1 $width))╗${NC}"
    printf "${BLUE}║${NC}%*s%s%*s${BLUE}║${NC}\n" $padding "" "$text" $padding ""
    echo -e "${BLUE}╚$(printf '═%.0s' $(seq 1 $width))╝${NC}"
    echo ""
}

print_section() {
    echo ""
    echo -e "${BLUE}━━━ $1 ━━━${NC}"
    echo ""
}

print_status() {
    local status="$1"
    local message="$2"

    case "$status" in
        "ok")
            echo -e "  ${GREEN}${CHECK}${NC} $message"
            ;;
        "fail")
            echo -e "  ${RED}${CROSS}${NC} $message"
            ;;
        "warn")
            echo -e "  ${YELLOW}${WARN}${NC} $message"
            ;;
        "info")
            echo -e "  ${BLUE}${INFO}${NC} $message"
            ;;
    esac
}

# ============================================================================
# STATUS CHECKS
# ============================================================================

check_domain() {
    local domain="$1"
    local http_code=$(curl -s -o /dev/null -w "%{http_code}" -L --max-time 5 "https://$domain" 2>/dev/null || echo "000")
    local response_time=$(curl -s -o /dev/null -w "%{time_total}" -L --max-time 5 "https://$domain" 2>/dev/null || echo "0")

    if [ "$http_code" = "200" ]; then
        print_status "ok" "$domain (${response_time}s)"
        return 0
    elif [ "$http_code" = "000" ]; then
        print_status "fail" "$domain (unreachable)"
        return 1
    else
        print_status "warn" "$domain (HTTP $http_code)"
        return 1
    fi
}

check_pi_node() {
    local name="$1"
    local ip="$2"

    if ssh -o ConnectTimeout=3 -o BatchMode=yes pi@"$ip" "echo 'OK'" >/dev/null 2>&1; then
        local uptime=$(ssh -o ConnectTimeout=3 pi@"$ip" "uptime -p" 2>/dev/null | sed 's/up //')
        print_status "ok" "$name ($ip) - up $uptime"
        return 0
    else
        print_status "fail" "$name ($ip) - unreachable"
        return 1
    fi
}

check_cloudflare_pages() {
    local count=$(curl -s -X GET "https://api.cloudflare.com/client/v4/accounts/$CLOUDFLARE_ACCOUNT_ID/pages/projects" \
        -H "Authorization: Bearer $CLOUDFLARE_TOKEN" \
        -H "Content-Type: application/json" 2>/dev/null | \
        python3 -c "import sys,json; data=json.load(sys.stdin); print(len(data.get('result', [])))" 2>/dev/null || echo "0")

    if [ "$count" -gt 0 ]; then
        print_status "ok" "$count Cloudflare Pages projects active"
        return 0
    else
        print_status "warn" "No Cloudflare Pages projects found"
        return 1
    fi
}

check_github_org() {
    local repo_count=$(gh repo list BlackRoad-OS --limit 1000 --json name 2>/dev/null | jq '. | length' || echo "0")

    if [ "$repo_count" -gt 0 ]; then
        print_status "ok" "$repo_count repositories in BlackRoad-OS"
        return 0
    else
        print_status "warn" "Cannot access BlackRoad-OS GitHub org"
        return 1
    fi
}

# ============================================================================
# DASHBOARD SECTIONS
# ============================================================================

show_critical_services() {
    print_section "🚀 Critical Services"

    check_domain "blackroad.io"
    check_domain "app.blackroad.io"
    check_domain "lucidia.earth"
    check_domain "app.lucidia.earth"
}

show_infrastructure() {
    print_section "🏗️ Infrastructure"

    check_domain "console.blackroad.io"
    check_domain "api.blackroad.io"
    check_domain "docs.blackroad.io"
    check_domain "status.blackroad.io"
}

show_verticals() {
    print_section "📦 Vertical Packs"

    check_domain "finance.blackroad.io"
    check_domain "edu.blackroad.io"
    check_domain "studio.blackroad.io"
    check_domain "lab.blackroad.io"
}

show_pi_mesh() {
    print_section "🥧 Pi Mesh Network"

    check_pi_node "lucidia" "192.168.4.38"
    check_pi_node "blackroad-pi" "192.168.4.64"
    check_pi_node "lucidia-alt" "192.168.4.99"
}

show_cloudflare() {
    print_section "☁️ Cloudflare"

    check_cloudflare_pages

    # Check zone status
    local zone_count=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones" \
        -H "Authorization: Bearer $CLOUDFLARE_TOKEN" 2>/dev/null | \
        python3 -c "import sys,json; data=json.load(sys.stdin); print(len(data.get('result', [])))" 2>/dev/null || echo "0")

    if [ "$zone_count" -gt 0 ]; then
        print_status "ok" "$zone_count DNS zones active"
    else
        print_status "warn" "No DNS zones found"
    fi
}

show_github() {
    print_section "🐙 GitHub"

    check_github_org

    # Check recent workflow runs
    local recent_runs=$(gh run list --repo BlackRoad-OS/blackroad-os-web --limit 5 --json conclusion 2>/dev/null | \
        jq -r '.[0].conclusion' 2>/dev/null || echo "unknown")

    case "$recent_runs" in
        "success")
            print_status "ok" "Latest workflow: success"
            ;;
        "failure")
            print_status "fail" "Latest workflow: failed"
            ;;
        *)
            print_status "info" "Latest workflow: $recent_runs"
            ;;
    esac
}

show_services_summary() {
    print_section "📊 Services Summary"

    # Count healthy services
    local total_domains=0
    local healthy_domains=0

    for domain in blackroad.io app.blackroad.io lucidia.earth app.lucidia.earth; do
        ((total_domains++))
        if curl -s -o /dev/null -w "%{http_code}" -L --max-time 5 "https://$domain" 2>/dev/null | grep -q "200"; then
            ((healthy_domains++))
        fi
    done

    local health_percent=$(awk "BEGIN {printf \"%.0f\", ($healthy_domains/$total_domains)*100}")

    if [ "$health_percent" -eq 100 ]; then
        print_status "ok" "All critical services healthy ($healthy_domains/$total_domains)"
    elif [ "$health_percent" -ge 75 ]; then
        print_status "warn" "Most services healthy ($healthy_domains/$total_domains - ${health_percent}%)"
    else
        print_status "fail" "Service degradation ($healthy_domains/$total_domains - ${health_percent}%)"
    fi

    # Pi mesh summary
    local total_pis=3
    local healthy_pis=0

    for pi_ip in 192.168.4.38 192.168.4.64 192.168.4.99; do
        if ssh -o ConnectTimeout=3 -o BatchMode=yes pi@"$pi_ip" "echo 'OK'" >/dev/null 2>&1; then
            ((healthy_pis++))
        fi
    done

    local pi_health_percent=$(awk "BEGIN {printf \"%.0f\", ($healthy_pis/$total_pis)*100}")

    if [ "$pi_health_percent" -eq 100 ]; then
        print_status "ok" "All Pi nodes online ($healthy_pis/$total_pis)"
    elif [ "$pi_health_percent" -ge 66 ]; then
        print_status "warn" "Some Pi nodes offline ($healthy_pis/$total_pis - ${pi_health_percent}%)"
    else
        print_status "fail" "Pi mesh degraded ($healthy_pis/$total_pis - ${pi_health_percent}%)"
    fi
}

show_recent_deployments() {
    print_section "🚢 Recent Deployments"

    # Check memory system for recent deployments
    if [ -f ~/.blackroad/memory/context/current-context.md ]; then
        print_status "info" "Memory system active"

        # Get last 3 deployments from memory
        grep "deployed:" ~/.blackroad/memory/journals/*.jsonl 2>/dev/null | tail -3 | while read line; do
            local timestamp=$(echo "$line" | jq -r '.timestamp' 2>/dev/null || echo "unknown")
            local entity=$(echo "$line" | jq -r '.entity' 2>/dev/null || echo "unknown")
            print_status "info" "$(date -d "$timestamp" '+%Y-%m-%d %H:%M' 2>/dev/null || echo $timestamp) - $entity"
        done
    else
        print_status "info" "No deployment history available"
    fi
}

# ============================================================================
# MAIN DASHBOARD
# ============================================================================

show_dashboard() {
    clear
    print_header "BlackRoad Status Dashboard"

    echo "Last updated: $(date '+%Y-%m-%d %H:%M:%S')"

    show_services_summary
    show_critical_services
    show_infrastructure
    show_verticals
    show_pi_mesh
    show_cloudflare
    show_github
    show_recent_deployments

    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

show_compact() {
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║  BlackRoad Status (Compact)                                ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""

    # Quick checks
    local checks_passed=0
    local checks_total=0

    for domain in blackroad.io app.blackroad.io lucidia.earth; do
        ((checks_total++))
        if curl -s -o /dev/null -w "%{http_code}" -L --max-time 5 "https://$domain" 2>/dev/null | grep -q "200"; then
            ((checks_passed++))
            echo "✓ $domain"
        else
            echo "✗ $domain"
        fi
    done

    for pi in 192.168.4.38 192.168.4.64 192.168.4.99; do
        ((checks_total++))
        if ping -c 1 -W 2 "$pi" >/dev/null 2>&1; then
            ((checks_passed++))
            echo "✓ Pi node $pi"
        else
            echo "✗ Pi node $pi"
        fi
    done

    echo ""
    echo "Overall: $checks_passed/$checks_total checks passed"
}

watch_dashboard() {
    while true; do
        show_dashboard
        sleep 10
    done
}

# ============================================================================
# MAIN
# ============================================================================

usage() {
    cat <<EOF
BlackRoad Status Dashboard

Usage: $0 [command]

Commands:
  dashboard    Show full dashboard (default)
  compact      Show compact status
  watch        Auto-refresh dashboard every 10s
  json         Output status as JSON

Examples:
  $0
  $0 compact
  $0 watch

EOF
}

main() {
    case "${1:-dashboard}" in
        dashboard)
            show_dashboard
            ;;
        compact)
            show_compact
            ;;
        watch)
            watch_dashboard
            ;;
        json)
            # TODO: Implement JSON output
            echo "{\"status\": \"not_implemented\"}"
            ;;
        *)
            usage
            exit 1
            ;;
    esac
}

main "$@"
