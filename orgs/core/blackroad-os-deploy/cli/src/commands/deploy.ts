import { Command } from 'commander';
import fs from 'fs-extra';
import path from 'path';
import chalk from 'chalk';
import ora from 'ora';
import { getApiClient } from '../api';
import { exec } from 'child_process';
import { promisify } from 'util';

const execAsync = promisify(exec);

export const deployCommand = new Command('deploy')
  .description('Deploy your application')
  .option('-n, --name <name>', 'Deployment name')
  .option('-i, --image <image>', 'Docker image to deploy')
  .action(async (options) => {
    try {
      const cwd = process.cwd();
      const configPath = path.join(cwd, 'blackroad.json');

      let config: any = {};

      // Load config if exists
      if (await fs.pathExists(configPath)) {
        config = await fs.readJson(configPath);
      }

      const name = options.name || config.name;
      let image = options.image;

      if (!name) {
        console.error(chalk.red('Error: Deployment name required'));
        console.log(chalk.dim('Run: blackroad init'));
        process.exit(1);
      }

      const api = await getApiClient();
      const spinner = ora();

      // If no image provided, build Docker image
      if (!image) {
        const dockerfilePath = path.join(cwd, 'Dockerfile');

        if (!(await fs.pathExists(dockerfilePath))) {
          console.error(chalk.red('Error: No Dockerfile found'));
          console.log(chalk.dim('Create a Dockerfile or provide --image'));
          process.exit(1);
        }

        image = `ghcr.io/blackroad/${name}:latest`;

        spinner.start('Building Docker image...');
        try {
          await execAsync(`docker build -t ${image} .`);
          spinner.succeed('Docker image built');
        } catch (err: any) {
          spinner.fail('Docker build failed');
          console.error(chalk.red(err.message));
          process.exit(1);
        }

        spinner.start('Pushing image to registry...');
        try {
          await execAsync(`docker push ${image}`);
          spinner.succeed('Image pushed');
        } catch (err: any) {
          spinner.fail('Docker push failed');
          console.error(chalk.red(err.message));
          console.log(chalk.dim('Make sure you are logged in: docker login ghcr.io'));
          process.exit(1);
        }
      }

      spinner.start('Deploying...');

      try {
        const response = await api.post('/api/deployments', {
          name,
          image,
          env: config.env || {},
          port: config.port || 3000,
        });

        spinner.succeed(chalk.green('Deployment successful!'));
        console.log(chalk.bold('\nDeployment Details:'));
        console.log(chalk.dim('Name:'), response.data.deployment.name);
        console.log(chalk.dim('Image:'), response.data.deployment.image);
        console.log(chalk.dim('Status:'), response.data.deployment.status);
        console.log(chalk.dim('URL:'), chalk.cyan(`https://${response.data.domain}`));

        console.log(chalk.dim('\nNext steps:'));
        console.log(chalk.dim('  • View logs: blackroad logs ' + name));
        console.log(chalk.dim('  • Set env vars: blackroad env set ' + name + ' KEY=value'));
      } catch (err: any) {
        spinner.fail(chalk.red('Deployment failed'));
        if (err.response?.data?.error) {
          console.error(chalk.red(err.response.data.error));
        } else {
          console.error(chalk.red(err.message));
        }
        process.exit(1);
      }
    } catch (err: any) {
      console.error(chalk.red('Error:'), err.message);
      process.exit(1);
    }
  });
