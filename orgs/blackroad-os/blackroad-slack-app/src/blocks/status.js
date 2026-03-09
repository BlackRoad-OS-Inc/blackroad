function buildStatusBlocks({ health, agents, tasks, memory }) {
  const statusEmoji = health.status === 'healthy' ? '🟢' : '🔴';

  return [
    {
      type: 'header',
      text: {
        type: 'plain_text',
        text: '🖤 BlackRoad Status',
      },
    },
    {
      type: 'section',
      text: {
        type: 'mrkdwn',
        text: `${statusEmoji} *API Status:* ${health.status} (v${health.version})`,
      },
    },
    {
      type: 'divider',
    },
    {
      type: 'section',
      fields: [
        {
          type: 'mrkdwn',
          text: `*🤖 Agents*\nTotal: ${agents.total}\nActive: ${agents.active || 0}`,
        },
        {
          type: 'mrkdwn',
          text: `*📋 Tasks*\nTotal: ${tasks.total}\nPending: ${tasks.pending || 0}`,
        },
        {
          type: 'mrkdwn',
          text: `*🧠 Memory*\nEntries: ${memory.total}`,
        },
        {
          type: 'mrkdwn',
          text: `*✅ Completed*\nTasks: ${tasks.completed || 0}`,
        },
      ],
    },
    {
      type: 'divider',
    },
    {
      type: 'actions',
      elements: [
        {
          type: 'button',
          text: { type: 'plain_text', text: '🤖 Agents' },
          action_id: 'view_agents',
        },
        {
          type: 'button',
          text: { type: 'plain_text', text: '📋 Tasks' },
          action_id: 'view_tasks',
        },
        {
          type: 'button',
          text: { type: 'plain_text', text: '🧠 Memory' },
          action_id: 'view_memory',
        },
        {
          type: 'button',
          text: { type: 'plain_text', text: '🚀 Deploy' },
          style: 'primary',
          action_id: 'open_deploy_modal',
        },
      ],
    },
    {
      type: 'context',
      elements: [
        {
          type: 'mrkdwn',
          text: `Last updated: ${new Date().toLocaleString()}`,
        },
      ],
    },
  ];
}

module.exports = { buildStatusBlocks };
