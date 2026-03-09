#!/bin/bash
# BlackRoad Memory Indexer System
# Creates searchable indexes for ultra-fast memory queries

MEMORY_DIR="$HOME/.blackroad/memory"
JOURNAL_FILE="$MEMORY_DIR/journals/master-journal.jsonl"
INDEX_DIR="$MEMORY_DIR/indexes"
INDEX_DB="$INDEX_DIR/indexes.db"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Initialize indexing system
init() {
    echo -e "${PURPLE}🔍 Initializing Memory Indexing System...${NC}\n"

    mkdir -p "$INDEX_DIR"

    # Create comprehensive index database
    sqlite3 "$INDEX_DB" <<EOF
-- Core indexes
CREATE TABLE IF NOT EXISTS action_index (
    action TEXT PRIMARY KEY,
    count INTEGER DEFAULT 0,
    first_seen TEXT,
    last_seen TEXT,
    avg_frequency REAL
);

CREATE TABLE IF NOT EXISTS entity_index (
    entity TEXT PRIMARY KEY,
    count INTEGER DEFAULT 0,
    first_seen TEXT,
    last_seen TEXT,
    related_actions TEXT,
    tags TEXT
);

CREATE TABLE IF NOT EXISTS agent_index (
    agent_hash TEXT PRIMARY KEY,
    agent_name TEXT,
    total_actions INTEGER DEFAULT 0,
    actions_by_type TEXT,
    first_seen TEXT,
    last_seen TEXT,
    specialties TEXT,
    success_rate REAL
);

CREATE TABLE IF NOT EXISTS date_index (
    date TEXT PRIMARY KEY,
    action_count INTEGER DEFAULT 0,
    unique_agents INTEGER DEFAULT 0,
    unique_entities INTEGER DEFAULT 0,
    peak_hour INTEGER,
    peak_activity INTEGER
);

CREATE TABLE IF NOT EXISTS keyword_index (
    keyword TEXT PRIMARY KEY,
    frequency INTEGER DEFAULT 0,
    contexts TEXT,
    related_keywords TEXT
);

-- Relationship indexes
CREATE TABLE IF NOT EXISTS action_entity_relations (
    action TEXT,
    entity TEXT,
    count INTEGER DEFAULT 0,
    last_occurrence TEXT,
    PRIMARY KEY (action, entity)
);

CREATE TABLE IF NOT EXISTS agent_entity_relations (
    agent_hash TEXT,
    entity TEXT,
    count INTEGER DEFAULT 0,
    last_occurrence TEXT,
    PRIMARY KEY (agent_hash, entity)
);

-- Pattern recognition
CREATE TABLE IF NOT EXISTS patterns (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    pattern_type TEXT,
    pattern_name TEXT,
    pattern_data TEXT,
    confidence REAL,
    occurrences INTEGER,
    first_detected TEXT,
    last_detected TEXT
);

-- Knowledge graph
CREATE TABLE IF NOT EXISTS knowledge_graph (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    subject TEXT,
    predicate TEXT,
    object TEXT,
    confidence REAL,
    source_hash TEXT,
    timestamp TEXT
);

-- Full-text search support
CREATE VIRTUAL TABLE IF NOT EXISTS memory_fts USING fts5(
    timestamp,
    action,
    entity,
    details,
    agent
);

-- Performance indexes
CREATE INDEX IF NOT EXISTS idx_action_last_seen ON action_index(last_seen);
CREATE INDEX IF NOT EXISTS idx_entity_count ON entity_index(count);
CREATE INDEX IF NOT EXISTS idx_agent_success ON agent_index(success_rate);
CREATE INDEX IF NOT EXISTS idx_keyword_freq ON keyword_index(frequency);
CREATE INDEX IF NOT EXISTS idx_pattern_type ON patterns(pattern_type);
CREATE INDEX IF NOT EXISTS idx_knowledge_subject ON knowledge_graph(subject);
EOF

    echo -e "${GREEN}✅ Index database created${NC}"
    echo -e "${CYAN}📊 Location: $INDEX_DB${NC}\n"
}

# Build indexes from journal
build_indexes() {
    echo -e "${CYAN}🔨 Building indexes from memory journal...${NC}\n"

    if [ ! -f "$JOURNAL_FILE" ]; then
        echo -e "${RED}❌ Journal file not found${NC}"
        return 1
    fi

    local total_entries=$(wc -l < "$JOURNAL_FILE")
    echo -e "${YELLOW}Processing $total_entries entries...${NC}\n"

    # Clear existing indexes
    sqlite3 "$INDEX_DB" <<EOF
DELETE FROM action_index;
DELETE FROM entity_index;
DELETE FROM agent_index;
DELETE FROM date_index;
DELETE FROM keyword_index;
DELETE FROM action_entity_relations;
DELETE FROM agent_entity_relations;
DELETE FROM memory_fts;
EOF

    local count=0
    local last_progress=0

    # Parse journal and build indexes
    while IFS= read -r line; do
        count=$((count + 1))

        # Progress indicator (every 10%)
        local progress=$((count * 100 / total_entries))
        if [ $((progress / 10)) -gt $((last_progress / 10)) ]; then
            echo -ne "${GREEN}Progress: ${progress}%${NC}\r"
            last_progress=$progress
        fi

        # Extract fields
        local timestamp=$(echo "$line" | grep -o '"timestamp":"[^"]*"' | cut -d'"' -f4)
        local action=$(echo "$line" | grep -o '"action":"[^"]*"' | cut -d'"' -f4)
        local entity=$(echo "$line" | grep -o '"entity":"[^"]*"' | cut -d'"' -f4)
        local details=$(echo "$line" | grep -o '"details":"[^"]*"' | cut -d'"' -f4)
        local hash=$(echo "$line" | grep -o '"sha256":"[^"]*"' | cut -d'"' -f4)

        # Escape single quotes for SQL
        action="${action//\'/\'\'}"
        entity="${entity//\'/\'\'}"
        details="${details//\'/\'\'}"

        # Extract date
        local date="${timestamp:0:10}"

        # Detect agent from entity or details
        local agent="unknown"
        if [[ "$entity" =~ (claude-|cecilia-|winston-|apollo-|artemis-|persephone-|phoenix-|silas-|cadence-) ]]; then
            agent="$entity"
        elif [[ "$details" =~ (claude-|cecilia-|winston-|apollo-|artemis-|persephone-|phoenix-|silas-|cadence-)[a-zA-Z0-9-]+ ]]; then
            agent="${BASH_REMATCH[0]}"
        fi

        # Index action
        sqlite3 "$INDEX_DB" <<SQLEOF
INSERT INTO action_index (action, count, first_seen, last_seen)
VALUES ('$action', 1, '$timestamp', '$timestamp')
ON CONFLICT(action) DO UPDATE SET
    count = count + 1,
    last_seen = '$timestamp';

-- Index entity
INSERT INTO entity_index (entity, count, first_seen, last_seen)
VALUES ('$entity', 1, '$timestamp', '$timestamp')
ON CONFLICT(entity) DO UPDATE SET
    count = count + 1,
    last_seen = '$timestamp';

-- Index agent
INSERT INTO agent_index (agent_hash, agent_name, total_actions, first_seen, last_seen)
VALUES ('$agent', '$agent', 1, '$timestamp', '$timestamp')
ON CONFLICT(agent_hash) DO UPDATE SET
    total_actions = total_actions + 1,
    last_seen = '$timestamp';

-- Index date
INSERT INTO date_index (date, action_count)
VALUES ('$date', 1)
ON CONFLICT(date) DO UPDATE SET
    action_count = action_count + 1;

-- Index relationships
INSERT INTO action_entity_relations (action, entity, count, last_occurrence)
VALUES ('$action', '$entity', 1, '$timestamp')
ON CONFLICT(action, entity) DO UPDATE SET
    count = count + 1,
    last_occurrence = '$timestamp';

INSERT INTO agent_entity_relations (agent_hash, entity, count, last_occurrence)
VALUES ('$agent', '$entity', 1, '$timestamp')
ON CONFLICT(agent_hash, entity) DO UPDATE SET
    count = count + 1,
    last_occurrence = '$timestamp';

-- Full-text search index
INSERT INTO memory_fts (timestamp, action, entity, details, agent)
VALUES ('$timestamp', '$action', '$entity', '$details', '$agent');
SQLEOF

        # Extract and index keywords from details (every 100th entry to save time)
        if [ $((count % 100)) -eq 0 ]; then
            echo "$details" | tr ' ' '\n' | grep -E '^[A-Za-z]{4,}$' | tr '[:upper:]' '[:lower:]' | \
            while read -r keyword; do
                sqlite3 "$INDEX_DB" "
                INSERT INTO keyword_index (keyword, frequency)
                VALUES ('$keyword', 1)
                ON CONFLICT(keyword) DO UPDATE SET frequency = frequency + 1;
                " 2>/dev/null
            done
        fi

    done < "$JOURNAL_FILE"

    echo -e "\n${GREEN}✅ Indexes built successfully!${NC}\n"

    # Show statistics
    show_index_stats
}

# Show index statistics
show_index_stats() {
    echo -e "${PURPLE}📊 Index Statistics:${NC}\n"

    local actions=$(sqlite3 "$INDEX_DB" "SELECT COUNT(*) FROM action_index")
    local entities=$(sqlite3 "$INDEX_DB" "SELECT COUNT(*) FROM entity_index")
    local agents=$(sqlite3 "$INDEX_DB" "SELECT COUNT(*) FROM agent_index")
    local dates=$(sqlite3 "$INDEX_DB" "SELECT COUNT(*) FROM date_index")
    local keywords=$(sqlite3 "$INDEX_DB" "SELECT COUNT(*) FROM keyword_index")
    local relations=$(sqlite3 "$INDEX_DB" "SELECT COUNT(*) FROM action_entity_relations")

    echo -e "  ${CYAN}Actions indexed:${NC} $actions"
    echo -e "  ${CYAN}Entities indexed:${NC} $entities"
    echo -e "  ${CYAN}Agents indexed:${NC} $agents"
    echo -e "  ${CYAN}Dates indexed:${NC} $dates"
    echo -e "  ${CYAN}Keywords indexed:${NC} $keywords"
    echo -e "  ${CYAN}Relationships:${NC} $relations\n"
}

# Fast lookup by action
lookup_action() {
    local action="$1"

    echo -e "${CYAN}🔍 Looking up action: ${YELLOW}$action${NC}\n"

    sqlite3 -column -header "$INDEX_DB" <<EOF
SELECT
    action,
    count as occurrences,
    first_seen,
    last_seen
FROM action_index
WHERE action LIKE '%$action%'
ORDER BY count DESC;
EOF

    echo ""

    # Related entities
    echo -e "${PURPLE}Related Entities:${NC}"
    sqlite3 -column "$INDEX_DB" <<EOF
SELECT entity, count
FROM action_entity_relations
WHERE action LIKE '%$action%'
ORDER BY count DESC
LIMIT 10;
EOF
}

# Fast lookup by entity
lookup_entity() {
    local entity="$1"

    echo -e "${CYAN}🔍 Looking up entity: ${YELLOW}$entity${NC}\n"

    sqlite3 -column -header "$INDEX_DB" <<EOF
SELECT
    entity,
    count as occurrences,
    first_seen,
    last_seen
FROM entity_index
WHERE entity LIKE '%$entity%'
ORDER BY count DESC;
EOF

    echo ""

    # Related actions
    echo -e "${PURPLE}Related Actions:${NC}"
    sqlite3 -column "$INDEX_DB" <<EOF
SELECT action, count
FROM action_entity_relations
WHERE entity LIKE '%$entity%'
ORDER BY count DESC
LIMIT 10;
EOF
}

# Fast lookup by agent
lookup_agent() {
    local agent="$1"

    echo -e "${CYAN}🔍 Looking up agent: ${YELLOW}$agent${NC}\n"

    sqlite3 -column -header "$INDEX_DB" <<EOF
SELECT
    agent_name,
    total_actions,
    first_seen,
    last_seen
FROM agent_index
WHERE agent_hash LIKE '%$agent%'
ORDER BY total_actions DESC;
EOF

    echo ""

    # Agent's most worked entities
    echo -e "${PURPLE}Most Worked Entities:${NC}"
    sqlite3 -column "$INDEX_DB" <<EOF
SELECT entity, count
FROM agent_entity_relations
WHERE agent_hash LIKE '%$agent%'
ORDER BY count DESC
LIMIT 10;
EOF
}

# Full-text search
fts_search() {
    local query="$1"
    local limit="${2:-20}"

    echo -e "${CYAN}🔍 Full-text search: ${YELLOW}$query${NC}\n"

    sqlite3 -column "$INDEX_DB" <<EOF
SELECT
    timestamp,
    action,
    entity,
    substr(details, 1, 80) as details
FROM memory_fts
WHERE memory_fts MATCH '$query'
ORDER BY rank
LIMIT $limit;
EOF
}

# Find patterns
detect_patterns() {
    echo -e "${CYAN}🔎 Detecting patterns in memory...${NC}\n"

    # Pattern 1: Sequential actions
    echo -e "${YELLOW}Sequential Action Patterns:${NC}"
    sqlite3 -column "$INDEX_DB" <<EOF
SELECT
    r1.action || ' → ' || r2.action as pattern,
    COUNT(*) as occurrences
FROM action_entity_relations r1
JOIN action_entity_relations r2 ON r1.entity = r2.entity
WHERE r1.last_occurrence < r2.last_occurrence
GROUP BY r1.action, r2.action
HAVING COUNT(*) > 5
ORDER BY occurrences DESC
LIMIT 10;
EOF

    echo ""

    # Pattern 2: Agent specializations
    echo -e "${YELLOW}Agent Specializations:${NC}"
    sqlite3 -column "$INDEX_DB" <<EOF
SELECT
    a.agent_name,
    GROUP_CONCAT(DISTINCT r.entity, ', ') as primary_entities
FROM agent_index a
JOIN agent_entity_relations r ON a.agent_hash = r.agent_hash
WHERE r.count > 3
GROUP BY a.agent_name
LIMIT 10;
EOF

    echo ""

    # Pattern 3: Time-based patterns
    echo -e "${YELLOW}Peak Activity Days:${NC}"
    sqlite3 -column "$INDEX_DB" <<EOF
SELECT
    date,
    action_count
FROM date_index
ORDER BY action_count DESC
LIMIT 10;
EOF
}

# Build knowledge graph
build_knowledge_graph() {
    echo -e "${CYAN}🕸️  Building knowledge graph...${NC}\n"

    # Clear existing
    sqlite3 "$INDEX_DB" "DELETE FROM knowledge_graph;"

    # Add relationships
    # Agent works on Entity
    sqlite3 "$INDEX_DB" <<EOF
INSERT INTO knowledge_graph (subject, predicate, object, confidence, timestamp)
SELECT
    agent_hash,
    'works_on',
    entity,
    CAST(count AS REAL) / (SELECT MAX(count) FROM agent_entity_relations),
    last_occurrence
FROM agent_entity_relations
WHERE count > 2;

-- Action affects Entity
INSERT INTO knowledge_graph (subject, predicate, object, confidence, timestamp)
SELECT
    action,
    'affects',
    entity,
    CAST(count AS REAL) / (SELECT MAX(count) FROM action_entity_relations),
    last_occurrence
FROM action_entity_relations
WHERE count > 2;

-- Entity related to Entity (co-occurrence)
INSERT INTO knowledge_graph (subject, predicate, object, confidence, timestamp)
SELECT DISTINCT
    r1.entity,
    'related_to',
    r2.entity,
    0.5,
    MAX(r1.last_occurrence, r2.last_occurrence)
FROM action_entity_relations r1
JOIN action_entity_relations r2
    ON r1.action = r2.action
    AND r1.entity != r2.entity
WHERE r1.count > 1 AND r2.count > 1;
EOF

    local graph_size=$(sqlite3 "$INDEX_DB" "SELECT COUNT(*) FROM knowledge_graph")
    echo -e "${GREEN}✅ Knowledge graph built: $graph_size relationships${NC}\n"
}

# Query knowledge graph
query_knowledge() {
    local subject="$1"

    echo -e "${CYAN}🕸️  Knowledge graph for: ${YELLOW}$subject${NC}\n"

    sqlite3 -column -header "$INDEX_DB" <<EOF
SELECT
    predicate,
    object,
    ROUND(confidence, 3) as conf
FROM knowledge_graph
WHERE subject LIKE '%$subject%'
ORDER BY confidence DESC
LIMIT 20;
EOF

    echo ""

    # Reverse lookup
    echo -e "${PURPLE}Inverse Relationships:${NC}"
    sqlite3 -column -header "$INDEX_DB" <<EOF
SELECT
    subject,
    predicate,
    ROUND(confidence, 3) as conf
FROM knowledge_graph
WHERE object LIKE '%$subject%'
ORDER BY confidence DESC
LIMIT 20;
EOF
}

# Rebuild all indexes
rebuild() {
    echo -e "${YELLOW}🔄 Rebuilding all indexes...${NC}\n"
    init
    build_indexes
    build_knowledge_graph
    echo -e "${GREEN}✅ All indexes rebuilt!${NC}"
}

# Main execution
case "${1:-help}" in
    init)
        init
        ;;
    build)
        build_indexes
        ;;
    stats)
        show_index_stats
        ;;
    lookup-action)
        lookup_action "$2"
        ;;
    lookup-entity)
        lookup_entity "$2"
        ;;
    lookup-agent)
        lookup_agent "$2"
        ;;
    search)
        fts_search "$2" "$3"
        ;;
    patterns)
        detect_patterns
        ;;
    knowledge)
        build_knowledge_graph
        ;;
    query-knowledge)
        query_knowledge "$2"
        ;;
    rebuild)
        rebuild
        ;;
    help|*)
        echo -e "${PURPLE}╔════════════════════════════════════════════════╗${NC}"
        echo -e "${PURPLE}║     🔍 BlackRoad Memory Indexer System       ║${NC}"
        echo -e "${PURPLE}╚════════════════════════════════════════════════╝${NC}\n"
        echo "Fast indexing and pattern recognition for memory system"
        echo ""
        echo "Usage: $0 COMMAND [OPTIONS]"
        echo ""
        echo "Setup:"
        echo "  init                    - Initialize index database"
        echo "  build                   - Build indexes from journal"
        echo "  rebuild                 - Rebuild everything (init + build + knowledge)"
        echo ""
        echo "Lookups:"
        echo "  lookup-action ACTION    - Fast action lookup"
        echo "  lookup-entity ENTITY    - Fast entity lookup"
        echo "  lookup-agent AGENT      - Fast agent lookup"
        echo "  search QUERY [LIMIT]    - Full-text search"
        echo ""
        echo "Analysis:"
        echo "  stats                   - Show index statistics"
        echo "  patterns                - Detect patterns"
        echo "  knowledge               - Build knowledge graph"
        echo "  query-knowledge SUBJECT - Query knowledge graph"
        echo ""
        echo "Examples:"
        echo "  $0 rebuild"
        echo "  $0 lookup-action enhanced"
        echo "  $0 lookup-entity blackroad-os"
        echo "  $0 search cloudflare 30"
        echo "  $0 patterns"
        echo "  $0 query-knowledge cecilia"
        ;;
esac
