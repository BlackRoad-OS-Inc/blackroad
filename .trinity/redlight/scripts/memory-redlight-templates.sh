#!/bin/bash
# RedLight Memory Templates
# Standardized logging for template management with BlackRoad memory system

set -e

MEMORY_SYSTEM="$HOME/memory-system.sh"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Helper to log with RedLight tags
rl_log() {
    local rl_tags="$1"
    local action="$2"
    local entity="$3"
    local details="$4"

    # Prepend RedLight tags to details
    local full_details="[${rl_tags}] ${details}"

    $MEMORY_SYSTEM log "$action" "$entity" "$full_details"
}

# ═══════════════════════════════════════════════════════
# TEMPLATE MANAGEMENT
# ═══════════════════════════════════════════════════════

# Template: Create template
rl_template_create() {
    local template_name="$1"
    local category="$2"  # world, website, animation, design, game, app, visual
    local description="$3"

    local category_emoji=""
    case "$category" in
        world) category_emoji="🌍" ;;
        website) category_emoji="🌐" ;;
        animation) category_emoji="✨" ;;
        design) category_emoji="🎨" ;;
        game) category_emoji="🎮" ;;
        app) category_emoji="📱" ;;
        visual) category_emoji="🖼️" ;;
        *) category_emoji="🔴" ;;
    esac

    rl_log "🔴${category_emoji}👉📌" \
        "created" \
        "$template_name" \
        "RedLight template: $description"
}

# Template: Update template
rl_template_update() {
    local template_name="$1"
    local changes="$2"
    local category="${3:-world}"

    local category_emoji=""
    case "$category" in
        world) category_emoji="🌍" ;;
        website) category_emoji="🌐" ;;
        animation) category_emoji="✨" ;;
        *) category_emoji="🔴" ;;
    esac

    rl_log "🔴🔄${category_emoji}👉" \
        "updated" \
        "$template_name" \
        "Template updated: $changes"
}

# Template: Delete template
rl_template_delete() {
    local template_name="$1"
    local reason="${2:-deprecated}"

    rl_log "🔴❌👉📌" \
        "deleted" \
        "$template_name" \
        "Template removed: $reason"
}

# Template: Copy template
rl_template_copy() {
    local source_template="$1"
    local new_template="$2"
    local purpose="$3"

    rl_log "🔴📋👉📌" \
        "copied" \
        "$new_template" \
        "Copied from $source_template: $purpose"
}

# Template: Archive template
rl_template_archive() {
    local template_name="$1"
    local reason="${2:-outdated}"

    rl_log "🔴📦👉📌" \
        "archived" \
        "$template_name" \
        "Template archived: $reason"
}

# ═══════════════════════════════════════════════════════
# DEPLOYMENT
# ═══════════════════════════════════════════════════════

# Template: Deploy template
rl_template_deploy() {
    local template_name="$1"
    local url="$2"
    local platform="${3:-cloudflare}"  # cloudflare, github, railway, vercel

    local platform_emoji=""
    case "$platform" in
        cloudflare) platform_emoji="☁️" ;;
        github) platform_emoji="🐙" ;;
        railway) platform_emoji="🚂" ;;
        vercel) platform_emoji="▲" ;;
        netlify) platform_emoji="🦋" ;;
        *) platform_emoji="🌐" ;;
    esac

    rl_log "🔴🚀${platform_emoji}✅" \
        "deployed" \
        "$template_name" \
        "Template deployed: $url"
}

# Template: Deployment failed
rl_deploy_failed() {
    local template_name="$1"
    local platform="$2"
    local error="${3:-unknown error}"

    rl_log "🔴❌🚨🔥" \
        "deploy_failed" \
        "$template_name" \
        "Deployment failed on $platform: $error"
}

# Template: Deployment rollback
rl_deploy_rollback() {
    local template_name="$1"
    local from_version="$2"
    local to_version="$3"

    rl_log "🔴🔙⚠️📌" \
        "rollback" \
        "$template_name" \
        "Rolled back from v$from_version to v$to_version"
}

# ═══════════════════════════════════════════════════════
# VERSIONING
# ═══════════════════════════════════════════════════════

# Template: Version release
rl_version_release() {
    local template_name="$1"
    local version="$2"
    local changes="$3"

    rl_log "🔴🏷️✅📌" \
        "version_release" \
        "$template_name" \
        "Released v$version: $changes"
}

# Template: Version tag
rl_version_tag() {
    local template_name="$1"
    local tag="$2"
    local commit="$3"

    rl_log "🔴🔖👉📌" \
        "version_tag" \
        "$template_name" \
        "Tagged $tag at commit $commit"
}

# ═══════════════════════════════════════════════════════
# TESTING
# ═══════════════════════════════════════════════════════

# Template: Test passed
rl_test_passed() {
    local template_name="$1"
    local test_type="${2:-visual}"  # visual, performance, accessibility
    local details="${3:-all tests passed}"

    local test_emoji=""
    case "$test_type" in
        visual) test_emoji="👀" ;;
        performance) test_emoji="⚡" ;;
        accessibility) test_emoji="♿" ;;
        integration) test_emoji="🔗" ;;
        *) test_emoji="✅" ;;
    esac

    rl_log "🔴${test_emoji}✅👉" \
        "test_passed" \
        "$template_name" \
        "$test_type test: $details"
}

# Template: Test failed
rl_test_failed() {
    local template_name="$1"
    local test_type="$2"
    local error="$3"

    rl_log "🔴❌🚨🔥" \
        "test_failed" \
        "$template_name" \
        "$test_type test failed: $error"
}

# ═══════════════════════════════════════════════════════
# ANALYTICS
# ═══════════════════════════════════════════════════════

# Template: Analytics snapshot
rl_analytics_snapshot() {
    local template_name="$1"
    local views="$2"
    local interactions="$3"
    local avg_session="${4:-unknown}"

    rl_log "🔴📊👉📌" \
        "analytics" \
        "$template_name" \
        "Views: $views, Interactions: $interactions, Avg session: $avg_session"
}

# Template: Performance metrics
rl_performance_metrics() {
    local template_name="$1"
    local fps="$2"
    local load_time="$3"
    local memory_mb="${4:-unknown}"

    rl_log "🔴⚡📊👉" \
        "performance" \
        "$template_name" \
        "FPS: $fps, Load: ${load_time}s, Memory: ${memory_mb}MB"
}

# ═══════════════════════════════════════════════════════
# FEATURES
# ═══════════════════════════════════════════════════════

# Template: Feature added
rl_feature_added() {
    local template_name="$1"
    local feature="$2"
    local description="$3"

    rl_log "🔴✨👉⭐" \
        "feature_added" \
        "$template_name" \
        "New feature: $feature - $description"
}

# Template: Bug fixed
rl_bug_fixed() {
    local template_name="$1"
    local bug="$2"
    local fix="$3"

    rl_log "🔴🐛✅👉" \
        "bug_fixed" \
        "$template_name" \
        "Bug fixed: $bug → $fix"
}

# ═══════════════════════════════════════════════════════
# COLLABORATION
# ═══════════════════════════════════════════════════════

# Template: Template shared
rl_template_shared() {
    local template_name="$1"
    local with_who="$2"
    local platform="${3:-link}"

    rl_log "🔴🤝👉📌" \
        "shared" \
        "$template_name" \
        "Shared with $with_who via $platform"
}

# Template: Feedback received
rl_feedback_received() {
    local template_name="$1"
    local from_who="$2"
    local feedback="$3"

    rl_log "🔴💬👉📌" \
        "feedback" \
        "$template_name" \
        "Feedback from $from_who: $feedback"
}

# ═══════════════════════════════════════════════════════
# WORLD-SPECIFIC TEMPLATES
# ═══════════════════════════════════════════════════════

# Template: World created
rl_world_create() {
    local world_name="$1"
    local type="${2:-planet}"  # planet, city, environment, metaverse
    local features="$3"

    rl_log "🔴🌍🆕📌" \
        "world_created" \
        "$world_name" \
        "Type: $type, Features: $features"
}

# Template: Biome added
rl_biome_add() {
    local world_name="$1"
    local biome_name="$2"
    local properties="$3"

    rl_log "🔴🌍🌱👉" \
        "biome_added" \
        "$world_name" \
        "New biome: $biome_name ($properties)"
}

# Template: Entity spawned
rl_entity_spawn() {
    local world_name="$1"
    local entity_type="$2"  # particle, object, agent, city
    local count="${3:-1}"

    rl_log "🔴🌍✨👉" \
        "entity_spawned" \
        "$world_name" \
        "Spawned $count × $entity_type"
}

# ═══════════════════════════════════════════════════════
# ANIMATION-SPECIFIC TEMPLATES
# ═══════════════════════════════════════════════════════

# Template: Animation created
rl_animation_create() {
    local animation_name="$1"
    local type="${2:-motion}"  # motion, particle, shader, morph
    local duration="${3:-unknown}"

    rl_log "🔴✨🆕📌" \
        "animation_created" \
        "$animation_name" \
        "Type: $type, Duration: $duration"
}

# Template: Effect applied
rl_effect_apply() {
    local template_name="$1"
    local effect_type="$2"  # glow, bloom, blur, distortion
    local intensity="${3:-medium}"

    rl_log "🔴✨👉📌" \
        "effect_applied" \
        "$template_name" \
        "Applied $effect_type effect (intensity: $intensity)"
}

# ═══════════════════════════════════════════════════════
# DESIGN SYSTEM TEMPLATES
# ═══════════════════════════════════════════════════════

# Template: Component created
rl_component_create() {
    local component_name="$1"
    local type="${2:-ui}"  # ui, layout, utility
    local variants="$3"

    rl_log "🔴🎨🆕📌" \
        "component_created" \
        "$component_name" \
        "Type: $type, Variants: $variants"
}

# Template: Theme updated
rl_theme_update() {
    local theme_name="$1"
    local changes="$2"

    rl_log "🔴🎨🔄📌" \
        "theme_updated" \
        "$theme_name" \
        "Theme changes: $changes"
}

# ═══════════════════════════════════════════════════════
# INTERACTIVE TEMPLATES
# ═══════════════════════════════════════════════════════

# Template: Interaction added
rl_interaction_add() {
    local template_name="$1"
    local interaction_type="$2"  # click, hover, drag, voice, gesture
    local action="$3"

    local interaction_emoji=""
    case "$interaction_type" in
        click) interaction_emoji="🖱️" ;;
        hover) interaction_emoji="👆" ;;
        drag) interaction_emoji="✋" ;;
        voice) interaction_emoji="🎤" ;;
        gesture) interaction_emoji="👋" ;;
        *) interaction_emoji="⚡" ;;
    esac

    rl_log "🔴${interaction_emoji}👉📌" \
        "interaction_added" \
        "$template_name" \
        "$interaction_type → $action"
}

# Template: User session
rl_user_session() {
    local template_name="$1"
    local session_duration="$2"
    local interactions="$3"

    rl_log "🔴👤📊👉" \
        "user_session" \
        "$template_name" \
        "Session: ${session_duration}s, Interactions: $interactions"
}

# ═══════════════════════════════════════════════════════
# INTEGRATION WITH GREENLIGHT
# ═══════════════════════════════════════════════════════

# Helper: Create GreenLight task from RedLight template
rl_create_gl_task() {
    local template_name="$1"
    local task_description="$2"
    local priority="${3:-📌}"

    source "$HOME/memory-greenlight-templates.sh"

    gl_feature \
        "RedLight: $template_name" \
        "$task_description" \
        "🍖" \
        "$priority"
}

# Helper: Update GreenLight on deployment
rl_notify_gl_deploy() {
    local template_name="$1"
    local url="$2"
    local platform="${3:-cloudflare}"

    source "$HOME/memory-greenlight-templates.sh"

    gl_deploy \
        "$template_name" \
        "$url" \
        "RedLight template deployed via $platform" \
        "👉" \
        "🎨"
}

# ═══════════════════════════════════════════════════════
# SHOW HELP
# ═══════════════════════════════════════════════════════

show_help() {
    cat <<'EOF'
RedLight Memory Templates

USAGE:
    source memory-redlight-templates.sh
    rl_<template> [args...]

TEMPLATE MANAGEMENT:

    rl_template_create <name> <category> <description>
        Create new template (world/website/animation/design/game/app/visual)

    rl_template_update <name> <changes> [category]
        Update existing template

    rl_template_delete <name> [reason]
        Delete template

    rl_template_copy <source> <new_name> <purpose>
        Copy template

    rl_template_archive <name> [reason]
        Archive template

DEPLOYMENT:

    rl_template_deploy <name> <url> [platform]
        Deploy template (cloudflare/github/railway/vercel)

    rl_deploy_failed <name> <platform> [error]
        Log deployment failure

    rl_deploy_rollback <name> <from_version> <to_version>
        Rollback deployment

VERSIONING:

    rl_version_release <name> <version> <changes>
        Release new version

    rl_version_tag <name> <tag> <commit>
        Tag version

TESTING:

    rl_test_passed <name> [test_type] [details]
        Log successful test (visual/performance/accessibility)

    rl_test_failed <name> <test_type> <error>
        Log test failure

ANALYTICS:

    rl_analytics_snapshot <name> <views> <interactions> [avg_session]
        Record analytics snapshot

    rl_performance_metrics <name> <fps> <load_time> [memory_mb]
        Record performance metrics

FEATURES:

    rl_feature_added <name> <feature> <description>
        Log new feature

    rl_bug_fixed <name> <bug> <fix>
        Log bug fix

COLLABORATION:

    rl_template_shared <name> <with_who> [platform]
        Log template sharing

    rl_feedback_received <name> <from_who> <feedback>
        Log feedback

WORLD-SPECIFIC:

    rl_world_create <name> [type] <features>
        Create 3D world (planet/city/environment/metaverse)

    rl_biome_add <world_name> <biome_name> <properties>
        Add biome to world

    rl_entity_spawn <world_name> <entity_type> [count]
        Spawn entities in world

ANIMATION-SPECIFIC:

    rl_animation_create <name> [type] [duration]
        Create animation (motion/particle/shader/morph)

    rl_effect_apply <name> <effect_type> [intensity]
        Apply visual effect (glow/bloom/blur/distortion)

DESIGN SYSTEM:

    rl_component_create <name> [type] <variants>
        Create design component (ui/layout/utility)

    rl_theme_update <name> <changes>
        Update theme

INTERACTIVE:

    rl_interaction_add <name> <type> <action>
        Add interaction (click/hover/drag/voice/gesture)

    rl_user_session <name> <duration> <interactions>
        Log user session

GREENLIGHT INTEGRATION:

    rl_create_gl_task <name> <description> [priority]
        Create GreenLight task from template

    rl_notify_gl_deploy <name> <url> [platform]
        Notify GreenLight of deployment

EXAMPLES:

    # Create Earth template
    rl_template_create "blackroad-earth" "world" \
        "Interactive Earth globe with city markers"

    # Deploy to Cloudflare
    rl_template_deploy "blackroad-earth" \
        "https://earth.blackroad.io" \
        "cloudflare"

    # Add biome
    rl_biome_add "blackroad-earth" "tropical-rainforest" \
        "High humidity, dense vegetation, 25-30°C"

    # Record performance
    rl_performance_metrics "blackroad-earth" "60" "1.2" "180"

    # Create GreenLight task
    rl_create_gl_task "blackroad-mars" \
        "Create interactive Mars template with rover missions" \
        "⭐"

CATEGORIES:
    🌍 world      - 3D interactive worlds
    🌐 website    - Landing pages, dashboards
    ✨ animation  - Motion graphics, effects
    🎨 design     - Design systems, components
    🎮 game       - Interactive games
    📱 app        - Web applications
    🖼️ visual     - Visual effects, shaders

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
