#!/usr/bin/env node

/**
 * BlackRoad Deploy CLI
 *
 * Command-line tool for instant deployments
 *
 * Usage:
 *   br deploy                          - Deploy current directory
 *   br deploy --domain api.blackroad.io --target pi-lucidia
 *   br list                            - List all deployments
 *   br logs <name>                     - View logs for deployment
 *   br domain update <domain> --target <server>
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');
const yaml = require('js-yaml');

const command = process.argv[2];
const args = process.argv.slice(3);

// Parse CLI flags
function parseFlags(args) {
  const flags = {};
  for (let i = 0; i < args.length; i++) {
    if (args[i].startsWith('--')) {
      const key = args[i].substring(2);
      flags[key] = args[i + 1] || true;
      i++;
    }
  }
  return flags;
}

// Deploy command
async function deploy() {
  const flags = parseFlags(args);
  const projectDir = process.cwd();

  console.log('\nBlackRoad Deploy');
  console.log('================\n');

  // Read or create deploy.yaml
  const deployConfigPath = path.join(projectDir, 'deploy.yaml');
  let config = {};

  if (fs.existsSync(deployConfigPath)) {
    console.log('Reading deploy.yaml...');
    config = yaml.load(fs.readFileSync(deployConfigPath, 'utf8'));
  } else {
    console.log('No deploy.yaml found, creating one...');
    config = {
      domain: flags.domain || path.basename(projectDir) + '.blackroad.io',
      target: flags.target || 'droplet',
      port: flags.port || 3000,
    };
    fs.writeFileSync(deployConfigPath, yaml.dump(config));
  }

  // Override with CLI flags
  if (flags.domain) config.domain = flags.domain;
  if (flags.target) config.target = flags.target;
  if (flags.port) config.port = parseInt(flags.port);

  console.log('Domain: ' + config.domain);
  console.log('Target: ' + config.target);
  console.log('Port: ' + config.port);

  // Detect language
  console.log('\nDetecting language...');
  const LanguageDetector = require('../orchestrator/detector');
  const detector = new LanguageDetector(projectDir);
  const detection = detector.detect();
  console.log('Language: ' + detection.language);
  console.log('Framework: ' + detection.framework);

  // Build Docker image
  console.log('\nBuilding Docker image...');
  const imageName = 'blackroad/' + path.basename(projectDir) + ':latest';
  const Builder = require('../orchestrator/builder');
  const builder = new Builder(projectDir, { ...config, ...detection });
  await builder.build();
  console.log('Built: ' + imageName);

  // Deploy
  console.log('\nDeploying...');
  const Deployer = require('../orchestrator/deployer');
  const deployer = new Deployer({ ...config, name: path.basename(projectDir) });
  await deployer.deploy(imageName);

  console.log('\nDeployment complete!');
  console.log('Live at: https://' + config.domain + '\n');
}

// List deployments
function list() {
  const targets = ['droplet', 'pi-lucidia', 'pi-blackroad', 'pi-lucidia-alt'];
  const targetHosts = {
    droplet: '159.65.43.12',
    'pi-lucidia': '192.168.4.38',
    'pi-blackroad': '192.168.4.64',
    'pi-lucidia-alt': '192.168.4.99',
  };

  console.log('\nActive Deployments');
  console.log('==================\n');

  for (const target of targets) {
    console.log(target.toUpperCase() + ' (' + targetHosts[target] + ')');
    try {
      const result = execSync(`ssh root@${targetHosts[target]} "docker ps --format 'table {{.Names}}\\t{{.Status}}\\t{{.Ports}}'"`, {
        encoding: 'utf8',
      });
      console.log(result);
    } catch (error) {
      console.log('  Unable to connect\n');
    }
  }
}

// View logs
function logs() {
  const name = args[0];
  const flags = parseFlags(args);

  if (!name) {
    console.error('Usage: br logs <deployment-name>');
    process.exit(1);
  }

  console.log('Fetching logs for: ' + name + '\n');

  // Try all targets
  const targets = {
    droplet: '159.65.43.12',
    'pi-lucidia': '192.168.4.38',
    'pi-blackroad': '192.168.4.64',
    'pi-lucidia-alt': '192.168.4.99',
  };

  for (const [targetName, host] of Object.entries(targets)) {
    try {
      const followFlag = flags.f || flags.follow ? '-f' : '';
      const linesFlag = flags.n ? '--tail ' + flags.n : '--tail 100';
      execSync(`ssh root@${host} "docker logs ${followFlag} ${linesFlag} ${name}"`, {
        stdio: 'inherit',
      });
      return;
    } catch (error) {
      // Try next target
    }
  }

  console.error('Deployment not found: ' + name);
  process.exit(1);
}

// Domain update
function domainUpdate() {
  const domain = args[1];
  const flags = parseFlags(args);

  if (!domain || !flags.target) {
    console.error('Usage: br domain update <domain> --target <server>');
    process.exit(1);
  }

  console.log('Updating DNS...');
  console.log('Domain: ' + domain);
  console.log('Target: ' + flags.target);
  console.log('\nNote: DNS updates require manual Cloudflare API setup');
  console.log('See documentation for details\n');
}

// Help
function help() {
  console.log(`
BlackRoad Deploy CLI

Usage:
  br deploy [options]              Deploy current directory
  br list                          List all deployments
  br logs <name> [options]         View deployment logs
  br domain update <domain> --target <server>

Deploy Options:
  --domain <domain>                Custom domain
  --target <server>                Target server (droplet, pi-lucidia, pi-blackroad, pi-lucidia-alt)
  --port <port>                    Application port

Logs Options:
  -f, --follow                     Follow logs
  -n <number>                      Number of lines to show

Examples:
  br deploy
  br deploy --domain api.blackroad.io --target pi-lucidia --port 8080
  br list
  br logs my-app -f
  br domain update api.blackroad.io --target droplet

Documentation: https://github.com/BlackRoad-OS/blackroad-deploy
`);
}

// Main router
async function main() {
  try {
    if (command === 'deploy') {
      await deploy();
    } else if (command === 'list' || command === 'ls') {
      list();
    } else if (command === 'logs') {
      logs();
    } else if (command === 'domain' && args[0] === 'update') {
      domainUpdate();
    } else if (command === 'help' || !command) {
      help();
    } else {
      console.error('Unknown command: ' + command);
      help();
      process.exit(1);
    }
  } catch (error) {
    console.error('\nError: ' + error.message);
    process.exit(1);
  }
}

main();
