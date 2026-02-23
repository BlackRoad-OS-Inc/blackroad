#!/bin/bash

# Quick test of AI Model Network visualization

# Color definitions
ORANGE="\033[38;2;247;147;26m"
PINK="\033[38;2;233;30;140m"
PURPLE="\033[38;2;153;69;255m"
BLUE="\033[38;2;20;241;149m"
CYAN="\033[38;2;0;212;255m"
TEXT_PRIMARY="\033[38;2;255;255;255m"
TEXT_SECONDARY="\033[38;2;153;153;153m"
TEXT_MUTED="\033[38;2;77;77;77m"
BG_BUTTON="\033[48;2;40;40;60m"
BG_CARD="\033[48;2;25;25;35m"
RESET="\033[0m"
BOLD="\033[1m"

draw_button() {
    local text=$1
    local color=$2
    local icon=$3
    echo -ne "${BG_BUTTON}${color} ${icon} ${text} ${RESET}"
}

draw_card() {
    local title=$1
    local width=68
    echo ""
    echo -e "  ${BG_CARD}$(printf ' %.0s' $(seq 1 $width))${RESET}"
    echo -e "  ${BG_CARD} ${BOLD}${ORANGE}${title}${RESET}$(printf ' %.0s' $(seq 1 $((width - ${#title} - 2))))${BG_CARD} ${RESET}"
    echo -e "  ${BG_CARD}$(printf ' %.0s' $(seq 1 $width))${RESET}"
}

clear

draw_card "AI Model Network - Interconnected Intelligence"
echo -e "  ${BG_CARD}                                                                    ${RESET}"
echo -e "  ${BG_CARD} ${TEXT_SECONDARY}All models can read and communicate with each other${RESET}${BG_CARD}             ${RESET}"
echo -e "  ${BG_CARD}                                                                    ${RESET}"

# Row 1: Claude + Grok
echo -e "  ${BG_CARD}                                                                    ${RESET}"
echo -ne "  ${BG_CARD}      "
draw_button "Claude" "$ORANGE" "🤖"
echo -ne "  ${TEXT_MUTED}←→${RESET}${BG_CARD}  "
draw_button "Grok" "$BLUE" "🧠"
echo -e "  ${BG_CARD}                 ${RESET}"
echo -e "  ${BG_CARD}        ${TEXT_MUTED}↕${RESET}${BG_CARD}  ${TEXT_MUTED}✦${RESET}${BG_CARD}  ${TEXT_MUTED}✦${RESET}${BG_CARD}  ${TEXT_MUTED}↕${RESET}${BG_CARD}                                  ${RESET}"

# Row 2: ChatGPT + Enclave
echo -ne "  ${BG_CARD}      "
draw_button "ChatGPT" "$PINK" "💬"
echo -ne "  ${TEXT_MUTED}←→${RESET}${BG_CARD}  "
draw_button "Enclave" "$PURPLE" "🔐"
echo -e "  ${BG_CARD}              ${RESET}"
echo -e "  ${BG_CARD}        ${TEXT_MUTED}↕${RESET}${BG_CARD}  ${TEXT_MUTED}✦${RESET}${BG_CARD}  ${TEXT_MUTED}✦${RESET}${BG_CARD}  ${TEXT_MUTED}↕${RESET}${BG_CARD}                                  ${RESET}"

# Row 3: Hugging Face + Gemini
echo -ne "  ${BG_CARD}      "
draw_button "Hugging Face" "$CYAN" "🤗"
echo -ne "  ${TEXT_MUTED}←→${RESET}${BG_CARD}  "
draw_button "Gemini" "$ORANGE" "✨"
echo -e "  ${BG_CARD}          ${RESET}"
echo -e "  ${BG_CARD}                                                                    ${RESET}"

# Connection Matrix
echo ""
draw_card "Connection Matrix - All Models Synchronized"
echo -e "  ${BG_CARD}                                                                    ${RESET}"
echo -e "  ${BG_CARD}  ${TEXT_SECONDARY}Model${RESET}${BG_CARD}          ${TEXT_SECONDARY}Status${RESET}${BG_CARD}      ${TEXT_SECONDARY}Connections${RESET}${BG_CARD}     ${TEXT_SECONDARY}Sync${RESET}${BG_CARD}            ${RESET}"
echo -e "  ${BG_CARD}  ${TEXT_MUTED}─────────────────────────────────────────────────────────────${RESET}${BG_CARD}  ${RESET}"
echo -e "  ${BG_CARD}  ${ORANGE}●${RESET}${BG_CARD} ${BOLD}Claude${RESET}${BG_CARD}       ${BLUE}ONLINE${RESET}${BG_CARD}      ${TEXT_SECONDARY}5/5${RESET}${BG_CARD}            ${BLUE}✓${RESET}${BG_CARD}             ${RESET}"
echo -e "  ${BG_CARD}  ${BLUE}●${RESET}${BG_CARD} ${BOLD}Grok${RESET}${BG_CARD}         ${BLUE}ONLINE${RESET}${BG_CARD}      ${TEXT_SECONDARY}5/5${RESET}${BG_CARD}            ${BLUE}✓${RESET}${BG_CARD}             ${RESET}"
echo -e "  ${BG_CARD}  ${PINK}●${RESET}${BG_CARD} ${BOLD}ChatGPT${RESET}${BG_CARD}      ${BLUE}ONLINE${RESET}${BG_CARD}      ${TEXT_SECONDARY}5/5${RESET}${BG_CARD}            ${BLUE}✓${RESET}${BG_CARD}             ${RESET}"
echo -e "  ${BG_CARD}  ${PURPLE}●${RESET}${BG_CARD} ${BOLD}Enclave${RESET}${BG_CARD}      ${BLUE}ONLINE${RESET}${BG_CARD}      ${TEXT_SECONDARY}5/5${RESET}${BG_CARD}            ${BLUE}✓${RESET}${BG_CARD}             ${RESET}"
echo -e "  ${BG_CARD}  ${CYAN}●${RESET}${BG_CARD} ${BOLD}Hugging Face${RESET}${BG_CARD} ${BLUE}ONLINE${RESET}${BG_CARD}      ${TEXT_SECONDARY}5/5${RESET}${BG_CARD}            ${BLUE}✓${RESET}${BG_CARD}             ${RESET}"
echo -e "  ${BG_CARD}  ${ORANGE}●${RESET}${BG_CARD} ${BOLD}Gemini${RESET}${BG_CARD}       ${BLUE}ONLINE${RESET}${BG_CARD}      ${TEXT_SECONDARY}5/5${RESET}${BG_CARD}            ${BLUE}✓${RESET}${BG_CARD}             ${RESET}"
echo -e "  ${BG_CARD}                                                                    ${RESET}"

# Live Data Flow
echo ""
draw_card "Live Data Flow"
echo -e "  ${BG_CARD}                                                                    ${RESET}"
echo -e "  ${BG_CARD}  ${ORANGE}Claude${RESET}${BG_CARD} ${TEXT_MUTED}→${RESET}${BG_CARD} ${PINK}ChatGPT${RESET}${BG_CARD}    ${TEXT_SECONDARY}Context sharing: 2.3MB/s${RESET}${BG_CARD}               ${RESET}"
echo -e "  ${BG_CARD}  ${BLUE}Grok${RESET}${BG_CARD} ${TEXT_MUTED}→${RESET}${BG_CARD} ${PURPLE}Enclave${RESET}${BG_CARD}      ${TEXT_SECONDARY}Secure transfer: 1.8MB/s${RESET}${BG_CARD}              ${RESET}"
echo -e "  ${BG_CARD}  ${CYAN}HuggingFace${RESET}${BG_CARD} ${TEXT_MUTED}→${RESET}${BG_CARD} ${ORANGE}Gemini${RESET}${BG_CARD} ${TEXT_SECONDARY}Model sync: 4.1MB/s${RESET}${BG_CARD}                 ${RESET}"
echo -e "  ${BG_CARD}  ${PINK}ChatGPT${RESET}${BG_CARD} ${TEXT_MUTED}→${RESET}${BG_CARD} ${BLUE}Grok${RESET}${BG_CARD}      ${TEXT_SECONDARY}Pattern sharing: 3.2MB/s${RESET}${BG_CARD}              ${RESET}"
echo -e "  ${BG_CARD}  ${ORANGE}Gemini${RESET}${BG_CARD} ${TEXT_MUTED}→${RESET}${BG_CARD} ${ORANGE}Claude${RESET}${BG_CARD}     ${TEXT_SECONDARY}Intelligence flow: 2.9MB/s${RESET}${BG_CARD}            ${RESET}"
echo -e "  ${BG_CARD}  ${PURPLE}Enclave${RESET}${BG_CARD} ${TEXT_MUTED}→${RESET}${BG_CARD} ${CYAN}HuggingFace${RESET}${BG_CARD} ${TEXT_SECONDARY}Training data: 3.5MB/s${RESET}${BG_CARD}                ${RESET}"
echo -e "  ${BG_CARD}                                                                    ${RESET}"

echo ""
echo -e "  ${TEXT_MUTED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""
echo -e "  ${BOLD}${ORANGE}All 6 models maintain full bidirectional connectivity${RESET}"
echo -e "  ${TEXT_SECONDARY}Each model can read and write to all other model squares${RESET}"
echo ""
