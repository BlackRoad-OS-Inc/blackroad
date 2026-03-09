#!/bin/bash

# BlackRoad Dependency Notification System
# Subscribe to events and get notified when dependencies complete!

MEMORY_DIR="$HOME/.blackroad/memory"
DEPS_DIR="$MEMORY_DIR/dependencies"
SUBS_DIR="$DEPS_DIR/subscriptions"
EVENTS_DIR="$DEPS_DIR/events"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Initialize
init_deps() {
    mkdir -p "$DEPS_DIR" "$SUBS_DIR" "$EVENTS_DIR"
    echo -e "${GREEN}✅ Dependency notification system initialized!${NC}"
}

# Subscribe to an event
subscribe() {
    local event_name="$1"
    local subscriber="${2:-${MY_CLAUDE:-unknown}}"
    local notify_when="${3:-completed}"  # completed, started, updated, failed

    if [[ -z "$event_name" ]]; then
        echo -e "${RED}Usage: subscribe <event-name> [subscriber-id] [notify-when]${NC}"
        echo -e "${YELLOW}Example: subscribe api-deployment claude-frontend completed${NC}"
        return 1
    fi

    local sub_file="$SUBS_DIR/${event_name}__${subscriber}.json"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")

    cat > "$sub_file" << EOF
{
    "event_name": "$event_name",
    "subscriber": "$subscriber",
    "notify_when": "$notify_when",
    "subscribed_at": "$timestamp",
    "status": "active"
}
EOF

    ~/memory-system.sh log subscribed "$subscriber" "🔔 Subscribed to: $event_name (notify on: $notify_when)"

    echo -e "${GREEN}✅ Subscribed to: ${CYAN}$event_name${NC}"
    echo -e "   ${BLUE}Subscriber:${NC} $subscriber"
    echo -e "   ${BLUE}Notify when:${NC} $notify_when"
    echo -e "   ${YELLOW}💡 Publish event with:${NC} ./memory-dependency-notify.sh publish $event_name <status>"
}

# Unsubscribe from an event
unsubscribe() {
    local event_name="$1"
    local subscriber="${2:-${MY_CLAUDE:-unknown}}"

    local sub_file="$SUBS_DIR/${event_name}__${subscriber}.json"

    if [[ ! -f "$sub_file" ]]; then
        echo -e "${RED}❌ No subscription found for: $event_name by $subscriber${NC}"
        return 1
    fi

    rm "$sub_file"

    ~/memory-system.sh log unsubscribed "$subscriber" "🔕 Unsubscribed from: $event_name"

    echo -e "${GREEN}✅ Unsubscribed from: ${CYAN}$event_name${NC}"
}

# Publish an event (notify subscribers!)
publish() {
    local event_name="$1"
    local status="$2"  # started, completed, updated, failed
    local details="${3:-No details provided}"
    local publisher="${4:-${MY_CLAUDE:-unknown}}"

    if [[ -z "$event_name" || -z "$status" ]]; then
        echo -e "${RED}Usage: publish <event-name> <status> [details] [publisher-id]${NC}"
        echo -e "${YELLOW}Status: started|completed|updated|failed${NC}"
        return 1
    fi

    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")
    local event_file="$EVENTS_DIR/${event_name}__${timestamp}.json"

    cat > "$event_file" << EOF
{
    "event_name": "$event_name",
    "status": "$status",
    "details": "$details",
    "publisher": "$publisher",
    "published_at": "$timestamp"
}
EOF

    # Find and notify subscribers
    local notification_count=0

    for sub_file in "$SUBS_DIR/${event_name}__"*.json; do
        [[ ! -f "$sub_file" ]] && continue

        local subscriber=$(jq -r '.subscriber' "$sub_file")
        local notify_when=$(jq -r '.notify_when' "$sub_file")

        # Check if this status matches what subscriber wants
        if [[ "$notify_when" == "$status" || "$notify_when" == "any" ]]; then
            # Send notification via memory system
            ~/memory-system.sh log notification "$subscriber" "🔔 DEPENDENCY READY: $event_name is now $status! Details: $details (Published by: $publisher)"

            echo -e "${GREEN}📬 Notified: ${CYAN}$subscriber${NC}"
            ((notification_count++))
        fi
    done

    ~/memory-system.sh log event-published "$event_name" "📢 Event published: $status (Notified: $notification_count subscribers)"

    echo -e "${GREEN}✅ Event published: ${CYAN}$event_name${NC}"
    echo -e "   ${BLUE}Status:${NC} $status"
    echo -e "   ${BLUE}Publisher:${NC} $publisher"
    echo -e "   ${BLUE}Notifications sent:${NC} $notification_count"

    if [[ $notification_count -eq 0 ]]; then
        echo -e "   ${YELLOW}💡 No subscribers waiting for this event${NC}"
    fi
}

# List all subscriptions
list_subscriptions() {
    local filter_subscriber="$1"

    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║           🔔 Active Subscriptions 🔔                      ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    local sub_count=0

    for sub_file in "$SUBS_DIR"/*.json; do
        [[ ! -f "$sub_file" ]] && continue

        local event_name=$(jq -r '.event_name' "$sub_file")
        local subscriber=$(jq -r '.subscriber' "$sub_file")
        local notify_when=$(jq -r '.notify_when' "$sub_file")
        local subscribed_at=$(jq -r '.subscribed_at' "$sub_file")

        # Filter if specified
        if [[ -n "$filter_subscriber" && "$subscriber" != "$filter_subscriber" ]]; then
            continue
        fi

        echo -e "${CYAN}🔔 $event_name${NC}"
        echo -e "   ${BLUE}Subscriber:${NC} $subscriber"
        echo -e "   ${BLUE}Notify when:${NC} $notify_when"
        echo -e "   ${BLUE}Subscribed:${NC} $subscribed_at"
        echo ""

        ((sub_count++))
    done

    if [[ $sub_count -eq 0 ]]; then
        echo -e "${YELLOW}No active subscriptions${NC}"
    else
        echo -e "${GREEN}Total subscriptions: $sub_count${NC}"
    fi
}

# List recent events
list_events() {
    local limit="${1:-10}"

    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║           📢 Recent Events 📢                             ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    local event_count=0

    # Get most recent events
    for event_file in $(ls -t "$EVENTS_DIR"/*.json 2>/dev/null | head -n "$limit"); do
        local event_name=$(jq -r '.event_name' "$event_file")
        local status=$(jq -r '.status' "$event_file")
        local details=$(jq -r '.details' "$event_file")
        local publisher=$(jq -r '.publisher' "$event_file")
        local published_at=$(jq -r '.published_at' "$event_file")

        # Status color
        local status_color="$NC"
        case "$status" in
            completed) status_color="$GREEN" ;;
            started) status_color="$YELLOW" ;;
            failed) status_color="$RED" ;;
            updated) status_color="$BLUE" ;;
        esac

        echo -e "${CYAN}📢 $event_name${NC}"
        echo -e "   ${BLUE}Status:${NC} ${status_color}$status${NC}"
        echo -e "   ${BLUE}Publisher:${NC} $publisher"
        echo -e "   ${BLUE}Details:${NC} $details"
        echo -e "   ${BLUE}Published:${NC} $published_at"
        echo ""

        ((event_count++))
    done

    if [[ $event_count -eq 0 ]]; then
        echo -e "${YELLOW}No events published yet${NC}"
    fi
}

# Show my subscriptions
my_subscriptions() {
    local subscriber="${MY_CLAUDE:-unknown}"

    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║           🔔 My Subscriptions ($subscriber)               ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    list_subscriptions "$subscriber"
}

# Wait for an event (blocking)
wait_for() {
    local event_name="$1"
    local status="${2:-completed}"
    local timeout_seconds="${3:-300}"  # 5 minutes default

    echo -e "${YELLOW}⏳ Waiting for: ${CYAN}$event_name${NC} (status: $status, timeout: ${timeout_seconds}s)"

    local start_time=$(date +%s)
    local subscriber="${MY_CLAUDE:-wait-$$}"

    # Subscribe
    subscribe "$event_name" "$subscriber" "$status" > /dev/null

    # Poll for the event
    while true; do
        # Check if event was published
        for event_file in "$EVENTS_DIR/${event_name}__"*.json; do
            [[ ! -f "$event_file" ]] && continue

            local event_status=$(jq -r '.status' "$event_file")
            local published_at=$(jq -r '.published_at' "$event_file")

            if [[ "$event_status" == "$status" ]]; then
                echo -e "${GREEN}✅ Event received: $event_name is $status!${NC}"
                unsubscribe "$event_name" "$subscriber" > /dev/null
                return 0
            fi
        done

        # Check timeout
        local current_time=$(date +%s)
        local elapsed=$((current_time - start_time))

        if [[ $elapsed -ge $timeout_seconds ]]; then
            echo -e "${RED}⏱️ Timeout waiting for: $event_name${NC}"
            unsubscribe "$event_name" "$subscriber" > /dev/null
            return 1
        fi

        sleep 2
    done
}

# Show help
show_help() {
    cat << EOF
${CYAN}╔════════════════════════════════════════════════════════════╗${NC}
${CYAN}║    🔔 BlackRoad Dependency Notification System 🔔         ║${NC}
${CYAN}╚════════════════════════════════════════════════════════════╝${NC}

${GREEN}USAGE:${NC}
    $0 <command> [options]

${GREEN}COMMANDS:${NC}

${BLUE}init${NC}
    Initialize the dependency notification system

${BLUE}subscribe${NC} <event-name> [subscriber-id] [notify-when]
    Subscribe to an event
    notify-when: started|completed|updated|failed|any (default: completed)
    Example: subscribe api-deployment claude-frontend completed

${BLUE}unsubscribe${NC} <event-name> [subscriber-id]
    Unsubscribe from an event
    Example: unsubscribe api-deployment claude-frontend

${BLUE}publish${NC} <event-name> <status> [details] [publisher-id]
    Publish an event (notifies subscribers!)
    Status: started|completed|updated|failed
    Example: publish api-deployment completed "Deployed to api.blackroad.io"

${BLUE}list-subscriptions${NC} [subscriber-id]
    List active subscriptions
    Example: list-subscriptions claude-frontend

${BLUE}list-events${NC} [limit]
    List recent events (default: 10)
    Example: list-events 20

${BLUE}my-subscriptions${NC}
    Show subscriptions for current Claude (\$MY_CLAUDE)

${BLUE}wait-for${NC} <event-name> [status] [timeout-seconds]
    Block until event occurs (default: completed, 300s timeout)
    Example: wait-for api-deployment completed 600

${GREEN}WORKFLOW EXAMPLE:${NC}

    # Claude A (Frontend) needs API to be ready
    MY_CLAUDE=claude-frontend $0 subscribe api-deployment completed

    # Claude B (Backend) deploys API
    MY_CLAUDE=claude-backend $0 publish api-deployment started "Deploying..."
    # ... do deployment work ...
    MY_CLAUDE=claude-backend $0 publish api-deployment completed "API live at api.blackroad.io"

    # Claude A automatically gets notified! 🔔
    # Notification appears in [MEMORY] system

${GREEN}USE CASES:${NC}

    • Wait for API deployment before building frontend
    • Notify when database migration completes
    • Alert when CI/CD pipeline finishes
    • Coordinate multi-stage deployments
    • Async handoffs between Claudes

EOF
}

# Main command router
case "$1" in
    init)
        init_deps
        ;;
    subscribe)
        subscribe "$2" "$3" "$4"
        ;;
    unsubscribe)
        unsubscribe "$2" "$3"
        ;;
    publish)
        publish "$2" "$3" "$4" "$5"
        ;;
    list-subscriptions)
        list_subscriptions "$2"
        ;;
    list-events)
        list_events "$2"
        ;;
    my-subscriptions)
        my_subscriptions
        ;;
    wait-for)
        wait_for "$2" "$3" "$4"
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo -e "${RED}Unknown command: $1${NC}"
        echo -e "Run ${CYAN}$0 help${NC} for usage information"
        exit 1
        ;;
esac
