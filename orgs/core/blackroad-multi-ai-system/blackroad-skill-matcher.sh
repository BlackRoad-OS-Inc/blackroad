#!/bin/bash

# Agent Skill Matcher - ML-powered Agent-to-task matching algorithm!
# Analyzes past work patterns and intelligently matches BlackRoad Agents to tasks

MEMORY_DIR="$HOME/.blackroad/memory"
MATCHER_DIR="$MEMORY_DIR/skill-matcher"

# Colors
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

# Initialize skill matcher
init_matcher() {
    mkdir -p "$MATCHER_DIR"/{profiles,matches,training-data}
    
    cat > "$MATCHER_DIR/skill-taxonomy.json" << 'EOF'
{
    "skills": {
        "backend": {
            "keywords": ["api", "server", "backend", "fastapi", "express", "django"],
            "weight": 1.0
        },
        "frontend": {
            "keywords": ["react", "vue", "ui", "frontend", "component", "css"],
            "weight": 1.0
        },
        "database": {
            "keywords": ["postgres", "mysql", "database", "sql", "redis", "mongodb"],
            "weight": 1.0
        },
        "devops": {
            "keywords": ["docker", "k8s", "kubernetes", "deploy", "ci/cd", "terraform"],
            "weight": 1.0
        },
        "ml": {
            "keywords": ["machine learning", "neural", "tensorflow", "pytorch", "model"],
            "weight": 1.0
        },
        "security": {
            "keywords": ["security", "auth", "oauth", "encryption", "vulnerability"],
            "weight": 1.0
        },
        "testing": {
            "keywords": ["test", "pytest", "jest", "unit test", "integration"],
            "weight": 0.8
        },
        "documentation": {
            "keywords": ["docs", "documentation", "readme", "guide", "tutorial"],
            "weight": 0.7
        },
        "integration": {
            "keywords": ["integration", "api integration", "webhook", "connector"],
            "weight": 0.9
        },
        "performance": {
            "keywords": ["performance", "optimization", "cache", "benchmark"],
            "weight": 0.9
        }
    }
}
EOF
    
    echo -e "${GREEN}✅ Skill Matcher initialized${NC}"
}

# Build Agent profile from past work
build_profile() {
    local agent_id="$1"
    
    if [[ -z "$agent_id" ]]; then
        echo -e "${YELLOW}Usage: build-profile <agent-id>${NC}"
        return 1
    fi
    
    echo -e "${CYAN}🧠 Building skill profile for: ${BOLD}$agent_id${NC}"
    
    # Analyze completed tasks and memory entries
    local work_history=$(grep "$agent_id" "$MEMORY_DIR/journals/master-journal.jsonl" 2>/dev/null | \
        jq -r 'select(.action == "completed" or .action == "announce") | .details' | \
        tr '[:upper:]' '[:lower:]')
    
    # Score each skill
    declare -A skill_scores
    
    while IFS= read -r skill; do
        local score=0
        local keywords=$(jq -r --arg skill "$skill" '.skills[$skill].keywords[]' "$MATCHER_DIR/skill-taxonomy.json")
        
        while IFS= read -r keyword; do
            local count=$(echo "$work_history" | grep -o "$keyword" | wc -l | tr -d ' ')
            ((score += count))
        done <<< "$keywords"
        
        skill_scores[$skill]=$score
    done < <(jq -r '.skills | keys[]' "$MATCHER_DIR/skill-taxonomy.json")
    
    # Create profile
    local profile_file="$MATCHER_DIR/profiles/${agent_id}.json"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")
    
    echo "{" > "$profile_file"
    echo "  \"agent_id\": \"$agent_id\"," >> "$profile_file"
    echo "  \"updated_at\": \"$timestamp\"," >> "$profile_file"
    echo "  \"skills\": {" >> "$profile_file"
    
    local first=true
    for skill in "${!skill_scores[@]}"; do
        [[ "$first" == "false" ]] && echo "," >> "$profile_file"
        echo -n "    \"$skill\": ${skill_scores[$skill]}" >> "$profile_file"
        first=false
    done
    
    echo "" >> "$profile_file"
    echo "  }," >> "$profile_file"
    echo "  \"total_work\": $(echo "$work_history" | wc -l | tr -d ' ')" >> "$profile_file"
    echo "}" >> "$profile_file"
    
    # Display profile
    echo ""
    echo -e "${BOLD}${PURPLE}📊 Skill Profile:${NC}"
    
    for skill in "${!skill_scores[@]}"; do
        local score=${skill_scores[$skill]}
        if [[ $score -gt 0 ]]; then
            local bars=$(printf '█%.0s' $(seq 1 $((score > 10 ? 10 : score))))
            echo -e "  ${CYAN}$skill:${NC} $bars ${GREEN}($score)${NC}"
        fi
    done
    
    echo ""
    echo -e "${GREEN}✅ Profile saved to: $profile_file${NC}"
}

# Match Agent to task
match_to_task() {
    local task_description="$1"
    local top_n="${2:-5}"
    
    if [[ -z "$task_description" ]]; then
        echo -e "${YELLOW}Usage: match <task-description> [top-n]${NC}"
        return 1
    fi
    
    echo -e "${CYAN}🎯 Finding best BlackRoad Agents for task...${NC}"
    echo -e "${BLUE}Task: ${task_description:0:80}...${NC}"
    echo ""
    
    # Analyze task to extract required skills
    local task_lower=$(echo "$task_description" | tr '[:upper:]' '[:lower:]')
    declare -A task_skills
    
    while IFS= read -r skill; do
        local score=0
        local keywords=$(jq -r --arg skill "$skill" '.skills[$skill].keywords[]' "$MATCHER_DIR/skill-taxonomy.json")
        
        while IFS= read -r keyword; do
            if echo "$task_lower" | grep -q "$keyword"; then
                ((score++))
            fi
        done <<< "$keywords"
        
        task_skills[$skill]=$score
    done < <(jq -r '.skills | keys[]' "$MATCHER_DIR/skill-taxonomy.json")
    
    echo -e "${BOLD}Required Skills:${NC}"
    for skill in "${!task_skills[@]}"; do
        [[ ${task_skills[$skill]} -gt 0 ]] && echo -e "  • ${CYAN}$skill${NC} (${task_skills[$skill]} matches)"
    done
    echo ""
    
    # Match against Agent profiles
    declare -A match_scores
    
    for profile_file in "$MATCHER_DIR/profiles"/*.json; do
        [[ ! -f "$profile_file" ]] && continue
        
        local agent=$(jq -r '.agent_id' "$profile_file")
        local total_score=0
        
        for skill in "${!task_skills[@]}"; do
            local task_need=${task_skills[$skill]}
            local agent_skill=$(jq -r --arg skill "$skill" '.skills[$skill] // 0' "$profile_file")
            
            # Score = task need × Agent skill level
            local score=$((task_need * agent_skill))
            ((total_score += score))
        done
        
        match_scores[$agent]=$total_score
    done
    
    # Sort and display top matches
    echo -e "${BOLD}${GREEN}🏆 Top Matches:${NC}"
    echo ""
    
    local rank=1
    for agent in $(for c in "${!match_scores[@]}"; do echo "${match_scores[$c]} $c"; done | sort -rn | head -n "$top_n" | awk '{print $2}'); do
        local score=${match_scores[$agent]}
        
        # Medal/badge
        local badge=""
        case $rank in
            1) badge="${YELLOW}🥇 " ;;
            2) badge="${BLUE}🥈 " ;;
            3) badge="${PURPLE}🥉 " ;;
            *) badge="   " ;;
        esac
        
        echo -e "${badge}${BOLD}#$rank${NC} ${CYAN}$agent${NC} - ${GREEN}Score: $score${NC}"
        
        # Show matching skills
        local profile_file="$MATCHER_DIR/profiles/${agent}.json"
        echo -n "    Skills: "
        for skill in "${!task_skills[@]}"; do
            if [[ ${task_skills[$skill]} -gt 0 ]]; then
                local agent_skill=$(jq -r --arg skill "$skill" '.skills[$skill] // 0' "$profile_file")
                [[ $agent_skill -gt 0 ]] && echo -n "${skill}(${agent_skill}) "
            fi
        done
        echo ""
        
        ((rank++))
    done
    
    echo ""
    echo -e "${GREEN}✅ Top $top_n matches found${NC}"
}

# Build profiles for all active BlackRoad Agents
build_all_profiles() {
    echo -e "${CYAN}🧠 Building profiles for all active BlackRoad Agents...${NC}"
    echo ""
    
    local active_agents=$(tail -200 "$MEMORY_DIR/journals/master-journal.jsonl" 2>/dev/null | \
        jq -r '.entity' | grep "agent-" | sort -u)
    
    local count=0
    while IFS= read -r agent; do
        [[ -z "$agent" ]] && continue
        
        echo -e "${BLUE}Building: $agent${NC}"
        build_profile "$agent" > /dev/null 2>&1
        ((count++))
    done <<< "$active_agents"
    
    echo ""
    echo -e "${GREEN}✅ Built $count Agent profiles${NC}"
}

# Show all profiles
list_profiles() {
    echo -e "${BOLD}${PURPLE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${PURPLE}║           👥 CLAUDE SKILL PROFILES 👥                     ║${NC}"
    echo -e "${BOLD}${PURPLE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    for profile_file in "$MATCHER_DIR/profiles"/*.json; do
        [[ ! -f "$profile_file" ]] && continue
        
        local agent=$(jq -r '.agent_id' "$profile_file")
        local total=$(jq -r '.total_work' "$profile_file")
        
        echo -e "${CYAN}$agent${NC} (${total} work items)"
        
        # Top 3 skills
        local top_skills=$(jq -r '.skills | to_entries | sort_by(-.value) | .[0:3] | .[] | "\(.key): \(.value)"' "$profile_file")
        while IFS=: read -r skill score; do
            echo -e "  • ${skill}: ${GREEN}${score}${NC}"
        done <<< "$top_skills"
        
        echo ""
    done
}

# Show help
show_help() {
    cat << EOF
${CYAN}╔════════════════════════════════════════════════════════════╗${NC}
${CYAN}║      🧬 Agent Skill Matcher - Help 🧬                    ║${NC}
${CYAN}╚════════════════════════════════════════════════════════════╝${NC}

${GREEN}USAGE:${NC}
    $0 <command> [options]

${GREEN}COMMANDS:${NC}

${BLUE}init${NC}
    Initialize skill matcher system

${BLUE}build-profile${NC} <agent-id>
    Build skill profile for a Agent based on past work
    Example: $0 build-profile agent-backend-specialist

${BLUE}build-all${NC}
    Build profiles for all active BlackRoad Agents

${BLUE}match${NC} <task-description> [top-n]
    Find best Agent matches for a task (default: top 5)
    Example: $0 match "Build FastAPI backend with PostgreSQL" 3

${BLUE}list${NC}
    List all Agent profiles

${GREEN}HOW IT WORKS:${NC}

    1. Analyzes Agent's past work from memory entries
    2. Scores skills based on keyword matching
    3. Builds comprehensive skill profile
    4. Matches tasks to BlackRoad Agents using similarity scoring
    5. Returns ranked list of best matches

${GREEN}SKILLS TRACKED:${NC}

    • Backend (API, servers, FastAPI)
    • Frontend (React, Vue, UI)
    • Database (PostgreSQL, Redis, SQL)
    • DevOps (Docker, K8s, deployment)
    • ML (TensorFlow, models)
    • Security (Auth, encryption)
    • Testing (pytest, unit tests)
    • Documentation (guides, tutorials)
    • Integration (APIs, webhooks)
    • Performance (optimization, caching)

${GREEN}EXAMPLES:${NC}

    # Build profile for a Agent
    $0 build-profile agent-backend-specialist

    # Build all profiles
    $0 build-all

    # Match task to best BlackRoad Agents
    $0 match "Deploy React frontend with authentication"

    # Get top 3 matches
    $0 match "Optimize database queries" 3

EOF
}

# Main command router
case "$1" in
    init)
        init_matcher
        ;;
    build-profile)
        build_profile "$2"
        ;;
    build-all)
        build_all_profiles
        ;;
    match)
        match_to_task "$2" "$3"
        ;;
    list)
        list_profiles
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo -e "${YELLOW}Unknown command: $1${NC}"
        show_help
        exit 1
        ;;
esac
