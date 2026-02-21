#!/bin/bash
# BlackRoad RAG Pipeline
# Retrieval-Augmented Generation using the Pi cluster
# Agent: Icarus (b3e01bd9)

PINK='\033[38;5;205m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RESET='\033[0m'

RAG_DIR="$HOME/.blackroad/rag"
DOCS_DIR="$RAG_DIR/documents"
CHUNKS_DIR="$RAG_DIR/chunks"
INDEX_FILE="$RAG_DIR/index.json"

LLM_NODE="cecilia"  # Primary LLM node
DEFAULT_MODEL="llama3.2:1b"
CHUNK_SIZE=500  # Characters per chunk

# Initialize
init() {
    mkdir -p "$DOCS_DIR" "$CHUNKS_DIR"
    [ -f "$INDEX_FILE" ] || echo '{"documents":[],"chunks":[]}' > "$INDEX_FILE"
    echo -e "${GREEN}RAG pipeline initialized${RESET}"
    echo "  Documents: $DOCS_DIR"
    echo "  Chunks: $CHUNKS_DIR"
    echo "  Index: $INDEX_FILE"
}

# Add document to knowledge base
add_document() {
    local file="$1"
    local name=$(basename "$file")
    local doc_id=$(echo "$name$(date +%s)" | md5sum | head -c 8)

    if [ ! -f "$file" ]; then
        echo -e "${YELLOW}File not found: $file${RESET}"
        return 1
    fi

    echo -e "${BLUE}Processing: $name${RESET}"

    # Copy to docs dir
    cp "$file" "$DOCS_DIR/$doc_id-$name"

    # Extract text (handle different file types)
    local content=""
    case "$name" in
        *.txt|*.md|*.sh|*.py|*.js|*.ts)
            content=$(cat "$file")
            ;;
        *.json)
            content=$(cat "$file" | jq -r '.' 2>/dev/null || cat "$file")
            ;;
        *.pdf)
            if command -v pdftotext &>/dev/null; then
                content=$(pdftotext "$file" - 2>/dev/null)
            else
                echo "  Warning: pdftotext not available, storing as-is"
                content=$(cat "$file")
            fi
            ;;
        *)
            content=$(cat "$file")
            ;;
    esac

    # Chunk the content
    local total_chars=${#content}
    local num_chunks=$(( (total_chars + CHUNK_SIZE - 1) / CHUNK_SIZE ))

    echo "  Size: $total_chars chars"
    echo "  Chunks: $num_chunks"

    for ((i=0; i<num_chunks; i++)); do
        local start=$((i * CHUNK_SIZE))
        local chunk="${content:$start:$CHUNK_SIZE}"
        local chunk_id="${doc_id}_chunk_$i"

        # Save chunk
        echo "$chunk" > "$CHUNKS_DIR/$chunk_id.txt"

        # Add to index
        jq --arg doc_id "$doc_id" \
           --arg chunk_id "$chunk_id" \
           --arg name "$name" \
           --arg content "${chunk:0:100}..." \
           '.chunks += [{"doc_id": $doc_id, "chunk_id": $chunk_id, "name": $name, "preview": $content}]' \
           "$INDEX_FILE" > "$INDEX_FILE.tmp" && mv "$INDEX_FILE.tmp" "$INDEX_FILE"
    done

    # Add document to index
    jq --arg doc_id "$doc_id" \
       --arg name "$name" \
       --argjson chunks "$num_chunks" \
       --arg added "$(date -Iseconds)" \
       '.documents += [{"id": $doc_id, "name": $name, "chunks": $chunks, "added": $added}]' \
       "$INDEX_FILE" > "$INDEX_FILE.tmp" && mv "$INDEX_FILE.tmp" "$INDEX_FILE"

    echo -e "${GREEN}Added: $doc_id${RESET}"
}

# Simple keyword search (no embeddings needed)
search_chunks() {
    local query="$1"
    local max_results="${2:-5}"
    local results=()

    # Search through chunks for keyword matches
    for chunk_file in "$CHUNKS_DIR"/*.txt; do
        [ -f "$chunk_file" ] || continue

        local matches=$(grep -ci "$query" "$chunk_file" 2>/dev/null || echo 0)
        if [ "$matches" -gt 0 ]; then
            local chunk_id=$(basename "$chunk_file" .txt)
            results+=("$matches:$chunk_id")
        fi
    done

    # Sort by match count and return top results
    printf '%s\n' "${results[@]}" | sort -t: -k1 -rn | head -n "$max_results" | cut -d: -f2
}

# RAG query - search documents and augment LLM with context
query() {
    local question="$*"

    echo -e "${PINK}=== RAG QUERY ===${RESET}"
    echo -e "Question: $question"
    echo

    # Extract keywords from question (simple approach)
    local keywords=$(echo "$question" | tr '[:upper:]' '[:lower:]' | tr -cs '[:alnum:]' '\n' | sort -u | head -10)

    # Search for relevant chunks
    local context=""
    local found_chunks=0

    for keyword in $keywords; do
        [ ${#keyword} -lt 3 ] && continue  # Skip short words

        local chunks=$(search_chunks "$keyword" 3)
        for chunk_id in $chunks; do
            if [ -f "$CHUNKS_DIR/$chunk_id.txt" ]; then
                local chunk_content=$(cat "$CHUNKS_DIR/$chunk_id.txt")
                context+="--- $chunk_id ---\n$chunk_content\n\n"
                ((found_chunks++))
            fi
        done
    done

    echo -e "${BLUE}Found $found_chunks relevant chunks${RESET}"
    echo

    # Build RAG prompt
    local prompt="You are a helpful assistant. Use the following context to answer the question. If the context doesn't contain relevant information, say so.

CONTEXT:
$context

QUESTION: $question

ANSWER:"

    # Query LLM with context
    echo -e "${GREEN}Generating answer...${RESET}"
    echo

    local response=$(ssh -o ConnectTimeout=30 "$LLM_NODE" \
        "curl -s http://localhost:11434/api/generate -d '{\"model\":\"$DEFAULT_MODEL\",\"prompt\":\"$prompt\",\"stream\":false}'" 2>/dev/null \
        | jq -r '.response // "No response"')

    echo -e "${PINK}Answer:${RESET}"
    echo "$response"
}

# Interactive RAG chat
chat() {
    echo -e "${PINK}╔══════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${PINK}║           📚 RAG KNOWLEDGE ASSISTANT 📚                      ║${RESET}"
    echo -e "${PINK}╚══════════════════════════════════════════════════════════════╝${RESET}"
    echo

    local doc_count=$(jq '.documents | length' "$INDEX_FILE" 2>/dev/null || echo 0)
    local chunk_count=$(jq '.chunks | length' "$INDEX_FILE" 2>/dev/null || echo 0)

    echo "Knowledge base: $doc_count documents, $chunk_count chunks"
    echo "Type 'exit' to quit, 'docs' to list documents"
    echo

    while true; do
        echo -n -e "${GREEN}You: ${RESET}"
        read -r input

        case "$input" in
            exit|quit|q)
                echo "Goodbye!"
                break
                ;;
            docs|list)
                list_documents
                ;;
            "")
                continue
                ;;
            *)
                query "$input"
                echo
                ;;
        esac
    done
}

# List documents in knowledge base
list_documents() {
    echo -e "${PINK}=== KNOWLEDGE BASE ===${RESET}"
    echo

    jq -r '.documents[] | "  \(.id): \(.name) (\(.chunks) chunks)"' "$INDEX_FILE" 2>/dev/null

    local total=$(jq '.documents | length' "$INDEX_FILE" 2>/dev/null || echo 0)
    echo
    echo "Total: $total documents"
}

# Remove document
remove_document() {
    local doc_id="$1"

    # Remove chunks
    rm -f "$CHUNKS_DIR/${doc_id}_chunk_"*.txt

    # Remove from index
    jq --arg doc_id "$doc_id" \
       '.documents = [.documents[] | select(.id != $doc_id)] | .chunks = [.chunks[] | select(.doc_id != $doc_id)]' \
       "$INDEX_FILE" > "$INDEX_FILE.tmp" && mv "$INDEX_FILE.tmp" "$INDEX_FILE"

    rm -f "$DOCS_DIR/$doc_id-"*

    echo -e "${GREEN}Removed: $doc_id${RESET}"
}

# Stats
stats() {
    echo -e "${PINK}=== RAG PIPELINE STATS ===${RESET}"
    echo

    local doc_count=$(jq '.documents | length' "$INDEX_FILE" 2>/dev/null || echo 0)
    local chunk_count=$(jq '.chunks | length' "$INDEX_FILE" 2>/dev/null || echo 0)
    local docs_size=$(du -sh "$DOCS_DIR" 2>/dev/null | cut -f1)
    local chunks_size=$(du -sh "$CHUNKS_DIR" 2>/dev/null | cut -f1)

    echo "  Documents: $doc_count"
    echo "  Chunks: $chunk_count"
    echo "  Docs size: $docs_size"
    echo "  Chunks size: $chunks_size"
    echo "  Chunk size: $CHUNK_SIZE chars"
    echo "  LLM node: $LLM_NODE"
    echo "  Model: $DEFAULT_MODEL"
}

# Help
help() {
    echo -e "${PINK}BlackRoad RAG Pipeline${RESET}"
    echo
    echo "Retrieval-Augmented Generation for the Pi cluster"
    echo
    echo "Commands:"
    echo "  init                Initialize RAG pipeline"
    echo "  add <file>          Add document to knowledge base"
    echo "  query <question>    Query with RAG"
    echo "  chat                Interactive RAG chat"
    echo "  list                List documents"
    echo "  remove <doc_id>     Remove document"
    echo "  stats               Show statistics"
    echo
    echo "Examples:"
    echo "  $0 add ~/README.md"
    echo "  $0 add ~/docs/*.txt"
    echo "  $0 query 'How does the API work?'"
    echo "  $0 chat"
}

# Ensure initialized
[ -d "$RAG_DIR" ] || init >/dev/null

case "${1:-help}" in
    init)
        init
        ;;
    add)
        shift
        for file in "$@"; do
            add_document "$file"
        done
        ;;
    query|ask)
        shift
        query "$@"
        ;;
    chat)
        chat
        ;;
    list|docs)
        list_documents
        ;;
    remove|rm)
        remove_document "$2"
        ;;
    stats)
        stats
        ;;
    *)
        help
        ;;
esac
