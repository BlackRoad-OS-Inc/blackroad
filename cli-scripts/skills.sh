#!/bin/bash

# Colors
PINK='\033[38;5;205m'
AMBER='\033[38;5;214m'
BLUE='\033[38;5;69m'
VIOLET='\033[38;5;135m'
GREEN='\033[38;5;82m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GRAY='\033[2m'
BOLD='\033[1m'
RESET='\033[0m'

show_core_matrix() {
    echo ""
    echo -e "  ${PINK}┌──────────────────────────────────────────────────────────────────────────────┐${RESET}"
    echo -e "  ${PINK}│${RESET}  ${WHITE}BLACKROAD OS · CORE AGENT CAPABILITIES${RESET}                                     ${PINK}│${RESET}"
    echo -e "  ${PINK}├──────────────────────────────────────────────────────────────────────────────┤${RESET}"
    echo -e "  ${PINK}│${RESET}                                                                              ${PINK}│${RESET}"
    echo -e "  ${PINK}│${RESET}             ${GRAY}REASON  ROUTE  COMPUTE  ANALYZE  MEMORY  SECURITY${RESET}         ${PINK}│${RESET}"
    echo -e "  ${PINK}│${RESET}                                                                              ${PINK}│${RESET}"
    echo -e "  ${PINK}│${RESET}  ${AMBER}LUCIDIA${RESET}    ${GREEN}█████${RESET}   ███     ███      ████    ███     ███          ${PINK}│${RESET}"
    echo -e "  ${PINK}│${RESET}  ${CYAN}ALICE${RESET}      ███    ${GREEN}█████${RESET}   ███      ███     ███     ████         ${PINK}│${RESET}"
    echo -e "  ${PINK}│${RESET}  ${GREEN}OCTAVIA${RESET}    ███    ███     ${GREEN}█████${RESET}    ███     ██      ███          ${PINK}│${RESET}"
    echo -e "  ${PINK}│${RESET}  ${AMBER}PRISM${RESET}      ████   ███     ███      ${GREEN}█████${RESET}   ████    ███          ${PINK}│${RESET}"
    echo -e "  ${PINK}│${RESET}  ${VIOLET}ECHO${RESET}       ███    ██      ██       ████    ${GREEN}█████${RESET}   ██           ${PINK}│${RESET}"
    echo -e "  ${PINK}│${RESET}  ${BLUE}CIPHER${RESET}     ███    ████    ███      ███     ███     ${GREEN}█████${RESET}        ${PINK}│${RESET}"
    echo -e "  ${PINK}│${RESET}                                                                              ${PINK}│${RESET}"
    echo -e "  ${PINK}├──────────────────────────────────────────────────────────────────────────────┤${RESET}"
    echo -e "  ${PINK}│${RESET}  ${GRAY}█████ = Primary   ████ = Strong   ███ = Capable   ██ = Basic${RESET}            ${PINK}│${RESET}"
    echo -e "  ${PINK}└──────────────────────────────────────────────────────────────────────────────┘${RESET}"
}

show_extended_matrix() {
    echo ""
    echo -e "  ${VIOLET}┌──────────────────────────────────────────────────────────────────────────────┐${RESET}"
    echo -e "  ${VIOLET}│${RESET}  ${WHITE}BLACKROAD OS · EXTENDED SKILL DOMAINS${RESET}                                      ${VIOLET}│${RESET}"
    echo -e "  ${VIOLET}├──────────────────────────────────────────────────────────────────────────────┤${RESET}"
    echo -e "  ${VIOLET}│${RESET}                                                                              ${VIOLET}│${RESET}"
    echo -e "  ${VIOLET}│${RESET}  ${BOLD}${AMBER}AI/ML SKILLS${RESET}                                                              ${VIOLET}│${RESET}"
    echo -e "  ${VIOLET}│${RESET}  ├─ ${CYAN}inference${RESET}     vLLM, Ollama, RAG, embeddings, chunking          ${VIOLET}│${RESET}"
    echo -e "  ${VIOLET}│${RESET}  ├─ ${CYAN}nlp${RESET}           transformers, sentiment, NER, classification       ${VIOLET}│${RESET}"
    echo -e "  ${VIOLET}│${RESET}  ├─ ${CYAN}vision${RESET}        YOLO, OpenCV, diffusion, detection                  ${VIOLET}│${RESET}"
    echo -e "  ${VIOLET}│${RESET}  ├─ ${CYAN}vector_db${RESET}     Qdrant, Weaviate, Chroma, Milvus, pgvector          ${VIOLET}│${RESET}"
    echo -e "  ${VIOLET}│${RESET}  └─ ${CYAN}agents${RESET}        multi-agent, orchestration, coordination            ${VIOLET}│${RESET}"
    echo -e "  ${VIOLET}│${RESET}                                                                              ${VIOLET}│${RESET}"
    echo -e "  ${VIOLET}│${RESET}  ${BOLD}${BLUE}DEVOPS SKILLS${RESET}                                                             ${VIOLET}│${RESET}"
    echo -e "  ${VIOLET}│${RESET}  ├─ ${CYAN}containers${RESET}    Docker, K8s, Helm, ArgoCD                           ${VIOLET}│${RESET}"
    echo -e "  ${VIOLET}│${RESET}  ├─ ${CYAN}cloud${RESET}         AWS, GCP, Cloudflare, Vercel, Railway               ${VIOLET}│${RESET}"
    echo -e "  ${VIOLET}│${RESET}  ├─ ${CYAN}iac${RESET}           Terraform, Pulumi, Ansible                          ${VIOLET}│${RESET}"
    echo -e "  ${VIOLET}│${RESET}  ├─ ${CYAN}monitoring${RESET}    Grafana, Prometheus, Datadog, Sentry                ${VIOLET}│${RESET}"
    echo -e "  ${VIOLET}│${RESET}  └─ ${CYAN}networking${RESET}    DNS, CDN, Tailscale, Traefik                        ${VIOLET}│${RESET}"
    echo -e "  ${VIOLET}│${RESET}                                                                              ${VIOLET}│${RESET}"
    echo -e "  ${VIOLET}│${RESET}  ${BOLD}${GREEN}DATA SKILLS${RESET}                                                               ${VIOLET}│${RESET}"
    echo -e "  ${VIOLET}│${RESET}  ├─ ${CYAN}databases${RESET}     PostgreSQL, Redis, MongoDB, SQLite                  ${VIOLET}│${RESET}"
    echo -e "  ${VIOLET}│${RESET}  ├─ ${CYAN}etl${RESET}           Airflow, Dagster, Spark, dbt                        ${VIOLET}│${RESET}"
    echo -e "  ${VIOLET}│${RESET}  ├─ ${CYAN}analytics${RESET}     dashboards, BI, metrics, Superset                   ${VIOLET}│${RESET}"
    echo -e "  ${VIOLET}│${RESET}  ├─ ${CYAN}timeseries${RESET}    InfluxDB, forecasting, anomaly detection            ${VIOLET}│${RESET}"
    echo -e "  ${VIOLET}│${RESET}  └─ ${CYAN}search${RESET}        Elasticsearch, Meilisearch, full-text               ${VIOLET}│${RESET}"
    echo -e "  ${VIOLET}│${RESET}                                                                              ${VIOLET}│${RESET}"
    echo -e "  ${VIOLET}│${RESET}  ${BOLD}${PINK}SECURITY SKILLS${RESET}                                                           ${VIOLET}│${RESET}"
    echo -e "  ${VIOLET}│${RESET}  ├─ ${CYAN}crypto${RESET}        hashing, JWT, encryption, TLS, HMAC                 ${VIOLET}│${RESET}"
    echo -e "  ${VIOLET}│${RESET}  ├─ ${CYAN}auth${RESET}          OAuth, SSO, RBAC, session management                ${VIOLET}│${RESET}"
    echo -e "  ${VIOLET}│${RESET}  ├─ ${CYAN}scanning${RESET}      SAST, secret detection, vulnerability analysis      ${VIOLET}│${RESET}"
    echo -e "  ${VIOLET}│${RESET}  └─ ${CYAN}compliance${RESET}    GDPR, SOC2, HIPAA, audit                            ${VIOLET}│${RESET}"
    echo -e "  ${VIOLET}│${RESET}                                                                              ${VIOLET}│${RESET}"
    echo -e "  ${VIOLET}└──────────────────────────────────────────────────────────────────────────────┘${RESET}"
}

show_skill_counts() {
    echo ""
    echo -e "  ${AMBER}┌──────────────────────────────────────────────────────────────────────────────┐${RESET}"
    echo -e "  ${AMBER}│${RESET}  ${WHITE}BLACKROAD OS · SKILL INVENTORY${RESET}                                             ${AMBER}│${RESET}"
    echo -e "  ${AMBER}├──────────────────────────────────────────────────────────────────────────────┤${RESET}"
    echo -e "  ${AMBER}│${RESET}                                                                              ${AMBER}│${RESET}"
    echo -e "  ${AMBER}│${RESET}  ${BOLD}Python Skills${RESET} (bots/skills/)                                              ${AMBER}│${RESET}"
    echo -e "  ${AMBER}│${RESET}  ├─ ${GREEN}ai_skill.py${RESET}       embeddings, RAG, chunking, similarity          ${AMBER}│${RESET}"
    echo -e "  ${AMBER}│${RESET}  ├─ ${GREEN}devops_skill.py${RESET}   Docker, K8s, deployment, metrics               ${AMBER}│${RESET}"
    echo -e "  ${AMBER}│${RESET}  ├─ ${GREEN}data_skill.py${RESET}     ETL, statistics, time series, analytics        ${AMBER}│${RESET}"
    echo -e "  ${AMBER}│${RESET}  ├─ ${GREEN}security_skill.py${RESET} encryption, auth, vulnerability scanning       ${AMBER}│${RESET}"
    echo -e "  ${AMBER}│${RESET}  ├─ ${GREEN}math_skill.py${RESET}     primes, norms, FFT                             ${AMBER}│${RESET}"
    echo -e "  ${AMBER}│${RESET}  ├─ ${GREEN}quantum_skill.py${RESET}  Bell pairs, QFT                                ${AMBER}│${RESET}"
    echo -e "  ${AMBER}│${RESET}  └─ ${GREEN}viz_skill.py${RESET}      charts, histograms                             ${AMBER}│${RESET}"
    echo -e "  ${AMBER}│${RESET}                                                                              ${AMBER}│${RESET}"
    echo -e "  ${AMBER}│${RESET}  ${BOLD}TypeScript SDK${RESET} (@blackroad/skills-sdk)                                    ${AMBER}│${RESET}"
    echo -e "  ${AMBER}│${RESET}  ├─ ${BLUE}memory.ts${RESET}         PS-SHA∞ persistence, facts, observations       ${AMBER}│${RESET}"
    echo -e "  ${AMBER}│${RESET}  ├─ ${BLUE}reasoning.ts${RESET}      trinary logic, claims, contradictions          ${AMBER}│${RESET}"
    echo -e "  ${AMBER}│${RESET}  ├─ ${BLUE}coordination.ts${RESET}   events, tasks, delegation                      ${AMBER}│${RESET}"
    echo -e "  ${AMBER}│${RESET}  ├─ ${BLUE}ai.ts${RESET}             embeddings, RAG, classification, NER           ${AMBER}│${RESET}"
    echo -e "  ${AMBER}│${RESET}  ├─ ${BLUE}infrastructure.ts${RESET} health, deploy, scale, logs                    ${AMBER}│${RESET}"
    echo -e "  ${AMBER}│${RESET}  ├─ ${BLUE}data.ts${RESET}           SQL, aggregation, timeseries, anomalies        ${AMBER}│${RESET}"
    echo -e "  ${AMBER}│${RESET}  └─ ${BLUE}security.ts${RESET}       hash, JWT, secrets, vulnerabilities            ${AMBER}│${RESET}"
    echo -e "  ${AMBER}│${RESET}                                                                              ${AMBER}│${RESET}"
    echo -e "  ${AMBER}│${RESET}  ${BOLD}Skill Taxonomy${RESET} (30 categories across 10 domains)                         ${AMBER}│${RESET}"
    echo -e "  ${AMBER}│${RESET}  ├─ ${VIOLET}AI${RESET}              ml, inference, nlp, vision, vector_db, agents   ${AMBER}│${RESET}"
    echo -e "  ${AMBER}│${RESET}  ├─ ${VIOLET}Development${RESET}     backend, frontend, mobile, cli, realtime        ${AMBER}│${RESET}"
    echo -e "  ${AMBER}│${RESET}  ├─ ${VIOLET}Infrastructure${RESET}  devops, cloud, monitoring, networking           ${AMBER}│${RESET}"
    echo -e "  ${AMBER}│${RESET}  ├─ ${VIOLET}Data${RESET}            database, data_engineering, analytics, search   ${AMBER}│${RESET}"
    echo -e "  ${AMBER}│${RESET}  ├─ ${VIOLET}Security${RESET}        security, crypto, compliance                    ${AMBER}│${RESET}"
    echo -e "  ${AMBER}│${RESET}  └─ ${VIOLET}Other${RESET}           blockchain, iot, workflow, integration          ${AMBER}│${RESET}"
    echo -e "  ${AMBER}│${RESET}                                                                              ${AMBER}│${RESET}"
    echo -e "  ${AMBER}└──────────────────────────────────────────────────────────────────────────────┘${RESET}"
}

show_help() {
    echo ""
    echo -e "  ${WHITE}Usage:${RESET} ./skills.sh [command]"
    echo ""
    echo -e "  ${CYAN}Commands:${RESET}"
    echo "    core      Show core agent capabilities matrix"
    echo "    extended  Show extended skill domains"
    echo "    inventory Show full skill inventory"
    echo "    all       Show all skill information"
    echo "    help      Show this help message"
    echo ""
}

case "${1:-all}" in
    core)
        show_core_matrix
        ;;
    extended)
        show_extended_matrix
        ;;
    inventory)
        show_skill_counts
        ;;
    all)
        show_core_matrix
        show_extended_matrix
        show_skill_counts
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        show_core_matrix
        show_extended_matrix
        show_skill_counts
        ;;
esac

echo ""
