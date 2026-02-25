// BR-CLI telemetry and monitoring system
import chalk from 'chalk';
import fs from 'fs';
import path from 'path';
import os from 'os';

class Telemetry {
    constructor() {
        this.telemetryDir = path.join(os.homedir(), '.blackroad', 'telemetry');
        this.metricsFile = path.join(this.telemetryDir, 'metrics.jsonl');
        
        this.ensureTelemetryDir();
    }

    ensureTelemetryDir() {
        if (!fs.existsSync(this.telemetryDir)) {
            fs.mkdirSync(this.telemetryDir, { recursive: true });
        }
    }

    /**
     * Record a metric
     */
    record(metric) {
        const record = {
            ...metric,
            timestamp: new Date().toISOString(),
            session: process.env.BR_SESSION_ID || 'default'
        };

        try {
            fs.appendFileSync(this.metricsFile, JSON.stringify(record) + '\n');
        } catch (error) {
            console.debug('Failed to record metric:', error.message);
        }
    }

    /**
     * Record command execution
     */
    recordCommand(command, duration, success) {
        this.record({
            type: 'command',
            command,
            duration,
            success,
            user: os.userInfo().username,
            cwd: process.cwd()
        });
    }

    /**
     * Record error
     */
    recordError(error, context = {}) {
        this.record({
            type: 'error',
            error: error.message,
            stack: error.stack,
            ...context
        });
    }

    /**
     * Get recent metrics
     */
    getMetrics(limit = 100) {
        try {
            if (!fs.existsSync(this.metricsFile)) {
                return [];
            }

            const content = fs.readFileSync(this.metricsFile, 'utf-8');
            const lines = content.trim().split('\n').slice(-limit);
            return lines.map(line => JSON.parse(line));
        } catch (error) {
            return [];
        }
    }

    /**
     * Get command statistics
     */
    getCommandStats() {
        const metrics = this.getMetrics(1000);
        const commands = metrics.filter(m => m.type === 'command');

        const stats = {};
        commands.forEach(cmd => {
            if (!stats[cmd.command]) {
                stats[cmd.command] = {
                    count: 0,
                    totalDuration: 0,
                    successes: 0,
                    failures: 0
                };
            }
            
            stats[cmd.command].count++;
            stats[cmd.command].totalDuration += cmd.duration || 0;
            if (cmd.success) {
                stats[cmd.command].successes++;
            } else {
                stats[cmd.command].failures++;
            }
        });

        return Object.entries(stats).map(([command, data]) => ({
            command,
            count: data.count,
            avgDuration: Math.round(data.totalDuration / data.count),
            successRate: Math.round((data.successes / data.count) * 100)
        }));
    }

    /**
     * Show dashboard
     */
    showDashboard() {
        const stats = this.getCommandStats();
        const metrics = this.getMetrics(100);

        console.log(chalk.bold.cyan('\n📊 BR-CLI Telemetry Dashboard\n'));

        // Top commands
        console.log(chalk.bold('Top Commands:'));
        stats
            .sort((a, b) => b.count - a.count)
            .slice(0, 10)
            .forEach((stat, i) => {
                console.log(
                    chalk.gray(`${i + 1}.`) + ' ' +
                    chalk.yellow(stat.command.padEnd(20)) +
                    chalk.cyan(`${stat.count}x`.padEnd(10)) +
                    chalk.gray(`${stat.avgDuration}ms avg`.padEnd(15)) +
                    chalk.green(`${stat.successRate}% success`)
                );
            });

        // Recent errors
        const errors = metrics.filter(m => m.type === 'error').slice(-5);
        if (errors.length > 0) {
            console.log(chalk.bold('\n\nRecent Errors:'));
            errors.forEach(error => {
                console.log(
                    chalk.red('✗') + ' ' +
                    chalk.gray(error.timestamp) + ' ' +
                    chalk.red(error.error)
                );
            });
        }

        console.log('\n');
    }
}

export default Telemetry;
