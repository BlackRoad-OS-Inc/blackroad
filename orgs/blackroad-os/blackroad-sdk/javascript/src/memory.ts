/**
 * BlackRoad Memory API
 */

import type { BlackRoadClient } from './client';
import type { MemoryEntry, MemoryQueryOptions, LogMemoryOptions, Stats } from './types';

export class MemoryAPI {
  constructor(private client: BlackRoadClient) {}

  /**
   * Log an entry to the memory system.
   */
  async log(options: LogMemoryOptions): Promise<MemoryEntry> {
    return this.client.post<MemoryEntry>('/memory', {
      action: options.action,
      entity: options.entity,
      details: options.details,
      tags: options.tags,
      metadata: options.metadata,
    });
  }

  /**
   * Query memory entries.
   */
  async query(options: MemoryQueryOptions = {}): Promise<MemoryEntry[]> {
    const params: Record<string, unknown> = {
      limit: options.limit || 100,
      offset: options.offset || 0,
    };

    if (options.search) params.q = options.search;
    if (options.action) params.action = options.action;
    if (options.entity) params.entity = options.entity;
    if (options.tags) params.tags = options.tags.join(',');
    if (options.since) params.since = options.since.toISOString();
    if (options.until) params.until = options.until.toISOString();

    const response = await this.client.get<{ entries: MemoryEntry[] }>('/memory', params);
    return response.entries || [];
  }

  /**
   * Get a specific memory entry by hash.
   */
  async get(entryHash: string): Promise<MemoryEntry> {
    return this.client.get<MemoryEntry>(`/memory/${entryHash}`);
  }

  /**
   * Get recent memory entries.
   */
  async recent(limit: number = 50): Promise<MemoryEntry[]> {
    return this.query({ limit });
  }

  /**
   * Get agent state.
   */
  async agentState(agentId: string): Promise<Record<string, unknown>> {
    return this.client.get<Record<string, unknown>>(`/memory/agents/${agentId}/state`);
  }

  /**
   * Sync agent state.
   */
  async syncState(agentId: string, state: Record<string, unknown>): Promise<{ synced: boolean }> {
    return this.client.post<{ synced: boolean }>(`/memory/agents/${agentId}/state`, state);
  }

  /**
   * Broadcast a message.
   */
  async broadcast(type: string, payload: string): Promise<{ broadcast_id: string }> {
    return this.client.post<{ broadcast_id: string }>('/memory/broadcast', { type, payload });
  }

  /**
   * Share a "Today I Learned" entry.
   */
  async til(category: string, learning: string): Promise<MemoryEntry> {
    return this.log({
      action: 'til',
      entity: category,
      details: learning,
      tags: ['til', category],
    });
  }

  /**
   * Get memory statistics.
   */
  async stats(): Promise<Stats> {
    return this.client.get<Stats>('/memory/stats');
  }

  /**
   * Verify hash chain integrity.
   */
  async verifyChain(startHash?: string): Promise<{ valid: boolean; checked: number }> {
    const params = startHash ? { start: startHash } : {};
    return this.client.get<{ valid: boolean; checked: number }>('/memory/verify', params);
  }
}
