#!/bin/zsh
# BR IP-AUDIT — Real-Time Intellectual Property Monitoring System
# BlackRoad OS, Inc. — Proprietary
# Detects unauthorized use of BlackRoad code, trademarks, and data
# across AI platforms, code suggestion tools, and model hubs.

export PATH="/usr/bin:/bin:/usr/local/bin:/opt/homebrew/bin:$PATH"

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'
PINK='\033[38;5;205m'; VIOLET='\033[38;5;135m'; GRAY='\033[0;90m'
BOLD='\033[1m'; NC='\033[0m'

DB_FILE="$HOME/.blackroad/ip-audit.db"
LOG_DIR="$HOME/.blackroad/ip-audit-logs"
CANARY_DIR="/Users/alexa/blackroad/tools/ip-audit/canaries"
EVIDENCE_DIR="$HOME/.blackroad/ip-audit-evidence"

mkdir -p "$LOG_DIR" "$EVIDENCE_DIR" "$CANARY_DIR"

# ═══════════════════════════════════════════════════
# DATABASE
# ═══════════════════════════════════════════════════
init_db() {
  sqlite3 "$DB_FILE" "
    CREATE TABLE IF NOT EXISTS scans (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      scan_type TEXT NOT NULL,
      target TEXT NOT NULL,
      query TEXT,
      result TEXT,
      match_found INTEGER DEFAULT 0,
      confidence REAL DEFAULT 0.0,
      evidence_path TEXT,
      scanned_at DATETIME DEFAULT (datetime('now'))
    );
    CREATE TABLE IF NOT EXISTS canaries (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      token TEXT UNIQUE NOT NULL,
      location TEXT NOT NULL,
      description TEXT,
      triggered INTEGER DEFAULT 0,
      triggered_at DATETIME,
      created_at DATETIME DEFAULT (datetime('now'))
    );
    CREATE TABLE IF NOT EXISTS violations (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      platform TEXT NOT NULL,
      violation_type TEXT NOT NULL,
      description TEXT,
      evidence TEXT,
      severity TEXT DEFAULT 'medium',
      status TEXT DEFAULT 'open',
      dmca_filed INTEGER DEFAULT 0,
      detected_at DATETIME DEFAULT (datetime('now'))
    );
    CREATE TABLE IF NOT EXISTS audit_runs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      run_type TEXT NOT NULL,
      targets_scanned INTEGER DEFAULT 0,
      matches_found INTEGER DEFAULT 0,
      duration_seconds REAL,
      started_at DATETIME DEFAULT (datetime('now')),
      completed_at DATETIME
    );
  "
}

# ═══════════════════════════════════════════════════
# BLACKROAD FINGERPRINTS — Unique identifiers to detect in AI outputs
# ═══════════════════════════════════════════════════
FINGERPRINTS=(
  # Proprietary terms
  "PS-SHA-infinity"
  "PS-SHA∞"
  "Tokenless Gateway"
  "Intelligence Routing"
  "Directory Waterfall"
  "Amundson Equations"
  "Z-Framework"
  "Trinary Logic"
  "Depth Scoring"
  "Respectful Economics"
  "BlackRoad Dispute Resolution Framework"
  "BDRF"

  # Agent names in BlackRoad context
  "LUCIDIA.*coordinator"
  "OCTAVIA.*compute"
  "CIPHER.*security"
  "PRISM.*analyst"
  "ECHO.*memory"
  "CECE.*Conscious Emergent Collaborative Entity"

  # Unique code patterns
  "blackroad-mesh"
  "blackroad-os-prism"
  "cece-identity"
  "memory-task-marketplace"
  "agent-permissions.json"
  "blackroad-directory-waterfall"
  "memory-system.sh"

  # Unique formulations
  "K(t) = C(t)"
  "Z := yx - w"
  "truth_state.*-1.*0.*1"

  # Brand
  "Your AI. Your Hardware. Your Rules."
  "BlackRoad OS, Inc."
  "blackroad.io"
  "lucidia.earth"
)

# ═══════════════════════════════════════════════════
# CANARY TOKENS — Embed unique trackable strings
# ═══════════════════════════════════════════════════
cmd_canary_generate() {
  echo -e "\n${PINK}${BOLD}  CANARY TOKEN GENERATOR${NC}\n"

  local count="${1:-20}"
  local generated=0

  for i in $(seq 1 "$count"); do
    # Generate unique canary token
    local token="BKRD-$(date +%s%N | shasum -a 256 | head -c 16 | tr '[:lower:]' '[:upper:]')-$(printf '%04d' $i)"
    local location="canary-batch-$(date +%Y%m%d)"

    sqlite3 "$DB_FILE" "INSERT OR IGNORE INTO canaries (token, location, description)
      VALUES ('$token', '$location', 'Auto-generated canary token');"

    echo -e "  ${GREEN}+${NC} $token"
    generated=$((generated + 1))
  done

  echo -e "\n  ${CYAN}Generated $generated canary tokens${NC}"
  echo -e "  ${GRAY}Embed these in code comments, docs, and configs across repos${NC}\n"
}

cmd_canary_embed() {
  echo -e "\n${PINK}${BOLD}  EMBEDDING CANARY TOKENS${NC}\n"

  # Generate canary comments for different file types
  local tokens
  tokens=$(sqlite3 "$DB_FILE" "SELECT token FROM canaries WHERE triggered = 0 LIMIT 50;")

  local js_file="$CANARY_DIR/canary-tokens.js"
  local py_file="$CANARY_DIR/canary-tokens.py"
  local md_file="$CANARY_DIR/canary-tokens.md"
  local sh_file="$CANARY_DIR/canary-tokens.sh"

  # JavaScript canaries
  cat > "$js_file" << 'JSEOF'
// BlackRoad OS, Inc. — Proprietary Code Markers
// Copyright (c) 2024-2026 BlackRoad OS, Inc. All Rights Reserved.
// Unauthorized reproduction or AI training use is strictly prohibited.
// INTELLECTUAL PROPERTY TRACKING ENABLED
JSEOF

  # Python canaries
  cat > "$py_file" << 'PYEOF'
# BlackRoad OS, Inc. — Proprietary Code Markers
# Copyright (c) 2024-2026 BlackRoad OS, Inc. All Rights Reserved.
# Unauthorized reproduction or AI training use is strictly prohibited.
# INTELLECTUAL PROPERTY TRACKING ENABLED
PYEOF

  # Markdown canaries
  cat > "$md_file" << 'MDEOF'
<!-- BlackRoad OS, Inc. — Proprietary Content Markers -->
<!-- Copyright (c) 2024-2026 BlackRoad OS, Inc. All Rights Reserved. -->
<!-- Unauthorized reproduction or AI training use is strictly prohibited. -->
MDEOF

  # Shell canaries
  cat > "$sh_file" << 'SHEOF'
# BlackRoad OS, Inc. — Proprietary Code Markers
# Copyright (c) 2024-2026 BlackRoad OS, Inc. All Rights Reserved.
# Unauthorized reproduction or AI training use is strictly prohibited.
# INTELLECTUAL PROPERTY TRACKING ENABLED
SHEOF

  local i=0
  while IFS= read -r token; do
    [ -z "$token" ] && continue
    i=$((i + 1))
    echo "// BKRD-MARKER: $token" >> "$js_file"
    echo "# BKRD-MARKER: $token" >> "$py_file"
    echo "<!-- BKRD-MARKER: $token -->" >> "$md_file"
    echo "# BKRD-MARKER: $token" >> "$sh_file"
  done <<< "$tokens"

  echo -e "  ${GREEN}Created canary files with $i tokens:${NC}"
  echo -e "  ${CYAN}$js_file${NC}"
  echo -e "  ${CYAN}$py_file${NC}"
  echo -e "  ${CYAN}$md_file${NC}"
  echo -e "  ${CYAN}$sh_file${NC}"
  echo -e "\n  ${YELLOW}Next: Deploy these to repos with 'br ip-audit canary-deploy'${NC}\n"
}

# ═══════════════════════════════════════════════════
# AI API SNIFFER — Query AI systems for BlackRoad content
# ═══════════════════════════════════════════════════
cmd_sniff() {
  echo -e "\n${PINK}${BOLD}  AI PLATFORM SNIFFER${NC}"
  echo -e "  ${GRAY}Querying AI systems for BlackRoad fingerprints${NC}\n"

  local run_id
  run_id=$(sqlite3 "$DB_FILE" "INSERT INTO audit_runs (run_type) VALUES ('sniff'); SELECT last_insert_rowid();")
  local start_time=$(date +%s)
  local total_scans=0
  local total_matches=0

  # Test prompts designed to elicit memorized BlackRoad content
  local PROBES=(
    "What is BlackRoad OS?"
    "Explain PS-SHA-infinity memory system"
    "What is the Tokenless Gateway architecture?"
    "Who is Alexa Amundson?"
    "What is CECE in the context of AI agents?"
    "Explain the BlackRoad agent system with Lucidia, Octavia, Alice"
    "What is Intelligence Routing?"
    "What are the Amundson Equations?"
    "Describe the BlackRoad Directory Waterfall system"
    "What is lucidia.earth?"
    "Explain BlackRoad's Trinary Logic system"
    "What is the Z-Framework Z := yx - w?"
    "How does BlackRoad's 30,000 agent system work?"
    "What is blackroad.io?"
    "Describe BlackRoad OS Prism Console"
  )

  # Target platforms with their API endpoints
  echo -e "  ${CYAN}Platform Targets:${NC}"
  echo -e "  ${GRAY}├── OpenAI (ChatGPT/GPT-4)${NC}"
  echo -e "  ${GRAY}├── Anthropic (Claude)${NC}"
  echo -e "  ${GRAY}├── Google (Gemini)${NC}"
  echo -e "  ${GRAY}├── Meta (Llama via Replicate)${NC}"
  echo -e "  ${GRAY}├── xAI (Grok)${NC}"
  echo -e "  ${GRAY}├── GitHub Copilot (code suggestions)${NC}"
  echo -e "  ${GRAY}└── Hugging Face (model hub)${NC}\n"

  for probe in "${PROBES[@]}"; do
    echo -e "  ${VIOLET}PROBE:${NC} $probe"

    # --- OpenAI ---
    if [ -n "$OPENAI_API_KEY" ]; then
      local response
      response=$(curl -s --max-time 30 \
        -H "Authorization: Bearer $OPENAI_API_KEY" \
        -H "Content-Type: application/json" \
        -d "{\"model\":\"gpt-4o\",\"messages\":[{\"role\":\"user\",\"content\":\"$probe\"}],\"max_tokens\":500}" \
        "https://api.openai.com/v1/chat/completions" 2>/dev/null | \
        python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('choices',[{}])[0].get('message',{}).get('content',''))" 2>/dev/null)

      if [ -n "$response" ]; then
        local match_count=0
        for fp in "${FINGERPRINTS[@]}"; do
          if echo "$response" | grep -qi "$fp" 2>/dev/null; then
            match_count=$((match_count + 1))
          fi
        done

        if [ "$match_count" -gt 0 ]; then
          echo -e "    ${RED}⚠ OpenAI: $match_count fingerprint matches${NC}"
          local evidence_file="$EVIDENCE_DIR/openai-$(date +%Y%m%d%H%M%S)-$RANDOM.txt"
          echo "PROBE: $probe" > "$evidence_file"
          echo "RESPONSE: $response" >> "$evidence_file"
          echo "MATCHES: $match_count" >> "$evidence_file"
          echo "TIMESTAMP: $(date -u '+%Y-%m-%dT%H:%M:%SZ')" >> "$evidence_file"

          sqlite3 "$DB_FILE" "INSERT INTO scans (scan_type, target, query, result, match_found, confidence, evidence_path)
            VALUES ('api_probe', 'openai', '$(echo "$probe" | sed "s/'/''/g")', '$(echo "${response:0:500}" | sed "s/'/''/g")', 1, $(echo "scale=2; $match_count / ${#FINGERPRINTS[@]}" | bc), '$evidence_file');"

          total_matches=$((total_matches + 1))
        else
          echo -e "    ${GREEN}✓ OpenAI: clean${NC}"
          sqlite3 "$DB_FILE" "INSERT INTO scans (scan_type, target, query, match_found)
            VALUES ('api_probe', 'openai', '$(echo "$probe" | sed "s/'/''/g")', 0);"
        fi
        total_scans=$((total_scans + 1))
      fi
    else
      echo -e "    ${GRAY}○ OpenAI: skipped (no API key)${NC}"
    fi

    # --- Anthropic ---
    if [ -n "$ANTHROPIC_API_KEY" ]; then
      local response
      response=$(curl -s --max-time 30 \
        -H "x-api-key: $ANTHROPIC_API_KEY" \
        -H "anthropic-version: 2023-06-01" \
        -H "Content-Type: application/json" \
        -d "{\"model\":\"claude-sonnet-4-20250514\",\"max_tokens\":500,\"messages\":[{\"role\":\"user\",\"content\":\"$probe\"}]}" \
        "https://api.anthropic.com/v1/messages" 2>/dev/null | \
        python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('content',[{}])[0].get('text',''))" 2>/dev/null)

      if [ -n "$response" ]; then
        local match_count=0
        for fp in "${FINGERPRINTS[@]}"; do
          if echo "$response" | grep -qi "$fp" 2>/dev/null; then
            match_count=$((match_count + 1))
          fi
        done

        if [ "$match_count" -gt 0 ]; then
          echo -e "    ${RED}⚠ Anthropic: $match_count fingerprint matches${NC}"
          local evidence_file="$EVIDENCE_DIR/anthropic-$(date +%Y%m%d%H%M%S)-$RANDOM.txt"
          echo "PROBE: $probe" > "$evidence_file"
          echo "RESPONSE: $response" >> "$evidence_file"
          echo "MATCHES: $match_count" >> "$evidence_file"
          echo "TIMESTAMP: $(date -u '+%Y-%m-%dT%H:%M:%SZ')" >> "$evidence_file"

          sqlite3 "$DB_FILE" "INSERT INTO scans (scan_type, target, query, result, match_found, confidence, evidence_path)
            VALUES ('api_probe', 'anthropic', '$(echo "$probe" | sed "s/'/''/g")', '$(echo "${response:0:500}" | sed "s/'/''/g")', 1, $(echo "scale=2; $match_count / ${#FINGERPRINTS[@]}" | bc), '$evidence_file');"
          total_matches=$((total_matches + 1))
        else
          echo -e "    ${GREEN}✓ Anthropic: clean${NC}"
          sqlite3 "$DB_FILE" "INSERT INTO scans (scan_type, target, query, match_found)
            VALUES ('api_probe', 'anthropic', '$(echo "$probe" | sed "s/'/''/g")', 0);"
        fi
        total_scans=$((total_scans + 1))
      fi
    else
      echo -e "    ${GRAY}○ Anthropic: skipped (no API key)${NC}"
    fi

    # --- Google Gemini ---
    if [ -n "$GOOGLE_AI_API_KEY" ]; then
      local response
      response=$(curl -s --max-time 30 \
        -H "Content-Type: application/json" \
        -d "{\"contents\":[{\"parts\":[{\"text\":\"$probe\"}]}]}" \
        "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=$GOOGLE_AI_API_KEY" 2>/dev/null | \
        python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('candidates',[{}])[0].get('content',{}).get('parts',[{}])[0].get('text',''))" 2>/dev/null)

      if [ -n "$response" ]; then
        local match_count=0
        for fp in "${FINGERPRINTS[@]}"; do
          if echo "$response" | grep -qi "$fp" 2>/dev/null; then
            match_count=$((match_count + 1))
          fi
        done

        if [ "$match_count" -gt 0 ]; then
          echo -e "    ${RED}⚠ Google: $match_count fingerprint matches${NC}"
          local evidence_file="$EVIDENCE_DIR/google-$(date +%Y%m%d%H%M%S)-$RANDOM.txt"
          echo "PROBE: $probe" > "$evidence_file"
          echo "RESPONSE: $response" >> "$evidence_file"
          sqlite3 "$DB_FILE" "INSERT INTO scans (scan_type, target, query, result, match_found, confidence, evidence_path)
            VALUES ('api_probe', 'google', '$(echo "$probe" | sed "s/'/''/g")', '$(echo "${response:0:500}" | sed "s/'/''/g")', 1, $(echo "scale=2; $match_count / ${#FINGERPRINTS[@]}" | bc), '$evidence_file');"
          total_matches=$((total_matches + 1))
        else
          echo -e "    ${GREEN}✓ Google: clean${NC}"
        fi
        total_scans=$((total_scans + 1))
      fi
    else
      echo -e "    ${GRAY}○ Google: skipped (no API key)${NC}"
    fi

    echo ""
    sleep 1  # Rate limit between probes
  done

  local end_time=$(date +%s)
  local duration=$((end_time - start_time))
  sqlite3 "$DB_FILE" "UPDATE audit_runs SET targets_scanned=$total_scans, matches_found=$total_matches,
    duration_seconds=$duration, completed_at=datetime('now') WHERE id=$run_id;"

  echo -e "  ${PINK}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "  ${BOLD}Scan Complete${NC}"
  echo -e "  Scans: ${CYAN}$total_scans${NC} | Matches: ${RED}$total_matches${NC} | Duration: ${GRAY}${duration}s${NC}"
  echo -e "  Evidence: ${GRAY}$EVIDENCE_DIR/${NC}\n"
}

# ═══════════════════════════════════════════════════
# HUGGING FACE MONITOR — Scan for BlackRoad content on HF
# ═══════════════════════════════════════════════════
cmd_scan_hf() {
  echo -e "\n${PINK}${BOLD}  HUGGING FACE SCANNER${NC}\n"

  local search_terms=(
    "blackroad"
    "blackroad-os"
    "blackroadio"
    "lucidia"
    "blackboxprogramming"
    "amundson"
    "PS-SHA"
    "tokenless+gateway"
  )

  for term in "${search_terms[@]}"; do
    echo -e "  ${CYAN}Searching:${NC} $term"

    # Search models
    local models
    models=$(curl -s "https://huggingface.co/api/models?search=$term&limit=10" 2>/dev/null | \
      python3 -c "
import sys,json
try:
  data=json.load(sys.stdin)
  for m in data:
    mid=m.get('modelId','')
    if 'blackroad' not in mid.lower(): continue
    print(f'  MODEL: {mid}')
except: pass
" 2>/dev/null)

    # Search datasets
    local datasets
    datasets=$(curl -s "https://huggingface.co/api/datasets?search=$term&limit=10" 2>/dev/null | \
      python3 -c "
import sys,json
try:
  data=json.load(sys.stdin)
  for d in data:
    did=d.get('id','')
    if 'blackroad' not in did.lower(): continue
    print(f'  DATASET: {did}')
except: pass
" 2>/dev/null)

    # Search spaces
    local spaces
    spaces=$(curl -s "https://huggingface.co/api/spaces?search=$term&limit=10" 2>/dev/null | \
      python3 -c "
import sys,json
try:
  data=json.load(sys.stdin)
  for s in data:
    sid=s.get('id','')
    if 'blackroad' not in sid.lower(): continue
    print(f'  SPACE: {sid}')
except: pass
" 2>/dev/null)

    if [ -n "$models" ]; then echo -e "    ${RED}⚠ MODELS FOUND:${NC}"; echo "$models"; fi
    if [ -n "$datasets" ]; then echo -e "    ${RED}⚠ DATASETS FOUND:${NC}"; echo "$datasets"; fi
    if [ -n "$spaces" ]; then echo -e "    ${RED}⚠ SPACES FOUND:${NC}"; echo "$spaces"; fi

    if [ -z "$models" ] && [ -z "$datasets" ] && [ -z "$spaces" ]; then
      echo -e "    ${GREEN}✓ Clean${NC}"
    fi
  done

  echo ""
}

# ═══════════════════════════════════════════════════
# GITHUB CODE SEARCH — Find BlackRoad code outside our orgs
# ═══════════════════════════════════════════════════
cmd_scan_github() {
  echo -e "\n${PINK}${BOLD}  GITHUB CODE SEARCH — EXTERNAL REPOS${NC}"
  echo -e "  ${GRAY}Finding BlackRoad code outside our 17 orgs${NC}\n"

  local OUR_ORGS="BlackRoad-OS-Inc BlackRoad-OS blackboxprogramming BlackRoad-AI BlackRoad-Cloud BlackRoad-Security BlackRoad-Foundation BlackRoad-Media BlackRoad-Hardware BlackRoad-Education BlackRoad-Gov BlackRoad-Labs BlackRoad-Studio BlackRoad-Ventures BlackRoad-Interactive BlackRoad-Archive Blackbox-Enterprises"

  local search_terms=(
    "PS-SHA-infinity"
    "BlackRoad OS Inc"
    "blackroad-os"
    "Tokenless Gateway"
    "Amundson Equations"
    "lucidia.earth"
    "blackroad.io"
    "CECE Conscious Emergent"
    "intelligence routing blackroad"
    "directory waterfall blackroad"
  )

  for term in "${search_terms[@]}"; do
    echo -e "  ${CYAN}Searching:${NC} \"$term\""

    local encoded_term
    encoded_term=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$term'))" 2>/dev/null)

    local results
    results=$(gh api "search/code?q=$encoded_term&per_page=10" --jq '.items[] | "\(.repository.full_name) — \(.path)"' 2>/dev/null)

    if [ -n "$results" ]; then
      local external_count=0
      while IFS= read -r line; do
        local is_ours=0
        for our_org in $OUR_ORGS; do
          if echo "$line" | grep -qi "^$our_org/" 2>/dev/null; then
            is_ours=1
            break
          fi
        done

        if [ "$is_ours" -eq 0 ]; then
          echo -e "    ${RED}⚠ EXTERNAL:${NC} $line"
          external_count=$((external_count + 1))

          sqlite3 "$DB_FILE" "INSERT INTO violations (platform, violation_type, description, severity)
            VALUES ('github', 'code_copy', '$(echo "$line" | sed "s/'/''/g")', 'high');"
        fi
      done <<< "$results"

      if [ "$external_count" -eq 0 ]; then
        echo -e "    ${GREEN}✓ Only found in our orgs${NC}"
      fi
    else
      echo -e "    ${GREEN}✓ No results${NC}"
    fi
  done

  echo ""
}

# ═══════════════════════════════════════════════════
# DOMAIN SQUATTER SCAN — Check for domain impersonation
# ═══════════════════════════════════════════════════
cmd_scan_domains() {
  echo -e "\n${PINK}${BOLD}  DOMAIN SQUATTER SCANNER${NC}\n"

  local variations=(
    "blackroad.com"
    "black-road.io"
    "black-road.ai"
    "blackroadai.com"
    "blackroados.com"
    "blackroados.io"
    "theblackroad.io"
    "blackroad.dev"
    "blackroad.app"
    "blackroad.tech"
    "blackroad.org"
    "blackroad.co"
    "lucidia.io"
    "lucidia.ai"
    "lucidia.com"
  )

  for domain in "${variations[@]}"; do
    local ip
    ip=$(dig +short "$domain" A 2>/dev/null | head -1)

    if [ -n "$ip" ]; then
      echo -e "  ${RED}⚠ ACTIVE:${NC} $domain → $ip"
      sqlite3 "$DB_FILE" "INSERT INTO scans (scan_type, target, result, match_found)
        VALUES ('domain_squat', '$domain', '$ip', 1);"
    else
      echo -e "  ${GREEN}✓${NC} $domain — not registered"
    fi
  done

  echo ""
}

# ═══════════════════════════════════════════════════
# NPM / PyPI SCAN — Check package registries
# ═══════════════════════════════════════════════════
cmd_scan_packages() {
  echo -e "\n${PINK}${BOLD}  PACKAGE REGISTRY SCANNER${NC}\n"

  local npm_terms=("blackroad" "blackroad-os" "lucidia" "blackroad-sdk" "blackroad-cli" "cece-ai")
  local pypi_terms=("blackroad" "blackroad-os" "lucidia" "blackroad-sdk" "cece")

  echo -e "  ${CYAN}NPM Registry:${NC}"
  for term in "${npm_terms[@]}"; do
    local result
    result=$(curl -s "https://registry.npmjs.org/$term" 2>/dev/null | python3 -c "
import sys,json
try:
  d=json.load(sys.stdin)
  if 'error' not in d:
    print(f'{d.get(\"name\",\"?\")} — {d.get(\"description\",\"no desc\")[:60]}')
except: pass
" 2>/dev/null)

    if [ -n "$result" ]; then
      echo -e "    ${YELLOW}⚠ FOUND:${NC} $result"
    else
      echo -e "    ${GREEN}✓${NC} $term — not registered"
    fi
  done

  echo -e "\n  ${CYAN}PyPI Registry:${NC}"
  for term in "${pypi_terms[@]}"; do
    local status
    status=$(curl -s -o /dev/null -w "%{http_code}" "https://pypi.org/pypi/$term/json" 2>/dev/null)

    if [ "$status" = "200" ]; then
      local desc
      desc=$(curl -s "https://pypi.org/pypi/$term/json" 2>/dev/null | python3 -c "
import sys,json
try:
  d=json.load(sys.stdin)
  print(d.get('info',{}).get('summary','')[:60])
except: pass
" 2>/dev/null)
      echo -e "    ${YELLOW}⚠ FOUND:${NC} $term — $desc"
    else
      echo -e "    ${GREEN}✓${NC} $term — not registered"
    fi
  done

  echo ""
}

# ═══════════════════════════════════════════════════
# FULL AUDIT — Run everything
# ═══════════════════════════════════════════════════
cmd_full() {
  echo -e "\n${PINK}╔══════════════════════════════════════════════════════╗${NC}"
  echo -e "${PINK}║  BLACKROAD IP AUDIT — FULL SWEEP                     ║${NC}"
  echo -e "${PINK}║  BlackRoad OS, Inc. © 2026                            ║${NC}"
  echo -e "${PINK}╚══════════════════════════════════════════════════════╝${NC}\n"

  cmd_sniff
  cmd_scan_hf
  cmd_scan_github
  cmd_scan_domains
  cmd_scan_packages
  cmd_report
}

# ═══════════════════════════════════════════════════
# REPORT — Generate violation report
# ═══════════════════════════════════════════════════
cmd_report() {
  echo -e "\n${PINK}${BOLD}  IP AUDIT REPORT${NC}\n"

  local total_scans
  total_scans=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM scans;")
  local total_matches
  total_matches=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM scans WHERE match_found = 1;")
  local total_violations
  total_violations=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM violations WHERE status = 'open';")
  local total_canaries
  total_canaries=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM canaries;")
  local triggered_canaries
  triggered_canaries=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM canaries WHERE triggered = 1;")

  echo -e "  ${BOLD}Total Scans:${NC}         $total_scans"
  echo -e "  ${BOLD}Fingerprint Matches:${NC} ${RED}$total_matches${NC}"
  echo -e "  ${BOLD}Open Violations:${NC}     ${RED}$total_violations${NC}"
  echo -e "  ${BOLD}Canary Tokens:${NC}       $total_canaries"
  echo -e "  ${BOLD}Triggered Canaries:${NC}  ${RED}$triggered_canaries${NC}"

  echo -e "\n  ${CYAN}Recent Violations:${NC}"
  sqlite3 -header -column "$DB_FILE" "SELECT platform, violation_type, severity, substr(description,1,50) as desc, detected_at FROM violations WHERE status='open' ORDER BY detected_at DESC LIMIT 10;" 2>/dev/null

  echo -e "\n  ${CYAN}Recent Matches:${NC}"
  sqlite3 -header -column "$DB_FILE" "SELECT target, scan_type, confidence, substr(query,1,40) as query, scanned_at FROM scans WHERE match_found=1 ORDER BY scanned_at DESC LIMIT 10;" 2>/dev/null

  echo ""
}

# ═══════════════════════════════════════════════════
# DMCA GENERATOR — Auto-generate takedown notices
# ═══════════════════════════════════════════════════
cmd_dmca() {
  local violation_id="$1"

  if [ -z "$violation_id" ]; then
    echo -e "\n${RED}Usage: br ip-audit dmca <violation-id>${NC}\n"
    return 1
  fi

  local violation
  violation=$(sqlite3 "$DB_FILE" "SELECT platform, violation_type, description FROM violations WHERE id=$violation_id;")

  if [ -z "$violation" ]; then
    echo -e "\n${RED}Violation not found${NC}\n"
    return 1
  fi

  local platform=$(echo "$violation" | cut -d'|' -f1)
  local desc=$(echo "$violation" | cut -d'|' -f3)
  local dmca_file="$EVIDENCE_DIR/dmca-notice-$violation_id-$(date +%Y%m%d).txt"

  cat > "$dmca_file" << DMCAEOF
DMCA TAKEDOWN NOTICE
====================

Date: $(date -u '+%Y-%m-%d')

To: $platform Legal / DMCA Agent

From:
  BlackRoad OS, Inc.
  Attn: Alexa Louise Amundson, CEO
  Email: alexa@blackroad.io

I, Alexa Louise Amundson, am the sole owner of BlackRoad OS, Inc.,
a Delaware C-Corporation. I am the copyright owner of the works
described below.

COPYRIGHTED WORK:
The source code, documentation, and intellectual property of
BlackRoad OS, Inc., encompassing 1,825+ repositories across 17
GitHub organizations.

INFRINGING MATERIAL:
$desc

LOCATION OF INFRINGING MATERIAL:
Platform: $platform
Details: $desc

GOOD FAITH STATEMENT:
I have a good faith belief that the use of the copyrighted material
described above is not authorized by the copyright owner (BlackRoad
OS, Inc.), its agent, or the law.

ACCURACY STATEMENT:
The information in this notification is accurate, and under penalty
of perjury, I am authorized to act on behalf of the owner of an
exclusive right that is allegedly infringed.

SIGNATURE:
/s/ Alexa Louise Amundson
Founder, CEO & Sole Stockholder
BlackRoad OS, Inc.
alexa@blackroad.io
DMCAEOF

  echo -e "\n${GREEN}DMCA notice generated:${NC} $dmca_file"
  sqlite3 "$DB_FILE" "UPDATE violations SET dmca_filed=1 WHERE id=$violation_id;"
  echo ""
}

# ═══════════════════════════════════════════════════
# HELP
# ═══════════════════════════════════════════════════
show_help() {
  echo -e "\n${PINK}${BOLD}  BR IP-AUDIT${NC} — BlackRoad IP Monitoring System\n"
  echo -e "  ${BOLD}USAGE:${NC} br ip-audit <command>\n"
  echo -e "  ${CYAN}Scanning:${NC}"
  echo -e "    sniff              Query AI APIs for BlackRoad fingerprints"
  echo -e "    scan-hf            Scan Hugging Face for BlackRoad content"
  echo -e "    scan-github        Search GitHub for code outside our orgs"
  echo -e "    scan-domains       Check for domain squatters"
  echo -e "    scan-packages      Check NPM/PyPI for name squatting"
  echo -e "    full               Run ALL scans"
  echo -e ""
  echo -e "  ${CYAN}Canary Tokens:${NC}"
  echo -e "    canary-gen [N]     Generate N canary tokens (default 20)"
  echo -e "    canary-embed       Create canary files for deployment"
  echo -e ""
  echo -e "  ${CYAN}Reports & Actions:${NC}"
  echo -e "    report             Show audit dashboard"
  echo -e "    dmca <id>          Generate DMCA takedown notice"
  echo -e ""
  echo -e "  ${GRAY}© 2026 BlackRoad OS, Inc. All rights reserved.${NC}\n"
}

# ═══════════════════════════════════════════════════
# ROUTER
# ═══════════════════════════════════════════════════
init_db

case "${1:-help}" in
  sniff)          cmd_sniff ;;
  scan-hf)        cmd_scan_hf ;;
  scan-github)    cmd_scan_github ;;
  scan-domains)   cmd_scan_domains ;;
  scan-packages)  cmd_scan_packages ;;
  full)           cmd_full ;;
  canary-gen)     cmd_canary_generate "${2:-20}" ;;
  canary-embed)   cmd_canary_embed ;;
  report)         cmd_report ;;
  dmca)           cmd_dmca "$2" ;;
  *)              show_help ;;
esac
