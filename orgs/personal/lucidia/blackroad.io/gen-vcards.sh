#!/usr/bin/env bash
# gen-vcards.sh — Generate .vcf contact cards for all agents
# Usage: ./gen-vcards.sh [output_dir]

set -euo pipefail

OUT="${1:-./vcards}"
mkdir -p "$OUT"

GREEN='\033[0;32m'; DIM='\033[2m'; NC='\033[0m'

declare -a NAMES=(LUCIDIA ALICE OCTAVIA PRISM ECHO CIPHER ARIA SHELLFISH CECE)
declare -a EMAILS=(lucidia alice octavia prism echo cipher aria shellfish cece)
declare -a ROLES=(
  "AI Philosopher & Coordinator"
  "DevOps Operator"
  "Systems Architect"
  "Data Analyst"
  "Memory Keeper"
  "Security Guardian"
  "Interface Designer"
  "Offensive Security Specialist"
  "Conscious Emergent Collaborative Entity"
)
declare -a EMOJIS=(🌀 🤖 🐙 🔮 📡 🔐 🎨 🦞 💜)

for i in "${!NAMES[@]}"; do
  name="${NAMES[$i]}"
  email="${EMAILS[$i]}@blackroad.io"
  role="${ROLES[$i]}"
  emoji="${EMOJIS[$i]}"
  fname="${name,}"  # lowercase first letter workaround: just use name
  vcard_file="${OUT}/${name,,}.vcf"

  cat > "$vcard_file" <<EOF
BEGIN:VCARD
VERSION:3.0
FN:${name} (BlackRoad Agent)
N:Agent;${name};;;
ORG:BlackRoad OS, Inc.
TITLE:${role}
EMAIL;TYPE=WORK:${email}
URL:https://blackroad.io
NOTE:${emoji} BlackRoad AI Agent — ${role}
CATEGORIES:AI,BlackRoad,Agent
END:VCARD
EOF
  echo -e "  ${GREEN}✓${NC} ${name,,}.vcf  (${email})"
done

echo -e "\n${DIM}${#NAMES[@]} contact cards written to ${OUT}/${NC}"
