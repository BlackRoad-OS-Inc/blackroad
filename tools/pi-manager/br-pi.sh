#!/usr/bin/env zsh

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
MAGENTA='\033[0;35m'
NC='\033[0m'

DB_FILE="$HOME/.blackroad/pi-manager.db"

init_db() {
    mkdir -p "$(dirname "$DB_FILE")"
    sqlite3 "$DB_FILE" <<EOF
CREATE TABLE IF NOT EXISTS pis (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT UNIQUE,
    host TEXT,
    port INTEGER DEFAULT 22,
    username TEXT,
    description TEXT,
    last_seen INTEGER,
    created_at INTEGER
);

CREATE TABLE IF NOT EXISTS commands (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    pi_name TEXT,
    command TEXT,
    output TEXT,
    exit_code INTEGER,
    executed_at INTEGER
);

CREATE TABLE IF NOT EXISTS deployments (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    pi_name TEXT,
    source_path TEXT,
    dest_path TEXT,
    deployed_at INTEGER
);

CREATE TABLE IF NOT EXISTS tasks (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    pi_name TEXT,
    project_path TEXT,
    task_name TEXT,
    task_command TEXT,
    status TEXT,
    output TEXT,
    started_at INTEGER,
    completed_at INTEGER
);
EOF
}

cmd_add() {
    init_db
    local name="$1"
    local connection="$2"
    local description="$3"
    
    if [[ -z "$name" || -z "$connection" ]]; then
        echo -e "${RED}❌ Usage: br pi add <name> <user@host[:port]> [description]${NC}"
        echo "Example: br pi add pi1 pi@192.168.1.100"
        echo "         br pi add pi2 ubuntu@raspberrypi.local:2222 'Living Room Pi'"
        exit 1
    fi
    
    # Parse connection string
    local username host port
    if [[ "$connection" =~ ^([^@]+)@([^:]+):?([0-9]*)$ ]]; then
        username="${match[1]}"
        host="${match[2]}"
        port="${match[3]:-22}"
    else
        echo -e "${RED}❌ Invalid format. Use: user@host[:port]${NC}"
        exit 1
    fi
    
    sqlite3 "$DB_FILE" "INSERT OR REPLACE INTO pis (name, host, port, username, description, created_at) VALUES ('$name', '$host', $port, '$username', '$description', $(date +%s));"
    
    echo -e "${GREEN}✓ Added Pi: $name${NC}"
    echo -e "  ${CYAN}→${NC} $username@$host:$port"
    [[ -n "$description" ]] && echo -e "  ${BLUE}📝${NC} $description"
}

cmd_list() {
    init_db
    echo -e "${CYAN}🥧 Raspberry Pis:${NC}\n"
    
    local count=0
    sqlite3 -separator $'\t' "$DB_FILE" "SELECT name, username, host, port, description, last_seen FROM pis ORDER BY name;" | while IFS=$'\t' read -r name username host port desc last_seen; do
        count=$((count + 1))
        echo -e "${MAGENTA}●${NC} ${GREEN}$name${NC}"
        echo -e "  ${CYAN}→${NC} $username@$host:$port"
        [[ -n "$desc" ]] && echo -e "  ${BLUE}📝${NC} $desc"
        
        if [[ -n "$last_seen" && "$last_seen" != "0" ]]; then
            local time_ago=$(($(date +%s) - last_seen))
            if [[ $time_ago -lt 300 ]]; then
                echo -e "  ${GREEN}✓${NC} Online (seen ${time_ago}s ago)"
            else
                echo -e "  ${YELLOW}⚠${NC} Last seen: $(date -r "$last_seen" "+%Y-%m-%d %H:%M")"
            fi
        fi
        echo ""
    done
}

cmd_connect() {
    init_db
    local name="$1"
    
    if [[ -z "$name" ]]; then
        echo -e "${RED}❌ Specify Pi name${NC}"
        exit 1
    fi
    
    local result=$(sqlite3 -separator '|' "$DB_FILE" "SELECT username, host, port FROM pis WHERE name='$name';")
    
    if [[ -z "$result" ]]; then
        echo -e "${RED}❌ Pi '$name' not found${NC}"
        echo "Run: br pi list"
        exit 1
    fi
    
    IFS='|' read -r username host port <<< "$result"
    
    echo -e "${CYAN}🔌 Connecting to $name ($username@$host:$port)...${NC}\n"
    
    sqlite3 "$DB_FILE" "UPDATE pis SET last_seen=$(date +%s) WHERE name='$name';"
    
    ssh -p "$port" "$username@$host"
}

cmd_exec() {
    init_db
    local name="$1"
    shift
    local command="$*"
    
    if [[ -z "$name" || -z "$command" ]]; then
        echo -e "${RED}❌ Usage: br pi exec <name> <command>${NC}"
        echo "Example: br pi exec pi1 'uptime'"
        exit 1
    fi
    
    local result=$(sqlite3 -separator '|' "$DB_FILE" "SELECT username, host, port FROM pis WHERE name='$name';")
    
    if [[ -z "$result" ]]; then
        echo -e "${RED}❌ Pi '$name' not found${NC}"
        exit 1
    fi
    
    IFS='|' read -r username host port <<< "$result"
    
    echo -e "${CYAN}⚡ Executing on $name: ${YELLOW}$command${NC}\n"
    
    local output=$(ssh -p "$port" "$username@$host" "$command" 2>&1)
    local exit_code=$?
    
    echo "$output"
    
    sqlite3 "$DB_FILE" "INSERT INTO commands (pi_name, command, output, exit_code, executed_at) VALUES ('$name', '$(echo "$command" | sed "s/'/''/g")', '$(echo "$output" | sed "s/'/''/g")', $exit_code, $(date +%s));"
    sqlite3 "$DB_FILE" "UPDATE pis SET last_seen=$(date +%s) WHERE name='$name';"
    
    if [[ $exit_code -eq 0 ]]; then
        echo -e "\n${GREEN}✓ Success${NC}"
    else
        echo -e "\n${RED}✗ Failed (exit code: $exit_code)${NC}"
    fi
}

cmd_status() {
    init_db
    local name="$1"
    
    if [[ -z "$name" ]]; then
        echo -e "${RED}❌ Specify Pi name${NC}"
        echo "Use: br pi status <name>"
        exit 1
    fi
    
    local result=$(sqlite3 -separator '|' "$DB_FILE" "SELECT username, host, port FROM pis WHERE name='$name';")
    
    if [[ -z "$result" ]]; then
        echo -e "${RED}❌ Pi '$name' not found${NC}"
        exit 1
    fi
    
    IFS='|' read -r username host port <<< "$result"
    
    echo -e "${CYAN}📊 Status for $name:${NC}\n"
    
    # Check connectivity
    if ssh -p "$port" -o ConnectTimeout=3 -o BatchMode=yes "$username@$host" "exit" 2>/dev/null; then
        echo -e "${GREEN}✓ Online${NC}\n"
        
        # Get system info
        local info=$(ssh -p "$port" "$username@$host" '
            echo "HOSTNAME=$(hostname)"
            echo "UPTIME=$(uptime -p 2>/dev/null || uptime)"
            echo "CPU=$(top -bn1 | grep "Cpu(s)" | awk "{print \$2}" | cut -d"%" -f1 2>/dev/null || echo "N/A")"
            echo "MEMORY=$(free -m | awk "NR==2{printf \"%.1f%%\", \$3*100/\$2 }")"
            echo "DISK=$(df -h / | awk "NR==2{print \$5}")"
            echo "TEMP=$(vcgencmd measure_temp 2>/dev/null | cut -d"=" -f2 || echo "N/A")"
        ' 2>/dev/null)
        
        echo "$info" | while IFS='=' read -r key value; do
            case "$key" in
                HOSTNAME) echo -e "${BLUE}🖥️  Hostname:${NC} $value" ;;
                UPTIME)   echo -e "${BLUE}⏱️  Uptime:${NC} $value" ;;
                CPU)      echo -e "${BLUE}⚡ CPU:${NC} ${value}%" ;;
                MEMORY)   echo -e "${BLUE}💾 Memory:${NC} $value" ;;
                DISK)     echo -e "${BLUE}💿 Disk:${NC} $value" ;;
                TEMP)     echo -e "${BLUE}🌡️  Temp:${NC} $value" ;;
            esac
        done
        
        sqlite3 "$DB_FILE" "UPDATE pis SET last_seen=$(date +%s) WHERE name='$name';"
    else
        echo -e "${RED}✗ Offline or unreachable${NC}"
    fi
}

cmd_deploy() {
    init_db
    local name="$1"
    local source="$2"
    local dest="$3"
    
    if [[ -z "$name" || -z "$source" || -z "$dest" ]]; then
        echo -e "${RED}❌ Usage: br pi deploy <name> <source> <dest>${NC}"
        echo "Example: br pi deploy pi1 ./app /home/pi/app"
        exit 1
    fi
    
    if [[ ! -e "$source" ]]; then
        echo -e "${RED}❌ Source not found: $source${NC}"
        exit 1
    fi
    
    local result=$(sqlite3 -separator '|' "$DB_FILE" "SELECT username, host, port FROM pis WHERE name='$name';")
    
    if [[ -z "$result" ]]; then
        echo -e "${RED}❌ Pi '$name' not found${NC}"
        exit 1
    fi
    
    IFS='|' read -r username host port <<< "$result"
    
    echo -e "${CYAN}🚀 Deploying to $name...${NC}"
    echo -e "  ${BLUE}Source:${NC} $source"
    echo -e "  ${BLUE}Dest:${NC} $dest"
    echo ""
    
    scp -P "$port" -r "$source" "$username@$host:$dest"
    
    if [[ $? -eq 0 ]]; then
        echo -e "\n${GREEN}✓ Deployed successfully${NC}"
        sqlite3 "$DB_FILE" "INSERT INTO deployments (pi_name, source_path, dest_path, deployed_at) VALUES ('$name', '$source', '$dest', $(date +%s));"
        sqlite3 "$DB_FILE" "UPDATE pis SET last_seen=$(date +%s) WHERE name='$name';"
    else
        echo -e "\n${RED}✗ Deployment failed${NC}"
        exit 1
    fi
}

cmd_all() {
    init_db
    shift
    local command="$*"
    
    if [[ -z "$command" ]]; then
        echo -e "${RED}❌ Usage: br pi all <command>${NC}"
        echo "Example: br pi all 'sudo apt update'"
        exit 1
    fi
    
    echo -e "${CYAN}📡 Running on all Pis: ${YELLOW}$command${NC}\n"
    
    sqlite3 -separator $'\t' "$DB_FILE" "SELECT name FROM pis ORDER BY name;" | while IFS=$'\t' read -r name; do
        echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${GREEN}Pi: $name${NC}"
        echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        
        local result=$(sqlite3 -separator '|' "$DB_FILE" "SELECT username, host, port FROM pis WHERE name='$name';")
        IFS='|' read -r username host port <<< "$result"
        
        ssh -p "$port" -o ConnectTimeout=5 "$username@$host" "$command" 2>&1
        
        if [[ $? -eq 0 ]]; then
            echo -e "${GREEN}✓ $name: Success${NC}\n"
        else
            echo -e "${RED}✗ $name: Failed${NC}\n"
        fi
    done
}

cmd_discover() {
    echo -e "${CYAN}🔍 Discovering Raspberry Pis on network...${NC}\n"
    
    if ! command -v nmap &> /dev/null; then
        echo -e "${YELLOW}⚠️  nmap not installed${NC}"
        echo "Install: brew install nmap"
        echo ""
        echo "Alternative: Checking common addresses..."
        
        # Try common Pi addresses
        for ip in raspberrypi.local pi.local 192.168.1.{1..254}; do
            if ping -c 1 -W 1 "$ip" &> /dev/null 2>&1; then
                echo -e "${GREEN}✓ Found: $ip${NC}"
            fi
        done
        return
    fi
    
    # Get local network
    local network=$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null)
    
    if [[ -z "$network" ]]; then
        echo -e "${RED}❌ Could not determine network${NC}"
        exit 1
    fi
    
    local subnet=$(echo "$network" | cut -d'.' -f1-3)
    
    echo "Scanning ${subnet}.0/24..."
    nmap -sn "${subnet}.0/24" | grep -B 2 "Raspberry Pi" | grep "Nmap scan" | awk '{print $5}'
}

cmd_remove() {
    init_db
    local name="$1"
    
    if [[ -z "$name" ]]; then
        echo -e "${RED}❌ Specify Pi name${NC}"
        exit 1
    fi
    
    sqlite3 "$DB_FILE" "DELETE FROM pis WHERE name='$name';"
    echo -e "${GREEN}✓ Removed Pi: $name${NC}"
}

cmd_history() {
    init_db
    local name="${1:-all}"
    
    echo -e "${CYAN}📜 Command History:${NC}\n"
    
    local where=""
    [[ "$name" != "all" ]] && where="WHERE pi_name='$name'"
    
    sqlite3 -separator $'\t' "$DB_FILE" "SELECT pi_name, command, exit_code, datetime(executed_at, 'unixepoch') FROM commands $where ORDER BY executed_at DESC LIMIT 30;" | while IFS=$'\t' read -r pi cmd exit_code time; do
        if [[ "$exit_code" == "0" ]]; then
            echo -e "${GREEN}✓${NC} ${BLUE}$pi${NC} - $time"
        else
            echo -e "${RED}✗${NC} ${BLUE}$pi${NC} - $time"
        fi
        echo -e "  ${YELLOW}$cmd${NC}"
        echo ""
    done
}

cmd_task_detect() {
    init_db
    local name="$1"
    local project_path="$2"
    
    if [[ -z "$name" || -z "$project_path" ]]; then
        echo -e "${RED}❌ Usage: br pi task detect <name> <project-path>${NC}"
        echo "Example: br pi task detect pi1 /home/pi/myapp"
        exit 1
    fi
    
    local result=$(sqlite3 -separator '|' "$DB_FILE" "SELECT username, host, port FROM pis WHERE name='$name';")
    
    if [[ -z "$result" ]]; then
        echo -e "${RED}❌ Pi '$name' not found${NC}"
        exit 1
    fi
    
    IFS='|' read -r username host port <<< "$result"
    
    echo -e "${CYAN}🔍 Detecting tasks on $name at $project_path...${NC}\n"
    
    # Check for different project types
    local tasks=$(ssh -p "$port" "$username@$host" "cd '$project_path' 2>/dev/null && {
        if [ -f package.json ]; then
            echo 'TYPE:npm'
            cat package.json | grep -A 50 '\"scripts\"' | grep '\"' | head -20
        elif [ -f Makefile ]; then
            echo 'TYPE:make'
            grep '^[a-zA-Z_-]*:' Makefile | cut -d':' -f1
        elif [ -f Cargo.toml ]; then
            echo 'TYPE:cargo'
            echo 'build\ntest\nrun\nclean'
        elif [ -f go.mod ]; then
            echo 'TYPE:go'
            echo 'build\ntest\nrun'
        elif [ -f pyproject.toml ] || [ -f setup.py ]; then
            echo 'TYPE:python'
            echo 'install\ntest\nrun'
        else
            echo 'TYPE:none'
        fi
    }" 2>/dev/null)
    
    if [[ -z "$tasks" ]]; then
        echo -e "${RED}✗ Could not access project at $project_path${NC}"
        exit 1
    fi
    
    local project_type=$(echo "$tasks" | grep "^TYPE:" | cut -d: -f2)
    
    case "$project_type" in
        npm)
            echo -e "${BLUE}📦 Node.js Project (npm)${NC}\n"
            echo "$tasks" | grep -v "^TYPE:" | sed 's/[",]//g' | awk '{print $1}' | grep -v "^$" | while read -r task; do
                echo -e "${GREEN}▸${NC} $task"
            done
            ;;
        make)
            echo -e "${BLUE}🔨 Makefile Project${NC}\n"
            echo "$tasks" | grep -v "^TYPE:" | while read -r task; do
                echo -e "${GREEN}▸${NC} $task"
            done
            ;;
        cargo)
            echo -e "${BLUE}🦀 Rust Project (Cargo)${NC}\n"
            echo "$tasks" | grep -v "^TYPE:" | while read -r task; do
                echo -e "${GREEN}▸${NC} $task"
            done
            ;;
        go)
            echo -e "${BLUE}🐹 Go Project${NC}\n"
            echo "$tasks" | grep -v "^TYPE:" | while read -r task; do
                echo -e "${GREEN}▸${NC} $task"
            done
            ;;
        python)
            echo -e "${BLUE}🐍 Python Project${NC}\n"
            echo "$tasks" | grep -v "^TYPE:" | while read -r task; do
                echo -e "${GREEN}▸${NC} $task"
            done
            ;;
        *)
            echo -e "${YELLOW}⚠️  No recognizable project found${NC}"
            ;;
    esac
    
    sqlite3 "$DB_FILE" "UPDATE pis SET last_seen=$(date +%s) WHERE name='$name';"
}

cmd_task_run() {
    init_db
    local name="$1"
    local project_path="$2"
    local task_name="$3"
    
    if [[ -z "$name" || -z "$project_path" || -z "$task_name" ]]; then
        echo -e "${RED}❌ Usage: br pi task run <name> <project-path> <task>${NC}"
        echo "Example: br pi task run pi1 /home/pi/myapp build"
        exit 1
    fi
    
    local result=$(sqlite3 -separator '|' "$DB_FILE" "SELECT username, host, port FROM pis WHERE name='$name';")
    
    if [[ -z "$result" ]]; then
        echo -e "${RED}❌ Pi '$name' not found${NC}"
        exit 1
    fi
    
    IFS='|' read -r username host port <<< "$result"
    
    echo -e "${CYAN}⚡ Running task '$task_name' on $name...${NC}\n"
    
    local started_at=$(date +%s)
    
    # Determine command based on project type
    local run_cmd=$(ssh -p "$port" "$username@$host" "cd '$project_path' 2>/dev/null && {
        if [ -f package.json ]; then
            echo 'npm run $task_name'
        elif [ -f Makefile ]; then
            echo 'make $task_name'
        elif [ -f Cargo.toml ]; then
            echo 'cargo $task_name'
        elif [ -f go.mod ]; then
            echo 'go $task_name'
        else
            echo '$task_name'
        fi
    }")
    
    run_cmd=$(echo "$run_cmd" | sed "s/\$task_name/$task_name/g")
    
    echo -e "${BLUE}Command:${NC} $run_cmd"
    echo ""
    
    local output=$(ssh -p "$port" "$username@$host" "cd '$project_path' && $run_cmd" 2>&1)
    local exit_code=$?
    local completed_at=$(date +%s)
    
    echo "$output"
    
    # Save to database
    sqlite3 "$DB_FILE" "INSERT INTO tasks (pi_name, project_path, task_name, task_command, status, output, started_at, completed_at) VALUES ('$name', '$project_path', '$task_name', '$(echo "$run_cmd" | sed "s/'/''/g")', '$([ $exit_code -eq 0 ] && echo "success" || echo "failed")', '$(echo "$output" | sed "s/'/''/g")', $started_at, $completed_at);"
    
    if [[ $exit_code -eq 0 ]]; then
        echo -e "\n${GREEN}✓ Task completed successfully${NC}"
    else
        echo -e "\n${RED}✗ Task failed (exit code: $exit_code)${NC}"
        exit 1
    fi
    
    sqlite3 "$DB_FILE" "UPDATE pis SET last_seen=$(date +%s) WHERE name='$name';"
}

cmd_task_deploy_run() {
    init_db
    local name="$1"
    local source="$2"
    local dest="$3"
    local task="$4"
    
    if [[ -z "$name" || -z "$source" || -z "$dest" || -z "$task" ]]; then
        echo -e "${RED}❌ Usage: br pi task deploy <name> <source> <dest> <task>${NC}"
        echo "Example: br pi task deploy pi1 ./myapp /home/pi/myapp build"
        exit 1
    fi
    
    echo -e "${CYAN}🚀 Deploy & Run Pipeline${NC}\n"
    
    # Step 1: Deploy
    echo -e "${BLUE}[1/3]${NC} Deploying code..."
    cmd_deploy "$name" "$source" "$dest"
    
    if [[ $? -ne 0 ]]; then
        echo -e "${RED}✗ Deployment failed${NC}"
        exit 1
    fi
    
    # Step 2: Install dependencies (if applicable)
    echo -e "\n${BLUE}[2/3]${NC} Installing dependencies..."
    local result=$(sqlite3 -separator '|' "$DB_FILE" "SELECT username, host, port FROM pis WHERE name='$name';")
    IFS='|' read -r username host port <<< "$result"
    
    ssh -p "$port" "$username@$host" "cd '$dest' && {
        if [ -f package.json ]; then
            npm install
        elif [ -f requirements.txt ]; then
            pip3 install -r requirements.txt
        elif [ -f Cargo.toml ]; then
            cargo build
        fi
    } 2>&1" | sed 's/^/  /'
    
    # Step 3: Run task
    echo -e "\n${BLUE}[3/3]${NC} Running task..."
    cmd_task_run "$name" "$dest" "$task"
}

cmd_task_background() {
    init_db
    local name="$1"
    local project_path="$2"
    local task_name="$3"
    
    if [[ -z "$name" || -z "$project_path" || -z "$task_name" ]]; then
        echo -e "${RED}❌ Usage: br pi task background <name> <project-path> <task>${NC}"
        echo "Example: br pi task background pi1 /home/pi/server start"
        exit 1
    fi
    
    local result=$(sqlite3 -separator '|' "$DB_FILE" "SELECT username, host, port FROM pis WHERE name='$name';")
    
    if [[ -z "$result" ]]; then
        echo -e "${RED}❌ Pi '$name' not found${NC}"
        exit 1
    fi
    
    IFS='|' read -r username host port <<< "$result"
    
    echo -e "${CYAN}🔄 Starting task '$task_name' in background on $name...${NC}\n"
    
    # Determine command based on project type
    local run_cmd=$(ssh -p "$port" "$username@$host" "cd '$project_path' 2>/dev/null && {
        if [ -f package.json ]; then
            echo 'nohup npm run $task_name > /tmp/br-task-$task_name.log 2>&1 &'
        elif [ -f Makefile ]; then
            echo 'nohup make $task_name > /tmp/br-task-$task_name.log 2>&1 &'
        else
            echo 'nohup $task_name > /tmp/br-task-$task_name.log 2>&1 &'
        fi
    }")
    
    run_cmd=$(echo "$run_cmd" | sed "s/\$task_name/$task_name/g")
    
    ssh -p "$port" "$username@$host" "cd '$project_path' && $run_cmd"
    
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}✓ Task started in background${NC}"
        echo -e "${BLUE}Logs:${NC} /tmp/br-task-$task_name.log on $name"
        echo -e "${CYAN}Check:${NC} br pi exec $name 'tail -f /tmp/br-task-$task_name.log'"
    else
        echo -e "${RED}✗ Failed to start task${NC}"
        exit 1
    fi
}

cmd_task_logs() {
    init_db
    local name="$1"
    local task_name="${2:-all}"
    
    if [[ -z "$name" ]]; then
        echo -e "${RED}❌ Usage: br pi task logs <name> [task]${NC}"
        exit 1
    fi
    
    echo -e "${CYAN}📜 Task History on $name:${NC}\n"
    
    local where="WHERE pi_name='$name'"
    [[ "$task_name" != "all" ]] && where="$where AND task_name='$task_name'"
    
    sqlite3 -separator $'\t' "$DB_FILE" "SELECT task_name, status, datetime(started_at, 'unixepoch'), datetime(completed_at, 'unixepoch') FROM tasks $where ORDER BY started_at DESC LIMIT 20;" | while IFS=$'\t' read -r task status started completed; do
        if [[ "$status" == "success" ]]; then
            echo -e "${GREEN}✓${NC} $task - $started to $completed"
        else
            echo -e "${RED}✗${NC} $task - $started to $completed"
        fi
    done
}

cmd_history() {
    init_db
    local name="${1:-all}"
    
    echo -e "${CYAN}📜 Command History:${NC}\n"
    
    local where=""
    [[ "$name" != "all" ]] && where="WHERE pi_name='$name'"
    
    sqlite3 -separator $'\t' "$DB_FILE" "SELECT pi_name, command, exit_code, datetime(executed_at, 'unixepoch') FROM commands $where ORDER BY executed_at DESC LIMIT 30;" | while IFS=$'\t' read -r pi cmd exit_code time; do
        if [[ "$exit_code" == "0" ]]; then
            echo -e "${GREEN}✓${NC} ${BLUE}$pi${NC} - $time"
        else
            echo -e "${RED}✗${NC} ${BLUE}$pi${NC} - $time"
        fi
        echo -e "  ${YELLOW}$cmd${NC}"
        echo ""
    done
}

cmd_help() {
    cat << 'EOF'
🥧 Raspberry Pi Manager

USAGE:
  br pi <command> [options]

CONNECTION MANAGEMENT:
  add <name> <user@host[:port]> [desc]  Add a Pi
  list                                   List all Pis
  connect <name>                         SSH to Pi
  remove <name>                          Remove Pi

OPERATIONS:
  exec <name> <command>      Execute command on Pi
  status <name>              Show Pi status (CPU, memory, temp)
  deploy <name> <src> <dst>  Deploy files/code to Pi
  all <command>              Run command on all Pis

TASK MANAGEMENT:
  task detect <name> <path>         Detect available tasks
  task run <name> <path> <task>     Run a task
  task deploy <name> <src> <dst> <task>  Deploy & run
  task background <name> <path> <task>   Run in background
  task logs <name> [task]           Show task history

DISCOVERY:
  discover                   Scan network for Pis
  history [name]             Show command history

EXAMPLES:
  # Add Pis
  br pi add pi1 pi@192.168.1.100
  br pi add pi2 ubuntu@raspberrypi.local:2222 "Living Room"
  
  # Connect and manage
  br pi list
  br pi connect pi1
  br pi status pi1
  
  # Execute commands
  br pi exec pi1 "uptime"
  br pi exec pi1 "vcgencmd measure_temp"
  br pi all "sudo apt update"
  
  # Deploy code
  br pi deploy pi1 ./myapp /home/pi/apps/
  
  # Task Management
  br pi task detect pi1 /home/pi/myapp
  br pi task run pi1 /home/pi/myapp build
  br pi task deploy pi1 ./myapp /home/pi/myapp start
  br pi task background pi1 /home/pi/server start
  br pi task logs pi1
  
  # Network discovery
  br pi discover

MONITORING:
  Status shows:
  - CPU usage
  - Memory usage
  - Disk usage
  - Temperature (if available)
  - Uptime

TIPS:
  - Use SSH keys for passwordless access
  - Run 'ssh-copy-id user@host' to setup keys
  - Use 'all' to batch update multiple Pis
  - Status shows vcgencmd temp if available

EOF
}

# Main dispatch
init_db

case "${1:-help}" in
    add) cmd_add "${@:2}" ;;
    list|ls) cmd_list ;;
    connect|ssh) cmd_connect "${@:2}" ;;
    exec|run) cmd_exec "${@:2}" ;;
    status|stat) cmd_status "${@:2}" ;;
    deploy) cmd_deploy "${@:2}" ;;
    all|batch) cmd_all "$@" ;;
    discover|scan) cmd_discover ;;
    remove|rm) cmd_remove "${@:2}" ;;
    history|hist) cmd_history "${@:2}" ;;
    task)
        case "${2:-help}" in
            detect) cmd_task_detect "${@:3}" ;;
            run) cmd_task_run "${@:3}" ;;
            deploy) cmd_task_deploy_run "${@:3}" ;;
            background|bg) cmd_task_background "${@:3}" ;;
            logs) cmd_task_logs "${@:3}" ;;
            *)
                echo -e "${RED}❌ Unknown task command: ${2:-help}${NC}"
                echo "Use: detect, run, deploy, background, logs"
                exit 1
                ;;
        esac
        ;;
    help|--help|-h) cmd_help ;;
    *)
        echo -e "${RED}❌ Unknown command: $1${NC}"
        cmd_help
        exit 1
        ;;
esac
