const { buildTaskDetailBlocks } = require('../blocks/tasks');
const { buildAgentDetailBlocks } = require('../blocks/agents');

function registerEvents(app) {
  // Handle button clicks
  app.action(/^complete_task_(.+)$/, async ({ ack, body, action, respond }) => {
    await ack();

    const taskId = action.action_id.replace('complete_task_', '');

    try {
      await app.api.completeTask(taskId, 'Completed via Slack');
      await respond({
        response_type: 'in_channel',
        text: `✅ Task \`${taskId.substring(0, 12)}\` completed!`,
        replace_original: false,
      });
    } catch (error) {
      await respond({
        response_type: 'ephemeral',
        text: `❌ Failed to complete task: ${error.message}`,
      });
    }
  });

  app.action(/^view_task_(.+)$/, async ({ ack, body, action, respond }) => {
    await ack();

    const taskId = action.action_id.replace('view_task_', '');

    try {
      const task = await app.api.getTask(taskId);
      const blocks = buildTaskDetailBlocks(task);
      await respond({
        response_type: 'ephemeral',
        blocks,
      });
    } catch (error) {
      await respond({
        response_type: 'ephemeral',
        text: `❌ Failed to get task: ${error.message}`,
      });
    }
  });

  app.action(/^cancel_task_(.+)$/, async ({ ack, body, action, respond }) => {
    await ack();

    const taskId = action.action_id.replace('cancel_task_', '');

    try {
      await app.api.request('DELETE', `/tasks/${taskId}`);
      await respond({
        response_type: 'in_channel',
        text: `❌ Task \`${taskId.substring(0, 12)}\` cancelled.`,
        replace_original: false,
      });
    } catch (error) {
      await respond({
        response_type: 'ephemeral',
        text: `❌ Failed to cancel task: ${error.message}`,
      });
    }
  });

  app.action(/^view_agent_(.+)$/, async ({ ack, body, action, respond }) => {
    await ack();

    const agentId = action.action_id.replace('view_agent_', '');

    try {
      const agent = await app.api.getAgent(agentId);
      const blocks = buildAgentDetailBlocks(agent);
      await respond({
        response_type: 'ephemeral',
        blocks,
      });
    } catch (error) {
      await respond({
        response_type: 'ephemeral',
        text: `❌ Failed to get agent: ${error.message}`,
      });
    }
  });

  app.action(/^heartbeat_agent_(.+)$/, async ({ ack, body, action, respond }) => {
    await ack();

    const agentId = action.action_id.replace('heartbeat_agent_', '');

    try {
      await app.api.request('POST', `/agents/${agentId}/heartbeat`, {});
      await respond({
        response_type: 'ephemeral',
        text: `💓 Heartbeat sent to agent \`${agentId.substring(0, 12)}\``,
      });
    } catch (error) {
      await respond({
        response_type: 'ephemeral',
        text: `❌ Failed to send heartbeat: ${error.message}`,
      });
    }
  });

  // View actions from status dashboard
  app.action('view_agents', async ({ ack, respond }) => {
    await ack();
    const agents = await app.api.listAgents({});
    const { buildAgentsBlocks } = require('../blocks/agents');
    const blocks = buildAgentsBlocks(agents.slice(0, 10));
    await respond({ response_type: 'ephemeral', blocks });
  });

  app.action('view_tasks', async ({ ack, respond }) => {
    await ack();
    const tasks = await app.api.listTasks({});
    const { buildTasksBlocks } = require('../blocks/tasks');
    const blocks = buildTasksBlocks(tasks.slice(0, 10));
    await respond({ response_type: 'ephemeral', blocks });
  });

  app.action('view_memory', async ({ ack, respond }) => {
    await ack();
    const entries = await app.api.queryMemory({ limit: 10 });
    const { buildMemoryBlocks } = require('../blocks/memory');
    const blocks = buildMemoryBlocks(entries);
    await respond({ response_type: 'ephemeral', blocks });
  });

  // Deploy modal
  app.action('open_deploy_modal', async ({ ack, body, client }) => {
    await ack();

    await client.views.open({
      trigger_id: body.trigger_id,
      view: {
        type: 'modal',
        callback_id: 'deploy_modal',
        title: { type: 'plain_text', text: '🚀 Deploy Project' },
        submit: { type: 'plain_text', text: 'Deploy' },
        blocks: [
          {
            type: 'input',
            block_id: 'project_name',
            element: {
              type: 'plain_text_input',
              action_id: 'project_input',
              placeholder: { type: 'plain_text', text: 'e.g., auth-service' },
            },
            label: { type: 'plain_text', text: 'Project Name' },
          },
          {
            type: 'input',
            block_id: 'priority',
            element: {
              type: 'static_select',
              action_id: 'priority_select',
              options: [
                { text: { type: 'plain_text', text: '🟢 Low' }, value: 'low' },
                { text: { type: 'plain_text', text: '🟡 Medium' }, value: 'medium' },
                { text: { type: 'plain_text', text: '🟠 High' }, value: 'high' },
                { text: { type: 'plain_text', text: '🔴 Urgent' }, value: 'urgent' },
              ],
              initial_option: { text: { type: 'plain_text', text: '🟠 High' }, value: 'high' },
            },
            label: { type: 'plain_text', text: 'Priority' },
          },
        ],
      },
    });
  });

  // Handle deploy modal submission
  app.view('deploy_modal', async ({ ack, body, view, client }) => {
    await ack();

    const projectName = view.state.values.project_name.project_input.value;
    const priority = view.state.values.priority.priority_select.selected_option.value;

    try {
      const task = await app.api.dispatchTask(`Deploy ${projectName}`, {
        description: `Deploy project ${projectName} to production`,
        priority,
        division: 'OS',
      });

      // Send notification to user
      await client.chat.postMessage({
        channel: body.user.id,
        text: `🚀 Deployment initiated for *${projectName}*\n\nTask ID: \`${task.id}\`\nPriority: ${priority}`,
      });
    } catch (error) {
      await client.chat.postMessage({
        channel: body.user.id,
        text: `❌ Failed to create deployment: ${error.message}`,
      });
    }
  });

  // Handle overflow menu selections
  app.action(/^task_overflow_(.+)$/, async ({ ack, body, action, respond }) => {
    await ack();

    const selectedValue = action.selected_option.value;
    const [actionType, taskId] = selectedValue.split('_');

    try {
      switch (actionType) {
        case 'view':
          const task = await app.api.getTask(taskId);
          const blocks = buildTaskDetailBlocks(task);
          await respond({ response_type: 'ephemeral', blocks });
          break;
        case 'complete':
          await app.api.completeTask(taskId, 'Completed via Slack');
          await respond({
            response_type: 'in_channel',
            text: `✅ Task \`${taskId.substring(0, 12)}\` completed!`,
          });
          break;
        case 'assign':
          await respond({
            response_type: 'ephemeral',
            text: `Use \`/blackroad tasks assign ${taskId} <agent-id>\` to assign this task.`,
          });
          break;
      }
    } catch (error) {
      await respond({
        response_type: 'ephemeral',
        text: `❌ Error: ${error.message}`,
      });
    }
  });
}

module.exports = { registerEvents };
