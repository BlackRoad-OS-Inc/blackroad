import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { execFile } from 'node:child_process';
import { promisify } from 'node:util';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const exec = promisify(execFile);
const __dirname = path.dirname(fileURLToPath(import.meta.url));
const brPath = path.resolve(__dirname, '..', 'bin', 'br.js');

describe('CLI dispatcher (bin/br.js)', () => {
  it('shows banner when run with no arguments', async () => {
    const { stdout } = await exec('node', [brPath], { timeout: 10000 });
    // Banner includes "Quick Commands:" in the help box
    assert.ok(stdout.includes('Quick Commands'), 'banner should contain Quick Commands text');
  });

  it('shows help with --help', async () => {
    const { stdout } = await exec('node', [brPath, '--help'], { timeout: 10000 });
    assert.ok(stdout.includes('status'), 'help should list status command');
    assert.ok(stdout.includes('deploy'), 'help should list deploy command');
    assert.ok(stdout.includes('health'), 'help should list health command');
    assert.ok(stdout.includes('ssh'), 'help should list ssh command');
  });

  it('shows version with --version', async () => {
    const { stdout } = await exec('node', [brPath, '--version'], { timeout: 10000 });
    assert.match(stdout.trim(), /^\d+\.\d+\.\d+$/);
  });

  it('lists all expected command names in help', async () => {
    const { stdout } = await exec('node', [brPath, '--help'], { timeout: 10000 });
    const expectedCommands = [
      'status',
      'deploy',
      'logs',
      'health',
      'services',
      'open',
      'emoji',
      'agents',
      'notify',
      'quiz',
      'ssh',
      'tunnel',
      'network',
      'cf',
      'git',
      'rw',
      'windows',
      'monitor',
      'docker',
      'db',
      'script',
      'crypto',
      'k8s',
      'logs-agg',
      'inventory',
      'run',
      'telemetry',
      'memory',
    ];
    for (const cmd of expectedCommands) {
      assert.ok(stdout.includes(cmd), `help should list "${cmd}" command`);
    }
  });

  it('exits with error for unknown command', async () => {
    try {
      await exec('node', [brPath, 'nonexistent-command-xyz'], { timeout: 10000 });
      assert.fail('should have thrown');
    } catch (err) {
      // Commander exits with code 1 for unknown commands
      assert.ok(err.code !== 0 || err.stderr.length > 0);
    }
  });

  it('status subcommand accepts --json flag', async () => {
    const { stdout } = await exec('node', [brPath, 'status', '--help'], { timeout: 10000 });
    assert.ok(stdout.includes('--json'), 'status should accept --json flag');
  });

  it('deploy subcommand accepts --all flag', async () => {
    const { stdout } = await exec('node', [brPath, 'deploy', '--help'], { timeout: 10000 });
    assert.ok(stdout.includes('--all'), 'deploy should accept --all flag');
  });

  it('agents subcommand shows all room options', async () => {
    const { stdout } = await exec('node', [brPath, 'agents', '--help'], { timeout: 10000 });
    assert.ok(stdout.includes('--seed'), 'agents should accept --seed');
    assert.ok(stdout.includes('--rounds'), 'agents should accept --rounds');
    assert.ok(stdout.includes('--shuffle'), 'agents should accept --shuffle');
    assert.ok(stdout.includes('--transcript'), 'agents should accept --transcript');
  });
});
