const { statusCommand } = require('./status');
const { agentsCommand } = require('./agents');
const { tasksCommand } = require('./tasks');
const { memoryCommand } = require('./memory');
const { deployCommand } = require('./deploy');
const { helpCommand } = require('./help');

function registerCommands(app) {
  // Main /blackroad command with subcommands
  app.command('/blackroad', async ({ command, ack, respond, client }) => {
    await ack();

    const args = command.text.trim().split(/\s+/);
    const subcommand = args[0]?.toLowerCase() || 'help';
    const subArgs = args.slice(1);

    const api = app.api;

    try {
      switch (subcommand) {
        case 'status':
          await statusCommand({ respond, api });
          break;
        case 'agents':
          await agentsCommand({ respond, api, args: subArgs });
          break;
        case 'tasks':
          await tasksCommand({ respond, api, args: subArgs });
          break;
        case 'memory':
          await memoryCommand({ respond, api, args: subArgs });
          break;
        case 'deploy':
          await deployCommand({ respond, api, args: subArgs, client, channelId: command.channel_id });
          break;
        case 'help':
        default:
          await helpCommand({ respond });
          break;
      }
    } catch (error) {
      console.error('Command error:', error);
      await respond({
        response_type: 'ephemeral',
        text: `❌ Error: ${error.message}`,
      });
    }
  });

  // Shortcut commands
  app.command('/br-status', async ({ ack, respond }) => {
    await ack();
    await statusCommand({ respond, api: app.api });
  });

  app.command('/br-agents', async ({ command, ack, respond }) => {
    await ack();
    const args = command.text.trim().split(/\s+/);
    await agentsCommand({ respond, api: app.api, args });
  });

  app.command('/br-tasks', async ({ command, ack, respond }) => {
    await ack();
    const args = command.text.trim().split(/\s+/);
    await tasksCommand({ respond, api: app.api, args });
  });

  app.command('/br-deploy', async ({ command, ack, respond, client }) => {
    await ack();
    const args = command.text.trim().split(/\s+/);
    await deployCommand({ respond, api: app.api, args, client, channelId: command.channel_id });
  });
}

module.exports = { registerCommands };
