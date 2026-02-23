#!/bin/zsh
# BR env-diff — Compare .env files across environments
# Detects missing keys, value differences, extra keys

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'
BLUE='\033[0;34m'; BOLD='\033[1m'; NC='\033[0m'

DB="$HOME/.blackroad/env-diff.db"

init_db() {
    mkdir -p "$(dirname "$DB")"
    sqlite3 "$DB" <<'SQL'
CREATE TABLE IF NOT EXISTS snapshots (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    env_name TEXT NOT NULL,
    key_name TEXT NOT NULL,
    value_hash TEXT,
    has_value INTEGER DEFAULT 1,
    ts TEXT DEFAULT (datetime('now'))
);
CREATE TABLE IF NOT EXISTS diff_history (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    env_a TEXT,
    env_b TEXT,
    missing_in_b INTEGER DEFAULT 0,
    missing_in_a INTEGER DEFAULT 0,
    value_diffs INTEGER DEFAULT 0,
    ts TEXT DEFAULT (datetime('now'))
);
SQL
}

parse_env_file() {
    local file="$1"
    local -A result=()
    while IFS='=' read -r key val; do
        [[ "$key" =~ ^[[:space:]]*# ]] && continue
        [[ -z "$key" ]] && continue
        key=$(echo "$key" | tr -d '[:space:]')
        result[$key]="$val"
    done < "$file"
    # Return as key=value pairs
    for k in "${(k)result[@]}"; do
        echo "$k=${result[$k]}"
    done
}

cmd_diff() {
    local file_a="$1"
    local file_b="$2"
    local show_values="${3:-}"

    [[ -z "$file_a" || -z "$file_b" ]] && echo -e "${RED}✗ Usage: br env-diff <file-a> <file-b>${NC}" && return 1
    [[ ! -f "$file_a" ]] && echo -e "${RED}✗ File not found: $file_a${NC}" && return 1
    [[ ! -f "$file_b" ]] && echo -e "${RED}✗ File not found: $file_b${NC}" && return 1

    local name_a=$(basename "$file_a")
    local name_b=$(basename "$file_b")

    echo -e "${BOLD}${BLUE}🔍 env-diff${NC}: ${CYAN}$name_a${NC} ↔ ${CYAN}$name_b${NC}\n"

    # Build associative arrays
    local -A keys_a=()
    local -A keys_b=()

    while IFS='=' read -r k v; do
        [[ -n "$k" ]] && keys_a[$k]="$v"
    done < <(grep -v '^\s*#' "$file_a" | grep '=' | sed 's/[[:space:]]*=[[:space:]]*/=/' | grep -v '^[[:space:]]*$')

    while IFS='=' read -r k v; do
        [[ -n "$k" ]] && keys_b[$k]="$v"
    done < <(grep -v '^\s*#' "$file_b" | grep '=' | sed 's/[[:space:]]*=[[:space:]]*/=/' | grep -v '^[[:space:]]*$')

    local missing_in_b=() missing_in_a=() value_diffs=() matching=()

    # Keys in A not in B
    for k in "${(k)keys_a[@]}"; do
        if [[ -z "${keys_b[$k]+x}" ]]; then
            missing_in_b+=("$k")
        elif [[ "${keys_a[$k]}" != "${keys_b[$k]}" ]]; then
            value_diffs+=("$k")
        else
            matching+=("$k")
        fi
    done

    # Keys in B not in A
    for k in "${(k)keys_b[@]}"; do
        [[ -z "${keys_a[$k]+x}" ]] && missing_in_a+=("$k")
    done

    # Sort arrays
    missing_in_b=(${(o)missing_in_b})
    missing_in_a=(${(o)missing_in_a})
    value_diffs=(${(o)value_diffs})

    # Show results
    if [[ ${#missing_in_b[@]} -gt 0 ]]; then
        echo -e "  ${RED}✗ Missing in ${name_b}${NC} (${#missing_in_b[@]})"
        for k in "${missing_in_b[@]}"; do
            local val_a="${keys_a[$k]}"
            local masked=$(echo "$val_a" | sed 's/./*/g' | cut -c1-6)
            [[ -n "$show_values" ]] && echo -e "    ${RED}-${NC} $k=${val_a}" || echo -e "    ${RED}-${NC} $k"
        done
        echo ""
    fi

    if [[ ${#missing_in_a[@]} -gt 0 ]]; then
        echo -e "  ${CYAN}+ Extra in ${name_b}${NC} (${#missing_in_a[@]})"
        for k in "${missing_in_a[@]}"; do
            [[ -n "$show_values" ]] && echo -e "    ${CYAN}+${NC} $k=${keys_b[$k]}" || echo -e "    ${CYAN}+${NC} $k"
        done
        echo ""
    fi

    if [[ ${#value_diffs[@]} -gt 0 ]]; then
        echo -e "  ${YELLOW}~ Value differences${NC} (${#value_diffs[@]})"
        for k in "${value_diffs[@]}"; do
            if [[ -n "$show_values" ]]; then
                echo -e "    ${YELLOW}~${NC} $k"
                echo -e "      ${RED}< ${keys_a[$k]}${NC}"
                echo -e "      ${GREEN}> ${keys_b[$k]}${NC}"
            else
                echo -e "    ${YELLOW}~${NC} $k ${CYAN}(values differ)${NC}"
            fi
        done
        echo ""
    fi

    if [[ ${#matching[@]} -gt 0 ]]; then
        echo -e "  ${GREEN}✓ Matching${NC} (${#matching[@]} keys identical)"
        echo ""
    fi

    # Summary
    local total_a=${#keys_a[@]} total_b=${#keys_b[@]}
    echo -e "  ${BOLD}Summary:${NC}"
    echo -e "  $name_a: ${total_a} keys  |  $name_b: ${total_b} keys"
    echo -e "  ${RED}Missing: ${#missing_in_b[@]}${NC}  ${CYAN}Extra: ${#missing_in_a[@]}${NC}  ${YELLOW}Different: ${#value_diffs[@]}${NC}  ${GREEN}Match: ${#matching[@]}${NC}"

    # Save to history
    sqlite3 "$DB" "INSERT INTO diff_history (env_a, env_b, missing_in_b, missing_in_a, value_diffs) VALUES ('$name_a', '$name_b', ${#missing_in_b[@]}, ${#missing_in_a[@]}, ${#value_diffs[@]});" 2>/dev/null

    # Exit code: 0 if identical, 1 if differences
    [[ ${#missing_in_b[@]} -eq 0 && ${#missing_in_a[@]} -eq 0 && ${#value_diffs[@]} -eq 0 ]] && return 0 || return 1
}

cmd_audit() {
    # Audit a single env file for common issues
    local file="${1:-.env}"
    [[ ! -f "$file" ]] && echo -e "${RED}✗ File not found: $file${NC}" && return 1

    echo -e "${BOLD}${BLUE}🔍 .env Audit${NC}: ${CYAN}$file${NC}\n"

    local issues=0

    while IFS='=' read -r key val; do
        [[ "$key" =~ ^[[:space:]]*# ]] && continue
        [[ -z "$key" ]] && continue
        key=$(echo "$key" | tr -d '[:space:]')
        val="${val#\"}" val="${val%\"}" val="${val#\'}" val="${val%\'}"

        # Check for empty values
        if [[ -z "$val" ]]; then
            echo -e "  ${YELLOW}⚠${NC} ${BOLD}$key${NC}: empty value"
            ((issues++))
        fi

        # Check for placeholder values
        if echo "$val" | grep -qiE 'todo|fixme|change.me|your.*key|placeholder|xxx|<.*>|\.\.\.|changeme'; then
            echo -e "  ${RED}✗${NC} ${BOLD}$key${NC}: looks like placeholder: ${YELLOW}${val:0:30}${NC}"
            ((issues++))
        fi

        # Check for localhost in production-like files
        if echo "$file" | grep -qi 'prod' && echo "$val" | grep -qi 'localhost\|127\.0\.0\.1'; then
            echo -e "  ${RED}✗${NC} ${BOLD}$key${NC}: localhost in production env"
            ((issues++))
        fi

        # Check for very short likely-invalid secrets
        if echo "$key" | grep -qiE 'secret|token|key|pass' && [[ ${#val} -gt 0 && ${#val} -lt 8 ]]; then
            echo -e "  ${YELLOW}⚠${NC} ${BOLD}$key${NC}: suspiciously short secret (${#val} chars)"
            ((issues++))
        fi
    done < "$file"

    local total=$(grep -c '^[^#].*=' "$file" 2>/dev/null || echo 0)
    echo ""
    echo -e "  ${BOLD}Keys:${NC} $total  ${BOLD}Issues:${NC} $([ $issues -eq 0 ] && echo "${GREEN}${issues}${NC}" || echo "${RED}${issues}${NC}")"
    [[ $issues -eq 0 ]] && echo -e "  ${GREEN}✓ No issues found${NC}"
}

cmd_template() {
    # Generate a .env.example from a .env file (masks values)
    local file="${1:-.env}"
    local out="${2:-.env.example}"
    [[ ! -f "$file" ]] && echo -e "${RED}✗ File not found: $file${NC}" && return 1

    echo "# Generated by br env-diff template — $(date)" > "$out"
    echo "# Copy to .env and fill in values" >> "$out"
    echo "" >> "$out"

    while IFS='=' read -r key val; do
        if [[ "$key" =~ ^[[:space:]]*# || -z "$key" ]]; then
            echo "$key" >> "$out"
            continue
        fi
        key=$(echo "$key" | tr -d '[:space:]')
        # Mask actual values
        if echo "$key" | grep -qiE 'secret|token|key|pass|pwd|auth|cred'; then
            echo "${key}=your_${key,,}_here" >> "$out"
        else
            echo "${key}=${val}" >> "$out"
        fi
    done < "$file"

    echo -e "${GREEN}✓${NC} Template saved: $out"
    echo -e "  $(grep -c '=' "$out") keys exported (secrets masked)"
}

cmd_sync_check() {
    # Check current process env vs a .env file
    local file="${1:-.env}"
    [[ ! -f "$file" ]] && echo -e "${RED}✗ File not found: $file${NC}" && return 1

    echo -e "${BOLD}${BLUE}🔍 Env Sync Check${NC}: $file ↔ current process\n"

    local missing=0 set_count=0
    while IFS='=' read -r key val; do
        [[ "$key" =~ ^[[:space:]]*# ]] && continue
        [[ -z "$key" ]] && continue
        key=$(echo "$key" | tr -d '[:space:]')
        if [[ -n "${(P)key}" ]]; then
            echo -e "  ${GREEN}✓${NC} $key"
            ((set_count++))
        else
            echo -e "  ${RED}✗${NC} $key ${YELLOW}(not set)${NC}"
            ((missing++))
        fi
    done < <(grep -v '^\s*#' "$file" | grep '=')

    echo ""
    echo -e "  Set: ${GREEN}${set_count}${NC}  Missing: ${RED}${missing}${NC}"
    [[ $missing -gt 0 ]] && echo -e "  Run: ${CYAN}source $file${NC} or ${CYAN}export \$(cat $file | xargs)${NC}"
}

cmd_history() {
    echo -e "${BOLD}${BLUE}📜 Diff History${NC}\n"
    sqlite3 "$DB" "SELECT ts, env_a, env_b, missing_in_b, missing_in_a, value_diffs FROM diff_history ORDER BY ts DESC LIMIT 20;" 2>/dev/null \
        | while IFS='|' read -r ts a b mb ma vd; do
            local ok="${RED}✗${NC}"
            [[ "$mb" -eq 0 && "$ma" -eq 0 && "$vd" -eq 0 ]] && ok="${GREEN}✓${NC}"
            echo -e "  $ok ${CYAN}$ts${NC}  $a ↔ $b  missing=${mb}+${ma} diff=${vd}"
        done
}

show_help() {
    echo -e "${BOLD}${BLUE}BR env-diff${NC} — Compare .env files\n"
    echo -e "${BOLD}Usage:${NC}"
    echo -e "  ${CYAN}br env-diff <file-a> <file-b> [--values]${NC}  — Diff two env files"
    echo -e "  ${CYAN}br env-diff audit [file]${NC}                  — Audit single env file"
    echo -e "  ${CYAN}br env-diff template [file] [out]${NC}         — Generate .env.example"
    echo -e "  ${CYAN}br env-diff sync-check [file]${NC}             — Compare file vs process env"
    echo -e "  ${CYAN}br env-diff history${NC}                       — Past diffs\n"
    echo -e "${BOLD}Examples:${NC}"
    echo -e "  br env-diff .env .env.staging"
    echo -e "  br env-diff .env.development .env.production --values"
    echo -e "  br env-diff audit .env.production"
    echo -e "  br env-diff template .env .env.example"
    echo -e "  br env-diff sync-check .env"
}

init_db
case "${1:-help}" in
    diff|compare|''|*.env*)
        if [[ "$1" == *.env* || "$1" == .env* ]]; then
            cmd_diff "$1" "$2" "$3"
        else
            show_help
        fi
        ;;
    audit|check-file)      cmd_audit "$2" ;;
    template|example|mask) cmd_template "$2" "$3" ;;
    sync|sync-check)       cmd_sync_check "$2" ;;
    history|log)           cmd_history ;;
    help|--help|-h)        show_help ;;
    *)
        # Try treating args as files
        if [[ -f "$1" ]]; then
            cmd_diff "$1" "$2" "$3"
        else
            show_help
        fi
        ;;
esac
