#!/bin/bash
# BlackRoad Deployment Testing System
# Comprehensive testing for all domains and services
# Version: 1.0.0

set -euo pipefail

# ============================================================================
# CONFIGURATION
# ============================================================================

# All domains to test
DOMAINS=(
    # Primary
    "blackroad.io"
    "app.blackroad.io"
    "console.blackroad.io"
    "docs.blackroad.io"
    "api.blackroad.io"
    "brand.blackroad.io"

    # Lucidia
    "lucidia.earth"
    "app.lucidia.earth"
    "console.lucidia.earth"

    # Verticals
    "finance.blackroad.io"
    "edu.blackroad.io"
    "studio.blackroad.io"
    "lab.blackroad.io"
    "canvas.blackroad.io"
    "video.blackroad.io"
    "writing.blackroad.io"

    # Infrastructure
    "status.blackroad.io"
    "cdn.blackroad.io"
)

# Pi nodes
PI_NODES=(
    "192.168.4.38"  # lucidia
    "192.168.4.64"  # blackroad
    "192.168.4.99"  # lucidia-alt
)

# Test results
RESULTS_FILE="/tmp/blackroad-deployment-tests-$(date +%Y%m%d-%H%M%S).json"
FAILED_TESTS=0
PASSED_TESTS=0

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

log() {
    echo "[$(date +'%H:%M:%S')] $*"
}

success() {
    echo "✅ $*"
    ((PASSED_TESTS++))
}

fail() {
    echo "❌ $*"
    ((FAILED_TESTS++))
}

# ============================================================================
# HTTP TESTING
# ============================================================================

test_http() {
    local url="$1"
    local expected_code="${2:-200}"

    log "Testing HTTP: $url"

    local http_code=$(curl -s -o /dev/null -w "%{http_code}" -L --max-time 10 "$url" 2>/dev/null || echo "000")
    local response_time=$(curl -s -o /dev/null -w "%{time_total}" -L --max-time 10 "$url" 2>/dev/null || echo "0")

    if [ "$http_code" = "$expected_code" ]; then
        success "$url → HTTP $http_code (${response_time}s)"
        echo "{\"url\": \"$url\", \"status\": \"pass\", \"http_code\": $http_code, \"response_time\": $response_time}" >> "$RESULTS_FILE"
        return 0
    else
        fail "$url → HTTP $http_code (expected $expected_code)"
        echo "{\"url\": \"$url\", \"status\": \"fail\", \"http_code\": $http_code, \"expected\": $expected_code}" >> "$RESULTS_FILE"
        return 1
    fi
}

test_ssl() {
    local domain="$1"

    log "Testing SSL: $domain"

    if echo | openssl s_client -connect "$domain:443" -servername "$domain" 2>/dev/null | grep -q "Verify return code: 0"; then
        success "$domain SSL certificate is valid"
        return 0
    else
        fail "$domain SSL certificate is invalid or missing"
        return 1
    fi
}

test_dns() {
    local domain="$1"

    log "Testing DNS: $domain"

    if dig +short "$domain" | grep -q .; then
        local records=$(dig +short "$domain" | tr '\n' ' ')
        success "$domain resolves to: $records"
        return 0
    else
        fail "$domain does not resolve"
        return 1
    fi
}

test_api_endpoint() {
    local endpoint="$1"
    local expected_field="${2:-status}"

    log "Testing API: $endpoint"

    local response=$(curl -s -L --max-time 10 "$endpoint" 2>/dev/null || echo "{}")

    if echo "$response" | jq -e ".$expected_field" >/dev/null 2>&1; then
        success "$endpoint API is responding"
        return 0
    else
        fail "$endpoint API is not responding correctly"
        return 1
    fi
}

# ============================================================================
# PI MESH TESTING
# ============================================================================

test_pi_node() {
    local pi_ip="$1"

    log "Testing Pi node: $pi_ip"

    if ping -c 1 -W 2 "$pi_ip" >/dev/null 2>&1; then
        success "$pi_ip is reachable"
    else
        fail "$pi_ip is unreachable"
        return 1
    fi

    if ssh -o ConnectTimeout=5 -o BatchMode=yes pi@"$pi_ip" "echo 'OK'" >/dev/null 2>&1; then
        success "$pi_ip SSH is working"
        return 0
    else
        fail "$pi_ip SSH is not working"
        return 1
    fi
}

test_pi_service() {
    local pi_ip="$1"
    local service="$2"

    log "Testing service $service on $pi_ip"

    if ssh -o ConnectTimeout=5 pi@"$pi_ip" "cd /home/pi/services/$service && docker-compose ps" >/dev/null 2>&1; then
        success "$service is running on $pi_ip"
        return 0
    else
        fail "$service is not running on $pi_ip"
        return 1
    fi
}

# ============================================================================
# CLOUDFLARE TESTING
# ============================================================================

test_cloudflare_pages() {
    local domain="$1"

    log "Testing Cloudflare Pages: $domain"

    # Check if served by Cloudflare
    local cf_ray=$(curl -sI "https://$domain" 2>/dev/null | grep -i "cf-ray" || echo "")

    if [ -n "$cf_ray" ]; then
        success "$domain is served by Cloudflare"
        return 0
    else
        fail "$domain is not served by Cloudflare"
        return 1
    fi
}

# ============================================================================
# PERFORMANCE TESTING
# ============================================================================

test_performance() {
    local url="$1"

    log "Testing performance: $url"

    local metrics=$(curl -s -o /dev/null -w "DNS:%{time_namelookup}s Connect:%{time_connect}s TLS:%{time_appconnect}s TTFB:%{time_starttransfer}s Total:%{time_total}s" "$url" 2>/dev/null)

    echo "$metrics"
    success "Performance metrics for $url"
}

# ============================================================================
# COMPREHENSIVE TEST SUITES
# ============================================================================

test_all_domains() {
    log "Starting comprehensive domain testing..."

    echo "[" > "$RESULTS_FILE"

    for domain in "${DOMAINS[@]}"; do
        echo ""
        log "═══════════════════════════════════════"
        log "Testing domain: $domain"
        log "═══════════════════════════════════════"

        test_dns "$domain" || true
        test_ssl "$domain" || true
        test_http "https://$domain" || true
        test_cloudflare_pages "$domain" || true
        test_performance "https://$domain" || true

        sleep 1
    done

    echo "]" >> "$RESULTS_FILE"
}

test_all_pi_nodes() {
    log "Starting Pi mesh testing..."

    for pi in "${PI_NODES[@]}"; do
        echo ""
        log "═══════════════════════════════════════"
        log "Testing Pi node: $pi"
        log "═══════════════════════════════════════"

        test_pi_node "$pi" || true

        sleep 1
    done
}

test_api_endpoints() {
    log "Starting API endpoint testing..."

    # Test various API endpoints
    test_api_endpoint "https://api.blackroad.io/health" || true
    test_api_endpoint "https://api.lucidia.earth/health" || true
}

# ============================================================================
# SMOKE TESTS
# ============================================================================

smoke_test() {
    log "Running smoke tests..."

    # Critical paths
    test_http "https://blackroad.io" 200
    test_http "https://lucidia.earth" 200
    test_http "https://app.blackroad.io" 200

    # API health checks
    test_http "https://api.blackroad.io/health" 200 || true

    # Status page
    test_http "https://status.blackroad.io" 200 || true
}

# ============================================================================
# REPORTING
# ============================================================================

generate_report() {
    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║  BlackRoad Deployment Test Report                         ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    echo "📊 Test Summary:"
    echo "   ✅ Passed: $PASSED_TESTS"
    echo "   ❌ Failed: $FAILED_TESTS"
    echo "   📈 Success Rate: $(awk "BEGIN {printf \"%.1f\", ($PASSED_TESTS/($PASSED_TESTS+$FAILED_TESTS))*100}")%"
    echo ""
    echo "📝 Full results saved to: $RESULTS_FILE"
    echo ""

    if [ $FAILED_TESTS -gt 0 ]; then
        echo "⚠️  Some tests failed. Review the output above for details."
        return 1
    else
        echo "🎉 All tests passed!"
        return 0
    fi
}

# ============================================================================
# CONTINUOUS MONITORING
# ============================================================================

monitor_continuous() {
    local interval="${1:-300}"  # Default 5 minutes

    log "Starting continuous monitoring (interval: ${interval}s)..."

    while true; do
        smoke_test
        sleep "$interval"
    done
}

# ============================================================================
# MAIN
# ============================================================================

usage() {
    cat <<EOF
BlackRoad Deployment Testing System

Usage: $0 <command> [options]

Commands:
  all              Run all tests
  domains          Test all domains
  pi               Test all Pi nodes
  api              Test API endpoints
  smoke            Run smoke tests only
  monitor [secs]   Continuous monitoring (default 300s)
  perf <url>       Test performance of specific URL

Examples:
  $0 all
  $0 smoke
  $0 monitor 60
  $0 perf https://app.blackroad.io

EOF
}

main() {
    case "${1:-}" in
        all)
            test_all_domains
            test_all_pi_nodes
            test_api_endpoints
            generate_report
            ;;
        domains)
            test_all_domains
            generate_report
            ;;
        pi)
            test_all_pi_nodes
            generate_report
            ;;
        api)
            test_api_endpoints
            generate_report
            ;;
        smoke)
            smoke_test
            generate_report
            ;;
        monitor)
            monitor_continuous "${2:-300}"
            ;;
        perf)
            [ -z "${2:-}" ] && { echo "URL required"; usage; exit 1; }
            test_performance "$2"
            ;;
        *)
            usage
            exit 1
            ;;
    esac
}

main "$@"
