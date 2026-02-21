#!/bin/bash
# BlackRoad Metrics API
# REST API for cluster metrics and monitoring
# Agent: Icarus (b3e01bd9)

PINK='\033[38;5;205m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RESET='\033[0m'

PORT="${METRICS_PORT:-9090}"
ALL_NODES=("alice" "aria" "lucidia" "octavia" "cecilia")
LLM_NODES=("lucidia" "cecilia" "octavia" "aria")

# Metrics collection
collect_node_metrics() {
    local node="$1"

    if ! ssh -o ConnectTimeout=2 -o BatchMode=yes "$node" "echo ok" >/dev/null 2>&1; then
        echo "{\"status\":\"offline\"}"
        return
    fi

    ssh -o ConnectTimeout=5 "$node" "
        load=\$(cat /proc/loadavg | awk '{print \$1}')
        mem_total=\$(free -b | awk '/Mem:/ {print \$2}')
        mem_used=\$(free -b | awk '/Mem:/ {print \$3}')
        mem_percent=\$(free | awk '/Mem:/ {printf \"%.1f\", \$3/\$2*100}')
        disk_percent=\$(df / | awk 'NR==2 {gsub(/%/,\"\"); print \$5}')
        temp=\$(vcgencmd measure_temp 2>/dev/null | grep -oP '[\d.]+' || echo 0)
        containers=\$(docker ps -q 2>/dev/null | wc -l)
        uptime_sec=\$(awk '{print int(\$1)}' /proc/uptime)

        echo \"{\\\"status\\\":\\\"online\\\",\\\"load\\\":\$load,\\\"mem_total\\\":\$mem_total,\\\"mem_used\\\":\$mem_used,\\\"mem_percent\\\":\$mem_percent,\\\"disk_percent\\\":\$disk_percent,\\\"temp_c\\\":\$temp,\\\"containers\\\":\$containers,\\\"uptime_sec\\\":\$uptime_sec}\"
    " 2>/dev/null || echo "{\"status\":\"error\"}"
}

collect_llm_metrics() {
    local node="$1"

    ssh -o ConnectTimeout=5 "$node" "
        if curl -s http://localhost:11434/api/tags >/dev/null 2>&1; then
            models=\$(curl -s http://localhost:11434/api/tags | jq '.models | length')
            echo \"{\\\"ollama\\\":\\\"online\\\",\\\"models\\\":\$models}\"
        else
            echo '{\"ollama\":\"offline\",\"models\":0}'
        fi
    " 2>/dev/null || echo '{"ollama":"unknown","models":0}'
}

# JSON response helpers
json_response() {
    local code="$1"
    local body="$2"

    echo -e "HTTP/1.1 $code\r"
    echo -e "Content-Type: application/json\r"
    echo -e "Access-Control-Allow-Origin: *\r"
    echo -e "Cache-Control: no-cache\r"
    echo -e "\r"
    echo "$body"
}

# API endpoints
handle_request() {
    local method="$1"
    local path="$2"

    case "$path" in
        /health)
            json_response "200 OK" '{"status":"healthy","service":"blackroad-metrics"}'
            ;;

        /metrics)
            local metrics='{"timestamp":"'"$(date -Iseconds)"'","nodes":{'
            local first=true

            for node in "${ALL_NODES[@]}"; do
                [ "$first" = true ] || metrics+=","
                first=false
                local node_metrics=$(collect_node_metrics "$node")
                metrics+="\"$node\":$node_metrics"
            done

            metrics+='}}'
            json_response "200 OK" "$metrics"
            ;;

        /metrics/llm)
            local metrics='{"timestamp":"'"$(date -Iseconds)"'","nodes":{'
            local first=true

            for node in "${LLM_NODES[@]}"; do
                [ "$first" = true ] || metrics+=","
                first=false
                local node_metrics=$(collect_node_metrics "$node")
                local llm_metrics=$(collect_llm_metrics "$node")
                metrics+="\"$node\":$(echo "$node_metrics $llm_metrics" | jq -s 'add')"
            done

            metrics+='}}'
            json_response "200 OK" "$metrics"
            ;;

        /metrics/node/*)
            local node="${path#/metrics/node/}"
            local node_metrics=$(collect_node_metrics "$node")
            json_response "200 OK" "$node_metrics"
            ;;

        /cluster/status)
            local online=0
            local total=${#ALL_NODES[@]}

            for node in "${ALL_NODES[@]}"; do
                if ssh -o ConnectTimeout=2 -o BatchMode=yes "$node" "echo ok" >/dev/null 2>&1; then
                    ((online++))
                fi
            done

            local status="healthy"
            [ "$online" -lt "$total" ] && status="degraded"
            [ "$online" -eq 0 ] && status="down"

            json_response "200 OK" "{\"status\":\"$status\",\"online\":$online,\"total\":$total}"
            ;;

        /cluster/summary)
            local summary='{"timestamp":"'"$(date -Iseconds)"'"'
            local online=0
            local total_load=0
            local total_mem=0
            local total_containers=0

            for node in "${ALL_NODES[@]}"; do
                local metrics=$(collect_node_metrics "$node")
                local status=$(echo "$metrics" | jq -r '.status')

                if [ "$status" = "online" ]; then
                    ((online++))
                    total_load=$(echo "$total_load + $(echo "$metrics" | jq -r '.load')" | bc)
                    total_mem=$((total_mem + $(echo "$metrics" | jq -r '.mem_percent | floor')))
                    total_containers=$((total_containers + $(echo "$metrics" | jq -r '.containers')))
                fi
            done

            local avg_load=$(echo "scale=2; $total_load / $online" | bc 2>/dev/null || echo 0)
            local avg_mem=$((total_mem / (online > 0 ? online : 1)))

            summary+=",\"online_nodes\":$online"
            summary+=",\"total_nodes\":${#ALL_NODES[@]}"
            summary+=",\"avg_load\":$avg_load"
            summary+=",\"avg_mem_percent\":$avg_mem"
            summary+=",\"total_containers\":$total_containers"
            summary+='}'

            json_response "200 OK" "$summary"
            ;;

        /prometheus)
            # Prometheus exposition format
            local output="# HELP blackroad_node_up Node availability\n# TYPE blackroad_node_up gauge\n"

            for node in "${ALL_NODES[@]}"; do
                local metrics=$(collect_node_metrics "$node")
                local status=$(echo "$metrics" | jq -r '.status')
                local up=0
                [ "$status" = "online" ] && up=1

                output+="blackroad_node_up{node=\"$node\"} $up\n"

                if [ "$status" = "online" ]; then
                    local load=$(echo "$metrics" | jq -r '.load')
                    local mem=$(echo "$metrics" | jq -r '.mem_percent')
                    local temp=$(echo "$metrics" | jq -r '.temp_c')
                    local containers=$(echo "$metrics" | jq -r '.containers')

                    output+="blackroad_node_load{node=\"$node\"} $load\n"
                    output+="blackroad_node_memory_percent{node=\"$node\"} $mem\n"
                    output+="blackroad_node_temp_celsius{node=\"$node\"} $temp\n"
                    output+="blackroad_node_containers{node=\"$node\"} $containers\n"
                fi
            done

            echo -e "HTTP/1.1 200 OK\r"
            echo -e "Content-Type: text/plain\r"
            echo -e "\r"
            echo -e "$output"
            ;;

        *)
            json_response "404 Not Found" '{"error":"Not found","path":"'"$path"'"}'
            ;;
    esac
}

# Start server
serve() {
    echo -e "${PINK}╔══════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${PINK}║           📊 BLACKROAD METRICS API 📊                        ║${RESET}"
    echo -e "${PINK}╚══════════════════════════════════════════════════════════════╝${RESET}"
    echo
    echo "Port: $PORT"
    echo
    echo "Endpoints:"
    echo "  GET /health           Health check"
    echo "  GET /metrics          All node metrics"
    echo "  GET /metrics/llm      LLM cluster metrics"
    echo "  GET /metrics/node/:n  Single node metrics"
    echo "  GET /cluster/status   Cluster status"
    echo "  GET /cluster/summary  Cluster summary"
    echo "  GET /prometheus       Prometheus format"
    echo
    echo -e "${GREEN}Starting server...${RESET}"
    echo

    while true; do
        # Accept connection
        {
            read -r request_line
            method=$(echo "$request_line" | cut -d' ' -f1)
            path=$(echo "$request_line" | cut -d' ' -f2)

            # Read headers (skip them)
            while read -r header; do
                [ "$header" = $'\r' ] && break
            done

            # Handle request
            handle_request "$method" "$path"
        } | nc -l "$PORT" -q1 2>/dev/null || nc -l "$PORT"
    done
}

# One-shot metrics dump
dump() {
    local format="${1:-json}"

    case "$format" in
        json)
            local metrics='{"timestamp":"'"$(date -Iseconds)"'","nodes":{'
            local first=true

            for node in "${ALL_NODES[@]}"; do
                [ "$first" = true ] || metrics+=","
                first=false
                local node_metrics=$(collect_node_metrics "$node")
                metrics+="\"$node\":$node_metrics"
            done

            metrics+='}}'
            echo "$metrics" | jq .
            ;;
        prometheus)
            for node in "${ALL_NODES[@]}"; do
                local metrics=$(collect_node_metrics "$node")
                local status=$(echo "$metrics" | jq -r '.status')
                local up=0
                [ "$status" = "online" ] && up=1

                echo "blackroad_node_up{node=\"$node\"} $up"

                if [ "$status" = "online" ]; then
                    echo "blackroad_node_load{node=\"$node\"} $(echo "$metrics" | jq -r '.load')"
                    echo "blackroad_node_memory_percent{node=\"$node\"} $(echo "$metrics" | jq -r '.mem_percent')"
                    echo "blackroad_node_temp_celsius{node=\"$node\"} $(echo "$metrics" | jq -r '.temp_c')"
                    echo "blackroad_node_containers{node=\"$node\"} $(echo "$metrics" | jq -r '.containers')"
                fi
            done
            ;;
        csv)
            echo "timestamp,node,status,load,mem_percent,temp_c,containers"
            local ts=$(date -Iseconds)
            for node in "${ALL_NODES[@]}"; do
                local metrics=$(collect_node_metrics "$node")
                local status=$(echo "$metrics" | jq -r '.status')
                local load=$(echo "$metrics" | jq -r '.load // 0')
                local mem=$(echo "$metrics" | jq -r '.mem_percent // 0')
                local temp=$(echo "$metrics" | jq -r '.temp_c // 0')
                local containers=$(echo "$metrics" | jq -r '.containers // 0')
                echo "$ts,$node,$status,$load,$mem,$temp,$containers"
            done
            ;;
    esac
}

# Help
help() {
    echo -e "${PINK}BlackRoad Metrics API${RESET}"
    echo
    echo "REST API for cluster metrics and monitoring"
    echo
    echo "Commands:"
    echo "  serve [port]    Start metrics server (default 9090)"
    echo "  dump [format]   One-shot metrics dump (json/prometheus/csv)"
    echo
    echo "Environment:"
    echo "  METRICS_PORT    Server port (default 9090)"
    echo
    echo "Examples:"
    echo "  $0 serve 8080"
    echo "  $0 dump json"
    echo "  curl http://localhost:9090/metrics"
}

case "${1:-help}" in
    serve|start)
        PORT="${2:-$PORT}"
        serve
        ;;
    dump|export)
        dump "$2"
        ;;
    *)
        help
        ;;
esac
