import chalk from 'chalk';
import inquirer from 'inquirer';
import { spawn } from 'child_process';
import { getRailwayServices, getServiceBySlug } from '../lib/services.js';

export async function logsCommand(serviceName, options) {
  const railwayServices = getRailwayServices();

  // Interactive service selection
  if (!serviceName) {
    const { selected } = await inquirer.prompt([
      {
        type: 'list',
        name: 'selected',
        message: 'Select a service to view logs:',
        choices: railwayServices.map(s => ({
          name: `${s.name} (${s.url})`,
          value: s.slug
        }))
      }
    ]);
    serviceName = selected;
  }

  const service = getServiceBySlug(serviceName);

  if (!service) {
    console.log(chalk.red(`\n  Service "${serviceName}" not found.\n`));
    console.log(chalk.gray('  Available services:'));
    railwayServices.forEach(s => {
      console.log(chalk.gray(`    - ${s.slug}`));
    });
    return;
  }

  if (!service.railway) {
    console.log(chalk.yellow(`\n  "${service.name}" is hosted on Cloudflare Pages.`));
    console.log(chalk.gray('  View logs at: https://dash.cloudflare.com\n'));
    return;
  }

  console.log(chalk.hex('#FF6B00').bold(`\n  Fetching logs for ${service.name}...\n`));

  const args = ['logs', '--service', service.slug];
  if (options.follow) args.push('--follow');
  if (options.lines) args.push('--lines', options.lines);

  const proc = spawn('railway', args, {
    stdio: 'inherit'
  });

  proc.on('error', (err) => {
    console.log(chalk.red(`\n  Error: ${err.message}`));
    console.log(chalk.gray('  Make sure Railway CLI is installed and you are logged in.\n'));
  });
}
