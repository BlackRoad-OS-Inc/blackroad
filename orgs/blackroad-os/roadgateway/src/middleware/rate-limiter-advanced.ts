/**
 * RoadGateway Advanced Rate Limiter
 *
 * Features:
 * - Multiple rate limiting strategies
 * - Per-user, per-IP, per-API key limits
 * - Sliding window and token bucket algorithms
 * - Burst handling
 * - Adaptive limits based on server load
 * - Quota management
 */

interface RateLimitConfig {
  strategy: 'sliding-window' | 'token-bucket' | 'fixed-window' | 'leaky-bucket';
  limit: number;
  window: number; // seconds
  burst?: number; // for token bucket
  costPerRequest?: number; // for weighted limiting
}

interface RateLimitResult {
  allowed: boolean;
  remaining: number;
  limit: number;
  reset: number; // timestamp
  retryAfter?: number; // seconds
}

interface RateLimitState {
  count: number;
  tokens?: number;
  windowStart: number;
  lastUpdate: number;
  history?: number[]; // for sliding window
}

interface QuotaConfig {
  daily: number;
  monthly: number;
  perMinute: number;
}

interface QuotaState {
  daily: { count: number; date: string };
  monthly: { count: number; month: string };
  minute: { count: number; timestamp: number };
}

/**
 * Sliding Window Rate Limiter
 * More accurate than fixed window, prevents burst at window boundaries
 */
export class SlidingWindowLimiter {
  private kv: KVNamespace;
  private prefix: string;
  private limit: number;
  private windowMs: number;

  constructor(kv: KVNamespace, limit: number, windowSeconds: number, prefix = 'rl:sw:') {
    this.kv = kv;
    this.prefix = prefix;
    this.limit = limit;
    this.windowMs = windowSeconds * 1000;
  }

  async check(key: string): Promise<RateLimitResult> {
    const now = Date.now();
    const stateKey = `${this.prefix}${key}`;

    // Get current state
    const stateData = await this.kv.get(stateKey, 'json') as RateLimitState | null;

    let state: RateLimitState = stateData || {
      count: 0,
      windowStart: now,
      lastUpdate: now,
      history: [],
    };

    // Clean old entries from history
    const cutoff = now - this.windowMs;
    state.history = (state.history || []).filter(t => t > cutoff);

    // Calculate rate based on sliding window
    const count = state.history.length;

    if (count >= this.limit) {
      const oldestEntry = Math.min(...state.history);
      const retryAfter = Math.ceil((oldestEntry + this.windowMs - now) / 1000);

      return {
        allowed: false,
        remaining: 0,
        limit: this.limit,
        reset: oldestEntry + this.windowMs,
        retryAfter: Math.max(1, retryAfter),
      };
    }

    // Add current request
    state.history.push(now);
    state.lastUpdate = now;

    // Store updated state
    await this.kv.put(stateKey, JSON.stringify(state), {
      expirationTtl: Math.ceil(this.windowMs / 1000) + 60,
    });

    return {
      allowed: true,
      remaining: this.limit - state.history.length,
      limit: this.limit,
      reset: now + this.windowMs,
    };
  }
}

/**
 * Token Bucket Rate Limiter
 * Allows burst traffic while maintaining average rate
 */
export class TokenBucketLimiter {
  private kv: KVNamespace;
  private prefix: string;
  private bucketSize: number;
  private refillRate: number; // tokens per second
  private refillInterval: number; // ms

  constructor(
    kv: KVNamespace,
    bucketSize: number,
    refillRatePerSecond: number,
    prefix = 'rl:tb:',
  ) {
    this.kv = kv;
    this.prefix = prefix;
    this.bucketSize = bucketSize;
    this.refillRate = refillRatePerSecond;
    this.refillInterval = 1000 / refillRatePerSecond;
  }

  async check(key: string, cost = 1): Promise<RateLimitResult> {
    const now = Date.now();
    const stateKey = `${this.prefix}${key}`;

    // Get current state
    const stateData = await this.kv.get(stateKey, 'json') as RateLimitState | null;

    let tokens: number;
    let lastUpdate: number;

    if (stateData) {
      lastUpdate = stateData.lastUpdate;
      const elapsed = now - lastUpdate;
      const refill = Math.floor(elapsed / this.refillInterval);
      tokens = Math.min(this.bucketSize, (stateData.tokens || 0) + refill);
    } else {
      tokens = this.bucketSize;
      lastUpdate = now;
    }

    if (tokens < cost) {
      const tokensNeeded = cost - tokens;
      const refillTime = Math.ceil(tokensNeeded * this.refillInterval);

      return {
        allowed: false,
        remaining: Math.floor(tokens),
        limit: this.bucketSize,
        reset: now + refillTime,
        retryAfter: Math.ceil(refillTime / 1000),
      };
    }

    // Consume tokens
    tokens -= cost;

    // Store state
    await this.kv.put(stateKey, JSON.stringify({
      tokens,
      lastUpdate: now,
    }), {
      expirationTtl: 3600, // 1 hour
    });

    return {
      allowed: true,
      remaining: Math.floor(tokens),
      limit: this.bucketSize,
      reset: now + this.refillInterval,
    };
  }
}

/**
 * Leaky Bucket Rate Limiter
 * Smooths out traffic at a constant rate
 */
export class LeakyBucketLimiter {
  private kv: KVNamespace;
  private prefix: string;
  private bucketSize: number;
  private leakRate: number; // requests per second

  constructor(
    kv: KVNamespace,
    bucketSize: number,
    leakRatePerSecond: number,
    prefix = 'rl:lb:',
  ) {
    this.kv = kv;
    this.prefix = prefix;
    this.bucketSize = bucketSize;
    this.leakRate = leakRatePerSecond;
  }

  async check(key: string): Promise<RateLimitResult> {
    const now = Date.now();
    const stateKey = `${this.prefix}${key}`;

    const stateData = await this.kv.get(stateKey, 'json') as RateLimitState | null;

    let waterLevel: number;

    if (stateData) {
      const elapsed = (now - stateData.lastUpdate) / 1000;
      const leaked = elapsed * this.leakRate;
      waterLevel = Math.max(0, (stateData.count || 0) - leaked);
    } else {
      waterLevel = 0;
    }

    if (waterLevel >= this.bucketSize) {
      const overflowAmount = waterLevel - this.bucketSize + 1;
      const drainTime = overflowAmount / this.leakRate;

      return {
        allowed: false,
        remaining: 0,
        limit: this.bucketSize,
        reset: now + drainTime * 1000,
        retryAfter: Math.ceil(drainTime),
      };
    }

    // Add to bucket
    waterLevel += 1;

    await this.kv.put(stateKey, JSON.stringify({
      count: waterLevel,
      lastUpdate: now,
    }), {
      expirationTtl: 3600,
    });

    return {
      allowed: true,
      remaining: Math.floor(this.bucketSize - waterLevel),
      limit: this.bucketSize,
      reset: now + 1000 / this.leakRate,
    };
  }
}

/**
 * Quota Manager
 * Tracks usage across different time periods
 */
export class QuotaManager {
  private kv: KVNamespace;
  private config: QuotaConfig;

  constructor(kv: KVNamespace, config: QuotaConfig) {
    this.kv = kv;
    this.config = config;
  }

  async checkAndIncrement(userId: string): Promise<{
    allowed: boolean;
    quotas: {
      daily: { used: number; limit: number };
      monthly: { used: number; limit: number };
      minute: { used: number; limit: number };
    };
    exceededQuota?: 'daily' | 'monthly' | 'minute';
  }> {
    const now = new Date();
    const today = now.toISOString().split('T')[0];
    const month = today.slice(0, 7);
    const minuteTs = Math.floor(now.getTime() / 60000) * 60000;

    const stateKey = `quota:${userId}`;
    const stateData = await this.kv.get(stateKey, 'json') as QuotaState | null;

    const state: QuotaState = stateData || {
      daily: { count: 0, date: today },
      monthly: { count: 0, month },
      minute: { count: 0, timestamp: minuteTs },
    };

    // Reset counters if period changed
    if (state.daily.date !== today) {
      state.daily = { count: 0, date: today };
    }
    if (state.monthly.month !== month) {
      state.monthly = { count: 0, month };
    }
    if (state.minute.timestamp !== minuteTs) {
      state.minute = { count: 0, timestamp: minuteTs };
    }

    // Check limits
    let exceededQuota: 'daily' | 'monthly' | 'minute' | undefined;

    if (state.minute.count >= this.config.perMinute) {
      exceededQuota = 'minute';
    } else if (state.daily.count >= this.config.daily) {
      exceededQuota = 'daily';
    } else if (state.monthly.count >= this.config.monthly) {
      exceededQuota = 'monthly';
    }

    if (!exceededQuota) {
      state.minute.count++;
      state.daily.count++;
      state.monthly.count++;

      await this.kv.put(stateKey, JSON.stringify(state), {
        expirationTtl: 86400 * 32, // 32 days
      });
    }

    return {
      allowed: !exceededQuota,
      quotas: {
        daily: { used: state.daily.count, limit: this.config.daily },
        monthly: { used: state.monthly.count, limit: this.config.monthly },
        minute: { used: state.minute.count, limit: this.config.perMinute },
      },
      exceededQuota,
    };
  }

  async getUsage(userId: string): Promise<QuotaState | null> {
    return await this.kv.get(`quota:${userId}`, 'json');
  }

  async resetQuota(userId: string): Promise<void> {
    await this.kv.delete(`quota:${userId}`);
  }
}

/**
 * Adaptive Rate Limiter
 * Adjusts limits based on server load
 */
export class AdaptiveRateLimiter {
  private kv: KVNamespace;
  private baseLimiter: TokenBucketLimiter;
  private loadFactor: number = 1.0;
  private minLoadFactor: number = 0.2;
  private maxLoadFactor: number = 2.0;

  constructor(kv: KVNamespace, baseLimit: number, baseRatePerSecond: number) {
    this.kv = kv;
    this.baseLimiter = new TokenBucketLimiter(kv, baseLimit, baseRatePerSecond, 'rl:adaptive:');
  }

  async updateLoadFactor(currentLoad: number, maxLoad: number): Promise<void> {
    // Calculate load factor (lower factor = stricter limits)
    const loadPercent = currentLoad / maxLoad;

    if (loadPercent > 0.9) {
      this.loadFactor = this.minLoadFactor;
    } else if (loadPercent > 0.7) {
      this.loadFactor = 0.5;
    } else if (loadPercent > 0.5) {
      this.loadFactor = 0.75;
    } else if (loadPercent < 0.3) {
      this.loadFactor = this.maxLoadFactor;
    } else {
      this.loadFactor = 1.0;
    }

    await this.kv.put('rl:load-factor', String(this.loadFactor));
  }

  async check(key: string): Promise<RateLimitResult> {
    // Get current load factor
    const storedFactor = await this.kv.get('rl:load-factor');
    if (storedFactor) {
      this.loadFactor = parseFloat(storedFactor);
    }

    const cost = 1 / this.loadFactor;
    return this.baseLimiter.check(key, cost);
  }
}

/**
 * Composite Rate Limiter
 * Combines multiple limiters with priority
 */
export class CompositeRateLimiter {
  private limiters: Array<{
    name: string;
    limiter: SlidingWindowLimiter | TokenBucketLimiter | LeakyBucketLimiter;
    priority: number;
  }>;

  constructor() {
    this.limiters = [];
  }

  add(
    name: string,
    limiter: SlidingWindowLimiter | TokenBucketLimiter | LeakyBucketLimiter,
    priority: number = 0,
  ): void {
    this.limiters.push({ name, limiter, priority });
    this.limiters.sort((a, b) => b.priority - a.priority);
  }

  async check(key: string): Promise<RateLimitResult & { limiterName?: string }> {
    for (const { name, limiter } of this.limiters) {
      const result = await limiter.check(key);
      if (!result.allowed) {
        return { ...result, limiterName: name };
      }
    }

    // All passed
    const lastLimiter = this.limiters[this.limiters.length - 1];
    return lastLimiter.limiter.check(key);
  }
}

/**
 * Rate Limiter Factory
 */
export function createRateLimiter(
  kv: KVNamespace,
  config: RateLimitConfig,
): SlidingWindowLimiter | TokenBucketLimiter | LeakyBucketLimiter {
  switch (config.strategy) {
    case 'sliding-window':
      return new SlidingWindowLimiter(kv, config.limit, config.window);

    case 'token-bucket':
      return new TokenBucketLimiter(
        kv,
        config.burst || config.limit,
        config.limit / config.window,
      );

    case 'leaky-bucket':
      return new LeakyBucketLimiter(
        kv,
        config.limit,
        config.limit / config.window,
      );

    case 'fixed-window':
    default:
      return new SlidingWindowLimiter(kv, config.limit, config.window);
  }
}

/**
 * Create rate limit headers
 */
export function createRateLimitHeaders(result: RateLimitResult): Record<string, string> {
  return {
    'X-RateLimit-Limit': String(result.limit),
    'X-RateLimit-Remaining': String(result.remaining),
    'X-RateLimit-Reset': String(Math.ceil(result.reset / 1000)),
    ...(result.retryAfter ? { 'Retry-After': String(result.retryAfter) } : {}),
  };
}
