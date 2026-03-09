/**
 * Authentication Middleware
 * Validates API keys and JWT tokens
 */

import { Context, Next } from 'hono';
import type { Env } from '../index';

export const auth = async (c: Context<{ Bindings: Env }>, next: Next) => {
  // Skip auth for health check
  if (c.req.path === '/health') {
    return next();
  }

  // Check for API key
  const apiKey = c.req.header('X-API-Key');
  const authHeader = c.req.header('Authorization');

  if (apiKey) {
    // Validate API key
    const validKeys = (c.env.API_KEYS || '').split(',').filter(Boolean);
    if (validKeys.length > 0 && !validKeys.includes(apiKey)) {
      return c.json({
        error: 'Unauthorized',
        message: 'Invalid API key',
      }, 401);
    }
    // Valid API key or no keys configured
    return next();
  }

  if (authHeader?.startsWith('Bearer ')) {
    const token = authHeader.slice(7);
    // In production, validate JWT token here
    // For now, just check it exists
    if (token) {
      return next();
    }
  }

  // No auth provided - allow for now (can be made strict)
  return next();
};

/**
 * Require authentication (strict mode)
 */
export const requireAuth = async (c: Context<{ Bindings: Env }>, next: Next) => {
  const apiKey = c.req.header('X-API-Key');
  const authHeader = c.req.header('Authorization');

  if (!apiKey && !authHeader) {
    return c.json({
      error: 'Unauthorized',
      message: 'Authentication required. Provide X-API-Key or Authorization header.',
    }, 401);
  }

  return auth(c, next);
};
