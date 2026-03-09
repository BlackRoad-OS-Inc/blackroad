#!/bin/bash
# 🧹 Cleanup Alice Pi Storage
# Removes unnecessary CUDA libraries (3GB) from Raspberry Pi

echo "🧹 Cleaning up Alice Pi (192.168.4.49)"
echo "========================================="
echo ""

# Check current storage
echo "📊 Current Storage:"
ssh pi@192.168.4.49 'df -h /'
echo ""

# Show what will be removed
echo "🗑️  Files to be removed:"
echo "   - /usr/local/lib/ollama/cuda_v12/ (~2GB - CUDA 12 libraries)"
echo "   - /usr/local/lib/ollama/cuda_v13/ (~600MB - CUDA 13 libraries)"
echo ""
echo "⚠️  Raspberry Pi doesn't have NVIDIA GPU - these CUDA libraries are not needed"
echo ""

read -p "Continue with cleanup? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cleanup cancelled."
    exit 1
fi

# Remove CUDA libraries
echo ""
echo "🗑️  Removing CUDA libraries..."
ssh pi@192.168.4.49 'sudo rm -rf /usr/local/lib/ollama/cuda_v12 /usr/local/lib/ollama/cuda_v13'
echo "✅ CUDA libraries removed"
echo ""

# Clean apt cache
echo "🧹 Cleaning package cache..."
ssh pi@192.168.4.49 'sudo apt-get clean && sudo apt-get autoclean'
echo "✅ Package cache cleaned"
echo ""

# Remove old logs
echo "📋 Cleaning old system logs (keep last 3 days)..."
ssh pi@192.168.4.49 'sudo journalctl --vacuum-time=3d'
echo "✅ Logs cleaned"
echo ""

# Final storage check
echo "========================================="
echo "📊 Final Storage:"
ssh pi@192.168.4.49 'df -h /'
echo ""

# Show freed space
echo "✅ Cleanup complete!"
echo ""
echo "🖤🛣️ Alice Pi ready for BlackRoad deployments!"
