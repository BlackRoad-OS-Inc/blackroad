async function deployCommand({ respond, api, args, client, channelId }) {
  const project = args[0];

  if (!project) {
    await respond({
      response_type: 'ephemeral',
      blocks: [
        {
          type: 'section',
          text: {
            type: 'mrkdwn',
            text: '*🚀 Deploy a Project*\n\nUsage: `/blackroad deploy <project-name>`',
          },
        },
        {
          type: 'section',
          text: {
            type: 'mrkdwn',
            text: '*Examples:*\n• `/blackroad deploy auth-service`\n• `/blackroad deploy api-gateway`\n• `/blackroad deploy web-frontend`',
          },
        },
      ],
    });
    return;
  }

  // Get priority from args
  let priority = 'high';
  const priorityIdx = args.indexOf('--priority');
  if (priorityIdx !== -1 && args[priorityIdx + 1]) {
    priority = args[priorityIdx + 1];
  }

  // Create deployment task
  const task = await api.dispatchTask(`Deploy ${project}`, {
    description: `Deploy project ${project} to production`,
    priority,
    division: 'OS',
  });

  // Log to memory
  await api.logMemory('deployed', project, `Deployment initiated via Slack`, ['deployment', 'slack']);

  await respond({
    response_type: 'in_channel',
    blocks: [
      {
        type: 'header',
        text: {
          type: 'plain_text',
          text: '🚀 Deployment Initiated',
        },
      },
      {
        type: 'section',
        fields: [
          {
            type: 'mrkdwn',
            text: `*Project:*\n${project}`,
          },
          {
            type: 'mrkdwn',
            text: `*Priority:*\n${priority}`,
          },
          {
            type: 'mrkdwn',
            text: `*Task ID:*\n\`${task.id}\``,
          },
          {
            type: 'mrkdwn',
            text: `*Status:*\n${task.status}`,
          },
        ],
      },
      {
        type: 'actions',
        elements: [
          {
            type: 'button',
            text: { type: 'plain_text', text: '📊 View Progress' },
            action_id: `view_task_${task.id}`,
          },
          {
            type: 'button',
            text: { type: 'plain_text', text: '✓ Mark Complete' },
            style: 'primary',
            action_id: `complete_task_${task.id}`,
          },
          {
            type: 'button',
            text: { type: 'plain_text', text: '✗ Cancel' },
            style: 'danger',
            action_id: `cancel_task_${task.id}`,
          },
        ],
      },
      {
        type: 'context',
        elements: [
          {
            type: 'mrkdwn',
            text: `Initiated at ${new Date().toISOString()}`,
          },
        ],
      },
    ],
  });
}

module.exports = { deployCommand };
