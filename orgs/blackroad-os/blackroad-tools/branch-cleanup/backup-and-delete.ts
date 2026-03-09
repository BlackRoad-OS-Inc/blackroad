import { Octokit } from '@octokit/core';
import dayjs from 'dayjs';

export type DeletionResult =
  | { status: 'Deleted'; backupTag: string }
  | { status: 'ProtectedRuleBlocked'; error: string }
  | { status: 'TokenInsufficient'; error: string }
  | { status: 'AlreadyDeleted'; error: string }
  | { status: 'Error'; error: string };

export interface BackupConfig {
  create_backup_tag: boolean;
  backup_tag_prefix: string;
  backup_ttl_days: number;
}

export class BranchBackupAndDelete {
  private octokit: Octokit;
  private config: BackupConfig;

  constructor(octokit: Octokit, config: BackupConfig) {
    this.octokit = octokit;
    this.config = config;
  }

  async backupAndDelete(
    owner: string,
    repo: string,
    branchName: string,
    sha: string,
    dryRun: boolean = false
  ): Promise<DeletionResult> {
    let backupTag = '';

    try {
      // Step 1: Create backup tag
      if (this.config.create_backup_tag && !dryRun) {
        backupTag = await this.createBackupTag(owner, repo, branchName, sha);
      } else if (this.config.create_backup_tag && dryRun) {
        backupTag = this.getBackupTagName(branchName);
      }

      // Step 2: Delete branch
      if (!dryRun) {
        await this.deleteBranch(owner, repo, branchName);
      }

      return { status: 'Deleted', backupTag };
    } catch (error: any) {
      return this.handleDeletionError(error);
    }
  }

  private async createBackupTag(
    owner: string,
    repo: string,
    branchName: string,
    sha: string
  ): Promise<string> {
    const tagName = this.getBackupTagName(branchName);
    const message = `Backup tag for branch ${branchName} before cleanup\nCreated: ${dayjs().toISOString()}\nTTL: ${this.config.backup_ttl_days} days`;

    // Create annotated tag object
    const { data: tagObject } = await this.octokit.request('POST /repos/{owner}/{repo}/git/tags', {
      owner,
      repo,
      tag: tagName,
      message,
      object: sha,
      type: 'commit',
    });

    // Create reference to the tag
    await this.octokit.request('POST /repos/{owner}/{repo}/git/refs', {
      owner,
      repo,
      ref: `refs/tags/${tagName}`,
      sha: tagObject.sha,
    });

    return tagName;
  }

  private async deleteBranch(owner: string, repo: string, branchName: string): Promise<void> {
    await this.octokit.request('DELETE /repos/{owner}/{repo}/git/refs/{ref}', {
      owner,
      repo,
      ref: `heads/${branchName}`,
    });
  }

  private getBackupTagName(branchName: string): string {
    const sanitizedBranch = branchName.replace(/\//g, '-');
    const date = dayjs().format('YYYYMMDD');
    return `${this.config.backup_tag_prefix}/${sanitizedBranch}/${date}`;
  }

  private handleDeletionError(error: any): DeletionResult {
    const status = error.status || 0;
    const message = error.message || String(error);

    // 403 Forbidden
    if (status === 403) {
      if (message.toLowerCase().includes('protected')) {
        return { status: 'ProtectedRuleBlocked', error: message };
      }
      if (message.toLowerCase().includes('resource not accessible')) {
        return { status: 'TokenInsufficient', error: message };
      }
      return { status: 'TokenInsufficient', error: message };
    }

    // 422 Unprocessable (ref doesn't exist)
    if (status === 422) {
      return { status: 'AlreadyDeleted', error: 'Branch reference not found' };
    }

    // 404 Not Found
    if (status === 404) {
      return { status: 'AlreadyDeleted', error: 'Branch not found' };
    }

    return { status: 'Error', error: message };
  }

  async pruneExpiredBackupTags(owner: string, repo: string, dryRun: boolean = false): Promise<number> {
    const cutoffDate = dayjs().subtract(this.config.backup_ttl_days, 'days');
    let prunedCount = 0;

    try {
      // List all tags
      const { data: tags } = await this.octokit.request('GET /repos/{owner}/{repo}/tags', {
        owner,
        repo,
        per_page: 100,
      });

      for (const tag of tags) {
        if (!tag.name.startsWith(this.config.backup_tag_prefix)) {
          continue;
        }

        // Extract date from tag name (format: cleanup-backup/branch-name/YYYYMMDD)
        const datePart = tag.name.split('/').pop();
        if (!datePart || datePart.length !== 8) {
          continue;
        }

        const tagDate = dayjs(datePart, 'YYYYMMDD');
        if (tagDate.isValid() && tagDate.isBefore(cutoffDate)) {
          if (!dryRun) {
            await this.octokit.request('DELETE /repos/{owner}/{repo}/git/refs/{ref}', {
              owner,
              repo,
              ref: `tags/${tag.name}`,
            });
          }
          prunedCount++;
        }
      }
    } catch (error) {
      console.error('Error pruning backup tags:', error);
    }

    return prunedCount;
  }
}
