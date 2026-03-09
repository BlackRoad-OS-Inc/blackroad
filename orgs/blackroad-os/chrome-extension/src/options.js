// BlackRoad Chrome Extension - Options Page

const DEFAULT_API_URL = 'https://api.blackroad.io/v1';

// Load settings on page load
document.addEventListener('DOMContentLoaded', async () => {
  await loadSettings();
  setupEventListeners();
});

// Load settings from storage
async function loadSettings() {
  const settings = await chrome.storage.sync.get([
    'apiKey',
    'apiUrl',
    'notifications',
    'urgentOnly'
  ]);

  document.getElementById('apiKey').value = settings.apiKey || '';
  document.getElementById('apiUrl').value = settings.apiUrl || DEFAULT_API_URL;
  document.getElementById('notifications').checked = settings.notifications !== false;
  document.getElementById('urgentOnly').checked = settings.urgentOnly || false;
}

// Setup event listeners
function setupEventListeners() {
  document.getElementById('saveBtn').addEventListener('click', saveSettings);
  document.getElementById('testBtn').addEventListener('click', testConnection);
}

// Save settings
async function saveSettings() {
  const apiKey = document.getElementById('apiKey').value.trim();
  const apiUrl = document.getElementById('apiUrl').value.trim() || DEFAULT_API_URL;
  const notifications = document.getElementById('notifications').checked;
  const urgentOnly = document.getElementById('urgentOnly').checked;

  await chrome.storage.sync.set({
    apiKey,
    apiUrl,
    notifications,
    urgentOnly
  });

  showStatus('Settings saved successfully!', 'success');
}

// Test API connection
async function testConnection() {
  const apiKey = document.getElementById('apiKey').value.trim();
  const apiUrl = document.getElementById('apiUrl').value.trim() || DEFAULT_API_URL;

  if (!apiKey) {
    showStatus('Please enter an API key', 'error');
    return;
  }

  try {
    const response = await fetch(`${apiUrl}/health`, {
      headers: {
        'Authorization': `Bearer ${apiKey}`,
        'Content-Type': 'application/json'
      }
    });

    if (response.ok) {
      const data = await response.json();
      if (data.status === 'healthy') {
        showStatus(`Connected! API version: ${data.version}`, 'success');
      } else {
        showStatus('API returned unhealthy status', 'error');
      }
    } else if (response.status === 401) {
      showStatus('Invalid API key', 'error');
    } else {
      showStatus(`API error: ${response.status}`, 'error');
    }
  } catch (error) {
    showStatus(`Connection failed: ${error.message}`, 'error');
  }
}

// Show status message
function showStatus(message, type) {
  const statusEl = document.getElementById('status');
  statusEl.textContent = message;
  statusEl.className = `status ${type}`;
  statusEl.style.display = 'block';

  setTimeout(() => {
    statusEl.style.display = 'none';
  }, 5000);
}
