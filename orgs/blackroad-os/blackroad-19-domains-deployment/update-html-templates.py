#!/usr/bin/env python3

"""
BlackRoad HTML Template Updater
Injects real GitHub project data into HTML templates
"""

import json
from pathlib import Path
import re

print("🎨 BlackRoad HTML Template Updater")
print("=" * 60)

sites_dir = Path("sites")
updated_count = 0
skipped_count = 0

for site_path in sorted(sites_dir.iterdir()):
    if not site_path.is_dir():
        continue

    domain = site_path.name
    html_file = site_path / "index.html"
    features_file = site_path / "features.json"

    if not html_file.exists():
        print(f"⚠️  Skipping {domain}: no index.html")
        skipped_count += 1
        continue

    if not features_file.exists():
        print(f"⚠️  Skipping {domain}: no features.json")
        skipped_count += 1
        continue

    print(f"\n🔧 Updating: {domain}")

    # Load features
    with features_file.open() as f:
        features = json.load(f)

    # Load HTML
    html = html_file.read_text()

    # Update stats section
    if features['stats']:
        stats = features['stats']

        # Find stats section and update values
        html = re.sub(
            r'\[000\]',
            str(stats['total_repos']),
            html,
            count=1
        )
        html = re.sub(
            r'\[00K\+\]',
            f"{stats['active_projects']}+",
            html,
            count=1
        )
        html = re.sub(
            r'\[00%\]',
            f"{stats['languages']}",
            html,
            count=1
        )
        html = re.sub(
            r'\[∞\]',
            "∞",
            html,
            count=1
        )

        # Update stat labels
        html = re.sub(r'\[Stat Label 1\]', 'Total Repositories', html, count=1)
        html = re.sub(r'\[Stat Label 2\]', 'Active Projects', html, count=1)
        html = re.sub(r'\[Stat Label 3\]', 'Languages', html, count=1)
        html = re.sub(r'\[Stat Label 4\]', 'Categories', html, count=1)

        print(f"   ✓ Updated stats")

    # Update features section (first 6 featured projects)
    if features['featured_projects']:
        for i, proj in enumerate(features['featured_projects'][:6], 1):
            # Update feature titles
            html = re.sub(
                rf'\[Feature Title {i}\]',
                proj['name'].replace('-', ' ').title(),
                html,
                count=1
            )

            # Update feature descriptions
            html = re.sub(
                rf'\[Feature item {i}\]',
                proj['name'],
                html,
                count=1
            )

            # Inject actual descriptions in feature cards
            feature_pattern = rf'(<h3 class="feature-title">\[Feature Title {i}\]</h3>\s*<p class="feature-desc">)([^<]+)(</p>)'
            html = re.sub(
                feature_pattern,
                rf'\1{proj["description"][:100]}...\3',
                html
            )

        print(f"   ✓ Updated {len(features['featured_projects'][:6])} features")

    # Update products section
    if features['products_section']:
        for i, product_cat in enumerate(features['products_section'][:4], 1):
            if product_cat['projects']:
                proj = product_cat['projects'][0]

                # Update product names
                html = re.sub(
                    rf'\[Product Name {i}\]',
                    proj['name'].replace('-', ' ').title(),
                    html,
                    count=1
                )

                # Update product category
                html = re.sub(
                    rf'\[Category {i}\]',
                    product_cat['category'],
                    html,
                    count=1
                )

                # Update product descriptions
                desc = proj['description'][:80] + "..." if len(proj['description']) > 80 else proj['description']
                html = re.sub(
                    rf'\[Product Name {i}\]',
                    proj['name'].replace('-', ' ').title(),
                    html
                )

        print(f"   ✓ Updated {len(features['products_section'][:4])} product categories")

    # Update section labels
    html = re.sub(r'\[Section Label\]', 'PROJECTS', html)
    html = re.sub(r'\[Features Section Title\]', 'Featured Projects', html)
    html = re.sub(r'\[Products Section Title\]', 'Our Solutions', html)

    # Write updated HTML
    html_file.write_text(html)
    updated_count += 1
    print(f"   ✅ Updated index.html")

print("\n" + "=" * 60)
print(f"✅ Updated {updated_count} sites")
print(f"⚠️  Skipped {skipped_count} sites")
print("\n✨ HTML template update complete!")
print("\nNext: Deploy with ./deploy-all-domains.sh")
