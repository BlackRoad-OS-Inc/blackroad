#!/bin/bash

# BlackRoad OS - Sound Effects System
# Add audio feedback to dashboard interactions

# Sound library (using afplay on macOS, or beep sequences)
play_sound() {
    local sound=$1

    case "$sound" in
        "startup")
            # Startup chime
            for freq in 440 554 659 880; do
                ( speaker-test -t sine -f $freq >/dev/null 2>&1 ) & pid=$!
                sleep 0.1
                kill -9 $pid 2>/dev/null
            done
            ;;
        "success")
            # Success ding
            echo -e "\a"
            ;;
        "error")
            # Error buzz
            echo -e "\a\a"
            ;;
        "warning")
            # Warning beep
            echo -e "\a"
            sleep 0.1
            echo -e "\a"
            ;;
        "notification")
            # Notification chime
            echo -e "\a"
            ;;
        "click")
            # Click sound
            printf "\e[10;500]\e[11;100]\a"
            ;;
        "navigation")
            # Navigation blip
            printf "\a"
            ;;
        "deploy")
            # Deploy rocket sound
            for i in {1..5}; do
                echo -ne "\a"
                sleep 0.05
            done
            ;;
        "alert")
            # Alert siren
            for i in {1..3}; do
                echo -ne "\a"
                sleep 0.2
            done
            ;;
        *)
            echo -e "\a"
            ;;
    esac
}

# Sound effects manager
show_sound_demo() {
    clear
    echo ""
    echo -e "${BOLD}${PURPLE}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${PURPLE}║${RESET}  ${CYAN}🔊${RESET} ${BOLD}SOUND EFFECTS SYSTEM${RESET}                                              ${BOLD}${PURPLE}║${RESET}"
    echo -e "${BOLD}${PURPLE}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""

    echo "  ${TEXT_PRIMARY}Press number to play sound:${RESET}"
    echo ""
    echo "  ${ORANGE}1)${RESET} Startup Chime"
    echo "  ${PINK}2)${RESET} Success Ding ✓"
    echo "  ${RED}3)${RESET} Error Buzz ✗"
    echo "  ${YELLOW}4)${RESET} Warning Beep ⚠"
    echo "  ${CYAN}5)${RESET} Notification"
    echo "  ${GREEN}6)${RESET} Click"
    echo "  ${BLUE}7)${RESET} Navigation Blip"
    echo "  ${PURPLE}8)${RESET} Deploy Rocket 🚀"
    echo "  ${ORANGE}9)${RESET} Alert Siren 🚨"
    echo ""
    echo "  ${TEXT_MUTED}0)${RESET} Exit"
    echo ""
    echo -e "${PURPLE}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo -ne "${TEXT_PRIMARY}Select [1-9]: ${RESET}"

    read -n1 choice
    echo ""

    case "$choice" in
        1)
            echo -e "${ORANGE}Playing startup chime...${RESET}"
            play_sound "startup"
            ;;
        2)
            echo -e "${PINK}Playing success sound...${RESET}"
            play_sound "success"
            ;;
        3)
            echo -e "${RED}Playing error sound...${RESET}"
            play_sound "error"
            ;;
        4)
            echo -e "${YELLOW}Playing warning sound...${RESET}"
            play_sound "warning"
            ;;
        5)
            echo -e "${CYAN}Playing notification...${RESET}"
            play_sound "notification"
            ;;
        6)
            echo -e "${GREEN}Playing click...${RESET}"
            play_sound "click"
            ;;
        7)
            echo -e "${BLUE}Playing navigation blip...${RESET}"
            play_sound "navigation"
            ;;
        8)
            echo -e "${PURPLE}Playing deploy sound...${RESET}"
            play_sound "deploy"
            ;;
        9)
            echo -e "${ORANGE}Playing alert siren...${RESET}"
            play_sound "alert"
            ;;
        0)
            exit 0
            ;;
    esac

    sleep 1
    show_sound_demo
}

# Event listener (integrates with dashboards)
listen_for_events() {
    local events_file=$1

    if [ ! -f "$events_file" ]; then
        return
    fi

    tail -f "$events_file" | while read -r event; do
        case "$event" in
            "deploy:success")
                play_sound "success"
                ;;
            "deploy:failed")
                play_sound "error"
                ;;
            "container:started")
                play_sound "startup"
                ;;
            "container:stopped")
                play_sound "warning"
                ;;
            "alert:critical")
                play_sound "alert"
                ;;
            "alert:warning")
                play_sound "warning"
                ;;
            "navigation")
                play_sound "navigation"
                ;;
            "click")
                play_sound "click"
                ;;
        esac
    done
}

# If run directly, show demo
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    show_sound_demo
fi
