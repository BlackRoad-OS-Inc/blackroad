#!/bin/bash

# BlackRoad OS - Master Dashboard Launcher
# Navigate and launch all 92+ dashboards

source ~/blackroad-dashboards/themes.sh
load_theme

DASHBOARDS_DIR="$HOME/blackroad-dashboards"

# Dashboard categories
declare -a SYSTEM_DASHBOARDS=(
    "system-dashboard.sh:System Monitor:CPU, Memory, Disk"
    "network-monitor.sh:Network Monitor:Traffic, Bandwidth"
    "docker-dashboard.sh:Docker Dashboard:Containers, Images"
    "kubernetes-dashboard.sh:Kubernetes:Pods, Services"
    "ci-cd-pipeline.sh:CI/CD Pipeline:Builds, Deployments"
    "log-aggregator.sh:Log Aggregator:System Logs"
    "security-monitor.sh:Security Monitor:Threats, Firewall"
    "backup-manager.sh:Backup Manager:Snapshots, Recovery"
)

declare -a AI_DASHBOARDS=(
    "neural-network-viz.sh:Neural Network:Layers, Training"
    "ml-model-trainer.sh:ML Model Trainer:Training Progress"
    "ai-inference.sh:AI Inference:Predictions, Latency"
    "brain-computer-interface.sh:Brain-Computer Interface:EEG, Mental State"
    "consciousness-upload.sh:Consciousness Upload:Neural Mapping"
    "matrix-simulation.sh:Matrix Simulation:Reality Code"
)

declare -a BLOCKCHAIN_DASHBOARDS=(
    "blockchain-explorer.sh:Blockchain Explorer:Blocks, Transactions"
    "crypto-wallet.sh:Crypto Wallet:Balance, Transactions"
    "defi-dashboard.sh:DeFi Dashboard:Yield, Liquidity"
    "nft-gallery.sh:NFT Gallery:Collections, Minting"
)

declare -a QUANTUM_DASHBOARDS=(
    "quantum-computer.sh:Quantum Computer:Qubits, Gates"
    "quantum-simulator.sh:Quantum Simulator:States, Circuits"
    "particle-physics.sh:Particle Physics:LHC, Collisions"
    "dark-matter-detector.sh:Dark Matter:WIMP Detection"
    "antimatter-containment.sh:Antimatter:Magnetic Bottle"
)

declare -a SPACE_DASHBOARDS=(
    "space-station.sh:Space Station:ISS Monitor"
    "satellite-tracker.sh:Satellite Tracker:Orbital Tracking"
    "rocket-launch.sh:Rocket Launch:Mission Control"
    "mars-rover.sh:Mars Rover:Telemetry, Camera"
    "solar-system.sh:Solar System:Planet Explorer"
    "galaxy-viewer.sh:Galaxy Viewer:Milky Way, Clusters"
    "black-hole-simulator.sh:Black Hole:Event Horizon"
    "wormhole-navigator.sh:Wormhole:Spacetime Travel"
    "dyson-sphere.sh:Dyson Sphere:Stellar Megastructure"
)

declare -a EARTH_DASHBOARDS=(
    "weather-climate.sh:Weather & Climate:Forecast, Radar"
    "ocean-currents.sh:Ocean Currents:Gulf Stream"
    "seismic-monitor.sh:Seismic Monitor:Earthquakes"
    "volcano-tracker.sh:Volcano Tracker:Eruptions"
)

declare -a BIOTECH_DASHBOARDS=(
    "dna-visualizer.sh:DNA Visualizer:Genome, CRISPR"
    "genetic-engineering.sh:Genetic Engineering:Gene Editing"
    "nanobot-swarm.sh:Nanobot Swarm:Medical Nanobots"
    "cryogenic-stasis.sh:Cryogenic Stasis:Suspended Animation"
)

declare -a ENERGY_DASHBOARDS=(
    "nuclear-reactor.sh:Nuclear Reactor:Fission Control"
    "fusion-reactor.sh:Fusion Reactor:Plasma Confinement"
    "renewable-energy.sh:Renewable Energy:Solar, Wind"
    "power-grid.sh:Power Grid:Distribution, Load"
)

declare -a METAVERSE_DASHBOARDS=(
    "ar-overlay.sh:AR Overlay:Augmented Reality"
    "holographic-display.sh:Holographic Display:3D Holograms"
    "multiverse-dashboard.sh:Multiverse:Parallel Universes"
    "time-machine.sh:Time Machine:Historical Timeline"
)

declare -a REALITY_DASHBOARDS=(
    "reality-debugger.sh:Reality Debugger:Universe Stack Trace"
    "probability-manipulator.sh:Probability:Quantum Luck"
    "time-loop-detector.sh:Time Loop:Loop Detection"
    "reality-switcher.sh:Reality Switcher:Parallel Realities"
    "singularity-countdown.sh:Singularity:AI Takeover Timer"
    "universe-reset.sh:Universe Reset:Big Bang Button"
)

declare -a CORPORATE_DASHBOARDS=(
    "corporate-agents.sh:Corporate Agents:AI Executive Team"
)

declare -a MISC_DASHBOARDS=(
    "cosmic-ray-detector.sh:Cosmic Rays:Particle Detection"
    "terraforming.sh:Terraforming:Mars Transformation"
)

CURRENT_CATEGORY="system"
CURRENT_INDEX=0

# Get category dashboards
get_category_dashboards() {
    local category=$1
    case $category in
        system)     echo "${SYSTEM_DASHBOARDS[@]}" ;;
        ai)         echo "${AI_DASHBOARDS[@]}" ;;
        blockchain) echo "${BLOCKCHAIN_DASHBOARDS[@]}" ;;
        quantum)    echo "${QUANTUM_DASHBOARDS[@]}" ;;
        space)      echo "${SPACE_DASHBOARDS[@]}" ;;
        earth)      echo "${EARTH_DASHBOARDS[@]}" ;;
        biotech)    echo "${BIOTECH_DASHBOARDS[@]}" ;;
        energy)     echo "${ENERGY_DASHBOARDS[@]}" ;;
        metaverse)  echo "${METAVERSE_DASHBOARDS[@]}" ;;
        reality)    echo "${REALITY_DASHBOARDS[@]}" ;;
        corporate)  echo "${CORPORATE_DASHBOARDS[@]}" ;;
        misc)       echo "${MISC_DASHBOARDS[@]}" ;;
    esac
}

# Count dashboards
count_all_dashboards() {
    local total=0
    total=$((${#SYSTEM_DASHBOARDS[@]} + ${#AI_DASHBOARDS[@]} + ${#BLOCKCHAIN_DASHBOARDS[@]} +
             ${#QUANTUM_DASHBOARDS[@]} + ${#SPACE_DASHBOARDS[@]} + ${#EARTH_DASHBOARDS[@]} +
             ${#BIOTECH_DASHBOARDS[@]} + ${#ENERGY_DASHBOARDS[@]} + ${#METAVERSE_DASHBOARDS[@]} +
             ${#REALITY_DASHBOARDS[@]} + ${#CORPORATE_DASHBOARDS[@]} + ${#MISC_DASHBOARDS[@]}))
    echo $total
}

# Show launcher
show_launcher() {
    clear
    echo ""
    echo -e "${BOLD}${CYAN}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${CYAN}║${RESET}  ${PURPLE}🚀${RESET} ${BOLD}BLACKROAD DASHBOARD LAUNCHER${RESET}                                    ${BOLD}${CYAN}║${RESET}"
    echo -e "${BOLD}${CYAN}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""

    # Stats
    local total=$(count_all_dashboards)
    echo -e "  ${BOLD}${TEXT_PRIMARY}Total Dashboards:${RESET}    ${GOLD}$total${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Categories:${RESET}          ${CYAN}12${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Status:${RESET}              ${GREEN}✓ All Available${RESET}"
    echo ""

    # Categories
    echo -e "${TEXT_MUTED}╭─ CATEGORIES ──────────────────────────────────────────────────────────╮${RESET}"
    echo ""

    local categories=(
        "system:🖥️  System & Infrastructure:${#SYSTEM_DASHBOARDS[@]}"
        "ai:🧠 AI & Machine Learning:${#AI_DASHBOARDS[@]}"
        "blockchain:⛓️  Blockchain & Crypto:${#BLOCKCHAIN_DASHBOARDS[@]}"
        "quantum:⚛️  Quantum & Physics:${#QUANTUM_DASHBOARDS[@]}"
        "space:🚀 Space & Astronomy:${#SPACE_DASHBOARDS[@]}"
        "earth:🌍 Earth & Environment:${#EARTH_DASHBOARDS[@]}"
        "biotech:🧬 Biotech & Nanotech:${#BIOTECH_DASHBOARDS[@]}"
        "energy:⚡ Energy Systems:${#ENERGY_DASHBOARDS[@]}"
        "metaverse:🌌 Metaverse & AR/VR:${#METAVERSE_DASHBOARDS[@]}"
        "reality:🎭 Reality Hacking:${#REALITY_DASHBOARDS[@]}"
        "corporate:🏢 Corporate Automation:${#CORPORATE_DASHBOARDS[@]}"
        "misc:🔮 Miscellaneous:${#MISC_DASHBOARDS[@]}"
    )

    for cat in "${categories[@]}"; do
        IFS=':' read -r key label count <<< "$cat"

        if [ "$key" = "$CURRENT_CATEGORY" ]; then
            echo -e "  ${BOLD}${CYAN}▶${RESET} ${BOLD}$label${RESET} ${TEXT_MUTED}($count)${RESET}"
        else
            echo -e "    $label ${TEXT_MUTED}($count)${RESET}"
        fi
    done
    echo ""

    # Current category dashboards
    echo -e "${TEXT_MUTED}╭─ DASHBOARDS ──────────────────────────────────────────────────────────╮${RESET}"
    echo ""

    local dashboards=($(get_category_dashboards "$CURRENT_CATEGORY"))
    local index=0

    for dash in "${dashboards[@]}"; do
        IFS=':' read -r file name desc <<< "$dash"

        local status="${TEXT_MUTED}○${RESET}"
        if [ -f "$DASHBOARDS_DIR/$file" ]; then
            status="${GREEN}✓${RESET}"
        fi

        if [ $index -eq $CURRENT_INDEX ]; then
            echo -e "  ${BOLD}${CYAN}▶${RESET} $status ${BOLD}$name${RESET}"
            echo -e "    ${TEXT_MUTED}$desc${RESET}"
        else
            echo -e "    $status $name ${TEXT_MUTED}- $desc${RESET}"
        fi

        ((index++))
    done
    echo ""

    # Instructions
    echo -e "${CYAN}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo -e "  ${TEXT_SECONDARY}[←→]${RESET} Category  ${TEXT_SECONDARY}[↑↓]${RESET} Dashboard  ${TEXT_SECONDARY}[Enter]${RESET} Launch  ${TEXT_SECONDARY}[L]${RESET} List All  ${TEXT_SECONDARY}[Q]${RESET} Quit"
    echo ""
}

# Launch dashboard
launch_dashboard() {
    local dashboards=($(get_category_dashboards "$CURRENT_CATEGORY"))
    local dash="${dashboards[$CURRENT_INDEX]}"
    IFS=':' read -r file name desc <<< "$dash"

    local full_path="$DASHBOARDS_DIR/$file"

    if [ -f "$full_path" ] && [ -x "$full_path" ]; then
        clear
        echo -e "${CYAN}Launching: $name${RESET}\n"
        "$full_path"
    else
        echo -e "\n${RED}Error: Dashboard not found or not executable${RESET}"
        echo -e "${TEXT_MUTED}Path: $full_path${RESET}"
        sleep 2
    fi
}

# List all dashboards
list_all_dashboards() {
    clear
    echo ""
    echo -e "${BOLD}${PURPLE}All Available Dashboards ($(count_all_dashboards))${RESET}"
    echo ""

    local categories=(
        "System & Infrastructure:system"
        "AI & Machine Learning:ai"
        "Blockchain & Crypto:blockchain"
        "Quantum & Physics:quantum"
        "Space & Astronomy:space"
        "Earth & Environment:earth"
        "Biotech & Nanotech:biotech"
        "Energy Systems:energy"
        "Metaverse & AR/VR:metaverse"
        "Reality Hacking:reality"
        "Corporate Automation:corporate"
        "Miscellaneous:misc"
    )

    for cat in "${categories[@]}"; do
        IFS=':' read -r label key <<< "$cat"
        echo -e "${BOLD}${CYAN}$label${RESET}"

        local dashboards=($(get_category_dashboards "$key"))
        for dash in "${dashboards[@]}"; do
            IFS=':' read -r file name desc <<< "$dash"
            echo -e "  ${GREEN}●${RESET} $name ${TEXT_MUTED}- $desc${RESET}"
        done
        echo ""
    done

    echo -e "${TEXT_MUTED}Press any key to continue...${RESET}"
    read -n1
}

# Navigation
navigate_category() {
    local direction=$1
    local categories=(system ai blockchain quantum space earth biotech energy metaverse reality corporate misc)

    for i in "${!categories[@]}"; do
        if [ "${categories[$i]}" = "$CURRENT_CATEGORY" ]; then
            if [ "$direction" = "next" ]; then
                CURRENT_CATEGORY="${categories[$(((i+1) % ${#categories[@]}))]}"
            else
                CURRENT_CATEGORY="${categories[$(((i-1+${#categories[@]}) % ${#categories[@]}))]}"
            fi
            CURRENT_INDEX=0
            break
        fi
    done
}

navigate_dashboard() {
    local direction=$1
    local dashboards=($(get_category_dashboards "$CURRENT_CATEGORY"))
    local max=$((${#dashboards[@]} - 1))

    if [ "$direction" = "next" ]; then
        CURRENT_INDEX=$(((CURRENT_INDEX + 1) % (max + 1)))
    else
        CURRENT_INDEX=$(((CURRENT_INDEX - 1 + max + 1) % (max + 1)))
    fi
}

# Main loop
main() {
    while true; do
        show_launcher

        read -sn1 key

        case "$key" in
            $'\x1b')
                read -sn2 -t 0.1 key
                case "$key" in
                    '[D') navigate_category "prev" ;;  # Left arrow
                    '[C') navigate_category "next" ;;  # Right arrow
                    '[A') navigate_dashboard "prev" ;; # Up arrow
                    '[B') navigate_dashboard "next" ;; # Down arrow
                esac
                ;;
            '')
                launch_dashboard
                ;;
            'l'|'L')
                list_all_dashboards
                ;;
            'q'|'Q')
                clear
                echo -e "\n${CYAN}Dashboard launcher closed${RESET}\n"
                exit 0
                ;;
        esac
    done
}

# Run
main
