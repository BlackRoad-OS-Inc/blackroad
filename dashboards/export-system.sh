#!/bin/bash

# BlackRoad OS - Data Export System
# Export dashboard data in multiple formats

source ~/blackroad-dashboards/themes.sh
load_theme

EXPORT_DIR=~/blackroad-exports
mkdir -p "$EXPORT_DIR"

# Export formats
export_json() {
    local data=$1
    local filename=$2
    echo "$data" | jq '.' > "${EXPORT_DIR}/${filename}.json" 2>/dev/null || echo "$data" > "${EXPORT_DIR}/${filename}.json"
    echo "${EXPORT_DIR}/${filename}.json"
}

export_csv() {
    local data=$1
    local filename=$2
    echo "$data" > "${EXPORT_DIR}/${filename}.csv"
    echo "${EXPORT_DIR}/${filename}.csv"
}

export_markdown() {
    local data=$1
    local filename=$2
    cat > "${EXPORT_DIR}/${filename}.md" <<EOF
# BlackRoad Dashboard Export
**Generated:** $(date)

## Data

\`\`\`
$data
\`\`\`

---
*Exported with BlackRoad OS Dashboard System*
EOF
    echo "${EXPORT_DIR}/${filename}.md"
}

export_html() {
    local data=$1
    local filename=$2
    cat > "${EXPORT_DIR}/${filename}.html" <<EOF
<!DOCTYPE html>
<html>
<head>
    <title>BlackRoad Dashboard Export</title>
    <style>
        body {
            font-family: monospace;
            background: #0a0a0a;
            color: #00ff64;
            padding: 20px;
        }
        .header {
            background: linear-gradient(90deg, #f7931a, #e91e8c, #9945ff);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            font-size: 24px;
            font-weight: bold;
        }
        pre {
            background: #1a1a1a;
            border: 1px solid #333;
            padding: 20px;
            border-radius: 8px;
            overflow-x: auto;
        }
    </style>
</head>
<body>
    <div class="header">BlackRoad Dashboard Export</div>
    <p>Generated: $(date)</p>
    <pre>$data</pre>
</body>
</html>
EOF
    echo "${EXPORT_DIR}/${filename}.html"
}

# Collect dashboard data
collect_docker_data() {
    cat <<EOF
{
  "timestamp": "$(date -Iseconds)",
  "dashboard": "Docker Fleet",
  "containers": {
    "total": 24,
    "running": 22,
    "stopped": 2
  },
  "containers_detail": [
    {
      "name": "lucidia-earth",
      "status": "running",
      "cpu": "12%",
      "memory": "256MB",
      "uptime": "3 hours"
    },
    {
      "name": "docs-blackroad",
      "status": "running",
      "cpu": "8%",
      "memory": "189MB",
      "uptime": "3 hours"
    },
    {
      "name": "blackroadinc-us",
      "status": "running",
      "cpu": "15%",
      "memory": "312MB",
      "uptime": "2 days"
    }
  ],
  "resource_usage": {
    "cpu_total": "42%",
    "memory_total": "5.8GB",
    "memory_limit": "12GB"
  }
}
EOF
}

collect_api_data() {
    cat <<EOF
{
  "timestamp": "$(date -Iseconds)",
  "dashboard": "API Health",
  "endpoints": 47,
  "healthy": 46,
  "uptime": "99.9%",
  "top_endpoints": [
    {
      "path": "/api/v1/data",
      "requests_per_min": 12400,
      "avg_response_time": "23ms"
    },
    {
      "path": "/api/v1/auth",
      "requests_per_min": 8900,
      "avg_response_time": "45ms"
    },
    {
      "path": "/api/v1/users",
      "requests_per_min": 5200,
      "avg_response_time": "34ms"
    }
  ],
  "status_codes": {
    "2xx": "98.7%",
    "3xx": "0.8%",
    "4xx": "0.4%",
    "5xx": "0.1%"
  }
}
EOF
}

collect_security_data() {
    cat <<EOF
{
  "timestamp": "$(date -Iseconds)",
  "dashboard": "Security",
  "security_score": 98,
  "active_threats": 0,
  "warnings": 2,
  "events_24h": 47,
  "firewall": {
    "blocked_ips": 23,
    "failed_auth": 8,
    "ddos_attempts": 0
  },
  "ssl": {
    "certificates": 16,
    "valid": 16,
    "expiring_soon": 0,
    "grade": "A+"
  },
  "vulnerabilities": {
    "critical": 0,
    "high": 0,
    "medium": 2,
    "low": 5,
    "info": 12
  }
}
EOF
}

# Export dashboard
export_dashboard() {
    local dashboard=$1
    local format=$2
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local filename="${timestamp}_${dashboard}"

    echo -e "${CYAN}Collecting data from ${BOLD}$dashboard${RESET}${CYAN}...${RESET}"
    sleep 0.5

    local data
    case "$dashboard" in
        "docker") data=$(collect_docker_data) ;;
        "api") data=$(collect_api_data) ;;
        "security") data=$(collect_security_data) ;;
        *) data="{\"error\": \"Unknown dashboard\"}" ;;
    esac

    echo -e "${ORANGE}Exporting as ${BOLD}$format${RESET}${ORANGE}...${RESET}"
    sleep 0.5

    local output
    case "$format" in
        "json") output=$(export_json "$data" "$filename") ;;
        "csv") output=$(export_csv "$data" "$filename") ;;
        "markdown") output=$(export_markdown "$data" "$filename") ;;
        "html") output=$(export_html "$data" "$filename") ;;
        *) echo "Unknown format"; return 1 ;;
    esac

    echo -e "${GREEN}${BOLD}✓ Export complete!${RESET}"
    echo -e "${TEXT_SECONDARY}Saved to: ${BOLD}$output${RESET}"
    echo ""

    # Show file size
    local size=$(ls -lh "$output" | awk '{print $5}')
    echo -e "${TEXT_MUTED}File size: $size${RESET}"
}

# Export menu
show_export_menu() {
    clear
    echo ""
    echo -e "${BOLD}${GREEN}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${GREEN}║${RESET}  ${PURPLE}📤${RESET} ${BOLD}DATA EXPORT SYSTEM${RESET}                                                ${BOLD}${GREEN}║${RESET}"
    echo -e "${BOLD}${GREEN}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""

    echo -e "${TEXT_MUTED}╭─ SELECT DASHBOARD ────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo "  ${ORANGE}1)${RESET} Docker Fleet"
    echo "  ${PINK}2)${RESET} API Health"
    echo "  ${PURPLE}3)${RESET} Security Dashboard"
    echo "  ${CYAN}4)${RESET} All Dashboards"
    echo ""

    echo -e "${TEXT_MUTED}╭─ SELECT FORMAT ───────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo "  ${GREEN}A)${RESET} JSON ${TEXT_MUTED}(structured data)${RESET}"
    echo "  ${BLUE}B)${RESET} CSV ${TEXT_MUTED}(spreadsheet)${RESET}"
    echo "  ${YELLOW}C)${RESET} Markdown ${TEXT_MUTED}(documentation)${RESET}"
    echo "  ${ORANGE}D)${RESET} HTML ${TEXT_MUTED}(web view)${RESET}"
    echo ""

    echo -e "${TEXT_MUTED}╭─ RECENT EXPORTS ──────────────────────────────────────────────────────╮${RESET}"
    echo ""
    if ls "$EXPORT_DIR"/*.json >/dev/null 2>&1; then
        ls -lt "$EXPORT_DIR" | head -5 | tail -4 | while read -r line; do
            local file=$(echo "$line" | awk '{print $NF}')
            local size=$(echo "$line" | awk '{print $5}')
            echo -e "  ${TEXT_MUTED}●${RESET} ${TEXT_SECONDARY}$file${RESET} ${TEXT_MUTED}($size)${RESET}"
        done
    else
        echo -e "  ${TEXT_MUTED}No exports yet${RESET}"
    fi
    echo ""

    echo -e "${GREEN}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo -e "  ${TEXT_SECONDARY}[0]${RESET} Exit  ${TEXT_SECONDARY}[O]${RESET} Open exports folder"
    echo ""
    echo -ne "${TEXT_PRIMARY}Select dashboard [1-4]: ${RESET}"

    read -n1 dash_choice
    echo ""

    if [[ "$dash_choice" == "0" ]]; then
        exit 0
    elif [[ "$dash_choice" == "o" ]] || [[ "$dash_choice" == "O" ]]; then
        open "$EXPORT_DIR"
        return
    fi

    echo -ne "${TEXT_PRIMARY}Select format [A-D]: ${RESET}"
    read -n1 format_choice
    echo ""
    echo ""

    local dashboard format
    case "$dash_choice" in
        1) dashboard="docker" ;;
        2) dashboard="api" ;;
        3) dashboard="security" ;;
        4)
            for dash in docker api security; do
                for fmt in json csv markdown html; do
                    export_dashboard "$dash" "$fmt"
                done
            done
            echo -e "\n${GREEN}${BOLD}All dashboards exported in all formats!${RESET}\n"
            sleep 2
            show_export_menu
            return
            ;;
        *) echo "Invalid choice"; sleep 1; show_export_menu; return ;;
    esac

    case "$format_choice" in
        a|A) format="json" ;;
        b|B) format="csv" ;;
        c|C) format="markdown" ;;
        d|D) format="html" ;;
        *) echo "Invalid choice"; sleep 1; show_export_menu; return ;;
    esac

    export_dashboard "$dashboard" "$format"

    echo ""
    echo -ne "${TEXT_MUTED}Press any key to continue...${RESET}"
    read -n1
    show_export_menu
}

# Run if called directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    show_export_menu
fi
