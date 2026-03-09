#!/bin/bash
# BlackRoad Memory Codex System
# A living knowledge base of patterns, solutions, and best practices

MEMORY_DIR="$HOME/.blackroad/memory"
CODEX_DIR="$MEMORY_DIR/codex"
CODEX_DB="$CODEX_DIR/codex.db"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
BLUE='\033[0;34m'
NC='\033[0m'

# Initialize codex
init() {
    echo -e "${PURPLE}📚 Initializing BlackRoad Memory Codex...${NC}\n"

    mkdir -p "$CODEX_DIR/patterns"
    mkdir -p "$CODEX_DIR/solutions"
    mkdir -p "$CODEX_DIR/best-practices"
    mkdir -p "$CODEX_DIR/templates"

    # Create codex database
    sqlite3 "$CODEX_DB" <<EOF
-- Core codex tables
CREATE TABLE IF NOT EXISTS solutions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT UNIQUE NOT NULL,
    category TEXT,
    problem TEXT,
    solution TEXT,
    code_snippet TEXT,
    success_rate REAL DEFAULT 1.0,
    uses INTEGER DEFAULT 0,
    created_at TEXT,
    updated_at TEXT,
    tags TEXT,
    related_solutions TEXT
);

CREATE TABLE IF NOT EXISTS patterns (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    pattern_name TEXT UNIQUE NOT NULL,
    pattern_type TEXT,
    description TEXT,
    when_to_use TEXT,
    example TEXT,
    confidence REAL,
    occurrences INTEGER DEFAULT 0,
    first_seen TEXT,
    last_seen TEXT,
    tags TEXT
);

CREATE TABLE IF NOT EXISTS best_practices (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    category TEXT,
    practice_name TEXT,
    description TEXT,
    rationale TEXT,
    examples TEXT,
    contraindications TEXT,
    priority TEXT,
    created_at TEXT
);

CREATE TABLE IF NOT EXISTS templates (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    template_name TEXT UNIQUE NOT NULL,
    template_type TEXT,
    content TEXT,
    variables TEXT,
    usage_count INTEGER DEFAULT 0,
    success_rate REAL DEFAULT 1.0,
    created_at TEXT,
    tags TEXT
);

CREATE TABLE IF NOT EXISTS lessons_learned (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT,
    what_happened TEXT,
    what_worked TEXT,
    what_failed TEXT,
    lessons TEXT,
    recommendations TEXT,
    timestamp TEXT,
    source_hash TEXT
);

CREATE TABLE IF NOT EXISTS anti_patterns (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT,
    description TEXT,
    why_bad TEXT,
    better_approach TEXT,
    severity TEXT,
    occurrences INTEGER DEFAULT 0,
    first_detected TEXT
);

-- Search and relationships
CREATE VIRTUAL TABLE IF NOT EXISTS codex_fts USING fts5(
    name,
    category,
    description,
    content,
    tags
);

CREATE INDEX IF NOT EXISTS idx_solution_category ON solutions(category);
CREATE INDEX IF NOT EXISTS idx_pattern_type ON patterns(pattern_type);
CREATE INDEX IF NOT EXISTS idx_template_type ON templates(template_type);
CREATE INDEX IF NOT EXISTS idx_practice_priority ON best_practices(priority);
EOF

    echo -e "${GREEN}✅ Codex database created${NC}"
    echo -e "${CYAN}📊 Location: $CODEX_DB${NC}\n"

    # Load initial knowledge
    load_initial_knowledge
}

# Load initial knowledge from memory analysis
load_initial_knowledge() {
    echo -e "${CYAN}📖 Loading initial knowledge...${NC}\n"

    # Extract patterns from memory
    local patterns_found=$(grep -c "pattern\|workflow\|process" "$MEMORY_DIR/journals/master-journal.jsonl" 2>/dev/null || echo 0)
    local solutions_found=$(grep -c "solution\|fix\|resolved" "$MEMORY_DIR/journals/master-journal.jsonl" 2>/dev/null || echo 0)

    # Add common patterns
    sqlite3 "$CODEX_DB" <<EOF
-- Common enhancement pattern
INSERT OR IGNORE INTO patterns (pattern_name, pattern_type, description, when_to_use, confidence)
VALUES (
    'Repository Enhancement Workflow',
    'workflow',
    'Standard process for enhancing repositories with licensing and automation',
    'When adding proprietary licensing and CI/CD to repos',
    0.95
);

-- Parallel batch processing
INSERT OR IGNORE INTO patterns (pattern_name, pattern_type, description, when_to_use, confidence)
VALUES (
    'Parallel Batch Processing',
    'performance',
    'Process multiple repositories in parallel batches',
    'When enhancing multiple repos simultaneously. Optimal batch size: 20 repos',
    0.85
);

-- Agent coordination
INSERT OR IGNORE INTO patterns (pattern_name, pattern_type, description, when_to_use, confidence)
VALUES (
    'Pre-work Conflict Check',
    'coordination',
    'Check [MEMORY] before starting work to avoid conflicts',
    'Before any repo/entity modification',
    0.98
);
EOF

    # Add anti-patterns (things that failed)
    sqlite3 "$CODEX_DB" <<EOF
INSERT OR IGNORE INTO anti_patterns (name, description, why_bad, better_approach, severity)
VALUES (
    'Large Batch Sizes',
    'Processing 40+ repos in parallel',
    'Causes coordination conflicts (57 detected), high failure rates',
    'Use batch size of 20 repos with delays between batches',
    'HIGH'
);

INSERT OR IGNORE INTO anti_patterns (name, description, why_bad, better_approach, severity)
VALUES (
    'No Retry Logic',
    'Single-attempt operations without retry',
    'Transient failures cause permanent failures. 36% failure rate observed',
    'Implement exponential backoff with 3 retry attempts',
    'CRITICAL'
);

INSERT OR IGNORE INTO anti_patterns (name, description, why_bad, better_approach, severity)
VALUES (
    'Missing Pre-work Checks',
    'Starting work without checking [MEMORY] for conflicts',
    'Duplicate work, merge conflicts, wasted agent time',
    'Always check memory-query.sh entity ENTITY before starting',
    'HIGH'
);
EOF

    # Add best practices
    sqlite3 "$CODEX_DB" <<EOF
INSERT OR IGNORE INTO best_practices (category, practice_name, description, rationale, priority)
VALUES (
    'Enhancement',
    'Check [MEMORY] Before Work',
    'Always query memory system before starting any enhancement work',
    'Prevents conflicts, duplicate work, and coordination issues. Observed 57 conflicts when skipped',
    'CRITICAL'
);

INSERT OR IGNORE INTO best_practices (category, practice_name, description, rationale, priority)
VALUES (
    'Performance',
    'Use Optimal Batch Sizes',
    'Process repositories in batches of 20, not 40+',
    'Batch size 40 led to 86% failure rate in some orgs. Size 20 recommended',
    'HIGH'
);

INSERT OR IGNORE INTO best_practices (category, practice_name, description, rationale, priority)
VALUES (
    'Reliability',
    'Implement Exponential Backoff',
    'Add retry logic with exponential backoff (1s, 2s, 4s delays)',
    'Handles transient failures. Could reduce failure rate from 36% to ~15%',
    'CRITICAL'
);

INSERT OR IGNORE INTO best_practices (category, practice_name, description, rationale, priority)
VALUES (
    'Monitoring',
    'Track Operation Duration',
    'Log start time and duration for all operations',
    'Enables bottleneck detection. Operations >5min should trigger alerts',
    'HIGH'
);
EOF

    # Add successful templates
    sqlite3 "$CODEX_DB" <<EOF
INSERT OR IGNORE INTO templates (template_name, template_type, content, success_rate)
VALUES (
    'Proprietary LICENSE',
    'license',
    'BlackRoad OS, Inc. © 2026\nAll Rights Reserved\n\nThis software is proprietary and confidential.\n\nFor testing and non-commercial use only.\nPublicly visible but legally protected.',
    1.0
);

INSERT OR IGNORE INTO templates (template_name, template_type, content, success_rate)
VALUES (
    'GitHub Actions: Brand Check',
    'github-workflow',
    'name: Brand Compliance Check
on: [push, pull_request]
jobs:
  brand-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Check brand compliance
        run: |
          echo "Checking BlackRoad brand guidelines..."
          # Add brand validation logic',
    0.95
);
EOF

    echo -e "${GREEN}✅ Initial knowledge loaded${NC}\n"
}

# Add solution to codex
add_solution() {
    local name="$1"
    local category="$2"
    local problem="$3"
    local solution="$4"

    echo -e "${CYAN}💡 Adding solution to codex...${NC}\n"

    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")

    sqlite3 "$CODEX_DB" <<EOF
INSERT INTO solutions (name, category, problem, solution, created_at, updated_at)
VALUES ('$name', '$category', '$problem', '$solution', '$timestamp', '$timestamp')
ON CONFLICT(name) DO UPDATE SET
    solution = '$solution',
    uses = uses + 1,
    updated_at = '$timestamp';
EOF

    echo -e "${GREEN}✅ Solution added: $name${NC}"
}

# Add pattern to codex
add_pattern() {
    local name="$1"
    local type="$2"
    local description="$3"

    echo -e "${CYAN}🔍 Adding pattern to codex...${NC}\n"

    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")

    sqlite3 "$CODEX_DB" <<EOF
INSERT INTO patterns (pattern_name, pattern_type, description, first_seen, last_seen)
VALUES ('$name', '$type', '$description', '$timestamp', '$timestamp')
ON CONFLICT(pattern_name) DO UPDATE SET
    occurrences = occurrences + 1,
    last_seen = '$timestamp';
EOF

    echo -e "${GREEN}✅ Pattern added: $name${NC}"
}

# Search codex
search() {
    local query="$1"
    local category="${2:-all}"

    echo -e "${CYAN}🔍 Searching codex for: ${YELLOW}$query${NC}\n"

    if [ "$category" = "all" ]; then
        # Search solutions
        echo -e "${PURPLE}Solutions:${NC}"
        sqlite3 -column -header "$CODEX_DB" <<EOF
SELECT
    name,
    category,
    substr(problem, 1, 50) as problem
FROM solutions
WHERE name LIKE '%$query%'
   OR problem LIKE '%$query%'
   OR solution LIKE '%$query%'
   OR tags LIKE '%$query%'
LIMIT 5;
EOF

        echo ""

        # Search patterns
        echo -e "${PURPLE}Patterns:${NC}"
        sqlite3 -column -header "$CODEX_DB" <<EOF
SELECT
    pattern_name,
    pattern_type,
    substr(description, 1, 50) as description
FROM patterns
WHERE pattern_name LIKE '%$query%'
   OR description LIKE '%$query%'
LIMIT 5;
EOF

        echo ""

        # Search best practices
        echo -e "${PURPLE}Best Practices:${NC}"
        sqlite3 -column -header "$CODEX_DB" <<EOF
SELECT
    practice_name,
    category,
    priority
FROM best_practices
WHERE practice_name LIKE '%$query%'
   OR description LIKE '%$query%'
LIMIT 5;
EOF

    else
        # Category-specific search
        case $category in
            solution)
                sqlite3 -column -header "$CODEX_DB" "
                SELECT * FROM solutions WHERE name LIKE '%$query%' OR problem LIKE '%$query%';
                "
                ;;
            pattern)
                sqlite3 -column -header "$CODEX_DB" "
                SELECT * FROM patterns WHERE pattern_name LIKE '%$query%';
                "
                ;;
            practice)
                sqlite3 -column -header "$CODEX_DB" "
                SELECT * FROM best_practices WHERE practice_name LIKE '%$query%';
                "
                ;;
        esac
    fi
}

# Get solution
get_solution() {
    local name="$1"

    echo -e "${CYAN}💡 Retrieving solution: ${YELLOW}$name${NC}\n"

    sqlite3 -column "$CODEX_DB" <<EOF
SELECT
    'Name: ' || name || '
Category: ' || category || '
Success Rate: ' || ROUND(success_rate * 100, 1) || '%
Uses: ' || uses || '

PROBLEM:
' || problem || '

SOLUTION:
' || solution || CASE WHEN code_snippet IS NOT NULL THEN '

CODE:
' || code_snippet ELSE '' END
FROM solutions
WHERE name LIKE '%$name%'
LIMIT 1;
EOF

    # Increment usage counter
    sqlite3 "$CODEX_DB" "UPDATE solutions SET uses = uses + 1 WHERE name LIKE '%$name%'"
}

# Get pattern
get_pattern() {
    local name="$1"

    echo -e "${CYAN}🔍 Retrieving pattern: ${YELLOW}$name${NC}\n"

    sqlite3 -column "$CODEX_DB" <<EOF
SELECT
    'Pattern: ' || pattern_name || '
Type: ' || pattern_type || '
Confidence: ' || ROUND(confidence * 100, 1) || '%
Occurrences: ' || occurrences || '

DESCRIPTION:
' || description || '

WHEN TO USE:
' || when_to_use || CASE WHEN example IS NOT NULL THEN '

EXAMPLE:
' || example ELSE '' END
FROM patterns
WHERE pattern_name LIKE '%$name%'
LIMIT 1;
EOF
}

# List all by category
list_by_category() {
    local type="$1"

    case $type in
        solutions)
            echo -e "${PURPLE}📚 All Solutions:${NC}\n"
            sqlite3 -column -header "$CODEX_DB" "
            SELECT name, category, ROUND(success_rate * 100, 1) || '%' as success, uses
            FROM solutions ORDER BY uses DESC;
            "
            ;;
        patterns)
            echo -e "${PURPLE}🔍 All Patterns:${NC}\n"
            sqlite3 -column -header "$CODEX_DB" "
            SELECT pattern_name, pattern_type, ROUND(confidence * 100, 1) || '%' as conf, occurrences
            FROM patterns ORDER BY confidence DESC;
            "
            ;;
        practices)
            echo -e "${PURPLE}⭐ All Best Practices:${NC}\n"
            sqlite3 -column -header "$CODEX_DB" "
            SELECT category, practice_name, priority
            FROM best_practices ORDER BY
                CASE priority
                    WHEN 'CRITICAL' THEN 1
                    WHEN 'HIGH' THEN 2
                    WHEN 'MEDIUM' THEN 3
                    ELSE 4
                END;
            "
            ;;
        anti-patterns)
            echo -e "${PURPLE}⚠️  All Anti-Patterns:${NC}\n"
            sqlite3 -column -header "$CODEX_DB" "
            SELECT name, severity, occurrences
            FROM anti_patterns ORDER BY
                CASE severity
                    WHEN 'CRITICAL' THEN 1
                    WHEN 'HIGH' THEN 2
                    WHEN 'MEDIUM' THEN 3
                    ELSE 4
                END;
            "
            ;;
        templates)
            echo -e "${PURPLE}📄 All Templates:${NC}\n"
            sqlite3 -column -header "$CODEX_DB" "
            SELECT template_name, template_type, ROUND(success_rate * 100, 1) || '%' as success, usage_count
            FROM templates ORDER BY usage_count DESC;
            "
            ;;
        *)
            echo -e "${RED}Unknown type: $type${NC}"
            echo "Valid types: solutions, patterns, practices, anti-patterns, templates"
            ;;
    esac
}

# Recommend based on problem
recommend() {
    local problem="$1"

    echo -e "${CYAN}💡 Recommendations for: ${YELLOW}$problem${NC}\n"

    # Search for matching solutions
    echo -e "${PURPLE}Relevant Solutions:${NC}"
    sqlite3 -column "$CODEX_DB" <<EOF
SELECT
    name,
    ROUND(success_rate * 100, 1) || '%' as success
FROM solutions
WHERE problem LIKE '%$problem%'
   OR name LIKE '%$problem%'
ORDER BY success_rate DESC, uses DESC
LIMIT 3;
EOF

    echo ""

    # Search for matching patterns
    echo -e "${PURPLE}Relevant Patterns:${NC}"
    sqlite3 -column "$CODEX_DB" <<EOF
SELECT
    pattern_name,
    pattern_type
FROM patterns
WHERE description LIKE '%$problem%'
   OR when_to_use LIKE '%$problem%'
ORDER BY confidence DESC
LIMIT 3;
EOF

    echo ""

    # Search for matching best practices
    echo -e "${PURPLE}Relevant Best Practices:${NC}"
    sqlite3 -column "$CODEX_DB" <<EOF
SELECT
    practice_name,
    priority
FROM best_practices
WHERE practice_name LIKE '%$problem%'
   OR description LIKE '%$problem%'
ORDER BY
    CASE priority
        WHEN 'CRITICAL' THEN 1
        WHEN 'HIGH' THEN 2
        ELSE 3
    END
LIMIT 3;
EOF
}

# Export codex
export_codex() {
    local format="${1:-markdown}"
    local output_file="$CODEX_DIR/codex-export-$(date +%Y%m%d-%H%M%S).$format"

    echo -e "${CYAN}💾 Exporting codex...${NC}\n"

    if [ "$format" = "markdown" ]; then
        cat > "$output_file" <<'MDEOF'
# 📚 BlackRoad Memory Codex Export

## Solutions

MDEOF

        sqlite3 "$CODEX_DB" "SELECT '### ' || name || '\n**Category:** ' || category || '\n**Success Rate:** ' || ROUND(success_rate * 100, 1) || '%\n\n**Problem:**\n' || problem || '\n\n**Solution:**\n' || solution || '\n\n---\n' FROM solutions;" >> "$output_file"

        cat >> "$output_file" <<'MDEOF'

## Patterns

MDEOF

        sqlite3 "$CODEX_DB" "SELECT '### ' || pattern_name || '\n**Type:** ' || pattern_type || '\n**Confidence:** ' || ROUND(confidence * 100, 1) || '%\n\n' || description || '\n\n---\n' FROM patterns;" >> "$output_file"

        cat >> "$output_file" <<'MDEOF'

## Best Practices

MDEOF

        sqlite3 "$CODEX_DB" "SELECT '### ' || practice_name || '\n**Category:** ' || category || '\n**Priority:** ' || priority || '\n\n' || description || '\n\n**Rationale:** ' || rationale || '\n\n---\n' FROM best_practices;" >> "$output_file"

    elif [ "$format" = "json" ]; then
        sqlite3 "$CODEX_DB" <<EOF > "$output_file"
.mode json
SELECT json_object(
    'solutions', (SELECT json_group_array(json_object('name', name, 'category', category, 'problem', problem, 'solution', solution)) FROM solutions),
    'patterns', (SELECT json_group_array(json_object('name', pattern_name, 'type', pattern_type, 'description', description)) FROM patterns),
    'practices', (SELECT json_group_array(json_object('name', practice_name, 'category', category, 'description', description)) FROM best_practices)
);
EOF
    fi

    echo -e "${GREEN}✅ Codex exported to: $output_file${NC}"
}

# Show codex stats
stats() {
    echo -e "${PURPLE}📊 Codex Statistics:${NC}\n"

    local solutions=$(sqlite3 "$CODEX_DB" "SELECT COUNT(*) FROM solutions")
    local patterns=$(sqlite3 "$CODEX_DB" "SELECT COUNT(*) FROM patterns")
    local practices=$(sqlite3 "$CODEX_DB" "SELECT COUNT(*) FROM best_practices")
    local anti_patterns=$(sqlite3 "$CODEX_DB" "SELECT COUNT(*) FROM anti_patterns")
    local templates=$(sqlite3 "$CODEX_DB" "SELECT COUNT(*) FROM templates")
    local lessons=$(sqlite3 "$CODEX_DB" "SELECT COUNT(*) FROM lessons_learned")

    echo -e "  ${CYAN}Solutions:${NC} $solutions"
    echo -e "  ${CYAN}Patterns:${NC} $patterns"
    echo -e "  ${CYAN}Best Practices:${NC} $practices"
    echo -e "  ${CYAN}Anti-Patterns:${NC} $anti_patterns"
    echo -e "  ${CYAN}Templates:${NC} $templates"
    echo -e "  ${CYAN}Lessons Learned:${NC} $lessons\n"

    # Most used solutions
    echo -e "${PURPLE}Most Used Solutions:${NC}"
    sqlite3 -column "$CODEX_DB" "
    SELECT name, uses FROM solutions ORDER BY uses DESC LIMIT 5;
    "

    echo ""

    # Highest confidence patterns
    echo -e "${PURPLE}Highest Confidence Patterns:${NC}"
    sqlite3 -column "$CODEX_DB" "
    SELECT pattern_name, ROUND(confidence * 100, 1) || '%' as conf
    FROM patterns ORDER BY confidence DESC LIMIT 5;
    "
}

# Main execution
case "${1:-help}" in
    init)
        init
        ;;
    add-solution)
        add_solution "$2" "$3" "$4" "$5"
        ;;
    add-pattern)
        add_pattern "$2" "$3" "$4"
        ;;
    search)
        search "$2" "$3"
        ;;
    get-solution)
        get_solution "$2"
        ;;
    get-pattern)
        get_pattern "$2"
        ;;
    list)
        list_by_category "$2"
        ;;
    recommend)
        recommend "$2"
        ;;
    export)
        export_codex "$2"
        ;;
    stats)
        stats
        ;;
    help|*)
        echo -e "${PURPLE}╔════════════════════════════════════════════════╗${NC}"
        echo -e "${PURPLE}║       📚 BlackRoad Memory Codex System       ║${NC}"
        echo -e "${PURPLE}╚════════════════════════════════════════════════╝${NC}\n"
        echo "Living knowledge base of patterns, solutions, and best practices"
        echo ""
        echo "Usage: $0 COMMAND [OPTIONS]"
        echo ""
        echo "Setup:"
        echo "  init                              - Initialize codex"
        echo ""
        echo "Add Knowledge:"
        echo "  add-solution NAME CAT PROBLEM SOL - Add solution"
        echo "  add-pattern NAME TYPE DESC        - Add pattern"
        echo ""
        echo "Retrieve:"
        echo "  search QUERY [TYPE]               - Search codex"
        echo "  get-solution NAME                 - Get specific solution"
        echo "  get-pattern NAME                  - Get specific pattern"
        echo "  recommend PROBLEM                 - Get recommendations"
        echo ""
        echo "Browse:"
        echo "  list solutions                    - List all solutions"
        echo "  list patterns                     - List all patterns"
        echo "  list practices                    - List best practices"
        echo "  list anti-patterns                - List anti-patterns"
        echo "  list templates                    - List templates"
        echo ""
        echo "Export:"
        echo "  stats                             - Show statistics"
        echo "  export [markdown|json]            - Export codex"
        echo ""
        echo "Examples:"
        echo "  $0 init"
        echo "  $0 search retry"
        echo "  $0 get-solution 'Exponential Backoff'"
        echo "  $0 recommend 'high failure rate'"
        echo "  $0 list practices"
        echo "  $0 stats"
        ;;
esac
