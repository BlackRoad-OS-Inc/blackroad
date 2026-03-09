# 🛣️ BlackRoad GitHub Workflows System

**Complete CI/CD automation for 15 orgs • 40+ repositories**

---

## 📊 Discovered from Template Document

The BlackRoad GitHub Workflows template provides:

### 1. Repo Type Mapping

| Type | Repos | Workflows |
|------|-------|-----------|
| 🛣️ Core Platform | blackroad-os-web, greenlight-core | base/*, webapp/deploy-cloudflare, webapp/e2e |
| 🌀 Agent & AI | lucidia-core, agent-sdk, cece-agent | base/*, agent/*, python/* |
| 📦 Vertical Packs | edu-pack, media-pack, finance-pack | base/*, webapp/deploy-vercel |
| 🔧 Infrastructure | infra-terraform, k8s-configs | base/*, infra/* |
| 📚 Documentation | docs-main, api-docs, tutorials | base/dependabot, docs/* |
| 📖 Libraries | sdk-js, sdk-python, shared-types | base/*, python/publish OR release |
| ⛓️ Blockchain | roadchain-core, roadcoin-contracts | base/*, python/*, infra/docker |

### 2. Base Workflows (Every Repo)

**ci.yml** - Core CI pipeline
- ⚡ Detect changes (paths-filter)
- 🔍 Lint & format
- 🧪 Test (matrix: Node 18, 20, 22)
- 🏗️ Build
- 🏁 Status check

**release.yml** - Semantic versioning
- 📦 semantic-release
- 📣 NATS announcement
- GreenLight event publishing

**dependabot.yml** - Dependency management
- npm, GitHub Actions, Docker
- Weekly updates
- Auto-grouping by type

**codeql.yml** - Security scanning
- JavaScript/TypeScript analysis
- security-extended queries
- Weekly schedule

**labeler.yml** - Auto-label PRs
- Based on changed files
- Automatic categorization

### 3. GreenLight Integration

Workflows already include:

```yaml
env:
  GREENLIGHT_API: ${{ secrets.GREENLIGHT_API_URL }}
```

```yaml
- name: Notify NATS
  run: |
    curl -X POST "${{ secrets.GREENLIGHT_API }}/events" \
      -H "Content-Type: application/json" \
      -d '{
        "subject": "greenlight.done.macro.platform.${{ github.repository }}",
        "data": {
          "step": "announce",
          "version": "${{ steps.release.outputs.version }}",
          "repo": "${{ github.repository }}",
          "sha": "${{ github.sha }}"
        }
      }'
```

---

## 🎯 Next Steps

1. Extract all workflow templates from document
2. Create workflow generator script
3. Add to blackroad-os-web and priority repos
4. Set up GREENLIGHT_API_URL secret
5. Configure NATS event bus

---

**Source:** BlackRoad_GitHub_Workflows_Template.docx
**Date:** December 23, 2025
**Status:** 📐 PLANNING
