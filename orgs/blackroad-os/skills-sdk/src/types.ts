// Trinary Logic
export type TrinaryValue = 1 | 0 | -1;
export type TruthState = 'true' | 'unknown' | 'false';

// Agent Types
export interface Agent {
  id: string;
  name: string;
  type: string;
  capabilities: string[];
  status: 'active' | 'inactive' | 'busy';
  created_at: string;
}

// Memory Types
export interface Memory {
  hash: string;
  agent_id: string;
  content: string;
  type: 'fact' | 'observation' | 'inference' | 'commitment';
  context: Record<string, any>;
  timestamp: number;
  truth_state: TrinaryValue;
  created_at: string;
}

// Reasoning Types
export interface Claim {
  id: string;
  content: string;
  truth_state: TrinaryValue;
  confidence: number;
  source: string;
  timestamp: number;
}

export interface Contradiction {
  detected: boolean;
  claims: Claim[];
  resolution?: 'quarantine' | 'branch' | 'reconcile';
}

// Coordination Types
export interface Event {
  id: string;
  topic: string;
  type: string;
  payload: any;
  source_agent: string;
  timestamp: number;
}

export interface Task {
  id: string;
  type: string;
  description: string;
  assigned_to: string;
  assigned_by: string;
  status: 'pending' | 'in_progress' | 'completed' | 'failed';
  priority: number;
  created_at: string;
  result?: any;
}

// SDK Configuration
export interface SDKConfig {
  baseUrl: string;
  agentId: string;
  timeout?: number;
}
