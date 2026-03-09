const { buildAgentsBlocks, buildAgentDetailBlocks } = require('../blocks/agents');

async function agentsCommand({ respond, api, args }) {
  const action = args[0]?.toLowerCase() || 'list';

  switch (action) {
    case 'list': {
      const division = args[1];
      const params = division ? { division } : {};
      const agents = await api.listAgents(params);

      if (agents.length === 0) {
        await respond({
          response_type: 'ephemeral',
          text: 'No agents found.',
        });
        return;
      }

      const blocks = buildAgentsBlocks(agents.slice(0, 10));
      await respond({
        response_type: 'in_channel',
        blocks,
      });
      break;
    }

    case 'get': {
      const agentId = args[1];
      if (!agentId) {
        await respond({
          response_type: 'ephemeral',
          text: 'Usage: `/blackroad agents get <agent-id>`',
        });
        return;
      }

      const agent = await api.getAgent(agentId);
      const blocks = buildAgentDetailBlocks(agent);
      await respond({
        response_type: 'in_channel',
        blocks,
      });
      break;
    }

    case 'stats': {
      const stats = await api.agentStats();
      await respond({
        response_type: 'in_channel',
        blocks: [
          {
            type: 'section',
            text: {
              type: 'mrkdwn',
              text: `*🤖 Agent Statistics*\n\n• *Total:* ${stats.total}\n• *Active:* ${stats.active || 0}`,
            },
          },
        ],
      });
      break;
    }

    default:
      await respond({
        response_type: 'ephemeral',
        text: 'Usage: `/blackroad agents [list|get|stats]`',
      });
  }
}

module.exports = { agentsCommand };
