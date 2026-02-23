#!/bin/zsh
# BR AUTH — BlackRoad Auth Token (BRAT) CLI
# Protocol: BRAT v1 — HMAC-SHA256, role-scoped, chain-anchored
#
# Commands:
#   br auth init                   Generate master key + identity
#   br auth token [role] [ttl]     Mint a BRAT token
#   br auth verify <token>         Verify + decode a token
#   br auth whoami                 Show current identity + active session
#   br auth rotate                 Rotate master key (revokes all tokens)
#   br auth challenge <token>      Challenge-response verify
#   br auth sessions               List active sessions (SQLite)
#   br auth revoke <jti>           Revoke a token by JTI
#   br auth status                 Auth system health

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

AUTH_DIR="$HOME/.blackroad/auth"
KEY_FILE="$AUTH_DIR/master.key"
ID_FILE="$AUTH_DIR/identity"
DB_FILE="$AUTH_DIR/sessions.db"
INSTANCE_ID="${INSTANCE_ID:-copilot-cli}"

# ─── Init ─────────────────────────────────────────────────────────────────────
init_db() {
  mkdir -p "$AUTH_DIR" && chmod 700 "$AUTH_DIR"
  sqlite3 "$DB_FILE" <<'SQL'
CREATE TABLE IF NOT EXISTS sessions (
  jti       TEXT PRIMARY KEY,
  sub       TEXT NOT NULL,
  iss       TEXT NOT NULL,
  role      TEXT NOT NULL,
  scope     TEXT NOT NULL,
  iat       INTEGER NOT NULL,
  exp       INTEGER NOT NULL,
  revoked   INTEGER DEFAULT 0,
  token     TEXT NOT NULL,
  created   TEXT DEFAULT (datetime('now'))
);
CREATE TABLE IF NOT EXISTS revocations (
  jti       TEXT PRIMARY KEY,
  reason    TEXT,
  revoked_at TEXT DEFAULT (datetime('now'))
);
SQL
}

# ─── Python helper for BRAT operations ────────────────────────────────────────
brat_python() {
  python3 - "$@" <<'PYEOF'
import sys, json, hmac as hmaclib, hashlib, base64, secrets, os, time

HEADER = "BRAT_v1"

def b64enc(data):
    if isinstance(data, str): data = data.encode()
    return base64.urlsafe_b64encode(data).rstrip(b'=').decode()

def b64dec(s):
    pad = (4 - len(s) % 4) % 4
    return base64.urlsafe_b64decode(s + '=' * pad)

def sign(key_hex, msg):
    key = bytes.fromhex(key_hex)
    return hmaclib.new(key, msg.encode(), hashlib.sha256).digest()

def mint(key_hex, sub, iss, role, ttl, scope, chain=None):
    IMPLICIT = {
        "owner":       ["*"],
        "coordinator": ["mesh:*","agents:read","workers:read","api:read"],
        "agent":       ["mesh:read","agents:read"],
        "guest":       ["api:read"],
    }
    TTL_DEFAULT = {"owner":86400,"coordinator":14400,"agent":3600,"guest":900}
    now = int(time.time())
    payload = {
        "v": 1,
        "iss": iss,
        "sub": sub,
        "iat": now,
        "exp": now + (int(ttl) if ttl else TTL_DEFAULT.get(role, 3600)),
        "jti": secrets.token_hex(8),
        "role": role,
        "scope": scope.split(",") if scope else IMPLICIT.get(role, ["api:read"]),
    }
    if chain: payload["chain"] = chain
    p_b64 = b64enc(json.dumps(payload, separators=(',',':')))
    msg = f"{HEADER}.{p_b64}"
    sig = b64enc(sign(key_hex, msg))
    return f"{msg}.{sig}", payload

def verify(key_hex, token):
    parts = token.split('.')
    if len(parts) != 3:
        return None, "malformed: expected 3 parts"
    header, p_b64, sig_b64 = parts
    if header != HEADER:
        return None, f"invalid header: {header}"
    msg = f"{header}.{p_b64}"
    expected = b64enc(sign(key_hex, msg))
    if expected != sig_b64:
        return None, "invalid signature"
    try:
        payload = json.loads(b64dec(p_b64))
    except Exception as e:
        return None, f"payload decode error: {e}"
    now = int(time.time())
    if payload.get("exp", 0) < now:
        remaining = now - payload.get("exp", 0)
        return None, f"expired {remaining}s ago"
    return payload, None

def decode(token):
    parts = token.split('.')
    if len(parts) != 3: return None
    try: return json.loads(b64dec(parts[1]))
    except: return None

cmd = sys.argv[1] if len(sys.argv) > 1 else ""

if cmd == "mint":
    key_hex = sys.argv[2]
    sub     = sys.argv[3]
    iss     = sys.argv[4]
    role    = sys.argv[5] if len(sys.argv) > 5 else "agent"
    ttl     = sys.argv[6] if len(sys.argv) > 6 else ""
    scope   = sys.argv[7] if len(sys.argv) > 7 else ""
    chain   = sys.argv[8] if len(sys.argv) > 8 else None
    token, payload = mint(key_hex, sub, iss, role, ttl, scope, chain)
    print(json.dumps({"token": token, "payload": payload}))

elif cmd == "verify":
    key_hex = sys.argv[2]
    token   = sys.argv[3]
    payload, err = verify(key_hex, token)
    if err:
        print(json.dumps({"ok": False, "error": err}))
    else:
        print(json.dumps({"ok": True, "payload": payload}))

elif cmd == "decode":
    token = sys.argv[2]
    p = decode(token)
    print(json.dumps(p) if p else "{}")

elif cmd == "genkey":
    print(secrets.token_hex(32))

PYEOF
}

# ─── Load key ─────────────────────────────────────────────────────────────────
load_key() {
  if [[ ! -f "$KEY_FILE" ]]; then
    echo -e "${RED}✗ No master key. Run: br auth init${NC}" >&2
    exit 1
  fi
  cat "$KEY_FILE"
}

load_identity() {
  if [[ ! -f "$ID_FILE" ]]; then
    echo "${USER:-unknown}@${INSTANCE_ID}"
  else
    cat "$ID_FILE"
  fi
}

# ─── Journal chain anchor ─────────────────────────────────────────────────────
get_chain_head() {
  local journal="$HOME/.blackroad/memory/journals/master-journal.jsonl"
  if [[ -f "$journal" ]]; then
    tail -1 "$journal" 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('sha256','')[:16])" 2>/dev/null
  fi
}

# ─── Commands ─────────────────────────────────────────────────────────────────

cmd_init() {
  echo -e "${CYAN}${BOLD}◆ BR AUTH — Initialize${NC}"
  echo -e "${CYAN}────────────────────────────────${NC}"

  mkdir -p "$AUTH_DIR" && chmod 700 "$AUTH_DIR"
  init_db

  # Generate master key
  if [[ -f "$KEY_FILE" ]] && [[ "${1:-}" != "--force" ]]; then
    echo -e "${YELLOW}⚠ Master key already exists (use --force to regenerate)${NC}"
  else
    local key
    key=$(brat_python genkey)
    echo "$key" > "$KEY_FILE"
    chmod 400 "$KEY_FILE"
    echo -e "${GREEN}✓ Master key generated${NC} → $KEY_FILE"
  fi

  # Identity
  local identity="${USER:-alexa}@${INSTANCE_ID}"
  echo "$identity" > "$ID_FILE"
  echo -e "${GREEN}✓ Identity set${NC} → $identity"

  # Log to journal
  local journal_entry="{\"timestamp\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"action\":\"auth-init\",\"entity\":\"$identity\",\"details\":\"BRAT auth initialized\"}"
  mkdir -p "$HOME/.blackroad/memory/journals"
  echo "$journal_entry" >> "$HOME/.blackroad/memory/journals/master-journal.jsonl"

  echo ""
  echo -e "${GREEN}✅ BRAT auth ready.${NC}"
  echo -e "   Mint tokens:   ${CYAN}br auth token owner${NC}"
  echo -e "   Verify tokens: ${CYAN}br auth verify <token>${NC}"
}

cmd_token() {
  local role="${1:-owner}"
  local ttl="${2:-}"
  local scope="${3:-}"

  init_db
  local key identity chain result token payload jti exp

  key=$(load_key)
  identity=$(load_identity)
  chain=$(get_chain_head)

  result=$(brat_python mint "$key" "$identity" "$INSTANCE_ID" "$role" "$ttl" "$scope" "$chain")
  token=$(echo "$result" | python3 -c "import sys,json; print(json.load(sys.stdin)['token'])")
  payload=$(echo "$result" | python3 -c "import sys,json; print(json.dumps(json.load(sys.stdin)['payload'], indent=2))")

  jti=$(echo "$payload" | python3 -c "import sys,json; print(json.load(sys.stdin)['jti'])")
  exp=$(echo "$payload" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['exp'])")
  local scope_val
  scope_val=$(echo "$payload" | python3 -c "import sys,json; print(','.join(json.load(sys.stdin)['scope']))")

  # Store in sessions DB
  sqlite3 "$DB_FILE" "INSERT OR REPLACE INTO sessions (jti,sub,iss,role,scope,iat,exp,token) VALUES ('$jti','$identity','$INSTANCE_ID','$role','$scope_val',$(date +%s),$exp,'$token');"

  echo -e "${PURPLE}${BOLD}◆ BRAT Token Minted${NC}"
  echo -e "${CYAN}────────────────────────────────────────${NC}"
  echo -e "  ${BOLD}Role:${NC}     $role"
  echo -e "  ${BOLD}Subject:${NC}  $identity"
  echo -e "  ${BOLD}Issuer:${NC}   $INSTANCE_ID"
  echo -e "  ${BOLD}JTI:${NC}      $jti"
  echo -e "  ${BOLD}Expires:${NC}  $(python3 -c "import datetime; print(datetime.datetime.fromtimestamp($exp).strftime('%Y-%m-%d %H:%M:%S'))")"
  echo -e "  ${BOLD}Scope:${NC}    $scope_val"
  [[ -n "$chain" ]] && echo -e "  ${BOLD}Chain:${NC}    $chain"
  echo ""
  echo -e "${GREEN}${BOLD}TOKEN:${NC}"
  echo "$token"
}

cmd_verify() {
  local token="${1:-}"
  if [[ -z "$token" ]]; then
    echo -e "${RED}✗ Usage: br auth verify <token>${NC}"
    exit 1
  fi

  local key result
  key=$(load_key)
  result=$(brat_python verify "$key" "$token")

  local ok
  ok=$(echo "$result" | python3 -c "import sys,json; print(json.load(sys.stdin).get('ok', False))")

  if [[ "$ok" == "True" ]]; then
    local payload
    payload=$(echo "$result" | python3 -c "import sys,json; print(json.dumps(json.load(sys.stdin)['payload'], indent=2))")
    local sub role exp scope jti
    sub=$(echo "$payload"   | python3 -c "import sys,json; print(json.load(sys.stdin)['sub'])")
    role=$(echo "$payload"  | python3 -c "import sys,json; print(json.load(sys.stdin)['role'])")
    exp=$(echo "$payload"   | python3 -c "import sys,json; print(json.load(sys.stdin)['exp'])")
    scope=$(echo "$payload" | python3 -c "import sys,json; print(','.join(json.load(sys.stdin)['scope']))")
    jti=$(echo "$payload"   | python3 -c "import sys,json; print(json.load(sys.stdin)['jti'])")

    # Check revocation
    local revoked
    revoked=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM revocations WHERE jti='$jti';" 2>/dev/null || echo "0")

    echo -e "${GREEN}${BOLD}✓ VALID BRAT TOKEN${NC}"
    echo -e "${CYAN}────────────────────────────────${NC}"
    echo -e "  ${BOLD}Subject:${NC}  $sub"
    echo -e "  ${BOLD}Role:${NC}     $role"
    echo -e "  ${BOLD}Scope:${NC}    $scope"
    echo -e "  ${BOLD}JTI:${NC}      $jti"
    echo -e "  ${BOLD}Expires:${NC}  $(python3 -c "import datetime; print(datetime.datetime.fromtimestamp($exp).strftime('%Y-%m-%d %H:%M:%S'))")"

    if [[ "$revoked" -gt 0 ]]; then
      echo -e "  ${RED}${BOLD}⚠ REVOKED${NC}"
    else
      echo -e "  ${GREEN}Status:   active${NC}"
    fi
  else
    local err
    err=$(echo "$result" | python3 -c "import sys,json; print(json.load(sys.stdin).get('error','unknown'))")
    echo -e "${RED}${BOLD}✗ INVALID TOKEN${NC}"
    echo -e "  Error: $err"
    exit 1
  fi
}

cmd_whoami() {
  local identity key
  identity=$(load_identity)
  key=$(load_key 2>/dev/null || echo "")

  echo -e "${CYAN}${BOLD}◆ BRAT Identity${NC}"
  echo -e "${CYAN}────────────────────────────────${NC}"
  echo -e "  ${BOLD}Identity:${NC}  $identity"
  echo -e "  ${BOLD}Instance:${NC}  $INSTANCE_ID"
  echo -e "  ${BOLD}Key file:${NC}  $KEY_FILE"
  echo -e "  ${BOLD}Key set:${NC}   $( [[ -n "$key" ]] && echo "${GREEN}yes${NC}" || echo "${RED}no${NC}")"

  # Active sessions
  local active
  active=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM sessions WHERE exp > $(date +%s) AND revoked=0;" 2>/dev/null || echo "0")
  echo -e "  ${BOLD}Active tokens:${NC} $active"

  local chain
  chain=$(get_chain_head)
  [[ -n "$chain" ]] && echo -e "  ${BOLD}Chain head:${NC}  $chain"
}

cmd_sessions() {
  echo -e "${CYAN}${BOLD}◆ Active Sessions${NC}"
  echo -e "${CYAN}────────────────────────────────────────────────────${NC}"
  printf "  %-18s %-12s %-30s %s\n" "JTI" "ROLE" "SCOPE" "EXPIRES"
  echo -e "  ──────────────────────────────────────────────────────────"
  sqlite3 "$DB_FILE" \
    "SELECT jti, role, scope, datetime(exp,'unixepoch') FROM sessions WHERE exp > $(date +%s) AND revoked=0 ORDER BY exp DESC;" \
    2>/dev/null | while IFS='|' read -r jti role scope expires; do
    printf "  %-18s %-12s %-30s %s\n" "${jti:0:16}" "$role" "${scope:0:28}" "$expires"
  done
}

cmd_revoke() {
  local jti="${1:-}"
  if [[ -z "$jti" ]]; then
    echo -e "${RED}✗ Usage: br auth revoke <jti>${NC}"
    exit 1
  fi
  sqlite3 "$DB_FILE" "INSERT OR REPLACE INTO revocations (jti, reason) VALUES ('$jti', 'manual revocation');"
  sqlite3 "$DB_FILE" "UPDATE sessions SET revoked=1 WHERE jti='$jti';"
  echo -e "${GREEN}✓ Token $jti revoked${NC}"
}

cmd_rotate() {
  echo -e "${YELLOW}⚠ Rotating master key — all existing tokens will be invalid${NC}"
  echo -n "  Confirm? [y/N] "
  read -r confirm
  [[ "$confirm" != "y" && "$confirm" != "Y" ]] && echo "Cancelled." && return

  local new_key
  new_key=$(brat_python genkey)
  echo "$new_key" > "$KEY_FILE"
  chmod 400 "$KEY_FILE"

  # Invalidate all sessions
  sqlite3 "$DB_FILE" "UPDATE sessions SET revoked=1;"
  echo -e "${GREEN}✓ Master key rotated. All previous tokens invalidated.${NC}"
}

cmd_challenge() {
  # Generate a nonce, sign it, output for verification by remote
  local nonce
  nonce=$(python3 -c "import secrets; print(secrets.token_hex(16))")
  local key identity result token
  key=$(load_key)
  identity=$(load_identity)
  result=$(brat_python mint "$key" "$identity" "$INSTANCE_ID" "owner" "60" "challenge:respond" "")
  token=$(echo "$result" | python3 -c "import sys,json; print(json.load(sys.stdin)['token'])")

  echo -e "${CYAN}${BOLD}◆ Challenge Token${NC} (valid 60s)"
  echo -e "${CYAN}────────────────────────────────${NC}"
  echo -e "  Nonce:   $nonce"
  echo -e "  Token:   $token"
  echo ""
  echo -e "  Remote verifies with: ${CYAN}br auth verify <token>${NC}"
}

cmd_status() {
  echo -e "${CYAN}${BOLD}◆ BR AUTH Status${NC}"
  echo -e "${CYAN}────────────────────────────────${NC}"
  echo -e "  Protocol:    BRAT v1 (BlackRoad Auth Token)"
  echo -e "  Signing:     HMAC-SHA256"
  echo -e "  Key:         $( [[ -f "$KEY_FILE" ]] && echo "${GREEN}present${NC} ($(stat -f%z "$KEY_FILE" 2>/dev/null || stat -c%s "$KEY_FILE") bytes)" || echo "${RED}missing${NC}" )"
  echo -e "  Identity:    $(load_identity 2>/dev/null || echo 'none')"
  local total active revoked
  total=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM sessions;" 2>/dev/null || echo "0")
  active=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM sessions WHERE exp > $(date +%s) AND revoked=0;" 2>/dev/null || echo "0")
  revoked=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM revocations;" 2>/dev/null || echo "0")
  echo -e "  Sessions:    $total total / ${GREEN}$active active${NC} / ${RED}$revoked revoked${NC}"
  echo -e "  DB:          $DB_FILE"
}

show_help() {
  echo -e "${CYAN}${BOLD}◆ BR AUTH — BlackRoad Auth Token (BRAT v1)${NC}"
  echo -e "${CYAN}────────────────────────────────────────────────────${NC}"
  echo -e "  Protocol: HMAC-SHA256 signed tokens with role-based scopes"
  echo -e "  Format:   BRAT_v1.<payload_b64url>.<hmac_sig_b64url>"
  echo ""
  echo -e "  ${BOLD}COMMANDS${NC}"
  echo -e "    init [--force]          Generate master key + identity"
  echo -e "    token [role] [ttl]      Mint a token  (owner|coordinator|agent|guest)"
  echo -e "    verify <token>          Verify + decode a token"
  echo -e "    whoami                  Show current identity"
  echo -e "    sessions                List active sessions"
  echo -e "    revoke <jti>            Revoke token by JTI"
  echo -e "    rotate                  Rotate master key"
  echo -e "    challenge               Generate 60s challenge token"
  echo -e "    status                  Auth system status"
  echo ""
  echo -e "  ${BOLD}ROLES & IMPLICIT SCOPES${NC}"
  echo -e "    owner        →  [*]  (all access)"
  echo -e "    coordinator  →  [mesh:*, agents:read, workers:read, api:read]"
  echo -e "    agent        →  [mesh:read, agents:read]"
  echo -e "    guest        →  [api:read]"
  echo ""
  echo -e "  ${BOLD}EXAMPLES${NC}"
  echo -e "    br auth init"
  echo -e "    br auth token owner"
  echo -e "    br auth token coordinator 14400"
  echo -e "    br auth verify BRAT_v1.eyJ..."
  echo -e "    br auth sessions"
}

# ─── Dispatch ─────────────────────────────────────────────────────────────────
case "${1:-help}" in
  init)      shift; cmd_init "$@" ;;
  token)     shift; cmd_token "$@" ;;
  verify)    shift; cmd_verify "$@" ;;
  whoami)    cmd_whoami ;;
  sessions)  cmd_sessions ;;
  revoke)    shift; cmd_revoke "$@" ;;
  rotate)    cmd_rotate ;;
  challenge) cmd_challenge ;;
  status)    cmd_status ;;
  help|-h|--help) show_help ;;
  *) echo -e "${RED}✗ Unknown: $1${NC}"; show_help; exit 1 ;;
esac
