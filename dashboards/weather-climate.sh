#!/bin/bash

# BlackRoad OS - Weather & Climate Simulator
# Real-time weather patterns and climate modeling

source ~/blackroad-dashboards/themes.sh
load_theme

TEMPERATURE=72
HUMIDITY=65
PRESSURE=1013
WIND_SPEED=12
PRECIPITATION=0

# Weather conditions
CURRENT_CONDITION="Partly Cloudy"

# Show weather dashboard
show_weather_dashboard() {
    clear
    echo ""
    echo -e "${BOLD}${CYAN}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${CYAN}║${RESET}  ${BLUE}🌤${RESET}  ${BOLD}WEATHER & CLIMATE SIMULATOR${RESET}                                     ${BOLD}${CYAN}║${RESET}"
    echo -e "${BOLD}${CYAN}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""

    # Current conditions
    echo -e "${TEXT_MUTED}╭─ CURRENT CONDITIONS ──────────────────────────────────────────────────╮${RESET}"
    echo ""

    # Weather icon
    echo "                          ${CYAN}    ___${RESET}"
    echo "                       ${CYAN}___(     )___${RESET}"
    echo "                    ${CYAN}__(            )__${RESET}"
    echo "                   ${CYAN}(                  )${RESET}"
    echo "                    ${CYAN}──(            )──${RESET}"
    echo "                       ${CYAN}───(_______)───${RESET}"
    echo ""

    echo -e "  ${BOLD}${TEXT_PRIMARY}Condition:${RESET}           ${BOLD}${CYAN}$CURRENT_CONDITION${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Temperature:${RESET}         ${BOLD}${ORANGE}${TEMPERATURE}°F${RESET} ${TEXT_MUTED}(22°C)${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Humidity:${RESET}            ${BOLD}${BLUE}${HUMIDITY}%${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Pressure:${RESET}            ${BOLD}${PURPLE}${PRESSURE} mb${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Wind:${RESET}                ${BOLD}${GREEN}${WIND_SPEED} mph${RESET} ${TEXT_MUTED}NE${RESET}"
    echo ""

    # 7-day forecast
    echo -e "${TEXT_MUTED}╭─ 7-DAY FORECAST ──────────────────────────────────────────────────────╮${RESET}"
    echo ""

    local days=("Mon" "Tue" "Wed" "Thu" "Fri" "Sat" "Sun")
    local icons=("☀️" "🌤" "⛅" "🌧" "⛈" "🌤" "☀️")
    local highs=(75 78 72 68 71 74 76)
    local lows=(58 61 55 52 54 57 59)

    for i in {0..6}; do
        echo -e "  ${BOLD}${days[$i]}${RESET}  ${icons[$i]}   ${ORANGE}${highs[$i]}°${RESET} / ${CYAN}${lows[$i]}°${RESET}"
    done
    echo ""

    # Hourly forecast
    echo -e "${TEXT_MUTED}╭─ HOURLY FORECAST ─────────────────────────────────────────────────────╮${RESET}"
    echo ""

    echo -n "  ${TEXT_MUTED}Temp${RESET}  "
    for ((i=0; i<24; i++)); do
        local temp=$((70 + RANDOM % 10))
        if [ $temp -gt 75 ]; then
            echo -n "${ORANGE}▄${RESET}"
        elif [ $temp -gt 70 ]; then
            echo -n "${YELLOW}▄${RESET}"
        else
            echo -n "${CYAN}▄${RESET}"
        fi
    done
    echo ""

    echo -n "  ${TEXT_MUTED}Rain${RESET}  "
    for ((i=0; i<24; i++)); do
        local chance=$((RANDOM % 100))
        if [ $chance -lt 20 ]; then
            echo -n "${BLUE}█${RESET}"
        else
            echo -n "${TEXT_MUTED}░${RESET}"
        fi
    done
    echo ""

    echo "        ${TEXT_MUTED}12a  3a  6a  9a  12p  3p  6p  9p  12a${RESET}"
    echo ""

    # Weather map
    echo -e "${TEXT_MUTED}╭─ WEATHER MAP ─────────────────────────────────────────────────────────╮${RESET}"
    echo ""

    # ASCII weather map
    echo "                    ${TEXT_MUTED}╔════════════════════════╗${RESET}"
    echo "                    ${TEXT_MUTED}║${RESET}  ${CYAN}☁${RESET}      ${ORANGE}H${RESET}         ${TEXT_MUTED}║${RESET}"
    echo "                    ${TEXT_MUTED}║${RESET}     ${BLUE}☂${RESET}             ${TEXT_MUTED}║${RESET}"
    echo "                    ${TEXT_MUTED}║${RESET}           ${GREEN}●${RESET}      ${TEXT_MUTED}║${RESET}  ${TEXT_MUTED}You${RESET}"
    echo "                    ${TEXT_MUTED}║${RESET}  ${PURPLE}L${RESET}        ${CYAN}☁${RESET}    ${TEXT_MUTED}║${RESET}"
    echo "                    ${TEXT_MUTED}║${RESET}     ${BLUE}☂${RESET}  ${BLUE}☂${RESET}         ${TEXT_MUTED}║${RESET}"
    echo "                    ${TEXT_MUTED}╚════════════════════════╝${RESET}"
    echo ""
    echo "         ${ORANGE}H${RESET} High Pressure  ${PURPLE}L${RESET} Low Pressure  ${BLUE}☂${RESET} Rain  ${CYAN}☁${RESET} Clouds"
    echo ""

    # Radar
    echo -e "${TEXT_MUTED}╭─ PRECIPITATION RADAR ─────────────────────────────────────────────────╮${RESET}"
    echo ""

    for ((i=0; i<8; i++)); do
        echo -n "  "
        for ((j=0; j<50; j++)); do
            local intensity=$((RANDOM % 100))
            if [ $intensity -gt 90 ]; then
                echo -n "${RED}█${RESET}"
            elif [ $intensity -gt 70 ]; then
                echo -n "${ORANGE}▓${RESET}"
            elif [ $intensity -gt 50 ]; then
                echo -n "${YELLOW}▒${RESET}"
            elif [ $intensity -gt 30 ]; then
                echo -n "${GREEN}░${RESET}"
            else
                echo -n " "
            fi
        done
        echo ""
    done
    echo ""
    echo "  ${GREEN}Light${RESET}  ${YELLOW}Moderate${RESET}  ${ORANGE}Heavy${RESET}  ${RED}Severe${RESET}"
    echo ""

    # Climate data
    echo -e "${TEXT_MUTED}╭─ CLIMATE ANALYSIS ────────────────────────────────────────────────────╮${RESET}"
    echo ""

    echo -e "  ${BOLD}${TEXT_PRIMARY}Average Temp (Year):${RESET}  ${ORANGE}68.4°F${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Total Precipitation:${RESET}  ${BLUE}42.3 inches${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Sunny Days:${RESET}           ${YELLOW}247${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Climate Zone:${RESET}         ${GREEN}Temperate${RESET}"
    echo ""

    # Temperature trend (30 days)
    echo -e "${TEXT_MUTED}╭─ TEMPERATURE TREND (30 DAYS) ─────────────────────────────────────────╮${RESET}"
    echo ""

    echo "  ${TEXT_MUTED}°F${RESET}"
    echo "  ${TEXT_MUTED}90${RESET} ${RED}│${RESET}"
    echo "  ${TEXT_MUTED}80${RESET} ${ORANGE}│${RESET}        ${ORANGE}▄▄${RESET}"
    echo "  ${TEXT_MUTED}70${RESET} ${YELLOW}│${RESET}   ${YELLOW}▄▄▄${RESET}${ORANGE}█${RESET}${ORANGE}█${RESET}${YELLOW}█${RESET}  ${YELLOW}▄${RESET}"
    echo "  ${TEXT_MUTED}60${RESET} ${GREEN}│${RESET}${GREEN}▄▄${RESET}${YELLOW}█${RESET}${YELLOW}█${RESET}   ${YELLOW}█${RESET}${YELLOW}█${RESET}${GREEN}▄${RESET}${GREEN}██${RESET}"
    echo "  ${TEXT_MUTED}50${RESET} ${CYAN}│${RESET}${GREEN}█${RESET}${GREEN}█${RESET}       ${GREEN}█${RESET}"
    echo "  ${TEXT_MUTED}40${RESET} ${TEXT_MUTED}└─────────────────────────────────────────────→${RESET}"
    echo "      ${TEXT_MUTED}1w   2w   3w   4w   Now${RESET}"
    echo ""

    # Alerts
    echo -e "${TEXT_MUTED}╭─ WEATHER ALERTS ──────────────────────────────────────────────────────╮${RESET}"
    echo ""

    echo -e "  ${ORANGE}⚠${RESET}  ${BOLD}Wind Advisory${RESET}         ${TEXT_MUTED}Today 2pm - 8pm${RESET}"
    echo -e "  ${YELLOW}⚠${RESET}  ${BOLD}UV Index High${RESET}         ${TEXT_MUTED}Peak at 1pm${RESET}"
    echo ""

    # Atmospheric conditions
    echo -e "${TEXT_MUTED}╭─ ATMOSPHERIC CONDITIONS ──────────────────────────────────────────────╮${RESET}"
    echo ""

    echo -e "  ${BOLD}${TEXT_PRIMARY}Visibility:${RESET}          ${GREEN}10 miles${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}UV Index:${RESET}            ${ORANGE}8${RESET} ${TEXT_MUTED}(Very High)${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Dew Point:${RESET}           ${CYAN}58°F${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Cloud Cover:${RESET}         ${PURPLE}45%${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Air Quality:${RESET}         ${GREEN}Good${RESET} ${TEXT_MUTED}(AQI: 42)${RESET}"
    echo ""

    # Sun & Moon
    echo -e "${TEXT_MUTED}╭─ SUN & MOON ──────────────────────────────────────────────────────────╮${RESET}"
    echo ""

    echo -e "  ${YELLOW}☀${RESET}  ${BOLD}Sunrise:${RESET}  ${ORANGE}6:42 AM${RESET}     ${BOLD}Sunset:${RESET}   ${PURPLE}7:34 PM${RESET}"
    echo -e "  ${BLUE}🌙${RESET} ${BOLD}Moonrise:${RESET} ${CYAN}8:12 PM${RESET}     ${BOLD}Phase:${RESET}    ${TEXT_MUTED}Waxing Gibbous${RESET}"
    echo ""

    # Global weather
    echo -e "${TEXT_MUTED}╭─ GLOBAL WEATHER ──────────────────────────────────────────────────────╮${RESET}"
    echo ""

    echo -e "  ${BOLD}New York${RESET}     ${ORANGE}☀${RESET}  ${ORANGE}68°${RESET} / ${CYAN}52°${RESET}     ${BOLD}London${RESET}      ${BLUE}🌧${RESET}  ${ORANGE}61°${RESET} / ${CYAN}48°${RESET}"
    echo -e "  ${BOLD}Tokyo${RESET}        ${CYAN}⛅${RESET} ${ORANGE}71°${RESET} / ${CYAN}58°${RESET}     ${BOLD}Sydney${RESET}      ${YELLOW}☀${RESET}  ${ORANGE}82°${RESET} / ${CYAN}67°${RESET}"
    echo -e "  ${BOLD}Paris${RESET}        ${PURPLE}⛈${RESET}  ${ORANGE}64°${RESET} / ${CYAN}49°${RESET}     ${BOLD}Dubai${RESET}       ${YELLOW}☀${RESET}  ${RED}95°${RESET} / ${ORANGE}78°${RESET}"
    echo ""

    echo -e "${CYAN}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo -e "  ${TEXT_SECONDARY}[R]${RESET} Refresh  ${TEXT_SECONDARY}[M]${RESET} Map  ${TEXT_SECONDARY}[A]${RESET} Alerts  ${TEXT_SECONDARY}[C]${RESET} Climate  ${TEXT_SECONDARY}[Q]${RESET} Quit"
    echo ""
}

# Main loop
main() {
    while true; do
        show_weather_dashboard

        # Update values
        TEMPERATURE=$((TEMPERATURE + (RANDOM % 3 - 1)))
        HUMIDITY=$((HUMIDITY + (RANDOM % 5 - 2)))
        WIND_SPEED=$((WIND_SPEED + (RANDOM % 3 - 1)))

        read -t 2 -n1 key

        case "$key" in
            'r'|'R')
                # Refresh
                ;;
            'm'|'M')
                echo -e "\n${CYAN}Loading detailed weather map...${RESET}"
                sleep 1
                ;;
            'a'|'A')
                echo -e "\n${ORANGE}Checking weather alerts...${RESET}"
                sleep 1
                ;;
            'c'|'C')
                echo -e "\n${PURPLE}Loading climate data...${RESET}"
                sleep 1
                ;;
            'q'|'Q')
                echo -e "\n${CYAN}Weather monitoring ended${RESET}\n"
                exit 0
                ;;
        esac
    done
}

# Run
main
