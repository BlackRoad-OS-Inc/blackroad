/**
 * RoadCDN Multi-Region Support
 *
 * Features:
 * - Geographic routing
 * - Origin failover
 * - Region-specific caching
 * - Latency-based routing
 * - Cross-region replication
 * - Health-aware routing
 */

interface Region {
  id: string;
  name: string;
  code: string; // e.g., 'us-east', 'eu-west', 'ap-southeast'
  origins: Origin[];
  priority: number;
  countries: string[]; // ISO country codes served by this region
  fallback?: string; // Fallback region ID
}

interface Origin {
  id: string;
  url: string;
  weight: number;
  healthy: boolean;
  lastCheck: number;
  latencyMs: number;
  consecutiveFailures: number;
}

interface RoutingDecision {
  region: Region;
  origin: Origin;
  reason: 'geo' | 'latency' | 'failover' | 'weighted';
  fallback: boolean;
}

interface ReplicationJob {
  id: string;
  sourceRegion: string;
  targetRegions: string[];
  paths: string[];
  status: 'pending' | 'running' | 'completed' | 'failed';
  progress: number;
  startedAt: number;
  completedAt?: number;
  errors: string[];
}

interface RegionHealthStatus {
  regionId: string;
  healthy: boolean;
  availableOrigins: number;
  totalOrigins: number;
  avgLatencyMs: number;
  lastCheck: number;
}

/**
 * Multi-Region Router
 */
export class MultiRegionRouter {
  private regions: Map<string, Region> = new Map();
  private healthCheckInterval: number = 30000; // 30 seconds
  private kv: KVNamespace;

  constructor(kv: KVNamespace) {
    this.kv = kv;
  }

  /**
   * Add a region configuration
   */
  addRegion(region: Region): void {
    this.regions.set(region.id, region);
  }

  /**
   * Load regions from KV
   */
  async loadRegions(): Promise<void> {
    const data = await this.kv.get('cdn:regions', 'json') as Region[] | null;
    if (data) {
      for (const region of data) {
        this.regions.set(region.id, region);
      }
    }
  }

  /**
   * Save regions to KV
   */
  async saveRegions(): Promise<void> {
    const regions = Array.from(this.regions.values());
    await this.kv.put('cdn:regions', JSON.stringify(regions));
  }

  /**
   * Route request to best origin
   */
  async route(request: Request, cf?: IncomingRequestCfProperties): Promise<RoutingDecision> {
    const country = cf?.country || 'US';

    // Find region serving this country
    let targetRegion = this.findRegionByCountry(country);
    let fallback = false;

    // Check if region is healthy
    if (targetRegion && !this.isRegionHealthy(targetRegion)) {
      // Try fallback
      if (targetRegion.fallback) {
        targetRegion = this.regions.get(targetRegion.fallback);
        fallback = true;
      }
    }

    // If no region found, use lowest latency
    if (!targetRegion) {
      targetRegion = await this.findLowestLatencyRegion();
    }

    if (!targetRegion) {
      throw new Error('No healthy regions available');
    }

    // Select origin within region
    const origin = this.selectOrigin(targetRegion);

    return {
      region: targetRegion,
      origin,
      reason: fallback ? 'failover' : 'geo',
      fallback,
    };
  }

  /**
   * Find region by country code
   */
  private findRegionByCountry(country: string): Region | undefined {
    for (const region of this.regions.values()) {
      if (region.countries.includes(country)) {
        return region;
      }
    }
    return undefined;
  }

  /**
   * Check if region has healthy origins
   */
  private isRegionHealthy(region: Region): boolean {
    return region.origins.some(o => o.healthy);
  }

  /**
   * Find region with lowest average latency
   */
  private async findLowestLatencyRegion(): Promise<Region | undefined> {
    const healthyRegions = Array.from(this.regions.values()).filter(r =>
      this.isRegionHealthy(r)
    );

    if (healthyRegions.length === 0) return undefined;

    return healthyRegions.reduce((best, current) => {
      const bestAvg = this.getAverageLatency(best);
      const currentAvg = this.getAverageLatency(current);
      return currentAvg < bestAvg ? current : best;
    });
  }

  /**
   * Get average latency for a region
   */
  private getAverageLatency(region: Region): number {
    const healthyOrigins = region.origins.filter(o => o.healthy);
    if (healthyOrigins.length === 0) return Infinity;

    const sum = healthyOrigins.reduce((s, o) => s + o.latencyMs, 0);
    return sum / healthyOrigins.length;
  }

  /**
   * Select origin using weighted random selection
   */
  private selectOrigin(region: Region): Origin {
    const healthyOrigins = region.origins.filter(o => o.healthy);

    if (healthyOrigins.length === 0) {
      // All origins unhealthy, try anyway with first one
      return region.origins[0];
    }

    if (healthyOrigins.length === 1) {
      return healthyOrigins[0];
    }

    // Weighted random selection
    const totalWeight = healthyOrigins.reduce((sum, o) => sum + o.weight, 0);
    let random = Math.random() * totalWeight;

    for (const origin of healthyOrigins) {
      random -= origin.weight;
      if (random <= 0) {
        return origin;
      }
    }

    return healthyOrigins[0];
  }

  /**
   * Perform health checks on all origins
   */
  async performHealthChecks(): Promise<Map<string, RegionHealthStatus>> {
    const results = new Map<string, RegionHealthStatus>();

    for (const [regionId, region] of this.regions) {
      let healthyCount = 0;
      let totalLatency = 0;

      for (const origin of region.origins) {
        const start = Date.now();

        try {
          const response = await fetch(`${origin.url}/health`, {
            signal: AbortSignal.timeout(5000),
          });

          const latency = Date.now() - start;
          origin.latencyMs = latency;
          totalLatency += latency;

          if (response.ok) {
            origin.healthy = true;
            origin.consecutiveFailures = 0;
            healthyCount++;
          } else {
            origin.consecutiveFailures++;
            origin.healthy = origin.consecutiveFailures < 3;
          }
        } catch (e) {
          origin.consecutiveFailures++;
          origin.healthy = false;
          origin.latencyMs = 9999;
        }

        origin.lastCheck = Date.now();
      }

      results.set(regionId, {
        regionId,
        healthy: healthyCount > 0,
        availableOrigins: healthyCount,
        totalOrigins: region.origins.length,
        avgLatencyMs: healthyCount > 0 ? totalLatency / healthyCount : 0,
        lastCheck: Date.now(),
      });
    }

    // Save updated health status
    await this.saveRegions();

    return results;
  }

  /**
   * Get all region health statuses
   */
  getHealthStatus(): RegionHealthStatus[] {
    const statuses: RegionHealthStatus[] = [];

    for (const [regionId, region] of this.regions) {
      const healthyOrigins = region.origins.filter(o => o.healthy);
      const avgLatency = this.getAverageLatency(region);

      statuses.push({
        regionId,
        healthy: healthyOrigins.length > 0,
        availableOrigins: healthyOrigins.length,
        totalOrigins: region.origins.length,
        avgLatencyMs: avgLatency === Infinity ? 0 : avgLatency,
        lastCheck: Math.max(...region.origins.map(o => o.lastCheck)),
      });
    }

    return statuses;
  }
}

/**
 * Cross-Region Replicator
 */
export class CrossRegionReplicator {
  private kv: KVNamespace;
  private bucket: R2Bucket;
  private jobs: Map<string, ReplicationJob> = new Map();

  constructor(kv: KVNamespace, bucket: R2Bucket) {
    this.kv = kv;
    this.bucket = bucket;
  }

  /**
   * Start replication job
   */
  async startReplication(
    sourceRegion: string,
    targetRegions: string[],
    paths: string[],
  ): Promise<ReplicationJob> {
    const job: ReplicationJob = {
      id: crypto.randomUUID(),
      sourceRegion,
      targetRegions,
      paths,
      status: 'pending',
      progress: 0,
      startedAt: Date.now(),
      errors: [],
    };

    this.jobs.set(job.id, job);

    // Start async replication
    this.runReplication(job);

    return job;
  }

  /**
   * Run replication job
   */
  private async runReplication(job: ReplicationJob): Promise<void> {
    job.status = 'running';

    const totalPaths = job.paths.length * job.targetRegions.length;
    let completed = 0;

    for (const path of job.paths) {
      // Get source object
      const sourceObject = await this.bucket.get(`${job.sourceRegion}/${path}`);
      if (!sourceObject) {
        job.errors.push(`Source not found: ${path}`);
        continue;
      }

      const content = await sourceObject.arrayBuffer();
      const metadata = sourceObject.httpMetadata;

      // Replicate to each target region
      for (const targetRegion of job.targetRegions) {
        try {
          await this.bucket.put(`${targetRegion}/${path}`, content, {
            httpMetadata: metadata,
            customMetadata: {
              replicatedFrom: job.sourceRegion,
              replicatedAt: String(Date.now()),
              replicationJobId: job.id,
            },
          });
        } catch (e) {
          job.errors.push(`Failed to replicate ${path} to ${targetRegion}: ${(e as Error).message}`);
        }

        completed++;
        job.progress = Math.round((completed / totalPaths) * 100);
      }
    }

    job.status = job.errors.length > 0 ? 'failed' : 'completed';
    job.completedAt = Date.now();

    // Store job result
    await this.kv.put(`replication:${job.id}`, JSON.stringify(job), {
      expirationTtl: 86400 * 7, // 7 days
    });
  }

  /**
   * Get job status
   */
  getJobStatus(jobId: string): ReplicationJob | undefined {
    return this.jobs.get(jobId);
  }

  /**
   * List recent jobs
   */
  async listJobs(limit: number = 50): Promise<ReplicationJob[]> {
    const list = await this.kv.list({ prefix: 'replication:', limit });
    const jobs: ReplicationJob[] = [];

    for (const key of list.keys) {
      const data = await this.kv.get(key.name, 'json') as ReplicationJob;
      if (data) jobs.push(data);
    }

    return jobs.sort((a, b) => b.startedAt - a.startedAt);
  }
}

/**
 * Geographic Cache Manager
 */
export class GeoCacheManager {
  private kv: KVNamespace;
  private regionRouter: MultiRegionRouter;

  constructor(kv: KVNamespace, router: MultiRegionRouter) {
    this.kv = kv;
    this.regionRouter = router;
  }

  /**
   * Get region-specific cache key
   */
  getCacheKey(path: string, region: string): string {
    return `cache:${region}:${path}`;
  }

  /**
   * Get cached content for request
   */
  async getCached(
    path: string,
    request: Request,
    cf?: IncomingRequestCfProperties,
  ): Promise<{ content: string; contentType: string; regionId: string } | null> {
    const routing = await this.regionRouter.route(request, cf);
    const cacheKey = this.getCacheKey(path, routing.region.id);

    const cached = await this.kv.get(cacheKey, 'json') as {
      body: string;
      contentType: string;
      etag: string;
      cachedAt: number;
    } | null;

    if (cached) {
      return {
        content: cached.body,
        contentType: cached.contentType,
        regionId: routing.region.id,
      };
    }

    return null;
  }

  /**
   * Cache content for region
   */
  async cache(
    path: string,
    regionId: string,
    content: string,
    contentType: string,
    ttl: number = 3600,
  ): Promise<void> {
    const cacheKey = this.getCacheKey(path, regionId);

    await this.kv.put(cacheKey, JSON.stringify({
      body: content,
      contentType,
      etag: `"${Date.now()}"`,
      cachedAt: Date.now(),
    }), {
      expirationTtl: ttl,
    });
  }

  /**
   * Purge cache for path across all regions
   */
  async purge(path: string): Promise<number> {
    const regions = Array.from(this.regionRouter['regions'].keys());
    let purged = 0;

    for (const regionId of regions) {
      const cacheKey = this.getCacheKey(path, regionId);
      await this.kv.delete(cacheKey);
      purged++;
    }

    return purged;
  }

  /**
   * Warm cache for all regions
   */
  async warmCache(
    path: string,
    content: string,
    contentType: string,
    ttl: number = 3600,
  ): Promise<string[]> {
    const regions = Array.from(this.regionRouter['regions'].keys());

    for (const regionId of regions) {
      await this.cache(path, regionId, content, contentType, ttl);
    }

    return regions;
  }
}

/**
 * Region configuration presets
 */
export const REGION_PRESETS: Region[] = [
  {
    id: 'us-east',
    name: 'US East',
    code: 'us-east-1',
    countries: ['US', 'CA', 'MX', 'CO', 'VE', 'BR'],
    origins: [],
    priority: 1,
    fallback: 'eu-west',
  },
  {
    id: 'us-west',
    name: 'US West',
    code: 'us-west-1',
    countries: ['US'], // Will be routed by latency for west coast
    origins: [],
    priority: 2,
    fallback: 'us-east',
  },
  {
    id: 'eu-west',
    name: 'EU West',
    code: 'eu-west-1',
    countries: ['GB', 'IE', 'FR', 'DE', 'NL', 'BE', 'ES', 'PT', 'IT'],
    origins: [],
    priority: 1,
    fallback: 'us-east',
  },
  {
    id: 'eu-central',
    name: 'EU Central',
    code: 'eu-central-1',
    countries: ['DE', 'AT', 'CH', 'PL', 'CZ', 'HU', 'RO', 'BG'],
    origins: [],
    priority: 2,
    fallback: 'eu-west',
  },
  {
    id: 'ap-southeast',
    name: 'Asia Pacific Southeast',
    code: 'ap-southeast-1',
    countries: ['SG', 'MY', 'ID', 'TH', 'VN', 'PH', 'AU', 'NZ'],
    origins: [],
    priority: 1,
    fallback: 'ap-northeast',
  },
  {
    id: 'ap-northeast',
    name: 'Asia Pacific Northeast',
    code: 'ap-northeast-1',
    countries: ['JP', 'KR', 'TW', 'HK'],
    origins: [],
    priority: 1,
    fallback: 'ap-southeast',
  },
];

/**
 * Initialize router with preset regions
 */
export function createDefaultRouter(kv: KVNamespace): MultiRegionRouter {
  const router = new MultiRegionRouter(kv);

  for (const preset of REGION_PRESETS) {
    router.addRegion(preset);
  }

  return router;
}
