export interface CacheOptions {
  ttl?: number;
  compress?: boolean;
}

export class Cache {
  private memory = new Map<string, { value: unknown; expires: number }>();
  private prefix: string;
  private defaultTTL: number;

  constructor(opts: { prefix?: string; defaultTTL?: number } = {}) {
    this.prefix = opts.prefix || 'cache:';
    this.defaultTTL = opts.defaultTTL || 3600;
  }

  async get<T>(key: string): Promise<T | null> {
    const fullKey = this.prefix + key;
    const entry = this.memory.get(fullKey);
    
    if (!entry) return null;
    if (Date.now() > entry.expires) {
      this.memory.delete(fullKey);
      return null;
    }
    
    return entry.value as T;
  }

  async set<T>(key: string, value: T, opts: CacheOptions = {}): Promise<void> {
    const fullKey = this.prefix + key;
    const ttl = opts.ttl || this.defaultTTL;
    
    this.memory.set(fullKey, {
      value,
      expires: Date.now() + (ttl * 1000)
    });
  }

  async del(key: string): Promise<void> {
    this.memory.delete(this.prefix + key);
  }

  async delPattern(pattern: string): Promise<number> {
    const regex = new RegExp('^' + this.prefix + pattern.replace(/\*/g, '.*') + '$');
    let deleted = 0;
    
    for (const key of this.memory.keys()) {
      if (regex.test(key)) {
        this.memory.delete(key);
        deleted++;
      }
    }
    
    return deleted;
  }
}

export default { Cache };
