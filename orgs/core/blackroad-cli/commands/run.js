// BR-CLI run command - execute operations across nodes
import chalk from 'chalk';
import Inventory from '../lib/inventory.js';
import SelectorEngine from '../lib/selector.js';
import { exec } from 'child_process';
import { promisify } from 'util';

const execAsync = promisify(exec);

export async function runCommand(program) {
    const inventory = new Inventory();
    const selector = new SelectorEngine(inventory);

    const cmd = program
        .command('run')
        .description('Execute operations across selected nodes');

    // Execute command
    cmd
        .command('exec <command>')
        .description('Execute a command on selected nodes')
        .requiredOption('-s, --selector <expr>', 'Target selector expression')
        .option('-p, --parallel', 'Run in parallel', false)
        .option('--dry-run', 'Show what would be executed', false)
        .action(async (command, options) => {
            const nodes = selector.resolve(options.selector);

            console.log(chalk.blue('📡 Targeting ') + chalk.yellow(nodes.length) + chalk.blue(' nodes'));
            
            if (options.dryRun) {
                console.log(chalk.gray('\nDry run mode - no commands will be executed\n'));
                nodes.forEach(node => {
                    console.log(chalk.cyan(`${node.name}:`) + ` ${command}`);
                });
                return;
            }

            console.log(chalk.gray(`\nCommand: ${command}\n`));

            if (options.parallel) {
                // Parallel execution
                const promises = nodes.map(async (node) => {
                    try {
                        const sshCommand = `ssh ${node.ip} "${command}"`;
                        const { stdout, stderr } = await execAsync(sshCommand);
                        return { node: node.name, success: true, output: stdout || stderr };
                    } catch (error) {
                        return { node: node.name, success: false, error: error.message };
                    }
                });

                const results = await Promise.all(promises);
                
                results.forEach(result => {
                    if (result.success) {
                        console.log(chalk.green(`✓ ${result.node}`));
                        console.log(chalk.gray(result.output));
                    } else {
                        console.log(chalk.red(`✗ ${result.node}`));
                        console.log(chalk.red(result.error));
                    }
                });

                const successCount = results.filter(r => r.success).length;
                console.log(chalk.blue(`\n${successCount}/${results.length} nodes succeeded`));
            } else {
                // Serial execution
                for (const node of nodes) {
                    console.log(chalk.cyan(`\n▶ ${node.name}:`));
                    try {
                        const sshCommand = `ssh ${node.ip} "${command}"`;
                        const { stdout, stderr } = await execAsync(sshCommand);
                        console.log(stdout || stderr);
                        console.log(chalk.green('✓ Success'));
                    } catch (error) {
                        console.log(chalk.red('✗ Failed:'), error.message);
                    }
                }
            }
        });

    // SSH into node
    cmd
        .command('ssh <node>')
        .description('SSH into a specific node')
        .action(async (nodeName) => {
            const node = inventory.getNode(nodeName);
            
            if (!node) {
                console.log(chalk.red('✗ Node not found:'), nodeName);
                return;
            }

            console.log(chalk.blue('🔌 Connecting to ') + chalk.yellow(node.name));
            
            // Use spawn to maintain interactive session
            const { spawn } = await import('child_process');
            const ssh = spawn('ssh', [node.ip], { stdio: 'inherit' });
            
            ssh.on('exit', (code) => {
                console.log(chalk.gray(`\nDisconnected (exit code: ${code})`));
            });
        });

    // Upload file
    cmd
        .command('upload <file>')
        .description('Upload a file to selected nodes')
        .requiredOption('-s, --selector <expr>', 'Target selector expression')
        .requiredOption('-d, --dest <path>', 'Destination path on remote nodes')
        .action(async (file, options) => {
            const nodes = selector.resolve(options.selector);

            console.log(chalk.blue('📤 Uploading to ') + chalk.yellow(nodes.length) + chalk.blue(' nodes'));

            for (const node of nodes) {
                try {
                    const scpCommand = `scp "${file}" ${node.ip}:${options.dest}`;
                    await execAsync(scpCommand);
                    console.log(chalk.green('✓') + ` ${node.name}`);
                } catch (error) {
                    console.log(chalk.red('✗') + ` ${node.name}: ${error.message}`);
                }
            }
        });

    // Download file
    cmd
        .command('download <file>')
        .description('Download a file from a node')
        .requiredOption('-n, --node <name>', 'Node name')
        .requiredOption('-d, --dest <path>', 'Local destination path')
        .action(async (file, options) => {
            const node = inventory.getNode(options.node);
            
            if (!node) {
                console.log(chalk.red('✗ Node not found:'), options.node);
                return;
            }

            try {
                const scpCommand = `scp ${node.ip}:${file} "${options.dest}"`;
                await execAsync(scpCommand);
                console.log(chalk.green('✓ Downloaded to:'), options.dest);
            } catch (error) {
                console.log(chalk.red('✗ Failed:'), error.message);
            }
        });

    // Fanout test
    cmd
        .command('fanout-test')
        .description('Test fanout performance across all nodes')
        .requiredOption('-s, --selector <expr>', 'Target selector expression')
        .action(async (options) => {
            const nodes = selector.resolve(options.selector);
            const startTime = Date.now();

            console.log(chalk.blue('⚡ Testing fanout to ') + chalk.yellow(nodes.length) + chalk.blue(' nodes\n'));

            const promises = nodes.map(async (node) => {
                const nodeStart = Date.now();
                try {
                    const { stdout } = await execAsync(`ssh ${node.ip} "echo ok"`);
                    const duration = Date.now() - nodeStart;
                    return { node: node.name, success: true, duration };
                } catch (error) {
                    const duration = Date.now() - nodeStart;
                    return { node: node.name, success: false, duration };
                }
            });

            const results = await Promise.all(promises);
            const totalTime = Date.now() - startTime;

            const successResults = results.filter(r => r.success);
            const avgDuration = successResults.reduce((sum, r) => sum + r.duration, 0) / successResults.length;

            console.log(chalk.green(`\n✓ ${successResults.length}/${nodes.length} nodes responded`));
            console.log(chalk.cyan(`⏱  Total time: ${totalTime}ms`));
            console.log(chalk.cyan(`⏱  Average node time: ${Math.round(avgDuration)}ms`));
        });
}
