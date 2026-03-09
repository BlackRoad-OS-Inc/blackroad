function buildAgentsBlocks(agents) {
  const blocks = [
    {
      type: 'header',
      text: {
        type: 'plain_text',
        text: '🤖 Agents',
      },
    },
    {
      type: 'divider',
    },
  ];

  agents.forEach((agent) => {
    const statusEmoji = agent.status === 'active' || agent.status === 'online' ? '🟢' : '⚪';
    const load = agent.load ? `${Math.round(agent.load * 100)}%` : 'N/A';

    blocks.push({
      type: 'section',
      text: {
        type: 'mrkdwn',
        text: `${statusEmoji} *${agent.name}*\n\`${agent.id.substring(0, 12)}\` | ${agent.type} | Level ${agent.level} | Load: ${load}`,
      },
      accessory: {
        type: 'button',
        text: { type: 'plain_text', text: 'Details' },
        action_id: `view_agent_${agent.id}`,
      },
    });
  });

  blocks.push({
    type: 'context',
    elements: [
      {
        type: 'mrkdwn',
        text: `Showing ${agents.length} agents`,
      },
    ],
  });

  return blocks;
}

function buildAgentDetailBlocks(agent) {
  const statusEmoji = agent.status === 'active' || agent.status === 'online' ? '🟢' : '⚪';
  const load = agent.load ? `${Math.round(agent.load * 100)}%` : 'N/A';
  const lastSeen = agent.last_seen ? new Date(agent.last_seen).toLocaleString() : 'Never';

  return [
    {
      type: 'header',
      text: {
        type: 'plain_text',
        text: `🤖 ${agent.name}`,
      },
    },
    {
      type: 'section',
      fields: [
        {
          type: 'mrkdwn',
          text: `*ID:*\n\`${agent.id}\``,
        },
        {
          type: 'mrkdwn',
          text: `*Status:*\n${statusEmoji} ${agent.status}`,
        },
        {
          type: 'mrkdwn',
          text: `*Type:*\n${agent.type}`,
        },
        {
          type: 'mrkdwn',
          text: `*Level:*\n${agent.level}`,
        },
        {
          type: 'mrkdwn',
          text: `*Division:*\n${agent.division || 'N/A'}`,
        },
        {
          type: 'mrkdwn',
          text: `*Load:*\n${load}`,
        },
      ],
    },
    {
      type: 'context',
      elements: [
        {
          type: 'mrkdwn',
          text: `Created: ${new Date(agent.created_at).toLocaleString()} | Last seen: ${lastSeen}`,
        },
      ],
    },
    {
      type: 'actions',
      elements: [
        {
          type: 'button',
          text: { type: 'plain_text', text: '💓 Heartbeat' },
          action_id: `heartbeat_agent_${agent.id}`,
        },
        {
          type: 'button',
          text: { type: 'plain_text', text: '📋 Assign Task' },
          action_id: `assign_task_to_${agent.id}`,
        },
      ],
    },
  ];
}

module.exports = { buildAgentsBlocks, buildAgentDetailBlocks };
