/**
 * RoadCDN - Content Delivery Network
 *
 * Features:
 * - Edge caching with KV
 * - R2 origin storage
 * - Image optimization
 * - Cache purging
 * - Analytics
 * - Custom domains
 */

import { Hono } from 'hono';
import { cors } from 'hono/cors';

interface Env {
  CACHE: KVNamespace;
  ASSETS: R2Bucket;
  DEFAULT_TTL: string;
  MAX_AGE: string;
}

interface CacheEntry {
  body: string;
  contentType: string;
  etag: string;
  createdAt: number;
  hits: number;
}

interface AssetMeta {
  contentType: string;
  size: number;
  uploadedAt: number;
  origin?: string;
}

const app = new Hono<{ Bindings: Env }>();

app.use('*', cors({
  origin: '*',
  allowMethods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
}));

// Health check
app.get('/health', (c) => c.json({ status: 'healthy', service: 'roadcdn' }));

// Root
app.get('/', (c) => c.json({
  name: 'RoadCDN',
  version: '0.1.0',
  description: 'Content Delivery Network',
  endpoints: {
    serve: 'GET /cdn/:path',
    upload: 'PUT /cdn/:path',
    purge: 'DELETE /cdn/:path',
    purgeAll: 'POST /purge',
    stats: 'GET /stats',
    image: 'GET /image/:path?w=&h=&q=',
  },
}));

// Serve cached content
app.get('/cdn/*', async (c) => {
  const path = c.req.path.replace('/cdn/', '');

  if (!path) {
    return c.json({ error: 'Path required' }, 400);
  }

  // Check If-None-Match for conditional requests
  const ifNoneMatch = c.req.header('If-None-Match');

  // Try KV cache first
  const cacheKey = `cache:${path}`;
  const cached = await c.env.CACHE.get(cacheKey, 'json') as CacheEntry | null;

  if (cached) {
    // Update hit counter
    cached.hits += 1;
    await c.env.CACHE.put(cacheKey, JSON.stringify(cached), {
      expirationTtl: parseInt(c.env.DEFAULT_TTL),
    });

    // Check ETag
    if (ifNoneMatch && ifNoneMatch === cached.etag) {
      return new Response(null, { status: 304 });
    }

    return new Response(cached.body, {
      headers: {
        'Content-Type': cached.contentType,
        'Cache-Control': `public, max-age=${c.env.MAX_AGE}`,
        'ETag': cached.etag,
        'X-Cache': 'HIT',
        'X-Cache-Hits': String(cached.hits),
      },
    });
  }

  // Fallback to R2
  const object = await c.env.ASSETS.get(path);

  if (!object) {
    return c.json({ error: 'Not found' }, 404);
  }

  const body = await object.text();
  const contentType = object.httpMetadata?.contentType || 'application/octet-stream';
  const etag = object.etag;

  // Cache in KV
  const entry: CacheEntry = {
    body,
    contentType,
    etag,
    createdAt: Date.now(),
    hits: 1,
  };

  await c.env.CACHE.put(cacheKey, JSON.stringify(entry), {
    expirationTtl: parseInt(c.env.DEFAULT_TTL),
  });

  return new Response(body, {
    headers: {
      'Content-Type': contentType,
      'Cache-Control': `public, max-age=${c.env.MAX_AGE}`,
      'ETag': etag,
      'X-Cache': 'MISS',
    },
  });
});

// Upload asset
app.put('/cdn/*', async (c) => {
  const path = c.req.path.replace('/cdn/', '');

  if (!path) {
    return c.json({ error: 'Path required' }, 400);
  }

  const contentType = c.req.header('Content-Type') || 'application/octet-stream';
  const body = await c.req.arrayBuffer();

  // Upload to R2
  const object = await c.env.ASSETS.put(path, body, {
    httpMetadata: { contentType },
    customMetadata: {
      uploadedAt: String(Date.now()),
    },
  });

  // Invalidate cache
  await c.env.CACHE.delete(`cache:${path}`);

  return c.json({
    path,
    size: body.byteLength,
    etag: object.etag,
    url: `/cdn/${path}`,
  });
});

// Delete asset
app.delete('/cdn/*', async (c) => {
  const path = c.req.path.replace('/cdn/', '');

  if (!path) {
    return c.json({ error: 'Path required' }, 400);
  }

  // Delete from R2
  await c.env.ASSETS.delete(path);

  // Delete from cache
  await c.env.CACHE.delete(`cache:${path}`);

  return c.json({ deleted: true, path });
});

// Purge cache
app.post('/purge', async (c) => {
  const body = await c.req.json<{ paths?: string[]; all?: boolean }>();

  if (body.all) {
    // Purge all - list and delete
    const list = await c.env.CACHE.list({ prefix: 'cache:' });
    for (const key of list.keys) {
      await c.env.CACHE.delete(key.name);
    }
    return c.json({ purged: list.keys.length, all: true });
  }

  if (body.paths) {
    for (const path of body.paths) {
      await c.env.CACHE.delete(`cache:${path}`);
    }
    return c.json({ purged: body.paths.length, paths: body.paths });
  }

  return c.json({ error: 'Specify paths or all: true' }, 400);
});

// List assets
app.get('/assets', async (c) => {
  const prefix = c.req.query('prefix') || '';
  const limit = parseInt(c.req.query('limit') || '100');

  const list = await c.env.ASSETS.list({ prefix, limit });

  const assets = list.objects.map(obj => ({
    key: obj.key,
    size: obj.size,
    etag: obj.etag,
    uploaded: obj.uploaded,
  }));

  return c.json({
    assets,
    truncated: list.truncated,
    cursor: list.truncated ? list.cursor : null,
  });
});

// Image optimization
app.get('/image/*', async (c) => {
  const path = c.req.path.replace('/image/', '');
  const width = c.req.query('w');
  const height = c.req.query('h');
  const quality = c.req.query('q') || '80';
  const format = c.req.query('f') || 'auto';

  if (!path) {
    return c.json({ error: 'Path required' }, 400);
  }

  // Build cache key with transform params
  const transformKey = `${path}?w=${width}&h=${height}&q=${quality}&f=${format}`;
  const cacheKey = `transform:${transformKey}`;

  // Check transform cache
  const cached = await c.env.CACHE.get(cacheKey, 'arrayBuffer');
  if (cached) {
    return new Response(cached, {
      headers: {
        'Content-Type': `image/${format === 'auto' ? 'webp' : format}`,
        'Cache-Control': `public, max-age=${c.env.MAX_AGE}`,
        'X-Cache': 'HIT',
      },
    });
  }

  // Get original from R2
  const object = await c.env.ASSETS.get(path);
  if (!object) {
    return c.json({ error: 'Image not found' }, 404);
  }

  // For now, return original (real impl would use cf image resizing)
  const body = await object.arrayBuffer();

  // In production, you would use:
  // const resizedUrl = `https://imagedelivery.net/.../w=${width},h=${height},q=${quality}`;
  // or Cloudflare Image Resizing

  return new Response(body, {
    headers: {
      'Content-Type': object.httpMetadata?.contentType || 'image/jpeg',
      'Cache-Control': `public, max-age=${c.env.MAX_AGE}`,
      'X-Cache': 'MISS',
    },
  });
});

// Proxy and cache external URL
app.post('/proxy', async (c) => {
  const body = await c.req.json<{ url: string; ttl?: number }>();

  if (!body.url) {
    return c.json({ error: 'URL required' }, 400);
  }

  const cacheKey = `proxy:${body.url}`;

  // Check cache
  const cached = await c.env.CACHE.get(cacheKey, 'json') as CacheEntry | null;
  if (cached) {
    return c.json({
      cached: true,
      contentType: cached.contentType,
      hits: cached.hits,
    });
  }

  // Fetch and cache
  try {
    const response = await fetch(body.url);
    const content = await response.text();
    const contentType = response.headers.get('Content-Type') || 'text/plain';

    const entry: CacheEntry = {
      body: content,
      contentType,
      etag: `"${Date.now()}"`,
      createdAt: Date.now(),
      hits: 0,
    };

    await c.env.CACHE.put(cacheKey, JSON.stringify(entry), {
      expirationTtl: body.ttl || parseInt(c.env.DEFAULT_TTL),
    });

    return c.json({
      cached: false,
      contentType,
      size: content.length,
    });
  } catch (e) {
    return c.json({ error: 'Failed to fetch URL' }, 500);
  }
});

// Get proxied content
app.get('/proxy', async (c) => {
  const url = c.req.query('url');

  if (!url) {
    return c.json({ error: 'URL query parameter required' }, 400);
  }

  const cacheKey = `proxy:${url}`;
  const cached = await c.env.CACHE.get(cacheKey, 'json') as CacheEntry | null;

  if (cached) {
    cached.hits += 1;
    await c.env.CACHE.put(cacheKey, JSON.stringify(cached));

    return new Response(cached.body, {
      headers: {
        'Content-Type': cached.contentType,
        'X-Cache': 'HIT',
      },
    });
  }

  // Fetch fresh
  try {
    const response = await fetch(url);
    return new Response(response.body, {
      headers: {
        'Content-Type': response.headers.get('Content-Type') || 'text/plain',
        'X-Cache': 'MISS',
      },
    });
  } catch (e) {
    return c.json({ error: 'Failed to fetch' }, 500);
  }
});

// Stats
app.get('/stats', async (c) => {
  const cacheList = await c.env.CACHE.list({ prefix: 'cache:' });
  const assetList = await c.env.ASSETS.list();

  let totalHits = 0;
  let totalSize = 0;

  for (const key of cacheList.keys) {
    const data = await c.env.CACHE.get(key.name, 'json') as CacheEntry | null;
    if (data) {
      totalHits += data.hits;
    }
  }

  for (const obj of assetList.objects) {
    totalSize += obj.size;
  }

  return c.json({
    cachedItems: cacheList.keys.length,
    storedAssets: assetList.objects.length,
    totalHits,
    totalStorageBytes: totalSize,
    totalStorageMB: (totalSize / (1024 * 1024)).toFixed(2),
  });
});

// Preload assets
app.post('/preload', async (c) => {
  const body = await c.req.json<{ urls: string[] }>();

  const results = [];

  for (const url of body.urls) {
    try {
      const response = await fetch(url);
      const content = await response.arrayBuffer();
      const contentType = response.headers.get('Content-Type') || 'application/octet-stream';

      // Extract path from URL
      const urlObj = new URL(url);
      const path = urlObj.pathname.replace(/^\//, '');

      // Store in R2
      await c.env.ASSETS.put(path, content, {
        httpMetadata: { contentType },
      });

      results.push({ url, path, size: content.byteLength, status: 'ok' });
    } catch (e) {
      results.push({ url, status: 'failed', error: (e as Error).message });
    }
  }

  return c.json({ preloaded: results });
});

export default app;
