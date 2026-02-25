import chalk from 'chalk';
import { spawn } from 'child_process';
import ora from 'ora';
import Table from 'cli-table3';

const CLOUDFLARE_CONFIG = {
  tunnel_id: '72f1d60c-dcf2-4499-b02d-d7a063018b33',
  zone_id: '848cf0b18d51e0170e0d1537aec3505a',
  token: 'yP5h0HvsXX0BpHLs01tLmgtTbQurIKPL4YnQfIwy'
};

function runCommand(cmd, args = []) {
  return new Promise((resolve, reject) => {
    const proc = spawn(cmd, args, {
      stdio: 'pipe',
      env: {
        ...process.env,
        CF_TOKEN: CLOUDFLARE_CONFIG.token,
        CF_ZONE: CLOUDFLARE_CONFIG.zone_id,
        TUNNEL_ID: CLOUDFLARE_CONFIG.tunnel_id
      }
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

async function listTunnels() {
  try {
    const result = await runCommand('cloudflared', ['tunnel', 'list']);
    return result.stdout;
  } catch (e) {
    throw new Error(`Failed to list tunnels: ${e.message}`);
  }
}

async function tunnelInfo() {
  try {
    const result = await runCommand('cloudflared', ['tunnel', 'info', CLOUDFLARE_CONFIG.tunnel_id]);
    return result.stdout;
  } catch (e) {
    throw new Error(`Failed to get tunnel info: ${e.message}`);
  }
}

async function createDNSRecord(subdomain, fullDomain) {
  try {
    console.log(chalk.gray(`  📝 Adding DNS record for ${fullDomain}...`));
    const result = await runCommand('cloudflared', [
      'tunnel', 'route', 'dns',
      CLOUDFLARE_CONFIG.tunnel_id,
      fullDomain
    ]);
    return result;
  } catch (e) {
    throw new Error(`Failed to create DNS record: ${e.message}`);
  }
}

async function startTunnel(configPath) {
  console.log(chalk.hex('#FF6B00').bold('\n  🚇 Starting Cloudflare Tunnel...\n'));

  const args = ['tunnel', 'run'];
  if (configPath) {
    args.push('--config', configPath);
  }
  args.push(CLOUDFLARE_CONFIG.tunnel_id);

  const proc = spawn('cloudflared', args, {
    stdio: 'inherit',
    env: {
      ...process.env,
      CF_TOKEN: CLOUDFLARE_CONFIG.token
    }
  });

  proc.on('error', (err) => {
    console.log(chalk.red(`\n  ❌ Failed to start tunnel: ${err.message}\n`));
  });
}

export async function tunnelCommand(options) {
  // List tunnels
  if (options.list) {
    const spinner = ora('Fetching Cloudflare tunnels...').start();

    try {
      const output = await listTunnels();
      spinner.stop();

      console.log(chalk.hex('#FF6B00').bold('\n  🚇 Cloudflare Tunnels\n'));
      console.log(output);
      console.log();
    } catch (e) {
      spinner.fail(chalk.red('Failed to list tunnels'));
      console.log(chalk.red(`  ❌ ${e.message}\n`));
    }
    return;
  }

  // Show tunnel info
  if (options.info) {
    const spinner = ora('Fetching tunnel information...').start();

    try {
      const output = await tunnelInfo();
      spinner.stop();

      console.log(chalk.hex('#FF6B00').bold('\n  📊 Tunnel Information\n'));
      console.log(chalk.gray(`  Tunnel ID: ${CLOUDFLARE_CONFIG.tunnel_id}`));
      console.log();
      console.log(output);
      console.log();
    } catch (e) {
      spinner.fail(chalk.red('Failed to get tunnel info'));
      console.log(chalk.red(`  ❌ ${e.message}\n`));
    }
    return;
  }

  // Create DNS record
  if (options.dns) {
    const subdomain = options.dns;
    const fullDomain = `${subdomain}.blackroad.io`;

    const spinner = ora(`Creating DNS record for ${fullDomain}...`).start();

    try {
      await createDNSRecord(subdomain, fullDomain);
      spinner.succeed(chalk.green(`✅ DNS record created for ${fullDomain}`));
      console.log(chalk.gray(`\n  🌐 Your service will be available at: https://${fullDomain}\n`));
    } catch (e) {
      spinner.fail(chalk.red('Failed to create DNS record'));
      console.log(chalk.red(`  ❌ ${e.message}\n`));
    }
    return;
  }

  // Start tunnel
  if (options.start) {
    await startTunnel(options.config);
    return;
  }

  // Show status
  const spinner = ora('Checking tunnel status...').start();

  try {
    const output = await tunnelInfo();
    spinner.succeed(chalk.green('Tunnel is configured'));

    console.log(chalk.hex('#FF6B00').bold('\n  🚇 Cloudflare Tunnel Status\n'));

    const table = new Table({
      head: [chalk.gray('Property'), chalk.gray('Value')],
      style: {
        head: [],
        border: ['gray']
      }
    });

    table.push(
      ['Tunnel ID', chalk.cyan(CLOUDFLARE_CONFIG.tunnel_id)],
      ['Zone ID', chalk.cyan(CLOUDFLARE_CONFIG.zone_id)],
      ['Status', chalk.green('✅ Configured')]
    );

    console.log(table.toString());
    console.log();

    console.log(chalk.gray('  💡 Commands:'));
    console.log(chalk.gray('    br tunnel --start          Start the tunnel'));
    console.log(chalk.gray('    br tunnel --list           List all tunnels'));
    console.log(chalk.gray('    br tunnel --dns <subdomain>  Create DNS record'));
    console.log();

  } catch (e) {
    spinner.fail(chalk.red('Tunnel check failed'));
    console.log(chalk.red(`  ❌ ${e.message}\n`));
  }
}
