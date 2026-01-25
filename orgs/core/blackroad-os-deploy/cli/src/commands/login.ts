import { Command } from 'commander';
import inquirer from 'inquirer';
import chalk from 'chalk';
import ora from 'ora';
import axios from 'axios';
import { loadConfig, saveConfig } from '../config';
import { resetApiClient } from '../api';

export const loginCommand = new Command('login')
  .description('Login to BlackRoad Deploy')
  .action(async () => {
    try {
      const config = await loadConfig();

      const answers = await inquirer.prompt([
        {
          type: 'input',
          name: 'email',
          message: 'Email:',
          validate: (input) => input.includes('@') || 'Please enter a valid email',
        },
        {
          type: 'password',
          name: 'password',
          message: 'Password:',
          mask: '*',
        },
      ]);

      const spinner = ora('Logging in...').start();

      try {
        const response = await axios.post(`${config.apiUrl}/api/auth/login`, {
          email: answers.email,
          password: answers.password,
        });

        config.apiKey = response.data.apiKey;
        config.email = answers.email;
        await saveConfig(config);
        resetApiClient();

        spinner.succeed(chalk.green('Logged in successfully!'));
        console.log(chalk.dim(`API Key: ${response.data.apiKey.substring(0, 20)}...`));
      } catch (err: any) {
        spinner.fail(chalk.red('Login failed'));
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
