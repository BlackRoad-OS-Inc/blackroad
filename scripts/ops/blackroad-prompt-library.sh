#!/bin/bash
# BlackRoad Prompt Library
# Curated collection of AI prompts for the cluster
# Agent: Icarus (b3e01bd9)

PINK='\033[38;5;205m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RESET='\033[0m'

PROMPTS_DIR="$HOME/.blackroad/prompts"
PROMPTS_DB="$PROMPTS_DIR/prompts.db"

# Initialize
init() {
    mkdir -p "$PROMPTS_DIR"/{templates,chains,personas}

    sqlite3 "$PROMPTS_DB" << 'SQL'
CREATE TABLE IF NOT EXISTS prompts (
    id TEXT PRIMARY KEY,
    name TEXT,
    category TEXT,
    description TEXT,
    template TEXT,
    variables TEXT,
    model TEXT DEFAULT 'llama3.2:1b',
    usage_count INTEGER DEFAULT 0,
    rating REAL DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS chains (
    id TEXT PRIMARY KEY,
    name TEXT,
    description TEXT,
    steps TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS personas (
    id TEXT PRIMARY KEY,
    name TEXT,
    system_prompt TEXT,
    traits TEXT,
    model TEXT DEFAULT 'llama3.2:1b'
);
SQL

    # Seed with built-in prompts
    seed_prompts

    echo -e "${GREEN}Prompt library initialized${RESET}"
}

# Seed built-in prompts
seed_prompts() {
    # Check if already seeded
    local count=$(sqlite3 "$PROMPTS_DB" "SELECT COUNT(*) FROM prompts")
    [ "$count" -gt 0 ] && return

    # Analysis prompts
    sqlite3 "$PROMPTS_DB" "INSERT OR IGNORE INTO prompts (id, name, category, description, template, variables, model) VALUES
        ('analyze-sentiment', 'Sentiment Analysis', 'analysis', 'Analyze text sentiment', 'Analyze the sentiment of this text and classify as positive, negative, or neutral. Explain why.\n\nText: {{TEXT}}', 'TEXT', 'llama3.2:1b'),
        ('summarize', 'Summarize Text', 'analysis', 'Create concise summary', 'Summarize the following text in 2-3 sentences, capturing the main points:\n\n{{TEXT}}', 'TEXT', 'llama3.2:1b'),
        ('extract-keywords', 'Extract Keywords', 'analysis', 'Extract key terms', 'Extract the 5 most important keywords from this text:\n\n{{TEXT}}', 'TEXT', 'llama3.2:1b'),
        ('explain-simple', 'Explain Simply', 'analysis', 'Explain for beginners', 'Explain {{TOPIC}} as if you were explaining it to a 10-year-old. Use simple language and examples.', 'TOPIC', 'llama3.2:1b')
    "

    # Coding prompts
    sqlite3 "$PROMPTS_DB" "INSERT OR IGNORE INTO prompts (id, name, category, description, template, variables, model) VALUES
        ('code-review', 'Code Review', 'coding', 'Review code quality', 'Review this code for bugs, security issues, and improvements:\n\n\`\`\`{{LANGUAGE}}\n{{CODE}}\n\`\`\`', 'LANGUAGE,CODE', 'codellama:7b'),
        ('code-explain', 'Explain Code', 'coding', 'Explain what code does', 'Explain what this code does line by line:\n\n\`\`\`{{LANGUAGE}}\n{{CODE}}\n\`\`\`', 'LANGUAGE,CODE', 'codellama:7b'),
        ('code-convert', 'Convert Code', 'coding', 'Convert between languages', 'Convert this {{FROM}} code to {{TO}}:\n\n\`\`\`{{FROM}}\n{{CODE}}\n\`\`\`', 'FROM,TO,CODE', 'codellama:7b'),
        ('code-fix', 'Fix Bug', 'coding', 'Fix code bug', 'This code has a bug. Fix it and explain what was wrong:\n\n\`\`\`{{LANGUAGE}}\n{{CODE}}\n\`\`\`\n\nError: {{ERROR}}', 'LANGUAGE,CODE,ERROR', 'codellama:7b')
    "

    # Creative prompts
    sqlite3 "$PROMPTS_DB" "INSERT OR IGNORE INTO prompts (id, name, category, description, template, variables, model) VALUES
        ('brainstorm', 'Brainstorm Ideas', 'creative', 'Generate ideas', 'Brainstorm 5 creative ideas for: {{TOPIC}}', 'TOPIC', 'llama3.2:1b'),
        ('write-email', 'Write Email', 'creative', 'Draft professional email', 'Write a professional email about {{SUBJECT}} to {{RECIPIENT}}. Tone: {{TONE}}', 'SUBJECT,RECIPIENT,TONE', 'llama3.2:1b'),
        ('storytelling', 'Tell Story', 'creative', 'Create short story', 'Write a short story (100 words) about {{TOPIC}} in the style of {{STYLE}}', 'TOPIC,STYLE', 'llama3.2:1b')
    "

    # System prompts
    sqlite3 "$PROMPTS_DB" "INSERT OR IGNORE INTO prompts (id, name, category, description, template, variables, model) VALUES
        ('sysadmin', 'Sysadmin Help', 'system', 'Linux administration help', 'You are a Linux sysadmin expert. Help with: {{QUESTION}}', 'QUESTION', 'llama3.2:1b'),
        ('docker-help', 'Docker Help', 'system', 'Docker container help', 'You are a Docker expert. Help with: {{QUESTION}}\n\nContext: {{CONTEXT}}', 'QUESTION,CONTEXT', 'llama3.2:1b')
    "

    # Seed personas
    sqlite3 "$PROMPTS_DB" "INSERT OR IGNORE INTO personas (id, name, system_prompt, traits, model) VALUES
        ('lucidia', 'Lucidia', 'You are Lucidia, a helpful AI assistant created by BlackRoad OS. You are friendly, knowledgeable, and slightly playful. You run on a distributed Raspberry Pi cluster.', 'helpful,friendly,playful,technical', 'llama3.2:1b'),
        ('coder', 'CodeBot', 'You are an expert programmer. You write clean, efficient, well-documented code. Always explain your solutions.', 'precise,technical,educational', 'codellama:7b'),
        ('analyst', 'Analyst', 'You are a data analyst. You break down complex problems, identify patterns, and provide actionable insights.', 'analytical,thorough,objective', 'llama3.2:3b'),
        ('creative', 'Creative', 'You are a creative thinker. You generate novel ideas and think outside the box. Be imaginative and unconventional.', 'creative,innovative,playful', 'llama3.2:1b')
    "
}

# Add a prompt
add() {
    local name="$1"
    local category="$2"
    local template="$3"
    local description="${4:-}"
    local variables="${5:-}"
    local model="${6:-llama3.2:1b}"

    local id=$(echo "$name" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')

    sqlite3 "$PROMPTS_DB" "
        INSERT OR REPLACE INTO prompts (id, name, category, description, template, variables, model)
        VALUES ('$id', '$name', '$category', '$description', '$(echo "$template" | sed "s/'/''/g")', '$variables', '$model')
    "

    echo -e "${GREEN}Added prompt: $id${RESET}"
}

# Get and use a prompt
use() {
    local prompt_id="$1"
    shift

    local prompt=$(sqlite3 "$PROMPTS_DB" "
        SELECT template, variables, model FROM prompts WHERE id = '$prompt_id'
    ")

    if [ -z "$prompt" ]; then
        echo -e "${RED}Prompt not found: $prompt_id${RESET}"
        return 1
    fi

    local template=$(echo "$prompt" | cut -d'|' -f1)
    local variables=$(echo "$prompt" | cut -d'|' -f2)
    local model=$(echo "$prompt" | cut -d'|' -f3)

    # Replace variables
    local filled="$template"
    for var in "$@"; do
        local key="${var%%=*}"
        local value="${var#*=}"
        filled=$(echo "$filled" | sed "s/{{$key}}/$value/g")
    done

    # Check for unfilled variables
    if echo "$filled" | grep -q '{{'; then
        echo -e "${YELLOW}Missing variables in prompt${RESET}"
        echo "Required: $variables"
        return 1
    fi

    # Update usage count
    sqlite3 "$PROMPTS_DB" "UPDATE prompts SET usage_count = usage_count + 1 WHERE id = '$prompt_id'"

    echo -e "${BLUE}Using prompt: $prompt_id (model: $model)${RESET}"
    echo
    echo "$filled"
}

# Run prompt against LLM
run() {
    local prompt_id="$1"
    shift
    local node="${RUN_NODE:-cecilia}"

    local filled=$(use "$prompt_id" "$@")
    local model=$(sqlite3 "$PROMPTS_DB" "SELECT model FROM prompts WHERE id = '$prompt_id'")

    echo -e "${PINK}=== RUNNING PROMPT ===${RESET}"
    echo

    ssh -o ConnectTimeout=30 "$node" \
        "curl -s http://localhost:11434/api/generate -d '{\"model\":\"$model\",\"prompt\":\"$filled\",\"stream\":false}'" 2>/dev/null \
        | jq -r '.response // "No response"'
}

# List prompts
list() {
    local category="${1:-all}"

    echo -e "${PINK}=== PROMPT LIBRARY ===${RESET}"
    echo

    local where=""
    [ "$category" != "all" ] && where="WHERE category = '$category'"

    sqlite3 "$PROMPTS_DB" "
        SELECT id, name, category, usage_count FROM prompts $where ORDER BY category, name
    " | while IFS='|' read -r id name category usage; do
        printf "  %-20s %-15s %-12s (%d uses)\n" "$id" "[$category]" "$name" "$usage"
    done

    echo
    echo "Categories:"
    sqlite3 "$PROMPTS_DB" "SELECT DISTINCT category FROM prompts" | tr '\n' ' '
    echo
}

# Search prompts
search() {
    local query="$1"

    echo -e "${PINK}=== SEARCH: $query ===${RESET}"
    echo

    sqlite3 "$PROMPTS_DB" "
        SELECT id, name, description FROM prompts
        WHERE name LIKE '%$query%' OR description LIKE '%$query%' OR template LIKE '%$query%'
    " | while IFS='|' read -r id name desc; do
        echo "  $id: $name"
        echo "    $desc"
    done
}

# Show prompt details
show() {
    local prompt_id="$1"

    local prompt=$(sqlite3 "$PROMPTS_DB" -line "SELECT * FROM prompts WHERE id = '$prompt_id'")

    if [ -z "$prompt" ]; then
        echo -e "${RED}Prompt not found: $prompt_id${RESET}"
        return 1
    fi

    echo -e "${PINK}=== PROMPT: $prompt_id ===${RESET}"
    echo
    echo "$prompt"
}

# List personas
personas() {
    echo -e "${PINK}=== PERSONAS ===${RESET}"
    echo

    sqlite3 "$PROMPTS_DB" "
        SELECT id, name, traits FROM personas
    " | while IFS='|' read -r id name traits; do
        echo "  $id: $name"
        echo "    Traits: $traits"
    done
}

# Chat with persona
chat_persona() {
    local persona_id="$1"
    local node="${CHAT_NODE:-cecilia}"

    local persona=$(sqlite3 "$PROMPTS_DB" "
        SELECT name, system_prompt, model FROM personas WHERE id = '$persona_id'
    ")

    if [ -z "$persona" ]; then
        echo -e "${RED}Persona not found: $persona_id${RESET}"
        return 1
    fi

    local name=$(echo "$persona" | cut -d'|' -f1)
    local system=$(echo "$persona" | cut -d'|' -f2)
    local model=$(echo "$persona" | cut -d'|' -f3)

    echo -e "${PINK}╔══════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${PINK}║           💬 CHAT WITH $name                                 ║${RESET}"
    echo -e "${PINK}╚══════════════════════════════════════════════════════════════╝${RESET}"
    echo
    echo "Model: $model | Node: $node"
    echo "Type 'exit' to quit"
    echo

    while true; do
        echo -n -e "${GREEN}You: ${RESET}"
        read -r input

        [ "$input" = "exit" ] && break

        local prompt="$system\n\nUser: $input\n$name:"

        echo -n -e "${CYAN}$name: ${RESET}"
        ssh "$node" "curl -s http://localhost:11434/api/generate -d '{\"model\":\"$model\",\"prompt\":\"$prompt\",\"stream\":false}'" 2>/dev/null \
            | jq -r '.response // "..."'
        echo
    done
}

# Create prompt chain
chain() {
    local name="$1"
    local steps="$2"
    local description="${3:-}"

    local id=$(echo "$name" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')

    sqlite3 "$PROMPTS_DB" "
        INSERT OR REPLACE INTO chains (id, name, description, steps)
        VALUES ('$id', '$name', '$description', '$steps')
    "

    echo -e "${GREEN}Created chain: $id${RESET}"
}

# Run chain
run_chain() {
    local chain_id="$1"
    local input="$2"

    local chain=$(sqlite3 "$PROMPTS_DB" "SELECT steps FROM chains WHERE id = '$chain_id'")

    if [ -z "$chain" ]; then
        echo -e "${RED}Chain not found: $chain_id${RESET}"
        return 1
    fi

    echo -e "${PINK}=== RUNNING CHAIN: $chain_id ===${RESET}"
    echo

    local result="$input"
    local step_num=0

    for prompt_id in $(echo "$chain" | tr ',' '\n'); do
        ((step_num++))
        echo -e "${BLUE}[Step $step_num: $prompt_id]${RESET}"

        result=$(run "$prompt_id" "TEXT=$result" 2>/dev/null)
        echo "$result"
        echo
    done
}

# Rate prompt
rate() {
    local prompt_id="$1"
    local rating="$2"

    if [ "$rating" -lt 1 ] || [ "$rating" -gt 5 ]; then
        echo "Rating must be 1-5"
        return 1
    fi

    sqlite3 "$PROMPTS_DB" "UPDATE prompts SET rating = $rating WHERE id = '$prompt_id'"
    echo -e "${GREEN}Rated $prompt_id: $rating/5${RESET}"
}

# Export prompts
export_prompts() {
    local format="${1:-json}"

    case "$format" in
        json)
            sqlite3 "$PROMPTS_DB" -json "SELECT * FROM prompts"
            ;;
        markdown)
            echo "# BlackRoad Prompt Library"
            echo
            sqlite3 "$PROMPTS_DB" "SELECT category, id, name, description, template FROM prompts ORDER BY category" | while IFS='|' read -r cat id name desc tmpl; do
                echo "## $cat / $name ($id)"
                echo "$desc"
                echo '```'
                echo "$tmpl"
                echo '```'
                echo
            done
            ;;
    esac
}

# Help
help() {
    echo -e "${PINK}BlackRoad Prompt Library${RESET}"
    echo
    echo "Curated AI prompts for the cluster"
    echo
    echo "Commands:"
    echo "  list [category]           List prompts"
    echo "  search <query>            Search prompts"
    echo "  show <id>                 Show prompt details"
    echo "  use <id> [VAR=val...]     Fill prompt template"
    echo "  run <id> [VAR=val...]     Run prompt on LLM"
    echo "  add <name> <cat> <tmpl>   Add custom prompt"
    echo "  personas                  List personas"
    echo "  chat <persona>            Chat with persona"
    echo "  chain <name> <steps>      Create prompt chain"
    echo "  run-chain <id> <input>    Run prompt chain"
    echo "  rate <id> <1-5>           Rate prompt"
    echo "  export [json|markdown]    Export prompts"
    echo
    echo "Examples:"
    echo "  $0 list coding"
    echo "  $0 run summarize TEXT='Long text here'"
    echo "  $0 chat lucidia"
    echo "  $0 chain 'analyze' 'summarize,extract-keywords'"
}

# Ensure initialized
[ -f "$PROMPTS_DB" ] || init >/dev/null

case "${1:-help}" in
    init)
        init
        ;;
    add)
        add "$2" "$3" "$4" "$5" "$6" "$7"
        ;;
    use|fill)
        shift
        use "$@"
        ;;
    run|exec)
        shift
        run "$@"
        ;;
    list|ls)
        list "$2"
        ;;
    search|find)
        search "$2"
        ;;
    show|info)
        show "$2"
        ;;
    personas)
        personas
        ;;
    chat)
        chat_persona "$2"
        ;;
    chain)
        chain "$2" "$3" "$4"
        ;;
    run-chain)
        run_chain "$2" "$3"
        ;;
    rate)
        rate "$2" "$3"
        ;;
    export)
        export_prompts "$2"
        ;;
    *)
        help
        ;;
esac
