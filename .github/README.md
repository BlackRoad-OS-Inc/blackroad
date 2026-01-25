# GitHub Integration

This repository is integrated with GitHub automation:

## Features

- ✅ **CI/CD Pipeline** - Automatic testing and building
- ✅ **Auto-merge** - Dependabot PRs auto-merge when passing
- ✅ **Issue Templates** - Standardized bug reports and feature requests
- ✅ **PR Templates** - Consistent pull request format
- ✅ **Dependabot** - Automatic dependency updates

## Workflows

### CI Workflow (`.github/workflows/ci.yml`)
- Runs on every push and PR
- Tests, builds, and validates code
- Node.js 18 environment

### Auto-merge Workflow (`.github/workflows/auto-merge.yml`)
- Auto-merges PRs with `automerge` label
- Auto-merges Dependabot PRs when CI passes
- Uses squash merge strategy

## Labels

- `bug` - Bug reports
- `enhancement` - Feature requests
- `dependencies` - Dependency updates
- `automerge` - PRs to auto-merge

---
🤖 Generated with [Claude Code](https://claude.com/claude-code)
