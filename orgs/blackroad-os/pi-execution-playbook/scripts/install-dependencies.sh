#!/bin/bash

# Pi AI Execution Playbook - Dependency Installer
# Installs everything needed to execute the playbook

set -e

echo "🥧🍎 Pi AI Execution Playbook - Installing Dependencies 🥧🍎"
echo "============================================================="
echo ""

# Check OS
if [[ "$OSTYPE" == "darwin"* ]]; then
    OS="mac"
    echo "✓ Detected macOS"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
    echo "✓ Detected Linux"
else
    echo "❌ Unsupported OS: $OSTYPE"
    exit 1
fi

echo ""
echo "Installing required tools..."
echo ""

# 1. Git
if command -v git &> /dev/null; then
    echo "✓ Git already installed: $(git --version)"
else
    echo "Installing Git..."
    if [[ "$OS" == "mac" ]]; then
        brew install git
    else
        sudo apt-get update && sudo apt-get install -y git
    fi
fi

# 2. GitHub CLI
if command -v gh &> /dev/null; then
    echo "✓ GitHub CLI already installed: $(gh --version | head -n1)"
else
    echo "Installing GitHub CLI..."
    if [[ "$OS" == "mac" ]]; then
        brew install gh
    else
        curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
        sudo apt update && sudo apt install -y gh
    fi
    echo "Please authenticate with GitHub:"
    gh auth login
fi

# 3. jq (JSON processor)
if command -v jq &> /dev/null; then
    echo "✓ jq already installed"
else
    echo "Installing jq..."
    if [[ "$OS" == "mac" ]]; then
        brew install jq
    else
        sudo apt-get install -y jq
    fi
fi

# 4. Node.js & npm (for some automation)
if command -v node &> /dev/null; then
    echo "✓ Node.js already installed: $(node --version)"
else
    echo "Installing Node.js..."
    if [[ "$OS" == "mac" ]]; then
        brew install node
    else
        curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
        sudo apt-get install -y nodejs
    fi
fi

# 5. Python3 & pip (for automation scripts)
if command -v python3 &> /dev/null; then
    echo "✓ Python3 already installed: $(python3 --version)"
else
    echo "Installing Python3..."
    if [[ "$OS" == "mac" ]]; then
        brew install python3
    else
        sudo apt-get install -y python3 python3-pip
    fi
fi

echo ""
echo "============================================================="
echo "✓ All dependencies installed successfully!"
echo ""
echo "Next steps:"
echo "  1. Copy .env.example to .env and configure"
echo "  2. Run ./scripts/verify-setup.sh to verify everything"
echo "  3. Start Day 0 preparation!"
echo ""
echo "🥧🍎 Same Energy • 1% Cost • 100% Sovereignty 🥧🍎"
