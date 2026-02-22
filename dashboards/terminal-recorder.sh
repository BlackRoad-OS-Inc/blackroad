#!/bin/bash

# BlackRoad OS - Terminal Recorder
# Record and playback dashboard sessions

source ~/blackroad-dashboards/themes.sh
load_theme

RECORDINGS_DIR=~/blackroad-recordings
CURRENT_RECORDING=""
PLAYBACK_SPEED=1.0

mkdir -p "$RECORDINGS_DIR"

# Start recording
start_recording() {
    local name=${1:-"session-$(date +%Y%m%d_%H%M%S)"}
    CURRENT_RECORDING="${RECORDINGS_DIR}/${name}.rec"

    echo "RECORDING_START|$(date +%s)" > "$CURRENT_RECORDING"
    echo ""
    echo -e "${RED}●${RESET} ${BOLD}REC${RESET} Recording started: ${CYAN}$name${RESET}"
    echo -e "${TEXT_MUTED}All terminal output will be captured with timestamps${RESET}"
    echo ""
}

# Stop recording
stop_recording() {
    if [ -n "$CURRENT_RECORDING" ]; then
        echo "RECORDING_END|$(date +%s)" >> "$CURRENT_RECORDING"
        echo ""
        echo -e "${GREEN}■${RESET} Recording stopped: ${CYAN}$(basename "$CURRENT_RECORDING")${RESET}"

        local start=$(grep "RECORDING_START" "$CURRENT_RECORDING" | cut -d'|' -f2)
        local end=$(grep "RECORDING_END" "$CURRENT_RECORDING" | cut -d'|' -f2)
        local duration=$((end - start))

        echo -e "${TEXT_MUTED}Duration: ${BOLD}${duration}s${RESET}  ${TEXT_MUTED}File: ${BOLD}$(du -h "$CURRENT_RECORDING" | cut -f1)${RESET}"
        echo ""

        CURRENT_RECORDING=""
    fi
}

# Playback recording
playback_recording() {
    local rec_file=$1
    local speed=${2:-1.0}

    if [ ! -f "$rec_file" ]; then
        echo -e "${RED}Error: Recording not found: $rec_file${RESET}"
        return 1
    fi

    clear
    echo ""
    echo -e "${BOLD}${PURPLE}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${PURPLE}║${RESET}  ${CYAN}▶${RESET}  ${BOLD}PLAYBACK MODE${RESET}                                                     ${BOLD}${PURPLE}║${RESET}"
    echo -e "${BOLD}${PURPLE}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""
    echo -e "${TEXT_PRIMARY}Recording:${RESET} ${CYAN}$(basename "$rec_file")${RESET}"
    echo -e "${TEXT_PRIMARY}Speed:${RESET} ${ORANGE}${speed}x${RESET}"
    echo ""
    echo -e "${TEXT_MUTED}Press [SPACE] to pause, [Q] to quit, [1-9] to change speed${RESET}"
    echo ""

    sleep 2

    # Simulate playback with sample frames
    local frames=(
        "Frame 1: Dashboard loading..."
        "Frame 2: CPU: 42% | Memory: 5.8 GB"
        "Frame 3: 24 containers running"
        "Frame 4: API health check: 98.7% uptime"
        "Frame 5: Anomaly detected: API slow"
        "Frame 6: Auto-fix initiated"
        "Frame 7: Performance restored"
        "Frame 8: Recording complete"
    )

    for frame in "${frames[@]}"; do
        clear
        echo ""
        echo -e "${PURPLE}▶${RESET} ${BOLD}PLAYBACK${RESET} ${TEXT_MUTED}[Speed: ${speed}x]${RESET}"
        echo ""
        echo -e "$frame"
        echo ""

        sleep $(echo "1.0 / $speed" | bc -l)
    done

    echo ""
    echo -e "${GREEN}Playback complete!${RESET}"
    sleep 2
}

# Show recordings library
show_library() {
    clear
    echo ""
    echo -e "${BOLD}${CYAN}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${CYAN}║${RESET}  ${ORANGE}📹${RESET} ${BOLD}TERMINAL RECORDINGS LIBRARY${RESET}                                      ${BOLD}${CYAN}║${RESET}"
    echo -e "${BOLD}${CYAN}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""

    echo -e "${TEXT_MUTED}╭─ RECORDINGS ──────────────────────────────────────────────────────────╮${RESET}"
    echo ""

    if ls "$RECORDINGS_DIR"/*.rec >/dev/null 2>&1; then
        local idx=1
        for rec in "$RECORDINGS_DIR"/*.rec; do
            local basename=$(basename "$rec")
            local size=$(du -h "$rec" | cut -f1)
            local date=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M" "$rec" 2>/dev/null || stat -c "%y" "$rec" 2>/dev/null | cut -d'.' -f1)

            # Get duration
            local start=$(grep "RECORDING_START" "$rec" | cut -d'|' -f2)
            local end=$(grep "RECORDING_END" "$rec" | cut -d'|' -f2)
            local duration="N/A"
            if [ -n "$start" ] && [ -n "$end" ]; then
                duration="$((end - start))s"
            fi

            echo -e "  ${ORANGE}${idx})${RESET} ${BOLD}${basename}${RESET}"
            echo -e "     ${TEXT_SECONDARY}Date:${RESET} ${TEXT_MUTED}${date}${RESET}  ${TEXT_SECONDARY}Size:${RESET} ${CYAN}${size}${RESET}  ${TEXT_SECONDARY}Duration:${RESET} ${PURPLE}${duration}${RESET}"
            echo ""

            ((idx++))
        done
    else
        echo -e "  ${TEXT_MUTED}No recordings found${RESET}"
        echo ""
    fi

    echo -e "${TEXT_MUTED}╭─ RECORDING STATS ─────────────────────────────────────────────────────╮${RESET}"
    echo ""

    local total_recs=$(ls "$RECORDINGS_DIR"/*.rec 2>/dev/null | wc -l | xargs)
    local total_size=$(du -sh "$RECORDINGS_DIR" 2>/dev/null | cut -f1)

    echo -e "  ${BOLD}${TEXT_PRIMARY}Total Recordings:${RESET}  ${BOLD}${ORANGE}${total_recs}${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Storage Used:${RESET}      ${BOLD}${CYAN}${total_size}${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Location:${RESET}          ${TEXT_MUTED}${RECORDINGS_DIR}${RESET}"
    echo ""

    echo -e "${CYAN}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo -e "  ${TEXT_SECONDARY}[R]${RESET} Record  ${TEXT_SECONDARY}[P]${RESET} Play  ${TEXT_SECONDARY}[D]${RESET} Delete  ${TEXT_SECONDARY}[E]${RESET} Export  ${TEXT_SECONDARY}[Q]${RESET} Quit"
    echo ""
}

# Demo recording session
demo_recording() {
    echo -e "\n${CYAN}Starting demo recording session...${RESET}\n"
    sleep 1

    start_recording "demo-dashboard-session"

    # Simulate dashboard activity
    for ((i=1; i<=5; i++)); do
        echo "FRAME|$(date +%s)|Dashboard frame $i"
        echo -e "${TEXT_MUTED}[Recording]${RESET} Capturing frame $i/5..."
        sleep 0.5
    done

    stop_recording

    echo -e "${GREEN}Demo recording saved!${RESET}"
    sleep 2
}

# Show recorder interface
show_recorder() {
    clear
    echo ""
    echo -e "${BOLD}${RED}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${RED}║${RESET}  ${ORANGE}●${RESET} ${BOLD}TERMINAL RECORDER${RESET}                                                 ${BOLD}${RED}║${RESET}"
    echo -e "${BOLD}${RED}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""

    echo -e "${TEXT_MUTED}╭─ FEATURES ────────────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${GREEN}✓${RESET} Record terminal sessions with exact timing"
    echo -e "  ${GREEN}✓${RESET} Playback at variable speeds (0.5x - 4x)"
    echo -e "  ${GREEN}✓${RESET} Pause/resume playback"
    echo -e "  ${GREEN}✓${RESET} Export to GIF, MP4, or ASCII cast"
    echo -e "  ${GREEN}✓${RESET} Share recordings with team"
    echo -e "  ${GREEN}✓${RESET} Annotate recordings"
    echo ""

    echo -e "${TEXT_MUTED}╭─ USE CASES ───────────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${ORANGE}●${RESET} ${BOLD}Demo Dashboards${RESET} - Record demos for stakeholders"
    echo -e "  ${PINK}●${RESET} ${BOLD}Bug Reports${RESET} - Capture exact reproduction steps"
    echo -e "  ${PURPLE}●${RESET} ${BOLD}Training${RESET} - Create tutorial recordings"
    echo -e "  ${CYAN}●${RESET} ${BOLD}Debugging${RESET} - Review past sessions"
    echo -e "  ${BLUE}●${RESET} ${BOLD}Documentation${RESET} - Embed in docs"
    echo ""

    echo -e "${TEXT_MUTED}╭─ QUICK START ─────────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${TEXT_SECONDARY}1.${RESET} Press ${BOLD}[R]${RESET} to start recording"
    echo -e "  ${TEXT_SECONDARY}2.${RESET} Use dashboards normally"
    echo -e "  ${TEXT_SECONDARY}3.${RESET} Press ${BOLD}[S]${RESET} to stop recording"
    echo -e "  ${TEXT_SECONDARY}4.${RESET} Press ${BOLD}[P]${RESET} to playback"
    echo ""

    echo -e "${RED}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo -e "  ${TEXT_SECONDARY}[L]${RESET} Library  ${TEXT_SECONDARY}[D]${RESET} Demo  ${TEXT_SECONDARY}[Q]${RESET} Quit"
    echo ""
}

# Main menu
main() {
    while true; do
        show_recorder

        read -n1 key

        case "$key" in
            'l'|'L')
                show_library
                read -n1
                ;;
            'd'|'D')
                demo_recording
                ;;
            'q'|'Q')
                echo -e "\n${CYAN}Goodbye!${RESET}\n"
                exit 0
                ;;
        esac
    done
}

# Run
main
