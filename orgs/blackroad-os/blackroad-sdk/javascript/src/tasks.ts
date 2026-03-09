/**
 * BlackRoad Tasks API
 */

import type { BlackRoadClient } from './client';
import type { Task, TaskListOptions, DispatchTaskOptions, Stats } from './types';

export class TaskAPI {
  constructor(private client: BlackRoadClient) {}

  /**
   * Dispatch a new task.
   */
  async dispatch(options: DispatchTaskOptions): Promise<Task> {
    return this.client.post<Task>('/tasks', {
      title: options.title,
      description: options.description,
      priority: options.priority || 'medium',
      division: options.division,
      target_level: options.target_level,
      metadata: options.metadata,
    });
  }

  /**
   * Get a specific task by ID.
   */
  async get(taskId: string): Promise<Task> {
    return this.client.get<Task>(`/tasks/${taskId}`);
  }

  /**
   * List tasks with optional filters.
   */
  async list(options: TaskListOptions = {}): Promise<Task[]> {
    const response = await this.client.get<{ tasks: Task[] }>('/tasks', options);
    return response.tasks || [];
  }

  /**
   * Complete a task.
   */
  async complete(taskId: string, result?: string): Promise<Task> {
    return this.client.put<Task>(`/tasks/${taskId}`, {
      status: 'completed',
      result,
    });
  }

  /**
   * Fail a task.
   */
  async fail(taskId: string, reason?: string): Promise<Task> {
    return this.client.put<Task>(`/tasks/${taskId}`, {
      status: 'failed',
      result: reason,
    });
  }

  /**
   * Assign a task to an agent.
   */
  async assign(taskId: string, agentId: string): Promise<Task> {
    return this.client.put<Task>(`/tasks/${taskId}`, {
      assigned_agent: agentId,
      status: 'assigned',
    });
  }

  /**
   * Cancel a task.
   */
  async cancel(taskId: string): Promise<{ cancelled: boolean }> {
    return this.client.delete<{ cancelled: boolean }>(`/tasks/${taskId}`);
  }

  /**
   * Get task statistics.
   */
  async stats(): Promise<Stats> {
    return this.client.get<Stats>('/tasks/stats');
  }

  /**
   * Get pending tasks.
   */
  async pending(): Promise<Task[]> {
    return this.list({ status: 'pending' });
  }

  /**
   * Get in-progress tasks.
   */
  async inProgress(): Promise<Task[]> {
    return this.list({ status: 'in_progress' });
  }

  /**
   * Get tasks by division.
   */
  async byDivision(division: string): Promise<Task[]> {
    return this.list({ division });
  }

  /**
   * Get urgent tasks.
   */
  async urgent(): Promise<Task[]> {
    return this.list({ priority: 'urgent' });
  }
}
