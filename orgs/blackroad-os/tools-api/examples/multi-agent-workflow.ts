/**
 * BlackRoad Multi-Agent Workflow Example
 * 
 * Demonstrates orchestrating multiple agents to solve a complex problem:
 * "Analyze a dataset, generate insights, and create a report"
 */

import { BlackRoadSDK } from '@blackroad/skills-sdk';

const sdk = new BlackRoadSDK({
  baseUrl: process.env.BLACKROAD_API || 'https://blackroad-tools.amundsonalexa.workers.dev',
});

interface WorkflowResult {
  success: boolean;
  insights: string[];
  report: string;
  agents_involved: string[];
  execution_time_ms: number;
}

async function runAnalysisWorkflow(datasetDescription: string): Promise<WorkflowResult> {
  const startTime = Date.now();
  const agentsInvolved: string[] = [];
  const insights: string[] = [];

  console.log('🚀 Starting multi-agent analysis workflow...\n');

  // Phase 1: Data Analysis
  // Use analyst agents to extract patterns
  console.log('📊 Phase 1: Data Analysis');
  const analysts = ['agent-0010', 'agent-0089', 'agent-0156'];
  
  const analysisPromises = analysts.map(async (agentId) => {
    agentsInvolved.push(agentId);
    const result = await sdk.invokeAgent(agentId, 'pattern_recognition', {
      data: datasetDescription,
      focus: 'statistical_patterns',
    });
    return result;
  });

  const analysisResults = await Promise.all(analysisPromises);
  analysisResults.forEach((r, i) => {
    if (r.result) {
      insights.push(`Analyst ${analysts[i]}: ${JSON.stringify(r.result)}`);
    }
  });
  console.log(`  ✓ ${analysisResults.length} analysts completed\n`);

  // Phase 2: Reasoning & Synthesis
  // Use reasoning to evaluate and synthesize findings
  console.log('🧠 Phase 2: Reasoning & Synthesis');
  
  // Evaluate each insight for validity
  const evaluations = await Promise.all(
    insights.map(insight => 
      sdk.evaluate(`The insight "${insight}" is statistically significant`)
    )
  );

  // Filter to valid insights (TRUE or UNKNOWN, not FALSE)
  const validInsights = insights.filter((_, i) => evaluations[i].value >= 0);
  console.log(`  ✓ ${validInsights.length}/${insights.length} insights validated\n`);

  // Phase 3: Synthesis
  // Use synthesizer agent to combine insights
  console.log('🔮 Phase 3: Synthesis');
  const synthesizerId = 'agent-0400';
  agentsInvolved.push(synthesizerId);

  const synthesisResult = await sdk.invokeAgent(synthesizerId, 'cross_domain_integration', {
    inputs: validInsights,
    goal: 'unified_narrative',
  });
  console.log(`  ✓ Synthesis complete\n`);

  // Phase 4: Report Generation
  // Use speaker agent to create readable report
  console.log('📝 Phase 4: Report Generation');
  const speakerId = 'agent-0500';
  agentsInvolved.push(speakerId);

  const reportResult = await sdk.invokeAgent(speakerId, 'presentation', {
    content: synthesisResult.result,
    format: 'executive_summary',
    audience: 'technical_leadership',
  });
  console.log(`  ✓ Report generated\n`);

  // Phase 5: Quality Assurance
  // Use guardian agent to verify output
  console.log('🛡️ Phase 5: Quality Assurance');
  const guardianId = 'agent-0600';
  agentsInvolved.push(guardianId);

  const qaResult = await sdk.invokeAgent(guardianId, 'security_monitoring', {
    content: reportResult.result,
    checks: ['factual_accuracy', 'no_hallucinations', 'complete_coverage'],
  });
  console.log(`  ✓ QA passed: ${qaResult.result?.passed || 'unknown'}\n`);

  // Store workflow memory
  await sdk.storeMemory(
    'workflow-orchestrator',
    {
      type: 'analysis_workflow',
      dataset: datasetDescription,
      insights_count: validInsights.length,
      agents_used: agentsInvolved.length,
    },
    ['workflow', 'analysis', 'completed']
  );

  const executionTime = Date.now() - startTime;

  return {
    success: true,
    insights: validInsights,
    report: reportResult.result?.text || 'Report generation pending',
    agents_involved: [...new Set(agentsInvolved)],
    execution_time_ms: executionTime,
  };
}

// Consensus-based decision workflow
async function runConsensusWorkflow(
  proposal: string,
  voterAgents: string[]
): Promise<{ approved: boolean; votes: Record<string, number>; reasoning: string[] }> {
  console.log('🗳️ Starting consensus workflow...\n');
  console.log(`Proposal: "${proposal}"`);
  console.log(`Voters: ${voterAgents.length} agents\n`);

  const votes: Record<string, number> = {};
  const reasoning: string[] = [];

  // Each agent evaluates the proposal
  const votePromises = voterAgents.map(async (agentId) => {
    const evaluation = await sdk.evaluate(proposal, { agent_id: agentId });
    votes[agentId] = evaluation.value;
    reasoning.push(`${agentId}: ${evaluation.reasoning} (${evaluation.value})`);
    return evaluation;
  });

  await Promise.all(votePromises);

  // Calculate results
  const approvals = Object.values(votes).filter(v => v === 1).length;
  const rejections = Object.values(votes).filter(v => v === -1).length;
  const abstentions = Object.values(votes).filter(v => v === 0).length;

  console.log(`\nResults:`);
  console.log(`  ✅ Approvals:   ${approvals}`);
  console.log(`  ❌ Rejections:  ${rejections}`);
  console.log(`  ❓ Abstentions: ${abstentions}`);

  // Majority required (excluding abstentions)
  const approved = approvals > rejections;

  return { approved, votes, reasoning };
}

// Event-driven collaboration workflow
async function runCollaborativeWorkflow(
  task: string,
  teams: { name: string; agents: string[] }[]
): Promise<void> {
  console.log('🤝 Starting collaborative workflow...\n');
  
  // Subscribe teams to relevant events
  for (const team of teams) {
    for (const agent of team.agents) {
      await sdk.subscribe(agent, [
        `task.${team.name}.assigned`,
        `task.${team.name}.completed`,
        'coordination.sync_required',
      ]);
    }
    console.log(`  📥 Team ${team.name} subscribed (${team.agents.length} agents)`);
  }

  // Publish task to all teams
  const taskId = `task-${Date.now()}`;
  await sdk.publish('task.created', {
    id: taskId,
    description: task,
    teams: teams.map(t => t.name),
  });
  console.log(`\n  📡 Task published: ${taskId}`);

  // Teams work in parallel, publishing progress
  const teamResults = await Promise.all(
    teams.map(async (team) => {
      // Orchestrate team internally
      const result = await sdk.orchestrate(
        { description: `${task} - ${team.name} portion`, goal: 'complete_subtask' },
        team.agents,
        'parallel'
      );

      // Publish completion
      await sdk.publish(`task.${team.name}.completed`, {
        task_id: taskId,
        team: team.name,
        result: result.orchestration_id,
      });

      return result;
    })
  );

  console.log(`\n  ✓ All teams completed`);
  teamResults.forEach((r, i) => {
    console.log(`    ${teams[i].name}: ${r.status}`);
  });
}

// Main execution
async function main() {
  console.log('═══════════════════════════════════════════════════════════');
  console.log('          BlackRoad Multi-Agent Workflow Examples           ');
  console.log('═══════════════════════════════════════════════════════════\n');

  // Example 1: Analysis Workflow
  console.log('─── Example 1: Analysis Workflow ───\n');
  try {
    const result = await runAnalysisWorkflow('Q4 sales data with regional breakdown');
    console.log('\nWorkflow completed:');
    console.log(`  Insights: ${result.insights.length}`);
    console.log(`  Agents: ${result.agents_involved.length}`);
    console.log(`  Time: ${result.execution_time_ms}ms\n`);
  } catch (err) {
    console.log('  (Workflow requires live API)\n');
  }

  // Example 2: Consensus Workflow
  console.log('─── Example 2: Consensus Workflow ───\n');
  try {
    const consensus = await runConsensusWorkflow(
      'We should migrate the database to PostgreSQL',
      ['agent-0100', 'agent-0200', 'agent-0300', 'agent-0400', 'agent-0500']
    );
    console.log(`\nDecision: ${consensus.approved ? 'APPROVED ✅' : 'REJECTED ❌'}\n`);
  } catch (err) {
    console.log('  (Workflow requires live API)\n');
  }

  // Example 3: Collaborative Workflow
  console.log('─── Example 3: Collaborative Workflow ───\n');
  try {
    await runCollaborativeWorkflow(
      'Design and implement new user authentication system',
      [
        { name: 'architects', agents: ['agent-0010', 'agent-0011'] },
        { name: 'engineers', agents: ['agent-0020', 'agent-0021', 'agent-0022'] },
        { name: 'security', agents: ['agent-0030', 'agent-0031'] },
      ]
    );
    console.log('\n');
  } catch (err) {
    console.log('  (Workflow requires live API)\n');
  }

  console.log('═══════════════════════════════════════════════════════════\n');
}

main().catch(console.error);
