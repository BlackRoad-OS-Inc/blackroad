#!/usr/bin/env zsh
# BR Signal — inter-process event bus for br instances

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; BLUE='\033[0;34m'; NC='\033[0m'
BOLD='\033[1m'
DB="$HOME/.blackroad/signal.db"
SIGNAL_DIR="$HOME/.blackroad/signals"

init_db() {
  mkdir -p "$(dirname "$DB")" "$SIGNAL_DIR"
  sqlite3 "$DB" <<'SQL'
CREATE TABLE IF NOT EXISTS events (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  channel TEXT NOT NULL DEFAULT 'default',
  event TEXT NOT NULL,
  payload TEXT DEFAULT '{}',
  source TEXT DEFAULT '',
  consumed INTEGER DEFAULT 0,
  ts TEXT DEFAULT (datetime('now'))
);
CREATE TABLE IF NOT EXISTS subscriptions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  channel TEXT NOT NULL,
  subscriber TEXT NOT NULL,
  handler TEXT DEFAULT '',
  filter TEXT DEFAULT '',
  created_at TEXT DEFAULT (datetime('now')),
  UNIQUE(channel, subscriber)
);
CREATE TABLE IF NOT EXISTS webhooks (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  channel TEXT NOT NULL,
  event TEXT NOT NULL DEFAULT '*',
  url TEXT NOT NULL,
  method TEXT DEFAULT 'POST',
  secret TEXT DEFAULT '',
  enabled INTEGER DEFAULT 1,
  fires INTEGER DEFAULT 0,
  created_at TEXT DEFAULT (datetime('now'))
);
INSERT OR IGNORE INTO subscriptions (channel, subscriber, handler) VALUES
  ('deploy',   'br-audit',   'br audit record deploy'),
  ('git-push', 'br-notify',  'br notify send'),
  ('error',    'br-audit',   'br audit record error'),
  ('health',   'br-health',  'br health check');
SQL
}

cmd_emit() {
  local channel="${2:-default}" event="$1" payload="${3:-{}}" source="${4:-$(whoami)}"
  [[ -z "$event" ]] && { echo "Usage: br signal emit <event> [channel] [payload_json] [source]"; exit 1; }
  local id
  id=$(sqlite3 "$DB" "INSERT INTO events (channel, event, payload, source) VALUES ('$channel', '$event', '$payload', '$source'); SELECT last_insert_rowid();")
  # Write to signal dir for watchers
  echo "{\"id\":$id,\"channel\":\"$channel\",\"event\":\"$event\",\"payload\":$payload,\"source\":\"$source\",\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" \
    > "$SIGNAL_DIR/sig-${id}-${event//[^a-z0-9]/-}.json"
  echo -e "${GREEN}✓ Signal emitted: ${BOLD}$event${NC}${GREEN} on '$channel' (id=$id)${NC}"
  # Fire webhooks
  local wh_count
  wh_count=$(sqlite3 "$DB" "SELECT COUNT(*) FROM webhooks WHERE enabled=1 AND channel='$channel' AND (event='*' OR event='$event');")
  if [[ "$wh_count" -gt 0 ]]; then
    sqlite3 -separator "|" "$DB" "SELECT url, method, secret FROM webhooks WHERE enabled=1 AND channel='$channel' AND (event='*' OR event='$event');" | while IFS="|" read -r url method secret; do
      curl -s -X "$method" "$url" \
        -H "Content-Type: application/json" \
        -H "X-Signal-Event: $event" \
        -H "X-Signal-Channel: $channel" \
        -d "{\"event\":\"$event\",\"channel\":\"$channel\",\"payload\":$payload}" \
        &>/dev/null &
      sqlite3 "$DB" "UPDATE webhooks SET fires=fires+1 WHERE url='$url' AND channel='$channel';"
      echo -e "  ${CYAN}⚡ webhook fired → $url${NC}"
    done
  fi
  # Handle subscriptions
  sqlite3 -separator "|" "$DB" "SELECT subscriber, handler FROM subscriptions WHERE channel='$channel';" | while IFS="|" read -r sub handler; do
    [[ -n "$handler" ]] && eval "$handler" &>/dev/null &
  done
}

cmd_listen() {
  local channel="${1:-default}" filter="${2:-}"
  echo -e "${CYAN}📡 Listening on channel '${channel}'${filter:+ — filter: $filter} — Ctrl-C to stop${NC}"
  echo ""
  local last_id
  last_id=$(sqlite3 "$DB" "SELECT COALESCE(MAX(id),0) FROM events WHERE channel='$channel';")
  while true; do
    local new_events
    new_events=$(sqlite3 -separator "|" "$DB" "SELECT id, event, payload, source, ts FROM events WHERE channel='$channel' AND id > $last_id${filter:+ AND event LIKE '%$filter%'} ORDER BY id;")
    if [[ -n "$new_events" ]]; then
      echo "$new_events" | while IFS="|" read -r eid ev payload src ts; do
        echo -e "  ${GREEN}[${ts:11:8}]${NC}  ${BOLD}$ev${NC}  ${CYAN}from:$src${NC}"
        [[ "$payload" != "{}" ]] && echo "    $payload"
        last_id="$eid"
      done
    fi
    sleep 0.5
  done
}

cmd_log() {
  local channel="${1:-}" n="${2:-30}"
  local where=""; [[ -n "$channel" ]] && where="WHERE channel='$channel'"
  echo ""
  echo -e "${CYAN}📋 Signal Log${NC}"
  echo ""
  sqlite3 -separator "|" "$DB" "SELECT id, channel, event, source, consumed, ts FROM events $where ORDER BY ts DESC LIMIT $n;" | while IFS="|" read -r eid ch ev src consumed ts; do
    local color="$GREEN"; [[ "$consumed" -eq 0 ]] && color="$YELLOW"
    printf "  ${color}%4s${NC}  %-12s  %-20s  %-10s  %s\n" "$eid" "$ch" "$ev" "$src" "${ts:0:16}"
  done
  echo ""
}

cmd_channels() {
  echo ""
  echo -e "${CYAN}📡 Channels${NC}"
  echo ""
  sqlite3 -separator "|" "$DB" "SELECT channel, COUNT(*), MAX(ts) FROM events GROUP BY channel ORDER BY COUNT(*) DESC;" | while IFS="|" read -r ch cnt last; do
    local subs
    subs=$(sqlite3 "$DB" "SELECT COUNT(*) FROM subscriptions WHERE channel='$ch';")
    printf "  ${GREEN}%-15s${NC}  %5s events  %2s subs  last: %s\n" "$ch" "$cnt" "$subs" "${last:0:16}"
  done
  echo ""
}

cmd_sub() {
  local channel="$1" subscriber="$2" handler="${3:-}"
  [[ -z "$channel" || -z "$subscriber" ]] && { echo "Usage: br signal sub <channel> <subscriber> [handler_cmd]"; exit 1; }
  sqlite3 "$DB" "INSERT OR REPLACE INTO subscriptions (channel, subscriber, handler) VALUES ('$channel', '$subscriber', '$handler');"
  echo -e "${GREEN}✓ Subscribed '$subscriber' to '$channel'${NC}"
}

cmd_webhook_add() {
  local channel="$1" event="${2:-*}" url="$3"
  [[ -z "$channel" || -z "$url" ]] && { echo "Usage: br signal webhook <channel> <event|*> <url>"; exit 1; }
  sqlite3 "$DB" "INSERT INTO webhooks (channel, event, url) VALUES ('$channel', '$event', '$url');"
  echo -e "${GREEN}✓ Webhook: $channel/$event → $url${NC}"
}

cmd_consume() {
  local channel="${1:-default}" event="${2:-}"
  local where="channel='$channel' AND consumed=0"
  [[ -n "$event" ]] && where="$where AND event='$event'"
  sqlite3 "$DB" "UPDATE events SET consumed=1 WHERE $where;"
  echo -e "${GREEN}✓ Marked as consumed${NC}"
}

cmd_clear() {
  local days="${1:-7}"
  local n
  n=$(sqlite3 "$DB" "SELECT COUNT(*) FROM events WHERE ts < datetime('now', '-${days} days');")
  sqlite3 "$DB" "DELETE FROM events WHERE ts < datetime('now', '-${days} days');"
  rm -f "$SIGNAL_DIR"/sig-*.json 2>/dev/null
  echo -e "${GREEN}✓ Cleared $n events older than ${days} days${NC}"
}

show_help() {
  echo ""
  echo -e "${CYAN}${BOLD}br signal${NC} — inter-process event bus"
  echo ""
  echo -e "  ${GREEN}br signal emit <event> [channel] [payload]${NC}  Emit an event"
  echo -e "  ${GREEN}br signal listen [channel] [filter]${NC}         Watch channel live"
  echo -e "  ${GREEN}br signal log [channel] [n]${NC}                 Event log"
  echo -e "  ${GREEN}br signal channels${NC}                         List all channels"
  echo -e "  ${GREEN}br signal sub <channel> <name> [cmd]${NC}        Subscribe"
  echo -e "  ${GREEN}br signal webhook <ch> <event> <url>${NC}        Add webhook trigger"
  echo -e "  ${GREEN}br signal consume [channel] [event]${NC}         Mark consumed"
  echo -e "  ${GREEN}br signal clear [days]${NC}                      Prune old events"
  echo ""
  echo -e "  ${YELLOW}Channels:${NC} deploy, git-push, error, health (built-in)"
  echo -e "  ${YELLOW}Example:${NC}  br signal emit deploy.success deploy '{\"sha\":\"abc123\"}'"
  echo ""
}

init_db
case "${1:-channels}" in
  emit|pub|fire)   shift; cmd_emit "$@" ;;
  listen|watch|sub-live) shift; cmd_listen "$@" ;;
  log|ls)          shift; cmd_log "$@" ;;
  channels|list)   cmd_channels ;;
  sub|subscribe)   shift; cmd_sub "$@" ;;
  webhook|wh)      shift; cmd_webhook_add "$@" ;;
  consume)         shift; cmd_consume "$@" ;;
  clear|prune)     shift; cmd_clear "$@" ;;
  help|-h|--help)  show_help ;;
  *)               show_help ;;
esac
