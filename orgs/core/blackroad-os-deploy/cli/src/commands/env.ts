import { Command } from 'commander';
import chalk from 'chalk';
import inquirer from 'inquirer';
import { getApiClient } from '../api';

const envSetCommand = new Command('set')
  .description('Set environment variable')
  .argument('<name>', 'Deployment name')
  .argument('<keyvalue>', 'KEY=value')
  .action(async (name, keyvalue) => {
    try {
      const [key, ...valueParts] = keyvalue.split('=');
      const value = valueParts.join('=');

      if (!key || value === undefined) {
        console.error(chalk.red('Invalid format. Use: KEY=value'));
        process.exit(1);
      }

      const api = await getApiClient();
      await api.post(`/api/env/${name}`, { key, value });

      console.log(chalk.green(`✓ Set ${key} for ${name}`));
      console.log(chalk.dim('Restart deployment to apply changes: blackroad restart ' + name));
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

const envGetCommand = new Command('get')
  .description('Get environment variables')
  .argument('<name>', 'Deployment name')
  .action(async (name) => {
    try {
      const api = await getApiClient();
      const response = await api.get(`/api/env/${name}`);

      const env = response.data.env;
      const keys = Object.keys(env);

      if (keys.length === 0) {
        console.log(chalk.dim('No environment variables set'));
        return;
      }

      console.log(chalk.bold(`\nEnvironment variables for ${name}:\n`));
      for (const key of keys) {
        console.log(chalk.dim(key + ':'), env[key]);
      }
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

const envDeleteCommand = new Command('delete')
  .alias('rm')
  .description('Delete environment variable')
  .argument('<name>', 'Deployment name')
  .argument('<key>', 'Variable key')
  .action(async (name, key) => {
    try {
      const { confirm } = await inquirer.prompt([
        {
          type: 'confirm',
          name: 'confirm',
          message: `Delete ${key} from ${name}?`,
          default: false,
        },
      ]);

      if (!confirm) {
        console.log(chalk.dim('Cancelled'));
        return;
      }

      const api = await getApiClient();
      await api.delete(`/api/env/${name}/${key}`);

      console.log(chalk.green(`✓ Deleted ${key} from ${name}`));
    } catch (err: any) {
      if (err.response?.status === 404) {
        console.error(chalk.red(`Deployment '${name}' or variable '${key}' not found`));
      } else if (err.response?.data?.error) {
        console.error(chalk.red(err.response.data.error));
      } else {
        console.error(chalk.red('Error:'), err.message);
      }
      process.exit(1);
    }
  });

export const envCommand = new Command('env')
  .description('Manage environment variables')
  .addCommand(envSetCommand)
  .addCommand(envGetCommand)
  .addCommand(envDeleteCommand);
