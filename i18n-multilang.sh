#!/bin/bash

# BlackRoad OS - Multi-Language Support (i18n)
# Support 10+ languages

source ~/blackroad-dashboards/themes.sh
load_theme

LANG_FILE=~/blackroad-dashboards/.language
CURRENT_LANG=${1:-en}

# Load or set default language
if [ -f "$LANG_FILE" ]; then
    CURRENT_LANG=$(cat "$LANG_FILE")
else
    echo "en" > "$LANG_FILE"
fi

# Translation database
declare -A TRANSLATIONS_EN=(
    ["title"]="🌍 MULTI-LANGUAGE DASHBOARD"
    ["welcome"]="Welcome to BlackRoad OS"
    ["status"]="System Status"
    ["online"]="ONLINE"
    ["cpu"]="CPU Usage"
    ["memory"]="Memory"
    ["disk"]="Disk I/O"
    ["containers"]="Containers"
    ["running"]="running"
    ["alerts"]="Active Alerts"
    ["language"]="Language"
    ["settings"]="Settings"
    ["help"]="Help"
    ["quit"]="Quit"
)

declare -A TRANSLATIONS_ES=(
    ["title"]="🌍 PANEL MULTILINGÜE"
    ["welcome"]="Bienvenido a BlackRoad OS"
    ["status"]="Estado del Sistema"
    ["online"]="EN LÍNEA"
    ["cpu"]="Uso de CPU"
    ["memory"]="Memoria"
    ["disk"]="E/S de Disco"
    ["containers"]="Contenedores"
    ["running"]="ejecutando"
    ["alerts"]="Alertas Activas"
    ["language"]="Idioma"
    ["settings"]="Configuración"
    ["help"]="Ayuda"
    ["quit"]="Salir"
)

declare -A TRANSLATIONS_FR=(
    ["title"]="🌍 TABLEAU DE BORD MULTILINGUE"
    ["welcome"]="Bienvenue sur BlackRoad OS"
    ["status"]="État du Système"
    ["online"]="EN LIGNE"
    ["cpu"]="Utilisation CPU"
    ["memory"]="Mémoire"
    ["disk"]="E/S Disque"
    ["containers"]="Conteneurs"
    ["running"]="en cours"
    ["alerts"]="Alertes Actives"
    ["language"]="Langue"
    ["settings"]="Paramètres"
    ["help"]="Aide"
    ["quit"]="Quitter"
)

declare -A TRANSLATIONS_DE=(
    ["title"]="🌍 MEHRSPRACHIGES DASHBOARD"
    ["welcome"]="Willkommen bei BlackRoad OS"
    ["status"]="Systemstatus"
    ["online"]="ONLINE"
    ["cpu"]="CPU-Auslastung"
    ["memory"]="Speicher"
    ["disk"]="Datenträger-E/A"
    ["containers"]="Container"
    ["running"]="läuft"
    ["alerts"]="Aktive Warnungen"
    ["language"]="Sprache"
    ["settings"]="Einstellungen"
    ["help"]="Hilfe"
    ["quit"]="Beenden"
)

declare -A TRANSLATIONS_JA=(
    ["title"]="🌍 多言語ダッシュボード"
    ["welcome"]="BlackRoad OSへようこそ"
    ["status"]="システムステータス"
    ["online"]="オンライン"
    ["cpu"]="CPU使用率"
    ["memory"]="メモリ"
    ["disk"]="ディスクI/O"
    ["containers"]="コンテナ"
    ["running"]="実行中"
    ["alerts"]="アクティブなアラート"
    ["language"]="言語"
    ["settings"]="設定"
    ["help"]="ヘルプ"
    ["quit"]="終了"
)

declare -A TRANSLATIONS_ZH=(
    ["title"]="🌍 多语言仪表板"
    ["welcome"]="欢迎使用 BlackRoad OS"
    ["status"]="系统状态"
    ["online"]="在线"
    ["cpu"]="CPU 使用率"
    ["memory"]="内存"
    ["disk"]="磁盘 I/O"
    ["containers"]="容器"
    ["running"]="运行中"
    ["alerts"]="活动警报"
    ["language"]="语言"
    ["settings"]="设置"
    ["help"]="帮助"
    ["quit"]="退出"
)

declare -A TRANSLATIONS_RU=(
    ["title"]="🌍 МНОГОЯЗЫЧНАЯ ПАНЕЛЬ"
    ["welcome"]="Добро пожаловать в BlackRoad OS"
    ["status"]="Состояние Системы"
    ["online"]="В СЕТИ"
    ["cpu"]="Использование ЦП"
    ["memory"]="Память"
    ["disk"]="Дисковый Ввод/Вывод"
    ["containers"]="Контейнеры"
    ["running"]="работает"
    ["alerts"]="Активные Оповещения"
    ["language"]="Язык"
    ["settings"]="Настройки"
    ["help"]="Помощь"
    ["quit"]="Выход"
)

declare -A TRANSLATIONS_PT=(
    ["title"]="🌍 PAINEL MULTILÍNGUE"
    ["welcome"]="Bem-vindo ao BlackRoad OS"
    ["status"]="Status do Sistema"
    ["online"]="ONLINE"
    ["cpu"]="Uso de CPU"
    ["memory"]="Memória"
    ["disk"]="E/S de Disco"
    ["containers"]="Contêineres"
    ["running"]="executando"
    ["alerts"]="Alertas Ativos"
    ["language"]="Idioma"
    ["settings"]="Configurações"
    ["help"]="Ajuda"
    ["quit"]="Sair"
)

declare -A TRANSLATIONS_AR=(
    ["title"]="🌍 لوحة معلومات متعددة اللغات"
    ["welcome"]="مرحبا بك في BlackRoad OS"
    ["status"]="حالة النظام"
    ["online"]="متصل"
    ["cpu"]="استخدام المعالج"
    ["memory"]="الذاكرة"
    ["disk"]="إدخال/إخراج القرص"
    ["containers"]="الحاويات"
    ["running"]="قيد التشغيل"
    ["alerts"]="التنبيهات النشطة"
    ["language"]="اللغة"
    ["settings"]="الإعدادات"
    ["help"]="مساعدة"
    ["quit"]="خروج"
)

declare -A TRANSLATIONS_HI=(
    ["title"]="🌍 बहुभाषी डैशबोर्ड"
    ["welcome"]="BlackRoad OS में आपका स्वागत है"
    ["status"]="सिस्टम स्थिति"
    ["online"]="ऑनलाइन"
    ["cpu"]="CPU उपयोग"
    ["memory"]="मेमोरी"
    ["disk"]="डिस्क I/O"
    ["containers"]="कंटेनर"
    ["running"]="चल रहा है"
    ["alerts"]="सक्रिय अलर्ट"
    ["language"]="भाषा"
    ["settings"]="सेटिंग्स"
    ["help"]="मदद"
    ["quit"]="बाहर निकलें"
)

# Get translation
t() {
    local key=$1
    local lang_var="TRANSLATIONS_${CURRENT_LANG^^}"

    # Use nameref to access the associative array
    declare -n translations="$lang_var"

    echo "${translations[$key]}"
}

# Language list
declare -A LANGUAGES=(
    ["en"]="English 🇬🇧"
    ["es"]="Español 🇪🇸"
    ["fr"]="Français 🇫🇷"
    ["de"]="Deutsch 🇩🇪"
    ["ja"]="日本語 🇯🇵"
    ["zh"]="中文 🇨🇳"
    ["ru"]="Русский 🇷🇺"
    ["pt"]="Português 🇵🇹"
    ["ar"]="العربية 🇸🇦"
    ["hi"]="हिन्दी 🇮🇳"
)

# Show dashboard in selected language
show_dashboard() {
    clear
    echo ""
    echo -e "${BOLD}${PURPLE}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${PURPLE}║${RESET}  $(t title)                                    ${BOLD}${PURPLE}║${RESET}"
    echo -e "${BOLD}${PURPLE}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""

    # Welcome
    echo -e "${TEXT_MUTED}╭─ $(t welcome) ──────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${BOLD}${TEXT_PRIMARY}$(t status):${RESET}        ${GREEN}${BOLD}$(t online)${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}$(t language):${RESET}        ${CYAN}${LANGUAGES[$CURRENT_LANG]}${RESET}"
    echo ""

    # Metrics
    echo -e "${TEXT_MUTED}╭─ METRICS ─────────────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${ORANGE}$(t cpu)${RESET}      ${ORANGE}████████████${RESET}                    ${BOLD}42%${RESET}"
    echo -e "  ${PINK}$(t memory)${RESET}         ${PINK}████████████████${RESET}                ${BOLD}5.8 GB${RESET}"
    echo -e "  ${PURPLE}$(t disk)${RESET}       ${PURPLE}██████${RESET}                          ${BOLD}847 MB/s${RESET}"
    echo ""

    # Containers
    echo -e "${TEXT_MUTED}╭─ $(t containers) ──────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${BOLD}${TEXT_PRIMARY}Total:${RESET}  ${BOLD}${ORANGE}24${RESET}  ${TEXT_MUTED}(22 $(t running))${RESET}"
    echo ""

    # Available languages
    echo -e "${TEXT_MUTED}╭─ AVAILABLE LANGUAGES ─────────────────────────────────────────────────╮${RESET}"
    echo ""

    local idx=1
    for lang_code in "${!LANGUAGES[@]}"; do
        local lang_name="${LANGUAGES[$lang_code]}"
        local selected=""
        [ "$lang_code" = "$CURRENT_LANG" ] && selected=" ${GREEN}✓${RESET}"

        echo -e "  ${CYAN}${idx})${RESET} ${lang_name}${selected}"
        ((idx++))
    done
    echo ""

    echo -e "${PURPLE}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo -e "  ${TEXT_SECONDARY}[1-9]${RESET} $(t language)  ${TEXT_SECONDARY}[Q]${RESET} $(t quit)"
    echo ""
}

# Change language
change_language() {
    local new_lang=$1
    echo "$new_lang" > "$LANG_FILE"
    CURRENT_LANG=$new_lang

    echo -e "\n${GREEN}✓ $(t language) changed to ${LANGUAGES[$new_lang]}${RESET}"
    sleep 1
}

# Main loop
main() {
    while true; do
        show_dashboard

        read -n1 key

        case "$key" in
            1) change_language "en" ;;
            2) change_language "es" ;;
            3) change_language "fr" ;;
            4) change_language "de" ;;
            5) change_language "ja" ;;
            6) change_language "zh" ;;
            7) change_language "ru" ;;
            8) change_language "pt" ;;
            9) change_language "ar" ;;
            0) change_language "hi" ;;
            'q'|'Q')
                echo -e "\n${CYAN}Goodbye! | ¡Adiós! | Au revoir! | Auf Wiedersehen! | さようなら! | 再见! | До свидания! | Tchau! | مع السلامة! | अलविदा!${RESET}\n"
                exit 0
                ;;
        esac
    done
}

# Run
main
