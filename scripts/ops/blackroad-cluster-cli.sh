#!/bin/bash
# BlackRoad Cluster CLI
# Unified command-line interface for the entire Pi AI cluster
# Agent: Icarus (b3e01bd9)

PINK='\033[38;5;205m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
RESET='\033[0m'
BOLD='\033[1m'

VERSION="1.0.0"
CLUSTER_NAME="BlackRoad Pi Cluster"

# Header
header() {
    echo -e "${PINK}╔══════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${PINK}║   ${BOLD}🖤 BLACKROAD CLUSTER CLI v${VERSION}${RESET}${PINK}                               ║${RESET}"
    echo -e "${PINK}║   4 Pi nodes • 52 TOPS Hailo-8 • 20 LLM models                   ║${RESET}"
    echo -e "${PINK}╚══════════════════════════════════════════════════════════════════╝${RESET}"
    echo
}

# Quick status
quick_status() {
    echo -e "${CYAN}Cluster Status:${RESET}"

    local online=0
    for node in lucidia cecilia octavia aria; do
        if ssh -o ConnectTimeout=1 -o BatchMode=yes "$node" "echo ok" >/dev/null 2>&1; then
            ((online++))
        fi
    done

    local status_color=$GREEN
    [ "$online" -lt 4 ] && status_color=$YELLOW
    [ "$online" -eq 0 ] && status_color=$RED

    echo -e "  Nodes: ${status_color}${online}/4 online${RESET}"
    echo -e "  AI: 52 TOPS (Hailo-8 x2)"
    echo -e "  LLM: ~20 models available"
    echo
}

# Main menu
menu() {
    header
    quick_status

    echo -e "${BOLD}Quick Commands:${RESET}"
    echo -e "  ${GREEN}ask${RESET} <question>      Ask the cluster a question"
    echo -e "  ${GREEN}chat${RESET}                Start interactive chat"
    echo -e "  ${GREEN}status${RESET}              Full cluster status"
    echo -e "  ${GREEN}bench${RESET}               Run quick benchmark"
    echo
    echo -e "${BOLD}LLM Operations:${RESET}"
    echo -e "  ${BLUE}llm status${RESET}          LLM cluster status"
    echo -e "  ${BLUE}llm ask${RESET} <q>         Query LLM"
    echo -e "  ${BLUE}llm chat${RESET}            Interactive LLM chat"
    echo -e "  ${BLUE}llm models${RESET}          List available models"
    echo -e "  ${BLUE}llm benchmark${RESET}       Benchmark LLM performance"
    echo
    echo -e "${BOLD}Vision & AI:${RESET}"
    echo -e "  ${CYAN}vision detect${RESET} <img>  Object detection"
    echo -e "  ${CYAN}vision stream${RESET}        Live camera stream"
    echo -e "  ${CYAN}hailo status${RESET}         Hailo-8 accelerator status"
    echo
    echo -e "${BOLD}Cluster Management:${RESET}"
    echo -e "  ${YELLOW}nodes${RESET}               List all nodes"
    echo -e "  ${YELLOW}monitor${RESET}             Real-time monitoring"
    echo -e "  ${YELLOW}autoscale${RESET}           Autoscaler controls"
    echo -e "  ${YELLOW}logs${RESET} <node>         View node logs"
    echo
    echo -e "${BOLD}Advanced:${RESET}"
    echo -e "  ${PINK}agents${RESET}              Multi-agent orchestra"
    echo -e "  ${PINK}workflow${RESET} <name>     Run AI workflow"
    echo -e "  ${PINK}batch${RESET}               Batch job processor"
    echo -e "  ${PINK}rag${RESET}                 RAG knowledge base"
    echo -e "  ${PINK}sandbox${RESET}             Code execution sandbox"
    echo
    echo "Run 'brc help <command>' for details"
}

# Dispatch commands
dispatch() {
    local cmd="$1"
    shift

    case "$cmd" in
        # Quick commands
        ask|query|q)
            ~/blackroad-llm-cluster.sh ask "$@"
            ;;
        chat)
            ~/blackroad-lucidia-chat.sh chat
            ;;
        status|s)
            ~/blackroad-cluster-monitor.sh status
            ;;
        bench|benchmark)
            ~/blackroad-llm-cluster.sh benchmark
            ;;

        # LLM
        llm)
            local subcmd="$1"
            shift
            case "$subcmd" in
                status) ~/blackroad-llm-cluster.sh status ;;
                ask|query) ~/blackroad-llm-cluster.sh ask "$@" ;;
                chat) ~/blackroad-llm-cluster.sh chat ;;
                models|list) ~/blackroad-model-registry.sh list ;;
                benchmark|bench) ~/blackroad-llm-cluster.sh benchmark ;;
                parallel) ~/blackroad-llm-cluster.sh parallel "$@" ;;
                *) ~/blackroad-llm-cluster.sh help ;;
            esac
            ;;

        # Vision
        vision)
            local subcmd="$1"
            shift
            case "$subcmd" in
                detect) ~/blackroad-vision-llm.sh detect "$@" ;;
                stream) ~/blackroad-vision-llm.sh stream ;;
                status) ~/blackroad-vision-llm.sh status ;;
                *) ~/blackroad-vision-llm.sh help ;;
            esac
            ;;

        hailo)
            ~/blackroad-cluster-monitor.sh hailo
            ;;

        # Cluster management
        nodes)
            ~/blackroad-cluster-monitor.sh status
            ;;
        monitor|watch)
            ~/blackroad-cluster-monitor.sh watch "$@"
            ;;
        autoscale)
            local subcmd="$1"
            shift
            case "$subcmd" in
                analyze) ~/blackroad-cluster-autoscale.sh analyze ;;
                up) ~/blackroad-cluster-autoscale.sh up "$@" ;;
                down) ~/blackroad-cluster-autoscale.sh down "$@" ;;
                auto) ~/blackroad-cluster-autoscale.sh auto "$@" ;;
                status) ~/blackroad-cluster-autoscale.sh status ;;
                *) ~/blackroad-cluster-autoscale.sh help ;;
            esac
            ;;
        logs)
            local node="$1"
            ssh "$node" "journalctl -n 50 --no-pager" 2>/dev/null
            ;;

        # Advanced
        agents|orchestra)
            local subcmd="$1"
            shift
            case "$subcmd" in
                discuss) ~/blackroad-agent-orchestra.sh discuss "$@" ;;
                chain) ~/blackroad-agent-orchestra.sh chain "$@" ;;
                debate) ~/blackroad-agent-orchestra.sh debate "$@" ;;
                status) ~/blackroad-agent-orchestra.sh status ;;
                *) ~/blackroad-agent-orchestra.sh help ;;
            esac
            ;;
        workflow|wf)
            local subcmd="$1"
            shift
            case "$subcmd" in
                run) ~/blackroad-workflow-engine.sh run "$@" ;;
                create) ~/blackroad-workflow-engine.sh create "$@" ;;
                list) ~/blackroad-workflow-engine.sh list ;;
                *) ~/blackroad-workflow-engine.sh help ;;
            esac
            ;;
        batch)
            local subcmd="$1"
            shift
            case "$subcmd" in
                add) ~/blackroad-batch-processor.sh add "$@" ;;
                process) ~/blackroad-batch-processor.sh process "$@" ;;
                status) ~/blackroad-batch-processor.sh status ;;
                results) ~/blackroad-batch-processor.sh results "$@" ;;
                *) ~/blackroad-batch-processor.sh help ;;
            esac
            ;;
        rag)
            local subcmd="$1"
            shift
            case "$subcmd" in
                add) ~/blackroad-rag-pipeline.sh add "$@" ;;
                query) ~/blackroad-rag-pipeline.sh query "$@" ;;
                chat) ~/blackroad-rag-pipeline.sh chat ;;
                list) ~/blackroad-rag-pipeline.sh list ;;
                *) ~/blackroad-rag-pipeline.sh help ;;
            esac
            ;;
        sandbox|exec)
            local subcmd="$1"
            shift
            case "$subcmd" in
                python) ~/blackroad-code-sandbox.sh exec python "$@" ;;
                node) ~/blackroad-code-sandbox.sh exec node "$@" ;;
                bash) ~/blackroad-code-sandbox.sh exec bash "$@" ;;
                repl) ~/blackroad-code-sandbox.sh repl "$@" ;;
                *) ~/blackroad-code-sandbox.sh help ;;
            esac
            ;;

        # Model management
        models)
            local subcmd="$1"
            shift
            case "$subcmd" in
                list) ~/blackroad-model-registry.sh list "$@" ;;
                scan) ~/blackroad-model-registry.sh scan ;;
                info) ~/blackroad-model-registry.sh info "$@" ;;
                deploy) ~/blackroad-model-registry.sh deploy "$@" ;;
                *) ~/blackroad-model-registry.sh help ;;
            esac
            ;;

        # Fine-tuning
        finetune|ft)
            local subcmd="$1"
            shift
            case "$subcmd" in
                create) ~/blackroad-model-finetune.sh create "$@" ;;
                train) ~/blackroad-model-finetune.sh finetune "$@" ;;
                status) ~/blackroad-model-finetune.sh status ;;
                *) ~/blackroad-model-finetune.sh help ;;
            esac
            ;;

        # Stress testing
        stress|load)
            local subcmd="$1"
            shift
            case "$subcmd" in
                load) ~/blackroad-stress-test.sh load "$@" ;;
                probe) ~/blackroad-stress-test.sh probe ;;
                node) ~/blackroad-stress-test.sh node "$@" ;;
                *) ~/blackroad-stress-test.sh help ;;
            esac
            ;;

        # Metrics
        metrics)
            local subcmd="$1"
            shift
            case "$subcmd" in
                dump) ~/blackroad-metrics-api.sh dump "$@" ;;
                serve) ~/blackroad-metrics-api.sh serve "$@" ;;
                *) ~/blackroad-metrics-api.sh dump json ;;
            esac
            ;;

        # SSH shortcuts
        ssh)
            local node="$1"
            ssh "$node"
            ;;

        # Help
        help|h|--help|-h)
            if [ -n "$1" ]; then
                command_help "$1"
            else
                menu
            fi
            ;;

        # Version
        version|--version|-v)
            echo "BlackRoad Cluster CLI v${VERSION}"
            echo "Agent: Icarus (b3e01bd9)"
            ;;

        # Default: show menu
        ""|menu)
            menu
            ;;

        *)
            echo -e "${RED}Unknown command: $cmd${RESET}"
            echo "Run 'brc help' for available commands"
            ;;
    esac
}

# Command-specific help
command_help() {
    local cmd="$1"

    case "$cmd" in
        llm)
            echo "LLM Commands:"
            echo "  llm status      Show LLM cluster status"
            echo "  llm ask <q>     Ask a question"
            echo "  llm chat        Interactive chat"
            echo "  llm models      List available models"
            echo "  llm benchmark   Run LLM benchmark"
            echo "  llm parallel    Parallel query all nodes"
            ;;
        vision)
            echo "Vision Commands:"
            echo "  vision detect <image>  Detect objects in image"
            echo "  vision stream          Live camera stream"
            echo "  vision status          Check Hailo status"
            ;;
        agents)
            echo "Agent Orchestra Commands:"
            echo "  agents discuss <topic>  Multi-agent discussion"
            echo "  agents chain <task>     Chain agents for complex task"
            echo "  agents debate <topic>   Pro vs con debate"
            echo "  agents status           Show agent status"
            ;;
        workflow)
            echo "Workflow Commands:"
            echo "  workflow run <name> <input>  Execute workflow"
            echo "  workflow create <name>       Create new workflow"
            echo "  workflow list                List workflows"
            ;;
        rag)
            echo "RAG Commands:"
            echo "  rag add <file>    Add document to knowledge base"
            echo "  rag query <q>     Query with RAG"
            echo "  rag chat          Interactive RAG chat"
            echo "  rag list          List documents"
            ;;
        sandbox)
            echo "Code Sandbox Commands:"
            echo "  sandbox python <code>  Execute Python"
            echo "  sandbox node <code>    Execute JavaScript"
            echo "  sandbox bash <code>    Execute Bash"
            echo "  sandbox repl [lang]    Interactive REPL"
            ;;
        *)
            menu
            ;;
    esac
}

# Main
dispatch "$@"
