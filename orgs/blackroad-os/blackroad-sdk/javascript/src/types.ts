/**
 * BlackRoad SDK Types
 */

export interface Agent {
  agent_id: string;
  name: string;
  type: 'ai' | 'hardware' | 'human';
  level: 1 | 2 | 3 | 4;
  division?: string;
  status: 'active' | 'standby' | 'dead' | 'maintenance';
  tasks_completed: number;
  last_heartbeat?: string;
  metadata?: Record<string, unknown>;
  created_at: string;
}

export interface Task {
  task_id: string;
  title: string;
  description?: string;
  priority: 'urgent' | 'high' | 'medium' | 'low';
  status: 'pending' | 'assigned' | 'in_progress' | 'completed' | 'failed';
  target_level?: number;
  target_division?: string;
  assigned_agent?: string;
  result?: string;
  created_at: string;
  assigned_at?: string;
  completed_at?: string;
  metadata?: Record<string, unknown>;
}

export interface MemoryEntry {
  hash: string;
  prev_hash: string;
  action: string;
  entity: string;
  details?: string;
  tags?: string[];
  timestamp: string;
  metadata?: Record<string, unknown>;
}

export interface ClientConfig {
  apiKey?: string;
  baseUrl?: string;
  timeout?: number;
  maxRetries?: number;
}

export interface ListOptions {
  limit?: number;
  offset?: number;
}

export interface AgentListOptions extends ListOptions {
  level?: number;
  division?: string;
  status?: string;
}

export interface TaskListOptions extends ListOptions {
  status?: string;
  priority?: string;
  division?: string;
  assigned_agent?: string;
}

export interface MemoryQueryOptions extends ListOptions {
  search?: string;
  action?: string;
  entity?: string;
  tags?: string[];
  since?: Date;
  until?: Date;
}

export interface DispatchTaskOptions {
  title: string;
  description?: string;
  priority?: 'urgent' | 'high' | 'medium' | 'low';
  division?: string;
  target_level?: number;
  metadata?: Record<string, unknown>;
}

export interface RegisterAgentOptions {
  name: string;
  type?: 'ai' | 'hardware' | 'human';
  division?: string;
  level?: number;
  metadata?: Record<string, unknown>;
}

export interface LogMemoryOptions {
  action: string;
  entity: string;
  details?: string;
  tags?: string[];
  metadata?: Record<string, unknown>;
}

export interface ApiResponse<T> {
  data: T;
  meta?: {
    total?: number;
    limit?: number;
    offset?: number;
  };
}

export interface HealthStatus {
  status: 'healthy' | 'degraded' | 'down';
  version: string;
  timestamp: string;
}

export interface Stats {
  [key: string]: number | string | Record<string, unknown>;
}
