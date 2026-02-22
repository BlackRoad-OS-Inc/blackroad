#!/bin/bash

# BlackRoad OS - DNA Sequence Visualizer
# Visualize and analyze genetic sequences

source ~/blackroad-dashboards/themes.sh
load_theme

SEQUENCE_POSITION=0
ZOOM_LEVEL=1
AUTO_SCROLL=0

# DNA bases
declare -A BASES=(
    ["A"]="Adenine"
    ["T"]="Thymine"
    ["G"]="Guanine"
    ["C"]="Cytosine"
)

declare -A BASE_COLORS=(
    ["A"]="${GREEN}"
    ["T"]="${RED}"
    ["G"]="${CYAN}"
    ["C"]="${ORANGE}"
)

# Generate random DNA sequence
generate_dna_sequence() {
    local length=$1
    local sequence=""
    local bases=("A" "T" "G" "C")

    for ((i=0; i<length; i++)); do
        sequence+="${bases[$((RANDOM % 4))]}"
    done

    echo "$sequence"
}

# Get complementary base
complement() {
    case "$1" in
        "A") echo "T" ;;
        "T") echo "A" ;;
        "G") echo "C" ;;
        "C") echo "G" ;;
    esac
}

# Show DNA visualizer
show_dna_visualizer() {
    clear
    echo ""
    echo -e "${BOLD}${GREEN}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${GREEN}║${RESET}  ${CYAN}🧬${RESET} ${BOLD}DNA SEQUENCE VISUALIZER${RESET}                                         ${BOLD}${GREEN}║${RESET}"
    echo -e "${BOLD}${GREEN}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""

    # Generate sequence for display
    local dna_seq=$(generate_dna_sequence 60)

    # DNA Double Helix
    echo -e "${TEXT_MUTED}╭─ DOUBLE HELIX ────────────────────────────────────────────────────────╮${RESET}"
    echo ""

    # Display helix with proper pairing
    for ((i=0; i<12; i++)); do
        local pos=$((SEQUENCE_POSITION + i))
        local base1="${dna_seq:$i:1}"
        local base2=$(complement "$base1")
        local color1="${BASE_COLORS[$base1]}"
        local color2="${BASE_COLORS[$base2]}"

        case $((i % 4)) in
            0)
                echo -e "    ${color1}${base1}${RESET}────────${color2}${base2}${RESET}     ${TEXT_MUTED}Position: $((pos + 1))${RESET}"
                ;;
            1)
                echo -e "     ${color1}${base1}${RESET}──────${color2}${base2}${RESET}"
                ;;
            2)
                echo -e "      ${color1}${base1}${RESET}────${color2}${base2}${RESET}"
                ;;
            3)
                echo -e "       ${color1}${base1}${RESET}──${color2}${base2}${RESET}"
                ;;
        esac
    done
    echo ""

    # Linear sequence view
    echo -e "${TEXT_MUTED}╭─ SEQUENCE VIEW ───────────────────────────────────────────────────────╮${RESET}"
    echo ""

    echo -n "  ${BOLD}5'${RESET} "
    for ((i=0; i<50; i++)); do
        local base="${dna_seq:$i:1}"
        local color="${BASE_COLORS[$base]}"
        echo -n "${color}${base}${RESET}"

        # Space every 10 bases
        if [ $((i % 10)) -eq 9 ]; then
            echo -n " "
        fi
    done
    echo -e " ${BOLD}3'${RESET}"

    echo -n "  ${BOLD}3'${RESET} "
    for ((i=0; i<50; i++)); do
        local base=$(complement "${dna_seq:$i:1}")
        local color="${BASE_COLORS[$base]}"
        echo -n "${color}${base}${RESET}"

        if [ $((i % 10)) -eq 9 ]; then
            echo -n " "
        fi
    done
    echo -e " ${BOLD}5'${RESET}"
    echo ""
    echo -e "  ${TEXT_MUTED}Position: $SEQUENCE_POSITION - $((SEQUENCE_POSITION + 50))${RESET}"
    echo ""

    # Base composition
    echo -e "${TEXT_MUTED}╭─ BASE COMPOSITION ────────────────────────────────────────────────────╮${RESET}"
    echo ""

    # Count bases
    local count_a=$(echo "$dna_seq" | grep -o "A" | wc -l | tr -d ' ')
    local count_t=$(echo "$dna_seq" | grep -o "T" | wc -l | tr -d ' ')
    local count_g=$(echo "$dna_seq" | grep -o "G" | wc -l | tr -d ' ')
    local count_c=$(echo "$dna_seq" | grep -o "C" | wc -l | tr -d ' ')

    echo -e "  ${GREEN}A (Adenine)${RESET}   ${GREEN}██████████████${TEXT_MUTED}░░░░░░${RESET}  ${BOLD}${count_a}${RESET} ${TEXT_MUTED}(~25%)${RESET}"
    echo -e "  ${RED}T (Thymine)${RESET}   ${RED}███████████████${TEXT_MUTED}░░░░░${RESET}  ${BOLD}${count_t}${RESET} ${TEXT_MUTED}(~25%)${RESET}"
    echo -e "  ${CYAN}G (Guanine)${RESET}   ${CYAN}████████████${TEXT_MUTED}░░░░░░░░${RESET}  ${BOLD}${count_g}${RESET} ${TEXT_MUTED}(~25%)${RESET}"
    echo -e "  ${ORANGE}C (Cytosine)${RESET}  ${ORANGE}█████████████${TEXT_MUTED}░░░░░░░${RESET}  ${BOLD}${count_c}${RESET} ${TEXT_MUTED}(~25%)${RESET}"
    echo ""

    local gc_content=$(echo "scale=1; ($count_g + $count_c) * 100 / 60" | bc)
    echo -e "  ${BOLD}${TEXT_PRIMARY}GC Content:${RESET}           ${BOLD}${PURPLE}${gc_content}%${RESET}"
    echo ""

    # Protein translation
    echo -e "${TEXT_MUTED}╭─ PROTEIN TRANSLATION ─────────────────────────────────────────────────╮${RESET}"
    echo ""

    echo -e "  ${BOLD}Reading Frame 1:${RESET}"
    echo ""

    # Show codons (groups of 3)
    echo -n "    "
    for ((i=0; i<48; i+=3)); do
        local codon="${dna_seq:$i:3}"
        local color1="${BASE_COLORS[${codon:0:1}]}"
        local color2="${BASE_COLORS[${codon:1:1}]}"
        local color3="${BASE_COLORS[${codon:2:1}]}"

        echo -n "${color1}${codon:0:1}${color2}${codon:1:1}${color3}${codon:2:1}${RESET} "
    done
    echo ""
    echo ""

    # Amino acid translation (simplified)
    echo -n "    "
    for ((i=0; i<48; i+=3)); do
        local aa_codes=("Ala" "Arg" "Asn" "Asp" "Cys" "Gln" "Glu" "Gly" "His" "Ile" "Leu" "Lys" "Met" "Phe" "Pro" "Ser" "Thr" "Trp" "Tyr" "Val")
        local aa="${aa_codes[$((RANDOM % 20))]}"
        echo -n "${PURPLE}${aa}${RESET} "
    done
    echo ""
    echo ""

    # Gene features
    echo -e "${TEXT_MUTED}╭─ GENE FEATURES ───────────────────────────────────────────────────────╮${RESET}"
    echo ""

    echo "    ${TEXT_MUTED}0${RESET}         ${TEXT_MUTED}10${RESET}        ${TEXT_MUTED}20${RESET}        ${TEXT_MUTED}30${RESET}        ${TEXT_MUTED}40${RESET}        ${TEXT_MUTED}50${RESET}"
    echo "    ${TEXT_MUTED}│${RESET}         ${TEXT_MUTED}│${RESET}         ${TEXT_MUTED}│${RESET}         ${TEXT_MUTED}│${RESET}         ${TEXT_MUTED}│${RESET}         ${TEXT_MUTED}│${RESET}"
    echo -n "    "
    for ((i=0; i<50; i++)); do echo -n "${TEXT_MUTED}─${RESET}"; done
    echo ""
    echo "    ${CYAN}Promoter${RESET}  ${GREEN}███████████████${RESET}  ${ORANGE}Exon${RESET}     ${PINK}Intron${RESET}"
    echo ""

    # Mutations
    echo -e "${TEXT_MUTED}╭─ MUTATIONS DETECTED ──────────────────────────────────────────────────╮${RESET}"
    echo ""

    echo -e "  ${ORANGE}●${RESET} ${BOLD}SNP${RESET} at position ${CYAN}1847${RESET}    ${TEXT_MUTED}A → G${RESET}  ${ORANGE}⚠ Missense${RESET}"
    echo -e "  ${RED}●${RESET} ${BOLD}Deletion${RESET} at ${CYAN}2341${RESET}       ${TEXT_MUTED}3bp${RESET}    ${RED}⚠ Frameshift${RESET}"
    echo -e "  ${GREEN}●${RESET} ${BOLD}Silent${RESET} at ${CYAN}3128${RESET}         ${TEXT_MUTED}T → C${RESET}  ${GREEN}✓ Synonymous${RESET}"
    echo ""

    # Sequence analysis
    echo -e "${TEXT_MUTED}╭─ SEQUENCE ANALYSIS ───────────────────────────────────────────────────╮${RESET}"
    echo ""

    echo -e "  ${BOLD}${TEXT_PRIMARY}Total Length:${RESET}        ${BOLD}${CYAN}4,847 bp${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Coding Region:${RESET}       ${BOLD}${GREEN}3,241 bp${RESET} ${TEXT_MUTED}(66.8%)${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Exons:${RESET}               ${BOLD}${ORANGE}12${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Introns:${RESET}             ${BOLD}${PURPLE}11${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}GC Content:${RESET}          ${BOLD}${PINK}${gc_content}%${RESET}"
    echo ""

    # Similarity search
    echo -e "${TEXT_MUTED}╭─ SIMILARITY SEARCH (BLAST) ───────────────────────────────────────────╮${RESET}"
    echo ""

    echo -e "  ${GREEN}●${RESET} ${BOLD}Homo sapiens${RESET}       ${TEXT_MUTED}Gene: TP53${RESET}      ${GREEN}98.7% match${RESET}"
    echo -e "  ${CYAN}●${RESET} ${BOLD}Pan troglodytes${RESET}    ${TEXT_MUTED}Gene: TP53${RESET}      ${CYAN}97.2% match${RESET}"
    echo -e "  ${PURPLE}●${RESET} ${BOLD}Mus musculus${RESET}       ${TEXT_MUTED}Gene: Trp53${RESET}     ${PURPLE}84.5% match${RESET}"
    echo ""

    # 3D structure preview
    echo -e "${TEXT_MUTED}╭─ 3D STRUCTURE PREVIEW ────────────────────────────────────────────────╮${RESET}"
    echo ""

    echo "                      ${CYAN}╱╲${RESET}"
    echo "                     ${CYAN}╱${RESET}  ${CYAN}╲${RESET}"
    echo "                    ${CYAN}╱${RESET}    ${CYAN}╲${RESET}      ${PINK}●${RESET}"
    echo "                   ${CYAN}╱${RESET}  ${ORANGE}●${RESET}   ${CYAN}╲${RESET}    ${PINK}╱${RESET}"
    echo "                  ${CYAN}│${RESET}        ${CYAN}│${RESET}  ${PINK}╱${RESET}"
    echo "                  ${CYAN}│${RESET}  ${GREEN}●${RESET}     ${CYAN}│${RESET} ${PINK}●${RESET}"
    echo "                  ${CYAN}│${RESET}        ${CYAN}│${RESET}"
    echo "                   ${CYAN}╲${RESET}  ${PURPLE}●${RESET}   ${CYAN}╱${RESET}"
    echo "                    ${CYAN}╲${RESET}    ${CYAN}╱${RESET}"
    echo "                     ${CYAN}╲${RESET}  ${CYAN}╱${RESET}"
    echo "                      ${CYAN}╲╱${RESET}"
    echo ""
    echo "               ${TEXT_MUTED}DNA-Protein Complex${RESET}"
    echo ""

    echo -e "${GREEN}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo -e "  ${TEXT_SECONDARY}[←/→]${RESET} Navigate  ${TEXT_SECONDARY}[Z]${RESET} Zoom  ${TEXT_SECONDARY}[A]${RESET} Analyze  ${TEXT_SECONDARY}[S]${RESET} Search  ${TEXT_SECONDARY}[Q]${RESET} Quit"
    echo ""
}

# Main loop
main() {
    while true; do
        show_dna_visualizer

        read -n1 key

        # Handle escape sequences
        if [[ $key == $'\x1b' ]]; then
            read -rsn2 key
        fi

        case "$key" in
            '[D')  # Left arrow
                SEQUENCE_POSITION=$((SEQUENCE_POSITION - 10))
                [ $SEQUENCE_POSITION -lt 0 ] && SEQUENCE_POSITION=0
                ;;
            '[C')  # Right arrow
                SEQUENCE_POSITION=$((SEQUENCE_POSITION + 10))
                ;;
            'z'|'Z')
                ZOOM_LEVEL=$((ZOOM_LEVEL + 1))
                [ $ZOOM_LEVEL -gt 3 ] && ZOOM_LEVEL=1
                ;;
            'a'|'A')
                echo -e "\n${PURPLE}Running sequence analysis...${RESET}"
                sleep 2
                ;;
            's'|'S')
                echo -e "\n${CYAN}Searching sequence databases...${RESET}"
                sleep 2
                ;;
            'q'|'Q')
                echo -e "\n${CYAN}DNA analysis complete${RESET}\n"
                exit 0
                ;;
        esac
    done
}

# Run
main
