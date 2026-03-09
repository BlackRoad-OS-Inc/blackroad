/**
 * Rate Limiter Middleware
 * Uses Cloudflare KV for distributed rate limiting
 */

import { Context, Next } from 'hono';
import type { Env } from '../index';

interface RateLimitConfig {
  windowMs: number;   // Time window in ms
  max: number;        // Max requests per window
  keyPrefix: string;  // Key prefix in KV
}

const defaultConfig: RateLimitConfig = {
  windowMs: 60000,    // 1 minute
  max: 100,           // 100 requests per minute
  keyPrefix: 'rl:',
};

export const rateLimiter = async (c: Context<{ Bindings: Env }>, next: Next) => {
  const config = defaultConfig;
  const kv = c.env.RATE_LIMIT;

  if (!kv) {
    // If KV not configured, skip rate limiting
    return next();
  }

  // Get client identifier (IP or API key)
  const clientId = c.req.header('X-API-Key') ||
                   c.req.header('CF-Connecting-IP') ||
                   'anonymous';

  const key = `${config.keyPrefix}${clientId}`;
  const now = Date.now();
  const windowStart = Math.floor(now / config.windowMs) * config.windowMs;
  const windowKey = `${key}:${windowStart}`;

  try {
    // Get current count
    const current = await kv.get(windowKey);
    const count = current ? parseInt(current, 10) : 0;

    // Check limit
    if (count >= config.max) {
      c.header('X-RateLimit-Limit', config.max.toString());
      c.header('X-RateLimit-Remaining', '0');
      c.header('X-RateLimit-Reset', (windowStart + config.windowMs).toString());

      return c.json({
        error: 'Too Many Requests',
        message: `Rate limit exceeded. Try again in ${Math.ceil((windowStart + config.windowMs - now) / 1000)} seconds`,
        retryAfter: Math.ceil((windowStart + config.windowMs - now) / 1000),
      }, 429);
    }

    // Increment counter
    await kv.put(windowKey, (count + 1).toString(), {
      expirationTtl: Math.ceil(config.windowMs / 1000) + 60, // TTL + buffer
    });

    // Set headers
    c.header('X-RateLimit-Limit', config.max.toString());
    c.header('X-RateLimit-Remaining', (config.max - count - 1).toString());
    c.header('X-RateLimit-Reset', (windowStart + config.windowMs).toString());

  } catch (error) {
    // On error, allow request (fail open)
    console.error('Rate limit error:', error);
  }

  return next();
};
