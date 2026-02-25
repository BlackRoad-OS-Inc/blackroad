#!/usr/bin/env node

import { Command } from 'commander';
import chalk from 'chalk';
import boxen from 'boxen';

import { statusCommand } from '../commands/status.js';
import { deployCommand } from '../commands/deploy.js';
import { logsCommand } from '../commands/logs.js';
import { healthCommand } from '../commands/health.js';
import { servicesCommand } from '../commands/services.js';
import { openCommand } from '../commands/open.js';
import { emojiCommand } from '../commands/emoji.js';
import { notifyCommand } from '../commands/notify.js';
import { quizCommand } from '../commands/quiz.js';
import { sshCommand } from '../commands/ssh.js';
import { tunnelCommand } from '../commands/tunnel.js';
import { networkCommand } from '../commands/network.js';
import { cloudflareCommand } from '../commands/cloudflare.js';
import { gitCommand } from '../commands/git.js';
import { railwayCommand } from '../commands/railway.js';
import { windowsCommand } from '../commands/windows.js';
import { monitorCommand } from '../commands/monitor.js';
import { dockerCommand } from '../commands/docker.js';
import { dbCommand } from '../commands/db.js';
import { scriptCommand } from '../commands/script.js';
import { cryptoCommand } from '../commands/crypto.js';
import { k8sCommand } from '../commands/k8s.js';
import { logsAggCommand } from '../commands/logs-agg.js';
import { agentsCommand } from '../commands/agents.js';
import { inventoryCommand } from '../commands/inventory.js';
import { runCommand } from '../commands/run.js';

// Import new enhancement systems
import BRMemory from '../lib/memory.js';
import Telemetry from '../lib/telemetry.js';

// Initialize enhancement systems
const memory = new BRMemory();
const telemetry = new Telemetry();

const program = new Command();

// ASCII art banner
const banner = `
${chalk.hex('#FF6B00')('██████╗ ')}${chalk.hex('#FF0066')('██╗      █████╗  ██████╗██╗  ██╗')}
${chalk.hex('#FF6B00')('██╔══██╗')}${chalk.hex('#FF0066')('██║     ██╔══██╗██╔════╝██║ ██╔╝')}
${chalk.hex('#FF6B00')('██████╔╝')}${chalk.hex('#FF0066')('██║     ███████║██║     █████╔╝ ')}
${chalk.hex('#FF6B00')('██╔══██╗')}${chalk.hex('#FF0066')('██║     ██╔══██║██║     ██╔═██╗ ')}
${chalk.hex('#FF6B00')('██████╔╝')}${chalk.hex('#FF0066')('███████╗██║  ██║╚██████╗██║  ██╗')}
${chalk.hex('#FF6B00')('╚═════╝ ')}${chalk.hex('#FF0066')('╚══════╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝')}
${chalk.gray('        R O A D   O S')}
`;

program
  .name('br')
  .description('BlackRoad OS CLI - Manage your services, deployments, and agents')
  .version('1.0.0')
  .hook('preAction', () => {
    // Show banner on first command
    if (process.argv.length <= 2) {
      console.log(banner);
    }
  });

// Status command
program
  .command('status')
  .alias('s')
  .description('Check status of all BlackRoad services')
  .option('-j, --json', 'Output as JSON')
  .option('-w, --watch', 'Watch mode - refresh every 30 seconds')
  .action(statusCommand);

// Deploy command
program
  .command('deploy [service]')
  .alias('d')
  .description('Deploy a service to Railway')
  .option('-a, --all', 'Deploy all services')
  .option('--detach', 'Run deployment in background')
  .action(deployCommand);

// Logs command
program
  .command('logs [service]')
  .alias('l')
  .description('View logs for a service')
  .option('-f, --follow', 'Follow log output')
  .option('-n, --lines <number>', 'Number of lines to show', '50')
  .action(logsCommand);

// Health command
program
  .command('health')
  .alias('h')
  .description('Run health check on all services')
  .option('--heal', 'Attempt to auto-heal unhealthy services')
  .action(healthCommand);

// Services command
program
  .command('services')
  .alias('svc')
  .description('List all BlackRoad services and their URLs')
  .option('-c, --category <category>', 'Filter by category (core, web, infra)')
  .action(servicesCommand);

// Open command
program
  .command('open <target>')
  .alias('o')
  .description('Open a service, dashboard, or docs in browser')
  .action(openCommand);

// Emoji translator command
program
  .command('emoji [text]')
  .alias('e')
  .description('🗣️  Translate text to emoji or enter interactive mode')
  .option('-i, --interactive', 'Interactive translation mode')
  .option('-p, --phrases', 'Show emoji phrase library')
  .option('-s, --search <term>', 'Search emoji dictionary')
  .option('-r, --random', 'Generate random emoji sentences')
  .action(emojiCommand);

// Agents command
program
  .command('agents')
  .alias('a')
  .description('Start a multi-agent voice room')
  .option('-s, --seed <text>', 'Seed prompt for the room')
  .option('--seed-file <path>', 'Seed prompt from a file')
  .option('--topics-file <path>', 'Run multiple prompts from a file (one per line)')
  .option('-r, --rounds <n>', 'Rounds of agent-to-agent replies per prompt', '1')
  .option('-m, --mode <mode>', 'Response mode: chain or broadcast')
  .option('-a, --agenda <text>', 'Agenda or framing added to prompts')
  .option('--room <name>', 'Room name for announcements')
  .option('-p, --prefix <prefix>', 'Only include models with this prefix')
  .option('-l, --limit <n>', 'Limit number of models')
  .option('--exclude <pattern>', 'Exclude models matching regex')
  .option('--remove <pattern>', 'Remove models matching regex from roster', (value, previous) => {
    const list = Array.isArray(previous) ? previous : [];
    return list.concat([value]);
  }, [])
  .option('--mute <pattern>', 'Mute models matching regex', (value, previous) => {
    const list = Array.isArray(previous) ? previous : [];
    return list.concat([value]);
  }, [])
  .option('--pin <pattern>', 'Pin models matching regex', (value, previous) => {
    const list = Array.isArray(previous) ? previous : [];
    return list.concat([value]);
  }, [])
  .option('--queue <pattern>', 'Queue models matching regex', (value, previous) => {
    const list = Array.isArray(previous) ? previous : [];
    return list.concat([value]);
  }, [])
  .option('--spotlight <pattern>', 'Spotlight one or more models (mutes others)')
  .option('--shuffle', 'Shuffle speaker order each round')
  .option('--parallel', 'Run broadcast replies in parallel')
  .option('--round-robin', 'Rotate non-pinned speakers each round')
  .option('--roles-file <path>', 'Assign per-model roles from a file (model=role)')
  .option('--role-default <text>', 'Default role for all models')
  .option('--speaker-count <n>', 'Limit active speakers per round')
  .option('--speaker-delay <s>', 'Pause between speakers (seconds)')
  .option('--round-delay <s>', 'Pause between rounds (seconds)')
  .option('--topic-delay <s>', 'Pause between topics (seconds)')
  .option('--roster-file <path>', 'Use a roster file for participants')
  .option('--intro', 'Announce room details before starting')
  .option('--rollcall', 'Ask each agent to say hello before the rounds')
  .option('--summary', 'Moderator summarizes at the end')
  .option('--summary-final', 'Add one final summary at the end')
  .option('--summary-file <path>', 'Write summaries to a file')
  .option('--minutes', 'Generate meeting minutes at the end')
  .option('--minutes-file <path>', 'Write minutes to a file')
  .option('--stats', 'Print speaker stats at the end')
  .option('--stats-file <path>', 'Write speaker stats to a file')
  .option('--scribe <model>', 'Model to use for minutes (default: moderator)')
  .option('--moderator <model>', 'Moderator model (default: first model)')
  .option('--transcript <path>', 'Write transcript to file')
  .option('--roster', 'Print roster and exit')
  .option('--max-chars <n>', 'Max characters per response')
  .option('--context-lines <n>', 'Include last N lines of context in prompts')
  .option('--mute-voice', 'Disable TTS output')
  .option('--mic', 'Use microphone input via whisper.cpp')
  .action(agentsCommand);

// Notify command
program
  .command('notify [message]')
  .alias('n')
  .description('🔔 Emoji-based notifications and log prefixes')
  .option('-d, --demo <type>', 'Demo notification type (deploy, build, test, health, git, server)')
  .option('-l, --log <level>', 'Log a message with emoji prefix')
  .option('--prefixes', 'Show all available log prefixes')
  .action((message, options) => notifyCommand({ ...options, message }));

// Quiz command
program
  .command('quiz')
  .alias('q')
  .description('🎮 Play emoji language games and quizzes')
  .option('-r, --rounds <n>', 'Number of quiz rounds', '5')
  .option('-t, --type <type>', 'Quiz type (translate, decode, complete, grammar, mixed)', 'mixed')
  .option('-f, --flashcards', 'Flashcard mode')
  .option('-b, --builder', 'Sentence builder game')
  .option('-c, --count <n>', 'Number of flashcards', '10')
  .action(quizCommand);

// SSH command
program
  .command('ssh [target]')
  .description('🔌 SSH into BlackRoad infrastructure')
  .option('-l, --list', 'List all available hosts')
  .option('-t, --test', 'Test SSH connections to all hosts')
  .option('-u, --user <user>', 'Specify SSH user')
  .option('-p, --port <port>', 'Specify SSH port')
  .option('-c, --command <cmd>', 'Execute command on remote host')
  .action(sshCommand);

// Tunnel command
program
  .command('tunnel')
  .description('🚇 Manage Cloudflare Tunnel')
  .option('-l, --list', 'List all tunnels')
  .option('-i, --info', 'Show tunnel information')
  .option('-s, --start', 'Start the tunnel')
  .option('--dns <subdomain>', 'Create DNS record for subdomain')
  .option('--config <path>', 'Path to tunnel config file')
  .action(tunnelCommand);

// Network command
program
  .command('network')
  .description('🌐 Network diagnostics and mapping')
  .option('--scan', 'Scan all network hosts')
  .option('--ports <host>', 'Scan common ports on a host')
  .option('--trace <host>', 'Trace route to host')
  .action(networkCommand);

// Cloudflare command
program
  .command('cf')
  .alias('cloudflare')
  .description('☁️  Manage Cloudflare resources')
  .option('--kv', 'List KV namespaces')
  .option('--kv-list', 'List KV namespaces')
  .option('--kv-get <ns:key>', 'Get KV value')
  .option('--kv-set <ns:key=value>', 'Set KV value')
  .option('--d1', 'List D1 databases')
  .option('--d1-query <db:sql>', 'Query D1 database')
  .option('--pages', 'List Pages projects')
  .option('--pages-deploy <project:dir>', 'Deploy to Pages')
  .option('--whoami', 'Show account info')
  .action(cloudflareCommand);

// Git command
program
  .command('git')
  .description('🐙 Git and GitHub operations')
  .option('-s, --status', 'Git status')
  .option('--pr', 'List pull requests')
  .option('--pr-list', 'List pull requests')
  .option('--pr-create', 'Create pull request')
  .option('--pr-view <number>', 'View PR in browser')
  .option('--workflow', 'List GitHub workflows')
  .option('--workflow-list', 'List GitHub workflows')
  .option('--workflow-run <name>', 'Run a workflow')
  .action(gitCommand);

// Railway command
program
  .command('rw')
  .alias('railway')
  .description('🚂 Railway management')
  .option('-l, --list', 'List all services')
  .option('--status <service>', 'Service status')
  .option('--logs <service>', 'View service logs')
  .option('-f, --follow', 'Follow logs (use with --logs)')
  .option('--redeploy <service>', 'Redeploy service')
  .option('--vars <service>', 'View environment variables')
  .option('--open', 'Open dashboard')
  .option('--whoami', 'Check authentication')
  .action(railwayCommand);

// Windows command
program
  .command('windows')
  .alias('w')
  .description('🪟  Multi-window terminal (7 windows with SSH + AI)')
  .action(windowsCommand);

// Monitor command
program
  .command('monitor')
  .alias('m')
  .description('🖥️  Real-time system monitoring dashboard')
  .action(monitorCommand);

// Docker command
program
  .command('docker')
  .description('🐳 Docker container management')
  .option('--ps, --list', 'List containers')
  .option('-a, --all', 'Show all containers (with --ps)')
  .option('--images', 'List images')
  .option('--stats', 'Show container stats')
  .option('--start <name>', 'Start container')
  .option('--stop <name>', 'Stop container')
  .option('--restart <name>', 'Restart container')
  .option('--rm <name>', 'Remove container')
  .option('--logs <name>', 'View container logs')
  .option('-f, --follow', 'Follow logs (use with --logs)')
  .option('--tail <lines>', 'Number of log lines', '100')
  .option('--exec <container command>', 'Execute command in container')
  .option('--up', 'Docker Compose up')
  .option('-d, --detach', 'Detached mode (with --up)')
  .option('--down', 'Docker Compose down')
  .option('--prune', 'Prune unused resources')
  .action(dockerCommand);

// Database command
program
  .command('db')
  .description('🗄️  Database management (PostgreSQL, MySQL, MongoDB, Redis)')
  .option('--types', 'List available database types')
  .option('--postgres', 'Use PostgreSQL')
  .option('--mysql', 'Use MySQL')
  .option('--mongodb', 'Use MongoDB')
  .option('--redis', 'Use Redis')
  .option('--type <type>', 'Specify database type')
  .option('--connect', 'Interactive connection')
  .option('--list', 'List databases')
  .option('--dump', 'Dump database to file')
  .option('--host <host>', 'Database host')
  .option('--port <port>', 'Database port')
  .option('--user <user>', 'Database user')
  .option('--database <name>', 'Database name')
  .action(dbCommand);

// Script command
program
  .command('script')
  .description('📜 Automation & scripting')
  .option('--list', 'List all scripts')
  .option('--template', 'Create from template')
  .option('--create', 'Create custom script')
  .option('--run <name>', 'Run a script')
  .option('--delete', 'Delete a script')
  .option('--args <args>', 'Pass arguments to script')
  .action(scriptCommand);

// Crypto command
program
  .command('crypto')
  .description('₿ Cryptocurrency wallet management')
  .option('--chains', 'List supported blockchains')
  .option('--add', 'Add a wallet')
  .option('--list', 'List all wallets')
  .option('--balances', 'Show wallet balances')
  .option('--view', 'View wallet details')
  .option('--remove', 'Remove a wallet')
  .option('--prices', 'Show current crypto prices')
  .action(cryptoCommand);

// Kubernetes command
program
  .command('k8s')
  .description('☸️  Kubernetes cluster management')
  .option('--contexts', 'List contexts')
  .option('--use <context>', 'Switch context')
  .option('--namespaces', 'List namespaces')
  .option('--pods', 'List pods')
  .option('--services', 'List services')
  .option('--deployments', 'List deployments')
  .option('--logs <pod>', 'View pod logs')
  .option('-f, --follow', 'Follow logs')
  .option('--tail <lines>', 'Number of log lines', '100')
  .option('--exec <pod command>', 'Execute command in pod')
  .option('--scale <dep:replicas>', 'Scale deployment')
  .option('--restart <deployment>', 'Restart deployment')
  .option('--apply <file>', 'Apply manifest')
  .option('-n, --namespace <ns>', 'Specify namespace', 'default')
  .action(k8sCommand);

// Log aggregator command
program
  .command('logs-agg')
  .alias('lagg')
  .description('📊 Real-time log aggregation across all servers')
  .action(logsAggCommand);

// ===== NEW ENHANCEMENT COMMANDS =====

// Inventory management command
inventoryCommand(program);

// Distributed execution command
runCommand(program);

// Telemetry command
program
  .command('telemetry')
  .alias('telem')
  .description('📊 View BR-CLI telemetry and performance metrics')
  .action(() => {
    telemetry.showDashboard();
  });

// Memory command
program
  .command('memory')
  .alias('mem')
  .description('🧠 View BR-CLI command history and context')
  .option('-l, --limit <n>', 'Number of history items', '10')
  .action(async (options) => {
    const history = await memory.getHistory(parseInt(options.limit));
    console.log(chalk.bold.cyan('\n🧠 Command History\n'));
    history.forEach((record, i) => {
      const status = record.result === 'success' ? chalk.green('✓') : chalk.red('✗');
      console.log(
        chalk.gray(`${i + 1}.`) + ' ' +
        status + ' ' +
        chalk.yellow(record.command) + ' ' +
        chalk.gray(record.timestamp)
      );
    });
    console.log('');
  });

// Show banner when run without arguments
if (process.argv.length <= 2) {
  console.log(banner);
  console.log(boxen(
    `${chalk.bold('Quick Commands:')}\n\n` +
    `${chalk.hex('#FF9D00')('Services & Deployment:')}\n` +
    `  ${chalk.cyan('br status')}       Check all services\n` +
    `  ${chalk.cyan('br deploy')}       Deploy a service\n` +
    `  ${chalk.cyan('br health')}       Run health checks\n\n` +
    `${chalk.hex('#FF0066')('Infrastructure:')}\n` +
    `  ${chalk.cyan('br ssh')}          SSH into servers\n` +
    `  ${chalk.cyan('br tunnel')}       Manage Cloudflare Tunnel\n` +
    `  ${chalk.cyan('br network')}      Network diagnostics\n\n` +
    `${chalk.hex('#0066FF')('Platform Management:')}\n` +
    `  ${chalk.cyan('br cf')}           Cloudflare (KV, D1, Pages)\n` +
    `  ${chalk.cyan('br git')}          Git & GitHub operations\n` +
    `  ${chalk.cyan('br rw')}           Railway services\n\n` +
    `${chalk.hex('#7700FF')('Advanced:')}\n` +
    `  ${chalk.cyan('br windows')}      🪟  Multi-window terminal\n` +
    `  ${chalk.cyan('br monitor')}      🖥️  System monitoring\n` +
    `  ${chalk.cyan('br logs-agg')}     📊 Log aggregation\n` +
    `  ${chalk.cyan('br docker')}       🐳 Docker management\n` +
    `  ${chalk.cyan('br k8s')}          ☸️  Kubernetes\n` +
    `  ${chalk.cyan('br db')}           🗄️  Database tools\n` +
    `  ${chalk.cyan('br crypto')}       ₿  Crypto wallets\n` +
    `  ${chalk.cyan('br script')}       📜 Automation\n\n` +
    `${chalk.hex('#00FF88')('✨ New Enhancement Features:')}\n` +
    `  ${chalk.cyan('br inventory')}    🏗️  Infrastructure management\n` +
    `  ${chalk.cyan('br run')}          ⚡ Distributed execution\n` +
    `  ${chalk.cyan('br telemetry')}    📊 Performance metrics\n` +
    `  ${chalk.cyan('br memory')}       🧠 Command history\n\n` +
    `${chalk.gray('Run')} ${chalk.cyan('br --help')} ${chalk.gray('for all commands')}`,
    {
      padding: 1,
      margin: 1,
      borderStyle: 'round',
      borderColor: '#FF6B00'
    }
  ));
} else {
  program.parse();
}
