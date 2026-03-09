#!/bin/bash
# BlackRoad Mesh - Operator User Setup Script
# Run from Mac: ./setup-operator-user.sh <node>
# Example: ./setup-operator-user.sh alice

set -e

NODE=$1
if [ -z "$NODE" ]; then
  echo "Usage: $0 <node>"
  echo "Nodes: alice, lucidia, aria"
  exit 1
fi

echo "Setting up operator user on $NODE..."

# Read your public key
PUBKEY=$(cat $HOME/.ssh/id_br_ed25519.pub)

# Connect and setup
ssh ${NODE}-direct << ENDSCRIPT
set -e

# Set hostname
sudo hostnamectl set-hostname $NODE
echo "$NODE" | sudo tee /etc/hostname > /dev/null
sudo sed -i '/127.0.1.1/d' /etc/hosts
echo "127.0.1.1 $NODE" | sudo tee -a /etc/hosts > /dev/null

# Enable SSH and Avahi
sudo systemctl enable ssh
sudo systemctl start ssh
sudo apt-get update -qq && sudo apt-get install -y -qq avahi-daemon > /dev/null
sudo systemctl enable avahi-daemon
sudo systemctl start avahi-daemon

# Create operator user if doesn't exist
if ! id operator > /dev/null 2>&1; then
  sudo useradd -m -u 2000 -s /bin/bash -G sudo,adm,dialout,video,audio,docker operator
fi

# Set up SSH for operator
sudo mkdir -p /home/operator/.ssh
sudo chmod 700 /home/operator/.ssh

# Add public key
echo "$PUBKEY" | sudo tee /home/operator/.ssh/authorized_keys > /dev/null
sudo chmod 600 /home/operator/.ssh/authorized_keys
sudo chown -R operator:operator /home/operator/.ssh

# Set up passwordless sudo
echo "operator ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/operator > /dev/null
sudo chmod 440 /etc/sudoers.d/operator

# Verify
echo "Verifying operator user..."
sudo -u operator whoami

echo "✓ Operator user setup complete on $NODE"
ENDSCRIPT

echo ""
echo "✓ Setup complete! Testing connection as operator..."
ssh $NODE "hostname && whoami && echo '✓ SSH as operator@$NODE working!'"
