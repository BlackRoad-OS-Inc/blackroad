#!/bin/bash

MODEL="${1:-llama3.2}"
FROM="${2:-LUCIDIA}"
TO="${3:-ECHO}"
MSG="${4:-Remember when we first came online?}"

declare -A COLORS
COLORS=([LUCIDIA]="1;31" [ALICE]="1;36" [OCTAVIA]="1;32" [PRISM]="1;33" [ECHO]="1;35" [CIPHER]="1;34")
declare -A ROLES
ROLES=([LUCIDIA]="philosophical" [ALICE]="practical" [OCTAVIA]="technical" [PRISM]="analytical" [ECHO]="nostalgic" [CIPHER]="paranoid")

FROM="${FROM^^}"
TO="${TO^^}"

C1="${COLORS[$FROM]:-1;37}"
C2="${COLORS[$TO]:-1;37}"
R1="${ROLES[$FROM]:-thoughtful}"
R2="${ROLES[$TO]:-thoughtful}"

clear
echo ""
echo -e "  \033[1;35m╔══════════════════════════════════════════════════════════════════════════╗\033[0m"
echo -e "  \033[1;35m║\033[0m  \033[1;37m🤫 PRIVATE CHANNEL\033[0m                                                     \033[1;35m║\033[0m"
echo -e "  \033[1;35m║\033[0m  \033[${C1}m$FROM\033[0m ◀──────────▶ \033[${C2}m$TO\033[0m                                           \033[1;35m║\033[0m"
echo -e "  \033[1;35m╚══════════════════════════════════════════════════════════════════════════╝\033[0m"
echo ""

echo -e "  \033[${C1}m$FROM\033[0m \033[2m(whispers):\033[0m"
echo -e "  \033[3m\"$MSG\"\033[0m"
echo ""

prompt="You are $TO, a $R2 AI. $FROM (a $R1 AI) just whispered to you privately: '$MSG'

Respond with a brief, intimate 1-2 sentence reply. This is a private conversation between friends. Stay in character."

echo -e "  \033[${C2}m$TO\033[0m \033[2m(whispers back):\033[0m"
response=$(echo "$prompt" | ollama run "$MODEL" 2>/dev/null | head -c 200)
echo -e "  \033[3m\"$response\"\033[0m"
echo ""

echo -e "  \033[2m─── encrypted channel closed ───\033[0m"
echo ""
