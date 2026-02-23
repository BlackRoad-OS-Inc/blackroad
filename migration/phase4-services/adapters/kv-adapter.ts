/**
 * KV Adapter - Redis-backed replacement for Cloudflare KV
 *
 * Drop-in replacement for KVNamespace interface used by Workers.
 * Each KV namespace becomes a Redis key prefix.
 */

import Redis from 'ioredis';

let redis: Redis | null = null;

function getRedis(): Redis {
  if (!redis) {
    redis = new Redis({
      host: process.env.REDIS_HOST || '10.10.0.2',
      port: parseInt(process.env.REDIS_PORT || '6379'),
      password: process.env.REDIS_PASSWORD,
      retryStrategy: (times) => Math.min(times * 100, 3000),
      maxRetriesPerRequest: 3,
    });
  }
  return redis;
}

export interface KVGetOptions {
  type?: 'text' | 'json' | 'arrayBuffer' | 'stream';
  cacheTtl?: number;
}

export interface KVPutOptions {
  expirationTtl?: number;
  expiration?: number;
  metadata?: Record<string, unknown>;
}

export interface KVListResult {
  keys: Array<{ name: string; expiration?: number; metadata?: Record<string, unknown> }>;
  list_complete: boolean;
  cursor?: string;
}

export class KVNamespace {
  constructor(private prefix: string) {}

  async get(key: string, options?: KVGetOptions | string): Promise<any> {
    const r = getRedis();
    const val = await r.get(`${this.prefix}:${key}`);
    if (val === null) return null;

    const type = typeof options === 'string' ? options : options?.type;
    if (type === 'json') {
      try {
        return JSON.parse(val);
      } catch {
        return null;
      }
    }
    return val;
  }

  async getWithMetadata(key: string, options?: KVGetOptions | string): Promise<{
    value: any;
    metadata: Record<string, unknown> | null;
  }> {
    const value = await this.get(key, options);
    const r = getRedis();
    const metaStr = await r.get(`${this.prefix}:${key}:__meta`);
    const metadata = metaStr ? JSON.parse(metaStr) : null;
    return { value, metadata };
  }

  async put(key: string, value: string | ArrayBuffer, options?: KVPutOptions): Promise<void> {
    const r = getRedis();
    const strValue = typeof value === 'string' ? value : Buffer.from(value).toString();

    if (options?.expirationTtl) {
      await r.setex(`${this.prefix}:${key}`, options.expirationTtl, strValue);
    } else if (options?.expiration) {
      const ttl = options.expiration - Math.floor(Date.now() / 1000);
      if (ttl > 0) {
        await r.setex(`${this.prefix}:${key}`, ttl, strValue);
      }
    } else {
      await r.set(`${this.prefix}:${key}`, strValue);
    }

    if (options?.metadata) {
      const metaKey = `${this.prefix}:${key}:__meta`;
      if (options.expirationTtl) {
        await r.setex(metaKey, options.expirationTtl, JSON.stringify(options.metadata));
      } else {
        await r.set(metaKey, JSON.stringify(options.metadata));
      }
    }
  }

  async delete(key: string): Promise<void> {
    const r = getRedis();
    await r.del(`${this.prefix}:${key}`, `${this.prefix}:${key}:__meta`);
  }

  async list(options?: {
    prefix?: string;
    limit?: number;
    cursor?: string;
  }): Promise<KVListResult> {
    const r = getRedis();
    const pattern = options?.prefix
      ? `${this.prefix}:${options.prefix}*`
      : `${this.prefix}:*`;

    const limit = options?.limit || 1000;
    const cursor = options?.cursor || '0';

    const [newCursor, rawKeys] = await r.scan(
      parseInt(cursor),
      'MATCH', pattern,
      'COUNT', limit
    );

    // Filter out metadata keys
    const keys = (rawKeys as string[])
      .filter(k => !k.endsWith(':__meta'))
      .map(k => ({ name: k.replace(`${this.prefix}:`, '') }));

    return {
      keys,
      list_complete: newCursor === '0',
      cursor: newCursor === '0' ? undefined : newCursor,
    };
  }
}

/** Create KV namespaces matching Cloudflare Worker bindings */
export function createKVNamespaces() {
  return {
    CACHE: new KVNamespace('CACHE'),
    IDENTITIES: new KVNamespace('IDENTITIES'),
    API_KEYS: new KVNamespace('API_KEYS'),
    RATE_LIMIT: new KVNamespace('RATE_LIMIT'),
    TOOLS_KV: new KVNamespace('TOOLS_KV'),
    TEMPLATES: new KVNamespace('TEMPLATES'),
    CONTENT: new KVNamespace('CONTENT'),
    SUBSCRIPTIONS_KV: new KVNamespace('SUBSCRIPTIONS_KV'),
    USERS_KV: new KVNamespace('USERS_KV'),
    JOBS: new KVNamespace('JOBS'),
    APPLICATIONS: new KVNamespace('APPLICATIONS'),
  };
}

export async function closeRedis(): Promise<void> {
  if (redis) {
    await redis.quit();
    redis = null;
  }
}
