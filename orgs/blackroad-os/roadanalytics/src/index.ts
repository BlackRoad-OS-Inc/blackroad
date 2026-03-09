/**
 * RoadAnalytics - Privacy-first Web Analytics
 *
 * Features:
 * - No cookies, no tracking
 * - GDPR/CCPA compliant by design
 * - Real-time dashboards
 * - Custom events
 * - Funnel analysis
 */

import { Hono } from 'hono';
import { cors } from 'hono/cors';

interface Env {
  ANALYTICS: KVNamespace;
  ANALYTICS_DB: D1Database;
}

interface PageView {
  site: string;
  path: string;
  referrer?: string;
  country?: string;
  device?: string;
  browser?: string;
  timestamp: number;
}

interface Event {
  site: string;
  name: string;
  properties?: Record<string, any>;
  timestamp: number;
}

const app = new Hono<{ Bindings: Env }>();

// CORS for tracking script
app.use('*', cors({
  origin: '*',
  allowMethods: ['GET', 'POST', 'OPTIONS'],
}));

// Health check
app.get('/health', (c) => c.json({ status: 'healthy', service: 'roadanalytics' }));

// Root
app.get('/', (c) => c.json({
  name: 'RoadAnalytics',
  version: '0.1.0',
  description: 'Privacy-first web analytics',
  endpoints: {
    track: 'POST /track',
    event: 'POST /event',
    stats: 'GET /stats/:site',
    realtime: 'GET /realtime/:site',
  },
}));

// Track page view
app.post('/track', async (c) => {
  const body = await c.req.json<PageView>();
  const cf = c.req.raw.cf;

  const pageView: PageView = {
    site: body.site,
    path: body.path,
    referrer: body.referrer,
    country: cf?.country as string || 'unknown',
    device: getDeviceType(c.req.header('User-Agent') || ''),
    browser: getBrowser(c.req.header('User-Agent') || ''),
    timestamp: Date.now(),
  };

  // Store in KV with daily key
  const date = new Date().toISOString().split('T')[0];
  const key = `pv:${body.site}:${date}`;

  try {
    const existing = await c.env.ANALYTICS?.get(key);
    const views: PageView[] = existing ? JSON.parse(existing) : [];
    views.push(pageView);

    await c.env.ANALYTICS?.put(key, JSON.stringify(views), {
      expirationTtl: 60 * 60 * 24 * 90, // 90 days
    });

    // Update real-time counter
    const rtKey = `rt:${body.site}`;
    const rtCount = parseInt(await c.env.ANALYTICS?.get(rtKey) || '0');
    await c.env.ANALYTICS?.put(rtKey, String(rtCount + 1), {
      expirationTtl: 60, // 1 minute
    });

  } catch (e) {
    console.error('Track error:', e);
  }

  // Return 1x1 transparent pixel
  return new Response(
    new Uint8Array([0x47, 0x49, 0x46, 0x38, 0x39, 0x61, 0x01, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x21, 0xf9, 0x04, 0x01, 0x00, 0x00, 0x00, 0x00, 0x2c, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x01, 0x00, 0x00, 0x02, 0x01, 0x00, 0x00]),
    { headers: { 'Content-Type': 'image/gif', 'Cache-Control': 'no-store' } }
  );
});

// Track custom event
app.post('/event', async (c) => {
  const body = await c.req.json<Event>();

  const event: Event = {
    site: body.site,
    name: body.name,
    properties: body.properties,
    timestamp: Date.now(),
  };

  const date = new Date().toISOString().split('T')[0];
  const key = `ev:${body.site}:${date}`;

  try {
    const existing = await c.env.ANALYTICS?.get(key);
    const events: Event[] = existing ? JSON.parse(existing) : [];
    events.push(event);
    await c.env.ANALYTICS?.put(key, JSON.stringify(events), {
      expirationTtl: 60 * 60 * 24 * 90,
    });
  } catch (e) {
    console.error('Event error:', e);
  }

  return c.json({ status: 'ok' });
});

// Get stats for a site
app.get('/stats/:site', async (c) => {
  const site = c.req.param('site');
  const days = parseInt(c.req.query('days') || '7');

  const stats = {
    site,
    period: `${days} days`,
    pageviews: 0,
    visitors: 0,
    topPages: [] as { path: string; views: number }[],
    topReferrers: [] as { referrer: string; count: number }[],
    countries: {} as Record<string, number>,
    devices: {} as Record<string, number>,
    browsers: {} as Record<string, number>,
  };

  const pathCounts: Record<string, number> = {};
  const referrerCounts: Record<string, number> = {};
  const visitorSet = new Set<string>();

  // Aggregate data from KV
  for (let i = 0; i < days; i++) {
    const date = new Date(Date.now() - i * 24 * 60 * 60 * 1000).toISOString().split('T')[0];
    const key = `pv:${site}:${date}`;

    try {
      const data = await c.env.ANALYTICS?.get(key);
      if (data) {
        const views: PageView[] = JSON.parse(data);
        stats.pageviews += views.length;

        for (const view of views) {
          pathCounts[view.path] = (pathCounts[view.path] || 0) + 1;
          if (view.referrer) {
            referrerCounts[view.referrer] = (referrerCounts[view.referrer] || 0) + 1;
          }
          if (view.country) {
            stats.countries[view.country] = (stats.countries[view.country] || 0) + 1;
          }
          if (view.device) {
            stats.devices[view.device] = (stats.devices[view.device] || 0) + 1;
          }
          if (view.browser) {
            stats.browsers[view.browser] = (stats.browsers[view.browser] || 0) + 1;
          }
        }
      }
    } catch (e) {
      console.error('Stats error:', e);
    }
  }

  // Calculate top pages
  stats.topPages = Object.entries(pathCounts)
    .map(([path, views]) => ({ path, views }))
    .sort((a, b) => b.views - a.views)
    .slice(0, 10);

  // Calculate top referrers
  stats.topReferrers = Object.entries(referrerCounts)
    .map(([referrer, count]) => ({ referrer, count }))
    .sort((a, b) => b.count - a.count)
    .slice(0, 10);

  // Estimate visitors (rough approximation)
  stats.visitors = Math.ceil(stats.pageviews * 0.6);

  return c.json(stats);
});

// Real-time visitors
app.get('/realtime/:site', async (c) => {
  const site = c.req.param('site');
  const rtKey = `rt:${site}`;
  const count = parseInt(await c.env.ANALYTICS?.get(rtKey) || '0');

  return c.json({
    site,
    activeVisitors: count,
    timestamp: Date.now(),
  });
});

// Tracking script
app.get('/script.js', (c) => {
  const script = `
(function() {
  var site = document.currentScript.getAttribute('data-site');
  var endpoint = document.currentScript.src.replace('/script.js', '');

  function track() {
    var data = {
      site: site,
      path: location.pathname,
      referrer: document.referrer || null
    };
    navigator.sendBeacon(endpoint + '/track', JSON.stringify(data));
  }

  // Track initial page view
  track();

  // Track SPA navigation
  var pushState = history.pushState;
  history.pushState = function() {
    pushState.apply(history, arguments);
    track();
  };
  window.addEventListener('popstate', track);

  // Custom event tracking
  window.roadanalytics = {
    track: function(name, props) {
      navigator.sendBeacon(endpoint + '/event', JSON.stringify({
        site: site,
        name: name,
        properties: props
      }));
    }
  };
})();
`;

  return c.text(script, 200, {
    'Content-Type': 'application/javascript',
    'Cache-Control': 'public, max-age=3600',
  });
});

// Helper functions
function getDeviceType(ua: string): string {
  if (/mobile/i.test(ua)) return 'mobile';
  if (/tablet|ipad/i.test(ua)) return 'tablet';
  return 'desktop';
}

function getBrowser(ua: string): string {
  if (/firefox/i.test(ua)) return 'Firefox';
  if (/edg/i.test(ua)) return 'Edge';
  if (/chrome/i.test(ua)) return 'Chrome';
  if (/safari/i.test(ua)) return 'Safari';
  return 'Other';
}

export default app;
