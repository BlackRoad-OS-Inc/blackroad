import { Command } from 'commander';
import chalk from 'chalk';
import { getApiClient } from '../api';

export const listCommand = new Command('list')
  .alias('ls')
  .description('List all deployments')
  .action(async () => {
    try {
      const api = await getApiClient();
      const response = await api.get('/api/deployments');

      const deployments = response.data.deployments;

      if (deployments.length === 0) {
        console.log(chalk.dim('No deployments found'));
        console.log(chalk.dim('\nRun: blackroad deploy'));
        return;
      }

      console.log(chalk.bold(`\n${deployments.length} deployment${deployments.length === 1 ? '' : 's'}:\n`));

      for (const dep of deployments) {
        const statusColor =
          dep.status === 'running' ? chalk.green :
          dep.status === 'stopped' ? chalk.yellow :
          chalk.red;

        console.log(chalk.bold(dep.name));
        console.log(chalk.dim('  Status:'), statusColor(dep.status));
        console.log(chalk.dim('  Image:'), dep.image);
        console.log(chalk.dim('  Port:'), dep.port || 'N/A');
        console.log(chalk.dim('  Created:'), new Date(dep.created_at).toLocaleString());
        console.log();
      }
    } catch (err: any) {
      if (err.response?.data?.error) {
        console.error(chalk.red(err.response.data.error));
      } else {
        console.error(chalk.red('Error:'), err.message);
      }
      process.exit(1);
    }
  });
