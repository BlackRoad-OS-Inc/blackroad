#!/usr/bin/env node

import fs from 'fs';
import path from 'path';
import yaml from 'yaml';
import pLimit from 'p-limit';
import dayjs from 'dayjs';
import { GitHubQLClient } from './ghql.js';
import { BranchBackupAndDelete } from './backup-and-delete.js';
import { PermissionsHandler } from './permissions.js';
import { Reporter, CleanupRecord, ActionTaken } from './reporters.js';

interface Config {
  orgs: Array<{ name: string; repos: string[] }>;
  branch_patterns: string[];
  exclude_patterns: string[];
  safety: {
    create_backup_tag: boolean;
    backup_tag_prefix: string;
    backup_ttl_days: number;
    minimum_age_days: number;
  };
  rate_limits: {
    max_concurrency: number;
    per_repo_delay_ms: number;
  };
  reporting: {
    out_dir: string;
    write_json: boolean;
    write_csv: boolean;
  };
}

interface BranchCandidate {
  branchName: string;
  sha: string;
  prNumber: number | null;
  mergedAt: string | null;
}

class CleanupOrchestrator {
  private config: Config;
  private ghClient: GitHubQLClient;
  private backupDeleter: BranchBackupAndDelete;
  private permHandler: PermissionsHandler;
  private reporter: Reporter;
  private dryRun: boolean;

  constructor(config: Config, token: string, dryRun: boolean = false) {
    this.config = config;
    this.dryRun = dryRun;

    this.ghClient = new GitHubQLClient(token);
    const octokit = this.ghClient.getOctokit();

    this.backupDeleter = new BranchBackupAndDelete(octokit, config.safety);
    this.permHandler = new PermissionsHandler(octokit);
    this.reporter = new Reporter(config.reporting);
  }

  async run(): Promise<void> {
    console.log('🚀 Starting branch cleanup...');
    console.log(`Mode: ${this.dryRun ? 'DRY-RUN' : 'LIVE'}`);
    console.log('');

    const limit = pLimit(this.config.rate_limits.max_concurrency);
    const tasks: Promise<void>[] = [];

    for (const org of this.config.orgs) {
      for (const repo of org.repos) {
        tasks.push(limit(() => this.processRepo(org.name, repo)));
      }
    }

    await Promise.all(tasks);

    console.log('');
    console.log('📊 Writing reports...');
    await this.reporter.writeReports(this.dryRun);

    if (this.reporter.hasErrors()) {
      console.error('⚠ Cleanup completed with errors');
      process.exit(1);
    }

    console.log('✓ Cleanup completed successfully');
  }

  private async processRepo(owner: string, repo: string): Promise<void> {
    console.log(`\n📦 Processing ${owner}/${repo}...`);

    try {
      // Check permissions
      const perms = await this.permHandler.checkPermissions(owner, repo);
      if (!perms.canDelete) {
        console.warn(`  ⚠ Insufficient permissions for ${owner}/${repo}`);
        return;
      }

      // Get default branch
      const defaultBranch = await this.ghClient.getDefaultBranch(owner, repo);
      console.log(`  Default branch: ${defaultBranch}`);

      // Find candidates
      const candidates = await this.findCandidates(owner, repo, defaultBranch);
      console.log(`  Found ${candidates.length} candidate branches`);

      if (candidates.length === 0) {
        return;
      }

      // Process each candidate
      let blockedCount = 0;
      for (const candidate of candidates) {
        await this.delay(this.config.rate_limits.per_repo_delay_ms);

        const result = await this.processBranch(
          owner,
          repo,
          defaultBranch,
          candidate
        );

        if (result.actionTaken === 'ProtectedRuleBlocked' || result.actionTaken === 'TokenInsufficient') {
          blockedCount++;
        }

        this.reporter.addRecord(result);
      }

      // Try to enable auto-delete
      if (!perms.autoDeleteEnabled) {
        const enabled = await this.permHandler.enableAutoDelete(owner, repo, this.dryRun);
        if (!enabled && blockedCount > 0) {
          await this.permHandler.createPermissionIssue(owner, repo, blockedCount, this.dryRun);
        }
      }

    } catch (error: any) {
      console.error(`  ✗ Error processing ${owner}/${repo}:`, error.message);
    }
  }

  private async findCandidates(
    owner: string,
    repo: string,
    defaultBranch: string
  ): Promise<BranchCandidate[]> {
    const mergedPRs = await this.ghClient.getMergedPRs(owner, repo);
    const candidates = new Map<string, BranchCandidate>();

    for (const pr of mergedPRs) {
      // Skip if not targeting default branch
      if (pr.baseRefName !== defaultBranch) {
        continue;
      }

      // Check if matches patterns
      if (!this.matchesPatterns(pr.headRefName)) {
        continue;
      }

      // Skip if excluded
      if (this.isExcluded(pr.headRefName)) {
        continue;
      }

      // Use the most recent PR for each branch
      if (!candidates.has(pr.headRefName)) {
        candidates.set(pr.headRefName, {
          branchName: pr.headRefName,
          sha: pr.headRefOid,
          prNumber: pr.number,
          mergedAt: pr.mergedAt,
        });
      }
    }

    return Array.from(candidates.values());
  }

  private async processBranch(
    owner: string,
    repo: string,
    defaultBranch: string,
    candidate: BranchCandidate
  ): Promise<CleanupRecord> {
    const baseRecord: Partial<CleanupRecord> = {
      org: owner,
      repo,
      branch: candidate.branchName,
      headSha: candidate.sha,
      mergedPr: candidate.prNumber,
      mergedAt: candidate.mergedAt,
      defaultBranch,
      backupTag: '',
      error: '',
    };

    // Check if branch still exists
    const branchInfo = await this.ghClient.checkBranch(owner, repo, candidate.branchName);
    baseRecord.protected = branchInfo.protected;

    if (!branchInfo.exists) {
      return {
        ...baseRecord,
        actionTaken: 'AlreadyDeleted',
        protected: false,
      } as CleanupRecord;
    }

    // Check if protected
    if (branchInfo.protected) {
      return {
        ...baseRecord,
        actionTaken: 'SkippedProtected',
      } as CleanupRecord;
    }

    // Check age
    if (candidate.mergedAt) {
      const mergedDate = dayjs(candidate.mergedAt);
      const ageInDays = dayjs().diff(mergedDate, 'days');

      if (ageInDays < this.config.safety.minimum_age_days) {
        return {
          ...baseRecord,
          actionTaken: 'SkippedTooRecent',
          error: `Only ${ageInDays} days old`,
        } as CleanupRecord;
      }
    }

    // Check reachability (safety check)
    const isReachable = await this.ghClient.isBranchReachable(
      owner,
      repo,
      defaultBranch,
      candidate.branchName
    );

    if (!isReachable) {
      return {
        ...baseRecord,
        actionTaken: 'SkippedUnsafe',
        error: 'Branch has commits not in default branch',
      } as CleanupRecord;
    }

    // Delete the branch
    const result = await this.backupDeleter.backupAndDelete(
      owner,
      repo,
      candidate.branchName,
      candidate.sha,
      this.dryRun
    );

    return {
      ...baseRecord,
      actionTaken: result.status as ActionTaken,
      backupTag: 'backupTag' in result ? result.backupTag : '',
      error: 'error' in result ? result.error : '',
    } as CleanupRecord;
  }

  private matchesPatterns(branchName: string): boolean {
    return this.config.branch_patterns.some((pattern) => {
      const regex = new RegExp('^' + pattern.replace('*', '.*') + '$');
      return regex.test(branchName);
    });
  }

  private isExcluded(branchName: string): boolean {
    return this.config.exclude_patterns.some((pattern) => {
      const regex = new RegExp('^' + pattern.replace('*', '.*') + '$');
      return regex.test(branchName);
    });
  }

  private async delay(ms: number): Promise<void> {
    return new Promise((resolve) => setTimeout(resolve, ms));
  }
}

// Main execution
async function main() {
  const args = process.argv.slice(2);
  const dryRun = args.includes('--dry-run');

  // Load config
  const configPath = path.join(process.cwd(), 'tools/branch-cleanup/config.yaml');
  const configContent = fs.readFileSync(configPath, 'utf8');
  const config: Config = yaml.parse(configContent);

  // Get token
  const token = process.env.BRANCH_CLEANUP_TOKEN || process.env.GITHUB_TOKEN;
  if (!token) {
    console.error('Error: BRANCH_CLEANUP_TOKEN or GITHUB_TOKEN environment variable required');
    process.exit(1);
  }

  // Run cleanup
  const orchestrator = new CleanupOrchestrator(config, token, dryRun);
  await orchestrator.run();
}

main().catch((error) => {
  console.error('Fatal error:', error);
  process.exit(1);
});
