#!/bin/bash

# BlackRoad OS - Notification Center
# Centralized notification hub for all dashboards

source ~/blackroad-dashboards/themes.sh
load_theme

NOTIFICATIONS_FILE=~/blackroad-dashboards/.notifications
NOTIFICATION_SETTINGS=~/blackroad-dashboards/.notification_settings

touch "$NOTIFICATIONS_FILE" "$NOTIFICATION_SETTINGS"

# Initialize default settings
if [ ! -s "$NOTIFICATION_SETTINGS" ]; then
    cat > "$NOTIFICATION_SETTINGS" <<EOF
sound_enabled=true
desktop_enabled=true
priority_filter=all
max_notifications=100
EOF
fi

# Add notification
add_notification() {
    local priority=$1
    local category=$2
    local title=$3
    local message=$4

    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local id=$(date +%s%N | md5sum | cut -c1-8)

    echo "$id|$timestamp|$priority|$category|$title|$message|unread" >> "$NOTIFICATIONS_FILE"

    # Play sound if enabled
    if grep -q "sound_enabled=true" "$NOTIFICATION_SETTINGS"; then
        case "$priority" in
            critical) echo -e "\a\a" ;;
            high) echo -e "\a" ;;
        esac
    fi

    # Desktop notification (macOS)
    if grep -q "desktop_enabled=true" "$NOTIFICATION_SETTINGS" && [[ "$OSTYPE" == "darwin"* ]]; then
        osascript -e "display notification \"$message\" with title \"$title\"" 2>/dev/null
    fi
}

# Mark as read
mark_as_read() {
    local notif_id=$1
    sed -i '' "s/^$notif_id|\\(.*\\)|unread$/$notif_id|\\1|read/" "$NOTIFICATIONS_FILE" 2>/dev/null
}

# Mark all as read
mark_all_read() {
    sed -i '' 's/|unread$/|read/' "$NOTIFICATIONS_FILE" 2>/dev/null
}

# Clear all notifications
clear_all() {
    > "$NOTIFICATIONS_FILE"
}

# Show notification center
show_notification_center() {
    clear
    echo ""
    echo -e "${BOLD}${BLUE}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${BLUE}║${RESET}  ${YELLOW}🔔${RESET} ${BOLD}NOTIFICATION CENTER${RESET}                                              ${BOLD}${BLUE}║${RESET}"
    echo -e "${BOLD}${BLUE}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""

    # Stats
    local total=$(wc -l < "$NOTIFICATIONS_FILE" 2>/dev/null || echo 0)
    local unread=$(grep -c "|unread$" "$NOTIFICATIONS_FILE" 2>/dev/null || echo 0)
    local critical=$(grep -c "|critical|" "$NOTIFICATIONS_FILE" 2>/dev/null || echo 0)

    echo -e "${TEXT_MUTED}╭─ OVERVIEW ────────────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${BOLD}${TEXT_PRIMARY}Total:${RESET}      ${BOLD}${CYAN}${total}${RESET} notifications"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Unread:${RESET}     ${BOLD}${ORANGE}${unread}${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Critical:${RESET}   ${BOLD}${RED}${critical}${RESET}"
    echo ""

    # Notifications list
    echo -e "${TEXT_MUTED}╭─ NOTIFICATIONS ───────────────────────────────────────────────────────╮${RESET}"
    echo ""

    if [ "$total" -gt 0 ]; then
        tail -20 "$NOTIFICATIONS_FILE" | tac | while IFS='|' read -r id timestamp priority category title message status; do
            local icon
            local color

            # Priority icon and color
            case "$priority" in
                critical)
                    icon="${RED}🚨${RESET}"
                    color="${RED}"
                    ;;
                high)
                    icon="${ORANGE}⚠️${RESET}"
                    color="${ORANGE}"
                    ;;
                medium)
                    icon="${YELLOW}ℹ️${RESET}"
                    color="${YELLOW}"
                    ;;
                low)
                    icon="${CYAN}·${RESET}"
                    color="${CYAN}"
                    ;;
            esac

            # Read status
            local read_marker=""
            if [ "$status" = "unread" ]; then
                read_marker=" ${BOLD}${BLUE}●${RESET}"
            fi

            echo -e "  $icon ${color}${BOLD}$title${RESET}$read_marker"
            echo -e "     ${TEXT_MUTED}$timestamp${RESET}  ${TEXT_SECONDARY}$category${RESET}"
            echo -e "     ${TEXT_MUTED}$message${RESET}"
            echo ""
        done
    else
        echo -e "  ${TEXT_MUTED}No notifications${RESET}"
        echo ""
    fi

    # Categories breakdown
    echo -e "${TEXT_MUTED}╭─ BY CATEGORY ─────────────────────────────────────────────────────────╮${RESET}"
    echo ""

    declare -A categories
    while IFS='|' read -r id timestamp priority category title message status; do
        categories[$category]=$((${categories[$category]:-0} + 1))
    done < "$NOTIFICATIONS_FILE"

    if [ ${#categories[@]} -gt 0 ]; then
        for category in "${!categories[@]}"; do
            local count=${categories[$category]}
            echo -e "  ${PURPLE}●${RESET} ${BOLD}$category${RESET}  ${TEXT_MUTED}($count)${RESET}"
        done
    else
        echo -e "  ${TEXT_MUTED}No categories${RESET}"
    fi
    echo ""

    # Settings
    echo -e "${TEXT_MUTED}╭─ SETTINGS ────────────────────────────────────────────────────────────╮${RESET}"
    echo ""

    local sound=$(grep "sound_enabled=" "$NOTIFICATION_SETTINGS" | cut -d'=' -f2)
    local desktop=$(grep "desktop_enabled=" "$NOTIFICATION_SETTINGS" | cut -d'=' -f2)

    echo -e "  ${BOLD}${TEXT_PRIMARY}Sound Alerts:${RESET}       $([ "$sound" = "true" ] && echo "${GREEN}ON${RESET}" || echo "${RED}OFF${RESET}")"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Desktop Alerts:${RESET}     $([ "$desktop" = "true" ] && echo "${GREEN}ON${RESET}" || echo "${RED}OFF${RESET}")"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Priority Filter:${RESET}    ${CYAN}All${RESET}"
    echo ""

    echo -e "${BLUE}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo -e "  ${TEXT_SECONDARY}[T]${RESET} Test  ${TEXT_SECONDARY}[M]${RESET} Mark all read  ${TEXT_SECONDARY}[C]${RESET} Clear  ${TEXT_SECONDARY}[S]${RESET} Settings  ${TEXT_SECONDARY}[Q]${RESET} Quit"
    echo ""
}

# Send test notifications
send_test_notifications() {
    echo -e "\n${CYAN}Sending test notifications...${RESET}\n"

    add_notification "critical" "system" "Critical Alert" "CPU usage exceeded 90%"
    sleep 0.5
    add_notification "high" "security" "Security Warning" "Failed login attempt detected"
    sleep 0.5
    add_notification "medium" "api" "API Status" "Response time increased to 234ms"
    sleep 0.5
    add_notification "low" "info" "System Update" "New dashboard features available"

    echo -e "${GREEN}✓ Test notifications sent!${RESET}"
    sleep 2
}

# Settings menu
show_settings() {
    clear
    echo ""
    echo -e "${BOLD}${CYAN}NOTIFICATION SETTINGS${RESET}"
    echo ""

    local sound=$(grep "sound_enabled=" "$NOTIFICATION_SETTINGS" | cut -d'=' -f2)
    local desktop=$(grep "desktop_enabled=" "$NOTIFICATION_SETTINGS" | cut -d'=' -f2)

    echo -e "  ${ORANGE}1)${RESET} Sound Alerts:     $([ "$sound" = "true" ] && echo "${GREEN}ON${RESET}" || echo "${RED}OFF${RESET}")"
    echo -e "  ${PINK}2)${RESET} Desktop Alerts:   $([ "$desktop" = "true" ] && echo "${GREEN}ON${RESET}" || echo "${RED}OFF${RESET}")"
    echo -e "  ${PURPLE}3)${RESET} Priority Filter:  ${CYAN}All${RESET}"
    echo ""
    echo -ne "${TEXT_PRIMARY}Toggle setting (1-3) or press Enter to return: ${RESET}"

    read -n1 choice
    echo ""

    case "$choice" in
        1)
            if [ "$sound" = "true" ]; then
                sed -i '' 's/sound_enabled=true/sound_enabled=false/' "$NOTIFICATION_SETTINGS"
            else
                sed -i '' 's/sound_enabled=false/sound_enabled=true/' "$NOTIFICATION_SETTINGS"
            fi
            ;;
        2)
            if [ "$desktop" = "true" ]; then
                sed -i '' 's/desktop_enabled=true/desktop_enabled=false/' "$NOTIFICATION_SETTINGS"
            else
                sed -i '' 's/desktop_enabled=false/desktop_enabled=true/' "$NOTIFICATION_SETTINGS"
            fi
            ;;
    esac
}

# Main loop
main() {
    # Add some sample notifications
    if [ ! -s "$NOTIFICATIONS_FILE" ]; then
        add_notification "medium" "system" "Welcome" "Notification Center initialized"
        add_notification "low" "info" "Dashboard Ready" "All systems operational"
    fi

    while true; do
        show_notification_center

        read -n1 key

        case "$key" in
            't'|'T')
                send_test_notifications
                ;;
            'm'|'M')
                mark_all_read
                echo -e "\n${GREEN}All notifications marked as read${RESET}"
                sleep 1
                ;;
            'c'|'C')
                clear_all
                echo -e "\n${GREEN}All notifications cleared${RESET}"
                sleep 1
                ;;
            's'|'S')
                show_settings
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
