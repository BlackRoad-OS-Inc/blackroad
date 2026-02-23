#!/bin/zsh
# BR Edu — RoadWork AI Homework Helper
GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

GATEWAY_URL="${BLACKROAD_GATEWAY_URL:-http://127.0.0.1:8787}"
DB="$HOME/.blackroad/edu.db"

init_db() {
  mkdir -p "$(dirname $DB)"
  sqlite3 "$DB" "CREATE TABLE IF NOT EXISTS sessions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    ts TEXT DEFAULT (datetime('now')),
    subject TEXT,
    question TEXT,
    answer TEXT,
    rating INTEGER
  );"
}

ask_homework() {
  local subject="$1" question="$2"
  echo "\n${CYAN}🎓 RoadWork — $subject${NC}"
  echo "${YELLOW}Q: $question${NC}\n"

  # Try gateway
  local response=$(curl -s -X POST "$GATEWAY_URL/chat" \
    -H "Content-Type: application/json" \
    -d "{\"agent\":\"CECE\",\"message\":\"Help me understand: $question (subject: $subject). Explain step by step, be concise and encouraging.\"}" \
    --max-time 15 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('response','...'))" 2>/dev/null)

  if [[ -z "$response" ]]; then
    response="Gateway offline. Try: br agent ask CECE \"$question\""
  fi

  echo "${GREEN}A: $response${NC}\n"
  sqlite3 "$DB" "INSERT INTO sessions (subject, question, answer) VALUES ('$subject', '$(echo $question | sed "s/'/''/g")', '$(echo $response | sed "s/'/''/g" | head -c 500)');"
}

case "$1" in
  ask)
    init_db
    subject="${2:-General}"
    shift 2 2>/dev/null
    question="$*"
    if [[ -z "$question" ]]; then
      echo -n "${CYAN}Subject: ${NC}"; read subject
      echo -n "${CYAN}Question: ${NC}"; read question
    fi
    ask_homework "$subject" "$question"
    ;;
  history)
    init_db
    echo "${CYAN}📚 Homework History:${NC}"
    sqlite3 -column -header "$DB" "SELECT ts, subject, substr(question,1,40) as question FROM sessions ORDER BY ts DESC LIMIT 10;"
    ;;
  *)
    echo "${CYAN}BR Edu — RoadWork Homework Helper${NC}"
    echo ""
    echo "  br edu ask [subject] [question]"
    echo "  br edu history"
    echo ""
    echo "  Examples:"
    echo "    br edu ask Math \"What is the quadratic formula?\""
    echo "    br edu ask Physics \"Explain Newton's third law\""
    ;;
esac
