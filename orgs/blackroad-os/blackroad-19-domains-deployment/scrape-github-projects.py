#!/usr/bin/env python3

"""
BlackRoad GitHub Projects Scraper
Scrapes all repos from BlackRoad orgs and categorizes them
"""

import json
import subprocess
import re
from pathlib import Path
from datetime import datetime

# GitHub Organizations to scrape
ORGANIZATIONS = [
    "BlackRoad-OS",
    "BlackRoad-AI",
    "BlackRoad-Archive",
    "BlackRoad-Cloud",
    "BlackRoad-Education",
    "BlackRoad-Foundation",
    "BlackRoad-Gov",
    "BlackRoad-Hardware",
    "BlackRoad-Interactive",
    "BlackRoad-Labs",
    "BlackRoad-Media",
    "BlackRoad-Security",
    "BlackRoad-Studio",
    "BlackRoad-Ventures",
    "Blackbox-Enterprises"
]

# Domain mapping keywords
DOMAIN_KEYWORDS = {
    "blackboxprogramming.io": ["programming", "code", "enterprise", "sdk", "api", "framework", "library"],
    "blackroad.company": ["company", "corporate", "business", "brand", "overview"],
    "blackroad.network": ["network", "distributed", "mesh", "infrastructure", "cluster"],
    "blackroad.systems": ["system", "infrastructure", "deployment", "devops", "ops", "cloud"],
    "blackroadai.com": ["ai", "agent", "ml", "machine-learning", "neural", "model", "intelligence"],
    "blackroadqi.com": ["qi", "quantum-ai", "hybrid", "quantum-ml"],
    "blackroadquantum.com": ["quantum", "qubit", "qc", "quantum-computing"],
    "blackroadquantum.info": ["quantum-docs", "quantum-guide", "quantum-tutorial"],
    "blackroadquantum.net": ["quantum-network", "quantum-mesh"],
    "blackroadquantum.shop": ["quantum-product", "quantum-service"],
    "lucidia.earth": ["lucidia", "metaverse", "virtual", "world", "3d"],
    "lucidia.studio": ["creative", "design", "art", "studio", "visual"],
    "lucidiaqi.com": ["lucidia-ai", "metaverse-ai"],
    "roadchain.io": ["blockchain", "chain", "ledger", "crypto", "web3"],
    "roadcoin.io": ["coin", "token", "currency", "wallet"],
}

# Project categories
CATEGORIES = {
    "infrastructure": ["deploy", "infra", "ops", "cluster", "k8s", "docker"],
    "ai": ["ai", "agent", "ml", "model", "intelligence"],
    "quantum": ["quantum", "qubit", "qc"],
    "blockchain": ["blockchain", "chain", "crypto", "web3"],
    "frontend": ["react", "next", "frontend", "ui", "web"],
    "backend": ["api", "backend", "server", "service"],
    "tools": ["cli", "tool", "utility", "script"],
    "docs": ["docs", "documentation", "guide", "tutorial"],
    "template": ["template", "boilerplate", "starter"],
    "brand": ["brand", "design", "logo", "identity"]
}

print("🔍 BlackRoad GitHub Projects Scraper")
print("=" * 60)

all_projects = []

for org in ORGANIZATIONS:
    print(f"\n📦 Scraping: {org}")

    # Use gh CLI to list repos
    try:
        result = subprocess.run(
            ["gh", "repo", "list", org, "--limit", "1000", "--json", "name,description,url,createdAt,updatedAt,primaryLanguage,isArchived"],
            capture_output=True,
            text=True,
            timeout=30
        )

        if result.returncode == 0:
            repos = json.loads(result.stdout)
            print(f"   Found {len(repos)} repositories")

            for repo in repos:
                # Skip archived repos
                if repo.get('isArchived'):
                    continue

                project = {
                    "org": org,
                    "name": repo['name'],
                    "description": repo.get('description', ''),
                    "url": repo['url'],
                    "language": repo.get('primaryLanguage', {}).get('name', 'Unknown'),
                    "created": repo['createdAt'],
                    "updated": repo['updatedAt'],
                    "categories": [],
                    "domains": []
                }

                # Categorize project
                repo_text = f"{repo['name']} {repo.get('description', '')}".lower()

                for category, keywords in CATEGORIES.items():
                    if any(keyword in repo_text for keyword in keywords):
                        project["categories"].append(category)

                # Map to domains
                for domain, keywords in DOMAIN_KEYWORDS.items():
                    if any(keyword in repo_text for keyword in keywords):
                        project["domains"].append(domain)

                # Default domain mapping by org
                if not project["domains"]:
                    if "quantum" in org.lower():
                        project["domains"].append("blackroadquantum.com")
                    elif "ai" in org.lower():
                        project["domains"].append("blackroadai.com")
                    elif "blackbox" in org.lower():
                        project["domains"].append("blackboxprogramming.io")
                    else:
                        project["domains"].append("blackroad.company")

                all_projects.append(project)
        else:
            print(f"   ❌ Error: {result.stderr}")

    except subprocess.TimeoutExpired:
        print(f"   ⚠️  Timeout (skipping)")
    except Exception as e:
        print(f"   ❌ Error: {e}")

print("\n" + "=" * 60)
print(f"✅ Scraped {len(all_projects)} active projects")

# Save raw data
output_file = Path("github-projects-scraped.json")
with output_file.open('w') as f:
    json.dump({
        "scraped_at": datetime.now().isoformat(),
        "total_orgs": len(ORGANIZATIONS),
        "total_projects": len(all_projects),
        "projects": all_projects
    }, f, indent=2)

print(f"💾 Saved to: {output_file}")

# Generate statistics
print("\n📊 Statistics:")
print(f"   Total projects: {len(all_projects)}")

# By organization
org_counts = {}
for project in all_projects:
    org_counts[project['org']] = org_counts.get(project['org'], 0) + 1

print("\n   By Organization:")
for org, count in sorted(org_counts.items(), key=lambda x: x[1], reverse=True):
    print(f"      {org}: {count}")

# By category
category_counts = {}
for project in all_projects:
    for category in project['categories']:
        category_counts[category] = category_counts.get(category, 0) + 1

print("\n   By Category:")
for category, count in sorted(category_counts.items(), key=lambda x: x[1], reverse=True):
    print(f"      {category}: {count}")

# By domain
domain_counts = {}
for project in all_projects:
    for domain in project['domains']:
        domain_counts[domain] = domain_counts.get(domain, 0) + 1

print("\n   By Domain:")
for domain, count in sorted(domain_counts.items(), key=lambda x: x[1], reverse=True):
    print(f"      {domain}: {count}")

# By language
lang_counts = {}
for project in all_projects:
    lang = project.get('language', 'Unknown')
    lang_counts[lang] = lang_counts.get(lang, 0) + 1

print("\n   By Language:")
for lang, count in sorted(lang_counts.items(), key=lambda x: x[1], reverse=True)[:10]:
    print(f"      {lang}: {count}")

print("\n✨ Scraping complete! Run generate-website-features.py next.")
