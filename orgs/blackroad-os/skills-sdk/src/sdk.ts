import { BlackRoadClient } from './client';
import { AgentTools } from './tools';
import { MemoryTools } from './memory';
import { ReasoningTools } from './reasoning';
import { CoordinationTools } from './coordination';
import { SDKConfig } from './types';

export class BlackRoadSDK {
  private client: BlackRoadClient;
  
  public agents: AgentTools;
  public memory: MemoryTools;
  public reasoning: ReasoningTools;
  public coordination: CoordinationTools;

  constructor(config: SDKConfig) {
    this.client = new BlackRoadClient(config);
    this.agents = new AgentTools(this.client);
    this.memory = new MemoryTools(this.client);
    this.reasoning = new ReasoningTools(this.client);
    this.coordination = new CoordinationTools(this.client);
  }

  get agentId(): string {
    return this.client.agentId;
  }

  // High-level convenience methods
  async think(thought: string): Promise<string> {
    // Evaluate for contradictions, then store
    const evaluation = await this.reasoning.evaluate(thought);
    
    if (evaluation.contradictions.detected) {
      // Quarantine if contradictions found
      const claimIds = evaluation.contradictions.claims.map(c => c.id);
      await this.reasoning.quarantine(claimIds, 'Contradiction detected during think()');
      return this.memory.observe(`[QUARANTINED] ${thought}`);
    }
    
    return this.memory.infer(thought);
  }

  async learn(fact: string, confidence = 0.8): Promise<{ memoryHash: string; claimId: string }> {
    const [memoryResult, claimResult] = await Promise.all([
      this.memory.remember(fact),
      this.reasoning.assertTrue(fact, confidence)
    ]);
    
    return {
      memoryHash: memoryResult,
      claimId: claimResult.id
    };
  }

  async ask(question: string, capabilities: string[]): Promise<string> {
    // Delegate to a capable agent
    const result = await this.coordination.delegate({
      taskType: 'question',
      description: question,
      requiredCapabilities: capabilities,
      priority: 5
    });
    
    return result.task_id;
  }

  async collaborate(taskDescription: string, agentTypes: string[]): Promise<string[]> {
    // Find agents and delegate tasks
    const taskIds: string[] = [];
    
    for (const type of agentTypes) {
      const agents = await this.agents.list({ type, limit: 1 });
      if (agents.agents.length > 0) {
        const result = await this.coordination.delegate({
          taskType: 'collaboration',
          description: taskDescription,
          targetAgent: agents.agents[0].id
        });
        taskIds.push(result.task_id);
      }
    }
    
    return taskIds;
  }
}

// Factory function
export function createSDK(options: {
  baseUrl?: string;
  agentId: string;
}): BlackRoadSDK {
  return new BlackRoadSDK({
    baseUrl: options.baseUrl || 'https://blackroad-tools.amundsonalexa.workers.dev',
    agentId: options.agentId
  });
}
