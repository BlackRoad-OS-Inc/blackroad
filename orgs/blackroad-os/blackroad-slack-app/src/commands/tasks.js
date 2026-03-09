const { buildTasksBlocks, buildTaskDetailBlocks } = require('../blocks/tasks');

async function tasksCommand({ respond, api, args }) {
  const action = args[0]?.toLowerCase() || 'list';

  switch (action) {
    case 'list': {
      const status = args[1];
      const params = status ? { status } : {};
      const tasks = await api.listTasks(params);

      if (tasks.length === 0) {
        await respond({
          response_type: 'ephemeral',
          text: 'No tasks found.',
        });
        return;
      }

      const blocks = buildTasksBlocks(tasks.slice(0, 10));
      await respond({
        response_type: 'in_channel',
        blocks,
      });
      break;
    }

    case 'get': {
      const taskId = args[1];
      if (!taskId) {
        await respond({
          response_type: 'ephemeral',
          text: 'Usage: `/blackroad tasks get <task-id>`',
        });
        return;
      }

      const task = await api.getTask(taskId);
      const blocks = buildTaskDetailBlocks(task);
      await respond({
        response_type: 'in_channel',
        blocks,
      });
      break;
    }

    case 'dispatch':
    case 'create': {
      const title = args.slice(1).join(' ');
      if (!title) {
        await respond({
          response_type: 'ephemeral',
          text: 'Usage: `/blackroad tasks dispatch <title>`',
        });
        return;
      }

      const task = await api.dispatchTask(title, { priority: 'medium' });
      await respond({
        response_type: 'in_channel',
        blocks: [
          {
            type: 'section',
            text: {
              type: 'mrkdwn',
              text: `✅ *Task Dispatched*\n\n*ID:* \`${task.id}\`\n*Title:* ${task.title}\n*Priority:* ${task.priority}`,
            },
          },
          {
            type: 'actions',
            elements: [
              {
                type: 'button',
                text: { type: 'plain_text', text: '✓ Complete' },
                style: 'primary',
                action_id: `complete_task_${task.id}`,
              },
              {
                type: 'button',
                text: { type: 'plain_text', text: 'View Details' },
                action_id: `view_task_${task.id}`,
              },
            ],
          },
        ],
      });
      break;
    }

    case 'complete': {
      const taskId = args[1];
      const result = args.slice(2).join(' ');
      if (!taskId) {
        await respond({
          response_type: 'ephemeral',
          text: 'Usage: `/blackroad tasks complete <task-id> [result]`',
        });
        return;
      }

      await api.completeTask(taskId, result);
      await respond({
        response_type: 'in_channel',
        text: `✅ Task \`${taskId}\` completed!`,
      });
      break;
    }

    case 'stats': {
      const stats = await api.taskStats();
      await respond({
        response_type: 'in_channel',
        blocks: [
          {
            type: 'section',
            text: {
              type: 'mrkdwn',
              text: `*📋 Task Statistics*\n\n• *Total:* ${stats.total}\n• *Pending:* ${stats.pending || 0}\n• *Completed:* ${stats.completed || 0}`,
            },
          },
        ],
      });
      break;
    }

    default:
      await respond({
        response_type: 'ephemeral',
        text: 'Usage: `/blackroad tasks [list|get|dispatch|complete|stats]`',
      });
  }
}

module.exports = { tasksCommand };
