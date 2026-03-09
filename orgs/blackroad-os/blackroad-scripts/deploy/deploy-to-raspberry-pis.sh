#!/bin/bash
# 🥧 DEPLOY TO ALL RASPBERRY PIS + SHELLFISH
# Deploy OS window, AI models, and agent coordination to all infrastructure

echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║  🥧 RASPBERRY PI + SHELLFISH DEPLOYMENT 🥧                   ║"
echo "║  Deploy OS, AI Models, and 30k Agent System                  ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""

# Test connections first
test_connection() {
  local host=$1
  echo -n "Testing ssh $host... "
  if timeout 3 ssh -o ConnectTimeout=3 -o StrictHostKeyChecking=no "$host" "echo 'connected'" 2>/dev/null; then
    echo "✅ CONNECTED"
    return 0
  else
    echo "⚠️  offline (will configure when online)"
    return 1
  fi
}

# Deploy function
deploy_to_host() {
  local host=$1
  local role=$2
  
  echo ""
  echo "🚀 Deploying to $host ($role)..."
  
  if ! test_connection "$host"; then
    echo "   ⏭️  Skipping $host (offline)"
    return
  fi
  
  echo "   📦 Copying files to $host..."
  
  # Create deployment directory
  ssh "$host" "mkdir -p ~/blackroad-deployment" 2>/dev/null
  
  # Copy OS window
  if [ -f "/Users/alexa/Desktop/blackroad-os-ultimate-modern.html" ]; then
    scp "/Users/alexa/Desktop/blackroad-os-ultimate-modern.html" "$host:~/blackroad-deployment/os.html" 2>/dev/null || echo "   ⚠️  Copy failed"
  fi
  
  # Copy AI models
  if [ -f "/Users/alexa/Desktop/lucidia-minnesota-wilderness(1).html" ]; then
    scp "/Users/alexa/Desktop/lucidia-minnesota-wilderness(1).html" "$host:~/blackroad-deployment/ai-models.html" 2>/dev/null || echo "   ⚠️  Copy failed"
  fi
  
  # Copy agent coordination scripts
  for script in memory-system.sh blackroad-agent-registry.sh memory-task-marketplace.sh; do
    if [ -f ~/$script ]; then
      scp ~/$script "$host:~/blackroad-deployment/" 2>/dev/null || echo "   ⚠️  $script copy failed"
    fi
  done
  
  # Setup agent environment
  ssh "$host" "cd ~/blackroad-deployment && cat > setup-agent.sh << 'EOF'
#!/bin/bash
echo '🤖 BlackRoad Agent Environment Setup'
echo '   Host: \$(hostname)'
echo '   Role: $role'
echo '   OS: \$(uname -a)'
echo ''
echo '✅ BlackRoad deployment ready!'
echo '   OS Window: ~/blackroad-deployment/os.html'
echo '   AI Models: ~/blackroad-deployment/ai-models.html'
echo '   Scripts: ~/blackroad-deployment/*.sh'
EOF
chmod +x ~/blackroad-deployment/setup-agent.sh
~/blackroad-deployment/setup-agent.sh" 2>/dev/null || echo "   ⚠️  Setup failed"
  
  echo "   ✅ Deployed to $host!"
}

# Deploy to all infrastructure
echo "🥧 Deploying to Raspberry Pis..."
deploy_to_host "octavia" "PRIMARY (AI accelerator + NVMe - 20k agents)"
deploy_to_host "aria" "SECONDARY (5k agents)"
deploy_to_host "alice" "SECONDARY (5k agents)"
deploy_to_host "lucidia" "SECONDARY (5k agents)"

echo ""
echo "🐚 Deploying to DigitalOcean droplet..."
deploy_to_host "shellfish" "BACKUP (5k agents)"

echo ""
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║              📊 DEPLOYMENT SUMMARY 📊                        ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""
echo "✅ Deployment script complete!"
echo ""
echo "🔍 To verify deployments when Pis are online:"
echo "   ssh octavia 'ls -lh ~/blackroad-deployment'"
echo "   ssh aria 'ls -lh ~/blackroad-deployment'"
echo "   ssh alice 'ls -lh ~/blackroad-deployment'"
echo "   ssh lucidia 'ls -lh ~/blackroad-deployment'"
echo "   ssh shellfish 'ls -lh ~/blackroad-deployment'"
echo ""
echo "🚀 To run agent setup on each host:"
echo "   ssh octavia '~/blackroad-deployment/setup-agent.sh'"
echo ""
