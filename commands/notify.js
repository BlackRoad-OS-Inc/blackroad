import chalk from 'chalk';
import ora from 'ora';
import {
  emoji,
  phrases,
  getRandomStatus,
  progressBar,
  moodMeter,
  timeGreeting,
} from '../lib/emoji.js';

// Notification templates
const notifications = {
  deploy: {
    start: '📦 ➡️ 🚂 Starting deployment...',
    progress: (p) => `🚀 ${progressBar(p)} Deploying...`,
    success: '✅ 🚀 💯 🎉 Deployment successful!',
    fail: '❌ 🚀 💀 😭 Deployment failed!',
  },
  build: {
    start: '🔨 ➡️ 📦 Starting build...',
    progress: (p) => `🔨 ${progressBar(p)} Building...`,
    success: '✅ 🔨 ✨ Build complete!',
    fail: '❌ 🔨 💥 😭 Build failed!',
  },
  test: {
    start: '🧪 ➡️ 🔬 Running tests...',
    progress: (p) => `🧪 ${progressBar(p)} Testing...`,
    success: '✅ 🧪 💚 All tests passed!',
    fail: '❌ 🧪 🔴 Tests failed!',
  },
  health: {
    checking: '🏥 🔍 Checking health...',
    healthy: '💚 ✨ All systems operational!',
    degraded: '💛 ⚠️ Some services degraded',
    down: '💔 🚨 Services down!',
  },
  git: {
    push: '📤 ➡️ 🐙 Pushing to GitHub...',
    pull: '📥 ⬅️ 🐙 Pulling from GitHub...',
    commit: '💾 ✅ Changes committed!',
    merge: '🔀 ✅ Merged successfully!',
    conflict: '⚔️ ❌ Merge conflict!',
  },
  server: {
    starting: '🖥️ ⏳ Server starting...',
    running: '🖥️ ✅ 🚀 Server running!',
    stopping: '🖥️ 🛑 Server stopping...',
    crashed: '🖥️ 💥 💀 Server crashed!',
  },
};

// Demo notifications with animation
async function demoNotifications(type) {
  const notif = notifications[type];
  if (!notif) {
    console.log(chalk.red(`\n  ❌ Unknown notification type: ${type}\n`));
    console.log(chalk.gray('  Available: deploy, build, test, health, git, server\n'));
    return;
  }

  console.log(chalk.hex('#FF6B00').bold(`\n  🔔 ${type.toUpperCase()} Notification Demo\n`));

  if (notif.start) {
    const spinner = ora(chalk.cyan(notif.start)).start();
    await sleep(1000);

    // Progress simulation
    if (notif.progress) {
      for (let i = 0; i <= 100; i += 20) {
        spinner.text = chalk.cyan(notif.progress(i));
        await sleep(300);
      }
    }

    // Random success/fail
    const success = Math.random() > 0.3;
    await sleep(500);

    if (success && notif.success) {
      spinner.succeed(chalk.green(notif.success));
    } else if (notif.fail) {
      spinner.fail(chalk.red(notif.fail));
    }
  } else {
    // Health-style notifications
    Object.entries(notif).forEach(([key, msg]) => {
      if (key === 'checking') {
        console.log(chalk.cyan(`  ${msg}`));
      } else if (key === 'healthy') {
        console.log(chalk.green(`  ${msg}`));
      } else if (key === 'degraded') {
        console.log(chalk.yellow(`  ${msg}`));
      } else {
        console.log(chalk.red(`  ${msg}`));
      }
    });
  }
  console.log();
}

// Log with emoji prefix
function emojiLog(level, message) {
  const prefixes = {
    info: '📢',
    success: '✅',
    warning: '⚠️',
    error: '❌',
    debug: '🔍',
    deploy: '🚀',
    build: '🔨',
    test: '🧪',
    fix: '🔧',
    add: '➕',
    remove: '➖',
    update: '🔄',
    merge: '🔀',
    release: '🎉',
    security: '🔒',
    performance: '⚡',
    docs: '📚',
    style: '💄',
    refactor: '♻️',
    ci: '👷',
    chore: '🧹',
  };

  const prefix = prefixes[level] || '💬';
  const colors = {
    info: chalk.cyan,
    success: chalk.green,
    warning: chalk.yellow,
    error: chalk.red,
    debug: chalk.gray,
  };

  const color = colors[level] || chalk.white;
  console.log(color(`  ${prefix} ${message}`));
}

// Show all notification types
function showAll() {
  console.log(chalk.hex('#FF6B00').bold('\n  🔔 Emoji Notification Library\n'));

  Object.entries(notifications).forEach(([type, notifs]) => {
    console.log(chalk.yellow(`\n  ${type.toUpperCase()}:`));
    Object.entries(notifs).forEach(([key, value]) => {
      const msg = typeof value === 'function' ? value(75) : value;
      console.log(chalk.gray(`    ${key}:`) + chalk.cyan(` ${msg}`));
    });
  });
  console.log();
}

// Show log prefixes
function showPrefixes() {
  console.log(chalk.hex('#FF6B00').bold('\n  🏷️  Log Prefixes for Commits & Messages\n'));

  const prefixes = [
    ['info', '📢', 'General information'],
    ['success', '✅', 'Something succeeded'],
    ['warning', '⚠️', 'Warning message'],
    ['error', '❌', 'Error occurred'],
    ['debug', '🔍', 'Debug info'],
    ['deploy', '🚀', 'Deployment'],
    ['build', '🔨', 'Build process'],
    ['test', '🧪', 'Testing'],
    ['fix', '🔧', 'Bug fix'],
    ['add', '➕', 'New feature'],
    ['remove', '➖', 'Removed something'],
    ['update', '🔄', 'Update/change'],
    ['merge', '🔀', 'Merge branches'],
    ['release', '🎉', 'New release'],
    ['security', '🔒', 'Security fix'],
    ['performance', '⚡', 'Performance improvement'],
    ['docs', '📚', 'Documentation'],
    ['style', '💄', 'UI/Style changes'],
    ['refactor', '♻️', 'Code refactoring'],
    ['ci', '👷', 'CI/CD changes'],
    ['chore', '🧹', 'Maintenance'],
  ];

  prefixes.forEach(([key, emoji, desc]) => {
    console.log(chalk.gray(`  ${key.padEnd(12)}`) + chalk.cyan(`${emoji}  `) + chalk.gray(desc));
  });

  console.log(chalk.gray('\n  Usage: br notify --log <level> "message"\n'));
}

function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

export async function notifyCommand(options) {
  // Demo a notification type
  if (options.demo) {
    await demoNotifications(options.demo);
    return;
  }

  // Log a message with emoji
  if (options.log) {
    emojiLog(options.log, options.message || 'No message provided');
    return;
  }

  // Show all prefixes
  if (options.prefixes) {
    showPrefixes();
    return;
  }

  // Default: show all notifications
  showAll();
}
