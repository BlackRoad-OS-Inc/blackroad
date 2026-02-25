import chalk from 'chalk';
import { spawn } from 'child_process';
import ora from 'ora';
import Table from 'cli-table3';

// Network infrastructure
const network = {
  external: [
    { name: 'Codex Infinity', ip: '159.65.43.12', type: 'DigitalOcean Droplet' }
  ],
  internal: [
    { name: 'Lucidia', ip: '192.168.4.38', type: 'Raspberry Pi' },
    { name: 'BlackRoad Pi', ip: '192.168.4.64', type: 'Raspberry Pi' },
    { name: 'Lucidia Alternate', ip: '192.168.4.99', type: 'Raspberry Pi' },
    { name: 'iPhone Koder', ip: '192.168.4.68', type: 'Mobile Device', port: 8080 }
  ],
  services: [
    { name: 'blackroad.io', url: 'blackroad.io', type: 'Cloudflare Pages' },
    { name: 'app.blackroad.io', url: 'app.blackroad.io', type: 'Cloudflare Pages' },
    { name: 'api.blackroad.io', url: 'api.blackroad.io', type: 'Railway' },
    { name: 'headscale', url: 'headscale.blackroad.io', type: 'VPN Mesh' }
  ]
};

function ping(host, count = 4) {
  return new Promise((resolve) => {
    const proc = spawn('ping', ['-c', count.toString(), host], {
      stdio: 'pipe'
    });

    let output = '';
    proc.stdout?.on('data', (data) => output += data.toString());

    proc.on('close', (code) => {
      const success = code === 0;
      let avgTime = null;

      if (success) {
        const match = output.match(/avg = ([\d.]+)/);
        if (match) {
          avgTime = parseFloat(match[1]);
        }
      }

      resolve({ success, avgTime, output });
    });

    proc.on('error', () => {
      resolve({ success: false, avgTime: null, output: '' });
    });
  });
}

function portCheck(host, port) {
  return new Promise((resolve) => {
    const proc = spawn('nc', ['-zv', host, port.toString()], {
      stdio: 'pipe'
    });

    let stderr = '';
    proc.stderr?.on('data', (data) => stderr += data.toString());

    proc.on('close', (code) => {
      resolve({
        open: code === 0,
        message: stderr
      });
    });

    proc.on('error', () => {
      resolve({ open: false, message: 'nc command failed' });
    });
  });
}

async function checkHost(host) {
  const result = await ping(host.ip || host.url, 2);

  return {
    ...host,
    reachable: result.success,
    latency: result.avgTime
  };
}

export async function networkCommand(options) {
  // Scan network
  if (options.scan) {
    console.log(chalk.hex('#FF6B00').bold('\n  🔍 Scanning BlackRoad network...\n'));

    const allHosts = [...network.external, ...network.internal];

    for (const host of allHosts) {
      const spinner = ora(`Pinging ${host.name}...`).start();

      const result = await checkHost(host);

      if (result.reachable) {
        spinner.succeed(chalk.green(`✅ ${host.name} (${host.ip}) - ${result.latency?.toFixed(1)}ms`));
      } else {
        spinner.fail(chalk.red(`❌ ${host.name} (${host.ip}) - unreachable`));
      }
    }

    console.log();
    return;
  }

  // Port scan
  if (options.ports) {
    const target = options.ports;
    const commonPorts = [22, 80, 443, 8080, 3000, 5000];

    console.log(chalk.hex('#FF6B00').bold(`\n  🔍 Scanning ports on ${target}...\n`));

    for (const port of commonPorts) {
      const spinner = ora(`Checking port ${port}...`).start();

      const result = await portCheck(target, port);

      if (result.open) {
        spinner.succeed(chalk.green(`✅ Port ${port} - open`));
      } else {
        spinner.fail(chalk.gray(`❌ Port ${port} - closed`));
      }
    }

    console.log();
    return;
  }

  // Trace route
  if (options.trace) {
    const target = options.trace;
    console.log(chalk.hex('#FF6B00').bold(`\n  🗺️  Tracing route to ${target}...\n`));

    const proc = spawn('traceroute', [target], {
      stdio: 'inherit'
    });

    proc.on('error', (err) => {
      console.log(chalk.red(`\n  ❌ Traceroute failed: ${err.message}\n`));
    });

    return;
  }

  // Show network map
  console.log(chalk.hex('#FF6B00').bold('\n  🌐 BlackRoad Network Map\n'));

  console.log(chalk.cyan('  ☁️  External Servers:'));
  const externalTable = new Table({
    head: [chalk.gray('Name'), chalk.gray('IP'), chalk.gray('Type')],
    style: { head: [], border: ['gray'] }
  });

  network.external.forEach(h => {
    externalTable.push([h.name, chalk.cyan(h.ip), h.type]);
  });

  console.log(externalTable.toString());

  console.log(chalk.cyan('\n  🏠 Internal Network:'));
  const internalTable = new Table({
    head: [chalk.gray('Name'), chalk.gray('IP'), chalk.gray('Type')],
    style: { head: [], border: ['gray'] }
  });

  network.internal.forEach(h => {
    internalTable.push([
      h.name,
      chalk.cyan(h.port ? `${h.ip}:${h.port}` : h.ip),
      h.type
    ]);
  });

  console.log(internalTable.toString());

  console.log(chalk.cyan('\n  🌍 Services:'));
  const servicesTable = new Table({
    head: [chalk.gray('Name'), chalk.gray('URL'), chalk.gray('Type')],
    style: { head: [], border: ['gray'] }
  });

  network.services.forEach(s => {
    servicesTable.push([s.name, chalk.cyan(s.url), s.type]);
  });

  console.log(servicesTable.toString());

  console.log(chalk.gray('\n  💡 Commands:'));
  console.log(chalk.gray('    br network --scan              Ping all hosts'));
  console.log(chalk.gray('    br network --ports <host>      Scan common ports'));
  console.log(chalk.gray('    br network --trace <host>      Trace route to host'));
  console.log();
}
