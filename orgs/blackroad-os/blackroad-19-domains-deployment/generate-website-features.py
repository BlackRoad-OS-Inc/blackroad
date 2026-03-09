#!/usr/bin/env python3

"""
BlackRoad Website Feature Generator
Takes scraped GitHub data and generates features for each domain
"""

import json
from pathlib import Path
from collections import defaultdict

print("🎨 BlackRoad Website Feature Generator")
print("=" * 60)

# Load scraped data
scraped_file = Path("github-projects-scraped.json")
if not scraped_file.exists():
    print("❌ Error: github-projects-scraped.json not found")
    print("Run scrape-github-projects.py first!")
    exit(1)

with scraped_file.open() as f:
    data = json.load(f)

projects = data['projects']
print(f"📦 Loaded {len(projects)} projects")

# Group projects by domain
domain_projects = defaultdict(list)
for project in projects:
    for domain in project['domains']:
        domain_projects[domain].append(project)

print(f"🌐 Mapped to {len(domain_projects)} domains")

# Generate features for each domain
features_output = {}

for domain, projs in sorted(domain_projects.items()):
    print(f"\n🔨 Generating features for: {domain}")
    print(f"   Projects: {len(projs)}")

    # Get top categories
    category_counts = defaultdict(int)
    for p in projs:
        for cat in p['categories']:
            category_counts[cat] += 1

    top_categories = sorted(category_counts.items(), key=lambda x: x[1], reverse=True)[:3]

    # Get language distribution
    language_counts = defaultdict(int)
    for p in projs:
        language_counts[p['language']] += 1

    top_languages = sorted(language_counts.items(), key=lambda x: x[1], reverse=True)[:3]

    # Generate feature sections
    features = {
        "domain": domain,
        "total_projects": len(projs),
        "top_categories": [{"name": cat, "count": count} for cat, count in top_categories],
        "top_languages": [{"name": lang, "count": count} for lang, count in top_languages],
        "featured_projects": [],
        "products_section": [],
        "stats": {
            "total_repos": len(projs),
            "active_projects": len([p for p in projs if p['categories']]),
            "languages": len(language_counts),
            "categories": len(category_counts)
        }
    }

    # Select featured projects (most recently updated)
    sorted_projs = sorted(projs, key=lambda x: x['updated'], reverse=True)

    # Featured projects (top 6)
    for i, proj in enumerate(sorted_projs[:6]):
        features["featured_projects"].append({
            "name": proj['name'],
            "description": proj['description'] or "No description available",
            "url": proj['url'],
            "language": proj['language'],
            "categories": proj['categories'][:2],  # Top 2 categories
            "icon": "◆" if i % 4 == 0 else "◈" if i % 4 == 1 else "◇" if i % 4 == 2 else "⬡"
        })

    # Products section (group by category)
    category_products = defaultdict(list)
    for proj in sorted_projs:
        if proj['categories']:
            cat = proj['categories'][0]  # Primary category
            if len(category_products[cat]) < 3:  # Max 3 per category
                category_products[cat].append(proj)

    for cat, cat_projs in list(category_products.items())[:4]:  # Top 4 categories
        features["products_section"].append({
            "category": cat.title(),
            "projects": [
                {
                    "name": p['name'],
                    "description": p['description'] or "No description",
                    "url": p['url']
                }
                for p in cat_projs
            ]
        })

    features_output[domain] = features

    print(f"   ✅ Generated:")
    print(f"      - {len(features['featured_projects'])} featured projects")
    print(f"      - {len(features['products_section'])} product categories")
    print(f"      - Stats: {features['stats']}")

# Save features
output_file = Path("website-features-generated.json")
with output_file.open('w') as f:
    json.dump({
        "generated_at": data['scraped_at'],
        "total_domains": len(features_output),
        "features": features_output
    }, f, indent=2)

print("\n" + "=" * 60)
print(f"💾 Saved to: {output_file}")
print(f"✅ Generated features for {len(features_output)} domains")

# Summary
print("\n📊 Summary:")
for domain, features in sorted(features_output.items(), key=lambda x: x[1]['total_projects'], reverse=True):
    print(f"   {domain}: {features['total_projects']} projects")

print("\n✨ Feature generation complete! Run validate-and-export.py next.")
