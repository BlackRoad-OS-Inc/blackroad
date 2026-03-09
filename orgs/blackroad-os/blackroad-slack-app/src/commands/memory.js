const { buildMemoryBlocks } = require('../blocks/memory');

async function memoryCommand({ respond, api, args }) {
  const action = args[0]?.toLowerCase() || 'recent';

  switch (action) {
    case 'recent':
    case 'list': {
      const entries = await api.queryMemory({ limit: 10 });

      if (entries.length === 0) {
        await respond({
          response_type: 'ephemeral',
          text: 'No memory entries found.',
        });
        return;
      }

      const blocks = buildMemoryBlocks(entries);
      await respond({
        response_type: 'in_channel',
        blocks,
      });
      break;
    }

    case 'search': {
      const query = args.slice(1).join(' ');
      if (!query) {
        await respond({
          response_type: 'ephemeral',
          text: 'Usage: `/blackroad memory search <query>`',
        });
        return;
      }

      const entries = await api.queryMemory({ q: query });

      if (entries.length === 0) {
        await respond({
          response_type: 'ephemeral',
          text: `No entries found for "${query}".`,
        });
        return;
      }

      const blocks = buildMemoryBlocks(entries, `Search: "${query}"`);
      await respond({
        response_type: 'in_channel',
        blocks,
      });
      break;
    }

    case 'log': {
      // /blackroad memory log <action> <entity> [details]
      const logAction = args[1];
      const entity = args[2];
      const details = args.slice(3).join(' ');

      if (!logAction || !entity) {
        await respond({
          response_type: 'ephemeral',
          text: 'Usage: `/blackroad memory log <action> <entity> [details]`\n\nActions: deployed, created, updated, fixed, milestone, til',
        });
        return;
      }

      const entry = await api.logMemory(logAction, entity, details);
      await respond({
        response_type: 'in_channel',
        text: `✅ *Logged to Memory*\n\n• *Action:* ${logAction}\n• *Entity:* ${entity}\n• *Hash:* \`${entry.hash.substring(0, 12)}...\``,
      });
      break;
    }

    case 'til': {
      const category = args[1];
      const learning = args.slice(2).join(' ');

      if (!category || !learning) {
        await respond({
          response_type: 'ephemeral',
          text: 'Usage: `/blackroad memory til <category> <learning>`',
        });
        return;
      }

      const entry = await api.logMemory('til', category, learning, ['til', category]);
      await respond({
        response_type: 'in_channel',
        text: `💡 *TIL Shared*\n\n• *Category:* ${category}\n• *Learning:* ${learning}\n• *Hash:* \`${entry.hash.substring(0, 12)}...\``,
      });
      break;
    }

    case 'stats': {
      const stats = await api.memoryStats();
      await respond({
        response_type: 'in_channel',
        blocks: [
          {
            type: 'section',
            text: {
              type: 'mrkdwn',
              text: `*🧠 Memory Statistics*\n\n• *Total Entries:* ${stats.total}`,
            },
          },
        ],
      });
      break;
    }

    default:
      await respond({
        response_type: 'ephemeral',
        text: 'Usage: `/blackroad memory [recent|search|log|til|stats]`',
      });
  }
}

module.exports = { memoryCommand };
