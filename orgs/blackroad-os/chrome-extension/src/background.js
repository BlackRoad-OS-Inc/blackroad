// BlackRoad Chrome Extension - Background Service Worker

const API_BASE = 'https://api.blackroad.io/v1';
const CHECK_INTERVAL = 5; // minutes

// Initialize on install
chrome.runtime.onInstalled.addListener(() => {
  console.log('BlackRoad extension installed');
  setupAlarms();
});

// Setup periodic checks
function setupAlarms() {
  chrome.alarms.create('checkStatus', { periodInMinutes: CHECK_INTERVAL });
}

// Handle alarms
chrome.alarms.onAlarm.addListener(async (alarm) => {
  if (alarm.name === 'checkStatus') {
    await checkForUpdates();
  }
});

// Check for updates and notify
async function checkForUpdates() {
  const { apiKey, notifications } = await chrome.storage.sync.get(['apiKey', 'notifications']);

  if (!apiKey || notifications === false) return;

  try {
    // Check for urgent tasks
    const response = await fetch(`${API_BASE}/tasks?priority=urgent&status=pending`, {
      headers: {
        'Authorization': `Bearer ${apiKey}`,
        'Content-Type': 'application/json'
      }
    });

    if (response.ok) {
      const data = await response.json();
      const tasks = data.tasks || [];

      if (tasks.length > 0) {
        const { lastNotifiedTasks } = await chrome.storage.local.get(['lastNotifiedTasks']);
        const notified = lastNotifiedTasks || [];

        const newTasks = tasks.filter(t => !notified.includes(t.id));

        if (newTasks.length > 0) {
          chrome.notifications.create({
            type: 'basic',
            iconUrl: '../icons/icon128.png',
            title: 'BlackRoad: Urgent Tasks',
            message: `${newTasks.length} urgent task(s) pending`,
            priority: 2
          });

          await chrome.storage.local.set({
            lastNotifiedTasks: [...notified, ...newTasks.map(t => t.id)]
          });
        }
      }
    }
  } catch (error) {
    console.error('Failed to check for updates:', error);
  }
}

// Handle messages from popup
chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
  if (message.type === 'notification') {
    chrome.notifications.create({
      type: 'basic',
      iconUrl: '../icons/icon128.png',
      title: `BlackRoad: ${message.title}`,
      message: message.message,
      priority: 1
    });
  }
});

// Handle notification clicks
chrome.notifications.onClicked.addListener((notificationId) => {
  chrome.tabs.create({ url: 'https://console.blackroad.io' });
  chrome.notifications.clear(notificationId);
});

// Update badge based on pending tasks
async function updateBadge() {
  const { apiKey } = await chrome.storage.sync.get(['apiKey']);

  if (!apiKey) {
    chrome.action.setBadgeText({ text: '' });
    return;
  }

  try {
    const response = await fetch(`${API_BASE}/tasks/stats`, {
      headers: {
        'Authorization': `Bearer ${apiKey}`,
        'Content-Type': 'application/json'
      }
    });

    if (response.ok) {
      const stats = await response.json();
      const pending = stats.pending || 0;

      if (pending > 0) {
        chrome.action.setBadgeText({ text: pending > 99 ? '99+' : String(pending) });
        chrome.action.setBadgeBackgroundColor({ color: '#FF1D6C' });
      } else {
        chrome.action.setBadgeText({ text: '' });
      }
    }
  } catch (error) {
    console.error('Failed to update badge:', error);
  }
}

// Update badge periodically
chrome.alarms.onAlarm.addListener((alarm) => {
  if (alarm.name === 'checkStatus') {
    updateBadge();
  }
});

// Update badge when storage changes
chrome.storage.onChanged.addListener((changes, area) => {
  if (area === 'sync' && changes.apiKey) {
    updateBadge();
  }
});

// Initial badge update
updateBadge();
