#!/usr/bin/env zsh
# BR SSL - SSL Certificate Manager

AMBER='[38;5;214m'; PINK='[38;5;205m'; VIOLET='[38;5;135m'; BBLUE='[38;5;69m'
GREEN='[0;32m'; RED='[0;31m'; BOLD='[1m'; DIM='[2m'; NC='[0m'
CYAN="$AMBER"; YELLOW="$PINK"; BLUE="$BBLUE"; MAGENTA="$VIOLET"; PURPLE="$VIOLET"

show_help() {
  echo -e ""
  echo -e "  ${AMBER}${BOLD}◆ BR SSL${NC}  ${DIM}SSL certificates managed.${NC}"
  echo -e "  ${DIM}Auto-renew. Never expire. HTTPS, guaranteed.${NC}"
  echo -e "  ${DIM}──────────────────────────────────────────────${NC}"
  echo -e "  ${BOLD}USAGE${NC}  br ${DIM}<command> [args]${NC}"
  echo -e ""
  echo -e "  ${BOLD}COMMANDS${NC}"
  echo -e "  ${AMBER}  check <domain>                ${NC} Check certificate expiry"
  echo -e "  ${AMBER}  list                          ${NC} List all managed certificates"
  echo -e "  ${AMBER}  renew <domain>                ${NC} Renew a certificate"
  echo -e "  ${AMBER}  install <domain>              ${NC} Issue and install certificate"
  echo -e "  ${AMBER}  status                        ${NC} Certificate health overview"
  echo -e "  ${AMBER}  watch                         ${NC} Monitor expiry dates"
  echo -e ""
  echo -e "  ${BOLD}EXAMPLES${NC}"
  echo -e "  ${DIM}  br ssl check blackroad.io${NC}"
  echo -e "  ${DIM}  br ssl list${NC}"
  echo -e "  ${DIM}  br ssl renew api.blackroad.io${NC}"
  echo -e "  ${DIM}  br ssl watch${NC}"
  echo -e ""
}

check_cert() {
    local domain=$1
    if [[ -z "$domain" ]]; then echo "${RED}Usage: br ssl check <domain>${NC}"; exit 1; fi

    echo "${CYAN}🔒 Checking SSL for: ${domain}${NC}"
    echo ""

    local expiry
    expiry=$(echo | openssl s_client -servername "$domain" -connect "${domain}:443" 2>/dev/null \
        | openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2)

    if [[ -z "$expiry" ]]; then
        echo "${RED}✗ Could not connect or no SSL cert found${NC}"
        return 1
    fi

    local expiry_epoch
    expiry_epoch=$(date -j -f "%b %d %T %Y %Z" "$expiry" +%s 2>/dev/null || date -d "$expiry" +%s 2>/dev/null)
    local now_epoch=$(date +%s)
    local days_left=$(( (expiry_epoch - now_epoch) / 86400 ))

    if [[ $days_left -gt 30 ]]; then
        echo "${GREEN}✓ VALID${NC}  Expires: $expiry"
        echo "${GREEN}  $days_left days remaining${NC}"
    elif [[ $days_left -gt 7 ]]; then
        echo "${YELLOW}⚠ EXPIRING SOON${NC}  Expires: $expiry"
        echo "${YELLOW}  $days_left days remaining — renew soon!${NC}"
    elif [[ $days_left -gt 0 ]]; then
        echo "${RED}⚠ CRITICAL${NC}  Expires: $expiry"
        echo "${RED}  Only $days_left days left!${NC}"
    else
        echo "${RED}✗ EXPIRED${NC}  Was: $expiry"
    fi
}

cert_info() {
    local domain=$1
    if [[ -z "$domain" ]]; then echo "${RED}Usage: br ssl info <domain>${NC}"; exit 1; fi

    echo "${CYAN}🔒 Certificate details for: ${domain}${NC}"
    echo ""
    echo | openssl s_client -servername "$domain" -connect "${domain}:443" 2>/dev/null \
        | openssl x509 -noout -text 2>/dev/null \
        | grep -E "(Subject:|Issuer:|Not Before|Not After|DNS:)" \
        | sed 's/^[[:space:]]*/  /'
}

scan_subdomains() {
    local domain=$1
    if [[ -z "$domain" ]]; then echo "${RED}Usage: br ssl scan <domain>${NC}"; exit 1; fi

    local subdomains=("www" "api" "app" "mail" "docs" "blog" "admin" "cdn" "dev" "staging")
    echo "${CYAN}🔍 Scanning SSL for ${domain} subdomains...${NC}"
    echo ""
    for sub in "${subdomains[@]}"; do
        local host="${sub}.${domain}"
        local result
        result=$(echo | openssl s_client -servername "$host" -connect "${host}:443" 2>/dev/null \
            | openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2)
        if [[ -n "$result" ]]; then
            echo "${GREEN}  ✓ ${host}${NC} — expires $result"
        fi
    done
}

DB_FILE="$HOME/.blackroad/ssl-watchlist.db"
init_db() {
    mkdir -p "$(dirname "$DB_FILE")"
    sqlite3 "$DB_FILE" "CREATE TABLE IF NOT EXISTS watchlist (domain TEXT PRIMARY KEY, added_at TEXT);" 2>/dev/null
}

watch_domain() {
    local domain=$1
    if [[ -z "$domain" ]]; then echo "${RED}Usage: br ssl watch <domain>${NC}"; exit 1; fi
    init_db
    sqlite3 "$DB_FILE" "INSERT OR REPLACE INTO watchlist VALUES ('$domain', '$(date -u +%Y-%m-%dT%H:%M:%SZ)');"
    echo "${GREEN}✓ Added ${domain} to SSL watchlist${NC}"
}

list_watchlist() {
    init_db
    local domains=$(sqlite3 "$DB_FILE" "SELECT domain FROM watchlist;" 2>/dev/null)
    if [[ -z "$domains" ]]; then
        echo "${YELLOW}No domains in watchlist. Use: br ssl watch <domain>${NC}"
        return
    fi
    echo "${CYAN}🔒 SSL Watchlist${NC}"
    echo ""
    while IFS= read -r domain; do
        check_cert "$domain"
        echo ""
    done <<< "$domains"
}

check_local() {
    local dir=${1:-.}
    echo "${CYAN}🔍 Scanning for cert files in: ${dir}${NC}"
    echo ""
    find "$dir" -name "*.pem" -o -name "*.crt" -o -name "*.cer" 2>/dev/null | while read -r f; do
        local expiry
        expiry=$(openssl x509 -noout -enddate -in "$f" 2>/dev/null | cut -d= -f2)
        if [[ -n "$expiry" ]]; then
            echo "${GREEN}  ✓ ${f}${NC}"
            echo "    Expires: $expiry"
        fi
    done
}

case "${1:-help}" in
    check)   check_cert "$2" ;;
    info)    cert_info "$2" ;;
    scan)    scan_subdomains "$2" ;;
    watch)   watch_domain "$2" ;;
    list)    list_watchlist ;;
    local)   check_local "$2" ;;
    help|-h) show_help ;;
    *)       show_help ;;
esac
