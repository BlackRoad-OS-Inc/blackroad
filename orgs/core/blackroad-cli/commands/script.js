import chalk from 'chalk';
import { spawn } from 'child_process';
import fs from 'fs/promises';
import path from 'path';
import ora from 'ora';
import inquirer from 'inquirer';
import Table from 'cli-table3';

const SCRIPTS_DIR = path.join(process.env.HOME, '.blackroad', 'scripts');

class ScriptRunner {
  constructor() {
    this.variables = {};
  }

  async ensureScriptsDir() {
    try {
      await fs.mkdir(SCRIPTS_DIR, { recursive: true });
    } catch (e) {
      // Directory exists
    }
  }

  async listScripts() {
    await this.ensureScriptsDir();

    try {
      const files = await fs.readdir(SCRIPTS_DIR);
      return files.filter(f => f.endsWith('.br.js') || f.endsWith('.br.sh'));
    } catch (e) {
      return [];
    }
  }

  async readScript(name) {
    const scriptPath = path.join(SCRIPTS_DIR, name);
    const content = await fs.readFile(scriptPath, 'utf-8');
    return content;
  }

  async saveScript(name, content) {
    await this.ensureScriptsDir();
    const scriptPath = path.join(SCRIPTS_DIR, name);
    await fs.writeFile(scriptPath, content, 'utf-8');
    await fs.chmod(scriptPath, '755');
  }

  async deleteScript(name) {
    const scriptPath = path.join(SCRIPTS_DIR, name);
    await fs.unlink(scriptPath);
  }

  async runScript(name, args = []) {
    const scriptPath = path.join(SCRIPTS_DIR, name);

    if (name.endsWith('.br.sh')) {
      return this.runShellScript(scriptPath, args);
    } else if (name.endsWith('.br.js')) {
      return this.runJavaScriptScript(scriptPath, args);
    }
  }

  async runShellScript(scriptPath, args) {
    return new Promise((resolve, reject) => {
      const proc = spawn('bash', [scriptPath, ...args], {
        stdio: 'inherit',
        env: {
          ...process.env,
          ...this.variables
        }
      });

      proc.on('close', (code) => {
        if (code === 0) {
          resolve({ success: true });
        } else {
          reject(new Error(`Script exited with code ${code}`));
        }
      });

      proc.on('error', (err) => {
        reject(err);
      });
    });
  }

  async runJavaScriptScript(scriptPath, args) {
    return new Promise((resolve, reject) => {
      const proc = spawn('node', [scriptPath, ...args], {
        stdio: 'inherit',
        env: {
          ...process.env,
          ...this.variables
        }
      });

      proc.on('close', (code) => {
        if (code === 0) {
          resolve({ success: true });
        } else {
          reject(new Error(`Script exited with code ${code}`));
        }
      });

      proc.on('error', (err) => {
        reject(err);
      });
    });
  }
}

const SCRIPT_TEMPLATES = {
  'deploy-all': {
    name: 'deploy-all.br.sh',
    description: 'Deploy all services',
    content: `#!/bin/bash
# BlackRoad Deploy All Script

echo "🚀 Deploying all services..."

# Deploy to Railway
echo "📦 Deploying to Railway..."
railway up -d

# Deploy to Cloudflare Pages
echo "☁️  Deploying to Cloudflare..."
wrangler pages deploy dist --project-name blackroad

echo "✅ All deployments complete!"
`
  },
  'health-check': {
    name: 'health-check.br.sh',
    description: 'Run health checks on all infrastructure',
    content: `#!/bin/bash
# BlackRoad Health Check Script

echo "🏥 Running health checks..."

# Check all hosts
HOSTS=(
  "192.168.4.64:ARIA"
  "159.65.43.12:CODEX"
  "174.138.44.45:SHELLFISH"
  "192.168.4.49:ALICE"
  "192.168.4.38:LUCIDIA"
)

for host_entry in "\${HOSTS[@]}"; do
  IFS=':' read -r host name <<< "$host_entry"
  echo -n "Checking $name ($host)... "

  if ping -c 1 -W 2 "$host" > /dev/null 2>&1; then
    echo "✅ Online"
  else
    echo "❌ Offline"
  fi
done

echo "✅ Health check complete!"
`
  },
  'backup-db': {
    name: 'backup-db.br.sh',
    description: 'Backup all databases',
    content: `#!/bin/bash
# BlackRoad Database Backup Script

BACKUP_DIR=~/blackroad-backups/$(date +%Y%m%d)
mkdir -p "$BACKUP_DIR"

echo "💾 Backing up databases to $BACKUP_DIR..."

# PostgreSQL
if command -v pg_dump &> /dev/null; then
  echo "📊 Backing up PostgreSQL..."
  pg_dump -U postgres mydb > "$BACKUP_DIR/postgres-mydb.sql"
fi

# MySQL
if command -v mysqldump &> /dev/null; then
  echo "🐬 Backing up MySQL..."
  mysqldump -u root mydb > "$BACKUP_DIR/mysql-mydb.sql"
fi

# MongoDB
if command -v mongodump &> /dev/null; then
  echo "🍃 Backing up MongoDB..."
  mongodump --db mydb --out "$BACKUP_DIR/mongodb"
fi

echo "✅ Backup complete! Saved to $BACKUP_DIR"
`
  },
  'monitor': {
    name: 'monitor.br.js',
    description: 'Custom monitoring script',
    content: `#!/usr/bin/env node
// BlackRoad Monitoring Script

console.log('🖥️  Starting custom monitor...');

const hosts = [
  { name: 'ARIA', host: '192.168.4.64' },
  { name: 'CODEX', host: '159.65.43.12' },
  { name: 'SHELLFISH', host: '174.138.44.45' }
];

async function checkHost(host) {
  return new Promise((resolve) => {
    const { spawn } = require('child_process');
    const proc = spawn('ping', ['-c', '1', host.host]);

    proc.on('close', (code) => {
      resolve({
        ...host,
        status: code === 0 ? 'online' : 'offline'
      });
    });
  });
}

async function main() {
  const results = await Promise.all(hosts.map(checkHost));

  console.log('\\n📊 Status Report:\\n');
  results.forEach(r => {
    const icon = r.status === 'online' ? '✅' : '❌';
    console.log(\`  \${icon} \${r.name} (\${r.host}) - \${r.status}\`);
  });
  console.log();
}

main();
`
  }
};

export async function scriptCommand(options) {
  const runner = new ScriptRunner();

  // List scripts
  if (options.list) {
    const spinner = ora('Fetching scripts...').start();

    try {
      const scripts = await runner.listScripts();
      spinner.stop();

      console.log(chalk.hex('#FF6B00').bold('\n  📜 BlackRoad Scripts\n'));

      if (scripts.length === 0) {
        console.log(chalk.yellow('  No scripts found.'));
        console.log(chalk.gray('  Create a script with: br script --create\n'));
        return;
      }

      const table = new Table({
        head: [chalk.gray('Name'), chalk.gray('Type'), chalk.gray('Location')],
        style: { head: [], border: ['gray'] }
      });

      scripts.forEach(s => {
        const type = s.endsWith('.sh') ? chalk.green('Shell') : chalk.cyan('JavaScript');
        table.push([s, type, SCRIPTS_DIR]);
      });

      console.log(table.toString());
      console.log(chalk.gray(`\n  Total: ${scripts.length} script(s)\n`));

    } catch (e) {
      spinner.fail(chalk.red('Failed to list scripts'));
      console.log(chalk.red(`  ❌ ${e.message}\n`));
    }
    return;
  }

  // Create script from template
  if (options.template) {
    const templates = Object.entries(SCRIPT_TEMPLATES);

    const { selected } = await inquirer.prompt([
      {
        type: 'list',
        name: 'selected',
        message: 'Select template:',
        choices: templates.map(([key, tmpl]) => ({
          name: `${tmpl.name} - ${tmpl.description}`,
          value: key
        }))
      }
    ]);

    const template = SCRIPT_TEMPLATES[selected];
    const spinner = ora(`Creating ${template.name}...`).start();

    try {
      await runner.saveScript(template.name, template.content);
      spinner.succeed(chalk.green(`✅ Script created: ${template.name}`));
      console.log(chalk.gray(`\n  Location: ${path.join(SCRIPTS_DIR, template.name)}`));
      console.log(chalk.gray(`  Run with: br script --run ${template.name}\n`));
    } catch (e) {
      spinner.fail(chalk.red('Failed to create script'));
      console.log(chalk.red(`  ❌ ${e.message}\n`));
    }
    return;
  }

  // Create custom script
  if (options.create) {
    const answers = await inquirer.prompt([
      {
        type: 'input',
        name: 'name',
        message: 'Script name:',
        validate: (input) => {
          if (!input) return 'Name is required';
          if (!input.endsWith('.br.sh') && !input.endsWith('.br.js')) {
            return 'Must end with .br.sh or .br.js';
          }
          return true;
        }
      },
      {
        type: 'list',
        name: 'type',
        message: 'Script type:',
        choices: ['Shell (.br.sh)', 'JavaScript (.br.js)']
      }
    ]);

    const content = answers.type.includes('Shell')
      ? '#!/bin/bash\n\necho "Hello from BlackRoad Script!"\n'
      : '#!/usr/bin/env node\n\nconsole.log("Hello from BlackRoad Script!");\n';

    const spinner = ora(`Creating ${answers.name}...`).start();

    try {
      await runner.saveScript(answers.name, content);
      spinner.succeed(chalk.green(`✅ Script created: ${answers.name}`));
      console.log(chalk.gray(`\n  Location: ${path.join(SCRIPTS_DIR, answers.name)}`));
      console.log(chalk.gray(`  Edit with: code ${path.join(SCRIPTS_DIR, answers.name)}`));
      console.log(chalk.gray(`  Run with: br script --run ${answers.name}\n`));
    } catch (e) {
      spinner.fail(chalk.red('Failed to create script'));
      console.log(chalk.red(`  ❌ ${e.message}\n`));
    }
    return;
  }

  // Run script
  if (options.run) {
    const scriptName = options.run;
    const args = options.args ? options.args.split(' ') : [];

    console.log(chalk.hex('#FF6B00').bold(`\n  🚀 Running ${scriptName}...\n`));

    try {
      await runner.runScript(scriptName, args);
      console.log(chalk.green(`\n  ✅ Script completed successfully!\n`));
    } catch (e) {
      console.log(chalk.red(`\n  ❌ Script failed: ${e.message}\n`));
    }
    return;
  }

  // Delete script
  if (options.delete) {
    const scripts = await runner.listScripts();

    const { selected } = await inquirer.prompt([
      {
        type: 'list',
        name: 'selected',
        message: 'Select script to delete:',
        choices: scripts
      }
    ]);

    const { confirm } = await inquirer.prompt([
      {
        type: 'confirm',
        name: 'confirm',
        message: `Delete ${selected}?`,
        default: false
      }
    ]);

    if (!confirm) {
      console.log(chalk.yellow('\n  Cancelled.\n'));
      return;
    }

    const spinner = ora(`Deleting ${selected}...`).start();

    try {
      await runner.deleteScript(selected);
      spinner.succeed(chalk.green(`✅ Script deleted: ${selected}`));
      console.log();
    } catch (e) {
      spinner.fail(chalk.red('Failed to delete script'));
      console.log(chalk.red(`  ❌ ${e.message}\n`));
    }
    return;
  }

  // Default: show overview
  console.log(chalk.hex('#FF6B00').bold('\n  📜 Script Management\n'));

  const table = new Table({
    head: [chalk.gray('Command'), chalk.gray('Description')],
    style: { head: [], border: ['gray'] }
  });

  table.push(
    ['--list', 'List all scripts'],
    ['--template', 'Create from template'],
    ['--create', 'Create custom script'],
    ['--run <name>', 'Run a script'],
    ['--delete', 'Delete a script'],
    ['--args "<args>"', 'Pass args to script (with --run)']
  );

  console.log(table.toString());
  console.log();

  console.log(chalk.gray('  💡 Examples:'));
  console.log(chalk.gray('    br script --list'));
  console.log(chalk.gray('    br script --template'));
  console.log(chalk.gray('    br script --create'));
  console.log(chalk.gray('    br script --run deploy-all.br.sh'));
  console.log();
}
