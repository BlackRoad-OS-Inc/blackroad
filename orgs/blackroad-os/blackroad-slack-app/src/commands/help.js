async function helpCommand({ respond }) {
  await respond({
    response_type: 'ephemeral',
    blocks: [
      {
        type: 'header',
        text: {
          type: 'plain_text',
          text: '🖤 BlackRoad Slack Commands',
        },
      },
      {
        type: 'divider',
      },
      {
        type: 'section',
        text: {
          type: 'mrkdwn',
          text: '*📊 Status*\n`/blackroad status` - Show infrastructure status',
        },
      },
      {
        type: 'section',
        text: {
          type: 'mrkdwn',
          text: '*🤖 Agents*\n• `/blackroad agents list [division]` - List agents\n• `/blackroad agents get <id>` - Get agent details\n• `/blackroad agents stats` - Show statistics',
        },
      },
      {
        type: 'section',
        text: {
          type: 'mrkdwn',
          text: '*📋 Tasks*\n• `/blackroad tasks list [status]` - List tasks\n• `/blackroad tasks get <id>` - Get task details\n• `/blackroad tasks dispatch <title>` - Create task\n• `/blackroad tasks complete <id>` - Complete task\n• `/blackroad tasks stats` - Show statistics',
        },
      },
      {
        type: 'section',
        text: {
          type: 'mrkdwn',
          text: '*🧠 Memory*\n• `/blackroad memory recent` - Recent entries\n• `/blackroad memory search <query>` - Search\n• `/blackroad memory log <action> <entity> [details]` - Log entry\n• `/blackroad memory til <category> <learning>` - Share TIL\n• `/blackroad memory stats` - Show statistics',
        },
      },
      {
        type: 'section',
        text: {
          type: 'mrkdwn',
          text: '*🚀 Deploy*\n`/blackroad deploy <project>` - Deploy a project',
        },
      },
      {
        type: 'divider',
      },
      {
        type: 'context',
        elements: [
          {
            type: 'mrkdwn',
            text: 'BlackRoad Slack App v1.0.0 | <https://docs.blackroad.io/integrations/slack|Documentation>',
          },
        ],
      },
    ],
  });
}

module.exports = { helpCommand };
