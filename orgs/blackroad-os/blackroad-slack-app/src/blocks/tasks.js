function buildTasksBlocks(tasks) {
  const blocks = [
    {
      type: 'header',
      text: {
        type: 'plain_text',
        text: '📋 Tasks',
      },
    },
    {
      type: 'divider',
    },
  ];

  const priorityEmojis = {
    urgent: '🔴',
    high: '🟠',
    medium: '🟡',
    low: '🟢',
  };

  const statusEmojis = {
    pending: '⏳',
    in_progress: '🔄',
    assigned: '👤',
    completed: '✅',
    failed: '❌',
  };

  tasks.forEach((task) => {
    const priorityEmoji = priorityEmojis[task.priority] || '⚪';
    const statusEmoji = statusEmojis[task.status] || '⚪';
    const title = task.title.length > 50 ? task.title.substring(0, 47) + '...' : task.title;

    blocks.push({
      type: 'section',
      text: {
        type: 'mrkdwn',
        text: `${priorityEmoji} *${title}*\n${statusEmoji} ${task.status} | \`${task.id.substring(0, 12)}\``,
      },
      accessory: {
        type: 'overflow',
        options: [
          {
            text: { type: 'plain_text', text: '📄 View Details' },
            value: `view_${task.id}`,
          },
          {
            text: { type: 'plain_text', text: '✅ Complete' },
            value: `complete_${task.id}`,
          },
          {
            text: { type: 'plain_text', text: '👤 Assign' },
            value: `assign_${task.id}`,
          },
        ],
        action_id: `task_overflow_${task.id}`,
      },
    });
  });

  blocks.push({
    type: 'context',
    elements: [
      {
        type: 'mrkdwn',
        text: `Showing ${tasks.length} tasks`,
      },
    ],
  });

  return blocks;
}

function buildTaskDetailBlocks(task) {
  const priorityEmojis = {
    urgent: '🔴',
    high: '🟠',
    medium: '🟡',
    low: '🟢',
  };

  const statusEmojis = {
    pending: '⏳',
    in_progress: '🔄',
    assigned: '👤',
    completed: '✅',
    failed: '❌',
  };

  const priorityEmoji = priorityEmojis[task.priority] || '⚪';
  const statusEmoji = statusEmojis[task.status] || '⚪';

  const blocks = [
    {
      type: 'header',
      text: {
        type: 'plain_text',
        text: `📋 ${task.title}`,
      },
    },
    {
      type: 'section',
      fields: [
        {
          type: 'mrkdwn',
          text: `*ID:*\n\`${task.id}\``,
        },
        {
          type: 'mrkdwn',
          text: `*Status:*\n${statusEmoji} ${task.status}`,
        },
        {
          type: 'mrkdwn',
          text: `*Priority:*\n${priorityEmoji} ${task.priority}`,
        },
        {
          type: 'mrkdwn',
          text: `*Division:*\n${task.division || 'N/A'}`,
        },
      ],
    },
  ];

  if (task.description) {
    blocks.push({
      type: 'section',
      text: {
        type: 'mrkdwn',
        text: `*Description:*\n${task.description}`,
      },
    });
  }

  if (task.assigned_agent) {
    blocks.push({
      type: 'section',
      text: {
        type: 'mrkdwn',
        text: `*Assigned To:*\n\`${task.assigned_agent}\``,
      },
    });
  }

  blocks.push({
    type: 'context',
    elements: [
      {
        type: 'mrkdwn',
        text: `Created: ${new Date(task.created_at).toLocaleString()}`,
      },
    ],
  });

  if (task.status !== 'completed') {
    blocks.push({
      type: 'actions',
      elements: [
        {
          type: 'button',
          text: { type: 'plain_text', text: '✅ Complete' },
          style: 'primary',
          action_id: `complete_task_${task.id}`,
        },
        {
          type: 'button',
          text: { type: 'plain_text', text: '👤 Assign' },
          action_id: `assign_task_${task.id}`,
        },
        {
          type: 'button',
          text: { type: 'plain_text', text: '❌ Cancel' },
          style: 'danger',
          action_id: `cancel_task_${task.id}`,
        },
      ],
    });
  }

  return blocks;
}

module.exports = { buildTasksBlocks, buildTaskDetailBlocks };
