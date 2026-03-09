#!/bin/bash
# YellowLight Memory Templates
# Standardized logging for infrastructure management with BlackRoad memory system

set -e

MEMORY_SYSTEM="$HOME/memory-system.sh"

# Colors
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# Helper to log with YellowLight tags
yl_log() {
    local yl_tags="$1"
    local action="$2"
    local entity="$3"
    local details="$4"

    # Prepend YellowLight tags to details
    local full_details="[${yl_tags}] ${details}"

    $MEMORY_SYSTEM log "$action" "$entity" "$full_details"
}

# ═══════════════════════════════════════════════════════
# REPOSITORY MANAGEMENT
# ═══════════════════════════════════════════════════════

# Template: Repository created
yl_repo_created() {
    local repo_name="$1"
    local org="$2"
    local description="$3"
    local visibility="${4:-public}"

    local vis_emoji="🌍"
    [ "$visibility" = "private" ] && vis_emoji="🔐"

    yl_log "🟡🐙${vis_emoji}👉" \
        "created" \
        "$repo_name" \
        "Repo created in $org: $description"
}

# Template: Repository cloned
yl_repo_cloned() {
    local repo_name="$1"
    local destination="$2"

    yl_log "🟡🐙📥👉" \
        "cloned" \
        "$repo_name" \
        "Cloned to: $destination"
}

# Template: Repository archived
yl_repo_archived() {
    local repo_name="$1"
    local reason="${2:-inactive}"

    yl_log "🟡🐙📦👉" \
        "archived" \
        "$repo_name" \
        "Archived: $reason"
}

# Template: Branch created
yl_branch_created() {
    local repo_name="$1"
    local branch_name="$2"
    local from_branch="${3:-main}"

    yl_log "🟡🌿👉📌" \
        "branch_created" \
        "$repo_name" \
        "Branch: $branch_name (from $from_branch)"
}

# Template: Pull request opened
yl_pr_opened() {
    local repo_name="$1"
    local pr_number="$2"
    local title="$3"
    local author="${4:-unknown}"

    yl_log "🟡🔀👉📌" \
        "pr_opened" \
        "$repo_name" \
        "PR #$pr_number: $title (by $author)"
}

# Template: Pull request merged
yl_pr_merged() {
    local repo_name="$1"
    local pr_number="$2"
    local merged_by="${3:-unknown}"

    yl_log "🟡🔀✅🎉" \
        "pr_merged" \
        "$repo_name" \
        "PR #$pr_number merged by $merged_by"
}

# ═══════════════════════════════════════════════════════
# CONNECTOR MANAGEMENT
# ═══════════════════════════════════════════════════════

# Template: Connector deployed
yl_connector_deployed() {
    local connector_name="$1"
    local service="$2"
    local url="$3"
    local type="${4:-api}"  # api, webhook, websocket

    local type_emoji=""
    case "$type" in
        api) type_emoji="🔗" ;;
        webhook) type_emoji="📨" ;;
        websocket) type_emoji="⚡" ;;
        *) type_emoji="🔌" ;;
    esac

    yl_log "🟡${type_emoji}✅📌" \
        "deployed" \
        "$connector_name" \
        "Connector: $service → $url"
}

# Template: Integration configured
yl_integration_configured() {
    local service_a="$1"
    local service_b="$2"
    local type="$3"  # webhook, api, sync
    local details="${4:-}"

    local type_emoji=""
    case "$type" in
        webhook) type_emoji="📨" ;;
        api) type_emoji="🔗" ;;
        sync) type_emoji="🔄" ;;
        *) type_emoji="🔌" ;;
    esac

    yl_log "🟡${type_emoji}✅📌" \
        "configured" \
        "$service_a-$service_b" \
        "Integration: $service_a ↔ $service_b ($type). $details"
}

# Template: Webhook received
yl_webhook_received() {
    local service="$1"
    local event_type="$2"
    local event_id="${3:-unknown}"

    yl_log "🟡📨📥👉" \
        "webhook_received" \
        "$service" \
        "Event: $event_type ($event_id)"
}

# Template: API call made
yl_api_call() {
    local service="$1"
    local endpoint="$2"
    local method="${3:-GET}"
    local status="${4:-200}"

    local status_emoji="✅"
    [ "$status" -ge 400 ] && status_emoji="❌"

    yl_log "🟡🔗${status_emoji}👉" \
        "api_call" \
        "$service" \
        "$method $endpoint → HTTP $status"
}

# ═══════════════════════════════════════════════════════
# DEPLOYMENT MANAGEMENT
# ═══════════════════════════════════════════════════════

# Template: Deployment succeeded
yl_deployment_succeeded() {
    local service="$1"
    local platform="$2"  # cloudflare, railway, digitalocean, pi
    local url="$3"
    local version="${4:-latest}"
    local environment="${5:-production}"

    local platform_emoji=""
    case "$platform" in
        cloudflare) platform_emoji="☁️" ;;
        railway) platform_emoji="🚂" ;;
        digitalocean) platform_emoji="🌊" ;;
        pi) platform_emoji="🥧" ;;
        vercel) platform_emoji="▲" ;;
        netlify) platform_emoji="🦋" ;;
        fly) platform_emoji="🪰" ;;
        *) platform_emoji="🚀" ;;
    esac

    local env_emoji="🧪"
    [ "$environment" = "production" ] && env_emoji="🚀"

    yl_log "🟡${env_emoji}${platform_emoji}✅" \
        "deployed" \
        "$service" \
        "Deployed v$version to $platform ($environment): $url"
}

# Template: Deployment failed
yl_deployment_failed() {
    local service="$1"
    local platform="$2"
    local error="$3"
    local version="${4:-latest}"

    yl_log "🟡❌🚨🔥" \
        "failed" \
        "$service" \
        "Deployment failed v$version on $platform: $error"
}

# Template: Deployment rollback
yl_deployment_rollback() {
    local service="$1"
    local from_version="$2"
    local to_version="$3"
    local reason="${4:-errors detected}"

    yl_log "🟡🔙⚠️📌" \
        "rollback" \
        "$service" \
        "Rolled back v$from_version → v$to_version: $reason"
}

# Template: Service scaled
yl_service_scaled() {
    local service="$1"
    local from_instances="$2"
    local to_instances="$3"
    local reason="${4:-traffic increase}"

    yl_log "🟡📊🔄📌" \
        "scaled" \
        "$service" \
        "Scaled $from_instances → $to_instances instances: $reason"
}

# ═══════════════════════════════════════════════════════
# HEALTH & MONITORING
# ═══════════════════════════════════════════════════════

# Template: Health check passed
yl_health_check() {
    local service="$1"
    local url="$2"
    local response_time_ms="${3:-unknown}"

    yl_log "🟡💚✅👉" \
        "health_check" \
        "$service" \
        "Health check passed: $url (${response_time_ms}ms)"
}

# Template: Health check failed
yl_health_failed() {
    local service="$1"
    local url="$2"
    local error="$3"

    yl_log "🟡🔴❌🚨" \
        "health_failed" \
        "$service" \
        "Health check failed: $url - $error"
}

# Template: Service down
yl_service_down() {
    local service="$1"
    local duration="${2:-unknown}"
    local reason="${3:-unknown}"

    yl_log "🟡💀❌🔥" \
        "service_down" \
        "$service" \
        "Service down for $duration: $reason"
}

# Template: Service recovered
yl_service_recovered() {
    local service="$1"
    local downtime="${2:-unknown}"

    yl_log "🟡💚✅🎉" \
        "service_recovered" \
        "$service" \
        "Service recovered after $downtime downtime"
}

# ═══════════════════════════════════════════════════════
# CI/CD WORKFLOWS
# ═══════════════════════════════════════════════════════

# Template: Workflow triggered
yl_workflow_trigger() {
    local repo="$1"
    local trigger="$2"  # push, pr, manual, schedule
    local workflow_name="${3:-CI/CD}"

    yl_log "🟡⚡👉📌" \
        "triggered" \
        "$repo" \
        "Workflow: $workflow_name (trigger: $trigger)"
}

# Template: Workflow step
yl_workflow_step() {
    local repo="$1"
    local step="$2"  # lint, test, build, deploy
    local result="$3"  # passed, failed
    local duration="${4:-unknown}"

    local step_emoji=""
    case "$step" in
        lint) step_emoji="🔍" ;;
        test) step_emoji="🧪" ;;
        build) step_emoji="🏗️" ;;
        deploy) step_emoji="🚀" ;;
        *) step_emoji="⚙️" ;;
    esac

    local status_emoji="✅"
    [ "$result" = "failed" ] && status_emoji="❌"

    yl_log "🟡${step_emoji}${status_emoji}👉" \
        "$step" \
        "$repo" \
        "Step $step $result in $duration"
}

# Template: Workflow complete
yl_workflow_done() {
    local repo="$1"
    local result="$2"  # passed, failed
    local duration="$3"

    local status_emoji="✅"
    [ "$result" = "failed" ] && status_emoji="❌"

    yl_log "🟡${status_emoji}🎢🔧" \
        "workflow_${result}" \
        "$repo" \
        "Pipeline $result in $duration"
}

# ═══════════════════════════════════════════════════════
# INFRASTRUCTURE
# ═══════════════════════════════════════════════════════

# Template: Server provisioned
yl_server_provisioned() {
    local server_name="$1"
    local platform="$2"
    local specs="$3"
    local ip="${4:-unknown}"

    yl_log "🟡🖥️✅📌" \
        "provisioned" \
        "$server_name" \
        "Server on $platform: $specs (IP: $ip)"
}

# Template: Database created
yl_database_created() {
    local db_name="$1"
    local type="$2"  # postgres, mysql, redis, mongodb
    local platform="$3"

    local db_emoji=""
    case "$type" in
        postgres) db_emoji="🐘" ;;
        mysql) db_emoji="🐬" ;;
        redis) db_emoji="📮" ;;
        mongodb) db_emoji="🍃" ;;
        *) db_emoji="💾" ;;
    esac

    yl_log "🟡${db_emoji}✅📌" \
        "created" \
        "$db_name" \
        "Database: $type on $platform"
}

# Template: Migration applied
yl_migration_applied() {
    local database="$1"
    local migration_name="$2"
    local version="${3:-latest}"

    yl_log "🟡🔄💾✅" \
        "migrated" \
        "$database" \
        "Applied migration: $migration_name (v$version)"
}

# Template: Backup created
yl_backup_created() {
    local service="$1"
    local backup_size="$2"
    local location="${3:-s3}"

    yl_log "🟡💾📦✅" \
        "backup_created" \
        "$service" \
        "Backup: $backup_size to $location"
}

# Template: SSL certificate renewed
yl_ssl_renewed() {
    local domain="$1"
    local expiry_date="$2"

    yl_log "🟡🔒✅📌" \
        "ssl_renewed" \
        "$domain" \
        "SSL certificate renewed, expires: $expiry_date"
}

# ═══════════════════════════════════════════════════════
# CLOUDFLARE-SPECIFIC
# ═══════════════════════════════════════════════════════

# Template: Worker deployed
yl_worker_deploy() {
    local worker="$1"
    local route="$2"
    local version="${3:-latest}"

    yl_log "🟡⚙️☁️✅" \
        "deployed" \
        "$worker" \
        "Worker deployed v$version: $route"
}

# Template: D1 migration
yl_d1_migrate() {
    local database="$1"
    local migration="$2"

    yl_log "🟡🔄💾👉" \
        "migrated" \
        "$database" \
        "D1 migration: $migration"
}

# Template: KV namespace operation
yl_kv_update() {
    local namespace="$1"
    local operation="$2"  # created, updated, deleted

    yl_log "🟡✅🗂️👉" \
        "$operation" \
        "$namespace" \
        "KV namespace $operation"
}

# Template: R2 bucket operation
yl_r2_operation() {
    local bucket="$1"
    local operation="$2"
    local size="${3:-unknown}"

    yl_log "🟡📦💾👉" \
        "$operation" \
        "$bucket" \
        "R2 $operation ($size)"
}

# Template: Pages deployed
yl_pages_deploy() {
    local project_name="$1"
    local url="$2"
    local commit="${3:-latest}"

    yl_log "🟡🚀☁️✅" \
        "deployed" \
        "$project_name" \
        "Pages deployed: $url (commit: $commit)"
}

# ═══════════════════════════════════════════════════════
# EDGE DEVICES (Raspberry Pi)
# ═══════════════════════════════════════════════════════

# Template: Pi service deployed
yl_pi_deploy() {
    local service="$1"
    local pi_name="$2"
    local ip="$3"
    local port="${4:-8080}"

    yl_log "🟡🥧✅📌" \
        "deployed" \
        "$service" \
        "Deployed to $pi_name ($ip:$port)"
}

# Template: Pi mesh connected
yl_pi_mesh() {
    local pi_name="$1"
    local ip="$2"
    local mesh_size="${3:-unknown}"

    yl_log "🟡🥧🌐✅" \
        "mesh_connected" \
        "$pi_name" \
        "Connected to mesh ($ip), mesh size: $mesh_size nodes"
}

# ═══════════════════════════════════════════════════════
# DNS & DOMAINS
# ═══════════════════════════════════════════════════════

# Template: Domain configured
yl_domain_configured() {
    local domain="$1"
    local target="$2"
    local record_type="${3:-CNAME}"

    yl_log "🟡🌐✅📌" \
        "configured" \
        "$domain" \
        "DNS: $record_type → $target"
}

# Template: DNS propagated
yl_dns_propagated() {
    local domain="$1"
    local duration="${2:-unknown}"

    yl_log "🟡🌐✅🎉" \
        "propagated" \
        "$domain" \
        "DNS propagated in $duration"
}

# ═══════════════════════════════════════════════════════
# SECRETS & CREDENTIALS
# ═══════════════════════════════════════════════════════

# Template: Secret stored
yl_secret_stored() {
    local secret_name="$1"
    local vault="${2:-github}"

    yl_log "🟡🔐✅📌" \
        "stored" \
        "$secret_name" \
        "Secret stored in $vault"
}

# Template: API key rotated
yl_api_key_rotated() {
    local service="$1"
    local reason="${2:-scheduled rotation}"

    yl_log "🟡🔑🔄📌" \
        "rotated" \
        "$service" \
        "API key rotated: $reason"
}

# ═══════════════════════════════════════════════════════
# INTEGRATION WITH GREENLIGHT
# ═══════════════════════════════════════════════════════

# Helper: Create GreenLight task from YellowLight infra
yl_create_gl_task() {
    local service="$1"
    local task_description="$2"
    local priority="${3:-📌}"

    source "$HOME/memory-greenlight-templates.sh"

    gl_feature \
        "YellowLight: $service" \
        "$task_description" \
        "🍖" \
        "$priority"
}

# Helper: Update GreenLight on deployment
yl_notify_gl_deploy() {
    local service="$1"
    local url="$2"
    local platform="${3:-cloudflare}"

    source "$HOME/memory-greenlight-templates.sh"

    gl_deploy \
        "$service" \
        "$url" \
        "YellowLight deployment via $platform" \
        "🎢" \
        "🔧"
}

# ═══════════════════════════════════════════════════════
# SHOW HELP
# ═══════════════════════════════════════════════════════

show_help() {
    cat <<'EOF'
YellowLight Memory Templates

USAGE:
    source memory-yellowlight-templates.sh
    yl_<template> [args...]

REPOSITORY MANAGEMENT:

    yl_repo_created <name> <org> <description> [visibility]
        Create repository (public/private)

    yl_repo_cloned <name> <destination>
        Clone repository

    yl_repo_archived <name> [reason]
        Archive repository

    yl_branch_created <repo> <branch> [from_branch]
        Create branch

    yl_pr_opened <repo> <pr_number> <title> [author]
        Open pull request

    yl_pr_merged <repo> <pr_number> [merged_by]
        Merge pull request

CONNECTOR MANAGEMENT:

    yl_connector_deployed <name> <service> <url> [type]
        Deploy connector (api/webhook/websocket)

    yl_integration_configured <service_a> <service_b> <type> [details]
        Configure integration (webhook/api/sync)

    yl_webhook_received <service> <event_type> [event_id]
        Log webhook received

    yl_api_call <service> <endpoint> [method] [status]
        Log API call

DEPLOYMENT MANAGEMENT:

    yl_deployment_succeeded <service> <platform> <url> [version] [environment]
        Log successful deployment (cloudflare/railway/digitalocean/pi)

    yl_deployment_failed <service> <platform> <error> [version]
        Log deployment failure

    yl_deployment_rollback <service> <from_version> <to_version> [reason]
        Log deployment rollback

    yl_service_scaled <service> <from_instances> <to_instances> [reason]
        Log service scaling

HEALTH & MONITORING:

    yl_health_check <service> <url> [response_time_ms]
        Log health check passed

    yl_health_failed <service> <url> <error>
        Log health check failed

    yl_service_down <service> [duration] [reason]
        Log service downtime

    yl_service_recovered <service> [downtime]
        Log service recovery

CI/CD WORKFLOWS:

    yl_workflow_trigger <repo> <trigger> [workflow_name]
        Trigger workflow (push/pr/manual/schedule)

    yl_workflow_step <repo> <step> <result> [duration]
        Log workflow step (lint/test/build/deploy, passed/failed)

    yl_workflow_done <repo> <result> <duration>
        Log workflow completion (passed/failed)

INFRASTRUCTURE:

    yl_server_provisioned <name> <platform> <specs> [ip]
        Log server provisioning

    yl_database_created <name> <type> <platform>
        Create database (postgres/mysql/redis/mongodb)

    yl_migration_applied <database> <migration> [version]
        Log database migration

    yl_backup_created <service> <size> [location]
        Log backup creation

    yl_ssl_renewed <domain> <expiry_date>
        Log SSL renewal

CLOUDFLARE-SPECIFIC:

    yl_worker_deploy <worker> <route> [version]
        Deploy Cloudflare Worker

    yl_d1_migrate <database> <migration>
        D1 database migration

    yl_kv_update <namespace> <operation>
        KV namespace operation (created/updated/deleted)

    yl_r2_operation <bucket> <operation> [size]
        R2 bucket operation

    yl_pages_deploy <project> <url> [commit]
        Deploy Cloudflare Pages

EDGE DEVICES:

    yl_pi_deploy <service> <pi_name> <ip> [port]
        Deploy to Raspberry Pi

    yl_pi_mesh <pi_name> <ip> [mesh_size]
        Connect Pi to mesh

DNS & DOMAINS:

    yl_domain_configured <domain> <target> [record_type]
        Configure domain (CNAME/A/AAAA)

    yl_dns_propagated <domain> [duration]
        Log DNS propagation

SECRETS & CREDENTIALS:

    yl_secret_stored <name> [vault]
        Store secret (github/railway/cloudflare)

    yl_api_key_rotated <service> [reason]
        Rotate API key

GREENLIGHT INTEGRATION:

    yl_create_gl_task <service> <description> [priority]
        Create GreenLight task from infrastructure

    yl_notify_gl_deploy <service> <url> [platform]
        Notify GreenLight of deployment

EXAMPLES:

    # Deploy API to Railway
    yl_deployment_succeeded "blackroad-api" "railway" \
        "https://blackroad-api.railway.app" "1.2.3" "production"

    # Configure Stripe webhook
    yl_integration_configured "stripe" "blackroad-api" "webhook" \
        "Billing events → api.blackroad.io/webhooks/stripe"

    # Deploy to Raspberry Pi
    yl_pi_deploy "lucidia-agent" "lucidia" "192.168.4.38" "8080"

    # Health check
    yl_health_check "api.blackroad.io" "https://api.blackroad.io/health" "120"

    # Create GreenLight task
    yl_create_gl_task "cloudflare-worker-auth" \
        "Deploy authentication worker to Cloudflare" "⭐"

EOF
}

# Main command handler
case "${1:-help}" in
    help|--help|-h)
        show_help
        ;;
    *)
        # If sourced, functions are available
        # If executed directly, show help
        if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
            show_help
        fi
        ;;
esac
