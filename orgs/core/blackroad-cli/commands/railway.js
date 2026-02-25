import chalk from 'chalk';
import { spawn } from 'child_process';
import ora from 'ora';
import Table from 'cli-table3';

const RAILWAY_PROJECT_ID = '03ce1e43-5086-4255-b2bc-0146c8916f4c';

function runRailway(args = []) {
  return new Promise((resolve, reject) => {
    const proc = spawn('railway', args, {
      stdio: 'pipe'
    });

    let stdout = '';
    let stderr = '';

    proc.stdout?.on('data', (data) => stdout += data.toString());
    proc.stderr?.on('data', (data) => stderr += data.toString());

    proc.on('close', (code) => {
      if (code === 0) {
        resolve({ success: true, stdout, stderr });
      } else {
        reject(new Error(stderr || `Command failed with code ${code}`));
      }
    });

    proc.on('error', (err) => {
      reject(err);
    });
  });
}

async function listServices() {
  try {
    const result = await runRailway(['service', 'list']);
    return result.stdout;
  } catch (e) {
    throw new Error(`Failed to list services: ${e.message}`);
  }
}

async function getServiceStatus(service) {
  try {
    const result = await runRailway(['status', '--service', service]);
    return result.stdout;
  } catch (e) {
    throw new Error(`Failed to get service status: ${e.message}`);
  }
}

async function getLogs(service, options = {}) {
  const args = ['logs', '--service', service];

  if (options.follow) {
    args.push('--follow');
  }

  const proc = spawn('railway', args, {
    stdio: 'inherit'
  });

  return new Promise((resolve) => {
    proc.on('close', () => resolve());
  });
}

async function redeployService(service) {
  try {
    const result = await runRailway(['redeploy', '--service', service, '--yes']);
    return result.stdout;
  } catch (e) {
    throw new Error(`Failed to redeploy service: ${e.message}`);
  }
}

async function openDashboard() {
  const proc = spawn('railway', ['open'], {
    stdio: 'inherit'
  });

  return new Promise((resolve) => {
    proc.on('close', () => resolve());
  });
}

async function getVariables(service) {
  try {
    const result = await runRailway(['variables', '--service', service]);
    return result.stdout;
  } catch (e) {
    throw new Error(`Failed to get variables: ${e.message}`);
  }
}

export async function railwayCommand(options) {
  // List services
  if (options.list) {
    const spinner = ora('Fetching Railway services...').start();

    try {
      const services = await listServices();
      spinner.stop();

      console.log(chalk.hex('#FF6B00').bold('\n  🚂 Railway Services\n'));
      console.log(services);
      console.log();
    } catch (e) {
      spinner.fail(chalk.red('Failed to list services'));
      console.log(chalk.red(`  ❌ ${e.message}\n`));
    }
    return;
  }

  // Service status
  if (options.status) {
    const service = options.status;
    const spinner = ora(`Checking ${service} status...`).start();

    try {
      const status = await getServiceStatus(service);
      spinner.stop();

      console.log(chalk.hex('#FF6B00').bold(`\n  📊 ${service} Status\n`));
      console.log(status);
      console.log();
    } catch (e) {
      spinner.fail(chalk.red('Failed to get status'));
      console.log(chalk.red(`  ❌ ${e.message}\n`));
    }
    return;
  }

  // View logs
  if (options.logs) {
    const service = options.logs;
    console.log(chalk.hex('#FF6B00').bold(`\n  📋 Logs for ${service}\n`));

    try {
      await getLogs(service, { follow: options.follow });
    } catch (e) {
      console.log(chalk.red(`\n  ❌ ${e.message}\n`));
    }
    return;
  }

  // Redeploy service
  if (options.redeploy) {
    const service = options.redeploy;
    const spinner = ora(`Redeploying ${service}...`).start();

    try {
      await redeployService(service);
      spinner.succeed(chalk.green(`✅ ${service} redeployed successfully!`));
      console.log();
    } catch (e) {
      spinner.fail(chalk.red('Redeploy failed'));
      console.log(chalk.red(`  ❌ ${e.message}\n`));
    }
    return;
  }

  // Get variables
  if (options.vars) {
    const service = options.vars;
    const spinner = ora(`Fetching variables for ${service}...`).start();

    try {
      const vars = await getVariables(service);
      spinner.stop();

      console.log(chalk.hex('#FF6B00').bold(`\n  🔐 Variables for ${service}\n`));
      console.log(vars);
      console.log();
    } catch (e) {
      spinner.fail(chalk.red('Failed to get variables'));
      console.log(chalk.red(`  ❌ ${e.message}\n`));
    }
    return;
  }

  // Open dashboard
  if (options.open) {
    console.log(chalk.hex('#FF6B00').bold('\n  🌐 Opening Railway dashboard...\n'));
    await openDashboard();
    return;
  }

  // Check whoami
  if (options.whoami) {
    const spinner = ora('Checking Railway authentication...').start();

    try {
      const result = await runRailway(['whoami']);
      spinner.stop();

      console.log(chalk.hex('#FF6B00').bold('\n  👤 Railway Account\n'));
      console.log(result.stdout);
      console.log();
    } catch (e) {
      spinner.fail(chalk.red('Not authenticated'));
      console.log(chalk.red(`  ❌ ${e.message}\n`));
      console.log(chalk.gray('  💡 Run `railway login` to authenticate\n'));
    }
    return;
  }

  // Default: show Railway overview
  console.log(chalk.hex('#FF6B00').bold('\n  🚂 Railway Management\n'));

  const table = new Table({
    head: [chalk.gray('Command'), chalk.gray('Description')],
    style: { head: [], border: ['gray'] }
  });

  table.push(
    ['--list', 'List all services'],
    ['--status <service>', 'Get service status'],
    ['--logs <service>', 'View service logs'],
    ['--redeploy <service>', 'Redeploy a service'],
    ['--vars <service>', 'View environment variables'],
    ['--open', 'Open Railway dashboard'],
    ['--whoami', 'Check authentication']
  );

  console.log(table.toString());
  console.log();

  console.log(chalk.gray('  📊 Project ID: ') + chalk.cyan(RAILWAY_PROJECT_ID));
  console.log();
}
