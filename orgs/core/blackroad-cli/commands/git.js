import chalk from 'chalk';
import { spawn } from 'child_process';
import ora from 'ora';
import Table from 'cli-table3';
import inquirer from 'inquirer';

const GITHUB_ORG = 'BlackRoad-OS';

function runCommand(cmd, args = []) {
  return new Promise((resolve, reject) => {
    const proc = spawn(cmd, args, {
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
        reject(new Error(stderr || stdout || `Command failed with code ${code}`));
      }
    });

    proc.on('error', (err) => {
      reject(err);
    });
  });
}

async function getGitStatus() {
  try {
    const result = await runCommand('git', ['status', '--short']);
    return result.stdout;
  } catch (e) {
    throw new Error(`Failed to get git status: ${e.message}`);
  }
}

async function getCurrentBranch() {
  try {
    const result = await runCommand('git', ['branch', '--show-current']);
    return result.stdout.trim();
  } catch (e) {
    throw new Error(`Failed to get current branch: ${e.message}`);
  }
}

async function getRepoName() {
  try {
    const result = await runCommand('git', ['remote', 'get-url', 'origin']);
    const url = result.stdout.trim();
    const match = url.match(/([^/]+)\.git$/);
    return match ? match[1] : null;
  } catch (e) {
    return null;
  }
}

async function listPRs() {
  try {
    const result = await runCommand('gh', ['pr', 'list', '--limit', '10']);
    return result.stdout;
  } catch (e) {
    throw new Error(`Failed to list PRs: ${e.message}`);
  }
}

async function createPR(title, body) {
  try {
    const args = ['pr', 'create', '--title', title];
    if (body) {
      args.push('--body', body);
    }
    const result = await runCommand('gh', args);
    return result.stdout;
  } catch (e) {
    throw new Error(`Failed to create PR: ${e.message}`);
  }
}

async function viewPR(number) {
  const proc = spawn('gh', ['pr', 'view', number.toString(), '--web'], {
    stdio: 'inherit'
  });

  return new Promise((resolve) => {
    proc.on('close', () => resolve());
  });
}

async function listWorkflows() {
  try {
    const result = await runCommand('gh', ['workflow', 'list']);
    return result.stdout;
  } catch (e) {
    throw new Error(`Failed to list workflows: ${e.message}`);
  }
}

async function runWorkflow(workflow) {
  try {
    const result = await runCommand('gh', ['workflow', 'run', workflow]);
    return result.stdout;
  } catch (e) {
    throw new Error(`Failed to run workflow: ${e.message}`);
  }
}

export async function gitCommand(options) {
  // Git status
  if (options.status) {
    const spinner = ora('Checking git status...').start();

    try {
      const status = await getGitStatus();
      const branch = await getCurrentBranch();
      const repo = await getRepoName();

      spinner.stop();

      console.log(chalk.hex('#FF6B00').bold('\n  📊 Git Status\n'));
      console.log(chalk.gray('  Repository: ') + chalk.cyan(repo || 'Unknown'));
      console.log(chalk.gray('  Branch: ') + chalk.cyan(branch));
      console.log();

      if (status.trim()) {
        console.log(chalk.yellow('  Changes:'));
        console.log(status.split('\n').map(line => '    ' + line).join('\n'));
      } else {
        console.log(chalk.green('  ✨ Working tree clean'));
      }

      console.log();
    } catch (e) {
      spinner.fail(chalk.red('Failed to get status'));
      console.log(chalk.red(`  ❌ ${e.message}\n`));
    }
    return;
  }

  // List pull requests
  if (options.pr === true || options.prList) {
    const spinner = ora('Fetching pull requests...').start();

    try {
      const prs = await listPRs();
      spinner.stop();

      console.log(chalk.hex('#FF6B00').bold('\n  🔀 Pull Requests\n'));
      console.log(prs || chalk.gray('  No open pull requests'));
      console.log();
    } catch (e) {
      spinner.fail(chalk.red('Failed to list PRs'));
      console.log(chalk.red(`  ❌ ${e.message}\n`));
    }
    return;
  }

  // Create pull request
  if (options.prCreate) {
    const branch = await getCurrentBranch();

    const { title, body } = await inquirer.prompt([
      {
        type: 'input',
        name: 'title',
        message: 'PR title:',
        default: `Changes from ${branch}`
      },
      {
        type: 'input',
        name: 'body',
        message: 'PR description (optional):'
      }
    ]);

    const spinner = ora('Creating pull request...').start();

    try {
      const result = await createPR(title, body);
      spinner.succeed(chalk.green('Pull request created!'));
      console.log(chalk.cyan('\n' + result + '\n'));
    } catch (e) {
      spinner.fail(chalk.red('Failed to create PR'));
      console.log(chalk.red(`  ❌ ${e.message}\n`));
    }
    return;
  }

  // View pull request
  if (options.prView) {
    await viewPR(options.prView);
    return;
  }

  // List workflows
  if (options.workflow === true || options.workflowList) {
    const spinner = ora('Fetching GitHub workflows...').start();

    try {
      const workflows = await listWorkflows();
      spinner.stop();

      console.log(chalk.hex('#FF6B00').bold('\n  ⚙️  GitHub Actions Workflows\n'));
      console.log(workflows);
      console.log();
    } catch (e) {
      spinner.fail(chalk.red('Failed to list workflows'));
      console.log(chalk.red(`  ❌ ${e.message}\n`));
    }
    return;
  }

  // Run workflow
  if (options.workflowRun) {
    const spinner = ora(`Running workflow "${options.workflowRun}"...`).start();

    try {
      await runWorkflow(options.workflowRun);
      spinner.succeed(chalk.green('Workflow triggered!'));
      console.log();
    } catch (e) {
      spinner.fail(chalk.red('Failed to run workflow'));
      console.log(chalk.red(`  ❌ ${e.message}\n`));
    }
    return;
  }

  // Default: show git overview
  try {
    const status = await getGitStatus();
    const branch = await getCurrentBranch();
    const repo = await getRepoName();

    console.log(chalk.hex('#FF6B00').bold('\n  🐙 Git & GitHub\n'));

    const table = new Table({
      head: [chalk.gray('Property'), chalk.gray('Value')],
      style: { head: [], border: ['gray'] }
    });

    table.push(
      ['Repository', chalk.cyan(repo || 'Unknown')],
      ['Branch', chalk.cyan(branch)],
      ['Status', status.trim() ? chalk.yellow('Changes detected') : chalk.green('Clean')],
      ['Organization', chalk.cyan(GITHUB_ORG)]
    );

    console.log(table.toString());
    console.log();

    console.log(chalk.gray('  💡 Commands:'));
    console.log(chalk.gray('    br git --status              Git status'));
    console.log(chalk.gray('    br git --pr                  List PRs'));
    console.log(chalk.gray('    br git --pr-create           Create new PR'));
    console.log(chalk.gray('    br git --pr-view <number>    View PR in browser'));
    console.log(chalk.gray('    br git --workflow            List workflows'));
    console.log(chalk.gray('    br git --workflow-run <name> Run workflow'));
    console.log();
  } catch (e) {
    console.log(chalk.red(`\n  ❌ Error: ${e.message}\n`));
  }
}
