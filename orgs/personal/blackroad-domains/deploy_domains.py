#!/usr/bin/env python3
"""
BlackRoad OS - Automated Domain Deployment
Deploys all generated HTML pages to Cloudflare Pages
"""

import os
import subprocess
import time
import shutil

PAGES_DIR = "/Users/alexa/blackroad-domains/pages"

# Domain to Project mapping
DEPLOYMENTS = {
    "blackroad-io.html": "blackroad-io",
    "earth-blackroad-io.html": "earth-blackroad-io",
    "home-blackroad-io.html": "blackroad-os-home",
    "demo-blackroad-io.html": "blackroad-os-demo",
    # Note: universe and pitstop already have custom content
}

def deploy_domain(html_file, project_name):
    """Deploy a single domain to Cloudflare Pages"""
    print(f"📦 Deploying {html_file} to {project_name}...")

    temp_dir = f"/tmp/blackroad-deploy-{project_name}"

    try:
        # Create temp directory
        os.makedirs(temp_dir, exist_ok=True)

        # Copy HTML file as index.html
        src = os.path.join(PAGES_DIR, html_file)
        dst = os.path.join(temp_dir, "index.html")
        shutil.copy(src, dst)

        # Deploy using wrangler
        result = subprocess.run(
            ["wrangler", "pages", "deploy", ".", "--project-name", project_name, "--commit-dirty=true"],
            cwd=temp_dir,
            capture_output=True,
            text=True,
            timeout=120
        )

        if result.returncode == 0:
            print(f"   ✅ Successfully deployed {project_name}")
            # Extract deployment URL from output
            for line in result.stdout.split('\\n'):
                if 'Deployment complete!' in line or 'https://' in line:
                    if 'https://' in line and '.pages.dev' in line:
                        url = line.split('https://')[1].split()[0] if 'https://' in line else None
                        if url:
                            print(f"   🌐 Live at: https://{url}")
            return True
        else:
            print(f"   ❌ Failed to deploy {project_name}")
            print(f"   Error: {result.stderr[:200]}")
            return False

    except Exception as e:
        print(f"   ❌ Exception: {e}")
        return False

    finally:
        # Cleanup
        if os.path.exists(temp_dir):
            shutil.rmtree(temp_dir)


def main():
    """Main deployment function"""
    print("🚀 BlackRoad OS - Domain Deployment")
    print("=" * 60)
    print("")

    deployed = 0
    failed = 0

    for html_file, project_name in DEPLOYMENTS.items():
        html_path = os.path.join(PAGES_DIR, html_file)

        if os.path.exists(html_path):
            if deploy_domain(html_file, project_name):
                deployed += 1
            else:
                failed += 1

            # Rate limiting
            time.sleep(2)
        else:
            print(f"⚠️  File not found: {html_file}")
            failed += 1

        print("")

    print("=" * 60)
    print("📊 Deployment Summary")
    print("=" * 60)
    print(f"✅ Deployed: {deployed}")
    print(f"❌ Failed: {failed}")
    print("")
    print("🌐 Live URLs:")
    print("   https://blackroad.io")
    print("   https://earth.blackroad.io")
    print("   https://home.blackroad.io")
    print("   https://demo.blackroad.io")
    print("")
    print("🎉 Deployment complete!")


if __name__ == "__main__":
    main()
