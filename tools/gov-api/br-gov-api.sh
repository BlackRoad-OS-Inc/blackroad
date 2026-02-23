#!/bin/zsh
# BR Gov API — CECE Protocol governance endpoint
GREEN='\033[0;32m'; CYAN='\033[0;36m'; NC='\033[0m'
DB="$HOME/.blackroad/gov.db"

init_db() {
  mkdir -p "$(dirname $DB)"
  sqlite3 "$DB" "
    CREATE TABLE IF NOT EXISTS proposals (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      ts TEXT DEFAULT (datetime('now')),
      title TEXT,
      description TEXT,
      proposer TEXT DEFAULT 'CECE',
      status TEXT DEFAULT 'active',
      votes_yes INTEGER DEFAULT 0,
      votes_no INTEGER DEFAULT 0
    );
    CREATE TABLE IF NOT EXISTS votes (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      proposal_id INTEGER,
      voter TEXT,
      vote TEXT,
      ts TEXT DEFAULT (datetime('now'))
    );
  "
}

case "$1" in
  propose)
    init_db
    sqlite3 "$DB" "INSERT INTO proposals (title, description, proposer) VALUES ('$2', '$3', '${4:-CECE}');"
    echo "${GREEN}✓ Proposal created${NC}"
    ;;
  vote)
    init_db
    PROP_ID="$2" VOTER="${3:-anon}" VOTE="${4:-yes}"
    sqlite3 "$DB" "INSERT INTO votes (proposal_id, voter, vote) VALUES ($PROP_ID, '$VOTER', '$VOTE');"
    sqlite3 "$DB" "UPDATE proposals SET votes_yes = votes_yes + $([[ $VOTE == yes ]] && echo 1 || echo 0), votes_no = votes_no + $([[ $VOTE == no ]] && echo 1 || echo 0) WHERE id=$PROP_ID;"
    echo "${GREEN}✓ Vote recorded${NC}"
    ;;
  list)
    init_db
    echo "${CYAN}📜 Active Proposals:${NC}"
    sqlite3 -column -header "$DB" "SELECT id, title, votes_yes, votes_no, status FROM proposals ORDER BY ts DESC LIMIT 10;"
    ;;
  *)
    echo "Usage: br gov [propose|vote|list]"
    echo "  br gov propose 'title' 'description'"
    echo "  br gov vote <proposal_id> <voter> <yes|no>"
    echo "  br gov list"
    ;;
esac
