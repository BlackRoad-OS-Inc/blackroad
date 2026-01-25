import { Command } from 'commander';
import chalk from 'chalk';
import { getApiClient } from '../api';

export const logsCommand = new Command('logs')
  .description('View deployment logs')
  .argument('<name>', 'Deployment name')
  .option('-f, --follow', 'Follow log output')
  .option('-n, --tail <lines>', 'Number of lines to show', '100')
  .action(async (name, options) => {
    try {
      const api = await getApiClient();
      const config = await api.defaults;

      const url = `${config.baseURL}/api/logs/${name}?tail=${options.tail}&follow=${options.follow || false}`;

      if (options.follow) {
        console.log(chalk.dim(`Streaming logs for ${name}...`));
        console.log(chalk.dim('Press Ctrl+C to stop\n'));

        // For streaming, we need to use fetch or a streaming library
        const response = await fetch(url, {
          headers: {
            Authorization: api.defaults.headers.Authorization as string,
          },
        });

        if (!response.ok) {
          throw new Error(`HTTP ${response.status}: ${response.statusText}`);
        }

        const reader = response.body?.getReader();
        if (!reader) throw new Error('No response body');

        const decoder = new TextDecoder();

        while (true) {
          const { done, value } = await reader.read();
          if (done) break;

          const text = decoder.decode(value, { stream: true });
          process.stdout.write(text);
        }
      } else {
        const response = await api.get(`/api/logs/${name}?tail=${options.tail}`);
        console.log(response.data);
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
