const { buildStatusBlocks } = require('../blocks/status');

async function statusCommand({ respond, api }) {
  try {
    const [health, agentStats, taskStats, memoryStats] = await Promise.all([
      api.health(),
      api.agentStats(),
      api.taskStats(),
      api.memoryStats(),
    ]);

    const blocks = buildStatusBlocks({
      health,
      agents: agentStats,
      tasks: taskStats,
      memory: memoryStats,
    });

    await respond({
      response_type: 'in_channel',
      blocks,
    });
  } catch (error) {
    await respond({
      response_type: 'ephemeral',
      text: `❌ Failed to get status: ${error.message}`,
    });
  }
}

module.exports = { statusCommand };
