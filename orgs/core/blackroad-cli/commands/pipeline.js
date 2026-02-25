import chalk from 'chalk';
import { spawn } from 'child_process';
import ora from 'ora';
import Table from 'cli-table3';
import inquirer from 'inquirer';
import fs from 'fs/promises';
import path from 'path';
import axios from 'axios';

const PIPELINE_DIR = path.join(process.env.HOME, '.blackroad', 'pipelines');

const PIPELINE_TEMPLATES = {
  'node-deploy': {
    name: 'Node.js Deployment Pipeline',
    description: 'Build, test, and deploy Node.js app',
    stages: [
      { name: 'install', command: 'pnpm install', color: '#FF9D00' },
      { name: 'lint', command: 'pnpm run lint', color: '#FF6B00' },
      { name: 'test', command: 'pnpm test', color: '#FF0066' },
      { name: 'build', command: 'pnpm run build', color: '#D600AA' },
      { name: 'deploy', command: 'railway up -d', color: '#7700FF' }
    ]
  },
  'docker-build': {
    name: 'Docker Build & Push Pipeline',
    description: 'Build Docker image and push to registry',
    stages: [
      { name: 'build', command: 'docker build -t $IMAGE_NAME .', color: '#0066FF' },
      { name: 'tag', command: 'docker tag $IMAGE_NAME $REGISTRY/$IMAGE_NAME:$TAG', color: '#00FFAA' },
      { name: 'push', command: 'docker push $REGISTRY/$IMAGE_NAME:$TAG', color: '#FF9D00' },
      { name: 'deploy', command: 'kubectl rollout restart deployment/$DEPLOYMENT', color: '#7700FF' }
    ]
  },
  'cloudflare-pages': {
    name: 'Cloudflare Pages Deployment',
    description: 'Build and deploy to Cloudflare Pages',
    stages: [
      { name: 'install', command: 'pnpm install', color: '#FF9D00' },
      { name: 'build', command: 'pnpm run build', color: '#FF6B00' },
      { name: 'deploy', command: 'wrangler pages deploy dist --project-name=$PROJECT', color: '#FF0066' }
    ]
  },
  'full-stack': {
    name: 'Full Stack Deployment',
    description: 'Deploy frontend, backend, and database migrations',
    stages: [
      { name: 'db-migrate', command: 'pnpm run db:migrate', color: '#FF9D00' },
      { name: 'backend-test', command: 'cd backend && pnpm test', color: '#FF6B00' },
      { name: 'backend-deploy', command: 'cd backend && railway up -d', color: '#FF0066' },
      { name: 'frontend-build', command: 'cd frontend && pnpm run build', color: '#D600AA' },
      { name: 'frontend-deploy', command: 'cd frontend && wrangler pages deploy dist', color: '#7700FF' },
      { name: 'health-check', command: 'curl -f $BACKEND_URL/health && curl -f $FRONTEND_URL', color: '#0066FF' }
    ]
  },
  'github-actions': {
    name: 'Trigger GitHub Actions',
    description: 'Trigger GitHub Actions workflow',
    stages: [
      { name: 'trigger', command: 'gh workflow run $WORKFLOW_NAME', color: '#FF9D00' },
      { name: 'wait', command: 'sleep 5', color: '#FF6B00' },
      { name: 'status', command: 'gh run list --workflow=$WORKFLOW_NAME --limit 1', color: '#FF0066' }
    ]
  }
};

class PipelineRunner {
  constructor(pipeline, options = {}) {
    this.pipeline = pipeline;
    this.options = options;
    this.results = [];
    this.startTime = null;
    this.env = { ...process.env, ...options.env };
  }

  async runStage(stage) {
    const startTime = Date.now();

    return new Promise((resolve, reject) => {
      // Replace environment variables in command
      let command = stage.command;
      Object.keys(this.env).forEach(key => {
        command = command.replace(new RegExp(`\\$${key}`, 'g'), this.env[key]);
      });

      const proc = spawn('bash', ['-c', command], {
        stdio: this.options.verbose ? 'inherit' : 'pipe',
        env: this.env
      });

      let stdout = '';
      let stderr = '';

      if (!this.options.verbose) {
        proc.stdout?.on('data', (data) => stdout += data.toString());
        proc.stderr?.on('data', (data) => stderr += data.toString());
      }

      proc.on('close', (code) => {
        const duration = Date.now() - startTime;

        if (code === 0) {
          resolve({
            stage: stage.name,
            success: true,
            duration,
            stdout: stdout.trim(),
            stderr: stderr.trim()
          });
        } else {
          reject({
            stage: stage.name,
            success: false,
            duration,
            code,
            stdout: stdout.trim(),
            stderr: stderr.trim()
          });
        }
      });

      proc.on('error', (err) => {
        reject({
          stage: stage.name,
          success: false,
          error: err.message
        });
      });
    });
  }

  async run() {
    this.startTime = Date.now();
    console.log(chalk.hex('#FF6B00').bold(`\n  🚀 Running Pipeline: ${this.pipeline.name}\n`));

    for (let i = 0; i < this.pipeline.stages.length; i++) {
      const stage = this.pipeline.stages[i];
      const spinner = ora({
        text: `Stage ${i + 1}/${this.pipeline.stages.length}: ${stage.name}`,
        color: stage.color.replace('#', '')
      }).start();

      try {
        const result = await this.runStage(stage);
        this.results.push(result);

        spinner.succeed(
          chalk.hex(stage.color)(
            `✅ ${stage.name} (${(result.duration / 1000).toFixed(2)}s)`
          )
        );

        if (!this.options.verbose && result.stdout) {
          console.log(chalk.gray(`   ${result.stdout.split('\n').slice(-3).join('\n   ')}`));
        }

      } catch (err) {
        this.results.push(err);

        spinner.fail(
          chalk.red(
            `❌ ${stage.name} failed (${err.duration ? (err.duration / 1000).toFixed(2) + 's' : 'error'})`
          )
        );

        if (err.stderr) {
          console.log(chalk.red(`   ${err.stderr.split('\n').slice(-5).join('\n   ')}`));
        }

        if (!this.options.continueOnError) {
          console.log(chalk.red('\n  ❌ Pipeline failed. Stopping execution.\n'));
          return this.getSummary();
        }
      }
    }

    const totalDuration = Date.now() - this.startTime;
    console.log(chalk.green(`\n  ✅ Pipeline completed in ${(totalDuration / 1000).toFixed(2)}s\n`));

    return this.getSummary();
  }

  getSummary() {
    const totalDuration = Date.now() - this.startTime;
    const successful = this.results.filter(r => r.success).length;
    const failed = this.results.filter(r => !r.success).length;

    return {
      pipeline: this.pipeline.name,
      totalDuration,
      successful,
      failed,
      stages: this.results
    };
  }
}

async function ensurePipelineDir() {
  try {
    await fs.mkdir(PIPELINE_DIR, { recursive: true });
  } catch (e) {
    // Directory exists
  }
}

async function savePipeline(name, pipeline) {
  await ensurePipelineDir();
  const filePath = path.join(PIPELINE_DIR, `${name}.json`);
  await fs.writeFile(filePath, JSON.stringify(pipeline, null, 2), 'utf-8');
}

async function loadPipeline(name) {
  const filePath = path.join(PIPELINE_DIR, `${name}.json`);
  try {
    const data = await fs.readFile(filePath, 'utf-8');
    return JSON.parse(data);
  } catch (e) {
    return null;
  }
}

async function listPipelines() {
  await ensurePipelineDir();
  try {
    const files = await fs.readdir(PIPELINE_DIR);
    return files.filter(f => f.endsWith('.json')).map(f => f.replace('.json', ''));
  } catch (e) {
    return [];
  }
}

async function deletePipeline(name) {
  const filePath = path.join(PIPELINE_DIR, `${name}.json`);
  await fs.unlink(filePath);
}

export async function pipelineCommand(options) {
  // List templates
  if (options.templates) {
    console.log(chalk.hex('#FF6B00').bold('\n  🎨 Pipeline Templates\n'));

    const table = new Table({
      head: [chalk.gray('Template'), chalk.gray('Description'), chalk.gray('Stages')],
      style: { head: [], border: ['gray'] }
    });

    Object.entries(PIPELINE_TEMPLATES).forEach(([key, template]) => {
      table.push([
        chalk.cyan(key),
        template.description,
        template.stages.length
      ]);
    });

    console.log(table.toString());
    console.log();
    return;
  }

  // Create from template
  if (options.create) {
    const templateChoices = Object.entries(PIPELINE_TEMPLATES).map(([key, template]) => ({
      name: `${template.name} - ${template.description}`,
      value: key
    }));

    const answers = await inquirer.prompt([
      {
        type: 'list',
        name: 'template',
        message: 'Select pipeline template:',
        choices: [...templateChoices, { name: 'Custom pipeline', value: 'custom' }]
      },
      {
        type: 'input',
        name: 'name',
        message: 'Pipeline name:',
        validate: (input) => input ? true : 'Name is required'
      }
    ]);

    let pipeline;

    if (answers.template === 'custom') {
      const customAnswers = await inquirer.prompt([
        {
          type: 'input',
          name: 'description',
          message: 'Description:'
        },
        {
          type: 'number',
          name: 'stageCount',
          message: 'Number of stages:',
          default: 3
        }
      ]);

      const stages = [];
      for (let i = 0; i < customAnswers.stageCount; i++) {
        const stageAnswers = await inquirer.prompt([
          {
            type: 'input',
            name: 'name',
            message: `Stage ${i + 1} name:`,
            default: `stage-${i + 1}`
          },
          {
            type: 'input',
            name: 'command',
            message: `Stage ${i + 1} command:`,
            default: 'echo "Stage completed"'
          }
        ]);

        stages.push({
          name: stageAnswers.name,
          command: stageAnswers.command,
          color: '#FF6B00'
        });
      }

      pipeline = {
        name: answers.name,
        description: customAnswers.description,
        stages
      };
    } else {
      pipeline = {
        name: answers.name,
        ...PIPELINE_TEMPLATES[answers.template]
      };
    }

    await savePipeline(answers.name, pipeline);
    console.log(chalk.green(`\n  ✅ Pipeline "${answers.name}" created\n`));
    return;
  }

  // List saved pipelines
  if (options.list) {
    const pipelines = await listPipelines();

    if (pipelines.length === 0) {
      console.log(chalk.yellow('\n  No pipelines found.\n'));
      console.log(chalk.gray('  Create one with: br pipeline --create\n'));
      return;
    }

    console.log(chalk.hex('#FF6B00').bold('\n  📋 Saved Pipelines\n'));

    const table = new Table({
      head: [chalk.gray('Name'), chalk.gray('Description'), chalk.gray('Stages')],
      style: { head: [], border: ['gray'] }
    });

    for (const name of pipelines) {
      const pipeline = await loadPipeline(name);
      table.push([
        chalk.cyan(name),
        pipeline.description || 'No description',
        pipeline.stages.length
      ]);
    }

    console.log(table.toString());
    console.log(chalk.gray(`\n  Total: ${pipelines.length} pipeline(s)\n`));
    return;
  }

  // Delete pipeline
  if (options.delete) {
    const pipelines = await listPipelines();

    if (pipelines.length === 0) {
      console.log(chalk.yellow('\n  No pipelines found.\n'));
      return;
    }

    const { selected } = await inquirer.prompt([
      {
        type: 'list',
        name: 'selected',
        message: 'Select pipeline to delete:',
        choices: pipelines
      }
    ]);

    const { confirm } = await inquirer.prompt([
      {
        type: 'confirm',
        name: 'confirm',
        message: `Delete pipeline "${selected}"?`,
        default: false
      }
    ]);

    if (!confirm) {
      console.log(chalk.yellow('\n  Cancelled.\n'));
      return;
    }

    await deletePipeline(selected);
    console.log(chalk.green(`\n  ✅ Pipeline "${selected}" deleted\n`));
    return;
  }

  // Run pipeline
  if (options.run) {
    const pipelineName = options.run;
    let pipeline = await loadPipeline(pipelineName);

    if (!pipeline) {
      // Check if it's a template
      if (PIPELINE_TEMPLATES[pipelineName]) {
        pipeline = {
          name: pipelineName,
          ...PIPELINE_TEMPLATES[pipelineName]
        };
      } else {
        console.log(chalk.red(`\n  ❌ Pipeline "${pipelineName}" not found\n`));
        return;
      }
    }

    // Parse environment variables from --env flag
    const env = {};
    if (options.env) {
      options.env.split(',').forEach(pair => {
        const [key, value] = pair.split('=');
        if (key && value) {
          env[key] = value;
        }
      });
    }

    const runner = new PipelineRunner(pipeline, {
      env,
      verbose: options.verbose,
      continueOnError: options.continueOnError
    });

    const summary = await runner.run();

    // Save summary if requested
    if (options.save) {
      const summaryPath = path.join(PIPELINE_DIR, `${pipelineName}-${Date.now()}.json`);
      await fs.writeFile(summaryPath, JSON.stringify(summary, null, 2), 'utf-8');
      console.log(chalk.gray(`  📄 Summary saved to: ${summaryPath}\n`));
    }

    return;
  }

  // View pipeline details
  if (options.view) {
    const pipeline = await loadPipeline(options.view);

    if (!pipeline) {
      console.log(chalk.red(`\n  ❌ Pipeline "${options.view}" not found\n`));
      return;
    }

    console.log(chalk.hex('#FF6B00').bold(`\n  📋 Pipeline: ${pipeline.name}\n`));
    console.log(chalk.gray(`  Description: ${pipeline.description || 'No description'}\n`));

    const table = new Table({
      head: [chalk.gray('#'), chalk.gray('Stage'), chalk.gray('Command')],
      style: { head: [], border: ['gray'] }
    });

    pipeline.stages.forEach((stage, idx) => {
      table.push([
        idx + 1,
        chalk.hex(stage.color)(stage.name),
        stage.command.substring(0, 60) + (stage.command.length > 60 ? '...' : '')
      ]);
    });

    console.log(table.toString());
    console.log();
    return;
  }

  // Default: show help
  console.log(chalk.hex('#FF6B00').bold('\n  🚀 CI/CD Pipeline Management\n'));

  const table = new Table({
    head: [chalk.gray('Command'), chalk.gray('Description')],
    style: { head: [], border: ['gray'] }
  });

  table.push(
    ['--templates', 'List available pipeline templates'],
    ['--create', 'Create new pipeline from template'],
    ['--list', 'List all saved pipelines'],
    ['--run <name>', 'Run a pipeline'],
    ['--view <name>', 'View pipeline details'],
    ['--delete', 'Delete a pipeline'],
    ['--env <vars>', 'Set environment variables (KEY=value,...)'],
    ['--verbose', 'Show full command output'],
    ['--continue-on-error', 'Continue pipeline on stage failure'],
    ['--save', 'Save pipeline execution summary']
  );

  console.log(table.toString());
  console.log();

  console.log(chalk.gray('  💡 Examples:'));
  console.log(chalk.gray('    br pipeline --templates'));
  console.log(chalk.gray('    br pipeline --create'));
  console.log(chalk.gray('    br pipeline --run node-deploy --verbose'));
  console.log(chalk.gray('    br pipeline --run docker-build --env IMAGE_NAME=myapp,TAG=v1.0'));
  console.log();
}
