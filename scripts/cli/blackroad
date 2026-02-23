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
# BlackRoad OS - Unified Command Interface

case "$1" in
    code|c)
        # Launch BlackRoad Code (local AI development)
        shift
        exec ~/.local/bin/blackroad-code "$@"
        ;;
    ai|k)
        # BlackRoad AI Gateway
        shift
        exec ~/.local/bin/blackroad-ai "$@"
        ;;
    local|l)
        # Force local backend
        shift
        exec ~/.local/bin/blackroad-ai -l "$@"
        ;;
    anthropic|a)
        # Force Anthropic backend
        shift
        exec ~/.local/bin/blackroad-ai -a "$@"
        ;;
    openai|o)
        # Force OpenAI backend
        shift
        exec ~/.local/bin/blackroad-ai -o "$@"
        ;;
    models)
        # RoadChain SHA-2048 Model Registry
        shift
        exec python3 -m roadchain models "${@:-stats}"
        ;;
    ai-models)
        # List available AI backend models
        exec ~/.local/bin/blackroad-ai --models
        ;;
    windows|win|w)
        # Windows integration layer
        shift
        exec ~/.local/bin/blackroad-windows "$@"
        ;;
    identity|id)
        # RoadChain SHA-2048 Agent Identity
        shift
        exec python3 -m roadchain identity "$@"
        ;;
    wallet)
        # RoadChain Wallet
        shift
        exec python3 -m roadchain wallet "$@"
        ;;
    chain)
        # RoadChain stats
        shift
        exec python3 -m roadchain "${1:-stats}" "$@"
        ;;
    hash)
        # SHA-2048 hash
        shift
        exec python3 -m roadchain hash "$@"
        ;;
    security|sec)
        # RoadChain Security Scanner
        shift
        case "${1:-fleet}" in
            local)    exec python3 ~/roadchain-security-scan.py --local ;;
            scan)     shift; exec python3 ~/roadchain-security-scan.py --scan "$@" ;;
            discover) exec python3 ~/roadchain-security-scan.py --discover ;;
            fleet)    exec python3 ~/roadchain-security-scan.py --fleet ;;
            harden)   shift; exec python3 ~/roadchain-security-scan.py --harden "$@" ;;
            scores)   exec python3 ~/roadchain-security-scan.py --scores ;;
            alerts)   exec python3 ~/roadchain-security-scan.py --alerts ;;
            report)   exec python3 ~/roadchain-security-scan.py --report ;;
            *)        echo "Usage: br security [local|scan|discover|fleet|harden|scores|alerts|report]" ;;
        esac
        ;;
    stack)
        # Show sovereignty stack
        echo "
BLACKROAD SOVEREIGNTY STACK
═══════════════════════════
LAYER 8: IDENTITY → SHA-2048 (RoadChain, identity > provider)
LAYER 7: API      → blackroad-ai (local/anthropic/openai)
LAYER 6: CDN      → Cloudflare (205 projects, owned)
LAYER 5: DNS      → Pi-hole + Cloudflare DNS
LAYER 4: ISP      → Tailscale mesh (8 devices)
LAYER 3: BACKBONE → Encrypted tunnels
LAYER 2: OS       → macOS, Linux (Pis), Windows (WSL2)
LAYER 1: HARDWARE → M1, Pi cluster, Hailo-8
LAYER 0: YOU      → BlackRoad root
"
        ;;
    *)
        # Default: BlackRoad OS login/menu system
        exec bash ~/blackroad-login.sh "$@"
        ;;
esac
