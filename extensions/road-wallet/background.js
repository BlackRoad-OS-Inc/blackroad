// ROAD Wallet Extension — Background Service Worker

const COINGECKO_URL = 'https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd';
const ALARM_NAME = 'road-price-refresh';

// Fetch and cache BTC price
async function refreshPrice() {
  try {
    const res = await fetch(COINGECKO_URL);
    if (!res.ok) return;
    const data = await res.json();
    const price = data.bitcoin.usd;
    await chrome.storage.local.set({ btcPrice: price, priceTimestamp: Date.now() });

    // Update badge with abbreviated balance
    chrome.action.setBadgeText({ text: '1.02M' });
    chrome.action.setBadgeBackgroundColor({ color: '#FF1D6C' });
  } catch (e) {
    // Silently fail — cached price persists
  }
}

// On install: set initial state and alarm
chrome.runtime.onInstalled.addListener(() => {
  refreshPrice();
  chrome.alarms.create(ALARM_NAME, { periodInMinutes: 1 });
  chrome.action.setBadgeText({ text: '1.02M' });
  chrome.action.setBadgeBackgroundColor({ color: '#FF1D6C' });
});

// On alarm: refresh price
chrome.alarms.onAlarm.addListener((alarm) => {
  if (alarm.name === ALARM_NAME) {
    refreshPrice();
  }
});

// On startup: ensure alarm exists
chrome.runtime.onStartup.addListener(() => {
  refreshPrice();
  chrome.alarms.create(ALARM_NAME, { periodInMinutes: 1 });
});
