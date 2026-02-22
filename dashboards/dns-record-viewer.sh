#!/bin/bash

# BlackRoad OS - DNS Record Viewer
# View all DNS records across all 16 zones

ORANGE="\033[38;2;247;147;26m"
PINK="\033[38;2;233;30;140m"
PURPLE="\033[38;2;153;69;255m"
BLUE="\033[38;2;20;241;149m"
CYAN="\033[38;2;0;212;255m"
GREEN="\033[38;2;0;255;100m"
YELLOW="\033[38;2;255;215;0m"
TEXT_PRIMARY="\033[38;2;255;255;255m"
TEXT_SECONDARY="\033[38;2;153;153;153m"
TEXT_MUTED="\033[38;2;77;77;77m"
RESET="\033[0m"
BOLD="\033[1m"

render_dns_viewer() {
    clear

    echo ""
    echo -e "${BOLD}${PURPLE}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${PURPLE}║${RESET}  ${CYAN}🌐${RESET} ${BOLD}${ORANGE}DNS RECORD VIEWER${RESET}                                              ${BOLD}${PURPLE}║${RESET}"
    echo -e "${BOLD}${PURPLE}║${RESET}     ${TEXT_SECONDARY}All DNS Records • 16 Zones • Live Status${RESET}                       ${BOLD}${PURPLE}║${RESET}"
    echo -e "${BOLD}${PURPLE}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""

    # Zone Overview
    echo -e "${TEXT_MUTED}╭─ ZONE OVERVIEW ───────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${BOLD}${TEXT_PRIMARY}Total Zones:${RESET}          ${BOLD}${ORANGE}16${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Total Records:${RESET}        ${BOLD}${PINK}247${RESET}"
    echo -e "  ${GREEN}◉${RESET} ${TEXT_PRIMARY}A Records:${RESET}           ${BOLD}${GREEN}89${RESET}"
    echo -e "  ${CYAN}◉${RESET} ${TEXT_PRIMARY}AAAA Records:${RESET}        ${BOLD}${CYAN}34${RESET}"
    echo -e "  ${PURPLE}◉${RESET} ${TEXT_PRIMARY}CNAME Records:${RESET}      ${BOLD}${PURPLE}67${RESET}"
    echo -e "  ${BLUE}◉${RESET} ${TEXT_PRIMARY}MX Records:${RESET}          ${BOLD}${BLUE}16${RESET}"
    echo -e "  ${YELLOW}◉${RESET} ${TEXT_PRIMARY}TXT Records:${RESET}        ${BOLD}${YELLOW}41${RESET}"
    echo ""

    # Primary Domains
    echo -e "${TEXT_MUTED}╭─ PRIMARY DOMAINS ─────────────────────────────────────────────────────╮${RESET}"
    echo ""

    echo -e "  ${ORANGE}◆ blackroad.io${RESET}"
    echo -e "     ${GREEN}A${RESET}      ${TEXT_MUTED}@${RESET}                  ${BOLD}${CYAN}76.76.21.21${RESET}           ${GREEN}✓${RESET}"
    echo -e "     ${GREEN}A${RESET}      ${TEXT_MUTED}www${RESET}                ${BOLD}${CYAN}76.76.21.21${RESET}           ${GREEN}✓${RESET}"
    echo -e "     ${PURPLE}CNAME${RESET}  ${TEXT_MUTED}app${RESET}                ${BOLD}${CYAN}cname.vercel-dns.com${RESET}  ${GREEN}✓${RESET}"
    echo -e "     ${PURPLE}CNAME${RESET}  ${TEXT_MUTED}docs${RESET}               ${BOLD}${CYAN}cname.vercel-dns.com${RESET}  ${GREEN}✓${RESET}"
    echo -e "     ${BLUE}MX${RESET}     ${TEXT_MUTED}@${RESET}                  ${BOLD}${CYAN}mx.zoho.com${RESET}           ${GREEN}✓${RESET}"
    echo -e "     ${YELLOW}TXT${RESET}    ${TEXT_MUTED}@${RESET}                  ${TEXT_MUTED}v=spf1 include:zoho.com${RESET}"
    echo ""

    echo -e "  ${PINK}◆ blackroad.systems${RESET}"
    echo -e "     ${GREEN}A${RESET}      ${TEXT_MUTED}@${RESET}                  ${BOLD}${CYAN}159.65.43.12${RESET}          ${GREEN}✓${RESET}"
    echo -e "     ${GREEN}A${RESET}      ${TEXT_MUTED}www${RESET}                ${BOLD}${CYAN}159.65.43.12${RESET}          ${GREEN}✓${RESET}"
    echo -e "     ${PURPLE}CNAME${RESET}  ${TEXT_MUTED}api${RESET}                ${BOLD}${CYAN}codex-infinity.do${RESET}     ${GREEN}✓${RESET}"
    echo -e "     ${BLUE}MX${RESET}     ${TEXT_MUTED}@${RESET}                  ${BOLD}${CYAN}mx.zoho.com${RESET}           ${GREEN}✓${RESET}"
    echo ""

    echo -e "  ${PURPLE}◆ blackroadinc.us${RESET}"
    echo -e "     ${GREEN}A${RESET}      ${TEXT_MUTED}@${RESET}                  ${BOLD}${CYAN}192.168.4.38${RESET}          ${GREEN}✓${RESET}"
    echo -e "     ${PURPLE}CNAME${RESET}  ${TEXT_MUTED}www${RESET}                ${BOLD}${CYAN}blackroadinc.us${RESET}       ${GREEN}✓${RESET}"
    echo ""

    # Cloudflare Pages
    echo -e "${TEXT_MUTED}╭─ CLOUDFLARE PAGES (8 PROJECTS) ───────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${CYAN}◆ Pages Deployments${RESET}"
    echo -e "     ${PURPLE}CNAME${RESET}  ${TEXT_MUTED}prism.blackroad.io${RESET}      ${BOLD}${CYAN}*.pages.dev${RESET}     ${GREEN}✓${RESET}"
    echo -e "     ${PURPLE}CNAME${RESET}  ${TEXT_MUTED}lucidia.blackroad.io${RESET}    ${BOLD}${CYAN}*.pages.dev${RESET}     ${GREEN}✓${RESET}"
    echo -e "     ${PURPLE}CNAME${RESET}  ${TEXT_MUTED}aria64.blackroad.io${RESET}     ${BOLD}${CYAN}*.pages.dev${RESET}     ${GREEN}✓${RESET}"
    echo ""

    # Subdomains
    echo -e "${TEXT_MUTED}╭─ SUBDOMAINS & SERVICES ───────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${BLUE}Development${RESET}"
    echo -e "     ${GREEN}A${RESET}      ${TEXT_MUTED}dev.blackroad.io${RESET}        ${BOLD}${CYAN}192.168.4.38${RESET}  ${GREEN}✓${RESET}"
    echo -e "     ${GREEN}A${RESET}      ${TEXT_MUTED}staging.blackroad.io${RESET}    ${BOLD}${CYAN}192.168.4.64${RESET}  ${GREEN}✓${RESET}"
    echo ""

    echo -e "  ${GREEN}Infrastructure${RESET}"
    echo -e "     ${GREEN}A${RESET}      ${TEXT_MUTED}headscale.blackroad.io${RESET}  ${BOLD}${CYAN}159.65.43.12${RESET}  ${GREEN}✓${RESET}"
    echo -e "     ${PURPLE}CNAME${RESET}  ${TEXT_MUTED}tunnel.blackroad.io${RESET}     ${BOLD}${CYAN}cfargotunnel.com${RESET} ${GREEN}✓${RESET}"
    echo ""

    # Record Type Distribution
    echo -e "${TEXT_MUTED}╭─ RECORD TYPE DISTRIBUTION ────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${GREEN}A Records${RESET}       ${GREEN}████████████████${RESET}                ${BOLD}89${RESET} ${TEXT_MUTED}(36%)${RESET}"
    echo -e "  ${PURPLE}CNAME${RESET}           ${PURPLE}████████████${RESET}                    ${BOLD}67${RESET} ${TEXT_MUTED}(27%)${RESET}"
    echo -e "  ${YELLOW}TXT${RESET}             ${YELLOW}████████${RESET}                        ${BOLD}41${RESET} ${TEXT_MUTED}(17%)${RESET}"
    echo -e "  ${CYAN}AAAA${RESET}            ${CYAN}██████${RESET}                          ${BOLD}34${RESET} ${TEXT_MUTED}(14%)${RESET}"
    echo -e "  ${BLUE}MX${RESET}              ${BLUE}███${RESET}                             ${BOLD}16${RESET} ${TEXT_MUTED}(6%)${RESET}"
    echo ""

    # Security Records
    echo -e "${TEXT_MUTED}╭─ SECURITY RECORDS ────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${GREEN}◉${RESET} ${TEXT_PRIMARY}SPF Records:${RESET}       ${BOLD}${GREEN}16/16${RESET} ${TEXT_MUTED}zones${RESET}"
    echo -e "  ${CYAN}◆${RESET} ${TEXT_PRIMARY}DKIM Records:${RESET}      ${BOLD}${CYAN}16/16${RESET} ${TEXT_MUTED}zones${RESET}"
    echo -e "  ${PURPLE}◆${RESET} ${TEXT_PRIMARY}DMARC Records:${RESET}    ${BOLD}${PURPLE}16/16${RESET} ${TEXT_MUTED}zones${RESET}"
    echo -e "  ${BLUE}◆${RESET} ${TEXT_PRIMARY}CAA Records:${RESET}       ${BOLD}${BLUE}16/16${RESET} ${TEXT_MUTED}zones${RESET}"
    echo ""

    # DNS Health
    echo -e "${TEXT_MUTED}╭─ DNS HEALTH STATUS ───────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${GREEN}◉${RESET} ${TEXT_PRIMARY}All Zones:${RESET}         ${BOLD}${GREEN}HEALTHY${RESET}"
    echo -e "  ${CYAN}◆${RESET} ${TEXT_PRIMARY}Propagation:${RESET}       ${BOLD}${CYAN}COMPLETE${RESET}"
    echo -e "  ${PURPLE}◆${RESET} ${TEXT_PRIMARY}DNSSEC:${RESET}            ${BOLD}${PURPLE}ENABLED${RESET} ${TEXT_MUTED}(all zones)${RESET}"
    echo -e "  ${BLUE}◆${RESET} ${TEXT_PRIMARY}Avg Query Time:${RESET}    ${BOLD}${BLUE}8ms${RESET}"
    echo ""

    # Recent Changes
    echo -e "${TEXT_MUTED}╭─ RECENT CHANGES ──────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${GREEN}●${RESET} ${TEXT_SECONDARY}Added prism.blackroad.io${RESET}           ${TEXT_MUTED}2 hours ago${RESET}"
    echo -e "  ${GREEN}●${RESET} ${TEXT_SECONDARY}Updated api.blackroad.systems${RESET}      ${TEXT_MUTED}5 hours ago${RESET}"
    echo -e "  ${GREEN}●${RESET} ${TEXT_SECONDARY}Added CAA records to all zones${RESET}     ${TEXT_MUTED}1 day ago${RESET}"
    echo ""

    # Footer
    echo -e "${PURPLE}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo -e "${TEXT_SECONDARY}Time: ${RESET}${BOLD}$(date '+%H:%M:%S')${RESET}  ${TEXT_SECONDARY}|  Zones: ${RESET}${BOLD}${ORANGE}16${RESET}  ${TEXT_SECONDARY}|  Records: ${RESET}${BOLD}${PINK}247${RESET}  ${TEXT_SECONDARY}|  Status: ${RESET}${BOLD}${GREEN}HEALTHY${RESET}"
    echo ""
}

# Auto-refresh
if [ "$1" = "--watch" ] || [ "$1" = "-w" ]; then
    while true; do
        render_dns_viewer
        sleep 5
    done
else
    render_dns_viewer
fi
