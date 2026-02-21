#!/bin/bash
# BlackRoad Workflow Engine
# Define and execute multi-step AI pipelines across the cluster
# Agent: Icarus (b3e01bd9)

PINK='\033[38;5;205m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
RESET='\033[0m'

WORKFLOWS_DIR="$HOME/.blackroad/workflows"
RUNS_DIR="$WORKFLOWS_DIR/runs"

# Available step types
# - llm: Query an LLM
# - vision: Run vision inference
# - code: Execute code in sandbox
# - transform: Transform data (jq, sed, etc.)
# - branch: Conditional branch
# - parallel: Run steps in parallel

# Initialize
init() {
    mkdir -p "$WORKFLOWS_DIR" "$RUNS_DIR"
    echo -e "${GREEN}Workflow engine initialized${RESET}"
}

# Create a new workflow
create() {
    local name="$1"

    if [ -z "$name" ]; then
        echo "Usage: create <workflow_name>"
        return 1
    fi

    local workflow_file="$WORKFLOWS_DIR/$name.yaml"

    cat > "$workflow_file" << 'EOF'
# BlackRoad Workflow Definition
name: example-workflow
description: Example AI workflow

# Variables available in steps
variables:
  model: llama3.2:1b
  node: cecilia

# Workflow steps (executed in order)
steps:
  - name: analyze
    type: llm
    prompt: "Analyze this input: ${input}"
    output: analysis

  - name: summarize
    type: llm
    prompt: "Summarize: ${analysis}"
    output: summary

  - name: format
    type: transform
    transform: "jq -r '.'"
    input: ${summary}
    output: result

# Output mapping
outputs:
  - analysis
  - summary
  - result
EOF

    echo -e "${GREEN}Created workflow: $workflow_file${RESET}"
    echo "Edit the YAML file to customize your workflow"
}

# Parse workflow YAML (simplified parser)
parse_workflow() {
    local file="$1"
    local section="$2"

    grep -A 100 "^$section:" "$file" | tail -n +2 | while read -r line; do
        [[ "$line" =~ ^[a-z] ]] && break
        echo "$line"
    done
}

# Execute LLM step
exec_llm_step() {
    local prompt="$1"
    local model="${2:-llama3.2:1b}"
    local node="${3:-cecilia}"

    ssh -o ConnectTimeout=30 "$node" \
        "curl -s http://localhost:11434/api/generate -d '{\"model\":\"$model\",\"prompt\":\"$prompt\",\"stream\":false}'" 2>/dev/null \
        | jq -r '.response // "ERROR"'
}

# Execute vision step
exec_vision_step() {
    local image="$1"
    local prompt="${2:-Describe this image}"
    local node="${3:-cecilia}"

    # Use Hailo for detection + LLM for description
    ssh -o ConnectTimeout=30 "$node" \
        "python3 -c \"
import cv2
from hailo_platform import HEF, InferVStreams, ConfigureParams, InputVStreamParams, OutputVStreamParams

# Simplified - would need full implementation
print('Vision inference on: $image')
print('Detected: [objects]')
\""
}

# Execute code step
exec_code_step() {
    local code="$1"
    local lang="${2:-python}"

    ~/blackroad-code-sandbox.sh exec "$lang" "$code" 2>/dev/null
}

# Execute transform step
exec_transform_step() {
    local input="$1"
    local transform="$2"

    echo "$input" | eval "$transform"
}

# Run workflow
run() {
    local workflow_name="$1"
    shift
    local input="$*"

    local workflow_file="$WORKFLOWS_DIR/$workflow_name.yaml"
    if [ ! -f "$workflow_file" ]; then
        echo -e "${RED}Workflow not found: $workflow_name${RESET}"
        return 1
    fi

    local run_id=$(date +%Y%m%d_%H%M%S)_$(openssl rand -hex 4)
    local run_dir="$RUNS_DIR/$run_id"
    mkdir -p "$run_dir"

    echo -e "${PINK}╔══════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${PINK}║           🔄 WORKFLOW EXECUTION 🔄                           ║${RESET}"
    echo -e "${PINK}╚══════════════════════════════════════════════════════════════╝${RESET}"
    echo
    echo "Workflow: $workflow_name"
    echo "Run ID: $run_id"
    echo "Input: $input"
    echo

    # Initialize context with input
    declare -A context
    context[input]="$input"

    # Save run metadata
    echo "{\"workflow\":\"$workflow_name\",\"run_id\":\"$run_id\",\"input\":\"$input\",\"started\":\"$(date -Iseconds)\",\"status\":\"running\"}" > "$run_dir/meta.json"

    # Parse and execute steps (simplified YAML parsing)
    local step_num=0
    local current_step=""
    local step_type=""
    local step_prompt=""
    local step_output=""

    while IFS= read -r line; do
        # New step
        if [[ "$line" =~ "- name:" ]]; then
            # Execute previous step if exists
            if [ -n "$current_step" ]; then
                execute_step "$current_step" "$step_type" "$step_prompt" "$step_output" "$run_dir"
            fi

            current_step=$(echo "$line" | sed 's/.*name: //')
            ((step_num++))
            echo -e "${BLUE}[Step $step_num: $current_step]${RESET}"
            step_type=""
            step_prompt=""
            step_output=""
        elif [[ "$line" =~ "type:" ]]; then
            step_type=$(echo "$line" | sed 's/.*type: //')
        elif [[ "$line" =~ "prompt:" ]]; then
            step_prompt=$(echo "$line" | sed 's/.*prompt: "//' | sed 's/"$//')
            # Variable substitution
            for key in "${!context[@]}"; do
                step_prompt="${step_prompt//\$\{$key\}/${context[$key]}}"
            done
        elif [[ "$line" =~ "output:" ]]; then
            step_output=$(echo "$line" | sed 's/.*output: //')
        fi
    done < "$workflow_file"

    # Execute last step
    if [ -n "$current_step" ]; then
        execute_step "$current_step" "$step_type" "$step_prompt" "$step_output" "$run_dir"
    fi

    # Mark complete
    jq '.status = "completed" | .completed = "'"$(date -Iseconds)"'"' "$run_dir/meta.json" > "$run_dir/meta.json.tmp" && mv "$run_dir/meta.json.tmp" "$run_dir/meta.json"

    echo
    echo -e "${GREEN}Workflow complete!${RESET}"
    echo "Results: $run_dir"
}

# Execute a single step
execute_step() {
    local name="$1"
    local type="$2"
    local prompt="$3"
    local output_var="$4"
    local run_dir="$5"

    local result=""
    local start_time=$(date +%s%N)

    case "$type" in
        llm)
            echo "  Querying LLM..."
            result=$(exec_llm_step "$prompt")
            ;;
        vision)
            echo "  Running vision..."
            result=$(exec_vision_step "$prompt")
            ;;
        code)
            echo "  Executing code..."
            result=$(exec_code_step "$prompt")
            ;;
        transform)
            echo "  Transforming..."
            result=$(exec_transform_step "${context[$output_var]}" "$prompt")
            ;;
        *)
            echo "  Unknown step type: $type"
            result="ERROR"
            ;;
    esac

    local end_time=$(date +%s%N)
    local duration=$(( (end_time - start_time) / 1000000 ))

    # Save step result
    echo "$result" > "$run_dir/step_${name}.txt"

    # Update context
    context[$output_var]="$result"

    # Show preview
    local preview="${result:0:100}"
    [ ${#result} -gt 100 ] && preview+="..."
    echo -e "  ${GREEN}✓${RESET} $preview (${duration}ms)"
}

# List workflows
list() {
    echo -e "${PINK}=== AVAILABLE WORKFLOWS ===${RESET}"
    echo

    for f in "$WORKFLOWS_DIR"/*.yaml; do
        [ -f "$f" ] || continue
        local name=$(basename "$f" .yaml)
        local desc=$(grep "^description:" "$f" | head -1 | sed 's/description: //')
        echo "  $name: $desc"
    done
}

# Show workflow runs
runs() {
    echo -e "${PINK}=== WORKFLOW RUNS ===${RESET}"
    echo

    for d in "$RUNS_DIR"/*/; do
        [ -d "$d" ] || continue
        local run_id=$(basename "$d")
        local workflow=$(jq -r '.workflow' "$d/meta.json" 2>/dev/null)
        local status=$(jq -r '.status' "$d/meta.json" 2>/dev/null)
        local started=$(jq -r '.started' "$d/meta.json" 2>/dev/null | cut -dT -f1)

        local color=$GREEN
        [ "$status" = "failed" ] && color=$RED
        [ "$status" = "running" ] && color=$YELLOW

        echo "  $run_id: $workflow [${color}$status${RESET}] ($started)"
    done
}

# Example workflows
examples() {
    # Analysis pipeline
    cat > "$WORKFLOWS_DIR/analyze-text.yaml" << 'EOF'
name: analyze-text
description: Analyze text with sentiment and key points

variables:
  model: llama3.2:1b

steps:
  - name: sentiment
    type: llm
    prompt: "Analyze the sentiment of this text (positive/negative/neutral) and explain why: ${input}"
    output: sentiment

  - name: key_points
    type: llm
    prompt: "List 3 key points from this text: ${input}"
    output: key_points

  - name: summary
    type: llm
    prompt: "Write a one-sentence summary combining sentiment (${sentiment}) and key points (${key_points})"
    output: summary

outputs:
  - sentiment
  - key_points
  - summary
EOF

    # Code review pipeline
    cat > "$WORKFLOWS_DIR/code-review.yaml" << 'EOF'
name: code-review
description: AI-powered code review pipeline

variables:
  model: codellama:7b

steps:
  - name: analyze_bugs
    type: llm
    prompt: "Find potential bugs in this code: ${input}"
    output: bugs

  - name: security_check
    type: llm
    prompt: "Check for security vulnerabilities: ${input}"
    output: security

  - name: suggestions
    type: llm
    prompt: "Suggest improvements for this code. Bugs found: ${bugs}. Security issues: ${security}"
    output: suggestions

  - name: final_report
    type: llm
    prompt: "Write a code review report with: Bugs: ${bugs}, Security: ${security}, Suggestions: ${suggestions}"
    output: report

outputs:
  - report
EOF

    echo -e "${GREEN}Created example workflows:${RESET}"
    echo "  - analyze-text: Text sentiment and key points"
    echo "  - code-review: AI code review pipeline"
}

# Help
help() {
    echo -e "${PINK}BlackRoad Workflow Engine${RESET}"
    echo
    echo "Define and execute multi-step AI pipelines"
    echo
    echo "Commands:"
    echo "  create <name>       Create new workflow template"
    echo "  run <name> <input>  Execute workflow"
    echo "  list                List available workflows"
    echo "  runs                Show workflow run history"
    echo "  examples            Create example workflows"
    echo
    echo "Step types:"
    echo "  llm        Query an LLM model"
    echo "  vision     Run vision inference"
    echo "  code       Execute code in sandbox"
    echo "  transform  Transform data with shell commands"
    echo
    echo "Examples:"
    echo "  $0 examples"
    echo "  $0 run analyze-text 'The product is amazing!'"
    echo "  $0 run code-review 'def foo(): return x'"
}

# Ensure initialized
[ -d "$WORKFLOWS_DIR" ] || init >/dev/null

case "${1:-help}" in
    init)
        init
        ;;
    create|new)
        create "$2"
        ;;
    run|exec)
        shift
        run "$@"
        ;;
    list|ls)
        list
        ;;
    runs|history)
        runs
        ;;
    examples)
        examples
        ;;
    *)
        help
        ;;
esac
