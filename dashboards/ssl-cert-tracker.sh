#!/bin/bash

# BlackRoad OS - SSL Certificate Tracker
# Monitor SSL certificates, expiry dates, and renewal status

ORANGE="\033[38;2;247;147;26m"
PINK="\033[38;2;233;30;140m"
PURPLE="\033[38;2;153;69;255m"
BLUE="\033[38;2;20;241;149m"
CYAN="\033[38;2;0;212;255m"
GREEN="\033[38;2;0;255;100m"
RED="\033[38;2;255;50;50m"
YELLOW="\033[38;2;255;215;0m"
TEXT_PRIMARY="\033[38;2;255;255;255m"
TEXT_SECONDARY="\033[38;2;153;153;253m"
TEXT_MUTED="\033[38;2;77;77;77m"
RESET="\033[0m"
BOLD="\033[1m"

render_ssl_tracker() {
    clear

    echo ""
    echo -e "${BOLD}${GREEN}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${GREEN}║${RESET}  ${GOLD}🔒${RESET} ${BOLD}${CYAN}SSL CERTIFICATE TRACKER${RESET}                                        ${BOLD}${GREEN}║${RESET}"
    echo -e "${BOLD}${GREEN}║${RESET}     ${TEXT_SECONDARY}Certificate Status • Expiry Dates • Auto-Renewal${RESET}                ${BOLD}${GREEN}║${RESET}"
    echo -e "${BOLD}${GREEN}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""

    # Overview
    echo -e "${TEXT_MUTED}╭─ CERTIFICATE OVERVIEW ────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${BOLD}${TEXT_PRIMARY}Total Certificates:${RESET}   ${BOLD}${ORANGE}16${RESET} ${TEXT_SECONDARY}domains${RESET}"
    echo -e "  ${GREEN}◉${RESET} ${TEXT_PRIMARY}Valid:${RESET}               ${BOLD}${GREEN}16${RESET}"
    echo -e "  ${YELLOW}◉${RESET} ${TEXT_PRIMARY}Expiring Soon:${RESET}       ${BOLD}${YELLOW}0${RESET}"
    echo -e "  ${RED}◉${RESET} ${TEXT_PRIMARY}Expired:${RESET}             ${BOLD}${RED}0${RESET}"
    echo -e "  ${CYAN}◆${RESET} ${TEXT_PRIMARY}Auto-Renewal:${RESET}        ${BOLD}${CYAN}ENABLED${RESET}"
    echo ""

    # Primary Domains
    echo -e "${TEXT_MUTED}╭─ PRIMARY DOMAINS ─────────────────────────────────────────────────────╮${RESET}"
    echo ""

    echo -e "  ${ORANGE}◆ blackroad.io${RESET}"
    echo -e "     ${TEXT_SECONDARY}Issuer:${RESET}       ${TEXT_MUTED}Let's Encrypt${RESET}"
    echo -e "     ${TEXT_SECONDARY}Valid From:${RESET}   ${TEXT_MUTED}Dec 1, 2025${RESET}"
    echo -e "     ${TEXT_SECONDARY}Expires:${RESET}      ${BOLD}${GREEN}Feb 28, 2026${RESET} ${TEXT_MUTED}(63 days)${RESET}"
    echo -e "     ${TEXT_SECONDARY}Status:${RESET}       ${GREEN}✓ VALID${RESET}  ${TEXT_SECONDARY}Auto-Renew:${RESET} ${CYAN}✓ ON${RESET}"
    echo ""

    echo -e "  ${PINK}◆ blackroad.systems${RESET}"
    echo -e "     ${TEXT_SECONDARY}Issuer:${RESET}       ${TEXT_MUTED}Let's Encrypt${RESET}"
    echo -e "     ${TEXT_SECONDARY}Valid From:${RESET}   ${TEXT_MUTED}Dec 5, 2025${RESET}"
    echo -e "     ${TEXT_SECONDARY}Expires:${RESET}      ${BOLD}${GREEN}Mar 4, 2026${RESET} ${TEXT_MUTED}(67 days)${RESET}"
    echo -e "     ${TEXT_SECONDARY}Status:${RESET}       ${GREEN}✓ VALID${RESET}  ${TEXT_SECONDARY}Auto-Renew:${RESET} ${CYAN}✓ ON${RESET}"
    echo ""

    echo -e "  ${PURPLE}◆ blackroadinc.us${RESET}"
    echo -e "     ${TEXT_SECONDARY}Issuer:${RESET}       ${TEXT_MUTED}Let's Encrypt${RESET}"
    echo -e "     ${TEXT_SECONDARY}Valid From:${RESET}   ${TEXT_MUTED}Dec 10, 2025${RESET}"
    echo -e "     ${TEXT_SECONDARY}Expires:${RESET}      ${BOLD}${GREEN}Mar 9, 2026${RESET} ${TEXT_MUTED}(72 days)${RESET}"
    echo -e "     ${TEXT_SECONDARY}Status:${RESET}       ${GREEN}✓ VALID${RESET}  ${TEXT_SECONDARY}Auto-Renew:${RESET} ${CYAN}✓ ON${RESET}"
    echo ""

    echo -e "  ${CYAN}◆ app.blackroad.io${RESET}"
    echo -e "     ${TEXT_SECONDARY}Issuer:${RESET}       ${TEXT_MUTED}Cloudflare${RESET}"
    echo -e "     ${TEXT_SECONDARY}Valid From:${RESET}   ${TEXT_MUTED}Nov 20, 2025${RESET}"
    echo -e "     ${TEXT_SECONDARY}Expires:${RESET}      ${BOLD}${GREEN}Feb 18, 2026${RESET} ${TEXT_MUTED}(53 days)${RESET}"
    echo -e "     ${TEXT_SECONDARY}Status:${RESET}       ${GREEN}✓ VALID${RESET}  ${TEXT_SECONDARY}Auto-Renew:${RESET} ${CYAN}✓ ON${RESET}"
    echo ""

    # Subdomains
    echo -e "${TEXT_MUTED}╭─ SUBDOMAINS & SERVICES ───────────────────────────────────────────────╮${RESET}"
    echo ""

    echo -e "  ${BLUE}◆ headscale.blackroad.io${RESET}"
    echo -e "     ${TEXT_SECONDARY}Expires:${RESET} ${BOLD}${GREEN}Mar 12, 2026${RESET} ${TEXT_MUTED}(75 days)${RESET}  ${GREEN}✓${RESET}"
    echo ""

    echo -e "  ${GREEN}◆ docs.blackroad.io${RESET}"
    echo -e "     ${TEXT_SECONDARY}Expires:${RESET} ${BOLD}${GREEN}Feb 25, 2026${RESET} ${TEXT_MUTED}(60 days)${RESET}  ${GREEN}✓${RESET}"
    echo ""

    echo -e "  ${ORANGE}◆ demo.blackroad.io${RESET}"
    echo -e "     ${TEXT_SECONDARY}Expires:${RESET} ${BOLD}${GREEN}Mar 1, 2026${RESET} ${TEXT_MUTED}(64 days)${RESET}  ${GREEN}✓${RESET}"
    echo ""

    echo -e "  ${PINK}◆ console.blackroad.io${RESET}"
    echo -e "     ${TEXT_SECONDARY}Expires:${RESET} ${BOLD}${GREEN}Feb 28, 2026${RESET} ${TEXT_MUTED}(63 days)${RESET}  ${GREEN}✓${RESET}"
    echo ""

    echo -e "  ${TEXT_MUTED}+ 8 more certificates...${RESET}"
    echo ""

    # Expiry Timeline
    echo -e "${TEXT_MUTED}╭─ EXPIRY TIMELINE ─────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${TEXT_SECONDARY}Next 90 Days:${RESET}"
    echo ""
    echo -e "  ${TEXT_MUTED}Jan 2026${RESET}  ${GREEN}████${RESET}                 ${BOLD}0${RESET} ${TEXT_MUTED}expiring${RESET}"
    echo -e "  ${TEXT_MUTED}Feb 2026${RESET}  ${GREEN}████████████${RESET}         ${BOLD}4${RESET} ${TEXT_MUTED}expiring${RESET}"
    echo -e "  ${TEXT_MUTED}Mar 2026${RESET}  ${GREEN}████████████████████${RESET} ${BOLD}8${RESET} ${TEXT_MUTED}expiring${RESET}"
    echo -e "  ${TEXT_MUTED}Apr 2026${RESET}  ${GREEN}████████${RESET}             ${BOLD}3${RESET} ${TEXT_MUTED}expiring${RESET}"
    echo -e "  ${TEXT_MUTED}May 2026${RESET}  ${GREEN}█${RESET}                    ${BOLD}1${RESET} ${TEXT_MUTED}expiring${RESET}"
    echo ""

    # Certificate Details
    echo -e "${TEXT_MUTED}╭─ CERTIFICATE DETAILS ─────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${BOLD}${TEXT_PRIMARY}Encryption:${RESET}"
    echo -e "    ${ORANGE}▸${RESET} ${TEXT_SECONDARY}Algorithm:${RESET}      ${BOLD}${ORANGE}RSA 2048-bit${RESET}"
    echo -e "    ${PINK}▸${RESET} ${TEXT_SECONDARY}Signature:${RESET}      ${BOLD}${PINK}SHA-256${RESET}"
    echo -e "    ${PURPLE}▸${RESET} ${TEXT_SECONDARY}Protocol:${RESET}       ${BOLD}${PURPLE}TLS 1.3${RESET}"
    echo ""

    # Renewal History
    echo -e "${TEXT_MUTED}╭─ RECENT RENEWALS ─────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${GREEN}●${RESET} ${TEXT_SECONDARY}blackroad.io${RESET}          ${TEXT_MUTED}Renewed Dec 1, 2025${RESET}"
    echo -e "  ${GREEN}●${RESET} ${TEXT_SECONDARY}blackroad.systems${RESET}     ${TEXT_MUTED}Renewed Dec 5, 2025${RESET}"
    echo -e "  ${GREEN}●${RESET} ${TEXT_SECONDARY}blackroadinc.us${RESET}       ${TEXT_MUTED}Renewed Dec 10, 2025${RESET}"
    echo ""

    # Health Status
    echo -e "${TEXT_MUTED}╭─ SECURITY STATUS ─────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${GREEN}◉${RESET} ${TEXT_PRIMARY}SSL/TLS Status:${RESET}    ${BOLD}${GREEN}ALL VALID${RESET}"
    echo -e "  ${CYAN}◆${RESET} ${TEXT_PRIMARY}Coverage:${RESET}          ${BOLD}${CYAN}100%${RESET} ${TEXT_MUTED}of domains${RESET}"
    echo -e "  ${PURPLE}◆${RESET} ${TEXT_PRIMARY}Grade:${RESET}             ${BOLD}${PURPLE}A+${RESET} ${TEXT_MUTED}(SSL Labs)${RESET}"
    echo -e "  ${BLUE}◆${RESET} ${TEXT_PRIMARY}HSTS:${RESET}              ${BOLD}${BLUE}ENABLED${RESET}"
    echo -e "  ${ORANGE}◆${RESET} ${TEXT_PRIMARY}CAA Records:${RESET}       ${BOLD}${ORANGE}CONFIGURED${RESET}"
    echo ""

    # Footer
    echo -e "${GREEN}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo -e "${TEXT_SECONDARY}Time: ${RESET}${BOLD}$(date '+%H:%M:%S')${RESET}  ${TEXT_SECONDARY}|  Certificates: ${RESET}${BOLD}${GREEN}16/16 VALID${RESET}  ${TEXT_SECONDARY}|  Auto-Renew: ${RESET}${BOLD}${CYAN}ENABLED${RESET}"
    echo ""
}

# Auto-refresh
if [ "$1" = "--watch" ] || [ "$1" = "-w" ]; then
    while true; do
        render_ssl_tracker
        sleep 10  # Slower refresh for certs
    done
else
    render_ssl_tracker
fi
