/**
 * cdn-blackroadio — Media Asset CDN Worker
 * Serves assets from R2 with aggressive caching and CORS support.
 */

export interface Env {
  MEDIA_BUCKET?: R2Bucket;
  CACHE?: KVNamespace;
}

const CACHE_TTL: Record<string, number> = {
  image: 86400 * 30,   // 30 days for images
  video: 86400 * 7,    // 7 days for video
  audio: 86400 * 14,   // 14 days for audio
  model: 86400 * 365,  // 1 year for ML model weights
  default: 3600,       // 1 hour default
};

const MIME_TO_TYPE: Record<string, string> = {
  "image/png": "image", "image/jpeg": "image", "image/webp": "image", "image/gif": "image",
  "video/mp4": "video", "video/webm": "video",
  "audio/mpeg": "audio", "audio/wav": "audio",
  "application/octet-stream": "model",
};

function getCacheControl(contentType: string): string {
  const mediaType = MIME_TO_TYPE[contentType] ?? "default";
  const ttl = CACHE_TTL[mediaType];
  return `public, max-age=${ttl}, stale-while-revalidate=${ttl * 2}`;
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);
    const cors = {
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Expose-Headers": "ETag, Content-Length, Content-Type",
    };

    if (request.method === "OPTIONS") return new Response(null, { headers: cors });

    const key = url.pathname.slice(1);  // strip leading /
    if (!key) {
      return Response.json({
        service: "BlackRoad CDN",
        bucket: "blackroad-media",
        usage: "GET /<asset-key>",
      }, { headers: cors });
    }

    // Check KV cache for metadata
    const cachedMeta = env.CACHE ? await env.CACHE.get(`cdn:${key}`, "json") as { size?: number, ct?: string } | null : null;

    // Serve from R2
    if (env.MEDIA_BUCKET) {
      const obj = await env.MEDIA_BUCKET.get(key, {
        onlyIf: { etagMatches: request.headers.get("If-None-Match") ?? undefined },
      });
      if (!obj) return new Response("Not found", { status: 404, headers: cors });
      if (obj instanceof Response) return new Response(null, { status: 304, headers: cors }); // 304 Not Modified

      const ct = obj.httpMetadata?.contentType ?? "application/octet-stream";
      const headers = new Headers({
        ...cors,
        "Content-Type": ct,
        "Content-Length": String(obj.size),
        "ETag": obj.httpEtag,
        "Cache-Control": getCacheControl(ct),
        "X-BlackRoad-CDN": "1",
      });
      return new Response(obj.body, { headers });
    }

    // Fallback — not connected to R2 in dev
    return Response.json({
      error: "R2 bucket not bound",
      key,
      hint: "Bind MEDIA_BUCKET in wrangler.toml",
    }, { status: 503, headers: cors });
  }
};
