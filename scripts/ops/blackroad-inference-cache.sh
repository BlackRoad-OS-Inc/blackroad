#!/bin/bash
# BlackRoad Inference Cache
# LLM response caching for faster repeated queries
# Agent: Icarus (b3e01bd9)

PINK='\033[38;5;205m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RESET='\033[0m'

CACHE_DIR="$HOME/.blackroad/inference-cache"
CACHE_DB="$CACHE_DIR/cache.db"
MAX_CACHE_SIZE=1000  # Max entries
CACHE_TTL=3600       # Seconds (1 hour default)

# Initialize SQLite cache
init() {
    mkdir -p "$CACHE_DIR"

    sqlite3 "$CACHE_DB" << 'SQL'
CREATE TABLE IF NOT EXISTS cache (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    prompt_hash TEXT UNIQUE,
    prompt TEXT,
    model TEXT,
    response TEXT,
    tokens INTEGER,
    latency_ms INTEGER,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    hits INTEGER DEFAULT 0,
    last_hit DATETIME
);
CREATE INDEX IF NOT EXISTS idx_hash ON cache(prompt_hash);
CREATE INDEX IF NOT EXISTS idx_created ON cache(created_at);
SQL

    echo -e "${GREEN}Inference cache initialized${RESET}"
    echo "  Database: $CACHE_DB"
    echo "  Max entries: $MAX_CACHE_SIZE"
    echo "  TTL: ${CACHE_TTL}s"
}

# Hash prompt for cache key
hash_prompt() {
    local prompt="$1"
    local model="$2"
    echo -n "${model}:${prompt}" | sha256sum | cut -d' ' -f1
}

# Query LLM with caching
query() {
    local prompt="$1"
    local model="${2:-llama3.2:1b}"
    local node="${3:-cecilia}"

    local hash=$(hash_prompt "$prompt" "$model")

    # Check cache
    local cached=$(sqlite3 "$CACHE_DB" "
        SELECT response, tokens, latency_ms FROM cache
        WHERE prompt_hash = '$hash'
        AND datetime(created_at, '+$CACHE_TTL seconds') > datetime('now')
        LIMIT 1
    " 2>/dev/null)

    if [ -n "$cached" ]; then
        # Cache hit
        local response=$(echo "$cached" | cut -d'|' -f1)
        local tokens=$(echo "$cached" | cut -d'|' -f2)
        local latency=$(echo "$cached" | cut -d'|' -f3)

        # Update hit count
        sqlite3 "$CACHE_DB" "
            UPDATE cache SET hits = hits + 1, last_hit = datetime('now')
            WHERE prompt_hash = '$hash'
        "

        echo -e "${GREEN}[CACHE HIT]${RESET} (${latency}ms, ${tokens} tokens)"
        echo "$response"
        return 0
    fi

    # Cache miss - query LLM
    echo -e "${YELLOW}[CACHE MISS]${RESET} Querying $node..."

    local start=$(date +%s%N)
    local result=$(ssh -o ConnectTimeout=30 "$node" \
        "curl -s http://localhost:11434/api/generate -d '{\"model\":\"$model\",\"prompt\":\"$prompt\",\"stream\":false}'" 2>/dev/null)
    local end=$(date +%s%N)
    local latency=$(( (end - start) / 1000000 ))

    local response=$(echo "$result" | jq -r '.response // "ERROR"')
    local tokens=$(echo "$result" | jq -r '.eval_count // 0')

    # Store in cache
    sqlite3 "$CACHE_DB" "
        INSERT OR REPLACE INTO cache (prompt_hash, prompt, model, response, tokens, latency_ms)
        VALUES ('$hash', '$(echo "$prompt" | sed "s/'/''/g")', '$model', '$(echo "$response" | sed "s/'/''/g")', $tokens, $latency)
    "

    # Evict old entries if over limit
    evict_if_needed

    echo "(${latency}ms, ${tokens} tokens)"
    echo "$response"
}

# Batch query with caching
batch_query() {
    local prompts_file="$1"
    local model="${2:-llama3.2:1b}"

    echo -e "${PINK}=== BATCH QUERY WITH CACHE ===${RESET}"
    echo

    local hits=0
    local misses=0

    while IFS= read -r prompt; do
        [ -z "$prompt" ] && continue

        local hash=$(hash_prompt "$prompt" "$model")
        local cached=$(sqlite3 "$CACHE_DB" "
            SELECT 1 FROM cache WHERE prompt_hash = '$hash'
            AND datetime(created_at, '+$CACHE_TTL seconds') > datetime('now')
        " 2>/dev/null)

        if [ -n "$cached" ]; then
            ((hits++))
            echo -n "."
        else
            ((misses++))
            echo -n "x"
            query "$prompt" "$model" >/dev/null 2>&1
        fi
    done < "$prompts_file"

    echo
    echo
    echo "Hits: $hits, Misses: $misses"
    echo "Hit rate: $(echo "scale=1; $hits * 100 / ($hits + $misses)" | bc)%"
}

# Evict old entries
evict_if_needed() {
    local count=$(sqlite3 "$CACHE_DB" "SELECT COUNT(*) FROM cache")

    if [ "$count" -gt "$MAX_CACHE_SIZE" ]; then
        local to_delete=$((count - MAX_CACHE_SIZE + 100))

        sqlite3 "$CACHE_DB" "
            DELETE FROM cache WHERE id IN (
                SELECT id FROM cache ORDER BY last_hit ASC, created_at ASC LIMIT $to_delete
            )
        "
    fi
}

# Clear cache
clear() {
    local what="${1:-all}"

    case "$what" in
        all)
            sqlite3 "$CACHE_DB" "DELETE FROM cache"
            echo -e "${GREEN}Cache cleared${RESET}"
            ;;
        expired)
            sqlite3 "$CACHE_DB" "
                DELETE FROM cache
                WHERE datetime(created_at, '+$CACHE_TTL seconds') < datetime('now')
            "
            echo -e "${GREEN}Expired entries cleared${RESET}"
            ;;
        model:*)
            local model="${what#model:}"
            sqlite3 "$CACHE_DB" "DELETE FROM cache WHERE model = '$model'"
            echo -e "${GREEN}Cleared cache for model: $model${RESET}"
            ;;
    esac
}

# Cache statistics
stats() {
    echo -e "${PINK}=== CACHE STATISTICS ===${RESET}"
    echo

    local total=$(sqlite3 "$CACHE_DB" "SELECT COUNT(*) FROM cache")
    local total_hits=$(sqlite3 "$CACHE_DB" "SELECT COALESCE(SUM(hits), 0) FROM cache")
    local avg_latency=$(sqlite3 "$CACHE_DB" "SELECT COALESCE(AVG(latency_ms), 0) FROM cache")
    local total_tokens=$(sqlite3 "$CACHE_DB" "SELECT COALESCE(SUM(tokens), 0) FROM cache")
    local cache_size=$(du -h "$CACHE_DB" 2>/dev/null | cut -f1)

    echo "Entries: $total / $MAX_CACHE_SIZE"
    echo "Total hits: $total_hits"
    echo "Avg latency saved: ${avg_latency}ms"
    echo "Total tokens cached: $total_tokens"
    echo "Cache size: $cache_size"
    echo "TTL: ${CACHE_TTL}s"
    echo

    echo "By model:"
    sqlite3 "$CACHE_DB" "
        SELECT model, COUNT(*), SUM(hits)
        FROM cache GROUP BY model
    " | while IFS='|' read -r model count hits; do
        echo "  $model: $count entries, $hits hits"
    done

    echo
    echo "Top queries by hits:"
    sqlite3 "$CACHE_DB" "
        SELECT substr(prompt, 1, 50), hits FROM cache
        ORDER BY hits DESC LIMIT 5
    " | while IFS='|' read -r prompt hits; do
        echo "  ($hits) $prompt..."
    done
}

# Warm cache with common queries
warm() {
    local prompts_file="$1"
    local model="${2:-llama3.2:1b}"

    if [ ! -f "$prompts_file" ]; then
        echo "Usage: warm <prompts_file> [model]"
        return 1
    fi

    echo -e "${PINK}=== WARMING CACHE ===${RESET}"
    echo

    local count=0
    while IFS= read -r prompt; do
        [ -z "$prompt" ] && continue

        echo -n "Caching: ${prompt:0:40}... "
        query "$prompt" "$model" >/dev/null 2>&1
        echo -e "${GREEN}done${RESET}"
        ((count++))
    done < "$prompts_file"

    echo
    echo -e "${GREEN}Warmed $count queries${RESET}"
}

# Export cache
export_cache() {
    local format="${1:-json}"
    local output="${2:-cache_export}"

    case "$format" in
        json)
            sqlite3 "$CACHE_DB" -json "
                SELECT prompt_hash, prompt, model, response, tokens, latency_ms, hits, created_at
                FROM cache
            " > "${output}.json"
            echo -e "${GREEN}Exported to ${output}.json${RESET}"
            ;;
        csv)
            sqlite3 "$CACHE_DB" -csv -header "
                SELECT prompt_hash, model, tokens, latency_ms, hits, created_at
                FROM cache
            " > "${output}.csv"
            echo -e "${GREEN}Exported to ${output}.csv${RESET}"
            ;;
    esac
}

# Search cache
search() {
    local pattern="$1"

    echo -e "${PINK}=== CACHE SEARCH ===${RESET}"
    echo "Pattern: $pattern"
    echo

    sqlite3 "$CACHE_DB" "
        SELECT model, hits, substr(prompt, 1, 60), substr(response, 1, 100)
        FROM cache
        WHERE prompt LIKE '%$pattern%' OR response LIKE '%$pattern%'
        LIMIT 10
    " | while IFS='|' read -r model hits prompt response; do
        echo "[$model] ($hits hits)"
        echo "  Q: $prompt..."
        echo "  A: $response..."
        echo
    done
}

# Precompute embeddings for semantic cache (placeholder)
embed() {
    echo -e "${YELLOW}Semantic caching requires embedding model${RESET}"
    echo "This would:"
    echo "  1. Generate embeddings for cached prompts"
    echo "  2. Enable fuzzy matching of similar queries"
    echo "  3. Return cached responses for semantically similar questions"
}

# Help
help() {
    echo -e "${PINK}BlackRoad Inference Cache${RESET}"
    echo
    echo "LLM response caching for faster queries"
    echo
    echo "Commands:"
    echo "  query <prompt> [model]    Query with caching"
    echo "  batch <file> [model]      Batch query file"
    echo "  warm <file> [model]       Pre-warm cache"
    echo "  clear [all|expired]       Clear cache"
    echo "  stats                     Cache statistics"
    echo "  search <pattern>          Search cache"
    echo "  export [json|csv]         Export cache"
    echo
    echo "Environment:"
    echo "  MAX_CACHE_SIZE=$MAX_CACHE_SIZE"
    echo "  CACHE_TTL=$CACHE_TTL"
    echo
    echo "Examples:"
    echo "  $0 query 'What is AI?'"
    echo "  $0 warm common-questions.txt"
    echo "  $0 stats"
    echo "  $0 clear expired"
}

# Ensure initialized
[ -f "$CACHE_DB" ] || init >/dev/null

case "${1:-help}" in
    init)
        init
        ;;
    query|ask|q)
        shift
        query "$@"
        ;;
    batch)
        batch_query "$2" "$3"
        ;;
    warm|preheat)
        warm "$2" "$3"
        ;;
    clear|flush)
        clear "$2"
        ;;
    stats|status)
        stats
        ;;
    search|find)
        search "$2"
        ;;
    export)
        export_cache "$2" "$3"
        ;;
    embed)
        embed
        ;;
    *)
        help
        ;;
esac
