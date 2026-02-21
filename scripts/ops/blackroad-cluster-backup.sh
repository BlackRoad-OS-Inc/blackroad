#!/bin/bash
# BlackRoad Cluster Backup
# Distributed backup and snapshot system for the Pi cluster
# Agent: Icarus (b3e01bd9)

PINK='\033[38;5;205m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
RESET='\033[0m'

BACKUP_DIR="$HOME/.blackroad/backups"
REMOTE_BACKUP_DIR="/opt/blackroad/backups"
ALL_NODES=("lucidia" "cecilia" "octavia" "aria" "alice")

# What to backup on each node
declare -A NODE_PATHS=(
    ["lucidia"]="/opt/ollama /home/pi/.config"
    ["cecilia"]="/opt/ollama /opt/hailo /home/pi/.config"
    ["octavia"]="/opt/ollama /home/pi/.config"
    ["aria"]="/opt/docker /home/pi/.config"
    ["alice"]="/opt/blackroad /home/pi"
)

# Initialize
init() {
    mkdir -p "$BACKUP_DIR"/{snapshots,configs,models,data}
    echo -e "${GREEN}Backup system initialized${RESET}"
    echo "  Local: $BACKUP_DIR"
}

# Backup a single node
backup_node() {
    local node="$1"
    local type="${2:-full}"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_name="${node}_${type}_${timestamp}"

    echo -e "${BLUE}Backing up $node ($type)...${RESET}"

    if ! ssh -o ConnectTimeout=3 "$node" "echo ok" >/dev/null 2>&1; then
        echo -e "${RED}  Node offline${RESET}"
        return 1
    fi

    local backup_file="$BACKUP_DIR/snapshots/$backup_name.tar.gz"

    case "$type" in
        full)
            # Full backup of configured paths
            local paths="${NODE_PATHS[$node]}"
            ssh "$node" "sudo tar czf - $paths 2>/dev/null" > "$backup_file"
            ;;
        config)
            # Just config files
            ssh "$node" "tar czf - /home/pi/.config /etc/*.conf 2>/dev/null" > "$backup_file"
            ;;
        models)
            # Ollama models only
            ssh "$node" "tar czf - /opt/ollama/models 2>/dev/null" > "$backup_file"
            ;;
        docker)
            # Docker volumes
            ssh "$node" "docker run --rm -v /var/lib/docker/volumes:/volumes alpine tar czf - /volumes 2>/dev/null" > "$backup_file"
            ;;
    esac

    local size=$(du -h "$backup_file" 2>/dev/null | cut -f1)
    echo -e "${GREEN}  ✓ Saved: $backup_name ($size)${RESET}"

    # Log to manifest
    echo "{\"node\":\"$node\",\"type\":\"$type\",\"file\":\"$backup_name.tar.gz\",\"size\":\"$size\",\"timestamp\":\"$(date -Iseconds)\"}" >> "$BACKUP_DIR/manifest.jsonl"
}

# Backup all nodes
backup_all() {
    local type="${1:-config}"

    echo -e "${PINK}╔══════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${PINK}║           💾 CLUSTER BACKUP - $type                          ║${RESET}"
    echo -e "${PINK}╚══════════════════════════════════════════════════════════════╝${RESET}"
    echo

    local success=0
    local failed=0

    for node in "${ALL_NODES[@]}"; do
        if backup_node "$node" "$type"; then
            ((success++))
        else
            ((failed++))
        fi
    done

    echo
    echo -e "${GREEN}Backup complete: $success success, $failed failed${RESET}"
}

# Create snapshot of cluster state
snapshot() {
    local name="${1:-snapshot_$(date +%Y%m%d_%H%M%S)}"

    echo -e "${PINK}=== CLUSTER SNAPSHOT: $name ===${RESET}"
    echo

    local snapshot_dir="$BACKUP_DIR/snapshots/$name"
    mkdir -p "$snapshot_dir"

    # Capture state from each node
    for node in "${ALL_NODES[@]}"; do
        echo -n "  $node: "

        if ! ssh -o ConnectTimeout=3 "$node" "echo ok" >/dev/null 2>&1; then
            echo -e "${YELLOW}offline${RESET}"
            continue
        fi

        # Capture system state
        ssh "$node" "
            echo '{\"hostname\":\"'$node'\",\"timestamp\":\"'$(date -Iseconds)'\",'
            echo '\"uptime\":\"'\$(uptime -p)'\",'
            echo '\"load\":'\$(cat /proc/loadavg | awk '{print \$1}')','
            echo '\"mem_percent\":'\$(free | awk '/Mem:/ {printf \"%.1f\", \$3/\$2*100}')','
            echo '\"disk_percent\":'\$(df / | awk 'NR==2 {gsub(/%/,\"\"); print \$5}')','
            echo '\"containers\":'\$(docker ps -q 2>/dev/null | wc -l)','
            echo '\"ollama_models\":'\$(curl -s http://localhost:11434/api/tags 2>/dev/null | jq '.models | length' || echo 0)'}'
        " > "$snapshot_dir/$node.json" 2>/dev/null

        echo -e "${GREEN}captured${RESET}"
    done

    # Capture cluster summary
    cat > "$snapshot_dir/summary.json" << EOF
{
    "name": "$name",
    "timestamp": "$(date -Iseconds)",
    "nodes": $(ls -1 "$snapshot_dir"/*.json 2>/dev/null | wc -l),
    "type": "snapshot"
}
EOF

    echo
    echo -e "${GREEN}Snapshot saved: $snapshot_dir${RESET}"
}

# Restore backup to node
restore() {
    local backup_file="$1"
    local node="$2"

    if [ ! -f "$backup_file" ]; then
        # Try finding in backup dir
        backup_file="$BACKUP_DIR/snapshots/$1"
    fi

    if [ ! -f "$backup_file" ]; then
        echo -e "${RED}Backup not found: $1${RESET}"
        return 1
    fi

    echo -e "${PINK}=== RESTORE ===${RESET}"
    echo "Backup: $backup_file"
    echo "Target: $node"
    echo

    echo -n "Are you sure? [y/N] "
    read -r confirm
    [[ "$confirm" =~ ^[Yy] ]] || return 1

    echo "Restoring..."
    cat "$backup_file" | ssh "$node" "sudo tar xzf - -C /"

    echo -e "${GREEN}Restore complete${RESET}"
}

# Sync models between nodes
sync_models() {
    local source="${1:-cecilia}"
    local target="$2"

    echo -e "${PINK}=== SYNC MODELS ===${RESET}"
    echo "Source: $source"
    echo

    if [ -n "$target" ]; then
        # Sync to specific node
        echo "Syncing to $target..."
        ssh "$source" "tar czf - /opt/ollama/models" | ssh "$target" "sudo tar xzf - -C /"
        echo -e "${GREEN}Done${RESET}"
    else
        # Sync to all nodes
        for node in "${ALL_NODES[@]}"; do
            [ "$node" = "$source" ] && continue

            echo -n "  $node: "
            if ! ssh -o ConnectTimeout=3 "$node" "echo ok" >/dev/null 2>&1; then
                echo -e "${YELLOW}offline${RESET}"
                continue
            fi

            ssh "$source" "tar czf - /opt/ollama/models 2>/dev/null" | ssh "$node" "sudo tar xzf - -C / 2>/dev/null"
            echo -e "${GREEN}synced${RESET}"
        done
    fi
}

# List backups
list() {
    echo -e "${PINK}=== BACKUP INVENTORY ===${RESET}"
    echo

    echo "Snapshots:"
    ls -lh "$BACKUP_DIR/snapshots/"*.tar.gz 2>/dev/null | awk '{print "  "$NF" ("$5")"}'

    echo
    echo "Cluster snapshots:"
    ls -d "$BACKUP_DIR/snapshots"/*/ 2>/dev/null | while read -r dir; do
        local name=$(basename "$dir")
        local nodes=$(ls -1 "$dir"/*.json 2>/dev/null | wc -l)
        echo "  $name ($nodes nodes)"
    done

    echo
    local total_size=$(du -sh "$BACKUP_DIR" 2>/dev/null | cut -f1)
    echo "Total backup size: $total_size"
}

# Cleanup old backups
cleanup() {
    local keep="${1:-5}"

    echo -e "${PINK}=== CLEANUP ===${RESET}"
    echo "Keeping last $keep backups per node"
    echo

    for node in "${ALL_NODES[@]}"; do
        local count=$(ls -1 "$BACKUP_DIR/snapshots/${node}_"*.tar.gz 2>/dev/null | wc -l)
        if [ "$count" -gt "$keep" ]; then
            local to_delete=$((count - keep))
            echo "  $node: removing $to_delete old backups"
            ls -1t "$BACKUP_DIR/snapshots/${node}_"*.tar.gz | tail -n "$to_delete" | xargs rm -f
        fi
    done

    echo -e "${GREEN}Cleanup complete${RESET}"
}

# Verify backup integrity
verify() {
    local backup_file="$1"

    if [ ! -f "$backup_file" ]; then
        backup_file="$BACKUP_DIR/snapshots/$1"
    fi

    echo -e "${PINK}=== VERIFY BACKUP ===${RESET}"
    echo "File: $backup_file"
    echo

    if tar tzf "$backup_file" >/dev/null 2>&1; then
        local files=$(tar tzf "$backup_file" | wc -l)
        local size=$(du -h "$backup_file" | cut -f1)
        echo -e "${GREEN}✓ Valid archive${RESET}"
        echo "  Files: $files"
        echo "  Size: $size"
    else
        echo -e "${RED}✗ Corrupt or invalid archive${RESET}"
        return 1
    fi
}

# Schedule automated backups
schedule() {
    local frequency="${1:-daily}"

    echo -e "${PINK}=== SCHEDULE BACKUP ===${RESET}"
    echo "Frequency: $frequency"
    echo

    local cron_cmd="$HOME/blackroad-cluster-backup.sh backup-all config"

    case "$frequency" in
        hourly)
            local cron_schedule="0 * * * *"
            ;;
        daily)
            local cron_schedule="0 2 * * *"
            ;;
        weekly)
            local cron_schedule="0 2 * * 0"
            ;;
        *)
            echo "Invalid frequency. Use: hourly, daily, weekly"
            return 1
            ;;
    esac

    # Add to crontab
    (crontab -l 2>/dev/null | grep -v "blackroad-cluster-backup"; echo "$cron_schedule $cron_cmd") | crontab -

    echo -e "${GREEN}Scheduled: $cron_schedule${RESET}"
    echo "Command: $cron_cmd"
}

# Help
help() {
    echo -e "${PINK}BlackRoad Cluster Backup${RESET}"
    echo
    echo "Distributed backup and snapshot system"
    echo
    echo "Commands:"
    echo "  backup <node> [type]   Backup single node (full/config/models/docker)"
    echo "  backup-all [type]      Backup all nodes"
    echo "  snapshot [name]        Create cluster snapshot"
    echo "  restore <file> <node>  Restore backup to node"
    echo "  sync-models [src] [dst]  Sync Ollama models"
    echo "  list                   List all backups"
    echo "  cleanup [keep]         Remove old backups"
    echo "  verify <file>          Verify backup integrity"
    echo "  schedule <freq>        Schedule automated backups"
    echo
    echo "Examples:"
    echo "  $0 backup cecilia models"
    echo "  $0 backup-all config"
    echo "  $0 snapshot pre-upgrade"
    echo "  $0 sync-models cecilia"
}

# Ensure initialized
[ -d "$BACKUP_DIR" ] || init >/dev/null

case "${1:-help}" in
    init)
        init
        ;;
    backup)
        backup_node "$2" "$3"
        ;;
    backup-all)
        backup_all "$2"
        ;;
    snapshot)
        snapshot "$2"
        ;;
    restore)
        restore "$2" "$3"
        ;;
    sync-models|sync)
        sync_models "$2" "$3"
        ;;
    list|ls)
        list
        ;;
    cleanup|clean)
        cleanup "$2"
        ;;
    verify|check)
        verify "$2"
        ;;
    schedule)
        schedule "$2"
        ;;
    *)
        help
        ;;
esac
