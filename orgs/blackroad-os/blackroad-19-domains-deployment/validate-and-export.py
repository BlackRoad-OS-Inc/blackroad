#!/usr/bin/env python3

"""
BlackRoad Validator and Exporter
Validates generated features and exports to website templates
Checks if anything is stupid and logs to memory
"""

import json
import subprocess
from pathlib import Path
from datetime import datetime

print("✅ BlackRoad Feature Validator & Exporter")
print("=" * 60)

# Load generated features
features_file = Path("website-features-generated.json")
if not features_file.exists():
    print("❌ Error: website-features-generated.json not found")
    print("Run generate-website-features.py first!")
    exit(1)

with features_file.open() as f:
    data = json.load(f)

features = data['features']
print(f"📦 Loaded features for {len(features)} domains")

# Validation checks
print("\n🔍 Running validation checks...")

validation_results = {
    "passed": [],
    "warnings": [],
    "errors": [],
    "stupid_checks": []
}

for domain, feat in features.items():
    print(f"\n   Checking: {domain}")

    # Check 1: Has projects
    if feat['total_projects'] == 0:
        validation_results['errors'].append(f"{domain}: NO PROJECTS FOUND (stupid!)")
        print(f"      ❌ No projects found")
    else:
        print(f"      ✓ {feat['total_projects']} projects")

    # Check 2: Has featured projects
    if len(feat['featured_projects']) == 0:
        validation_results['warnings'].append(f"{domain}: No featured projects")
        print(f"      ⚠️  No featured projects")
    else:
        print(f"      ✓ {len(feat['featured_projects'])} featured projects")

    # Check 3: All featured projects have descriptions
    empty_descriptions = [p for p in feat['featured_projects'] if not p['description'] or p['description'] == 'No description available']
    if empty_descriptions:
        validation_results['warnings'].append(f"{domain}: {len(empty_descriptions)} projects missing descriptions")
        print(f"      ⚠️  {len(empty_descriptions)} missing descriptions")

    # Check 4: Has product sections
    if len(feat['products_section']) == 0:
        validation_results['warnings'].append(f"{domain}: No product sections")
        print(f"      ⚠️  No product sections")
    else:
        print(f"      ✓ {len(feat['products_section'])} product categories")

    # Check 5: Stats look reasonable
    if feat['stats']['total_repos'] != feat['total_projects']:
        validation_results['stupid_checks'].append(f"{domain}: Stats mismatch (total_repos vs total_projects)")
        print(f"      🤔 Stats mismatch")

    # Check 6: Has at least one language
    if feat['stats']['languages'] == 0:
        validation_results['warnings'].append(f"{domain}: No programming languages detected")
        print(f"      ⚠️  No languages")

    # All checks passed
    if not any([
        f"{domain}:" in str(validation_results['errors']),
        f"{domain}:" in str(validation_results['warnings'])
    ]):
        validation_results['passed'].append(domain)

print("\n" + "=" * 60)
print("📊 Validation Results:")
print(f"   ✅ Passed: {len(validation_results['passed'])}")
print(f"   ⚠️  Warnings: {len(validation_results['warnings'])}")
print(f"   ❌ Errors: {len(validation_results['errors'])}")
print(f"   🤔 Stupid checks: {len(validation_results['stupid_checks'])}")

if validation_results['errors']:
    print("\n❌ Errors found:")
    for error in validation_results['errors']:
        print(f"      {error}")

if validation_results['warnings']:
    print("\n⚠️  Warnings:")
    for warning in validation_results['warnings'][:5]:  # Top 5
        print(f"      {warning}")

if validation_results['stupid_checks']:
    print("\n🤔 Stupid checks (things that look weird):")
    for check in validation_results['stupid_checks']:
        print(f"      {check}")

# Export features to website templates
print("\n🚀 Exporting features to websites...")

export_count = 0
for domain, feat in features.items():
    site_dir = Path(f"sites/{domain}")
    if not site_dir.exists():
        print(f"   ⚠️  Skipping {domain} (site directory not found)")
        continue

    # Create features.json for each site
    features_json = site_dir / "features.json"
    with features_json.open('w') as f:
        json.dump(feat, f, indent=2)

    print(f"   ✅ Exported to sites/{domain}/features.json")
    export_count += 1

print(f"\n💾 Exported to {export_count} sites")

# Generate quality report
quality_report = {
    "validated_at": datetime.now().isoformat(),
    "total_domains": len(features),
    "validation_summary": {
        "passed": len(validation_results['passed']),
        "warnings": len(validation_results['warnings']),
        "errors": len(validation_results['errors']),
        "stupid_checks": len(validation_results['stupid_checks'])
    },
    "validation_details": validation_results,
    "export_summary": {
        "exported": export_count,
        "skipped": len(features) - export_count
    }
}

report_file = Path("validation-report.json")
with report_file.open('w') as f:
    json.dump(quality_report, f, indent=2)

print(f"📄 Quality report saved to: {report_file}")

# Final verdict
print("\n" + "=" * 60)
if validation_results['errors']:
    print("⛔ VALIDATION FAILED - Fix errors before deploying")
    exit_code = 1
elif validation_results['warnings']:
    print("⚠️  VALIDATION PASSED WITH WARNINGS - Review before deploying")
    exit_code = 0
else:
    print("✅ VALIDATION PASSED - Ready to deploy!")
    exit_code = 0

# Log to memory
print("\n📝 Logging to [MEMORY]...")
try:
    subprocess.run([
        "bash", "-c",
        f"""~/memory-system.sh log validated "GitHub Projects Auto-Mapping" "SCRAPED AND VALIDATED ALL BLACKROAD GITHUB PROJECTS

Total Projects Scraped: {sum(f['total_projects'] for f in features.values())}
Domains Mapped: {len(features)}
Validation Status: {'PASSED' if exit_code == 0 else 'FAILED'}

Validation Results:
- Passed: {len(validation_results['passed'])}
- Warnings: {len(validation_results['warnings'])}
- Errors: {len(validation_results['errors'])}
- Stupid Checks: {len(validation_results['stupid_checks'])}

Top Domains by Projects:
{chr(10).join([f'  - {domain}: {feat["total_projects"]} projects' for domain, feat in sorted(features.items(), key=lambda x: x[1]["total_projects"], reverse=True)[:5]])}

Exported Features: {export_count} sites
Files Created:
- github-projects-scraped.json
- website-features-generated.json
- validation-report.json
- features.json (in each site directory)

Next: Update HTML templates with real project data
" "github,automation,validation,scraper" """
    ], check=True, capture_output=True, text=True)
    print("   ✅ Logged to [MEMORY]")
except Exception as e:
    print(f"   ⚠️  Memory log failed: {e}")

print("\n✨ Validation and export complete!")
print("\nNext steps:")
print("  1. Review validation-report.json")
print("  2. Fix any errors/warnings")
print("  3. Run update-html-templates.py to inject features into HTML")
print("")

exit(exit_code)
