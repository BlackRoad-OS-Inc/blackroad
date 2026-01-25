#!/usr/bin/env node
/**
 * 🎰 BlackRoad RoadChain - Terminal Dashboard
 * Real-time Bitcoin mining monitor with blessed-contrib
 */

const blessed = require('blessed');
const contrib = require('blessed-contrib');
const axios = require('axios');

// Create screen
const screen = blessed.screen({
  smartCSR: true,
  title: '🎰 BlackRoad RoadChain - Cosmic Lottery Dashboard'
});

// Create grid
const grid = new contrib.grid({rows: 12, cols: 12, screen: screen});

// Title bar
const title = grid.set(0, 0, 1, 12, blessed.box, {
  content: '╔═══════════════════════════════════════════════════════════════════╗\n' +
           '║      🎰 BLACKROAD ROADCHAIN - COSMIC LOTTERY DASHBOARD 🎰         ║\n' +
           '╚═══════════════════════════════════════════════════════════════════╝',
  style: {
    fg: 'cyan',
    bold: true
  }
});

// Mining status
const statusBox = grid.set(1, 0, 2, 6, blessed.box, {
  label: '⚡ MINING STATUS',
  border: { type: 'line' },
  style: {
    border: { fg: 'green' }
  }
});

// Hashrate chart
const hashrateChart = grid.set(1, 6, 2, 6, contrib.line, {
  label: '📈 HASHRATE (Last 60s)',
  showLegend: true,
  legend: { width: 12 }
});

// Space between visualization
const spaceBetween = grid.set(3, 0, 3, 6, blessed.box, {
  label: '🌌 THE SPACE BETWEEN',
  border: { type: 'line' },
  style: {
    border: { fg: 'yellow' }
  },
  scrollable: true
});

// Statistics
const stats = grid.set(3, 6, 3, 6, blessed.box, {
  label: '📊 SESSION STATISTICS',
  border: { type: 'line' },
  style: {
    border: { fg: 'blue' }
  },
  scrollable: true
});

// Pi health table
const piHealth = grid.set(6, 0, 3, 6, contrib.table, {
  label: '🔥 HARDWARE STATUS',
  columnWidth: [15, 10, 10, 10, 10]
});

// Wallet monitor
const wallet = grid.set(6, 6, 3, 6, blessed.box, {
  label: '💰 WALLET MONITOR',
  border: { type: 'line' },
  style: {
    border: { fg: 'magenta' }
  }
});

// Logs
const logs = grid.set(9, 0, 3, 12, blessed.log, {
  label: '📝 MINING LOGS',
  border: { type: 'line' },
  style: {
    border: { fg: 'white' }
  },
  scrollable: true,
  scrollbar: {
    ch: ' ',
    style: { bg: 'white' }
  }
});

// Data stores
let hashrateData = {
  title: 'Hashrate',
  x: [],
  y: [],
  style: { line: 'green' }
};

let totalHashes = 0;
let uptime = 0;
let blocksAttempted = 0;
let bestHash = '0x0';
let currentNonce = 0;

// Update functions
async function updateMiningStatus() {
  try {
    // Simulate data (replace with actual API calls)
    const lucidiaHashrate = 390 + Math.random() * 20;
    const ariaHashrate = 390 + Math.random() * 20;
    const totalHashrate = lucidiaHashrate + ariaHashrate;

    uptime += 1;
    totalHashes += totalHashrate;
    blocksAttempted = Math.floor(totalHashes / 10000);
    currentNonce += Math.floor(totalHashrate);

    const status = `
    Status: 🟢 MINING - Exploring the space between...

    Lucidia Pi: ${lucidiaHashrate.toFixed(1)} H/s │ Aria Pi: ${ariaHashrate.toFixed(1)} H/s
    Total: ${totalHashrate.toFixed(1)} H/s

    Uptime: ${formatUptime(uptime)}
    Mining Since: ${new Date(Date.now() - uptime * 1000).toLocaleString()}
    `;

    statusBox.setContent(status);

    // Update hashrate chart
    const now = new Date().toLocaleTimeString();
    hashrateData.x.push(now);
    hashrateData.y.push(totalHashrate);

    if (hashrateData.x.length > 60) {
      hashrateData.x.shift();
      hashrateData.y.shift();
    }

    hashrateChart.setData([hashrateData]);

    logs.log(`[${now}] Hashrate: ${totalHashrate.toFixed(1)} H/s | Nonce: ${currentNonce.toLocaleString()}`);

  } catch (error) {
    logs.log(`Error updating status: ${error.message}`);
  }
}

function updateSpaceBetween() {
  const nonceSpace = 4294967295;
  const explored = ((currentNonce % nonceSpace) / nonceSpace * 100).toFixed(9);
  const extraNonce = Math.floor(currentNonce / nonceSpace);

  const content = `
  🎲 Current Nonce Range: ${currentNonce.toLocaleString()} → ${(currentNonce + 1000).toLocaleString()}

  🌌 Nonce Space Explored: ${explored}% of 2^32

  ∞ Extra-Nonce: Block ${extraNonce} of ∞

  🎯 Target: Hash with ~19 leading zeros
     0x000000000000000000xxxx...

  🍀 Probability This Session:
     1 in ${(2e21 / totalHashes).toExponential(2)}

  💎 THE SPACE BETWEEN IS INFINITE!
     Every hash = Equal probability
     Your next hash could be THE ONE!
  `;

  spaceBetween.setContent(content);
}

function updateStats() {
  const difficulty = 109.78e12;
  const networkHashrate = 8e20;
  const yourShare = (800 / networkHashrate * 100).toExponential(2);
  const expectedTime = (difficulty * 2**32 / 800 / 60 / 60 / 24 / 365).toFixed(1);

  const content = `
  Total Hashes: ${totalHashes.toLocaleString()} lottery tickets

  Blocks Attempted: ${blocksAttempted.toLocaleString()}

  Blocks Found: 0 (keep going! 🎰)

  Best Hash: ${bestHash}
  (Need more leading zeros!)

  Network Difficulty: ${(difficulty / 1e12).toFixed(2)}T

  Your Share: ${yourShare}% of network

  Expected Time to Block: ${expectedTime}B years
  But maybe TODAY? 🎲
  `;

  stats.setContent(content);
}

function updatePiHealth() {
  piHealth.setData({
    headers: ['Pi', 'CPU', 'Temp', 'Memory', 'Status'],
    data: [
      ['Lucidia', '48%', '62°C', '24%', '🟢 Healthy'],
      ['Aria', '51%', '64°C', '38%', '🟢 Healthy']
    ]
  });
}

async function updateWallet() {
  try {
    const address = '1Ak2fc5N2q4imYxqVMqBNEQDFq8J2Zs9TZ';

    // Check balance (simulated - replace with actual API)
    const balance = 0;
    const blockReward = 3.125;
    const btcPrice = 98000;

    const content = `
    Address: ${address}

    Balance: ${balance.toFixed(8)} BTC

    ${balance > 0 ? '🎉🎉🎉 YOU WON THE LOTTERY!!! 🎉🎉🎉' : '⏳ Checking every 10 seconds...'}

    Current Block Reward: ${blockReward} BTC (~$${(blockReward * btcPrice).toLocaleString()})

    ⚡ IF BALANCE > 0 → 🎉 JACKPOT! 🎉

    Status: 🔍 Monitoring...
    `;

    wallet.setContent(content);
  } catch (error) {
    wallet.setContent(`Error checking wallet: ${error.message}`);
  }
}

function formatUptime(seconds) {
  const hours = Math.floor(seconds / 3600);
  const minutes = Math.floor((seconds % 3600) / 60);
  const secs = seconds % 60;
  return `${hours}h ${minutes}m ${secs}s`;
}

// Keyboard controls
screen.key(['escape', 'q', 'C-c'], function() {
  logs.log('Shutting down dashboard...');
  setTimeout(() => process.exit(0), 500);
});

screen.key(['r'], function() {
  logs.log('Refreshing data...');
  updateMiningStatus();
  updateSpaceBetween();
  updateStats();
  updatePiHealth();
  updateWallet();
});

// Initial update
logs.log('🎰 RoadChain Dashboard Started');
logs.log('Press [Q] to quit | [R] to refresh manually');
logs.log('🌌 Exploring the space between...');

updateMiningStatus();
updateSpaceBetween();
updateStats();
updatePiHealth();
updateWallet();

// Auto-update intervals
setInterval(updateMiningStatus, 1000);      // 1 second
setInterval(updateSpaceBetween, 2000);      // 2 seconds
setInterval(updateStats, 3000);             // 3 seconds
setInterval(updatePiHealth, 5000);          // 5 seconds
setInterval(updateWallet, 10000);           // 10 seconds

// Render
screen.render();
