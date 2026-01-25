import { Command } from 'commander';
import fs from 'fs-extra';
import path from 'path';
import chalk from 'chalk';
import inquirer from 'inquirer';

export const initCommand = new Command('init')
  .description('Initialize a new BlackRoad Deploy project')
  .action(async () => {
    try {
      const cwd = process.cwd();
      const configPath = path.join(cwd, 'blackroad.json');

      if (await fs.pathExists(configPath)) {
        console.log(chalk.yellow('blackroad.json already exists'));
        const { overwrite } = await inquirer.prompt([
          {
            type: 'confirm',
            name: 'overwrite',
            message: 'Overwrite existing config?',
            default: false,
          },
        ]);

        if (!overwrite) {
          console.log(chalk.dim('Cancelled'));
          return;
        }
      }

      const packageJsonPath = path.join(cwd, 'package.json');
      let defaultName = path.basename(cwd);

      if (await fs.pathExists(packageJsonPath)) {
        const packageJson = await fs.readJson(packageJsonPath);
        defaultName = packageJson.name || defaultName;
      }

      const answers = await inquirer.prompt([
        {
          type: 'input',
          name: 'name',
          message: 'Deployment name:',
          default: defaultName,
          validate: (input) =>
            /^[a-z0-9-]+$/.test(input) || 'Name must be lowercase alphanumeric with dashes',
        },
        {
          type: 'input',
          name: 'buildCommand',
          message: 'Build command:',
          default: 'npm run build',
        },
        {
          type: 'input',
          name: 'startCommand',
          message: 'Start command:',
          default: 'npm start',
        },
        {
          type: 'number',
          name: 'port',
          message: 'Port:',
          default: 3000,
        },
      ]);

      const config = {
        name: answers.name,
        buildCommand: answers.buildCommand,
        startCommand: answers.startCommand,
        port: answers.port,
        env: {},
      };

      await fs.writeJson(configPath, config, { spaces: 2 });

      console.log(chalk.green('✓ Created blackroad.json'));
      console.log(chalk.dim('\nNext steps:'));
      console.log(chalk.dim('  1. Run: blackroad login'));
      console.log(chalk.dim('  2. Run: blackroad deploy'));
    } catch (err: any) {
      console.error(chalk.red('Error:'), err.message);
      process.exit(1);
    }
  });
