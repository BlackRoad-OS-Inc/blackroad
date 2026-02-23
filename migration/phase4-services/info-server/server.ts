/**
 * BlackRoad Info Server - Consolidated Boilerplate Workers
 *
 * Replaces 16 Tier 4 Workers that just return JSON metadata.
 * Port: 8090
 */

import { Hono } from 'hono';
import { serve } from '@hono/node-server';

const app = new Hono();

const SERVICES: Record<string, {
  name: string;
  type: string;
  description: string;
  status: string;
  repo?: string;
}> = {
  'blackroad-os-core': { name: 'Core Library', type: 'library', description: 'Shared types, contracts, primitives', status: 'active' },
  'blackroad-os-helper': { name: 'Helper Service', type: 'service', description: 'Assistant and helper agent', status: 'active' },
  'blackroad-os-docs': { name: 'Documentation', type: 'docs', description: 'Guides, tutorials, API reference', status: 'active', repo: 'BlackRoad-OS/blackroad-os-docs' },
  'blackroad-cli': { name: 'CLI Tools', type: 'cli', description: 'Command-line interface', status: 'active', repo: 'BlackRoad-OS/blackroad-cli' },
  'blackroad-agents': { name: 'Agent System', type: 'service', description: 'Agent orchestration', status: 'active' },
  'blackroad-agent-os': { name: 'Agent OS', type: 'platform', description: 'Agent operating system', status: 'active' },
  'blackroad-hello': { name: 'Hello World', type: 'demo', description: 'Example service', status: 'active' },
  'containers-template': { name: 'Container Template', type: 'template', description: 'Docker/K8s templates', status: 'active' },
  'lucidia-core': { name: 'Lucidia Core', type: 'ai', description: 'AI reasoning engine', status: 'active' },
  'blackroad-pi-ops': { name: 'Pi Operations', type: 'iot', description: 'Raspberry Pi management', status: 'active' },
  'blackroad-tools': { name: 'Tools', type: 'tools', description: 'CRM/ERP adapters', status: 'active' },
  'blackroad-os-metaverse': { name: 'Metaverse', type: 'app', description: '3D world visualization', status: 'active' },
  'blackroad-os-pitstop': { name: 'Pitstop', type: 'portal', description: 'Portal and quick links hub', status: 'active' },
  'blackroad-os-roadworld': { name: 'RoadWorld', type: 'app', description: 'World simulation services', status: 'active' },
  'blackroad-os-dashboard': { name: 'Dashboard', type: 'ui', description: 'Monitoring dashboard', status: 'active' },
  'blackroad-os-mesh': { name: 'Mesh', type: 'service', description: 'WebSocket mesh network', status: 'active' },
};

app.get('/health', (c) => c.json({
  status: 'healthy',
  service: 'info-server',
  services_count: Object.keys(SERVICES).length,
  source: 'self-hosted',
  timestamp: new Date().toISOString(),
}));

app.get('/services', (c) => c.json({
  services: Object.entries(SERVICES).map(([id, info]) => ({ id, ...info })),
  count: Object.keys(SERVICES).length,
}));

app.get('/services/:id', (c) => {
  const id = c.req.param('id');
  const info = SERVICES[id];
  if (!info) return c.json({ error: 'Service not found' }, 404);
  return c.json({ id, ...info, timestamp: new Date().toISOString() });
});

// Catch-all: try to match by hostname
app.get('*', (c) => {
  const host = c.req.header('host') || '';
  const sub = host.split('.')[0].toLowerCase();

  // Try to match hostname to a service
  const matchedKey = Object.keys(SERVICES).find(k =>
    k.replace('blackroad-', '').replace('os-', '').includes(sub) || sub.includes(k.replace('blackroad-', ''))
  );

  if (matchedKey) {
    const info = SERVICES[matchedKey];
    return c.json({
      ...info,
      id: matchedKey,
      timestamp: new Date().toISOString(),
      source: 'self-hosted',
    });
  }

  return c.json({
    service: 'BlackRoad Info Server',
    version: '1.0.0',
    description: 'Consolidated service metadata endpoint',
    available_services: Object.keys(SERVICES).length,
    endpoints: {
      '/health': 'GET - Health check',
      '/services': 'GET - List all services',
      '/services/:id': 'GET - Get service details',
    },
    timestamp: new Date().toISOString(),
  });
});

const PORT = parseInt(process.env.PORT || '8090');
console.log(`[info-server] Starting on port ${PORT}`);

serve({ fetch: app.fetch, port: PORT }, (info) => {
  console.log(`[info-server] Listening on http://0.0.0.0:${info.port}`);
});

export default app;
