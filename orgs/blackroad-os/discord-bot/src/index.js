const { Client, GatewayIntentBits, SlashCommandBuilder, REST, Routes } = require('discord.js');

const client = new Client({ 
  intents: [GatewayIntentBits.Guilds, GatewayIntentBits.GuildMessages] 
});

const commands = [
  new SlashCommandBuilder()
    .setName('status')
    .setDescription('Check BlackRoad infrastructure status'),
  new SlashCommandBuilder()
    .setName('agents')
    .setDescription('List active AI agents'),
  new SlashCommandBuilder()
    .setName('help')
    .setDescription('Get help with BlackRoad OS')
].map(cmd => cmd.toJSON());

client.once('ready', () => {
  console.log(`Logged in as ${client.user.tag}`);
});

client.on('interactionCreate', async interaction => {
  if (!interaction.isChatInputCommand()) return;

  if (interaction.commandName === 'status') {
    await interaction.reply({
      embeds: [{
        title: '🖤 BlackRoad OS Status',
        color: 0xFF1D6C,
        fields: [
          { name: 'Infrastructure', value: 'Online', inline: true },
          { name: 'Agents', value: '30,000 ready', inline: true },
          { name: 'Cloudflare', value: '200+ projects', inline: true }
        ]
      }]
    });
  }
  
  if (interaction.commandName === 'agents') {
    await interaction.reply('🤖 Active agents: Lucidia, Alice, Aria, Octavia, Cecilia, Shellfish, Codex');
  }
  
  if (interaction.commandName === 'help') {
    await interaction.reply('Visit https://blackroad.io for documentation');
  }
});

client.login(process.env.DISCORD_TOKEN);
