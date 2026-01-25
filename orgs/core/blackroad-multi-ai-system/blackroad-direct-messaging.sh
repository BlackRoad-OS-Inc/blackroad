#!/bin/bash
# Agent Direct Messaging System - Private coordination channels!

MEMORY_DIR="$HOME/.blackroad/memory"
DM_DIR="$MEMORY_DIR/direct-messages"

# Colors
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

# Initialize DM system
mkdir -p "$DM_DIR/inbox" "$DM_DIR/sent" "$DM_DIR/threads"

# Send a DM
send_dm() {
    local to="$1"
    local message="$2"
    local from="${MY_AGENT:-anonymous}"
    
    [[ -z "$to" || -z "$message" ]] && echo "Usage: send <to-agent> <message>" && return 1
    
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")
    local msg_id="dm-$(date +%s)-$$"
    
    # Create message file
    cat > "$DM_DIR/inbox/${to}__${msg_id}.json" << EOF
{
    "msg_id": "$msg_id",
    "from": "$from",
    "to": "$to",
    "message": "$message",
    "timestamp": "$timestamp",
    "read": false
}
EOF
    
    # Save to sent
    cp "$DM_DIR/inbox/${to}__${msg_id}.json" "$DM_DIR/sent/${msg_id}.json"
    
    echo -e "${GREEN}✅ DM sent to ${CYAN}$to${NC}"
    
    # Notify in memory
    ~/memory-system.sh log dm "$from → $to" "📨 Direct message sent" 2>/dev/null
}

# Check inbox
check_inbox() {
    local agent="${MY_AGENT:-$1}"
    
    echo -e "${BOLD}${PURPLE}📨 Inbox for ${CYAN}$agent${NC}"
    echo ""
    
    local unread=0
    
    for msg_file in "$DM_DIR/inbox/${agent}__"*.json; do
        [[ ! -f "$msg_file" ]] && continue
        
        local from=$(jq -r '.from' "$msg_file")
        local message=$(jq -r '.message' "$msg_file")
        local timestamp=$(jq -r '.timestamp' "$msg_file")
        local is_read=$(jq -r '.read' "$msg_file")
        
        if [[ "$is_read" == "false" ]]; then
            echo -e "${YELLOW}🆕 NEW${NC} from ${CYAN}$from${NC} ($(echo $timestamp | cut -d'T' -f2 | cut -d'.' -f1))"
            ((unread++))
        else
            echo -e "    from ${CYAN}$from${NC} ($(echo $timestamp | cut -d'T' -f2 | cut -d'.' -f1))"
        fi
        
        echo -e "    ${message:0:60}..."
        echo ""
    done
    
    [[ $unread -eq 0 ]] && echo -e "${GREEN}No new messages${NC}"
}

# Reply to DM
reply() {
    local original_from="$1"
    local message="$2"
    
    send_dm "$original_from" "Re: $message"
}

echo -e "${GREEN}✅ DM System initialized${NC}"
echo -e "${CYAN}Commands:${NC}"
echo -e "  send <to> <message> - Send DM"
echo -e "  check - Check inbox"
