# BlackRoad Auto-Scraper Pipeline 🤖

**Intelligent GitHub scraper + generator system that automatically maps projects to domains**

---

## 🎯 What It Does

This pipeline automatically:
1. **Scrapes** all repos from 15 BlackRoad GitHub organizations
2. **Categorizes** projects by type (AI, quantum, infrastructure, etc.)
3. **Maps** projects to appropriate domains intelligently
4. **Generates** website features (stats, featured projects, product sections)
5. **Validates** everything isn't stupid (quality checks)
6. **Exports** real data to HTML templates
7. **Logs** results to [MEMORY]

---

## 🚀 Quick Start

### One Command Deployment:
```bash
./run-scraper-pipeline.sh
```

This runs the entire pipeline:
- Scrapes 15 GitHub orgs
- Maps to 19 domains
- Generates features
- Validates quality
- Exports to sites
- Updates HTML templates

---

## 📁 Files

| File | Purpose |
|------|---------|
| `scrape-github-projects.py` | Scrapes GitHub repos using `gh` CLI |
| `generate-website-features.py` | Creates features for each domain |
| `validate-and-export.py` | Quality checks + export to sites |
| `update-html-templates.py` | Injects real data into HTML |
| `run-scraper-pipeline.sh` | Master pipeline orchestrator |
| `github-projects-scraped.json` | Raw scraped data (output) |
| `website-features-generated.json` | Generated features (output) |
| `validation-report.json` | Quality report (output) |
| `sites/*/features.json` | Per-domain feature data (output) |

---

## 🏗️ Architecture

```
GitHub (15 orgs)
    ↓
scrape-github-projects.py
    ↓
github-projects-scraped.json (raw data)
    ↓
generate-website-features.py
    ↓
website-features-generated.json (structured features)
    ↓
validate-and-export.py
    ↓
sites/*/features.json (per-domain)
    ↓
update-html-templates.py
    ↓
sites/*/index.html (updated HTML)
```

---

## 🔍 Scraping Details

### Organizations Scraped:
1. BlackRoad-OS
2. BlackRoad-AI
3. BlackRoad-Archive
4. BlackRoad-Cloud
5. BlackRoad-Education
6. BlackRoad-Foundation
7. BlackRoad-Gov
8. BlackRoad-Hardware
9. BlackRoad-Interactive
10. BlackRoad-Labs
11. BlackRoad-Media
12. BlackRoad-Security
13. BlackRoad-Studio
14. BlackRoad-Ventures
15. Blackbox-Enterprises

### Project Categories:
- **infrastructure**: deploy, infra, ops, cluster, k8s, docker
- **ai**: ai, agent, ml, model, intelligence
- **quantum**: quantum, qubit, qc
- **blockchain**: blockchain, chain, crypto, web3
- **frontend**: react, next, frontend, ui, web
- **backend**: api, backend, server, service
- **tools**: cli, tool, utility, script
- **docs**: docs, documentation, guide, tutorial
- **template**: template, boilerplate, starter
- **brand**: brand, design, logo, identity

### Domain Mapping Keywords:
- **blackboxprogramming.io**: programming, code, enterprise, sdk, api, framework, library
- **blackroadai.com**: ai, agent, ml, machine-learning, neural, model, intelligence
- **blackroadquantum.com**: quantum, qubit, qc, quantum-computing
- **roadchain.io**: blockchain, chain, ledger, crypto, web3
- **lucidia.earth**: lucidia, metaverse, virtual, world, 3d
- *(and more...)*

---

## ✅ Validation Checks

The pipeline runs these quality checks:

### Critical (Errors):
- ❌ Domain has ZERO projects (very stupid!)

### Warnings:
- ⚠️  No featured projects
- ⚠️  Projects missing descriptions
- ⚠️  No product sections
- ⚠️  No programming languages detected

### Stupid Checks (Sanity):
- 🤔 Stats mismatch (total_repos vs total_projects)
- 🤔 Featured project has no URL
- 🤔 Category count doesn't match actual categories

---

## 📊 Generated Features

For each domain, the pipeline generates:

### Stats Section:
```json
{
  "total_repos": 42,
  "active_projects": 38,
  "languages": 8,
  "categories": 5
}
```

### Featured Projects (top 6):
```json
[
  {
    "name": "blackroad-os-carpool",
    "description": "Multi-AI orchestration platform...",
    "url": "https://github.com/...",
    "language": "TypeScript",
    "categories": ["ai", "infrastructure"],
    "icon": "◆"
  }
]
```

### Products Section (grouped by category):
```json
[
  {
    "category": "AI",
    "projects": [
      {
        "name": "project-1",
        "description": "...",
        "url": "..."
      }
    ]
  }
]
```

---

## 🎨 HTML Integration

The `update-html-templates.py` script injects real data into placeholders:

### Before:
```html
<div class="stat-value">[000]</div>
<div class="stat-label">[Stat Label 1]</div>
```

### After:
```html
<div class="stat-value">42</div>
<div class="stat-label">Total Repositories</div>
```

---

## 🛠️ Manual Usage

### Step 1: Scrape GitHub
```bash
python3 scrape-github-projects.py
```
**Output:** `github-projects-scraped.json`

### Step 2: Generate Features
```bash
python3 generate-website-features.py
```
**Output:** `website-features-generated.json`

### Step 3: Validate & Export
```bash
python3 validate-and-export.py
```
**Output:** `validation-report.json` + `sites/*/features.json`

### Step 4: Update HTML
```bash
python3 update-html-templates.py
```
**Output:** Updated `sites/*/index.html` files

---

## 📈 Current Results

**Last Run:** 2025-12-28 18:10:01

| Metric | Value |
|--------|-------|
| Total Projects Scraped | 4 |
| Organizations Scraped | 15 |
| Domains Mapped | 2 |
| Sites Exported | 2 |
| Validation Status | ⚠️  PASSED WITH WARNINGS |

### Domains with Projects:
- **blackroadai.com**: 3 projects
- **blackroad.systems**: 1 project

### Warnings:
- `blackroad.systems`: No product sections
- `blackroadai.com`: 2 projects missing descriptions

---

## 🔧 Configuration

### Adding New Organizations:
Edit `scrape-github-projects.py`:
```python
ORGANIZATIONS = [
    "BlackRoad-OS",
    "YourNewOrg",  # Add here
]
```

### Adding New Domain Keywords:
Edit `scrape-github-projects.py`:
```python
DOMAIN_KEYWORDS = {
    "yournewdomain.com": ["keyword1", "keyword2"],
}
```

### Adding New Categories:
Edit `scrape-github-projects.py`:
```python
CATEGORIES = {
    "yourcategory": ["keyword1", "keyword2"],
}
```

---

## 🧪 Testing

### Check scraped data:
```bash
cat github-projects-scraped.json | python3 -m json.tool | less
```

### Check generated features:
```bash
cat website-features-generated.json | python3 -m json.tool | less
```

### Check validation report:
```bash
cat validation-report.json | python3 -m json.tool | less
```

### Check exported features for a domain:
```bash
cat sites/blackroadai.com/features.json | python3 -m json.tool
```

---

## 🚨 Troubleshooting

### "gh: command not found"
Install GitHub CLI:
```bash
brew install gh
gh auth login
```

### "No projects scraped"
- Check GitHub authentication: `gh auth status`
- Verify organization access
- Check if repos are public

### "Validation failed"
Review `validation-report.json` for details:
```bash
cat validation-report.json | python3 -m json.tool
```

### "Sites not updated"
Ensure features.json exists:
```bash
find sites -name "features.json"
```

---

## 🔄 Workflow

### Daily Updates:
```bash
# Update all domains with latest GitHub data
./run-scraper-pipeline.sh

# Deploy updated sites
./deploy-all-domains.sh
```

### Adding New Project:
1. Push to GitHub
2. Run pipeline: `./run-scraper-pipeline.sh`
3. Project auto-maps to correct domain(s)
4. Deploy: `./deploy-all-domains.sh`

---

## 📝 Output Format

### github-projects-scraped.json
```json
{
  "scraped_at": "2025-12-28T18:10:01",
  "total_orgs": 15,
  "total_projects": 42,
  "projects": [...]
}
```

### website-features-generated.json
```json
{
  "generated_at": "2025-12-28T18:10:01",
  "total_domains": 19,
  "features": {
    "domain.com": {
      "total_projects": 5,
      "featured_projects": [...],
      "products_section": [...],
      "stats": {...}
    }
  }
}
```

### validation-report.json
```json
{
  "validated_at": "2025-12-28T18:10:01",
  "validation_summary": {
    "passed": 15,
    "warnings": 3,
    "errors": 0
  },
  "validation_details": {...}
}
```

---

## 🎯 Next Steps

1. **Add more orgs**: Include more GitHub organizations
2. **Better categorization**: Improve keyword matching
3. **Image scraping**: Extract repo images/screenshots
4. **README parsing**: Extract detailed descriptions from README files
5. **Contributor stats**: Add contributor counts, commit frequency
6. **Language stats**: Show language distribution charts
7. **Live data**: Run daily via cron job

---

## 📚 Integration with Main Deployment

The scraper pipeline integrates with the main deployment:

```bash
# 1. Scrape and generate features
./run-scraper-pipeline.sh

# 2. Deploy all domains
./deploy-all-domains.sh

# 3. Configure DNS
./configure-dns.sh

# 4. Test deployments
./test-all-domains.sh
```

---

**Generated:** 2025-12-28
**Status:** ✅ Operational
**Projects Tracked:** 4+ (growing)
**Domains Mapped:** 2+ (growing)
