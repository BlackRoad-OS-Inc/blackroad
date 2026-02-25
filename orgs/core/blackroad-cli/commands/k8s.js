import chalk from 'chalk';
import { spawn } from 'child_process';
import ora from 'ora';
import Table from 'cli-table3';
import inquirer from 'inquirer';

function runKubectl(args = [], options = {}) {
  return new Promise((resolve, reject) => {
    const proc = spawn('kubectl', args, {
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

async function getContexts() {
  const result = await runKubectl(['config', 'get-contexts', '-o', 'name']);
  return result.stdout.trim().split('\n').filter(c => c);
}

async function getCurrentContext() {
  const result = await runKubectl(['config', 'current-context']);
  return result.stdout.trim();
}

async function getPods(namespace = 'default') {
  const args = ['get', 'pods', '-n', namespace, '-o', 'json'];
  const result = await runKubectl(args);
  const data = JSON.parse(result.stdout);
  return data.items || [];
}

async function getServices(namespace = 'default') {
  const args = ['get', 'services', '-n', namespace, '-o', 'json'];
  const result = await runKubectl(args);
  const data = JSON.parse(result.stdout);
  return data.items || [];
}

async function getDeployments(namespace = 'default') {
  const args = ['get', 'deployments', '-n', namespace, '-o', 'json'];
  const result = await runKubectl(args);
  const data = JSON.parse(result.stdout);
  return data.items || [];
}

async function getNamespaces() {
  const result = await runKubectl(['get', 'namespaces', '-o', 'json']);
  const data = JSON.parse(result.stdout);
  return data.items.map(ns => ns.metadata.name);
}

export async function k8sCommand(options) {
  // List contexts
  if (options.contexts) {
    const spinner = ora('Fetching Kubernetes contexts...').start();

    try {
      const contexts = await getContexts();
      const current = await getCurrentContext();
      spinner.stop();

      console.log(chalk.hex('#FF6B00').bold('\n  ☸️  Kubernetes Contexts\n'));

      contexts.forEach(ctx => {
        const isCurrent = ctx === current;
        const icon = isCurrent ? chalk.green('●') : chalk.gray('○');
        const name = isCurrent ? chalk.green.bold(ctx) : ctx;
        console.log(`  ${icon} ${name}`);
      });

      console.log(chalk.gray(`\n  Total: ${contexts.length} context(s)\n`));

    } catch (e) {
      spinner.fail(chalk.red('Failed to list contexts'));
      console.log(chalk.red(`  ❌ ${e.message}\n`));
    }
    return;
  }

  // Switch context
  if (options.use) {
    const spinner = ora(`Switching to ${options.use}...`).start();

    try {
      await runKubectl(['config', 'use-context', options.use]);
      spinner.succeed(chalk.green(`✅ Switched to ${options.use}`));
      console.log();
    } catch (e) {
      spinner.fail(chalk.red('Failed to switch context'));
      console.log(chalk.red(`  ❌ ${e.message}\n`));
    }
    return;
  }

  // List namespaces
  if (options.namespaces) {
    const spinner = ora('Fetching namespaces...').start();

    try {
      const namespaces = await getNamespaces();
      spinner.stop();

      console.log(chalk.hex('#FF6B00').bold('\n  📦 Kubernetes Namespaces\n'));

      namespaces.forEach(ns => {
        console.log(`  ${chalk.cyan('•')} ${ns}`);
      });

      console.log(chalk.gray(`\n  Total: ${namespaces.length} namespace(s)\n`));

    } catch (e) {
      spinner.fail(chalk.red('Failed to list namespaces'));
      console.log(chalk.red(`  ❌ ${e.message}\n`));
    }
    return;
  }

  // List pods
  if (options.pods) {
    const namespace = options.namespace || 'default';
    const spinner = ora(`Fetching pods in ${namespace}...`).start();

    try {
      const pods = await getPods(namespace);
      spinner.stop();

      console.log(chalk.hex('#FF6B00').bold(`\n  🎯 Pods in ${namespace}\n`));

      const table = new Table({
        head: [chalk.gray('Name'), chalk.gray('Status'), chalk.gray('Restarts'), chalk.gray('Age')],
        style: { head: [], border: ['gray'] }
      });

      pods.forEach(pod => {
        const name = pod.metadata.name;
        const phase = pod.status.phase;
        const restarts = pod.status.containerStatuses
          ? pod.status.containerStatuses[0]?.restartCount || 0
          : 0;

        const createdAt = new Date(pod.metadata.creationTimestamp);
        const age = Math.floor((Date.now() - createdAt.getTime()) / 1000 / 60);

        const statusColor = phase === 'Running' ? chalk.green
          : phase === 'Pending' ? chalk.yellow
          : chalk.red;

        table.push([
          name.substring(0, 40),
          statusColor(phase),
          restarts,
          `${age}m`
        ]);
      });

      console.log(table.toString());
      console.log(chalk.gray(`\n  Total: ${pods.length} pod(s)\n`));

    } catch (e) {
      spinner.fail(chalk.red('Failed to list pods'));
      console.log(chalk.red(`  ❌ ${e.message}\n`));
    }
    return;
  }

  // List services
  if (options.services) {
    const namespace = options.namespace || 'default';
    const spinner = ora(`Fetching services in ${namespace}...`).start();

    try {
      const services = await getServices(namespace);
      spinner.stop();

      console.log(chalk.hex('#FF6B00').bold(`\n  🌐 Services in ${namespace}\n`));

      const table = new Table({
        head: [chalk.gray('Name'), chalk.gray('Type'), chalk.gray('Cluster IP'), chalk.gray('Ports')],
        style: { head: [], border: ['gray'] }
      });

      services.forEach(svc => {
        const name = svc.metadata.name;
        const type = svc.spec.type;
        const clusterIP = svc.spec.clusterIP;
        const ports = svc.spec.ports
          ? svc.spec.ports.map(p => `${p.port}/${p.protocol}`).join(', ')
          : '-';

        table.push([
          name,
          chalk.cyan(type),
          clusterIP,
          ports
        ]);
      });

      console.log(table.toString());
      console.log(chalk.gray(`\n  Total: ${services.length} service(s)\n`));

    } catch (e) {
      spinner.fail(chalk.red('Failed to list services'));
      console.log(chalk.red(`  ❌ ${e.message}\n`));
    }
    return;
  }

  // List deployments
  if (options.deployments) {
    const namespace = options.namespace || 'default';
    const spinner = ora(`Fetching deployments in ${namespace}...`).start();

    try {
      const deployments = await getDeployments(namespace);
      spinner.stop();

      console.log(chalk.hex('#FF6B00').bold(`\n  🚀 Deployments in ${namespace}\n`));

      const table = new Table({
        head: [chalk.gray('Name'), chalk.gray('Ready'), chalk.gray('Up-to-date'), chalk.gray('Available')],
        style: { head: [], border: ['gray'] }
      });

      deployments.forEach(dep => {
        const name = dep.metadata.name;
        const ready = `${dep.status.readyReplicas || 0}/${dep.spec.replicas}`;
        const upToDate = dep.status.updatedReplicas || 0;
        const available = dep.status.availableReplicas || 0;

        const readyColor = (dep.status.readyReplicas === dep.spec.replicas)
          ? chalk.green
          : chalk.yellow;

        table.push([
          name,
          readyColor(ready),
          upToDate,
          available
        ]);
      });

      console.log(table.toString());
      console.log(chalk.gray(`\n  Total: ${deployments.length} deployment(s)\n`));

    } catch (e) {
      spinner.fail(chalk.red('Failed to list deployments'));
      console.log(chalk.red(`  ❌ ${e.message}\n`));
    }
    return;
  }

  // View logs
  if (options.logs) {
    const podName = options.logs;
    const namespace = options.namespace || 'default';

    console.log(chalk.hex('#FF6B00').bold(`\n  📋 Logs for ${podName}\n`));

    try {
      const args = ['logs', podName, '-n', namespace];
      if (options.follow) args.push('-f');
      if (options.tail) args.push('--tail', options.tail);

      await runKubectl(args, { inherit: true });
    } catch (e) {
      console.log(chalk.red(`\n  ❌ ${e.message}\n`));
    }
    return;
  }

  // Execute command
  if (options.exec) {
    const [podName, ...command] = options.exec.split(' ');
    const namespace = options.namespace || 'default';

    console.log(chalk.hex('#FF6B00').bold(`\n  🔧 Executing in ${podName}\n`));

    try {
      const args = ['exec', '-it', podName, '-n', namespace, '--', ...command];
      await runKubectl(args, { inherit: true });
    } catch (e) {
      console.log(chalk.red(`\n  ❌ ${e.message}\n`));
    }
    return;
  }

  // Scale deployment
  if (options.scale) {
    const [deployment, replicas] = options.scale.split(':');
    const namespace = options.namespace || 'default';

    const spinner = ora(`Scaling ${deployment} to ${replicas} replicas...`).start();

    try {
      await runKubectl(['scale', 'deployment', deployment, `--replicas=${replicas}`, '-n', namespace]);
      spinner.succeed(chalk.green(`✅ ${deployment} scaled to ${replicas} replicas`));
      console.log();
    } catch (e) {
      spinner.fail(chalk.red('Scaling failed'));
      console.log(chalk.red(`  ❌ ${e.message}\n`));
    }
    return;
  }

  // Restart deployment
  if (options.restart) {
    const deployment = options.restart;
    const namespace = options.namespace || 'default';

    const spinner = ora(`Restarting ${deployment}...`).start();

    try {
      await runKubectl(['rollout', 'restart', 'deployment', deployment, '-n', namespace]);
      spinner.succeed(chalk.green(`✅ ${deployment} restart initiated`));
      console.log();
    } catch (e) {
      spinner.fail(chalk.red('Restart failed'));
      console.log(chalk.red(`  ❌ ${e.message}\n`));
    }
    return;
  }

  // Apply manifest
  if (options.apply) {
    const file = options.apply;
    const spinner = ora(`Applying ${file}...`).start();

    try {
      await runKubectl(['apply', '-f', file]);
      spinner.succeed(chalk.green(`✅ Applied ${file}`));
      console.log();
    } catch (e) {
      spinner.fail(chalk.red('Apply failed'));
      console.log(chalk.red(`  ❌ ${e.message}\n`));
    }
    return;
  }

  // Default: show cluster info
  console.log(chalk.hex('#FF6B00').bold('\n  ☸️  Kubernetes Management\n'));

  try {
    const current = await getCurrentContext();

    const table = new Table({
      head: [chalk.gray('Property'), chalk.gray('Value')],
      style: { head: [], border: ['gray'] }
    });

    table.push(['Current Context', chalk.green(current)]);

    console.log(table.toString());
    console.log();

    console.log(chalk.gray('  💡 Commands:'));
    console.log(chalk.gray('    br k8s --contexts           List contexts'));
    console.log(chalk.gray('    br k8s --use <context>      Switch context'));
    console.log(chalk.gray('    br k8s --pods               List pods'));
    console.log(chalk.gray('    br k8s --services           List services'));
    console.log(chalk.gray('    br k8s --deployments        List deployments'));
    console.log(chalk.gray('    br k8s --logs <pod>         View pod logs'));
    console.log(chalk.gray('    br k8s --scale <dep>:<n>    Scale deployment'));
    console.log(chalk.gray('    br k8s --namespace <ns>     Specify namespace'));
    console.log();

  } catch (e) {
    console.log(chalk.yellow('  ⚠️  kubectl not configured or not available\n'));
    console.log(chalk.gray('  Install kubectl: https://kubernetes.io/docs/tasks/tools/\n'));
  }
}
