#!/usr/bin/env python3

"""
BlackRoad 19 Domains - Site Generator
Generates customized HTML sites for all 19 domains with Dockerfiles
"""

import json
import os
from pathlib import Path

# Load domain configuration
with open('domain-config.json', 'r') as f:
    config = json.load(f)

# Load templates
templates_dir = Path(__file__).parent
homepage_template = (templates_dir.parent / 'Downloads/files(4)/blackroad-template-01-homepage.html').read_text()
pricing_template = (templates_dir.parent / 'Downloads/files(4)/blackroad-template-03-pricing.html').read_text()
docs_template = (templates_dir.parent / 'Downloads/files(4)/blackroad-template-05-docs.html').read_text()

# Docker configuration
DOCKERFILE_TEMPLATE = """FROM nginx:alpine

COPY index.html /usr/share/nginx/html/index.html
COPY nginx.conf /etc/nginx/nginx.conf

EXPOSE 3000

CMD ["nginx", "-g", "daemon off;"]
"""

NGINX_CONF = """events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    server {
        listen 3000;
        server_name localhost;

        root /usr/share/nginx/html;
        index index.html;

        location / {
            try_files $uri $uri/ /index.html;
        }

        # Enable gzip compression
        gzip on;
        gzip_types text/plain text/css application/json application/javascript text/xml application/xml;
    }
}
"""

def customize_template(template, branding):
    """Replace placeholders in template with domain-specific branding"""
    html = template

    # Page title
    html = html.replace('[PAGE TITLE]', branding['tagline'])
    html = html.replace('[PRICING PAGE TITLE]', branding['tagline'])
    html = html.replace('[PAGE_TITLE]', branding['tagline'])
    html = html.replace('[BRAND_NAME]', branding['name'])

    # Hero section
    html = html.replace('[STATUS BADGE TEXT]', branding['badge'])
    html = html.replace('[Page Label]', branding['badge'].upper())
    html = html.replace('[HERO_LABEL]', branding['badge'].upper())
    html = html.replace('[Headline Line One]', branding['hero_title'])
    html = html.replace('[Gradient Headline]', branding['hero_gradient'])
    html = html.replace('[Pricing Page Title]', branding['hero_title'] + ' ' + branding['hero_gradient'])
    html = html.replace('[HERO_TITLE]', branding['hero_title'] + ' ' + branding['hero_gradient'])
    html = html.replace('[DOC_TITLE]', branding['hero_title'] + ' ' + branding['hero_gradient'])
    html = html.replace('Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.', branding['hero_desc'])
    html = html.replace('[HERO_DESCRIPTION]', branding['hero_desc'])

    # Navigation and footer
    html = html.replace('BlackRoad OS', branding['name'])
    html = html.replace('[Nav Link 1]', 'Home')
    html = html.replace('[Nav Link 2]', 'About')
    html = html.replace('[Nav Link 3]', 'Docs')
    html = html.replace('[Nav Link 4]', 'Contact')
    html = html.replace('[NAV_LINK_1]', 'Home')
    html = html.replace('[NAV_LINK_2]', 'About')
    html = html.replace('[NAV_LINK_3]', 'Docs')
    html = html.replace('[NAV_LINK_4]', 'Contact')
    html = html.replace('[CTA Button]', 'Get Started')
    html = html.replace('[Primary CTA]', 'Get Started')
    html = html.replace('[Secondary CTA]', 'Learn More')
    html = html.replace('[YEAR]', '2024-2025')
    html = html.replace('[Legal Text Placeholder]', f'{branding["name"]} · All Rights Reserved')
    html = html.replace('[FOOTER_TEXT]', f'© 2024-2025 {branding["name"]} · All Rights Reserved')

    return html

print("🚀 BlackRoad 19 Domains - Site Generator")
print("=" * 60)

sites_dir = Path('sites')
sites_dir.mkdir(exist_ok=True)

for domain_info in config['domains']:
    domain = domain_info['domain']
    template_type = domain_info['template']
    branding = domain_info['branding']

    print(f"\n📦 Generating: {domain}")
    print(f"   Template: {template_type}")
    print(f"   Port: {domain_info['port']}")

    # Select template
    if template_type == 'homepage':
        template = homepage_template
    elif template_type == 'pricing':
        template = pricing_template
    elif template_type == 'docs':
        template = docs_template
    else:
        template = homepage_template

    # Customize template
    customized_html = customize_template(template, branding)

    # Create domain directory
    domain_dir = sites_dir / domain
    domain_dir.mkdir(exist_ok=True)

    # Write files
    (domain_dir / 'index.html').write_text(customized_html)
    (domain_dir / 'Dockerfile').write_text(DOCKERFILE_TEMPLATE)
    (domain_dir / 'nginx.conf').write_text(NGINX_CONF)

    # Create .dockerignore
    (domain_dir / '.dockerignore').write_text("*.md\n.git\n.gitignore\n")

    print(f"   ✅ Generated in sites/{domain}/")

print("\n" + "=" * 60)
print(f"✨ Complete! Generated {len(config['domains'])} sites")
print("\nNext steps:")
print("  1. Review sites/ directory")
print("  2. Run: ./deploy-all-domains.sh")
print("  3. Run: ./configure-dns.sh")
print("")
