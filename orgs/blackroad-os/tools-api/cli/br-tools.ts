#!/usr/bin/env node
/**
 * BlackRoad Tools CLI
 * Command-line interface for interacting with the BlackRoad Tools API
 */

const API_BASE = process.env.BLACKROAD_API || 'https://blackroad-tools.amundsonalexa.workers.dev';

interface Agent {
  id: string;
  name: string;
  type: string;
  capabilities: string[];
  status: string;
}

interface CommandResult {
  success: boolean;
  data?: any;
  error?: string;
}

async function apiCall(path: string, method = 'GET', body?: any): Promise<CommandResult> {
  try {
    const options: RequestInit = {
      method,
      headers: { 'Content-Type': 'application/json' },
    };
    if (body) {
      options.body = JSON.stringify(body);
    }

    const response = await fetch(`${API_BASE}${path}`, options);
    const data = await response.json();

    if (!response.ok) {
      return { success: false, error: data.error || `HTTP ${response.status}` };
    }

    return { success: true, data };
  } catch (err) {
    return { success: false, error: String(err) };
  }
}

// Command handlers
const commands: Record<string, (args: string[]) => Promise<void>> = {
  // Agent commands
  async 'agent:list'(args) {
    const type = args[0];
    const limit = args[1] || '20';
    const path = `/tools/agent/list?limit=${limit}${type ? `&type=${type}` : ''}`;
    
    const result = await apiCall(path);
    if (result.success) {
      console.log(`\n📋 Agents (${result.data.total} total):\n`);
      result.data.agents.forEach((agent: Agent) => {
        console.log(`  ${agent.id} | ${agent.name.padEnd(20)} | ${agent.type.padEnd(12)} | ${agent.status}`);
      });
    } else {
      console.error('Error:', result.error);
    }
  },

  async 'agent:get'(args) {
    if (!args[0]) {
      console.error('Usage: agent:get <agent-id>');
      return;
    }

    const result = await apiCall(`/tools/agent/${args[0]}`);
    if (result.success) {
      const agent = result.data;
      console.log(`\n🤖 Agent: ${agent.name}\n`);
      console.log(`  ID:           ${agent.id}`);
      console.log(`  Type:         ${agent.type}`);
      console.log(`  Status:       ${agent.status}`);
      console.log(`  Home World:   ${agent.home_world}`);
      console.log(`  Birthday:     ${agent.birthday}`);
      console.log(`  Capabilities: ${agent.capabilities.join(', ')}`);
      console.log(`  Memory Hash:  ${agent.memory_hash}`);
    } else {
      console.error('Error:', result.error);
    }
  },

  async 'agent:spawn'(args) {
    const name = args[0];
    const type = args[1] || 'analyst';
    
    if (!name) {
      console.error('Usage: agent:spawn <name> [type]');
      return;
    }

    const result = await apiCall('/tools/agent/spawn', 'POST', { name, type });
    if (result.success) {
      console.log(`\n✨ Agent spawned: ${result.data.id} (${result.data.name})`);
    } else {
      console.error('Error:', result.error);
    }
  },

  async 'agent:invoke'(args) {
    const agentId = args[0];
    const capability = args[1];
    const input = args[2] ? JSON.parse(args[2]) : {};

    if (!agentId || !capability) {
      console.error('Usage: agent:invoke <agent-id> <capability> [input-json]');
      return;
    }

    const result = await apiCall(`/tools/agent/${agentId}/invoke`, 'POST', { capability, input });
    if (result.success) {
      console.log(`\n⚡ Invocation result:\n`);
      console.log(JSON.stringify(result.data, null, 2));
    } else {
      console.error('Error:', result.error);
    }
  },

  // Memory commands
  async 'memory:store'(args) {
    const agentId = args[0];
    const content = args[1];
    const tags = args.slice(2);

    if (!agentId || !content) {
      console.error('Usage: memory:store <agent-id> <content> [tags...]');
      return;
    }

    const result = await apiCall('/tools/memory/store', 'POST', {
      agent_id: agentId,
      content: { text: content },
      tags,
    });

    if (result.success) {
      console.log(`\n💾 Memory stored: ${result.data.hash}`);
    } else {
      console.error('Error:', result.error);
    }
  },

  async 'memory:recall'(args) {
    const agentId = args[0];
    const query = args[1];

    if (!agentId) {
      console.error('Usage: memory:recall <agent-id> [query]');
      return;
    }

    const result = await apiCall('/tools/memory/recall', 'POST', {
      agent_id: agentId,
      query,
      limit: 10,
    });

    if (result.success) {
      console.log(`\n🧠 Memories for ${agentId}:\n`);
      result.data.memories.forEach((mem: any) => {
        console.log(`  [${mem.hash}] ${mem.timestamp}`);
        console.log(`    ${JSON.stringify(mem.content)}`);
        console.log(`    Tags: ${mem.tags?.join(', ') || 'none'}\n`);
      });
    } else {
      console.error('Error:', result.error);
    }
  },

  async 'memory:verify'(args) {
    const hash = args[0];

    if (!hash) {
      console.error('Usage: memory:verify <hash>');
      return;
    }

    const result = await apiCall('/tools/memory/verify', 'POST', { hash });
    if (result.success) {
      const v = result.data;
      console.log(`\n🔐 Memory verification:`);
      console.log(`  Valid:       ${v.valid ? '✅ Yes' : '❌ No'}`);
      console.log(`  Chain Depth: ${v.chain_depth}`);
      console.log(`  Root Hash:   ${v.root_hash}`);
    } else {
      console.error('Error:', result.error);
    }
  },

  // Reasoning commands
  async 'reason:evaluate'(args) {
    const proposition = args.join(' ');

    if (!proposition) {
      console.error('Usage: reason:evaluate <proposition>');
      return;
    }

    const result = await apiCall('/tools/reasoning/evaluate', 'POST', { proposition });
    if (result.success) {
      const r = result.data;
      const valueStr = r.value === 1 ? 'TRUE ✅' : r.value === -1 ? 'FALSE ❌' : 'UNKNOWN ❓';
      console.log(`\n🧮 Evaluation: ${valueStr}`);
      console.log(`  Confidence: ${(r.confidence * 100).toFixed(1)}%`);
      console.log(`  Reasoning:  ${r.reasoning}`);
    } else {
      console.error('Error:', result.error);
    }
  },

  async 'reason:resolve'(args) {
    // Parse claims from args: "claim1|source1|conf1" "claim2|source2|conf2"
    const claims = args.map(arg => {
      const [statement, source, confidence] = arg.split('|');
      return { statement, source, confidence: parseFloat(confidence) || 0.5 };
    });

    if (claims.length < 2) {
      console.error('Usage: reason:resolve "claim1|source|conf" "claim2|source|conf" ...');
      return;
    }

    const result = await apiCall('/tools/reasoning/resolve', 'POST', {
      claims,
      strategy: 'quarantine',
    });

    if (result.success) {
      const r = result.data;
      console.log(`\n⚖️ Resolution: ${r.resolved ? 'Resolved' : 'Unresolved'}`);
      console.log(`  Strategy: ${r.strategy_used}`);
      if (r.quarantined?.length) {
        console.log(`  Quarantined: ${r.quarantined.join(', ')}`);
      }
      console.log(`  Result:`, r.result);
    } else {
      console.error('Error:', result.error);
    }
  },

  // Coordination commands
  async 'coord:publish'(args) {
    const eventType = args[0];
    const payload = args[1] ? JSON.parse(args[1]) : {};
    const sourceAgent = args[2];

    if (!eventType) {
      console.error('Usage: coord:publish <event-type> [payload-json] [source-agent]');
      return;
    }

    const result = await apiCall('/tools/coordination/publish', 'POST', {
      event_type: eventType,
      payload,
      source_agent: sourceAgent,
    });

    if (result.success) {
      console.log(`\n📡 Event published: ${result.data.event_id}`);
      console.log(`  Subscribers notified: ${result.data.subscribers_notified}`);
    } else {
      console.error('Error:', result.error);
    }
  },

  async 'coord:subscribe'(args) {
    const agentId = args[0];
    const eventTypes = args.slice(1);

    if (!agentId || eventTypes.length === 0) {
      console.error('Usage: coord:subscribe <agent-id> <event-type> [event-type...]');
      return;
    }

    const result = await apiCall('/tools/coordination/subscribe', 'POST', {
      agent_id: agentId,
      event_types: eventTypes,
    });

    if (result.success) {
      console.log(`\n📥 Subscription created: ${result.data.subscription_id}`);
      console.log(`  Events: ${result.data.event_types.join(', ')}`);
    } else {
      console.error('Error:', result.error);
    }
  },

  async 'coord:orchestrate'(args) {
    const description = args[0];
    const agents = args.slice(1);

    if (!description || agents.length === 0) {
      console.error('Usage: coord:orchestrate <task-description> <agent-id> [agent-id...]');
      return;
    }

    const result = await apiCall('/tools/coordination/orchestrate', 'POST', {
      task: { description, goal: description },
      agents,
      strategy: 'parallel',
    });

    if (result.success) {
      console.log(`\n🎭 Orchestration started: ${result.data.orchestration_id}`);
      console.log(`  Status: ${result.data.status}`);
      console.log(`  Agents: ${result.data.agents_assigned.join(', ')}`);
    } else {
      console.error('Error:', result.error);
    }
  },

  // Utility commands
  async 'health'() {
    const result = await apiCall('/health');
    if (result.success) {
      console.log(`\n💚 API Status: ${result.data.status}`);
      console.log(`  Version:   ${result.data.version}`);
      console.log(`  Timestamp: ${result.data.timestamp}`);
    } else {
      console.error('❌ API unreachable:', result.error);
    }
  },

  async 'help'() {
    console.log(`
BlackRoad Tools CLI

Usage: br-tools <command> [args...]

Commands:
  Agent Management:
    agent:list [type] [limit]           List agents
    agent:get <id>                      Get agent details
    agent:spawn <name> [type]           Spawn new agent
    agent:invoke <id> <cap> [input]     Invoke agent capability

  Memory (PS-SHA∞):
    memory:store <agent> <content> [tags...]  Store memory
    memory:recall <agent> [query]             Recall memories
    memory:verify <hash>                      Verify memory chain

  Reasoning (Trinary):
    reason:evaluate <proposition>             Evaluate truth value
    reason:resolve "c1|src|conf" ...          Resolve contradictions

  Coordination:
    coord:publish <type> [payload] [src]      Publish event
    coord:subscribe <agent> <types...>        Subscribe to events
    coord:orchestrate <task> <agents...>      Orchestrate task

  Utility:
    health                              Check API health
    help                                Show this help

Environment:
  BLACKROAD_API    API base URL (default: https://blackroad-tools.amundsonalexa.workers.dev)
`);
  },
};

// Main execution
async function main() {
  const args = process.argv.slice(2);
  const command = args[0] || 'help';
  const commandArgs = args.slice(1);

  const handler = commands[command];
  if (handler) {
    await handler(commandArgs);
  } else {
    console.error(`Unknown command: ${command}`);
    await commands['help']([]);
  }
}

main().catch(console.error);
