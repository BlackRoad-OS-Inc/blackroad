import chalk from 'chalk';
import { spawn } from 'child_process';
import ora from 'ora';
import Table from 'cli-table3';
import inquirer from 'inquirer';
import fs from 'fs/promises';
import path from 'path';

const DB_CONFIGS = {
  postgres: {
    name: 'PostgreSQL',
    color: '#336791',
    defaultPort: 5432,
    cli: 'psql'
  },
  mysql: {
    name: 'MySQL',
    color: '#00758F',
    defaultPort: 3306,
    cli: 'mysql'
  },
  mongodb: {
    name: 'MongoDB',
    color: '#47A248',
    defaultPort: 27017,
    cli: 'mongosh'
  },
  redis: {
    name: 'Redis',
    color: '#DC382D',
    defaultPort: 6379,
    cli: 'redis-cli'
  }
};

class DatabaseManager {
  constructor(type) {
    this.type = type;
    this.config = DB_CONFIGS[type];
  }

  async runCommand(args, options = {}) {
    return new Promise((resolve, reject) => {
      const proc = spawn(this.config.cli, args, {
        stdio: options.inherit ? 'inherit' : 'pipe',
        ...options
      });

      if (options.inherit) {
        proc.on('close', (code) => {
          if (code === 0) {
            resolve({ success: true });
          } else {
            reject(new Error(`Command failed with code ${code}`));
          }
        });
        return;
      }

      let stdout = '';
      let stderr = '';

      proc.stdout?.on('data', (data) => stdout += data.toString());
      proc.stderr?.on('data', (data) => stderr += data.toString());

      proc.on('close', (code) => {
        if (code === 0 || stdout) {
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

  async listDatabases(host, port, user) {
    if (this.type === 'postgres') {
      const result = await this.runCommand([
        '-h', host,
        '-p', port.toString(),
        '-U', user,
        '-l',
        '-t'
      ]);

      return result.stdout.split('\n')
        .filter(line => line.trim())
        .map(line => line.trim().split('|')[0].trim())
        .filter(name => name && !name.startsWith('template'));
    }

    if (this.type === 'mysql') {
      const result = await this.runCommand([
        '-h', host,
        '-P', port.toString(),
        '-u', user,
        '-e', 'SHOW DATABASES;'
      ]);

      return result.stdout.split('\n')
        .slice(1) // Skip header
        .filter(line => line.trim())
        .filter(name => !['information_schema', 'performance_schema', 'mysql', 'sys'].includes(name));
    }

    if (this.type === 'mongodb') {
      const result = await this.runCommand([
        `mongodb://${host}:${port}`,
        '--eval',
        'db.adminCommand({ listDatabases: 1 }).databases.map(d => d.name).join("\\n")'
      ]);

      return result.stdout.split('\n').filter(line => line.trim());
    }

    return [];
  }

  async connect(host, port, database, user) {
    console.log(chalk.hex(this.config.color).bold(`\n  🔌 Connecting to ${this.config.name}...\n`));

    if (this.type === 'postgres') {
      await this.runCommand([
        '-h', host,
        '-p', port.toString(),
        '-U', user,
        '-d', database
      ], { inherit: true });
    } else if (this.type === 'mysql') {
      await this.runCommand([
        '-h', host,
        '-P', port.toString(),
        '-u', user,
        '-D', database
      ], { inherit: true });
    } else if (this.type === 'mongodb') {
      await this.runCommand([
        `mongodb://${host}:${port}/${database}`
      ], { inherit: true });
    } else if (this.type === 'redis') {
      await this.runCommand([
        '-h', host,
        '-p', port.toString()
      ], { inherit: true });
    }
  }

  async dump(host, port, database, user, outputFile) {
    if (this.type === 'postgres') {
      await spawn('pg_dump', [
        '-h', host,
        '-p', port.toString(),
        '-U', user,
        '-d', database,
        '-F', 'c',
        '-f', outputFile
      ], { stdio: 'inherit' });
    } else if (this.type === 'mysql') {
      await spawn('mysqldump', [
        '-h', host,
        '-P', port.toString(),
        '-u', user,
        database,
        '--result-file', outputFile
      ], { stdio: 'inherit' });
    } else if (this.type === 'mongodb') {
      await spawn('mongodump', [
        `--host=${host}`,
        `--port=${port}`,
        `--db=${database}`,
        `--out=${outputFile}`
      ], { stdio: 'inherit' });
    }
  }
}

export async function dbCommand(options) {
  // List available database types
  if (options.types) {
    console.log(chalk.hex('#FF6B00').bold('\n  🗄️  Available Database Types\n'));

    const table = new Table({
      head: [chalk.gray('Type'), chalk.gray('Name'), chalk.gray('Default Port'), chalk.gray('CLI Tool')],
      style: { head: [], border: ['gray'] }
    });

    Object.entries(DB_CONFIGS).forEach(([type, config]) => {
      table.push([
        chalk.hex(config.color)(type),
        config.name,
        config.defaultPort,
        config.cli
      ]);
    });

    console.log(table.toString());
    console.log();
    return;
  }

  // Select database type
  let dbType = options.type || options.postgres && 'postgres' || options.mysql && 'mysql' || options.mongodb && 'mongodb' || options.redis && 'redis';

  if (!dbType) {
    const { selected } = await inquirer.prompt([
      {
        type: 'list',
        name: 'selected',
        message: 'Select database type:',
        choices: Object.entries(DB_CONFIGS).map(([type, config]) => ({
          name: `${config.name} (${type})`,
          value: type
        }))
      }
    ]);
    dbType = selected;
  }

  const manager = new DatabaseManager(dbType);

  // Connect to database
  if (options.connect) {
    const answers = await inquirer.prompt([
      {
        type: 'input',
        name: 'host',
        message: 'Host:',
        default: options.host || 'localhost'
      },
      {
        type: 'input',
        name: 'port',
        message: 'Port:',
        default: options.port || manager.config.defaultPort
      },
      {
        type: 'input',
        name: 'user',
        message: 'User:',
        default: options.user || 'postgres'
      },
      {
        type: 'input',
        name: 'database',
        message: 'Database:',
        default: options.database || 'postgres'
      }
    ]);

    try {
      await manager.connect(answers.host, answers.port, answers.database, answers.user);
    } catch (e) {
      console.log(chalk.red(`\n  ❌ Connection failed: ${e.message}\n`));
    }
    return;
  }

  // List databases
  if (options.list) {
    const host = options.host || 'localhost';
    const port = options.port || manager.config.defaultPort;
    const user = options.user || 'postgres';

    const spinner = ora('Fetching databases...').start();

    try {
      const databases = await manager.listDatabases(host, port, user);
      spinner.stop();

      console.log(chalk.hex(manager.config.color).bold(`\n  🗄️  ${manager.config.name} Databases\n`));

      databases.forEach(db => {
        console.log(`  ${chalk.cyan('•')} ${db}`);
      });

      console.log(chalk.gray(`\n  Total: ${databases.length} database(s)\n`));

    } catch (e) {
      spinner.fail(chalk.red('Failed to list databases'));
      console.log(chalk.red(`  ❌ ${e.message}\n`));
    }
    return;
  }

  // Dump database
  if (options.dump) {
    const answers = await inquirer.prompt([
      {
        type: 'input',
        name: 'host',
        message: 'Host:',
        default: 'localhost'
      },
      {
        type: 'input',
        name: 'port',
        message: 'Port:',
        default: manager.config.defaultPort
      },
      {
        type: 'input',
        name: 'user',
        message: 'User:',
        default: 'postgres'
      },
      {
        type: 'input',
        name: 'database',
        message: 'Database to dump:',
        default: 'mydb'
      },
      {
        type: 'input',
        name: 'output',
        message: 'Output file:',
        default: `dump_${Date.now()}.sql`
      }
    ]);

    const spinner = ora(`Dumping ${answers.database}...`).start();

    try {
      await manager.dump(answers.host, answers.port, answers.database, answers.user, answers.output);
      spinner.succeed(chalk.green(`✅ Database dumped to ${answers.output}`));
      console.log();
    } catch (e) {
      spinner.fail(chalk.red('Dump failed'));
      console.log(chalk.red(`  ❌ ${e.message}\n`));
    }
    return;
  }

  // Default: show overview
  console.log(chalk.hex('#FF6B00').bold('\n  🗄️  Database Management\n'));

  const table = new Table({
    head: [chalk.gray('Command'), chalk.gray('Description')],
    style: { head: [], border: ['gray'] }
  });

  table.push(
    ['--types', 'List available database types'],
    ['--connect', 'Interactive connection'],
    ['--list', 'List databases'],
    ['--dump', 'Dump database to file'],
    ['--type <type>', 'Specify database type'],
    ['--host <host>', 'Database host'],
    ['--port <port>', 'Database port'],
    ['--user <user>', 'Database user'],
    ['--database <db>', 'Database name']
  );

  console.log(table.toString());
  console.log();

  console.log(chalk.gray('  💡 Examples:'));
  console.log(chalk.gray('    br db --types'));
  console.log(chalk.gray('    br db --postgres --connect'));
  console.log(chalk.gray('    br db --mysql --list --host localhost'));
  console.log(chalk.gray('    br db --mongodb --dump'));
  console.log();
}
