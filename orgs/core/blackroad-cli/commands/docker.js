import chalk from 'chalk';
import { spawn } from 'child_process';
import ora from 'ora';
import Table from 'cli-table3';
import inquirer from 'inquirer';

function runDocker(args = [], options = {}) {
  return new Promise((resolve, reject) => {
    const proc = spawn('docker', args, {
      stdio: options.inherit ? 'inherit' : 'pipe',
      ...options
    });

    if (options.inherit) {
      proc.on('close', (code) => {
        if (code === 0) {
          resolve({ success: true });
        } else {
          reject(new Error(`Command failed with code ${code}`));
        }
      });
      return;
    }

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

async function listContainers(all = false) {
  const args = ['ps', '--format', '{{json .}}'];
  if (all) args.push('-a');

  const result = await runDocker(args);
  const lines = result.stdout.trim().split('\n').filter(l => l);

  return lines.map(line => {
    try {
      return JSON.parse(line);
    } catch {
      return null;
    }
  }).filter(Boolean);
}

async function listImages() {
  const result = await runDocker(['images', '--format', '{{json .}}']);
  const lines = result.stdout.trim().split('\n').filter(l => l);

  return lines.map(line => {
    try {
      return JSON.parse(line);
    } catch {
      return null;
    }
  }).filter(Boolean);
}

async function getContainerStats() {
  const result = await runDocker(['stats', '--no-stream', '--format', '{{json .}}']);
  const lines = result.stdout.trim().split('\n').filter(l => l);

  return lines.map(line => {
    try {
      return JSON.parse(line);
    } catch {
      return null;
    }
  }).filter(Boolean);
}

export async function dockerCommand(options) {
  // List containers
  if (options.ps || options.list) {
    const spinner = ora('Fetching containers...').start();

    try {
      const containers = await listContainers(options.all);
      spinner.stop();

      if (containers.length === 0) {
        console.log(chalk.yellow('\n  No containers found.\n'));
        return;
      }

      console.log(chalk.hex('#FF6B00').bold('\n  🐳 Docker Containers\n'));

      const table = new Table({
        head: [
          chalk.gray('ID'),
          chalk.gray('Name'),
          chalk.gray('Image'),
          chalk.gray('Status'),
          chalk.gray('Ports')
        ],
        style: {
          head: [],
          border: ['gray']
        }
      });

      containers.forEach(c => {
        const status = c.State === 'running'
          ? chalk.green(`● ${c.Status}`)
          : chalk.red(`○ ${c.Status}`);

        table.push([
          chalk.cyan(c.ID.substring(0, 12)),
          c.Names,
          c.Image,
          status,
          c.Ports || '-'
        ]);
      });

      console.log(table.toString());
      console.log(chalk.gray(`\n  Total: ${containers.length} container(s)\n`));

    } catch (e) {
      spinner.fail(chalk.red('Failed to list containers'));
      console.log(chalk.red(`  ❌ ${e.message}\n`));
    }
    return;
  }

  // List images
  if (options.images) {
    const spinner = ora('Fetching images...').start();

    try {
      const images = await listImages();
      spinner.stop();

      console.log(chalk.hex('#FF6B00').bold('\n  🖼️  Docker Images\n'));

      const table = new Table({
        head: [
          chalk.gray('Repository'),
          chalk.gray('Tag'),
          chalk.gray('Image ID'),
          chalk.gray('Size')
        ],
        style: {
          head: [],
          border: ['gray']
        }
      });

      images.forEach(img => {
        table.push([
          img.Repository,
          img.Tag,
          chalk.cyan(img.ID.substring(0, 12)),
          img.Size
        ]);
      });

      console.log(table.toString());
      console.log(chalk.gray(`\n  Total: ${images.length} image(s)\n`));

    } catch (e) {
      spinner.fail(chalk.red('Failed to list images'));
      console.log(chalk.red(`  ❌ ${e.message}\n`));
    }
    return;
  }

  // Container stats
  if (options.stats) {
    const spinner = ora('Fetching container stats...').start();

    try {
      const stats = await getContainerStats();
      spinner.stop();

      console.log(chalk.hex('#FF6B00').bold('\n  📊 Container Stats\n'));

      const table = new Table({
        head: [
          chalk.gray('Name'),
          chalk.gray('CPU %'),
          chalk.gray('Memory'),
          chalk.gray('Net I/O'),
          chalk.gray('Block I/O')
        ],
        style: {
          head: [],
          border: ['gray']
        }
      });

      stats.forEach(s => {
        const cpuColor = parseFloat(s.CPUPerc) > 50 ? 'red' : 'green';

        table.push([
          s.Name,
          chalk[cpuColor](s.CPUPerc),
          s.MemUsage,
          s.NetIO,
          s.BlockIO
        ]);
      });

      console.log(table.toString());
      console.log();

    } catch (e) {
      spinner.fail(chalk.red('Failed to get stats'));
      console.log(chalk.red(`  ❌ ${e.message}\n`));
    }
    return;
  }

  // Start container
  if (options.start) {
    const container = options.start;
    const spinner = ora(`Starting ${container}...`).start();

    try {
      await runDocker(['start', container]);
      spinner.succeed(chalk.green(`✅ ${container} started`));
      console.log();
    } catch (e) {
      spinner.fail(chalk.red('Failed to start container'));
      console.log(chalk.red(`  ❌ ${e.message}\n`));
    }
    return;
  }

  // Stop container
  if (options.stop) {
    const container = options.stop;
    const spinner = ora(`Stopping ${container}...`).start();

    try {
      await runDocker(['stop', container]);
      spinner.succeed(chalk.green(`✅ ${container} stopped`));
      console.log();
    } catch (e) {
      spinner.fail(chalk.red('Failed to stop container'));
      console.log(chalk.red(`  ❌ ${e.message}\n`));
    }
    return;
  }

  // Restart container
  if (options.restart) {
    const container = options.restart;
    const spinner = ora(`Restarting ${container}...`).start();

    try {
      await runDocker(['restart', container]);
      spinner.succeed(chalk.green(`✅ ${container} restarted`));
      console.log();
    } catch (e) {
      spinner.fail(chalk.red('Failed to restart container'));
      console.log(chalk.red(`  ❌ ${e.message}\n`));
    }
    return;
  }

  // Remove container
  if (options.rm) {
    const container = options.rm;

    const { confirm } = await inquirer.prompt([
      {
        type: 'confirm',
        name: 'confirm',
        message: `Remove container ${container}?`,
        default: false
      }
    ]);

    if (!confirm) {
      console.log(chalk.yellow('\n  Cancelled.\n'));
      return;
    }

    const spinner = ora(`Removing ${container}...`).start();

    try {
      await runDocker(['rm', '-f', container]);
      spinner.succeed(chalk.green(`✅ ${container} removed`));
      console.log();
    } catch (e) {
      spinner.fail(chalk.red('Failed to remove container'));
      console.log(chalk.red(`  ❌ ${e.message}\n`));
    }
    return;
  }

  // View logs
  if (options.logs) {
    const container = options.logs;
    console.log(chalk.hex('#FF6B00').bold(`\n  📋 Logs for ${container}\n`));

    try {
      const args = ['logs'];
      if (options.follow) args.push('-f');
      if (options.tail) args.push('--tail', options.tail);
      args.push(container);

      await runDocker(args, { inherit: true });
    } catch (e) {
      console.log(chalk.red(`\n  ❌ ${e.message}\n`));
    }
    return;
  }

  // Execute command in container
  if (options.exec) {
    const [container, ...command] = options.exec.split(' ');
    console.log(chalk.hex('#FF6B00').bold(`\n  🔧 Executing in ${container}\n`));

    try {
      await runDocker(['exec', '-it', container, ...command], { inherit: true });
    } catch (e) {
      console.log(chalk.red(`\n  ❌ ${e.message}\n`));
    }
    return;
  }

  // Compose up
  if (options.up) {
    console.log(chalk.hex('#FF6B00').bold('\n  🚀 Starting Docker Compose...\n'));

    try {
      const args = ['compose', 'up'];
      if (options.detach) args.push('-d');
      await runDocker(args, { inherit: true });
      console.log(chalk.green('\n  ✅ Compose started\n'));
    } catch (e) {
      console.log(chalk.red(`\n  ❌ ${e.message}\n`));
    }
    return;
  }

  // Compose down
  if (options.down) {
    console.log(chalk.hex('#FF6B00').bold('\n  🛑 Stopping Docker Compose...\n'));

    try {
      await runDocker(['compose', 'down'], { inherit: true });
      console.log(chalk.green('\n  ✅ Compose stopped\n'));
    } catch (e) {
      console.log(chalk.red(`\n  ❌ ${e.message}\n`));
    }
    return;
  }

  // Prune
  if (options.prune) {
    const { confirm } = await inquirer.prompt([
      {
        type: 'confirm',
        name: 'confirm',
        message: 'Prune unused containers, networks, and images?',
        default: false
      }
    ]);

    if (!confirm) {
      console.log(chalk.yellow('\n  Cancelled.\n'));
      return;
    }

    const spinner = ora('Pruning Docker resources...').start();

    try {
      await runDocker(['system', 'prune', '-f']);
      spinner.succeed(chalk.green('✅ Pruning complete'));
      console.log();
    } catch (e) {
      spinner.fail(chalk.red('Prune failed'));
      console.log(chalk.red(`  ❌ ${e.message}\n`));
    }
    return;
  }

  // Default: show quick stats
  console.log(chalk.hex('#FF6B00').bold('\n  🐳 Docker Quick Stats\n'));

  try {
    const [containers, images] = await Promise.all([
      listContainers(true),
      listImages()
    ]);

    const running = containers.filter(c => c.State === 'running').length;
    const stopped = containers.filter(c => c.State !== 'running').length;

    const table = new Table({
      head: [chalk.gray('Resource'), chalk.gray('Count')],
      style: { head: [], border: ['gray'] }
    });

    table.push(
      ['Running Containers', chalk.green(running.toString())],
      ['Stopped Containers', chalk.yellow(stopped.toString())],
      ['Total Images', chalk.cyan(images.length.toString())]
    );

    console.log(table.toString());
    console.log();

    console.log(chalk.gray('  💡 Commands:'));
    console.log(chalk.gray('    br docker --ps              List containers'));
    console.log(chalk.gray('    br docker --images          List images'));
    console.log(chalk.gray('    br docker --stats           Container stats'));
    console.log(chalk.gray('    br docker --logs <name>     View logs'));
    console.log(chalk.gray('    br docker --start <name>    Start container'));
    console.log(chalk.gray('    br docker --up              Compose up'));
    console.log();

  } catch (e) {
    console.log(chalk.red(`  ❌ ${e.message}\n`));
  }
}
