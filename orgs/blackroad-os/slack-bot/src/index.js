const { App } = require('@slack/bolt');

const app = new App({
  token: process.env.SLACK_BOT_TOKEN,
  signingSecret: process.env.SLACK_SIGNING_SECRET,
  socketMode: true,
  appToken: process.env.SLACK_APP_TOKEN
});

// Respond to /blackroad command
app.command('/blackroad', async ({ command, ack, respond }) => {
  await ack();
  await respond({
    blocks: [
      {
        type: 'section',
        text: {
          type: 'mrkdwn',
          text: `*BlackRoad OS Status*\n• Infrastructure: Online\n• Agents: 30,000 ready\n• Cloudflare: 200+ projects`
        }
      }
    ]
  });
});

// Listen for mentions
app.event('app_mention', async ({ event, say }) => {
  await say(`Hello <@${event.user}>! BlackRoad OS at your service.`);
});

(async () => {
  await app.start(process.env.PORT || 3000);
  console.log('BlackRoad Slack bot is running!');
})();
