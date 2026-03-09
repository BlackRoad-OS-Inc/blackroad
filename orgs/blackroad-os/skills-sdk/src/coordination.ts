import { BlackRoadClient } from './client';
import { Event, Task } from './types';

export class CoordinationTools {
  constructor(private client: BlackRoadClient) {}

  async publish(topic: string, type: string, payload: any, ttl?: number): Promise<{
    published: boolean;
    event_id: string;
    topic: string;
  }> {
    return this.client.fetch('/tools/coordination/publish', {
      method: 'POST',
      body: JSON.stringify({ topic, type, payload, ttl })
    });
  }

  async subscribe(topic: string, options?: {
    since?: number;
    limit?: number;
  }): Promise<{ topic: string; events: Event[]; count: number }> {
    const params = new URLSearchParams();
    if (options?.since) params.set('since', String(options.since));
    if (options?.limit) params.set('limit', String(options.limit));

    return this.client.fetch(`/tools/coordination/subscribe/${topic}?${params}`);
  }

  async getTopics(): Promise<{ topics: string[]; count: number }> {
    return this.client.fetch('/tools/coordination/topics');
  }

  async delegate(options: {
    taskType: string;
    description: string;
    targetAgent?: string;
    requiredCapabilities?: string[];
    priority?: number;
    dueAt?: string;
    payload?: any;
  }): Promise<{ delegated: boolean; task_id: string; assigned_to: string }> {
    return this.client.fetch('/tools/coordination/delegate', {
      method: 'POST',
      body: JSON.stringify({
        task_type: options.taskType,
        description: options.description,
        target_agent: options.targetAgent,
        required_capabilities: options.requiredCapabilities,
        priority: options.priority,
        due_at: options.dueAt,
        payload: options.payload
      })
    });
  }

  async getTasks(status?: Task['status']): Promise<{ tasks: Task[]; count: number }> {
    const params = status ? `?status=${status}` : '';
    return this.client.fetch(`/tools/coordination/tasks${params}`);
  }

  async complete(taskId: string, status: 'completed' | 'failed', result?: any): Promise<{
    task_id: string;
    status: string;
    completed: boolean;
  }> {
    return this.client.fetch('/tools/coordination/complete', {
      method: 'POST',
      body: JSON.stringify({ task_id: taskId, status, result })
    });
  }

  // Convenience methods
  async emit(type: string, payload: any): Promise<string> {
    const result = await this.publish('system.events', type, payload);
    return result.event_id;
  }

  async broadcast(message: string): Promise<string> {
    const result = await this.publish('agent.broadcast', 'message', { message });
    return result.event_id;
  }

  async requestHelp(description: string, capabilities: string[]): Promise<string> {
    const result = await this.delegate({
      taskType: 'help_request',
      description,
      requiredCapabilities: capabilities,
      priority: 3
    });
    return result.task_id;
  }
}
