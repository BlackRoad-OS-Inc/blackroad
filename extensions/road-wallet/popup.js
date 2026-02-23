// ROAD Wallet Extension — Popup Logic

const BALANCE = 1026950.51;
const BTC_RESERVE = 0.22001506;
const COINGECKO_URL = 'https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd';
const DASHBOARD_URL = 'https://road.blackroad.io';
const FALLBACK_PRICE = 96400;

function formatUSD(n) {
  if (n >= 1e9) return '$' + (n / 1e9).toFixed(2) + 'B';
  if (n >= 1e6) return '$' + (n / 1e6).toFixed(2) + 'M';
  if (n >= 1e3) return '$' + n.toLocaleString('en-US', { maximumFractionDigits: 0 });
  return '$' + n.toFixed(2);
}

function updatePrices(btcPrice) {
  const btcEl = document.getElementById('btc-price');
  const balUsdEl = document.getElementById('balance-usd');
  const resUsdEl = document.getElementById('reserve-usd');

  btcEl.textContent = '$' + btcPrice.toLocaleString('en-US', { maximumFractionDigits: 0 });
  balUsdEl.textContent = formatUSD(BALANCE * btcPrice);
  resUsdEl.textContent = formatUSD(BTC_RESERVE * btcPrice);
}

async function fetchPrice() {
  try {
    // Try cached price first
    if (typeof chrome !== 'undefined' && chrome.storage) {
      const cached = await chrome.storage.local.get(['btcPrice', 'priceTimestamp']);
      if (cached.btcPrice && cached.priceTimestamp && Date.now() - cached.priceTimestamp < 60000) {
        updatePrices(cached.btcPrice);
      }
    }

    // Fetch live price
    const res = await fetch(COINGECKO_URL);
    if (!res.ok) throw new Error('API error');
    const data = await res.json();
    const price = data.bitcoin.usd;

    updatePrices(price);

    // Cache price
    if (typeof chrome !== 'undefined' && chrome.storage) {
      chrome.storage.local.set({ btcPrice: price, priceTimestamp: Date.now() });
    }
  } catch (e) {
    // Use cached or fallback
    if (typeof chrome !== 'undefined' && chrome.storage) {
      const cached = await chrome.storage.local.get(['btcPrice']);
      updatePrices(cached.btcPrice || FALLBACK_PRICE);
    } else {
      updatePrices(FALLBACK_PRICE);
    }
  }
}

// Copy to clipboard
function showToast(msg) {
  const toast = document.getElementById('toast');
  toast.textContent = msg || 'Copied!';
  toast.classList.add('show');
  setTimeout(() => toast.classList.remove('show'), 1500);
}

document.querySelectorAll('.hash-value[data-copy]').forEach(el => {
  el.addEventListener('click', () => {
    const text = el.getAttribute('data-copy');
    navigator.clipboard.writeText(text).then(() => {
      el.classList.add('copied');
      showToast('Copied!');
      setTimeout(() => el.classList.remove('copied'), 2000);
    });
  });
});

// Open dashboard
document.getElementById('open-dashboard').addEventListener('click', (e) => {
  e.preventDefault();
  if (typeof chrome !== 'undefined' && chrome.tabs) {
    chrome.tabs.create({ url: DASHBOARD_URL });
  } else {
    window.open(DASHBOARD_URL, '_blank');
  }
});

// Init
fetchPrice();
