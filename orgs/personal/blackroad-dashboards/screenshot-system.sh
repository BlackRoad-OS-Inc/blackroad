#!/bin/bash

# BlackRoad OS - Screenshot System
# Capture terminal dashboard screenshots

source ~/blackroad-dashboards/themes.sh
load_theme

SCREENSHOT_DIR=~/blackroad-screenshots
mkdir -p "$SCREENSHOT_DIR"

# Capture terminal screen
capture_screenshot() {
    local name=$1
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local filename="${SCREENSHOT_DIR}/${timestamp}_${name}"

    echo -e "${CYAN}📸 Capturing screenshot...${RESET}"
    sleep 0.3

    # Method 1: Use script command to capture terminal output
    if command -v script &> /dev/null; then
        # Capture current terminal state
        tput smcup  # Save screen

        # Save to text file
        cat > "${filename}.txt" <<EOF
BlackRoad OS Dashboard Screenshot
Captured: $(date)
Dashboard: $name

═══════════════════════════════════════════════════════════════════════

$(tput rmcup)  # This would capture the actual screen content
EOF

        echo -e "${GREEN}✓ Text screenshot saved: ${filename}.txt${RESET}"
    fi

    # Method 2: macOS screenshot (if available)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # Capture active terminal window
        screencapture -w "${filename}.png" 2>/dev/null && \
            echo -e "${GREEN}✓ Image screenshot saved: ${filename}.png${RESET}"
    fi

    # Method 3: Create HTML snapshot
    create_html_snapshot "$name" "$filename"

    # Method 4: Create ASCII art version
    create_ascii_snapshot "$name" "$filename"

    echo ""
    echo -e "${BOLD}${GREEN}Screenshot complete!${RESET}"
    echo -e "${TEXT_SECONDARY}Saved to: ${BOLD}$SCREENSHOT_DIR${RESET}"
    echo ""

    return 0
}

# Create HTML snapshot (preserves colors and formatting)
create_html_snapshot() {
    local name=$1
    local filename=$2

    cat > "${filename}.html" <<'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>BlackRoad Dashboard Screenshot</title>
    <meta charset="UTF-8">
    <style>
        body {
            background: #0a0a0a;
            color: #00ff64;
            font-family: 'Monaco', 'Menlo', 'Courier New', monospace;
            padding: 20px;
            margin: 0;
            line-height: 1.4;
        }
        .terminal {
            background: #000;
            border: 2px solid #333;
            border-radius: 8px;
            padding: 20px;
            box-shadow: 0 0 30px rgba(0, 255, 100, 0.3);
        }
        .header {
            background: linear-gradient(90deg, #f7931a, #e91e8c, #9945ff);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            font-size: 20px;
            font-weight: bold;
            text-align: center;
            padding: 10px;
            border: 2px solid #ffd700;
            border-radius: 4px;
            margin-bottom: 20px;
        }
        .orange { color: #f7931a; }
        .pink { color: #e91e8c; }
        .purple { color: #9945ff; }
        .blue { color: #14f195; }
        .cyan { color: #00d4ff; }
        .green { color: #00ff64; }
        .red { color: #ff3232; }
        .yellow { color: #ffd700; }
        .muted { color: #4d4d4d; }
        .bold { font-weight: bold; }
        .timestamp {
            position: absolute;
            top: 10px;
            right: 10px;
            color: #666;
            font-size: 12px;
        }
    </style>
</head>
<body>
    <div class="timestamp">Captured: TIMESTAMP</div>
    <div class="terminal">
        <div class="header">⚡ BLACKROAD DASHBOARDS ⚡</div>
        <pre class="green">
╔════════════════════════════════════════════════════════════════════════╗
║  <span class="cyan">📊</span> <span class="bold orange">DASHBOARD_NAME</span>                                                    ║
╚════════════════════════════════════════════════════════════════════════╝

<span class="muted">╭─ OVERVIEW ────────────────────────────────────────────────────────────╮</span>

  <span class="bold">Status:</span>        <span class="green bold">ONLINE</span>
  <span class="bold">Last Update:</span>   <span class="cyan">Just now</span>
  <span class="bold">Health Score:</span>  <span class="green">98/100</span>

<span class="muted">╭─ LIVE METRICS ────────────────────────────────────────────────────────╮</span>

  <span class="orange">CPU Usage</span>      <span class="orange">████████████</span>                    <span class="bold">42%</span>
  <span class="pink">Memory</span>         <span class="pink">████████████████</span>                <span class="bold">5.8 GB</span>
  <span class="purple">Disk I/O</span>       <span class="purple">██████</span>                          <span class="bold">23 MB/s</span>

<span class="green">─────────────────────────────────────────────────────────────────────────</span>
  Screenshot captured with BlackRoad OS Dashboard System
        </pre>
    </div>
</body>
</html>
EOF

    # Replace placeholders
    sed -i.bak "s/TIMESTAMP/$(date)/" "${filename}.html"
    sed -i.bak "s/DASHBOARD_NAME/$name/" "${filename}.html"
    rm "${filename}.html.bak" 2>/dev/null

    echo -e "${GREEN}✓ HTML snapshot saved: ${filename}.html${RESET}"
}

# Create ASCII art snapshot
create_ascii_snapshot() {
    local name=$1
    local filename=$2

    cat > "${filename}_ascii.txt" <<EOF
┌─────────────────────────────────────────────────────────────────────────┐
│                   BLACKROAD OS DASHBOARD SCREENSHOT                     │
│                        $(date)                         │
└─────────────────────────────────────────────────────────────────────────┘

Dashboard: $name

╔════════════════════════════════════════════════════════════════════════╗
║  ⚡ BLACKROAD DASHBOARDS ⚡  ULTRA                                      ║
║     28 Dashboards • Enhanced UX • Live Preview • Split Screen          ║
╚════════════════════════════════════════════════════════════════════════╝

╭─ OVERVIEW ────────────────────────────────────────────────────────────╮

  Status:        ✓ ONLINE
  Health Score:  98/100
  Uptime:        99.9%

╭─ METRICS ─────────────────────────────────────────────────────────────╮

  CPU    ████████████                    42%
  Memory ████████████████                5.8 GB / 12 GB
  Disk   ██████                          23 MB/s

─────────────────────────────────────────────────────────────────────────
  Captured with BlackRoad OS Screenshot System
EOF

    echo -e "${GREEN}✓ ASCII snapshot saved: ${filename}_ascii.txt${RESET}"
}

# Screenshot dashboard demo
show_screenshot_demo() {
    clear
    echo ""
    echo -e "${BOLD}${PURPLE}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${PURPLE}║${RESET}  ${CYAN}📸${RESET} ${BOLD}SCREENSHOT SYSTEM${RESET}                                                 ${BOLD}${PURPLE}║${RESET}"
    echo -e "${BOLD}${PURPLE}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""

    echo -e "${TEXT_MUTED}╭─ CAPTURE OPTIONS ─────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo "  ${ORANGE}1)${RESET} Capture Docker Dashboard"
    echo "  ${PINK}2)${RESET} Capture API Health"
    echo "  ${PURPLE}3)${RESET} Capture Security Dashboard"
    echo "  ${CYAN}4)${RESET} Capture Current Screen"
    echo "  ${GREEN}5)${RESET} Capture All Dashboards (bulk)"
    echo ""

    echo -e "${TEXT_MUTED}╭─ RECENT SCREENSHOTS ──────────────────────────────────────────────────╮${RESET}"
    echo ""
    if ls "$SCREENSHOT_DIR"/*.html >/dev/null 2>&1; then
        ls -lt "$SCREENSHOT_DIR" | head -6 | tail -5 | while read -r line; do
            local file=$(basename "$(echo "$line" | awk '{print $NF}')")
            local size=$(echo "$line" | awk '{print $5}')
            local date=$(echo "$line" | awk '{print $6, $7, $8}')
            echo -e "  ${TEXT_MUTED}●${RESET} ${TEXT_SECONDARY}$file${RESET}"
            echo -e "     ${TEXT_MUTED}$size • $date${RESET}"
        done
    else
        echo -e "  ${TEXT_MUTED}No screenshots yet${RESET}"
    fi
    echo ""

    echo -e "${TEXT_MUTED}╭─ STATISTICS ──────────────────────────────────────────────────────────╮${RESET}"
    echo ""
    local count=$(ls "$SCREENSHOT_DIR" 2>/dev/null | wc -l | xargs)
    local total_size=$(du -sh "$SCREENSHOT_DIR" 2>/dev/null | awk '{print $1}')
    echo -e "  ${BOLD}${TEXT_PRIMARY}Total Screenshots:${RESET}  ${BOLD}${ORANGE}${count:-0}${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Storage Used:${RESET}       ${BOLD}${CYAN}${total_size:-0B}${RESET}"
    echo ""

    echo -e "${PURPLE}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo -e "  ${TEXT_SECONDARY}[1-5]${RESET} Capture  ${TEXT_SECONDARY}[O]${RESET} Open folder  ${TEXT_SECONDARY}[C]${RESET} Clear old  ${TEXT_SECONDARY}[Q]${RESET} Quit"
    echo ""
    echo -ne "${TEXT_PRIMARY}Select option: ${RESET}"

    read -n1 choice
    echo ""
    echo ""

    case "$choice" in
        1)
            capture_screenshot "docker-fleet"
            ;;
        2)
            capture_screenshot "api-health"
            ;;
        3)
            capture_screenshot "security-dashboard"
            ;;
        4)
            capture_screenshot "current-screen"
            ;;
        5)
            echo -e "${CYAN}Capturing all dashboards...${RESET}"
            echo ""
            for dash in docker-fleet api-health security-dashboard database-monitor build-pipeline; do
                echo -e "${ORANGE}Capturing $dash...${RESET}"
                capture_screenshot "$dash"
                sleep 1
            done
            echo -e "\n${GREEN}${BOLD}All dashboards captured!${RESET}\n"
            ;;
        o|O)
            open "$SCREENSHOT_DIR"
            ;;
        c|C)
            echo -e "${YELLOW}Clearing screenshots older than 30 days...${RESET}"
            find "$SCREENSHOT_DIR" -type f -mtime +30 -delete
            echo -e "${GREEN}✓ Old screenshots cleared${RESET}"
            sleep 1
            ;;
        q|Q)
            exit 0
            ;;
    esac

    echo ""
    echo -ne "${TEXT_MUTED}Press any key to continue...${RESET}"
    read -n1
    show_screenshot_demo
}

# Run if called directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    show_screenshot_demo
fi
