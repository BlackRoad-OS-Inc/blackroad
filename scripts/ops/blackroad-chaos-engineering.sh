#!/bin/bash
# BlackRoad Chaos Engineering
# Fault injection and resilience testing for the cluster
# Agent: Icarus (b3e01bd9)

PINK='\033[38;5;205m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
RESET='\033[0m'

CHAOS_DIR="$HOME/.blackroad/chaos"
CHAOS_DB="$CHAOS_DIR/chaos.db"
ALL_NODES=("lucidia" "cecilia" "octavia" "aria" "alice")

# Initialize
init() {
    mkdir -p "$CHAOS_DIR"/{experiments,reports}

    sqlite3 "$CHAOS_DB" << 'SQL'
CREATE TABLE IF NOT EXISTS experiments (
    id TEXT PRIMARY KEY,
    name TEXT,
    type TEXT,
    target TEXT,
    config TEXT,
    status TEXT DEFAULT 'created',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    started_at DATETIME,
    ended_at DATETIME,
    result TEXT
);

CREATE TABLE IF NOT EXISTS observations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    experiment_id TEXT,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    metric TEXT,
    value REAL,
    notes TEXT
);

CREATE TABLE IF NOT EXISTS game_days (
    id TEXT PRIMARY KEY,
    name TEXT,
    experiments TEXT,
    scheduled_at DATETIME,
    status TEXT DEFAULT 'scheduled'
);
SQL

    echo -e "${GREEN}Chaos engineering system initialized${RESET}"
    echo -e "${RED}WARNING: Use with caution on production systems!${RESET}"
}

# Create experiment
create() {
    local name="$1"
    local type="$2"
    local target="$3"
    local config="${4:-{}}"

    local exp_id="chaos_$(date +%s)_$(openssl rand -hex 4)"

    sqlite3 "$CHAOS_DB" "
        INSERT INTO experiments (id, name, type, target, config)
        VALUES ('$exp_id', '$name', '$type', '$target', '$config')
    "

    echo -e "${GREEN}Experiment created: $exp_id${RESET}"
    echo "  Name: $name"
    echo "  Type: $type"
    echo "  Target: $target"
}

# List experiment types
types() {
    echo -e "${PINK}=== CHAOS EXPERIMENT TYPES ===${RESET}"
    echo
    echo "Network:"
    echo "  latency     - Add network latency"
    echo "  packet-loss - Simulate packet loss"
    echo "  partition   - Network partition"
    echo "  blackhole   - Drop all traffic"
    echo
    echo "Resource:"
    echo "  cpu-stress  - CPU stress test"
    echo "  mem-stress  - Memory pressure"
    echo "  disk-fill   - Fill disk space"
    echo "  io-stress   - Disk I/O stress"
    echo
    echo "Process:"
    echo "  kill-proc   - Kill process"
    echo "  stop-svc    - Stop service"
    echo "  restart     - Force restart"
    echo "  oom         - Trigger OOM killer"
    echo
    echo "Application:"
    echo "  slow-resp   - Slow API responses"
    echo "  error-rate  - Inject errors"
    echo "  timeout     - Force timeouts"
}

# Inject latency
inject_latency() {
    local node="$1"
    local delay="${2:-100}"
    local duration="${3:-60}"

    echo -e "${RED}Injecting ${delay}ms latency on $node for ${duration}s${RESET}"

    ssh "$node" "
        sudo tc qdisc add dev eth0 root netem delay ${delay}ms 2>/dev/null || \
        sudo tc qdisc change dev eth0 root netem delay ${delay}ms
    "

    # Schedule cleanup
    (
        sleep "$duration"
        ssh "$node" "sudo tc qdisc del dev eth0 root 2>/dev/null"
        echo -e "\n${GREEN}Latency removed from $node${RESET}"
    ) &
}

# Inject packet loss
inject_packet_loss() {
    local node="$1"
    local loss="${2:-10}"
    local duration="${3:-60}"

    echo -e "${RED}Injecting ${loss}% packet loss on $node for ${duration}s${RESET}"

    ssh "$node" "
        sudo tc qdisc add dev eth0 root netem loss ${loss}% 2>/dev/null || \
        sudo tc qdisc change dev eth0 root netem loss ${loss}%
    "

    (
        sleep "$duration"
        ssh "$node" "sudo tc qdisc del dev eth0 root 2>/dev/null"
        echo -e "\n${GREEN}Packet loss removed from $node${RESET}"
    ) &
}

# CPU stress
inject_cpu_stress() {
    local node="$1"
    local load="${2:-80}"
    local duration="${3:-60}"

    echo -e "${RED}Stressing CPU to ${load}% on $node for ${duration}s${RESET}"

    ssh "$node" "
        stress-ng --cpu 4 --cpu-load $load --timeout ${duration}s >/dev/null 2>&1 || \
        for i in \$(seq 1 4); do
            timeout ${duration}s dd if=/dev/zero of=/dev/null &
        done
        wait
    " &
}

# Memory stress
inject_mem_stress() {
    local node="$1"
    local mb="${2:-512}"
    local duration="${3:-60}"

    echo -e "${RED}Allocating ${mb}MB memory on $node for ${duration}s${RESET}"

    ssh "$node" "
        stress-ng --vm 1 --vm-bytes ${mb}M --timeout ${duration}s >/dev/null 2>&1 || \
        python3 -c \"
import time
data = 'x' * ($mb * 1024 * 1024)
time.sleep($duration)
\" 2>/dev/null
    " &
}

# Kill process
inject_kill() {
    local node="$1"
    local process="$2"

    echo -e "${RED}Killing process '$process' on $node${RESET}"

    ssh "$node" "pkill -9 '$process'" 2>/dev/null

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Process killed${RESET}"
    else
        echo -e "${YELLOW}Process not found or could not be killed${RESET}"
    fi
}

# Stop Ollama service
inject_stop_ollama() {
    local node="$1"
    local duration="${2:-60}"

    echo -e "${RED}Stopping Ollama on $node for ${duration}s${RESET}"

    ssh "$node" "sudo systemctl stop ollama" 2>/dev/null

    (
        sleep "$duration"
        ssh "$node" "sudo systemctl start ollama" 2>/dev/null
        echo -e "\n${GREEN}Ollama restarted on $node${RESET}"
    ) &
}

# Network partition (block specific node)
inject_partition() {
    local source="$1"
    local target="$2"
    local duration="${3:-60}"

    local target_ip=$(ssh "$target" "hostname -I | awk '{print \$1}'" 2>/dev/null)

    echo -e "${RED}Partitioning $source from $target ($target_ip) for ${duration}s${RESET}"

    ssh "$source" "sudo iptables -A INPUT -s $target_ip -j DROP; sudo iptables -A OUTPUT -d $target_ip -j DROP"

    (
        sleep "$duration"
        ssh "$source" "sudo iptables -D INPUT -s $target_ip -j DROP; sudo iptables -D OUTPUT -d $target_ip -j DROP"
        echo -e "\n${GREEN}Partition healed between $source and $target${RESET}"
    ) &
}

# Run experiment
run() {
    local exp_id="$1"

    local exp=$(sqlite3 "$CHAOS_DB" "SELECT name, type, target, config FROM experiments WHERE id = '$exp_id'")

    if [ -z "$exp" ]; then
        echo -e "${RED}Experiment not found${RESET}"
        return 1
    fi

    local name=$(echo "$exp" | cut -d'|' -f1)
    local type=$(echo "$exp" | cut -d'|' -f2)
    local target=$(echo "$exp" | cut -d'|' -f3)
    local config=$(echo "$exp" | cut -d'|' -f4)

    echo -e "${PINK}╔══════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${PINK}║           💥 CHAOS EXPERIMENT: $name${RESET}"
    echo -e "${PINK}╚══════════════════════════════════════════════════════════════╝${RESET}"
    echo
    echo -e "${RED}Type: $type | Target: $target${RESET}"
    echo

    sqlite3 "$CHAOS_DB" "UPDATE experiments SET status = 'running', started_at = datetime('now') WHERE id = '$exp_id'"

    # Record baseline
    record_observation "$exp_id" "baseline" "$(get_cluster_health)"

    # Execute chaos
    case "$type" in
        latency)
            local delay=$(echo "$config" | jq -r '.delay // 100')
            local duration=$(echo "$config" | jq -r '.duration // 60')
            inject_latency "$target" "$delay" "$duration"
            ;;
        packet-loss)
            local loss=$(echo "$config" | jq -r '.loss // 10')
            local duration=$(echo "$config" | jq -r '.duration // 60')
            inject_packet_loss "$target" "$loss" "$duration"
            ;;
        cpu-stress)
            local load=$(echo "$config" | jq -r '.load // 80')
            local duration=$(echo "$config" | jq -r '.duration // 60')
            inject_cpu_stress "$target" "$load" "$duration"
            ;;
        mem-stress)
            local mb=$(echo "$config" | jq -r '.mb // 512')
            local duration=$(echo "$config" | jq -r '.duration // 60')
            inject_mem_stress "$target" "$mb" "$duration"
            ;;
        kill-proc)
            local process=$(echo "$config" | jq -r '.process')
            inject_kill "$target" "$process"
            ;;
        stop-ollama)
            local duration=$(echo "$config" | jq -r '.duration // 60')
            inject_stop_ollama "$target" "$duration"
            ;;
        partition)
            local other=$(echo "$config" | jq -r '.other')
            local duration=$(echo "$config" | jq -r '.duration // 60')
            inject_partition "$target" "$other" "$duration"
            ;;
    esac

    # Monitor during chaos
    echo
    echo "Monitoring..."
    for i in 1 2 3; do
        sleep 10
        record_observation "$exp_id" "during_$i" "$(get_cluster_health)"
    done

    sqlite3 "$CHAOS_DB" "UPDATE experiments SET status = 'completed', ended_at = datetime('now') WHERE id = '$exp_id'"

    echo
    echo -e "${GREEN}Experiment completed${RESET}"
    analyze "$exp_id"
}

# Get cluster health score
get_cluster_health() {
    local score=100
    local online=0

    for node in "${ALL_NODES[@]}"; do
        if ssh -o ConnectTimeout=2 "$node" "echo ok" >/dev/null 2>&1; then
            ((online++))
        else
            ((score -= 20))
        fi
    done

    echo "$score"
}

# Record observation
record_observation() {
    local exp_id="$1"
    local metric="$2"
    local value="$3"

    sqlite3 "$CHAOS_DB" "
        INSERT INTO observations (experiment_id, metric, value)
        VALUES ('$exp_id', '$metric', $value)
    "
}

# Analyze experiment results
analyze() {
    local exp_id="$1"

    echo -e "${PINK}=== EXPERIMENT ANALYSIS ===${RESET}"
    echo

    sqlite3 "$CHAOS_DB" "SELECT metric, value, timestamp FROM observations WHERE experiment_id = '$exp_id' ORDER BY timestamp" | \
    while IFS='|' read -r metric value ts; do
        local color=$GREEN
        [ "$value" -lt 80 ] && color=$YELLOW
        [ "$value" -lt 60 ] && color=$RED

        printf "  %-15s ${color}%3d${RESET}  %s\n" "$metric" "$value" "$ts"
    done

    echo
    local baseline=$(sqlite3 "$CHAOS_DB" "SELECT value FROM observations WHERE experiment_id = '$exp_id' AND metric = 'baseline'")
    local final=$(sqlite3 "$CHAOS_DB" "SELECT value FROM observations WHERE experiment_id = '$exp_id' ORDER BY timestamp DESC LIMIT 1")

    local impact=$((baseline - final))

    if [ "$impact" -le 10 ]; then
        echo -e "${GREEN}System showed good resilience (impact: ${impact}%)${RESET}"
    elif [ "$impact" -le 30 ]; then
        echo -e "${YELLOW}Moderate impact detected (impact: ${impact}%)${RESET}"
    else
        echo -e "${RED}Significant impact (impact: ${impact}%) - review resilience${RESET}"
    fi
}

# Quick chaos (one-liner)
quick() {
    local type="$1"
    local target="$2"
    local duration="${3:-30}"

    echo -e "${YELLOW}Quick chaos: $type on $target for ${duration}s${RESET}"
    echo -e "${RED}Starting in 3 seconds... Ctrl+C to cancel${RESET}"
    sleep 3

    case "$type" in
        latency) inject_latency "$target" 200 "$duration" ;;
        packet-loss) inject_packet_loss "$target" 20 "$duration" ;;
        cpu) inject_cpu_stress "$target" 90 "$duration" ;;
        memory) inject_mem_stress "$target" 1024 "$duration" ;;
        ollama) inject_stop_ollama "$target" "$duration" ;;
    esac
}

# List experiments
list() {
    echo -e "${PINK}=== CHAOS EXPERIMENTS ===${RESET}"
    echo

    sqlite3 "$CHAOS_DB" "
        SELECT id, name, type, target, status, started_at FROM experiments ORDER BY created_at DESC
    " | while IFS='|' read -r id name type target status started; do
        local status_color=$RESET
        [ "$status" = "running" ] && status_color=$RED
        [ "$status" = "completed" ] && status_color=$GREEN

        printf "  %-25s %-12s %-10s ${status_color}%-10s${RESET}\n" "$id" "$type" "$target" "$status"
        echo "    $name"
    done
}

# Abort running experiments
abort() {
    echo -e "${YELLOW}Aborting all chaos...${RESET}"

    for node in "${ALL_NODES[@]}"; do
        ssh "$node" "
            sudo tc qdisc del dev eth0 root 2>/dev/null
            sudo iptables -F 2>/dev/null
            pkill stress-ng 2>/dev/null
            sudo systemctl start ollama 2>/dev/null
        " 2>/dev/null &
    done
    wait

    sqlite3 "$CHAOS_DB" "UPDATE experiments SET status = 'aborted' WHERE status = 'running'"

    echo -e "${GREEN}All chaos aborted${RESET}"
}

# Help
help() {
    echo -e "${PINK}BlackRoad Chaos Engineering${RESET}"
    echo
    echo "Fault injection and resilience testing"
    echo
    echo "Commands:"
    echo "  create <name> <type> <target>   Create experiment"
    echo "  types                           List experiment types"
    echo "  run <exp_id>                    Run experiment"
    echo "  quick <type> <node> [dur]       Quick one-off chaos"
    echo "  list                            List experiments"
    echo "  analyze <exp_id>                Analyze results"
    echo "  abort                           Stop all chaos"
    echo
    echo "Quick types: latency, packet-loss, cpu, memory, ollama"
    echo
    echo "Examples:"
    echo "  $0 create 'test-resilience' latency cecilia '{\"delay\":200}'"
    echo "  $0 quick cpu cecilia 30"
    echo "  $0 abort"
}

# Ensure initialized
[ -f "$CHAOS_DB" ] || init >/dev/null

case "${1:-help}" in
    init)
        init
        ;;
    create|new)
        create "$2" "$3" "$4" "$5"
        ;;
    types)
        types
        ;;
    run|execute)
        run "$2"
        ;;
    quick|inject)
        quick "$2" "$3" "$4"
        ;;
    list|ls)
        list
        ;;
    analyze)
        analyze "$2"
        ;;
    abort|stop)
        abort
        ;;
    *)
        help
        ;;
esac
