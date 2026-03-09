# RoadCDN

Content Delivery Network for the BlackRoad ecosystem.

## Features

- **Edge Caching** - KV-based cache at the edge
- **R2 Origin** - Store assets in R2
- **Image Optimization** - Resize and compress images
- **Cache Purging** - Purge by path or all
- **Proxy Caching** - Cache external URLs
- **Analytics** - Cache hit stats

## Quick Start

```bash
npm install
wrangler deploy
```

## API Endpoints

### Assets
- `GET /cdn/:path` - Serve cached asset
- `PUT /cdn/:path` - Upload asset
- `DELETE /cdn/:path` - Delete asset
- `GET /assets` - List all assets

### Cache
- `POST /purge` - Purge cache
- `GET /stats` - Cache statistics

### Image Optimization
```
GET /image/photo.jpg?w=800&h=600&q=80&f=webp
```

### Proxy
- `POST /proxy` - Cache external URL
- `GET /proxy?url=...` - Serve proxied content

### Preload
```bash
POST /preload
{
  "urls": ["https://example.com/image.png"]
}
```

## Headers

- `X-Cache: HIT/MISS` - Cache status
- `X-Cache-Hits: N` - Number of cache hits
- `ETag` - Entity tag for conditional requests

## License

Proprietary - BlackRoad OS, Inc.
