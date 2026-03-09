# Branch Cleanup System

Automated, safe, and observable cleanup system for merged bot branches across multiple repositories.

## 🎯 Purpose

This tool addresses the **~2,463 merged bot branches** issue by:

1. ✅ Finding merged bot branches across multiple repos
2. ✅ Safely deleting them with backup tags
3. ✅ Handling permission issues gracefully
4. ✅ Enabling `delete_branch_on_merge` for future prevention
5. ✅ Generating comprehensive reports

## 🚀 Quick Start

### Prerequisites

- Node.js >= 20
- GitHub token with appropriate permissions (see [Permissions](#permissions))

### Local Usage

```bash
# Dry-run (preview what would be deleted)
make branch-cleanup-dry

# Execute cleanup (requires BRANCH_CLEANUP_TOKEN)
make branch-cleanup-run

# View reports
make branch-cleanup-report
```

### GitHub Action

The cleanup runs **nightly at 03:17 UTC** in dry-run mode by default.

To run manually:
1. Go to Actions → Branch Cleanup
2. Click "Run workflow"
3. Set `dry_run: false` for live execution

## 📋 Configuration

Edit `tools/branch-cleanup/config.yaml`:

```yaml
orgs:
  - name: blackboxprogramming
    repos: [ "blackroad-prism-console", "blackroad-api" ]

branch_patterns:
  - "claude/*"
  - "codex/*"
  - "bot/*"
  - "dependabot/*"

safety:
  minimum_age_days: 7  # Only delete branches merged ≥7 days ago
  create_backup_tag: true
  backup_ttl_days: 30
```

## 🔒 Permissions

### Required Scopes

For a **fine-grained Personal Access Token** (recommended):

| Permission | Access Level | Purpose |
|------------|--------------|---------|
| Contents | Read & write | Delete branch references |
| Pull Requests | Read | Query merged PRs |
| Issues | Write | Create permission issues |
| Administration | Read & write | Enable `delete_branch_on_merge` |

### Creating the Token

1. Go to: https://github.com/settings/tokens?type=beta
2. Click "Generate new token"
3. Set permissions as above
4. Select repositories to grant access
5. Generate and copy token

### Setting in GitHub Actions

1. Go to repository Settings → Secrets and variables → Actions
2. Create new secret: `BRANCH_CLEANUP_TOKEN`
3. Paste your token
4. Save

## 🛡️ Safety Features

### 1. Backup Tags

Before deletion, an **annotated tag** is created:

```
cleanup-backup/claude-feature-xyz/20251110
```

Tags are retained for **30 days**, allowing easy branch recovery:

```bash
# Recover a deleted branch
git checkout -b recovered-branch cleanup-backup/claude-feature-xyz/20251110
git push origin recovered-branch
```

### 2. Reachability Check

Branches are **only** deleted if:
- They have a merged PR into the default branch
- Their HEAD commit is reachable from the default branch
- They are not protected
- They are at least 7 days old (configurable)

### 3. Pattern Matching

Only branches matching configured patterns are considered:

```yaml
branch_patterns:
  - "claude/*"
  - "codex/*"
  - "bot/*"

exclude_patterns:
  - "main"
  - "master"
  - "release/*"
```

### 4. Dry-Run Mode

Always preview changes before executing:

```bash
make branch-cleanup-dry
```

## 📊 Reports

Reports are generated in `ops/reports/branch-cleanup/<timestamp>/`:

### Files

- **report.json**: Complete data with metadata
- **report.csv**: Spreadsheet-friendly format
- **summary.txt**: Human-readable summary

### Example Summary

```
================================================================================
BRANCH CLEANUP REPORT
================================================================================

Timestamp: 2025-11-10 03:17:42
Duration: 45.23s

Overall Summary:
  Total branches processed: 2463
  Deleted: 2401
  Skipped: 58
  Errors: 4

By Status:
  Deleted: 2401
  SkippedProtected: 12
  SkippedTooRecent: 38
  SkippedUnsafe: 8
  TokenInsufficient: 4

By Repository:
  blackboxprogramming/blackroad-prism-console: 1845
  blackboxprogramming/blackroad-api: 556
  BlackRoad-AI/BlackRoad.io: 62
```

## 🔧 Operator Playbook

### Permission Denied (403)

**Symptom**: `TokenInsufficient` in reports

**Fix**:
1. Check token scopes include `Administration: Read & write`
2. Verify token has access to the repository
3. Create new token if needed

### Branch Protected

**Symptom**: `ProtectedRuleBlocked` in reports

**Fix**:
1. Review branch protection rules
2. Either:
   - Adjust protection rule to exclude bot branches
   - Leave protected branches as-is

### Enable Auto-Delete Manually

```bash
# Per repository
gh api -X PATCH repos/OWNER/REPO -f delete_branch_on_merge=true

# Or via web UI:
# Settings → General → Pull Requests →
# ✅ Automatically delete head branches
```

### Prune Expired Backup Tags

```bash
# TODO: Add weekly job for this
# For now, manual:
git tag -l "cleanup-backup/*" | \
  xargs -I {} git tag -d {}
git push origin --delete $(git tag -l "cleanup-backup/*")
```

## 🧪 Testing

### Unit Tests

```bash
npm test
```

### Integration Test (Dry-Run)

```bash
# Against real repos, no deletions
make branch-cleanup-dry

# Check reports
ls -la ops/reports/branch-cleanup/
```

### Live Test

1. Create test repo with seeded branches
2. Run dry-run
3. Verify CSV/JSON accuracy
4. Run live execution
5. Confirm branches deleted + tags created

## 📈 Metrics

### Throughput

- **Concurrency**: 10 parallel operations
- **Rate limit**: 250ms delay between operations
- **Expected time for 2,463 branches**: ~5-10 minutes

### API Usage

- GraphQL queries: ~25 per repo
- REST calls: 2-3 per branch (check + delete)
- Well under GitHub's 5,000 requests/hour limit

## 🚨 Troubleshooting

### "No branches found"

**Cause**: Branch patterns don't match any branches

**Fix**: Update `config.yaml` patterns

### "BRANCH_CLEANUP_TOKEN not found"

**Cause**: Environment variable not set

**Fix**:
```bash
export BRANCH_CLEANUP_TOKEN=ghp_...
# or in GitHub Actions: add secret
```

### Cleanup takes too long

**Cause**: Too many concurrent operations

**Fix**: Reduce `max_concurrency` in config

### Exit code 1

**Cause**: Errors detected during cleanup

**Fix**: Check `report.json` for error details

## 🔄 Recurring Automation

### Nightly Schedule

The workflow runs daily at 03:17 UTC in **dry-run mode**.

To enable automatic cleanup:
1. Edit `.github/workflows/branch-cleanup.yml`
2. Change schedule trigger to run live:
   ```yaml
   - name: Run cleanup (live)
     if: github.event_name == 'schedule'
   ```

### Recommended Approach

1. Run dry-run nightly
2. Review reports weekly
3. Execute live cleanup monthly (manual trigger)
4. Enable auto-delete on all repos to prevent buildup

## 📚 Architecture

```
cleanup.ts (orchestrator)
  ├─ ghql.ts (GitHub API)
  ├─ backup-and-delete.ts (branch operations)
  ├─ permissions.ts (access control)
  └─ reporters.ts (output generation)
```

### Flow

1. Load config
2. For each repository:
   - Query merged PRs
   - Filter by patterns & age
   - Check reachability
   - Create backup tag
   - Delete branch
   - Update report
3. Attempt to enable auto-delete
4. Generate reports
5. Upload artifacts (GitHub Actions)

## 🎁 Stretch Goals

- [ ] Comment on PRs when branches are deleted
- [ ] Status badge in README
- [ ] Weekly tag-prune job
- [ ] Slack/Discord notifications
- [ ] Branch size metrics

## 📞 Support

Issues or questions? Create a GitHub issue with:
- Report files (JSON + CSV)
- Command output
- Token permissions screenshot

## 📄 License

Part of BlackRoad Prism Console. See repository LICENSE.

---

**Last Updated**: 2025-11-10
**Version**: 1.0.0
**Maintainer**: @blackboxprogramming
