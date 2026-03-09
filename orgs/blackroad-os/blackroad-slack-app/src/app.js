require('dotenv').config();
const { App } = require('@slack/bolt');
const { registerCommands } = require('./commands');
const { registerEvents } = require('./events');
const { BlackRoadAPI } = require('./utils/api');

// Initialize Slack app
const app = new App({
  token: process.env.SLACK_BOT_TOKEN,
  signingSecret: process.env.SLACK_SIGNING_SECRET,
  socketMode: true,
  appToken: process.env.SLACK_APP_TOKEN,
});

// Initialize BlackRoad API client
const api = new BlackRoadAPI(process.env.BLACKROAD_API_KEY);

// Make API available to all handlers
app.api = api;

// Register all slash commands
registerCommands(app);

// Register all event handlers
registerEvents(app);

// Global error handler
app.error(async (error) => {
  console.error('Slack app error:', error);
});

// Start the app
(async () => {
  const port = process.env.PORT || 3000;
  await app.start(port);
  console.log(`⚡️ BlackRoad Slack app is running on port ${port}`);
})();
