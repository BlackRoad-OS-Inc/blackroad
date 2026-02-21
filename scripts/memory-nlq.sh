#!/bin/bash
# BlackRoad Memory Natural Language Query (NLQ) System
# Ask questions in plain English, get intelligent answers

MEMORY_DIR="$HOME/.blackroad/memory"
NLQ_DIR="$MEMORY_DIR/nlq"
NLQ_DB="$NLQ_DIR/nlq.db"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
BLUE='\033[0;34m'
NC='\033[0m'

init() {
    echo -e "${PURPLE}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║     🗣️  Natural Language Query System         ║${NC}"
    echo -e "${PURPLE}╚════════════════════════════════════════════════╝${NC}\n"

    mkdir -p "$NLQ_DIR/patterns"

    # Create NLQ database
    sqlite3 "$NLQ_DB" <<'SQL'
-- Query history
CREATE TABLE IF NOT EXISTS query_history (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    query_text TEXT NOT NULL,
    interpreted_as TEXT,
    tool_used TEXT,
    result_count INTEGER,
    response_time INTEGER,           -- milliseconds
    success INTEGER,
    timestamp INTEGER NOT NULL
);

-- Query patterns (learned patterns)
CREATE TABLE IF NOT EXISTS query_patterns (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    pattern TEXT NOT NULL,
    intent TEXT NOT NULL,            -- 'search', 'count', 'filter', 'analyze', 'predict'
    tool TEXT NOT NULL,               -- which tool to use
    params TEXT,                      -- JSON parameters
    confidence REAL DEFAULT 0.5,
    usage_count INTEGER DEFAULT 0,
    success_count INTEGER DEFAULT 0
);

-- Intent keywords
CREATE TABLE IF NOT EXISTS intent_keywords (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    keyword TEXT NOT NULL,
    intent TEXT NOT NULL,
    weight REAL DEFAULT 1.0
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_query_history_timestamp ON query_history(timestamp);
CREATE INDEX IF NOT EXISTS idx_query_patterns_intent ON query_patterns(intent);
CREATE INDEX IF NOT EXISTS idx_intent_keywords_keyword ON intent_keywords(keyword);

SQL

    # Pre-load intent keywords
    sqlite3 "$NLQ_DB" <<'SQL'
-- Search intent
INSERT OR IGNORE INTO intent_keywords (keyword, intent, weight) VALUES
    ('find', 'search', 1.0),
    ('search', 'search', 1.0),
    ('show', 'search', 0.8),
    ('get', 'search', 0.8),
    ('what', 'search', 0.7),
    ('which', 'search', 0.7),
    ('where', 'search', 0.7);

-- Count intent
INSERT OR IGNORE INTO intent_keywords (keyword, intent, weight) VALUES
    ('how many', 'count', 1.0),
    ('count', 'count', 1.0),
    ('total', 'count', 0.9),
    ('number of', 'count', 1.0);

-- Filter intent
INSERT OR IGNORE INTO intent_keywords (keyword, intent, weight) VALUES
    ('filter', 'filter', 1.0),
    ('only', 'filter', 0.8),
    ('just', 'filter', 0.7),
    ('where', 'filter', 0.6);

-- Analyze intent
INSERT OR IGNORE INTO intent_keywords (keyword, intent, weight) VALUES
    ('analyze', 'analyze', 1.0),
    ('why', 'analyze', 0.9),
    ('explain', 'analyze', 0.8),
    ('breakdown', 'analyze', 0.8);

-- Predict intent
INSERT OR IGNORE INTO intent_keywords (keyword, intent, weight) VALUES
    ('predict', 'predict', 1.0),
    ('will', 'predict', 0.8),
    ('forecast', 'predict', 1.0),
    ('future', 'predict', 0.7);

-- Time keywords
INSERT OR IGNORE INTO intent_keywords (keyword, intent, weight) VALUES
    ('today', 'time', 1.0),
    ('yesterday', 'time', 1.0),
    ('recent', 'time', 0.9),
    ('latest', 'time', 0.9),
    ('last', 'time', 0.8);

SQL

    echo -e "${GREEN}✓${NC} Natural Language Query system initialized"
    echo -e "  ${CYAN}Try asking:${NC}"
    echo -e "    • What happened today?"
    echo -e "    • How many deployments failed yesterday?"
    echo -e "    • Show me recent enhancements"
    echo -e "    • Will blackroad-cloud succeed?"
    echo -e "    • Why did the deployment fail?"
}

# Analyze query intent
analyze_intent() {
    local query="$1"
    local query_lower=$(echo "$query" | tr '[:upper:]' '[:lower:]')

    # Check for each intent
    declare -A intent_scores

    # Search for keywords
    sqlite3 "$NLQ_DB" "SELECT keyword, intent, weight FROM intent_keywords" | \
    while IFS='|' read -r keyword intent weight; do
        if echo "$query_lower" | grep -q "$keyword"; then
            current=${intent_scores[$intent]:-0}
            intent_scores[$intent]=$(echo "$current + $weight" | bc)
        fi
    done

    # Get highest scoring intent
    local best_intent="search"  # default
    local best_score=0

    for intent in "${!intent_scores[@]}"; do
        score=${intent_scores[$intent]}
        if (( $(echo "$score > $best_score" | bc -l) )); then
            best_score=$score
            best_intent=$intent
        fi
    done

    echo "$best_intent"
}

# Extract entities from query
extract_entities() {
    local query="$1"

    # Extract dates
    local dates=""
    if echo "$query" | grep -qi "today"; then
        dates="today"
    elif echo "$query" | grep -qi "yesterday"; then
        dates="yesterday"
    elif echo "$query" | grep -qi "last week"; then
        dates="last_week"
    fi

    # Extract actions
    local actions=""
    for action in deployed enhanced failed started completed updated; do
        if echo "$query" | grep -qi "$action"; then
            actions="$actions $action"
        fi
    done

    # Extract numbers
    local numbers=$(echo "$query" | grep -oE '[0-9]+' | head -1)

    echo "dates=$dates actions=$actions numbers=$numbers"
}

# Execute query
execute_query() {
    local query="$1"
    local start_time=$(date +%s%3N)

    echo -e "${CYAN}🔍 Query:${NC} $query"
    echo ""

    # Analyze intent
    local intent=$(analyze_intent "$query")
    echo -e "${PURPLE}Intent detected:${NC} $intent"

    # Extract entities
    local entities=$(extract_entities "$query")
    echo -e "${PURPLE}Entities:${NC} $entities"
    echo ""

    # Route to appropriate tool
    case "$intent" in
        search)
            execute_search "$query" "$entities"
            ;;
        count)
            execute_count "$query" "$entities"
            ;;
        filter)
            execute_filter "$query" "$entities"
            ;;
        analyze)
            execute_analyze "$query" "$entities"
            ;;
        predict)
            execute_predict "$query" "$entities"
            ;;
        *)
            execute_search "$query" "$entities"
            ;;
    esac

    local end_time=$(date +%s%3N)
    local duration=$((end_time - start_time))

    echo ""
    echo -e "${CYAN}⏱️  Response time: ${duration}ms${NC}"

    # Log query
    log_query "$query" "$intent" "$duration" 1
}

# Execute search query
execute_search() {
    local query="$1"
    local entities="$2"

    echo -e "${CYAN}📊 Results:${NC}"

    # Extract key terms (remove common words)
    local search_terms=$(echo "$query" | \
        sed 's/\bwhat\b//gi; s/\bshow\b//gi; s/\bme\b//gi; s/\bthe\b//gi; s/\bfind\b//gi' | \
        sed 's/[[:punct:]]//g' | \
        tr '[:upper:]' '[:lower:]' | \
        tr -s ' ')

    # Search using indexer
    if [ -f ~/memory-indexer.sh ]; then
        ~/memory-indexer.sh search "$search_terms" 10
    else
        # Fallback to grep
        grep -i "$search_terms" "$MEMORY_DIR/journals/master-journal.jsonl" | tail -10 | \
        jq -r '[.timestamp // .ts, .action, .entity // .agent] | @tsv' 2>/dev/null || \
        grep -i "$search_terms" "$MEMORY_DIR/journals/master-journal.jsonl" | tail -10
    fi
}

# Execute count query
execute_count() {
    local query="$1"
    local entities="$2"

    # Extract what to count
    local count_target=$(echo "$query" | \
        sed 's/how many//gi; s/count//gi; s/total//gi; s/number of//gi' | \
        sed 's/[[:punct:]]//g' | \
        tr -s ' ' | \
        xargs)

    echo -e "${CYAN}📊 Counting: $count_target${NC}"

    local journal="$MEMORY_DIR/journals/master-journal.jsonl"

    # Count by action
    if echo "$count_target" | grep -qi "deployment\|deploy"; then
        local count=$(grep -c '"action":"deployed"' "$journal")
        echo -e "${GREEN}✓${NC} Total deployments: $count"

    elif echo "$count_target" | grep -qi "enhancement\|enhanced"; then
        local count=$(grep -c '"action":"enhanced"' "$journal")
        echo -e "${GREEN}✓${NC} Total enhancements: $count"

    elif echo "$count_target" | grep -qi "fail"; then
        local count=$(grep -c '"action":"failed"' "$journal")
        echo -e "${RED}✗${NC} Total failures: $count"

    elif echo "$count_target" | grep -qi "entr\|event"; then
        local count=$(wc -l < "$journal")
        echo -e "${GREEN}✓${NC} Total entries: $count"

    else
        # Generic count
        local count=$(grep -ic "$count_target" "$journal")
        echo -e "${CYAN}Count for '$count_target':${NC} $count"
    fi
}

# Execute filter query
execute_filter() {
    local query="$1"
    local entities="$2"

    echo -e "${CYAN}🔍 Filtering...${NC}"

    # Extract filter terms
    local filter_terms=$(echo "$query" | \
        sed 's/show me//gi; s/only//gi; s/just//gi; s/filter//gi' | \
        sed 's/[[:punct:]]//g' | \
        tr -s ' ' | \
        xargs)

    local journal="$MEMORY_DIR/journals/master-journal.jsonl"

    # Apply filter
    grep -i "$filter_terms" "$journal" | tail -20 | \
    jq -r '[.timestamp // .ts, .action, .entity // .agent] | @tsv' 2>/dev/null || \
    grep -i "$filter_terms" "$journal" | tail -20
}

# Execute analyze query
execute_analyze() {
    local query="$1"
    local entities="$2"

    echo -e "${CYAN}📈 Analysis:${NC}"

    # Get recommendations from codex
    if [ -f ~/memory-codex.sh ]; then
        ~/memory-codex.sh recommend "$query"
    else
        echo -e "${YELLOW}Codex not available for analysis${NC}"
    fi
}

# Execute predict query
execute_predict() {
    local query="$1"
    local entities="$2"

    # Extract entity to predict
    local predict_entity=$(echo "$query" | \
        sed 's/will//gi; s/predict//gi; s/forecast//gi; s/succeed//gi; s/fail//gi' | \
        sed 's/[[:punct:]]//g' | \
        tr -s ' ' | \
        xargs)

    echo -e "${CYAN}🔮 Prediction for: $predict_entity${NC}"

    if [ -f ~/memory-predictor.sh ]; then
        ~/memory-predictor.sh predict "$predict_entity"
    else
        echo -e "${YELLOW}Predictor not available${NC}"
    fi
}

# Interactive mode
interactive() {
    echo -e "${PURPLE}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║     🗣️  Interactive Query Mode                ║${NC}"
    echo -e "${PURPLE}╚════════════════════════════════════════════════╝${NC}\n"

    echo -e "${CYAN}Ask me anything! (Type 'exit' to quit)${NC}"
    echo -e "${YELLOW}Examples:${NC}"
    echo -e "  • What happened today?"
    echo -e "  • How many deployments failed?"
    echo -e "  • Show me recent enhancements"
    echo -e "  • Will blackroad-cloud succeed?"
    echo ""

    while true; do
        echo -n -e "${GREEN}❯${NC} "
        read -r query

        [ -z "$query" ] && continue
        [ "$query" = "exit" ] && break
        [ "$query" = "quit" ] && break

        echo ""
        execute_query "$query"
        echo ""
    done

    echo -e "${CYAN}Goodbye! 👋${NC}"
}

# Log query
log_query() {
    local query="$1"
    local intent="$2"
    local duration="$3"
    local success="$4"
    local timestamp=$(date +%s)

    sqlite3 "$NLQ_DB" <<SQL
INSERT INTO query_history (query_text, interpreted_as, response_time, success, timestamp)
VALUES ('$(echo "$query" | sed "s/'/''/g")', '$intent', $duration, $success, $timestamp);
SQL
}

# Show query history
show_history() {
    local limit="${1:-20}"

    echo -e "${PURPLE}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║     Query History                             ║${NC}"
    echo -e "${PURPLE}╚════════════════════════════════════════════════╝${NC}\n"

    sqlite3 -header -column "$NLQ_DB" <<SQL
SELECT
    SUBSTR(query_text, 1, 50) as query,
    interpreted_as,
    response_time || 'ms' as time,
    datetime(timestamp, 'unixepoch', 'localtime') as when
FROM query_history
ORDER BY timestamp DESC
LIMIT $limit;
SQL
}

# Show statistics
show_stats() {
    echo -e "${PURPLE}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║     NLQ Statistics                            ║${NC}"
    echo -e "${PURPLE}╚════════════════════════════════════════════════╝${NC}\n"

    # Total queries
    local total=$(sqlite3 "$NLQ_DB" "SELECT COUNT(*) FROM query_history")
    echo -e "${CYAN}Total Queries:${NC} $total"

    # Queries by intent
    echo -e "\n${PURPLE}Queries by Intent:${NC}"
    sqlite3 -header -column "$NLQ_DB" <<SQL
SELECT
    interpreted_as,
    COUNT(*) as count,
    AVG(response_time) as avg_ms
FROM query_history
GROUP BY interpreted_as
ORDER BY count DESC;
SQL

    # Average response time
    local avg_time=$(sqlite3 "$NLQ_DB" "SELECT AVG(response_time) FROM query_history")
    echo -e "\n${CYAN}Average Response Time:${NC} ${avg_time}ms"
}

# Main execution
case "${1:-help}" in
    init)
        init
        ;;
    ask)
        shift
        execute_query "$*"
        ;;
    interactive|chat)
        interactive
        ;;
    history)
        show_history "$2"
        ;;
    stats)
        show_stats
        ;;
    help|*)
        echo -e "${PURPLE}╔════════════════════════════════════════════════╗${NC}"
        echo -e "${PURPLE}║     🗣️  Natural Language Query System         ║${NC}"
        echo -e "${PURPLE}╚════════════════════════════════════════════════╝${NC}\n"
        echo "Ask questions in plain English!"
        echo ""
        echo "Usage: $0 COMMAND [OPTIONS]"
        echo ""
        echo "Commands:"
        echo "  init                    - Initialize NLQ system"
        echo "  ask QUESTION            - Ask a question"
        echo "  interactive             - Start interactive mode"
        echo "  history [LIMIT]         - Show query history"
        echo "  stats                   - Show statistics"
        echo ""
        echo "Example Questions:"
        echo "  $0 ask \"What happened today?\""
        echo "  $0 ask \"How many deployments failed?\""
        echo "  $0 ask \"Show me recent enhancements\""
        echo "  $0 ask \"Will blackroad-cloud succeed?\""
        echo "  $0 ask \"Why did the deployment fail?\""
        echo ""
        echo "Interactive Mode:"
        echo "  $0 interactive"
        ;;
esac
