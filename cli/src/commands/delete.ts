import { Command } from 'commander';
import chalk from 'chalk';
import inquirer from 'inquirer';
import ora from 'ora';
import { getApiClient } from '../api';

export const deleteCommand = new Command('delete')
  .alias('rm')
  .description('Delete a deployment')
  .argument('<name>', 'Deployment name')
  .option('-f, --force', 'Skip confirmation')
  .action(async (name, options) => {
    try {
      if (!options.force) {
        const { confirm } = await inquirer.prompt([
          {
            type: 'confirm',
            name: 'confirm',
            message: `Delete deployment '${name}'? This cannot be undone.`,
            default: false,
          },
        ]);

        if (!confirm) {
          console.log(chalk.dim('Cancelled'));
          return;
        }
      }

      const api = await getApiClient();
      const spinner = ora('Deleting deployment...').start();

      await api.delete(`/api/deployments/${name}`);

      spinner.succeed(chalk.green(`Deployment '${name}' deleted successfully`));
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
