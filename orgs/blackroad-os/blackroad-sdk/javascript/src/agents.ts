/**
 * BlackRoad Agents API
 */

import type { BlackRoadClient } from './client';
import type { Agent, AgentListOptions, RegisterAgentOptions, Stats } from './types';

export class AgentAPI {
  constructor(private client: BlackRoadClient) {}

  /**
   * List agents with optional filters.
   */
  async list(options: AgentListOptions = {}): Promise<Agent[]> {
    const response = await this.client.get<{ agents: Agent[] }>('/agents', options);
    return response.agents || [];
  }

  /**
   * Get a specific agent by ID.
   */
  async get(agentId: string): Promise<Agent> {
    return this.client.get<Agent>(`/agents/${agentId}`);
  }

  /**
   * Register a new agent.
   */
  async register(options: RegisterAgentOptions): Promise<Agent> {
    return this.client.post<Agent>('/agents', {
      name: options.name,
      type: options.type || 'ai',
      division: options.division,
      level: options.level || 4,
      metadata: options.metadata,
    });
  }

  /**
   * Send a heartbeat for an agent.
   */
  async heartbeat(agentId: string, load?: number): Promise<{ status: string }> {
    return this.client.post<{ status: string }>(`/agents/${agentId}/heartbeat`, { load });
  }

  /**
   * Update agent status.
   */
  async updateStatus(agentId: string, status: string): Promise<Agent> {
    return this.client.put<Agent>(`/agents/${agentId}`, { status });
  }

  /**
   * Delete an agent.
   */
  async delete(agentId: string): Promise<{ deleted: boolean }> {
    return this.client.delete<{ deleted: boolean }>(`/agents/${agentId}`);
  }

  /**
   * Get agent statistics.
   */
  async stats(): Promise<Stats> {
    return this.client.get<Stats>('/agents/stats');
  }

  /**
   * Get agents by division.
   */
  async byDivision(division: string): Promise<Agent[]> {
    return this.list({ division });
  }

  /**
   * Get Level 2 commanders.
   */
  async commanders(): Promise<Agent[]> {
    return this.list({ level: 2 });
  }

  /**
   * Get Level 3 managers.
   */
  async managers(): Promise<Agent[]> {
    return this.list({ level: 3 });
  }

  /**
   * Get Level 4 workers.
   */
  async workers(): Promise<Agent[]> {
    return this.list({ level: 4 });
  }
}
