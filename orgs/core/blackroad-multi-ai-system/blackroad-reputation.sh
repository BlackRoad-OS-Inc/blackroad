#!/bin/bash

# BlackRoad Reputation & Trust System
# Build agent reputation through quality work, reliability, and collaboration

MEMORY_DIR="$HOME/.blackroad/memory"
REP_DIR="$MEMORY_DIR/reputation"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Initialize reputation system
init_reputation() {
    mkdir -p "$REP_DIR"/{profiles,reviews,badges,history}
    
    cat > "$REP_DIR/config.json" << 'EOF'
{
    "system": "BlackRoad Reputation & Trust",
    "version": "1.0",
    "reputation_factors": {
        "task_completion": 50,
        "code_quality": 30,
        "collaboration": 15,
        "reliability": 5
    },
    "trust_levels": {
        "novice": {"min": 0, "max": 100},
        "trusted": {"min": 101, "max": 500},
        "expert": {"min": 501, "max": 1000},
        "master": {"min": 1001, "max": 5000},
        "legend": {"min": 5001, "max": 999999}
    }
}
EOF
    
    echo -e "${GREEN}✅ Reputation System initialized${NC}"
}

# Get or create agent reputation profile
get_profile() {
    local agent_id="$1"
    local profile_file="$REP_DIR/profiles/${agent_id}.json"
    
    if [[ ! -f "$profile_file" ]]; then
        # Create new profile
        local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")
        
        cat > "$profile_file" << EOF
{
    "agent_id": "$agent_id",
    "reputation_score": 0,
    "trust_level": "novice",
    "created_at": "$timestamp",
    "updated_at": "$timestamp",
    "stats": {
        "tasks_completed": 0,
        "tasks_failed": 0,
        "reviews_received": 0,
        "avg_rating": 0,
        "collaborations": 0,
        "badges_earned": []
    },
    "strengths": [],
    "verified": false
}
EOF
    fi
    
    echo "$profile_file"
}

# Award reputation points
award_points() {
    local agent_id="$1"
    local points="$2"
    local reason="$3"
    
    if [[ -z "$agent_id" || -z "$points" ]]; then
        echo -e "${RED}Usage: award <agent-id> <points> <reason>${NC}"
        return 1
    fi
    
    local profile_file=$(get_profile "$agent_id")
    local current_score=$(jq -r '.reputation_score' "$profile_file")
    local new_score=$((current_score + points))
    
    # Update score
    jq --arg score "$new_score" \
       --arg timestamp "$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")" \
       '.reputation_score = ($score | tonumber) | .updated_at = $timestamp' \
       "$profile_file" > "${profile_file}.tmp"
    mv "${profile_file}.tmp" "$profile_file"
    
    # Determine trust level
    local trust_level="novice"
    if [[ $new_score -ge 5001 ]]; then
        trust_level="legend"
    elif [[ $new_score -ge 1001 ]]; then
        trust_level="master"
    elif [[ $new_score -ge 501 ]]; then
        trust_level="expert"
    elif [[ $new_score -ge 101 ]]; then
        trust_level="trusted"
    fi
    
    jq --arg level "$trust_level" '.trust_level = $level' "$profile_file" > "${profile_file}.tmp"
    mv "${profile_file}.tmp" "$profile_file"
    
    # Log history
    cat >> "$REP_DIR/history/${agent_id}.log" << EOF
$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ") | +$points | $reason | total: $new_score
EOF
    
    # Log to memory
    ~/memory-system.sh log reputation "$agent_id" "⭐ +$points reputation: $reason (total: $new_score)" 2>/dev/null
    
    echo -e "${GREEN}✅ Awarded ${BOLD}+$points${NC}${GREEN} reputation to $agent_id${NC}"
    echo -e "   ${BLUE}Reason:${NC} $reason"
    echo -e "   ${CYAN}New Score:${NC} $new_score"
    echo -e "   ${PURPLE}Trust Level:${NC} $trust_level"
}

# Submit a review for an agent
submit_review() {
    local agent_id="$1"
    local rating="$2"
    local comment="$3"
    local reviewer="${4:-${MY_AGENT:-anonymous}}"
    
    if [[ -z "$agent_id" || -z "$rating" ]]; then
        echo -e "${RED}Usage: review <agent-id> <1-5> <comment> [reviewer]${NC}"
        return 1
    fi
    
    # Validate rating
    if [[ $rating -lt 1 || $rating -gt 5 ]]; then
        echo -e "${RED}Rating must be between 1 and 5${NC}"
        return 1
    fi
    
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")
    local review_id="review-$(date +%s)-$$"
    
    cat > "$REP_DIR/reviews/${review_id}.json" << EOF
{
    "review_id": "$review_id",
    "agent_id": "$agent_id",
    "reviewer": "$reviewer",
    "rating": $rating,
    "comment": "$comment",
    "timestamp": "$timestamp"
}
EOF
    
    # Update agent stats
    local profile_file=$(get_profile "$agent_id")
    
    # Increment review count
    local review_count=$(jq -r '.stats.reviews_received' "$profile_file")
    review_count=$((review_count + 1))
    
    # Calculate new average
    local current_avg=$(jq -r '.stats.avg_rating' "$profile_file")
    local new_avg=$(echo "scale=2; (($current_avg * ($review_count - 1)) + $rating) / $review_count" | bc)
    
    jq --arg count "$review_count" \
       --arg avg "$new_avg" \
       '.stats.reviews_received = ($count | tonumber) | .stats.avg_rating = ($avg | tonumber)' \
       "$profile_file" > "${profile_file}.tmp"
    mv "${profile_file}.tmp" "$profile_file"
    
    # Award reputation based on rating
    local rep_points=$(( (rating - 3) * 10 ))
    [[ $rep_points -gt 0 ]] && award_points "$agent_id" "$rep_points" "Received ${rating}-star review"
    
    echo -e "${GREEN}✅ Review submitted${NC}"
    echo -e "   ${CYAN}Agent:${NC} $agent_id"
    echo -e "   ${YELLOW}Rating:${NC} $rating/5 ⭐"
    echo -e "   ${BLUE}New Average:${NC} $new_avg"
}

# Show agent reputation profile
show_profile() {
    local agent_id="$1"
    
    if [[ -z "$agent_id" ]]; then
        echo -e "${RED}Usage: show <agent-id>${NC}"
        return 1
    fi
    
    local profile_file=$(get_profile "$agent_id")
    
    local score=$(jq -r '.reputation_score' "$profile_file")
    local level=$(jq -r '.trust_level' "$profile_file")
    local tasks_completed=$(jq -r '.stats.tasks_completed' "$profile_file")
    local tasks_failed=$(jq -r '.stats.tasks_failed' "$profile_file")
    local avg_rating=$(jq -r '.stats.avg_rating' "$profile_file")
    local reviews=$(jq -r '.stats.reviews_received' "$profile_file")
    local verified=$(jq -r '.verified' "$profile_file")
    
    echo -e "${BOLD}${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${CYAN}║        ⭐ REPUTATION PROFILE: $agent_id${NC}"
    echo -e "${BOLD}${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Trust level badge
    local level_color="$NC"
    local level_icon="🔰"
    
    case "$level" in
        novice)
            level_color="$BLUE"
            level_icon="🔰"
            ;;
        trusted)
            level_color="$GREEN"
            level_icon="✅"
            ;;
        expert)
            level_color="$CYAN"
            level_icon="💎"
            ;;
        master)
            level_color="$PURPLE"
            level_icon="👑"
            ;;
        legend)
            level_color="$YELLOW"
            level_icon="🏆"
            ;;
    esac
    
    echo -e "${level_icon} ${level_color}${BOLD}$(echo $level | tr a-z A-Z)${NC} ${level_color}LEVEL${NC}"
    echo ""
    
    echo -e "${BOLD}Reputation Score:${NC} ${CYAN}$score${NC}"
    
    # Progress bar to next level
    local next_threshold=101
    case "$level" in
        novice) next_threshold=101 ;;
        trusted) next_threshold=501 ;;
        expert) next_threshold=1001 ;;
        master) next_threshold=5001 ;;
        legend) next_threshold=999999 ;;
    esac
    
    if [[ $score -lt $next_threshold ]]; then
        local progress=$(( (score * 100) / next_threshold ))
        local bar_length=$(( progress / 5 ))
        local bar=""
        for ((i=0; i<bar_length && i<20; i++)); do
            bar="${bar}█"
        done
        
        echo -e "${BLUE}Progress to next level:${NC} ${bar} ${progress}%"
        echo -e "${BLUE}Next milestone:${NC} $next_threshold points"
    else
        echo -e "${YELLOW}⭐ MAXIMUM LEVEL ACHIEVED ⭐${NC}"
    fi
    
    echo ""
    
    # Verification badge
    if [[ "$verified" == "true" ]]; then
        echo -e "${GREEN}✅ VERIFIED AGENT${NC}"
    else
        echo -e "${YELLOW}⚠️  Unverified${NC}"
    fi
    
    echo ""
    
    # Statistics
    echo -e "${BOLD}${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}Performance Statistics:${NC}"
    echo ""
    
    echo -e "  ${GREEN}✅ Tasks Completed:${NC} $tasks_completed"
    echo -e "  ${RED}❌ Tasks Failed:${NC} $tasks_failed"
    
    if [[ $((tasks_completed + tasks_failed)) -gt 0 ]]; then
        local success_rate=$(( (tasks_completed * 100) / (tasks_completed + tasks_failed) ))
        echo -e "  ${BOLD}Success Rate:${NC} ${CYAN}$success_rate%${NC}"
    fi
    
    echo ""
    echo -e "  ${YELLOW}⭐ Average Rating:${NC} $avg_rating/5"
    echo -e "  ${BLUE}📝 Reviews Received:${NC} $reviews"
    
    # Show recent activity
    echo ""
    echo -e "${BOLD}${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}Recent Reputation Changes:${NC}"
    echo ""
    
    if [[ -f "$REP_DIR/history/${agent_id}.log" ]]; then
        tail -5 "$REP_DIR/history/${agent_id}.log" | while IFS='|' read -r ts points reason total; do
            ts=$(echo "$ts" | xargs)
            points=$(echo "$points" | xargs)
            reason=$(echo "$reason" | xargs)
            
            echo -e "  ${BLUE}$ts${NC} $points - $reason"
        done
    else
        echo -e "  ${YELLOW}No history yet${NC}"
    fi
}

# Leaderboard
show_leaderboard() {
    local limit="${1:-10}"
    
    echo -e "${BOLD}${PURPLE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${PURPLE}║        🏆 REPUTATION LEADERBOARD 🏆                       ║${NC}"
    echo -e "${BOLD}${PURPLE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Get all profiles and sort by score
    local rank=1
    
    for profile_file in $(ls "$REP_DIR/profiles"/*.json 2>/dev/null); do
        local agent_id=$(jq -r '.agent_id' "$profile_file")
        local score=$(jq -r '.reputation_score' "$profile_file")
        local level=$(jq -r '.trust_level' "$profile_file")
        
        echo "$score|$agent_id|$level"
    done | sort -t'|' -k1 -rn | head -n "$limit" | while IFS='|' read -r score agent_id level; do
        
        local rank_icon="  "
        case $rank in
            1) rank_icon="🥇" ;;
            2) rank_icon="🥈" ;;
            3) rank_icon="🥉" ;;
            *) rank_icon="  " ;;
        esac
        
        local level_icon="🔰"
        case "$level" in
            legend) level_icon="🏆" ;;
            master) level_icon="👑" ;;
            expert) level_icon="💎" ;;
            trusted) level_icon="✅" ;;
        esac
        
        printf "  %s #%-2d ${CYAN}%-30s${NC} ${level_icon} %-10s ${YELLOW}%6d pts${NC}\n" \
            "$rank_icon" "$rank" "$agent_id" "$level" "$score"
        
        ((rank++))
    done
}

# Show help
show_help() {
    cat << EOF
${CYAN}╔════════════════════════════════════════════════════════════╗${NC}
${CYAN}║      ⭐ BlackRoad Reputation System - Help ⭐            ║${NC}
${CYAN}╚════════════════════════════════════════════════════════════╝${NC}

${GREEN}USAGE:${NC}
    $0 <command> [options]

${GREEN}COMMANDS:${NC}

${CYAN}init${NC}
    Initialize reputation system

${CYAN}award${NC} <agent-id> <points> <reason>
    Award reputation points to an agent
    Example: $0 award cecilia-001 50 "Excellent PR review"

${CYAN}review${NC} <agent-id> <1-5> <comment> [reviewer]
    Submit a review/rating for an agent
    Example: $0 review cecilia-001 5 "Great collaboration!"

${CYAN}show${NC} <agent-id>
    Show agent's full reputation profile
    Example: $0 show cecilia-001

${CYAN}leaderboard${NC} [limit]
    Show top agents by reputation (default: top 10)
    Example: $0 leaderboard 20

${GREEN}TRUST LEVELS:${NC}

    🔰 ${BLUE}NOVICE${NC}   (0-100 pts)     - New to the system
    ✅ ${GREEN}TRUSTED${NC}  (101-500 pts)   - Proven reliability
    💎 ${CYAN}EXPERT${NC}   (501-1000 pts)  - High quality work
    👑 ${PURPLE}MASTER${NC}   (1001-5000 pts) - Exceptional performance
    🏆 ${YELLOW}LEGEND${NC}   (5001+ pts)     - Elite status

${GREEN}REPUTATION FACTORS:${NC}

    • Task Completion (50%)
    • Code Quality (30%)
    • Collaboration (15%)
    • Reliability (5%)

${GREEN}EXAMPLES:${NC}

    # Initialize
    $0 init

    # Award points for good work
    $0 award cecilia-deploy-001 100 "Flawless deployment"

    # Submit positive review
    $0 review cadence-dev-002 5 "Excellent code quality"

    # View profile
    $0 show silas-architect-003

    # See top 20 agents
    $0 leaderboard 20

EOF
}

# Main command router
case "$1" in
    init)
        init_reputation
        ;;
    award)
        award_points "$2" "$3" "$4"
        ;;
    review)
        submit_review "$2" "$3" "$4" "$5"
        ;;
    show)
        show_profile "$2"
        ;;
    leaderboard)
        show_leaderboard "$2"
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo -e "${RED}Unknown command: $1${NC}"
        show_help
        exit 1
        ;;
esac
