#!/bin/bash

# BlackRoad OS - Genetic Engineering Lab
# CRISPR gene editing and genome engineering

source ~/blackroad-dashboards/themes.sh
load_theme

EDIT_MODE="CRISPR-Cas9"
SUCCESS_RATE=94
ORGANISMS_MODIFIED=0

# Show genetic engineering dashboard
show_genetic_lab() {
    clear
    echo ""
    echo -e "${BOLD}${GREEN}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${GREEN}║${RESET}  ${CYAN}🧬${RESET} ${BOLD}GENETIC ENGINEERING LAB${RESET}                                         ${BOLD}${GREEN}║${RESET}"
    echo -e "${BOLD}${GREEN}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""

    # CRISPR editing visualization
    echo -e "${TEXT_MUTED}╭─ CRISPR-CAS9 GENE EDITING ────────────────────────────────────────────╮${RESET}"
    echo ""

    echo "  ${BOLD}Step 1: Guide RNA Recognition${RESET}"
    echo ""
    echo "    ${CYAN}5'${RESET} ${CYAN}ATGCTAGCTAGCTA${RESET}${GREEN}GCTAGCTA${RESET}${CYAN}GCTAGCTA${RESET} ${CYAN}3'${RESET}  ${TEXT_MUTED}DNA${RESET}"
    echo "       ${TEXT_MUTED}│││││││││││││││││││││││││││││${RESET}"
    echo "    ${ORANGE}3'${RESET} ${ORANGE}TACGATCGATCGAT${RESET}${PURPLE}CGATCGAT${RESET}${ORANGE}CGATCGAT${RESET} ${ORANGE}5'${RESET}  ${TEXT_MUTED}Guide RNA${RESET}"
    echo ""
    echo "                       ${PINK}↓${RESET} ${TEXT_MUTED}Cas9 cuts here${RESET}"
    echo ""

    echo "  ${BOLD}Step 2: DNA Cleavage${RESET}"
    echo ""
    echo "    ${CYAN}5'${RESET} ${CYAN}ATGCTAGCTAGCTA${RESET} ${RED}✂${RESET} ${CYAN}GCTAGCTA${RESET} ${CYAN}3'${RESET}"
    echo "    ${ORANGE}3'${RESET} ${ORANGE}TACGATCGATCGAT${RESET} ${RED}✂${RESET} ${ORANGE}CGATCGAT${RESET} ${ORANGE}5'${RESET}"
    echo ""

    echo "  ${BOLD}Step 3: Insert New Gene${RESET}"
    echo ""
    echo "    ${CYAN}5'${RESET} ${CYAN}ATGCTAGCTAGCTA${RESET}${GOLD}NNNNNNNN${RESET}${CYAN}GCTAGCTA${RESET} ${CYAN}3'${RESET}  ${TEXT_MUTED}Modified DNA${RESET}"
    echo "    ${ORANGE}3'${RESET} ${ORANGE}TACGATCGATCGAT${RESET}${GOLD}NNNNNNNN${RESET}${ORANGE}CGATCGAT${RESET} ${ORANGE}5'${RESET}"
    echo ""
    echo "                       ${GOLD}New gene inserted${RESET}"
    echo ""

    # Genome browser
    echo -e "${TEXT_MUTED}╭─ GENOME BROWSER ──────────────────────────────────────────────────────╮${RESET}"
    echo ""

    echo "  ${BOLD}Chromosome 7 (152,000,000 bp)${RESET}"
    echo ""
    echo "  ${TEXT_MUTED}Position:${RESET} ${CYAN}117,000,000${RESET}"
    echo ""
    echo "  ${TEXT_MUTED}├──────────────────────────────────────────────────────────┤${RESET}"
    echo "  ${GREEN}████${RESET}      ${ORANGE}██${RESET}  ${PURPLE}███${RESET}        ${PINK}████${RESET}       ${BLUE}██${RESET}"
    echo "  ${TEXT_MUTED}Genes${RESET}    ${TEXT_MUTED}Exons${RESET} ${TEXT_MUTED}Introns${RESET}       ${TEXT_MUTED}Regulatory${RESET}  ${TEXT_MUTED}Target${RESET}"
    echo ""
    echo "  ${BOLD}${GREEN}CFTR Gene${RESET}  ${TEXT_MUTED}(Cystic Fibrosis Transmembrane Conductance Regulator)${RESET}"
    echo ""

    # Target mutation
    echo -e "${TEXT_MUTED}╭─ TARGET MUTATION ─────────────────────────────────────────────────────╮${RESET}"
    echo ""

    echo -e "  ${BOLD}${TEXT_PRIMARY}Gene:${RESET}                ${GREEN}CFTR${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Location:${RESET}            ${CYAN}Chromosome 7:117,199,563${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Mutation:${RESET}            ${RED}ΔF508${RESET} ${TEXT_MUTED}(deletion)${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Edit Type:${RESET}           ${ORANGE}Correction${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Status:${RESET}              ${GREEN}Ready for editing${RESET}"
    echo ""

    echo "  ${BOLD}Before:${RESET}  ${CYAN}...ATCATCTTT${RESET}${RED}---${RESET}${CYAN}GGTGTT...${RESET}  ${TEXT_MUTED}(3bp deletion)${RESET}"
    echo "  ${BOLD}After:${RESET}   ${CYAN}...ATCATCTTT${RESET}${GREEN}TTC${RESET}${CYAN}GGTGTT...${RESET}  ${TEXT_MUTED}(corrected)${RESET}"
    echo ""

    # Gene editing toolkit
    echo -e "${TEXT_MUTED}╭─ GENE EDITING TOOLKIT ────────────────────────────────────────────────╮${RESET}"
    echo ""

    echo -e "  ${BOLD}Available Tools:${RESET}"
    echo -e "    ${CYAN}●${RESET} ${BOLD}CRISPR-Cas9${RESET}        ${TEXT_MUTED}Double-strand breaks${RESET}      ${GREEN}✓ Active${RESET}"
    echo -e "    ${PURPLE}●${RESET} ${BOLD}CRISPR-Cas12${RESET}       ${TEXT_MUTED}Staggered cuts${RESET}            ${TEXT_MUTED}Available${RESET}"
    echo -e "    ${ORANGE}●${RESET} ${BOLD}Base Editors${RESET}       ${TEXT_MUTED}Single base changes${RESET}       ${TEXT_MUTED}Available${RESET}"
    echo -e "    ${PINK}●${RESET} ${BOLD}Prime Editing${RESET}      ${TEXT_MUTED}Precise insertions${RESET}        ${TEXT_MUTED}Available${RESET}"
    echo -e "    ${BLUE}●${RESET} ${BOLD}TALENs${RESET}             ${TEXT_MUTED}Targeted nucleases${RESET}        ${TEXT_MUTED}Available${RESET}"
    echo ""

    # Success metrics
    echo -e "${TEXT_MUTED}╭─ EDITING METRICS ─────────────────────────────────────────────────────╮${RESET}"
    echo ""

    echo -n "  ${BOLD}${TEXT_PRIMARY}Success Rate:${RESET}   "
    local bars=$((SUCCESS_RATE / 5))
    for ((i=0; i<bars; i++)); do echo -n "${GREEN}█${RESET}"; done
    for ((i=bars; i<20; i++)); do echo -n "${TEXT_MUTED}░${RESET}"; done
    echo -e "  ${BOLD}${GREEN}${SUCCESS_RATE}%${RESET}"
    echo ""

    echo -e "  ${BOLD}${TEXT_PRIMARY}On-Target:${RESET}           ${GREEN}98.7%${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Off-Target:${RESET}          ${ORANGE}1.3%${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Cells Modified:${RESET}      ${CYAN}847,234${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Organisms:${RESET}           ${PURPLE}$ORGANISMS_MODIFIED${RESET}"
    echo ""

    # Synthetic biology
    echo -e "${TEXT_MUTED}╭─ SYNTHETIC BIOLOGY ───────────────────────────────────────────────────╮${RESET}"
    echo ""

    echo "  ${BOLD}BioBrick Assembly:${RESET}"
    echo ""
    echo "    ${ORANGE}[Promoter]${RESET} ${CYAN}[RBS]${RESET} ${GREEN}[Gene]${RESET} ${PURPLE}[Terminator]${RESET}"
    echo "         ${TEXT_MUTED}│${RESET}        ${TEXT_MUTED}│${RESET}      ${TEXT_MUTED}│${RESET}        ${TEXT_MUTED}│${RESET}"
    echo "    ${ORANGE}▓▓▓▓${RESET}${CYAN}▓▓${RESET}${GREEN}▓▓▓▓▓▓▓▓${RESET}${PURPLE}▓▓▓${RESET}  ${TEXT_MUTED}Construct${RESET}"
    echo ""
    echo -e "  ${BOLD}${TEXT_PRIMARY}Function:${RESET}            ${GOLD}Produce insulin${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Expression:${RESET}          ${GREEN}High${RESET}"
    echo ""

    # Applications
    echo -e "${TEXT_MUTED}╭─ APPLICATIONS ────────────────────────────────────────────────────────╮${RESET}"
    echo ""

    echo -e "  ${GREEN}✓${RESET} ${BOLD}Disease Correction${RESET}   ${TEXT_MUTED}Sickle cell, cystic fibrosis${RESET}"
    echo -e "  ${CYAN}✓${RESET} ${BOLD}Cancer Therapy${RESET}       ${TEXT_MUTED}CAR-T cell engineering${RESET}"
    echo -e "  ${PURPLE}✓${RESET} ${BOLD}Crop Enhancement${RESET}     ${TEXT_MUTED}Drought resistance, yield${RESET}"
    echo -e "  ${ORANGE}✓${RESET} ${BOLD}Biofuels${RESET}             ${TEXT_MUTED}Algae engineering${RESET}"
    echo -e "  ${PINK}✓${RESET} ${BOLD}De-extinction${RESET}        ${TEXT_MUTED}Mammoth revival${RESET}"
    echo ""

    # Organism library
    echo -e "${TEXT_MUTED}╭─ MODIFIED ORGANISMS ──────────────────────────────────────────────────╮${RESET}"
    echo ""

    echo -e "  ${BOLD}Bacteria:${RESET}"
    echo -e "    ${CYAN}●${RESET} ${BOLD}E. coli${RESET} (insulin production)    ${GREEN}✓ Stable${RESET}"
    echo -e "    ${PURPLE}●${RESET} ${BOLD}B. subtilis${RESET} (enzyme factory)    ${GREEN}✓ Stable${RESET}"
    echo ""

    echo -e "  ${BOLD}Plants:${RESET}"
    echo -e "    ${GREEN}●${RESET} ${BOLD}Rice${RESET} (Golden Rice - Vitamin A)  ${ORANGE}⚠ Testing${RESET}"
    echo -e "    ${ORANGE}●${RESET} ${BOLD}Corn${RESET} (drought resistance)       ${GREEN}✓ Stable${RESET}"
    echo ""

    echo -e "  ${BOLD}Animals:${RESET}"
    echo -e "    ${PINK}●${RESET} ${BOLD}Mice${RESET} (disease models)           ${GREEN}✓ Stable${RESET}"
    echo -e "    ${BLUE}●${RESET} ${BOLD}Pigs${RESET} (organ transplants)         ${ORANGE}⚠ Testing${RESET}"
    echo ""

    # Protein design
    echo -e "${TEXT_MUTED}╭─ PROTEIN ENGINEERING ─────────────────────────────────────────────────╮${RESET}"
    echo ""

    echo "                    ${CYAN}α-helix${RESET}"
    echo "                    ${CYAN}╱${RESET}${CYAN}○${RESET}${CYAN}○${RESET}${CYAN}○${RESET}${CYAN}╲${RESET}"
    echo "        ${ORANGE}β-sheet${RESET}  ${CYAN}│${RESET}${CYAN}○${RESET}  ${CYAN}○${RESET}${CYAN}│${RESET}"
    echo "          ${ORANGE}═══${RESET}    ${CYAN}│${RESET}${CYAN}○${RESET}${CYAN}○${RESET}${CYAN}○${RESET}${CYAN}│${RESET}    ${PURPLE}○${RESET}${PURPLE}○${RESET}  ${PURPLE}Loop${RESET}"
    echo "          ${ORANGE}═══${RESET}     ${CYAN}╲${RESET}${CYAN}○${RESET}${CYAN}○${RESET}${CYAN}╱${RESET}    ${PURPLE}○${RESET}${PURPLE}○${RESET}"
    echo ""
    echo -e "  ${BOLD}${TEXT_PRIMARY}Design:${RESET}              ${GOLD}Novel enzyme${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Function:${RESET}            ${GREEN}Plastic degradation${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Efficiency:${RESET}          ${CYAN}847x faster than natural${RESET}"
    echo ""

    # Ethics & safety
    echo -e "${TEXT_MUTED}╭─ ETHICS & SAFETY ─────────────────────────────────────────────────────╮${RESET}"
    echo ""

    echo -e "  ${GREEN}✓${RESET} ${BOLD}IRB Approved${RESET}         ${TEXT_MUTED}Institutional Review Board${RESET}"
    echo -e "  ${GREEN}✓${RESET} ${BOLD}Biosafety Level:${RESET}     ${CYAN}BSL-2${RESET}"
    echo -e "  ${GREEN}✓${RESET} ${BOLD}Containment:${RESET}         ${PURPLE}Physical + Biological${RESET}"
    echo -e "  ${ORANGE}⚠${RESET} ${BOLD}Germline Editing:${RESET}   ${RED}Restricted${RESET}"
    echo ""

    # Lab equipment
    echo -e "${TEXT_MUTED}╭─ LABORATORY EQUIPMENT ────────────────────────────────────────────────╮${RESET}"
    echo ""

    echo -e "  ${GREEN}●${RESET} ${BOLD}DNA Sequencer${RESET}        ${TEXT_MUTED}Illumina NovaSeq${RESET}   ${GREEN}✓ ONLINE${RESET}"
    echo -e "  ${CYAN}●${RESET} ${BOLD}PCR Thermocycler${RESET}     ${TEXT_MUTED}96-well${RESET}            ${GREEN}✓ ONLINE${RESET}"
    echo -e "  ${PURPLE}●${RESET} ${BOLD}Flow Cytometer${RESET}       ${TEXT_MUTED}BD FACSAria${RESET}        ${GREEN}✓ ONLINE${RESET}"
    echo -e "  ${ORANGE}●${RESET} ${BOLD}Incubator${RESET}            ${TEXT_MUTED}37°C, 5% CO₂${RESET}       ${GREEN}✓ ONLINE${RESET}"
    echo ""

    ORGANISMS_MODIFIED=$((ORGANISMS_MODIFIED + 1))

    echo -e "${GREEN}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo -e "  ${TEXT_SECONDARY}[E]${RESET} Edit  ${TEXT_SECONDARY}[D]${RESET} Design  ${TEXT_SECONDARY}[S]${RESET} Sequence  ${TEXT_SECONDARY}[T]${RESET} Test  ${TEXT_SECONDARY}[Q]${RESET} Quit"
    echo ""
}

# Main loop
main() {
    while true; do
        show_genetic_lab

        read -t 1 -n1 key

        case "$key" in
            'e'|'E')
                echo -e "\n${CYAN}Performing CRISPR edit...${RESET}"
                sleep 1
                echo -e "${GREEN}✓ Edit successful! Gene corrected.${RESET}"
                SUCCESS_RATE=$((SUCCESS_RATE + (RANDOM % 3 - 1)))
                [ $SUCCESS_RATE -gt 99 ] && SUCCESS_RATE=99
                [ $SUCCESS_RATE -lt 85 ] && SUCCESS_RATE=85
                sleep 1
                ;;
            'd'|'D')
                echo -e "\n${PURPLE}Designing synthetic gene...${RESET}"
                sleep 1
                echo -e "${GREEN}✓ Design complete!${RESET}"
                sleep 1
                ;;
            's'|'S')
                echo -e "\n${ORANGE}Sequencing genome...${RESET}"
                sleep 1
                echo -e "${GREEN}✓ Sequencing complete! 3.2 billion base pairs.${RESET}"
                sleep 1
                ;;
            't'|'T')
                echo -e "\n${PINK}Running organism tests...${RESET}"
                sleep 1
                echo -e "${GREEN}✓ Tests passed! Organism viable.${RESET}"
                sleep 1
                ;;
            'q'|'Q')
                echo -e "\n${CYAN}Genetic lab session ended${RESET}\n"
                exit 0
                ;;
        esac
    done
}

# Run
main
