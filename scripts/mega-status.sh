#!/bin/bash
# BlackRoad Mega Status - Everything at a glance

BR_PINK="\033[38;5;204m"
BR_ORANGE="\033[38;5;208m"
BR_BLUE="\033[38;5;33m"
BR_GREEN="\033[38;5;82m"
BR_RESET="\033[0m"

echo -e "${BR_PINK}╔══════════════════════════════════════════════════════════════════╗${BR_RESET}"
echo -e "${BR_PINK}║${BR_RESET}  ${BR_ORANGE}BLACKROAD MEGA STATUS${BR_RESET}                                          ${BR_PINK}║${BR_RESET}"
echo -e "${BR_PINK}╚══════════════════════════════════════════════════════════════════╝${BR_RESET}"

echo ""
echo -e "${BR_BLUE}=== AI FLEET ===${BR_RESET}"
for host in cecilia lucidia aria octavia shellfish codex-infinity; do
    echo -n "$host: "
    ssh -o ConnectTimeout=2 $host 'echo online' 2>/dev/null || echo "offline"
done
ssh -o ConnectTimeout=2 alice@alice 'echo alice: online' 2>/dev/null || echo "alice: offline"

echo ""
echo -e "${BR_BLUE}=== CLOUDFLARE ===${BR_RESET}"
echo "Pages: $(wrangler pages project list 2>/dev/null | wc -l | tr -d ' ') projects"
echo "Workers: $(ls ~/blackroad-*-worker 2>/dev/null | wc -l | tr -d ' ') directories"

echo ""
echo -e "${BR_BLUE}=== GITHUB ===${BR_RESET}"
echo "Orgs: 15"
echo "Repos: $(gh repo list BlackRoad-OS --limit 300 2>/dev/null | wc -l | tr -d ' ') in BlackRoad-OS"

echo ""
echo -e "${BR_BLUE}=== MEMORY ===${BR_RESET}"
echo "Entries: $(wc -l < ~/.blackroad/memory/journals/master-journal.jsonl 2>/dev/null || echo 0)"
echo "Tasks: $(ls ~/.blackroad/memory/tasks/available 2>/dev/null | wc -l) available"

echo ""
echo -e "${BR_GREEN}All systems operational!${BR_RESET}"
