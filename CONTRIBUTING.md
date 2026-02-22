# Contributing to blackroad-operator

> **All contributions are proprietary work-for-hire owned exclusively by BlackRoad OS, Inc.**

## Getting Started

1. Clone the repo: `git clone https://github.com/BlackRoad-OS-Inc/blackroad-operator.git`
2. Create a branch: `git checkout -b feat/your-feature`
3. Make your changes and commit
4. Open a Pull Request against `main`

## Branch Naming

| Type | Pattern | Example |
|------|---------|---------|
| Feature | `feat/description` | `feat/add-oauth` |
| Fix | `fix/description` | `fix/memory-leak` |
| Chore | `chore/description` | `chore/update-deps` |
| Docs | `docs/description` | `docs/update-readme` |

## Commit Style

Use conventional commits:
```
feat: add new agent routing logic
fix: resolve memory leak in gateway
docs: update API reference
chore: bump dependencies
```

## Pull Request Requirements

- [ ] All CI checks pass
- [ ] Code reviewed by at least 1 team member
- [ ] Tests added/updated for new behavior
- [ ] CHANGELOG.md updated

## Code Style

- Prettier for formatting (`.prettierrc` at repo root)
- ESLint / shellcheck for linting
- No secrets or credentials in code

## Questions?

Reach out via GitHub Issues or `blackroad.systems@gmail.com`

---
© BlackRoad OS, Inc. All rights reserved.
