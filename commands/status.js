import chalk from 'chalk';
import ora from 'ora';
import Table from 'cli-table3';
import { getAllServices } from '../lib/services.js';

async function checkService(service) {
  const start = Date.now();
  try {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 10000);

    const response = await fetch(`https://${service.url}`, {
      method: 'GET',
      signal: controller.signal,
      redirect: 'follow'
    });

    clearTimeout(timeout);
    const responseTime = Date.now() - start;

    // Consider 2xx, 3xx, and even 404 (page exists but route not found) as "reachable"
    const isHealthy = response.status < 500;

    return {
      ...service,
      status: isHealthy ? 'healthy' : 'degraded',
      responseTime,
      httpCode: response.status
    };
  } catch (e) {
    return {
      ...service,
      status: 'down',
      responseTime: Date.now() - start,
      httpCode: 0,
      error: e.message
    };
  }
}

export async function statusCommand(options) {
  const spinner = ora('Checking service status...').start();

  const services = getAllServices();
  const results = await Promise.all(services.map(checkService));

  spinner.stop();

  if (options.json) {
    console.log(JSON.stringify(results, null, 2));
    return;
  }

  const healthyCount = results.filter(s => s.status === 'healthy').length;
  const degradedCount = results.filter(s => s.status === 'degraded').length;
  const downCount = results.filter(s => s.status === 'down').length;

  // Overall status banner
  console.log();
  if (downCount === 0 && degradedCount === 0) {
    console.log(chalk.green.bold('  ✨ All Systems Operational 🚀'));
  } else if (downCount > 0) {
    console.log(chalk.red.bold(`  🔥 ${downCount} service(s) down 💀`));
  } else {
    console.log(chalk.yellow.bold(`  ⚡ ${degradedCount} service(s) degraded 🔧`));
  }
  console.log();

  // Create table
  const table = new Table({
    head: [
      chalk.gray('Status'),
      chalk.gray('Service'),
      chalk.gray('URL'),
      chalk.gray('Response'),
      chalk.gray('Platform')
    ],
    style: {
      head: [],
      border: ['gray']
    }
  });

  for (const service of results) {
    const statusIcon = service.status === 'healthy'
      ? '💚'
      : service.status === 'degraded'
        ? '💛'
        : '💔';

    const responseTime = service.responseTime < 500
      ? chalk.green(`⚡ ${service.responseTime}ms`)
      : service.responseTime < 1500
        ? chalk.yellow(`🐢 ${service.responseTime}ms`)
        : chalk.red(`🦥 ${service.responseTime}ms`);

    const platform = service.railway
      ? '🚂 Railway'
      : '☁️  Cloudflare';

    table.push([
      statusIcon,
      service.name,
      chalk.cyan(service.url),
      responseTime,
      platform
    ]);
  }

  console.log(table.toString());
  console.log();
  console.log(chalk.gray(`  💚 ${healthyCount} vibin · 💛 ${degradedCount} struggling · 💔 ${downCount} ded`));
  console.log();

  // Watch mode
  if (options.watch) {
    console.log(chalk.gray('Refreshing every 30 seconds... (Ctrl+C to exit)'));
    setInterval(async () => {
      console.clear();
      await statusCommand({ ...options, watch: false });
      console.log(chalk.gray('Refreshing every 30 seconds... (Ctrl+C to exit)'));
    }, 30000);
  }
}
