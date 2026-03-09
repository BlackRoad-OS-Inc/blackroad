import { BlackRoadClient } from './client';
import { Memory, TrinaryValue } from './types';

export class MemoryTools {
  constructor(private client: BlackRoadClient) {}

  async store(options: {
    content: string;
    type: 'fact' | 'observation' | 'inference' | 'commitment';
    context?: Record<string, any>;
    ttl?: number;
  }): Promise<{ stored: boolean; hash: string; timestamp: number }> {
    return this.client.fetch('/tools/memory/store', {
      method: 'POST',
      body: JSON.stringify(options)
    });
  }

  async retrieve(hash: string): Promise<{ memory: Memory }> {
    return this.client.fetch(`/tools/memory/retrieve/${hash}`);
  }

  async list(options?: {
    type?: Memory['type'];
    limit?: number;
  }): Promise<{ memories: Memory[]; count: number }> {
    const params = new URLSearchParams();
    if (options?.type) params.set('type', options.type);
    if (options?.limit) params.set('limit', String(options.limit));

    return this.client.fetch(`/tools/memory/list?${params}`);
  }

  async search(query: string, limit = 20): Promise<{ results: Memory[]; count: number }> {
    return this.client.fetch('/tools/memory/search', {
      method: 'POST',
      body: JSON.stringify({ query, limit })
    });
  }

  async invalidate(hash: string): Promise<{ invalidated: boolean; hash: string }> {
    return this.client.fetch(`/tools/memory/invalidate/${hash}`, {
      method: 'DELETE'
    });
  }

  // Convenience methods
  async remember(content: string, context?: Record<string, any>): Promise<string> {
    const result = await this.store({ content, type: 'fact', context });
    return result.hash;
  }

  async observe(content: string, context?: Record<string, any>): Promise<string> {
    const result = await this.store({ content, type: 'observation', context });
    return result.hash;
  }

  async infer(content: string, context?: Record<string, any>): Promise<string> {
    const result = await this.store({ content, type: 'inference', context });
    return result.hash;
  }

  async commit(content: string, context?: Record<string, any>): Promise<string> {
    const result = await this.store({ content, type: 'commitment', context });
    return result.hash;
  }
}
