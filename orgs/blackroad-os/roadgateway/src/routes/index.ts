/**
 * API Routes for RoadGateway
 */

import { Hono } from 'hono';
import type { Env } from '../index';

export const routes = new Hono<{ Bindings: Env }>();

// Proxy to AI service
routes.all('/ai/*', async (c) => {
  const backendUrl = c.env.BACKEND_URL || 'https://api.blackroad.io';
  const path = c.req.path.replace('/api/ai', '');

  const response = await fetch(`${backendUrl}/ai${path}`, {
    method: c.req.method,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': c.req.header('Authorization') || '',
    },
    body: c.req.method !== 'GET' ? await c.req.text() : undefined,
  });

  const data = await response.json();
  return c.json(data, response.status as any);
});

// Service discovery
routes.get('/services', (c) => {
  return c.json({
    services: [
      { name: 'roadai', url: '/api/ai', status: 'active' },
      { name: 'auth', url: '/api/auth', status: 'active' },
      { name: 'storage', url: '/api/storage', status: 'active' },
    ],
  });
});

// Echo endpoint for testing
routes.all('/echo', async (c) => {
  return c.json({
    method: c.req.method,
    path: c.req.path,
    headers: Object.fromEntries(c.req.raw.headers),
    query: c.req.query(),
    body: c.req.method !== 'GET' ? await c.req.text() : null,
    timestamp: new Date().toISOString(),
  });
});

// Version info
routes.get('/version', (c) => {
  return c.json({
    gateway: '0.1.0',
    environment: c.env.ENVIRONMENT,
    runtime: 'Cloudflare Workers',
  });
});
