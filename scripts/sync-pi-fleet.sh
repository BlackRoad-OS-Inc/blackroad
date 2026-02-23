#!/bin/zsh
# BR Pi Fleet Sync — rsync config files from macbook to Pi fleet
# Usage: ./scripts/sync-pi-fleet.sh [alice|aria|all]

set -euo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

log()   { echo -e "${GREEN}✔${NC} $1"; }
error() { echo -e "${RED}✘${NC} $1" >&2; }
warn()  { echo -e "${YELLOW}⚠${NC} $1"; }
info()  { echo -e "${CYAN}ℹ${NC} $1"; }

# ── Fleet targets ─────────────────────────────────────────────────────────────
# Format: "user@host"
typeset -A FLEET_HOSTS
FLEET_HOSTS=(
    alice   "alice@192.168.4.49"
    aria    "pi@192.168.4.38"
)

# ── Config sources on this Mac ────────────────────────────────────────────────
# Edit these paths to match where you keep local copies of Pi configs.
NGINX_LOCAL="${NGINX_LOCAL:-$HOME/.blackroad/fleet/nginx/sites-available}"
CLOUDFLARED_LOCAL="${CLOUDFLARED_LOCAL:-$HOME/.blackroad/fleet/cloudflared}"

SSH_OPTS="-o ConnectTimeout=10 -o StrictHostKeyChecking=no -o BatchMode=yes"

# ── helpers ───────────────────────────────────────────────────────────────────

ensure_local_dirs() {
    mkdir -p "$NGINX_LOCAL" "$CLOUDFLARED_LOCAL"
}

sync_target() {
    local name=$1
    local target=${FLEET_HOSTS[$name]}

    echo -e "\n${BOLD}${CYAN}▶ Syncing ${name} → ${target}${NC}"
    echo -e "  $(printf '%.s─' {1..50})"

    # Verify reachable
    if ! ssh $=SSH_OPTS "$target" 'echo ok' >/dev/null 2>&1; then
        error "Cannot reach $target — skipping $name"
        return 1
    fi
    log "Connected to $target"

    local synced=0 failed=0

    # ── nginx sites-available ────────────────────────────────────────────────
    if [[ -d $NGINX_LOCAL ]] && [[ -n "$(ls -A "$NGINX_LOCAL" 2>/dev/null)" ]]; then
        info "Syncing nginx sites-available…"
        if rsync -az --checksum \
            -e "ssh $SSH_OPTS" \
            "$NGINX_LOCAL/" \
            "${target}:/tmp/nginx-sites-sync/" 2>/dev/null; then
            # Move into place with sudo
            ssh $=SSH_OPTS "$target" '
                sudo mkdir -p /etc/nginx/sites-available
                sudo rsync -a /tmp/nginx-sites-sync/ /etc/nginx/sites-available/
                sudo rm -rf /tmp/nginx-sites-sync
            ' && log "nginx sites-available synced" && (( synced++ )) \
              || { error "Failed to install nginx configs on $name"; (( failed++ )); }
        else
            error "rsync of nginx configs failed"
            (( failed++ ))
        fi
    else
        warn "No local nginx configs at $NGINX_LOCAL — skipping"
    fi

    # ── cloudflared config ───────────────────────────────────────────────────
    local cf_config="$CLOUDFLARED_LOCAL/config.yml"
    if [[ -f $cf_config ]]; then
        info "Syncing cloudflared config.yml…"
        if rsync -az --checksum \
            -e "ssh $SSH_OPTS" \
            "$cf_config" \
            "${target}:/tmp/cloudflared-config.yml" 2>/dev/null; then
            ssh $=SSH_OPTS "$target" '
                sudo mkdir -p /etc/cloudflared
                sudo mv /tmp/cloudflared-config.yml /etc/cloudflared/config.yml
                sudo chmod 644 /etc/cloudflared/config.yml
            ' && log "cloudflared config.yml synced" && (( synced++ )) \
              || { error "Failed to install cloudflared config on $name"; (( failed++ )); }
        else
            error "rsync of cloudflared config failed"
            (( failed++ ))
        fi
    else
        warn "No cloudflared config at $cf_config — skipping"
    fi

    # ── reload / restart services ────────────────────────────────────────────
    if (( synced > 0 )); then
        info "Reloading services on $name…"
        ssh $=SSH_OPTS "$target" '
            errors=0
            # nginx — reload only (no downtime)
            if systemctl is-active --quiet nginx 2>/dev/null; then
                if sudo nginx -t 2>/dev/null; then
                    sudo systemctl reload nginx && echo "  nginx reloaded" || { echo "  nginx reload FAILED"; errors=1; }
                else
                    echo "  nginx config test FAILED — skipping reload"
                    errors=1
                fi
            fi
            # cloudflared — restart to pick up new config
            if systemctl is-active --quiet cloudflared 2>/dev/null; then
                sudo systemctl restart cloudflared && echo "  cloudflared restarted" || { echo "  cloudflared restart FAILED"; errors=1; }
            fi
            exit $errors
        ' && log "Services reloaded on $name" || warn "Some services failed to reload on $name"
    fi

    echo -e "  ${GREEN}${synced} synced${NC}${failed:+, ${RED}${failed} failed${NC}}"
}

show_help() {
    echo -e "\n${BOLD}${CYAN}BR Pi Fleet Sync${NC}"
    echo ""
    echo "  Usage: $0 [target]"
    echo ""
    echo "  Targets:"
    echo "    alice   — sync to alice@192.168.4.49"
    echo "    aria    — sync to pi@192.168.4.38"
    echo "    all     — sync to all Pis (default)"
    echo ""
    echo "  Local config dirs (override with env vars):"
    echo "    NGINX_LOCAL        $NGINX_LOCAL"
    echo "    CLOUDFLARED_LOCAL  $CLOUDFLARED_LOCAL"
    echo ""
    echo "  Syncs:"
    echo "    → /etc/nginx/sites-available/"
    echo "    → /etc/cloudflared/config.yml"
    echo "  Then runs: sudo nginx -t && systemctl reload nginx"
    echo "             sudo systemctl restart cloudflared"
    echo ""
}

# ── main ──────────────────────────────────────────────────────────────────────

ensure_local_dirs

target="${1:-all}"

case "$target" in
    all)
        echo -e "\n${BOLD}${CYAN}Pi Fleet Sync — all targets${NC}  $(date '+%Y-%m-%d %H:%M:%S')"
        for pi in "${(k)FLEET_HOSTS[@]}"; do
            sync_target "$pi" || true
        done
        ;;
    alice|aria)
        echo -e "\n${BOLD}${CYAN}Pi Fleet Sync — ${target}${NC}  $(date '+%Y-%m-%d %H:%M:%S')"
        sync_target "$target"
        ;;
    help|-h|--help)
        show_help
        ;;
    *)
        error "Unknown target: $target"
        show_help
        exit 1
        ;;
esac

echo -e "\n${GREEN}${BOLD}Done.${NC}\n"
