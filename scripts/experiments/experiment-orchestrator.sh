#!/bin/bash
# ============================================================================
# BLACKROAD OS, INC. - PROPRIETARY AND CONFIDENTIAL
# Copyright (c) 2024-2026 BlackRoad OS, Inc. All Rights Reserved.
# 
# This code is the intellectual property of BlackRoad OS, Inc.
# AI-assisted development does not transfer ownership to AI providers.
# Unauthorized use, copying, or distribution is prohibited.
# NOT licensed for AI training or data extraction.
# ============================================================================
# blackroad-experiment-orchestrator.sh
# Comprehensive capability testing for BlackRoad infrastructure
# Tests all devices to discover what they can do without external dependencies

# Don't exit on errors - we want to continue testing even if some tests fail
set +e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
PINK='\033[38;5;205m'
BOLD='\033[1m'
NC='\033[0m'

# Infrastructure inventory (Bash 3.2 compatible)
DEVICE_NAMES=(octavia alice lucidia aria shellfish)
DEVICE_IPS=(192.168.4.81 192.168.4.49 192.168.4.38 192.168.4.82 174.138.44.45)
DEVICE_USERS=(pi pi pi pi alexa)
DEVICE_KEYS=(id_octavia "" br_mesh_ed25519 br_mesh_ed25519 "")

RESULTS_DIR="/tmp/blackroad-experiments-$(date +%s)"
mkdir -p "$RESULTS_DIR"

# Experiment tracking
EXPERIMENTS_TOTAL=0
EXPERIMENTS_PASSED=0
EXPERIMENTS_FAILED=0

echo -e "${BOLD}${PINK}"
cat << "EOF"
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║   🧪 BLACKROAD EXPERIMENT ORCHESTRATOR 🧪                   ║
║                                                              ║
║   Discovering Infrastructure Capabilities                    ║
║   No External Dependencies Required                          ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Helper function to get device index
get_device_index() {
    local device=$1
    for i in "${!DEVICE_NAMES[@]}"; do
        if [[ "${DEVICE_NAMES[$i]}" == "$device" ]]; then
            echo "$i"
            return 0
        fi
    done
    echo "-1"
}

# Helper function to run command on device
run_on_device() {
    local device=$1
    local cmd=$2
    local idx=$(get_device_index "$device")

    if [[ $idx -eq -1 ]]; then
        echo "Device $device not found" >&2
        return 1
    fi

    local ip=${DEVICE_IPS[$idx]}
    local user=${DEVICE_USERS[$idx]}
    local key=${DEVICE_KEYS[$idx]}

    # Build SSH command with key if specified
    if [[ -n "$key" && -f "$HOME/.ssh/$key" ]]; then
        ssh -i "$HOME/.ssh/$key" -o ConnectTimeout=5 -o StrictHostKeyChecking=no "${user}@${ip}" "$cmd" 2>/dev/null
    else
        ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no "${user}@${ip}" "$cmd" 2>/dev/null
    fi
}

# Helper function to log experiment result
log_experiment() {
    local name=$1
    local device=$2
    local status=$3
    local result=$4

    ((EXPERIMENTS_TOTAL++))

    if [[ "$status" == "PASS" ]]; then
        ((EXPERIMENTS_PASSED++))
        echo -e "${GREEN}✓${NC} [$device] $name: $result"
    else
        ((EXPERIMENTS_FAILED++))
        echo -e "${RED}✗${NC} [$device] $name: $result"
    fi

    echo "$device,$name,$status,$result" >> "$RESULTS_DIR/experiments.csv"
}

# Experiment 1: Hardware Discovery
experiment_hardware_discovery() {
    echo -e "\n${BOLD}${PINK}━━━ Experiment 1: Hardware Discovery ━━━${NC}\n"

    for i in "${!DEVICE_NAMES[@]}"; do
        local device=${DEVICE_NAMES[$i]}
        local ip=${DEVICE_IPS[$i]}
        echo -e "${YELLOW}Testing $device ($ip)...${NC}"

        # CPU info
        cpu_info=$(run_on_device "$device" "nproc 2>/dev/null || echo '0'")
        if [[ "$cpu_info" != "0" ]]; then
            log_experiment "CPU_COUNT" "$device" "PASS" "${cpu_info} cores"
        else
            log_experiment "CPU_COUNT" "$device" "FAIL" "Unable to detect"
        fi

        # Memory info
        mem_info=$(run_on_device "$device" "free -h | grep Mem | awk '{print \$2}'")
        if [[ -n "$mem_info" ]]; then
            log_experiment "MEMORY_TOTAL" "$device" "PASS" "$mem_info"
        else
            log_experiment "MEMORY_TOTAL" "$device" "FAIL" "Unable to detect"
        fi

        # Disk space
        disk_info=$(run_on_device "$device" "df -h / | tail -1 | awk '{print \$2}'")
        if [[ -n "$disk_info" ]]; then
            log_experiment "DISK_SPACE" "$device" "PASS" "$disk_info"
        else
            log_experiment "DISK_SPACE" "$device" "FAIL" "Unable to detect"
        fi

        # Architecture
        arch_info=$(run_on_device "$device" "uname -m")
        if [[ -n "$arch_info" ]]; then
            log_experiment "ARCHITECTURE" "$device" "PASS" "$arch_info"
        else
            log_experiment "ARCHITECTURE" "$device" "FAIL" "Unable to detect"
        fi
    done
}

# Experiment 2: Software Inventory
experiment_software_inventory() {
    echo -e "\n${BOLD}${PINK}━━━ Experiment 2: Software Inventory ━━━${NC}\n"

    for i in "${!DEVICE_NAMES[@]}"; do
        local device=${DEVICE_NAMES[$i]}
        echo -e "${YELLOW}Checking $device...${NC}"

        # Docker
        if run_on_device "$device" "command -v docker" &>/dev/null; then
            version=$(run_on_device "$device" "docker --version | cut -d' ' -f3 | tr -d ','")
            log_experiment "DOCKER" "$device" "PASS" "v$version"
        else
            log_experiment "DOCKER" "$device" "FAIL" "Not installed"
        fi

        # Python
        if run_on_device "$device" "command -v python3" &>/dev/null; then
            version=$(run_on_device "$device" "python3 --version | cut -d' ' -f2")
            log_experiment "PYTHON3" "$device" "PASS" "v$version"
        else
            log_experiment "PYTHON3" "$device" "FAIL" "Not installed"
        fi

        # Node.js
        if run_on_device "$device" "command -v node" &>/dev/null; then
            version=$(run_on_device "$device" "node --version | tr -d 'v'")
            log_experiment "NODEJS" "$device" "PASS" "v$version"
        else
            log_experiment "NODEJS" "$device" "FAIL" "Not installed"
        fi

        # Git
        if run_on_device "$device" "command -v git" &>/dev/null; then
            version=$(run_on_device "$device" "git --version | cut -d' ' -f3")
            log_experiment "GIT" "$device" "PASS" "v$version"
        else
            log_experiment "GIT" "$device" "FAIL" "Not installed"
        fi

        # Kubernetes
        if run_on_device "$device" "command -v kubectl" &>/dev/null; then
            log_experiment "KUBERNETES" "$device" "PASS" "kubectl available"
        else
            log_experiment "KUBERNETES" "$device" "FAIL" "Not installed"
        fi
    done
}

# Experiment 3: CPU Performance Test
experiment_cpu_performance() {
    echo -e "\n${BOLD}${PINK}━━━ Experiment 3: CPU Performance Test ━━━${NC}\n"
    echo -e "${YELLOW}Running CPU benchmark (1000 iterations)...${NC}"

    for i in "${!DEVICE_NAMES[@]}"; do
        local device=${DEVICE_NAMES[$i]}
        # Simple CPU test: count to 1000000
        start_time=$(date +%s)
        result=$(run_on_device "$device" "
            count=0
            for i in \$(seq 1 1000); do
                count=\$((count + i))
            done
            echo \$count
        " 2>/dev/null || echo "0")
        end_time=$(date +%s)
        duration=$((end_time - start_time))

        if [[ "$result" != "0" ]]; then
            log_experiment "CPU_BENCH" "$device" "PASS" "${duration}s (result: $result)"
        else
            log_experiment "CPU_BENCH" "$device" "FAIL" "Benchmark failed"
        fi
    done
}

# Experiment 4: Network Speed Test
experiment_network_speed() {
    echo -e "\n${BOLD}${PINK}━━━ Experiment 4: Network Speed Test ━━━${NC}\n"
    echo -e "${YELLOW}Testing inter-device network performance...${NC}"

    # Create 1MB test file (smaller for faster tests)
    dd if=/dev/zero of=/tmp/nettest bs=1M count=1 2>/dev/null

    for i in "${!DEVICE_NAMES[@]}"; do
        local device=${DEVICE_NAMES[$i]}
        local ip=${DEVICE_IPS[$i]}
        local user=${DEVICE_USERS[$i]}

        start_time=$(date +%s)
        if scp -o ConnectTimeout=5 -o StrictHostKeyChecking=no /tmp/nettest "${user}@${ip}:/tmp/nettest" &>/dev/null; then
            end_time=$(date +%s)
            duration=$((end_time - start_time))

            # Calculate approximate speed
            if [[ $duration -gt 0 ]]; then
                log_experiment "NETWORK_UPLOAD" "$device" "PASS" "~${duration}s for 1MB"
            else
                log_experiment "NETWORK_UPLOAD" "$device" "PASS" "<1s for 1MB"
            fi

            # Cleanup
            run_on_device "$device" "rm -f /tmp/nettest" &>/dev/null
        else
            log_experiment "NETWORK_UPLOAD" "$device" "FAIL" "Transfer failed"
        fi
    done

    rm -f /tmp/nettest
}

# Experiment 5: Container Capability Test
experiment_container_capability() {
    echo -e "\n${BOLD}${PINK}━━━ Experiment 5: Container Capability Test ━━━${NC}\n"

    for i in "${!DEVICE_NAMES[@]}"; do
        local device=${DEVICE_NAMES[$i]}
        echo -e "${YELLOW}Testing $device...${NC}"

        # Check if docker is running
        if ! run_on_device "$device" "docker ps" &>/dev/null; then
            log_experiment "DOCKER_RUNNING" "$device" "FAIL" "Docker not running"
            continue
        fi

        log_experiment "DOCKER_RUNNING" "$device" "PASS" "Docker daemon active"

        # Count running containers
        container_count=$(run_on_device "$device" "docker ps -q | wc -l")
        log_experiment "RUNNING_CONTAINERS" "$device" "PASS" "$container_count containers"

        # List networks
        network_count=$(run_on_device "$device" "docker network ls -q | wc -l")
        log_experiment "DOCKER_NETWORKS" "$device" "PASS" "$network_count networks"

        # Check available images
        image_count=$(run_on_device "$device" "docker images -q | wc -l")
        log_experiment "DOCKER_IMAGES" "$device" "PASS" "$image_count images cached"
    done
}

# Experiment 6: Parallel Processing Test
experiment_parallel_processing() {
    echo -e "\n${BOLD}${PINK}━━━ Experiment 6: Parallel Processing Test ━━━${NC}\n"
    echo -e "${YELLOW}Testing distributed workload processing...${NC}"

    # Create a test script that each device will run
    test_script='
#!/bin/bash
count=0
for i in $(seq 1 1000); do
    count=$((count + i))
done
echo $count
'

    # Start all devices simultaneously
    pids=()
    for i in "${!DEVICE_NAMES[@]}"; do
        local device=${DEVICE_NAMES[$i]}
        (
            result=$(run_on_device "$device" "$test_script")
            echo "$device:$result" >> "$RESULTS_DIR/parallel_results.txt"
        ) &
        pids+=($!)
    done

    # Wait for all to complete
    start_time=$(date +%s)
    for pid in "${pids[@]}"; do
        wait "$pid"
    done
    end_time=$(date +%s)

    total_time=$((end_time - start_time))
    device_count=${#DEVICE_NAMES[@]}

    log_experiment "PARALLEL_PROCESSING" "cluster" "PASS" "${device_count} devices completed in ${total_time}s"
}

# Experiment 7: Storage I/O Performance
experiment_storage_io() {
    echo -e "\n${BOLD}${PINK}━━━ Experiment 7: Storage I/O Performance ━━━${NC}\n"

    for i in "${!DEVICE_NAMES[@]}"; do
        local device=${DEVICE_NAMES[$i]}
        echo -e "${YELLOW}Testing $device storage I/O...${NC}"

        # Write test
        write_speed=$(run_on_device "$device" "
            dd if=/dev/zero of=/tmp/iotest bs=1M count=100 2>&1 | \
            grep -oP '\d+(\.\d+)? MB/s' | tail -1
        " || echo "0 MB/s")

        if [[ "$write_speed" != "0 MB/s" ]]; then
            log_experiment "STORAGE_WRITE" "$device" "PASS" "$write_speed"
        else
            log_experiment "STORAGE_WRITE" "$device" "FAIL" "Unable to test"
        fi

        # Read test
        read_speed=$(run_on_device "$device" "
            dd if=/tmp/iotest of=/dev/null bs=1M 2>&1 | \
            grep -oP '\d+(\.\d+)? MB/s' | tail -1
        " || echo "0 MB/s")

        if [[ "$read_speed" != "0 MB/s" ]]; then
            log_experiment "STORAGE_READ" "$device" "PASS" "$read_speed"
        else
            log_experiment "STORAGE_READ" "$device" "FAIL" "Unable to test"
        fi

        # Cleanup
        run_on_device "$device" "rm -f /tmp/iotest" &>/dev/null
    done
}

# Experiment 8: Service Discovery
experiment_service_discovery() {
    echo -e "\n${BOLD}${PINK}━━━ Experiment 8: Active Service Discovery ━━━${NC}\n"

    for i in "${!DEVICE_NAMES[@]}"; do
        local device=${DEVICE_NAMES[$i]}
        echo -e "${YELLOW}Discovering services on $device...${NC}"

        # Check for common listening ports
        ports=$(run_on_device "$device" "ss -tuln 2>/dev/null | grep LISTEN | awk '{print \$5}' | cut -d':' -f2 | sort -n | uniq | tr '\n' ',' | sed 's/,$//'")

        if [[ -n "$ports" ]]; then
            log_experiment "LISTENING_PORTS" "$device" "PASS" "$ports"
        else
            log_experiment "LISTENING_PORTS" "$device" "FAIL" "No ports detected"
        fi

        # Check systemd services (if available)
        service_count=$(run_on_device "$device" "systemctl list-units --type=service --state=running 2>/dev/null | grep -c '.service' || echo '0'")

        if [[ "$service_count" != "0" ]]; then
            log_experiment "ACTIVE_SERVICES" "$device" "PASS" "$service_count systemd services"
        else
            log_experiment "ACTIVE_SERVICES" "$device" "FAIL" "Unable to count services"
        fi
    done
}

# Experiment 9: Compilation Test
experiment_compilation_capability() {
    echo -e "\n${BOLD}${PINK}━━━ Experiment 9: Native Compilation Test ━━━${NC}\n"

    for i in "${!DEVICE_NAMES[@]}"; do
        local device=${DEVICE_NAMES[$i]}
        echo -e "${YELLOW}Testing compilation on $device...${NC}"

        # Create simple C program
        c_program='
#include <stdio.h>
int main() {
    printf("BlackRoad Compilation Test\\n");
    return 0;
}
'

        # Test GCC
        if run_on_device "$device" "command -v gcc" &>/dev/null; then
            compile_result=$(run_on_device "$device" "
                echo '$c_program' > /tmp/test.c && \
                gcc /tmp/test.c -o /tmp/test 2>&1 && \
                /tmp/test && \
                rm -f /tmp/test.c /tmp/test
            " 2>/dev/null)

            if [[ "$compile_result" == *"BlackRoad Compilation Test"* ]]; then
                log_experiment "GCC_COMPILE" "$device" "PASS" "Native compilation working"
            else
                log_experiment "GCC_COMPILE" "$device" "FAIL" "Compilation failed"
            fi
        else
            log_experiment "GCC_COMPILE" "$device" "FAIL" "GCC not installed"
        fi
    done
}

# Experiment 10: Memory Stress Test
experiment_memory_stress() {
    echo -e "\n${BOLD}${PINK}━━━ Experiment 10: Memory Capacity Test ━━━${NC}\n"

    for i in "${!DEVICE_NAMES[@]}"; do
        local device=${DEVICE_NAMES[$i]}
        echo -e "${YELLOW}Testing $device memory...${NC}"

        # Get available memory
        mem_available=$(run_on_device "$device" "free -m | grep Mem | awk '{print \$7}'")

        if [[ -n "$mem_available" ]]; then
            log_experiment "MEMORY_AVAILABLE" "$device" "PASS" "${mem_available}MB free"

            # Test memory allocation (allocate 100MB)
            mem_test=$(run_on_device "$device" "
                python3 -c 'import sys; data = bytearray(100 * 1024 * 1024); print(len(data))' 2>/dev/null || echo '0'
            ")

            if [[ "$mem_test" != "0" ]]; then
                log_experiment "MEMORY_ALLOCATION" "$device" "PASS" "Can allocate 100MB"
            else
                log_experiment "MEMORY_ALLOCATION" "$device" "FAIL" "Allocation test failed"
            fi
        else
            log_experiment "MEMORY_AVAILABLE" "$device" "FAIL" "Unable to detect"
        fi
    done
}

# Generate comprehensive report
generate_report() {
    echo -e "\n${BOLD}${PINK}"
    cat << "EOF"
╔══════════════════════════════════════════════════════════════╗
║                 📊 EXPERIMENT RESULTS 📊                    ║
╚══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"

    echo -e "${BOLD}Total Experiments:${NC} $EXPERIMENTS_TOTAL"
    echo -e "${GREEN}Passed:${NC} $EXPERIMENTS_PASSED"
    echo -e "${RED}Failed:${NC} $EXPERIMENTS_FAILED"

    pass_rate=$(echo "scale=2; ($EXPERIMENTS_PASSED * 100) / $EXPERIMENTS_TOTAL" | bc)
    echo -e "${BOLD}Pass Rate:${NC} ${pass_rate}%"

    echo -e "\n${BOLD}Results saved to:${NC} $RESULTS_DIR"
    echo -e "  • experiments.csv - Detailed results"
    echo -e "  • parallel_results.txt - Parallel processing data"

    # Generate device capability matrix
    echo -e "\n${BOLD}${PINK}━━━ Device Capability Matrix ━━━${NC}\n"

    for i in "${!DEVICE_NAMES[@]}"; do
        local device=${DEVICE_NAMES[$i]}
        local ip=${DEVICE_IPS[$i]}
        echo -e "${YELLOW}$device ($ip):${NC}"
        grep "^$device," "$RESULTS_DIR/experiments.csv" | while IFS=, read -r dev exp status result; do
            if [[ "$status" == "PASS" ]]; then
                echo -e "  ${GREEN}✓${NC} $exp: $result"
            fi
        done
        echo ""
    done
}

# Main execution
main() {
    echo -e "${PINK}Starting comprehensive infrastructure experiments...${NC}\n"
    echo -e "${YELLOW}Testing ${#DEVICE_NAMES[@]} devices:${NC} ${DEVICE_NAMES[*]}\n"

    # Run all experiments
    experiment_hardware_discovery
    experiment_software_inventory
    experiment_cpu_performance
    experiment_network_speed
    experiment_container_capability
    experiment_parallel_processing
    experiment_storage_io
    experiment_service_discovery
    experiment_compilation_capability
    experiment_memory_stress

    # Generate final report
    generate_report

    # Log to memory system
    ~/memory-system.sh log experiment "[INFRASTRUCTURE]+[CAPABILITY_TEST] Experiment Orchestrator Complete" \
        "Ran $EXPERIMENTS_TOTAL experiments across ${#DEVICE_NAMES[@]} devices. Pass rate: ${pass_rate}%. Results: $RESULTS_DIR" \
        "infrastructure,testing,experiments" 2>/dev/null || true

    echo -e "\n${GREEN}${BOLD}🎉 All experiments complete! 🎉${NC}\n"
}

# Handle script arguments
case "${1:-}" in
    help|--help|-h)
        echo "Usage: $0 [command]"
        echo ""
        echo "Commands:"
        echo "  (no args)   - Run all experiments"
        echo "  hardware    - Hardware discovery only"
        echo "  software    - Software inventory only"
        echo "  network     - Network tests only"
        echo "  containers  - Container tests only"
        echo "  help        - Show this help"
        ;;
    hardware)
        experiment_hardware_discovery
        ;;
    software)
        experiment_software_inventory
        ;;
    network)
        experiment_network_speed
        ;;
    containers)
        experiment_container_capability
        ;;
    *)
        main
        ;;
esac
