// BlackRoad Chrome Extension - Popup Script

const API_BASE = 'https://api.blackroad.io/v1';

let apiKey = '';

// Initialize popup
document.addEventListener('DOMContentLoaded', async () => {
  await loadSettings();
  setupEventListeners();

  if (apiKey) {
    await checkConnection();
  }
});

// Load settings from storage
async function loadSettings() {
  const result = await chrome.storage.sync.get(['apiKey']);
  apiKey = result.apiKey || '';
}

// Setup event listeners
function setupEventListeners() {
  document.getElementById('settingsBtn').addEventListener('click', openSettings);
  document.getElementById('connectBtn').addEventListener('click', promptApiKey);
  document.getElementById('deployBtn').addEventListener('click', () => quickAction('deploy'));
  document.getElementById('taskBtn').addEventListener('click', () => quickAction('task'));
  document.getElementById('logBtn').addEventListener('click', () => quickAction('log'));
}

// Open settings page
function openSettings() {
  chrome.runtime.openOptionsPage();
}

// Prompt for API key
async function promptApiKey() {
  const key = prompt('Enter your BlackRoad API key:');
  if (key) {
    apiKey = key;
    await chrome.storage.sync.set({ apiKey: key });
    await checkConnection();
  }
}

// Check API connection
async function checkConnection() {
  const statusDot = document.getElementById('statusDot');
  const connectPrompt = document.getElementById('connectPrompt');
  const content = document.getElementById('content');

  try {
    const health = await apiRequest('GET', '/health');

    if (health.status === 'healthy') {
      statusDot.className = 'status-dot connected';
      connectPrompt.style.display = 'none';
      content.style.display = 'block';
      await loadDashboard();
    }
  } catch (error) {
    console.error('Connection failed:', error);
    statusDot.className = 'status-dot error';
    connectPrompt.style.display = 'block';
    content.style.display = 'none';
  }
}

// Load dashboard data
async function loadDashboard() {
  try {
    const [agentStats, taskStats, memoryStats, recentActivity] = await Promise.all([
      apiRequest('GET', '/agents/stats'),
      apiRequest('GET', '/tasks/stats'),
      apiRequest('GET', '/memory/stats'),
      apiRequest('GET', '/memory?limit=5')
    ]);

    document.getElementById('agentCount').textContent = agentStats.total || 0;
    document.getElementById('taskCount').textContent = taskStats.total || 0;
    document.getElementById('memoryCount').textContent = memoryStats.total || 0;

    renderActivity(recentActivity.entries || []);
  } catch (error) {
    console.error('Failed to load dashboard:', error);
  }
}

// Render activity list
function renderActivity(entries) {
  const activityList = document.getElementById('activityList');

  if (entries.length === 0) {
    activityList.innerHTML = '<div class="loading">No recent activity</div>';
    return;
  }

  const icons = {
    deployed: '🚀',
    created: '➕',
    updated: '✏️',
    fixed: '🔧',
    configured: '⚙️',
    milestone: '⭐',
    til: '💡',
    announce: '📢',
    progress: '📊'
  };

  activityList.innerHTML = entries.map(entry => `
    <div class="activity-item">
      <span class="activity-icon">${icons[entry.action] || '📌'}</span>
      <div class="activity-content">
        <div class="activity-action">${entry.action}</div>
        <div class="activity-entity">${entry.entity}</div>
      </div>
      <span class="activity-time">${formatTime(entry.timestamp)}</span>
    </div>
  `).join('');
}

// Format timestamp
function formatTime(timestamp) {
  const date = new Date(timestamp);
  const now = new Date();
  const diffMs = now - date;
  const diffMins = Math.floor(diffMs / 60000);
  const diffHours = Math.floor(diffMs / 3600000);
  const diffDays = Math.floor(diffMs / 86400000);

  if (diffMins < 1) return 'now';
  if (diffMins < 60) return `${diffMins}m`;
  if (diffHours < 24) return `${diffHours}h`;
  return `${diffDays}d`;
}

// Quick actions
async function quickAction(action) {
  switch (action) {
    case 'deploy':
      const projectName = prompt('Project name to deploy:');
      if (projectName) {
        try {
          const task = await apiRequest('POST', '/tasks', {
            title: `Deploy ${projectName}`,
            description: `Deploy project ${projectName} to production`,
            priority: 'high',
            division: 'OS'
          });
          showNotification('Deployment Started', `Task created: ${task.id}`);
          await loadDashboard();
        } catch (error) {
          alert('Failed to create deployment task: ' + error.message);
        }
      }
      break;

    case 'task':
      const taskTitle = prompt('Task title:');
      if (taskTitle) {
        try {
          const task = await apiRequest('POST', '/tasks', {
            title: taskTitle,
            priority: 'medium'
          });
          showNotification('Task Created', task.id);
          await loadDashboard();
        } catch (error) {
          alert('Failed to create task: ' + error.message);
        }
      }
      break;

    case 'log':
      const entity = prompt('Entity name:');
      if (entity) {
        const details = prompt('Details (optional):');
        try {
          const entry = await apiRequest('POST', '/memory', {
            action: 'updated',
            entity: entity,
            details: details || undefined
          });
          showNotification('Logged', `Hash: ${entry.hash.substring(0, 8)}...`);
          await loadDashboard();
        } catch (error) {
          alert('Failed to log: ' + error.message);
        }
      }
      break;
  }
}

// Show notification
function showNotification(title, message) {
  chrome.runtime.sendMessage({
    type: 'notification',
    title: title,
    message: message
  });
}

// API request helper
async function apiRequest(method, endpoint, body) {
  const url = `${API_BASE}${endpoint}`;

  const options = {
    method,
    headers: {
      'Authorization': `Bearer ${apiKey}`,
      'Content-Type': 'application/json'
    }
  };

  if (body) {
    options.body = JSON.stringify(body);
  }

  const response = await fetch(url, options);

  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(`API error (${response.status}): ${errorText}`);
  }

  return response.json();
}
