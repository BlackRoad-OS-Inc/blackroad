#!/usr/bin/env zsh
# BR Trace HTTP — Full HTTP request inspector with headers/timing/redirects

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; BLUE='\033[0;34m'; PURPLE='\033[0;35m'; NC='\033[0m'
BOLD='\033[1m'
DB="$HOME/.blackroad/trace.db"

init_db() {
  mkdir -p "$(dirname "$DB")"
  sqlite3 "$DB" <<'SQL'
CREATE TABLE IF NOT EXISTS traces (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  url TEXT NOT NULL,
  method TEXT DEFAULT 'GET',
  status_code INTEGER,
  dns_ms REAL DEFAULT 0,
  connect_ms REAL DEFAULT 0,
  tls_ms REAL DEFAULT 0,
  ttfb_ms REAL DEFAULT 0,
  total_ms REAL DEFAULT 0,
  size_bytes INTEGER DEFAULT 0,
  redirects INTEGER DEFAULT 0,
  final_url TEXT DEFAULT '',
  ts TEXT DEFAULT (datetime('now'))
);
SQL
}

do_trace() {
  local url="$1" method="${2:-GET}" data="${3:-}" headers_extra="${4:-}"
  echo ""
  echo -e "${CYAN}${BOLD}🔍 HTTP Trace: $url${NC}"
  echo ""

  # Use curl with timing
  local tmpfile; tmpfile=$(mktemp /tmp/br-trace-XXXXX)
  local tmpheaders; tmpheaders=$(mktemp /tmp/br-trace-hdr-XXXXX)
  local tmptiming; tmptiming=$(mktemp /tmp/br-trace-time-XXXXX)

  local curl_args=(-s -L -X "$method" -o "$tmpfile" -D "$tmpheaders" \
    --write-out '%{http_code}|%{time_namelookup}|%{time_connect}|%{time_appconnect}|%{time_starttransfer}|%{time_total}|%{size_download}|%{num_redirects}|%{url_effective}' \
    --max-time 30)

  [[ -n "$data" ]] && curl_args+=(-d "$data" -H "Content-Type: application/json")
  [[ -n "$headers_extra" ]] && curl_args+=(-H "$headers_extra")

  local timing
  timing=$(curl "${curl_args[@]}" "$url" 2>/dev/null | tee "$tmptiming")
  IFS="|" read -r http_status dns connect tls ttfb total size redirects final_url <<< "$timing"

  # Convert to ms
  local dns_ms connect_ms tls_ms ttfb_ms total_ms
  dns_ms=$(python3 -c "print(f'{float(${dns:-0})*1000:.1f}')")
  connect_ms=$(python3 -c "print(f'{float(${connect:-0})*1000:.1f}')")
  tls_ms=$(python3 -c "print(f'{(float(${tls:-0})-float(${connect:-0}))*1000:.1f}')")
  ttfb_ms=$(python3 -c "print(f'{float(${ttfb:-0})*1000:.1f}')")
  total_ms=$(python3 -c "print(f'{float(${total:-0})*1000:.1f}')")

  # Status color
  local sc="$NC"
  if [[ "$http_status" -lt 300 ]]; then sc="$GREEN"
  elif [[ "$http_status" -lt 400 ]]; then sc="$YELLOW"
  else sc="$RED"
  fi

  echo -e "  ${BOLD}Status:${NC}   ${sc}${http_status}${NC}"
  [[ "$final_url" != "$url" ]] && echo -e "  ${BOLD}Final URL:${NC} $final_url"
  [[ "${redirects:-0}" -gt 0 ]] && echo -e "  ${BOLD}Redirects:${NC} $redirects"
  echo ""

  # Timing breakdown
  echo -e "  ${BLUE}${BOLD}Timing:${NC}"
  echo -e "  ┌─────────────────────────────────────────"
  printf "  │  %-18s %s ms\n" "DNS lookup" "$dns_ms"
  printf "  │  %-18s %s ms\n" "TCP connect" "$connect_ms"
  printf "  │  %-18s %s ms\n" "TLS handshake" "$tls_ms"
  printf "  │  %-18s %s ms\n" "TTFB" "$ttfb_ms"
  printf "  │  %-18s ${BOLD}%s ms${NC}\n" "Total" "$total_ms"
  echo -e "  └─────────────────────────────────────────"
  echo ""

  # Visual timing bar
  local bar_width=40
  local total_f; total_f=$(echo "$total_ms" | tr -d ' ')
  [[ "$total_f" == "0.0" || -z "$total_f" ]] && total_f="1"
  echo -e "  ${BLUE}${BOLD}Timeline:${NC}"
  python3 - "$dns_ms" "$connect_ms" "$tls_ms" "$ttfb_ms" "$total_ms" << 'PY'
import sys
dns, tcp, tls, ttfb, total = (float(x) for x in sys.argv[1:])
width = 40
total = max(total, 1)
segments = [
    ("DNS", dns, "\033[0;34m"),
    ("TCP", tcp-dns, "\033[0;32m"),
    ("TLS", tls, "\033[0;35m"),
    ("TTFB", ttfb-tcp-tls, "\033[0;33m"),
]
bar = ""
for name, dur, color in segments:
    if dur <= 0: continue
    chars = max(1, int((dur/total)*width))
    bar += f"{color}{'█'*chars}\033[0m"
print(f"  [{bar}] {total:.1f}ms")
print()
for name, dur, color in segments:
    if dur <= 0: continue
    print(f"  {color}█\033[0m {name:<6} {dur:.1f}ms")
PY
  echo ""

  # Response headers
  echo -e "  ${BLUE}${BOLD}Response Headers:${NC}"
  head -30 "$tmpheaders" | grep -E "^[A-Za-z]" | while IFS=: read -r key val; do
    printf "  ${CYAN}%-30s${NC} %s\n" "$key:" "$(echo "$val" | tr -d '\r' | head -c 80)"
  done
  echo ""

  # Response body preview
  local size_h; size_h=$(python3 -c "s=${size:-0}; print(f'{s/1024:.1f}KB' if s>1024 else f'{s}B')")
  echo -e "  ${BLUE}${BOLD}Response Body:${NC} $size_h"
  if python3 -c "import json; json.load(open('$tmpfile'))" 2>/dev/null; then
    python3 -c "
import json
try:
    d = json.load(open('$tmpfile'))
    s = json.dumps(d, indent=2)
    lines = s.splitlines()
    for l in lines[:20]: print(f'  {l}')
    if len(lines) > 20: print(f'  ... ({len(lines)-20} more lines)')
except: pass
"
  else
    head -c 500 "$tmpfile" | sed 's/^/  /'
  fi
  echo ""

  # Save to DB
  sqlite3 "$DB" "INSERT INTO traces (url, method, status_code, dns_ms, connect_ms, tls_ms, ttfb_ms, total_ms, size_bytes, redirects, final_url) VALUES ('$url', '$method', ${http_status:-0}, $dns_ms, $connect_ms, $tls_ms, $ttfb_ms, $total_ms, ${size:-0}, ${redirects:-0}, '$final_url');"

  rm -f "$tmpfile" "$tmpheaders" "$tmptiming"
}

cmd_compare() {
  local url1="$1" url2="$2"
  [[ -z "$url1" || -z "$url2" ]] && { echo "Usage: br trace compare <url1> <url2>"; exit 1; }
  echo ""
  echo -e "${CYAN}${BOLD}⚡ Comparing:${NC}"
  echo -e "  A: $url1"
  echo -e "  B: $url2"
  echo ""
  local r1 r2
  r1=$(curl -sL -o /dev/null -w "%{http_code}|%{time_total}|%{size_download}" --max-time 15 "$url1" 2>/dev/null)
  r2=$(curl -sL -o /dev/null -w "%{http_code}|%{time_total}|%{size_download}" --max-time 15 "$url2" 2>/dev/null)
  IFS="|" read -r s1 t1 sz1 <<< "$r1"
  IFS="|" read -r s2 t2 sz2 <<< "$r2"
  local ms1; ms1=$(python3 -c "print(f'{float(${t1:-0})*1000:.1f}')")
  local ms2; ms2=$(python3 -c "print(f'{float(${t2:-0})*1000:.1f}')")
  echo -e "  ${GREEN}A:${NC}  status=${s1}  time=${ms1}ms  size=${sz1}B"
  echo -e "  ${BLUE}B:${NC}  status=${s2}  time=${ms2}ms  size=${sz2}B"
  echo ""
  python3 - "$ms1" "$ms2" << 'PY'
import sys
a, b = float(sys.argv[1]), float(sys.argv[2])
if a > 0 and b > 0:
    ratio = b/a
    if ratio > 1:
        print(f"  B is {ratio:.1f}x SLOWER than A (+{b-a:.1f}ms)")
    else:
        print(f"  B is {1/ratio:.1f}x FASTER than A ({a-b:.1f}ms savings)")
PY
  echo ""
}

cmd_history() {
  local limit="${1:-10}"
  echo ""
  echo -e "${CYAN}${BOLD}📜 Trace History${NC}"
  echo ""
  sqlite3 -separator "|" "$DB" "SELECT method, url, status_code, total_ms, size_bytes, ts FROM traces ORDER BY ts DESC LIMIT $limit;" | while IFS="|" read -r m u s t sz ts; do
    local sc="$NC"
    [[ "$s" -lt 300 ]] && sc="$GREEN"
    [[ "$s" -ge 400 ]] && sc="$RED"
    printf "  ${sc}%-4s %-5s${NC}  %-8s  %-45s  %s\n" "$m" "$s" "${t}ms" "${u:0:45}" "${ts:0:16}"
  done
  echo ""
}

show_help() {
  echo ""
  echo -e "${CYAN}${BOLD}br trace${NC} — HTTP request inspector"
  echo ""
  echo -e "  ${GREEN}br trace <url>${NC}                   Full trace"
  echo -e "  ${GREEN}br trace <url> -X POST -d '{}'${NC}   POST with body"
  echo -e "  ${GREEN}br trace <url> -H 'Auth: Bearer x'${NC}"
  echo -e "  ${GREEN}br trace compare <url1> <url2>${NC}   A/B timing comparison"
  echo -e "  ${GREEN}br trace history [n]${NC}             Recent traces"
  echo ""
  echo -e "  Shows: DNS/TCP/TLS/TTFB timing, headers, body preview, visual bar"
  echo ""
}

init_db
case "${1:-}" in
  ""|-h|help)   show_help ;;
  compare)      shift; cmd_compare "$@" ;;
  history|hist) shift; cmd_history "$@" ;;
  *)
    url="$1"; shift
    method="GET"; data=""; extra_header=""
    while [[ "$#" -gt 0 ]]; do
      case "$1" in
        -X) method="$2"; shift 2 ;;
        -d|--data) data="$2"; shift 2 ;;
        -H) extra_header="$2"; shift 2 ;;
        *) shift ;;
      esac
    done
    do_trace "$url" "$method" "$data" "$extra_header"
    ;;
esac
