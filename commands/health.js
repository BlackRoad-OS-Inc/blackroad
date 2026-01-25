import chalk from 'chalk';
import ora from 'ora';
import Table from 'cli-table3';
import { spawn } from 'child_process';
import { getAllServices, getRailwayServices } from '../lib/services.js';

async function checkEndpoint(url, endpoint = '/') {
  const start = Date.now();
  try {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 15000);

    const response = await fetch(`https://${url}${endpoint}`, {
      signal: controller.signal
    });

    clearTimeout(timeout);

    return {
      status: response.ok ? 'healthy' : 'unhealthy',
      code: response.status,
      time: Date.now() - start
    };
  } catch (e) {
    return {
      status: 'down',
      code: 0,
      time: Date.now() - start,
      error: e.message
    };
  }
}

async function healService(service) {
  return new Promise((resolve) => {
    const proc = spawn('railway', ['redeploy', '--service', service.slug, '--yes'], {
      stdio: 'pipe'
    });

    let output = '';
    proc.stdout?.on('data', (data) => output += data);
    proc.stderr?.on('data', (data) => output += data);

    proc.on('close', (code) => {
      resolve({ success: code === 0, output });
    });

    proc.on('error', () => {
      resolve({ success: false, output: 'Railway CLI not available' });
    });
  });
}

export async function healthCommand(options) {
  console.log(chalk.hex('#FF6B00').bold('\n  🏥 Running health checks... 🩺\n'));

  const services = getAllServices();
  const results = [];

  // Check each service
  for (const service of services) {
    const spinner = ora(`🔍 Checking ${service.name}...`).start();

    const health = await checkEndpoint(service.url);

    results.push({
      ...service,
      ...health
    });

    if (health.status === 'healthy') {
      spinner.succeed(chalk.green(`💪 ${service.name} healthy (${health.time}ms)`));
    } else if (health.status === 'unhealthy') {
      spinner.warn(chalk.yellow(`🤒 ${service.name} unhealthy (HTTP ${health.code})`));
    } else {
      spinner.fail(chalk.red(`☠️  ${service.name} down`));
    }
  }

  console.log();

  // Summary table
  const table = new Table({
    head: [
      chalk.gray('Service'),
      chalk.gray('Status'),
      chalk.gray('HTTP'),
      chalk.gray('Response'),
      chalk.gray('Details')
    ],
    style: {
      head: [],
      border: ['gray']
    }
  });

  const unhealthy = [];

  for (const r of results) {
    const statusColor = r.status === 'healthy'
      ? chalk.green
      : r.status === 'unhealthy'
        ? chalk.yellow
        : chalk.red;

    table.push([
      r.name,
      statusColor(r.status),
      r.code || '-',
      `${r.time}ms`,
      r.error || '-'
    ]);

    if (r.status !== 'healthy' && r.railway) {
      unhealthy.push(r);
    }
  }

  console.log(table.toString());

  // Auto-heal if requested
  if (options.heal && unhealthy.length > 0) {
    console.log(chalk.hex('#FF6B00').bold('\n  🧬 Attempting auto-heal... 💉\n'));

    for (const service of unhealthy) {
      const spinner = ora(`🩹 Healing ${service.name}...`).start();

      const result = await healService(service);

      if (result.success) {
        spinner.succeed(chalk.green(`✨ ${service.name} redeploy triggered`));
      } else {
        spinner.fail(chalk.red(`💀 ${service.name} heal failed`));
      }
    }

    console.log(chalk.gray('\n  ⏳ Services will take 1-2 minutes to redeploy.'));
    console.log(chalk.gray('  🔄 Run `br health` again to verify.\n'));
  } else if (unhealthy.length > 0 && !options.heal) {
    console.log(chalk.yellow(`\n  🚨 ${unhealthy.length} service(s) need attention.`));
    console.log(chalk.gray('  💊 Run `br health --heal` to attempt auto-recovery.\n'));
  } else if (unhealthy.length === 0) {
    console.log(chalk.green('\n  🎉 All services healthy! 💯\n'));
  }
}
