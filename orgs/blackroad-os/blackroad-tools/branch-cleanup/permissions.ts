import { Octokit } from '@octokit/core';

export interface PermissionCheckResult {
  canDelete: boolean;
  canAdmin: boolean;
  autoDeleteEnabled: boolean;
  error?: string;
}

export class PermissionsHandler {
  private octokit: Octokit;
  private issueCache: Set<string> = new Set();

  constructor(octokit: Octokit) {
    this.octokit = octokit;
  }

  async checkPermissions(owner: string, repo: string): Promise<PermissionCheckResult> {
    try {
      const { data } = await this.octokit.request('GET /repos/{owner}/{repo}', {
        owner,
        repo,
      });

      return {
        canDelete: data.permissions?.push || false,
        canAdmin: data.permissions?.admin || false,
        autoDeleteEnabled: data.delete_branch_on_merge || false,
      };
    } catch (error: any) {
      return {
        canDelete: false,
        canAdmin: false,
        autoDeleteEnabled: false,
        error: error.message,
      };
    }
  }

  async enableAutoDelete(owner: string, repo: string, dryRun: boolean = false): Promise<boolean> {
    if (dryRun) {
      console.log(`[DRY-RUN] Would enable auto-delete for ${owner}/${repo}`);
      return true;
    }

    try {
      await this.octokit.request('PATCH /repos/{owner}/{repo}', {
        owner,
        repo,
        delete_branch_on_merge: true,
      });
      console.log(`✓ Enabled auto-delete on merge for ${owner}/${repo}`);
      return true;
    } catch (error: any) {
      if (error.status === 403) {
        console.warn(`⚠ Cannot enable auto-delete for ${owner}/${repo}: insufficient permissions`);
        return false;
      }
      throw error;
    }
  }

  async createPermissionIssue(
    owner: string,
    repo: string,
    blockedCount: number,
    dryRun: boolean = false
  ): Promise<void> {
    const issueKey = `${owner}/${repo}`;
    if (this.issueCache.has(issueKey)) {
      return; // Already created
    }

    const title = 'Grant admin/contents permissions for branch cleanup (+ enable auto-delete)';
    const body = this.generateIssueBody(owner, repo, blockedCount);

    if (dryRun) {
      console.log(`[DRY-RUN] Would create issue in ${owner}/${repo}:`);
      console.log(`Title: ${title}`);
      console.log(`Body preview: ${body.substring(0, 200)}...`);
      this.issueCache.add(issueKey);
      return;
    }

    try {
      // Check if issue already exists
      const { data: existingIssues } = await this.octokit.request('GET /repos/{owner}/{repo}/issues', {
        owner,
        repo,
        state: 'open',
        labels: 'automation,branch-cleanup',
        per_page: 10,
      });

      const exists = existingIssues.some((issue) => issue.title === title);
      if (exists) {
        console.log(`Issue already exists for ${owner}/${repo}`);
        this.issueCache.add(issueKey);
        return;
      }

      // Create new issue
      await this.octokit.request('POST /repos/{owner}/{repo}/issues', {
        owner,
        repo,
        title,
        body,
        labels: ['automation', 'branch-cleanup', 'permissions'],
      });

      console.log(`✓ Created permissions issue for ${owner}/${repo}`);
      this.issueCache.add(issueKey);
    } catch (error: any) {
      console.error(`Failed to create issue for ${owner}/${repo}:`, error.message);
    }
  }

  private generateIssueBody(owner: string, repo: string, blockedCount: number): string {
    return `## Branch Cleanup Permissions Required

The automated branch cleanup tool needs additional permissions to manage merged branches effectively.

### Current Status
- **Blocked branches**: ${blockedCount}
- **Required permissions**: \`Contents: Read & write\`, \`Repository administration: Read & write\`

### Why These Permissions?

1. **Contents (Read & write)**: Delete branch references
2. **Repository administration (Read & write)**: Enable \`delete_branch_on_merge\` setting

### Action Required

#### Option 1: Enable Auto-Delete on Merge (Recommended)

Run this command to automatically delete branches when PRs are merged:

\`\`\`bash
gh api -X PATCH repos/${owner}/${repo} -f delete_branch_on_merge=true
\`\`\`

#### Option 2: Grant Token Permissions

If using a fine-grained PAT for \`BRANCH_CLEANUP_TOKEN\`:

1. Go to: https://github.com/settings/tokens
2. Edit the token used for branch cleanup
3. Under "Repository permissions":
   - Set **Contents** to \`Read & write\`
   - Set **Administration** to \`Read & write\`
4. Save and re-run the cleanup workflow

#### Option 3: GitHub App

If using a GitHub App:

1. Update app permissions to include \`administration:write\` and \`contents:write\`
2. Re-install the app to this repository

### Manual Cleanup Script

If you prefer to clean up branches manually:

\`\`\`bash
# List merged branches
git branch -r --merged origin/main | grep 'bot/\\|claude/\\|codex/'

# Delete specific branch
git push origin --delete branch-name
\`\`\`

### References

- [GitHub API - Update Repository](https://docs.github.com/en/rest/repos/repos#update-a-repository)
- [Fine-grained PAT Permissions](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens#creating-a-fine-grained-personal-access-token)

---

**Note**: This issue was automatically created by the branch cleanup workflow. Close it once permissions are granted.
`;
  }
}
