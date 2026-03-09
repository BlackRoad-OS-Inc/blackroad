# BlackRoad Cache Layer

**High-performance caching with Redis/Valkey**

## Features

- **Multi-tier**: Memory → Redis → Origin
- **TTL Management**: Automatic expiration
- **Cache Invalidation**: Pattern-based purging
- **Compression**: Automatic for large values
- **Metrics**: Hit/miss ratio tracking

## Quick Start

```typescript
import { Cache } from '@blackroad-os/cache-layer';

const cache = new Cache({
  redis: 'redis://localhost:6379',
  prefix: 'blackroad:',
  defaultTTL: 3600
});

// Set value
await cache.set('user:123', userData, { ttl: 1800 });

// Get value
const user = await cache.get<User>('user:123');

// Delete
await cache.del('user:123');

// Pattern delete
await cache.delPattern('user:*');
```

## Caching Strategies

### Cache-Aside
```typescript
async function getUser(id: string): Promise<User> {
  const cached = await cache.get<User>(`user:${id}`);
  if (cached) return cached;
  
  const user = await db.users.findById(id);
  await cache.set(`user:${id}`, user);
  return user;
}
```

### Write-Through
```typescript
async function updateUser(id: string, data: Partial<User>): Promise<User> {
  const user = await db.users.update(id, data);
  await cache.set(`user:${id}`, user);
  return user;
}
```

### Cache Warming
```typescript
await cache.warm([
  { key: 'config', fn: () => loadConfig() },
  { key: 'models', fn: () => loadModels() }
]);
```

## Cloudflare KV Integration

```typescript
// Use Cloudflare KV for edge caching
const cache = new Cache({
  provider: 'cloudflare-kv',
  namespace: env.CACHE_KV
});
```

## Metrics

| Metric | Description |
|--------|-------------|
| `cache_hits_total` | Cache hits |
| `cache_misses_total` | Cache misses |
| `cache_latency_seconds` | Get/Set latency |
| `cache_size_bytes` | Memory usage |

## Redis Cluster

```yaml
# For high availability
redis:
  cluster:
    nodes:
      - redis-1:6379
      - redis-2:6379
      - redis-3:6379
    replicas: 1
```

---

*BlackRoad OS - Speed at Every Layer*
