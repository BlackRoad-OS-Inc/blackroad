#!/bin/bash
# BlackRoad DNS Manager - Manage Cloudflare DNS records
# Automatically point domains to your deployed apps

CF_API_TOKEN="${CF_API_TOKEN:-yP5h0HvsXX0BpHLs01tLmgtTbQurIKPL4YnQfIwy}"
CF_ZONE_ID="${CF_ZONE_ID:-848cf0b18d51e0170e0d1537aec3505a}"
CF_API_BASE="https://api.cloudflare.com/client/v4"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

log_info() { echo -e "${BLUE}ℹ${NC} $1"; }
log_success() { echo -e "${GREEN}✓${NC} $1"; }
log_error() { echo -e "${RED}✗${NC} $1"; }

# Get target IP
get_target_ip() {
    case "$1" in
        aria64|aria|pi)
            echo "192.168.4.64"
            ;;
        shellfish|sf|droplet)
            echo "174.138.44.45"
            ;;
        alice)
            echo "192.168.4.49"
            ;;
        lucidia)
            echo "192.168.4.38"
            ;;
        *)
            echo "$1"  # Assume it's an IP
            ;;
    esac
}

# Create or update A record
set_dns() {
    local domain=$1
    local target=$2
    local ip=$(get_target_ip "$target")
    
    log_info "Setting DNS: $domain → $ip"
    
    # Check if record exists
    local existing=$(curl -s -X GET "$CF_API_BASE/zones/$CF_ZONE_ID/dns_records?name=$domain&type=A" \
        -H "Authorization: Bearer $CF_API_TOKEN" \
        -H "Content-Type: application/json")
    
    local record_id=$(echo "$existing" | python3 -c "import sys,json;r=json.load(sys.stdin).get('result',[]);print(r[0]['id'] if r else '')" 2>/dev/null)
    
    if [ -n "$record_id" ]; then
        # Update existing record
        log_info "Updating existing record..."
        curl -s -X PUT "$CF_API_BASE/zones/$CF_ZONE_ID/dns_records/$record_id" \
            -H "Authorization: Bearer $CF_API_TOKEN" \
            -H "Content-Type: application/json" \
            --data "{\"type\":\"A\",\"name\":\"$domain\",\"content\":\"$ip\",\"ttl\":1,\"proxied\":false}" \
            > /dev/null
    else
        # Create new record
        log_info "Creating new record..."
        curl -s -X POST "$CF_API_BASE/zones/$CF_ZONE_ID/dns_records" \
            -H "Authorization: Bearer $CF_API_TOKEN" \
            -H "Content-Type: application/json" \
            --data "{\"type\":\"A\",\"name\":\"$domain\",\"content\":\"$ip\",\"ttl\":1,\"proxied\":false}" \
            > /dev/null
    fi
    
    log_success "DNS record set: $domain → $ip"
}

# List DNS records
list_dns() {
    log_info "Fetching DNS records..."
    
    local records=$(curl -s -X GET "$CF_API_BASE/zones/$CF_ZONE_ID/dns_records?type=A&per_page=100" \
        -H "Authorization: Bearer $CF_API_TOKEN" \
        -H "Content-Type: application/json")
    
    echo "$records" | python3 << 'PYEOF'
import sys
import json

data = json.load(sys.stdin)
if data.get('success'):
    records = data.get('result', [])
    print(f"\n{'Domain':<40} {'IP':<15} {'Proxied':<8}")
    print("=" * 70)
    for r in sorted(records, key=lambda x: x['name']):
        name = r['name']
        ip = r['content']
        proxied = 'Yes' if r.get('proxied') else 'No'
        print(f"{name:<40} {ip:<15} {proxied:<8}")
    print(f"\nTotal: {len(records)} records")
else:
    print("Error fetching records:", data.get('errors'))
PYEOF
}

# Delete DNS record
delete_dns() {
    local domain=$1
    
    log_info "Deleting DNS record for $domain..."
    
    local existing=$(curl -s -X GET "$CF_API_BASE/zones/$CF_ZONE_ID/dns_records?name=$domain&type=A" \
        -H "Authorization: Bearer $CF_API_TOKEN" \
        -H "Content-Type: application/json")
    
    local record_id=$(echo "$existing" | python3 -c "import sys,json;r=json.load(sys.stdin).get('result',[]);print(r[0]['id'] if r else '')" 2>/dev/null)
    
    if [ -n "$record_id" ]; then
        curl -s -X DELETE "$CF_API_BASE/zones/$CF_ZONE_ID/dns_records/$record_id" \
            -H "Authorization: Bearer $CF_API_TOKEN" > /dev/null
        log_success "Deleted: $domain"
    else
        log_error "Record not found: $domain"
        exit 1
    fi
}

# Main
case "$1" in
    set)
        set_dns "$2" "$3"
        ;;
    list|ls)
        list_dns
        ;;
    delete|rm)
        delete_dns "$2"
        ;;
    *)
        echo "Usage: $0 {set|list|delete} [args]"
        echo ""
        echo "Examples:"
        echo "  $0 set myapp.blackroad.io aria64"
        echo "  $0 set api.blackroad.io shellfish"
        echo "  $0 list"
        echo "  $0 delete myapp.blackroad.io"
        exit 1
        ;;
esac
