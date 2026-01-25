import { Command } from 'commander';
import chalk from 'chalk';
import ora from 'ora';
import { getApiClient } from '../api';

export const restartCommand = new Command('restart')
  .description('Restart a deployment')
  .argument('<name>', 'Deployment name')
  .action(async (name) => {
    try {
      const api = await getApiClient();
      const spinner = ora('Restarting deployment...').start();

      await api.post(`/api/deployments/${name}/restart`);

      spinner.succeed(chalk.green(`Deployment '${name}' restarted successfully`));
    } catch (err: any) {
      if (err.response?.status === 404) {
        console.error(chalk.red(`Deployment '${name}' not found`));
      } else if (err.response?.data?.error) {
        console.error(chalk.red(err.response.data.error));
      } else {
        console.error(chalk.red('Error:'), err.message);
      }
      process.exit(1);
    }
  });
