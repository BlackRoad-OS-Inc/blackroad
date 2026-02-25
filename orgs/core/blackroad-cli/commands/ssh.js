import chalk from 'chalk';
import inquirer from 'inquirer';
import { spawn } from 'child_process';
import ora from 'ora';

// Infrastructure hosts
const hosts = {
  servers: [
    {
      name: 'Codex Infinity (DigitalOcean)',
      host: '159.65.43.12',
      users: ['root', 'alexa'],
      description: 'Main cloud server'
    }
  ],
  raspberry_pi: [
    {
      name: 'Lucidia',
      host: '192.168.4.38',
      users: ['pi', 'alexa', 'alice', 'ubuntu'],
      description: 'Primary Raspberry Pi node'
    },
    {
      name: 'BlackRoad Pi',
      host: '192.168.4.64',
      users: ['pi', 'alexa', 'alice', 'ubuntu'],
      description: 'Secondary Raspberry Pi node'
    },
    {
      name: 'Lucidia Alternate',
      host: '192.168.4.99',
      users: ['pi', 'alexa', 'alice', 'ubuntu'],
      description: 'Backup Raspberry Pi node'
    }
  ],
  devices: [
    {
      name: 'iPhone Koder',
      host: '192.168.4.68:8080',
      users: ['mobile'],
      description: 'Mobile development device'
    }
  ]
};

function getAllHosts() {
  return [
    ...hosts.servers,
    ...hosts.raspberry_pi,
    ...hosts.devices
  ];
}

function sshConnect(host, user, options = {}) {
  return new Promise((resolve, reject) => {
    const args = [];

    if (options.port) {
      args.push('-p', options.port);
    }

    args.push(`${user}@${host}`);

    if (options.command) {
      args.push(options.command);
    }

    console.log(chalk.gray(`\n  🔌 Connecting to ${user}@${host}...\n`));

    const proc = spawn('ssh', args, {
      stdio: 'inherit',
      shell: true
    });

    proc.on('close', (code) => {
      if (code === 0) {
        resolve({ success: true });
      } else {
        reject(new Error(`SSH connection failed with code ${code}`));
      }
    });

    proc.on('error', (err) => {
      reject(err);
    });
  });
}

async function testConnection(host, user) {
  return new Promise((resolve) => {
    const proc = spawn('timeout', ['3', 'ssh', '-o', 'ConnectTimeout=3', '-o', 'BatchMode=yes', `${user}@${host}`, 'echo connected'], {
      stdio: 'pipe'
    });

    let output = '';
    proc.stdout?.on('data', (data) => output += data.toString());

    proc.on('close', (code) => {
      resolve({
        success: code === 0,
        reachable: output.includes('connected')
      });
    });

    proc.on('error', () => {
      resolve({ success: false, reachable: false });
    });
  });
}

export async function sshCommand(target, options) {
  const allHosts = getAllHosts();

  // List all hosts
  if (options.list) {
    console.log(chalk.hex('#FF6B00').bold('\n  🌐 Infrastructure Hosts\n'));

    console.log(chalk.cyan('  📡 Cloud Servers:'));
    hosts.servers.forEach(h => {
      console.log(`    ${chalk.green('•')} ${h.name} - ${chalk.gray(h.host)}`);
      console.log(`      ${chalk.gray(h.description)}`);
    });

    console.log(chalk.cyan('\n  🥧 Raspberry Pi Nodes:'));
    hosts.raspberry_pi.forEach(h => {
      console.log(`    ${chalk.green('•')} ${h.name} - ${chalk.gray(h.host)}`);
      console.log(`      ${chalk.gray(h.description)}`);
    });

    console.log(chalk.cyan('\n  📱 Devices:'));
    hosts.devices.forEach(h => {
      console.log(`    ${chalk.green('•')} ${h.name} - ${chalk.gray(h.host)}`);
      console.log(`      ${chalk.gray(h.description)}`);
    });

    console.log();
    return;
  }

  // Test connections
  if (options.test) {
    console.log(chalk.hex('#FF6B00').bold('\n  🔍 Testing SSH connections...\n'));

    for (const host of allHosts) {
      const spinner = ora(`Testing ${host.name}...`).start();

      let connected = false;
      for (const user of host.users) {
        const result = await testConnection(host.host, user);
        if (result.success && result.reachable) {
          spinner.succeed(chalk.green(`✅ ${host.name} (${user}@${host.host})`));
          connected = true;
          break;
        }
      }

      if (!connected) {
        spinner.fail(chalk.red(`❌ ${host.name} (${host.host}) - unreachable`));
      }
    }

    console.log();
    return;
  }

  // Interactive selection
  if (!target) {
    const { selected } = await inquirer.prompt([
      {
        type: 'list',
        name: 'selected',
        message: 'Select a host to connect to:',
        choices: allHosts.map(h => ({
          name: `${h.name} (${h.host})`,
          value: h
        }))
      }
    ]);

    const { user } = await inquirer.prompt([
      {
        type: 'list',
        name: 'user',
        message: 'Select user:',
        choices: selected.users
      }
    ]);

    try {
      await sshConnect(selected.host, user, options);
    } catch (e) {
      console.log(chalk.red(`\n  ❌ SSH failed: ${e.message}\n`));
    }
    return;
  }

  // Connect to specified target
  const host = allHosts.find(h =>
    h.name.toLowerCase().includes(target.toLowerCase()) ||
    h.host.includes(target)
  );

  if (!host) {
    console.log(chalk.red(`\n  ❌ Host "${target}" not found.\n`));
    console.log(chalk.gray('  Run `br ssh --list` to see all hosts.\n'));
    return;
  }

  const user = options.user || host.users[0];

  try {
    await sshConnect(host.host, user, {
      port: options.port,
      command: options.command
    });
  } catch (e) {
    console.log(chalk.red(`\n  ❌ SSH failed: ${e.message}\n`));
  }
}
