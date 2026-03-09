#!/bin/bash
# Deploy all BlackRoad domains
set -e

total=0; success=0

deploy_app() {
  local subdomain=$1; local title=$2; local desc=$3
  ((total++))
  echo "[$total] Deploying $subdomain..."
  mkdir -p "/tmp/deploy-$subdomain"
  cat > "/tmp/deploy-$subdomain/index.html" << EOFHTML
<!DOCTYPE html>
<html><head><meta charset="UTF-8"><title>$title</title>
<style>
*{margin:0;padding:0;box-sizing:border-box}
body{background:#000;color:#fff;font-family:'SF Pro Display',-apple-system,sans-serif;min-height:100vh;display:flex;flex-direction:column;align-items:center;justify-content:center;padding:55px;line-height:1.618}
h1{font-size:89px;background:linear-gradient(135deg,#FF1D6C 38.2%,#F5A623 61.8%);-webkit-background-clip:text;-webkit-text-fill-color:transparent;margin-bottom:21px;text-align:center}
p{font-size:21px;color:rgba(255,255,255,0.7);text-align:center;max-width:800px;margin-bottom:34px}
.domain{font-family:'SF Mono',monospace;color:#2979FF;font-size:13px;margin-bottom:55px}
.status{display:inline-block;background:rgba(255,29,108,0.1);border:1px solid #FF1D6C;border-radius:34px;padding:13px 34px;font-size:13px;color:#FF1D6C}
.footer{position:fixed;bottom:34px;text-align:center;font-size:11px;color:rgba(255,255,255,0.4)}
</style>
</head><body>
<h1>$title</h1><p>$desc</p><div class="domain">$subdomain</div>
<div class="status">✅ LIVE</div>
<div class="footer">BlackRoad OS, Inc. © 2026 | CEO: Alexa Amundson</div>
</body></html>
EOFHTML
  cd "/tmp/deploy-$subdomain"
  if wrangler pages deploy . --project-name="$subdomain" --branch=main 2>&1 >/dev/null; then
    echo "   ✅ $subdomain"
    ((success++))
  fi
  cd - >/dev/null
  sleep 1
}

echo "🌌 Deploying all BlackRoad domains..."
deploy_app "roadtrip-blackroad-io" "RoadTrip" "AI-powered journey planning"
deploy_app "pitstop-blackroad-io" "PitStop" "Project management platform"
deploy_app "roadwork-blackroad-io" "RoadWork" "Team collaboration"
deploy_app "fastlane-blackroad-io" "FastLane" "Rapid deployment"
deploy_app "backroad-blackroad-io" "BackRoad" "Backup & recovery"
deploy_app "loadroad-blackroad-io" "LoadRoad" "Load balancing"
deploy_app "roadcoin-blackroad-io" "RoadCoin" "Crypto payments"
deploy_app "roadflow-blackroad-io" "RoadFlow" "Workflow automation"
deploy_app "ai-blackroad-io" "BlackRoad AI" "AI orchestration"
deploy_app "console-blackroad-io" "Console" "Developer console"
deploy_app "dashboard-blackroad-io" "Dashboard" "Real-time monitoring"
deploy_app "api-blackroad-io" "API" "RESTful endpoints"
deploy_app "quantum-blackroad-io" "Quantum" "Quantum computing on Pi"
deploy_app "iot-blackroad-io" "IoT" "ESP32 & Pi fleet"
deploy_app "security-blackroad-io" "Security" "Zero-trust security"
deploy_app "cloud-blackroad-io" "Cloud" "Cloud infrastructure"

echo "✅ $success/$total deployed"
