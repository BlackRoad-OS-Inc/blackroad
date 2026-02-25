import chalk from 'chalk';
import { spawn } from 'child_process';
import ora from 'ora';
import Table from 'cli-table3';
import inquirer from 'inquirer';

const CLOUDFLARE_CONFIG = {
  zone_id: '848cf0b18d51e0170e0d1537aec3505a',
  account_id: '848cf0b18d51e0170e0d1537aec3505a'
};

function runWrangler(args = []) {
  return new Promise((resolve, reject) => {
    const proc = spawn('wrangler', args, {
      stdio: 'pipe'
    });

    let stdout = '';
    let stderr = '';

    proc.stdout?.on('data', (data) => stdout += data.toString());
    proc.stderr?.on('data', (data) => stderr += data.toString());

    proc.on('close', (code) => {
      if (code === 0) {
        resolve({ success: true, stdout, stderr });
      } else {
        reject(new Error(stderr || `Command failed with code ${code}`));
      }
    });

    proc.on('error', (err) => {
      reject(err);
    });
  });
}

async function listKVNamespaces() {
  try {
    const result = await runWrangler(['kv', 'namespace', 'list']);
    return JSON.parse(result.stdout);
  } catch (e) {
    throw new Error(`Failed to list KV namespaces: ${e.message}`);
  }
}

async function listD1Databases() {
  try {
    const result = await runWrangler(['d1', 'list']);
    // Parse output - wrangler d1 list returns text, not JSON
    return result.stdout;
  } catch (e) {
    throw new Error(`Failed to list D1 databases: ${e.message}`);
  }
}

async function listPagesProjects() {
  try {
    const result = await runWrangler(['pages', 'project', 'list']);
    return result.stdout;
  } catch (e) {
    throw new Error(`Failed to list Pages projects: ${e.message}`);
  }
}

async function deployPages(projectName, directory) {
  console.log(chalk.hex('#FF6B00').bold(`\n  🚀 Deploying ${projectName} to Cloudflare Pages...\n`));

  const proc = spawn('wrangler', ['pages', 'deploy', directory, '--project-name', projectName], {
    stdio: 'inherit'
  });

  return new Promise((resolve, reject) => {
    proc.on('close', (code) => {
      if (code === 0) {
        resolve({ success: true });
      } else {
        reject(new Error(`Deployment failed with code ${code}`));
      }
    });

    proc.on('error', (err) => {
      reject(err);
    });
  });
}

async function queryD1(database, query) {
  try {
    const result = await runWrangler(['d1', 'execute', database, '--command', query]);
    return result.stdout;
  } catch (e) {
    throw new Error(`D1 query failed: ${e.message}`);
  }
}

async function getKVValue(namespace, key) {
  try {
    const result = await runWrangler(['kv', 'key', 'get', key, '--namespace-id', namespace]);
    return result.stdout;
  } catch (e) {
    throw new Error(`Failed to get KV value: ${e.message}`);
  }
}

async function setKVValue(namespace, key, value) {
  try {
    const result = await runWrangler(['kv', 'key', 'put', key, value, '--namespace-id', namespace]);
    return result.stdout;
  } catch (e) {
    throw new Error(`Failed to set KV value: ${e.message}`);
  }
}

export async function cloudflareCommand(options) {
  // List KV namespaces
  if (options.kv === true || options.kvList) {
    const spinner = ora('Fetching KV namespaces...').start();

    try {
      const namespaces = await listKVNamespaces();
      spinner.stop();

      console.log(chalk.hex('#FF6B00').bold('\n  🗄️  Cloudflare KV Namespaces\n'));

      const table = new Table({
        head: [chalk.gray('ID'), chalk.gray('Title'), chalk.gray('Supports URL Encoding')],
        style: { head: [], border: ['gray'] }
      });

      namespaces.forEach(ns => {
        table.push([
          chalk.cyan(ns.id),
          ns.title,
          ns.supports_url_encoding ? '✅' : '❌'
        ]);
      });

      console.log(table.toString());
      console.log();
    } catch (e) {
      spinner.fail(chalk.red('Failed to list KV namespaces'));
      console.log(chalk.red(`  ❌ ${e.message}\n`));
    }
    return;
  }

  // Get KV value
  if (options.kvGet) {
    const [namespace, key] = options.kvGet.split(':');
    if (!namespace || !key) {
      console.log(chalk.red('\n  ❌ Usage: --kv-get <namespace-id>:<key>\n'));
      return;
    }

    const spinner = ora(`Getting value for key "${key}"...`).start();

    try {
      const value = await getKVValue(namespace, key);
      spinner.succeed(chalk.green('Value retrieved'));
      console.log(chalk.cyan('\n' + value + '\n'));
    } catch (e) {
      spinner.fail(chalk.red('Failed to get value'));
      console.log(chalk.red(`  ❌ ${e.message}\n`));
    }
    return;
  }

  // Set KV value
  if (options.kvSet) {
    const [namespace, keyValue] = options.kvSet.split(':');
    const [key, ...valueParts] = keyValue.split('=');
    const value = valueParts.join('=');

    if (!namespace || !key || !value) {
      console.log(chalk.red('\n  ❌ Usage: --kv-set <namespace-id>:<key>=<value>\n'));
      return;
    }

    const spinner = ora(`Setting value for key "${key}"...`).start();

    try {
      await setKVValue(namespace, key, value);
      spinner.succeed(chalk.green(`Value set for key "${key}"`));
      console.log();
    } catch (e) {
      spinner.fail(chalk.red('Failed to set value'));
      console.log(chalk.red(`  ❌ ${e.message}\n`));
    }
    return;
  }

  // List D1 databases
  if (options.d1) {
    const spinner = ora('Fetching D1 databases...').start();

    try {
      const output = await listD1Databases();
      spinner.stop();

      console.log(chalk.hex('#FF6B00').bold('\n  🗃️  Cloudflare D1 Databases\n'));
      console.log(output);
      console.log();
    } catch (e) {
      spinner.fail(chalk.red('Failed to list D1 databases'));
      console.log(chalk.red(`  ❌ ${e.message}\n`));
    }
    return;
  }

  // Query D1 database
  if (options.d1Query) {
    const [database, ...queryParts] = options.d1Query.split(':');
    const query = queryParts.join(':');

    if (!database || !query) {
      console.log(chalk.red('\n  ❌ Usage: --d1-query <database-name>:<sql-query>\n'));
      return;
    }

    const spinner = ora('Executing query...').start();

    try {
      const result = await queryD1(database, query);
      spinner.succeed(chalk.green('Query executed'));
      console.log(chalk.cyan('\n' + result + '\n'));
    } catch (e) {
      spinner.fail(chalk.red('Query failed'));
      console.log(chalk.red(`  ❌ ${e.message}\n`));
    }
    return;
  }

  // List Pages projects
  if (options.pages) {
    const spinner = ora('Fetching Pages projects...').start();

    try {
      const output = await listPagesProjects();
      spinner.stop();

      console.log(chalk.hex('#FF6B00').bold('\n  📄 Cloudflare Pages Projects\n'));
      console.log(output);
      console.log();
    } catch (e) {
      spinner.fail(chalk.red('Failed to list Pages projects'));
      console.log(chalk.red(`  ❌ ${e.message}\n`));
    }
    return;
  }

  // Deploy to Pages
  if (options.pagesDeploy) {
    const [projectName, directory] = options.pagesDeploy.split(':');

    if (!projectName || !directory) {
      console.log(chalk.red('\n  ❌ Usage: --pages-deploy <project-name>:<directory>\n'));
      return;
    }

    try {
      await deployPages(projectName, directory);
      console.log(chalk.green('\n  ✅ Deployment complete!\n'));
    } catch (e) {
      console.log(chalk.red(`\n  ❌ Deployment failed: ${e.message}\n`));
    }
    return;
  }

  // Show whoami
  if (options.whoami) {
    const spinner = ora('Checking Wrangler authentication...').start();

    try {
      const result = await runWrangler(['whoami']);
      spinner.stop();

      console.log(chalk.hex('#FF6B00').bold('\n  👤 Cloudflare Account\n'));
      console.log(result.stdout);
      console.log();
    } catch (e) {
      spinner.fail(chalk.red('Not authenticated'));
      console.log(chalk.red(`  ❌ ${e.message}\n`));
      console.log(chalk.gray('  💡 Run `wrangler login` to authenticate\n'));
    }
    return;
  }

  // Default: show overview
  console.log(chalk.hex('#FF6B00').bold('\n  ☁️  Cloudflare Management\n'));

  const table = new Table({
    head: [chalk.gray('Resource'), chalk.gray('Command')],
    style: { head: [], border: ['gray'] }
  });

  table.push(
    ['KV Namespaces', chalk.cyan('br cf --kv')],
    ['KV Get Value', chalk.cyan('br cf --kv-get <ns-id>:<key>')],
    ['KV Set Value', chalk.cyan('br cf --kv-set <ns-id>:<key>=<value>')],
    ['D1 Databases', chalk.cyan('br cf --d1')],
    ['D1 Query', chalk.cyan('br cf --d1-query <db>:<sql>')],
    ['Pages Projects', chalk.cyan('br cf --pages')],
    ['Pages Deploy', chalk.cyan('br cf --pages-deploy <project>:<dir>')],
    ['Account Info', chalk.cyan('br cf --whoami')]
  );

  console.log(table.toString());
  console.log();

  console.log(chalk.gray('  📊 Zone ID: ') + chalk.cyan(CLOUDFLARE_CONFIG.zone_id));
  console.log();
}
