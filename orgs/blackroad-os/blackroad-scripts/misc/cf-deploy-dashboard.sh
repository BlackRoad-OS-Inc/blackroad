#!/usr/bin/env bash
# Simple deployment script for Cloudflare monitoring dashboard

cd ~/cloudflare-dashboard-deploy
wrangler pages deploy . --project-name=blackroad-monitoring --branch=main
