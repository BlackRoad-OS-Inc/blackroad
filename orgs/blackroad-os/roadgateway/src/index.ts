/**
 * RoadGateway - BlackRoad API Gateway
 *
 * Features:
 * - Smart routing to backend services
 * - Rate limiting with KV storage
 * - Request/response transformation
 * - CORS handling
 * - Authentication middleware
 * - Health checks
 * - Request logging
 */

import { Hono } from 'hono';
import { cors } from 'hono/cors';
import { logger } from 'hono/logger';
import { rateLimiter } from './middleware/rate-limiter';
import { auth } from './middleware/auth';
import { routes } from './routes';

export interface Env {
  RATE_LIMIT: KVNamespace;
  ENVIRONMENT: string;
  API_KEYS?: string;
  BACKEND_URL?: string;
}

const app = new Hono<{ Bindings: Env }>();

// Global middleware
app.use('*', logger());
app.use('*', cors({
  origin: '*',
  allowMethods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowHeaders: ['Content-Type', 'Authorization', 'X-API-Key'],
  exposeHeaders: ['X-RateLimit-Limit', 'X-RateLimit-Remaining', 'X-Request-Id'],
  credentials: true,
}));

// Health check (no auth required)
app.get('/health', (c) => {
  return c.json({
    status: 'healthy',
    service: 'roadgateway',
    version: '0.1.0',
    timestamp: new Date().toISOString(),
  });
});

// Rate limited routes
app.use('/api/*', rateLimiter);

// Root info
app.get('/', (c) => {
  return c.json({
    name: 'RoadGateway',
    version: '0.1.0',
    description: 'BlackRoad API Gateway',
    endpoints: {
      health: '/health',
      api: '/api/*',
      docs: '/docs',
    },
  });
});

// Mount API routes
app.route('/api', routes);

// 404 handler
app.notFound((c) => {
  return c.json({
    error: 'Not Found',
    message: `Route ${c.req.method} ${c.req.path} not found`,
    timestamp: new Date().toISOString(),
  }, 404);
});

// Error handler
app.onError((err, c) => {
  console.error('Gateway Error:', err);
  return c.json({
    error: 'Internal Server Error',
    message: err.message,
    timestamp: new Date().toISOString(),
  }, 500);
});

export default app;
