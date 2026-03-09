import { BlackRoadClient } from './client';
import { Agent } from './types';

export class AgentTools {
  constructor(private client: BlackRoadClient) {}

  async list(options?: {
    type?: string;
    capability?: string;
    limit?: number;
    offset?: number;
  }): Promise<{ agents: Agent[]; count: number }> {
    const params = new URLSearchParams();
    if (options?.type) params.set('type', options.type);
    if (options?.capability) params.set('capability', options.capability);
    if (options?.limit) params.set('limit', String(options.limit));
    if (options?.offset) params.set('offset', String(options.offset));

    return this.client.fetch(`/tools/agent/list?${params}`);
  }

  async get(agentId: string): Promise<{ agent: Agent }> {
    return this.client.fetch(`/tools/agent/get/${agentId}`);
  }

  async findByCapabilities(
    capabilities: string[],
    matchAll = false
  ): Promise<{ agents: Agent[]; count: number }> {
    return this.client.fetch('/tools/agent/find', {
      method: 'POST',
      body: JSON.stringify({ capabilities, matchAll })
    });
  }

  async getCapabilities(): Promise<{
    capabilities: string[];
    byType: Record<string, string[]>;
  }> {
    return this.client.fetch('/tools/agent/capabilities');
  }

  async getTypes(): Promise<{ types: { type: string; count: number }[] }> {
    return this.client.fetch('/tools/agent/types');
  }
}
