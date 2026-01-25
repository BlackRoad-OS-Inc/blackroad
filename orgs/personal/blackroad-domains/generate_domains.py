#!/usr/bin/env python3
"""
BlackRoad OS Domain HTML Generator
Generates unique HTML pages for all BlackRoad domains and subdomains
"""

DOMAINS = {
    # Core Platforms
    "blackroad.io": {
        "title": "BlackRoad OS — The Future of Infinite Intelligence",
        "tagline": "Infinite Intelligence • Infinite Creation • Infinite Love",
        "icon": "🌌",
        "description": "The main portal to the BlackRoad OS universe",
        "features": ["Metaverse Access", "Portal Login", "Complete Ecosystem"],
        "cta": "Enter BlackRoad",
        "cta_link": "https://universe.blackroad.io"
    },

    # Metaverse & Universe
    "universe.blackroad.io": {
        "title": "BlackRoad Universe — Infinite Metaverse",
        "tagline": "18 Systems • Infinite Worlds • Living AI",
        "icon": "🌌",
        "description": "Complete 3D metaverse with procedural generation",
        "features": ["18 Integrated Systems", "Living Nature", "AI Agents"],
        "cta": "Enter Universe",
        "cta_link": "/universe.html"
    },

    "earth.blackroad.io": {
        "title": "BlackRoad Earth — Real-Time Planet Simulation",
        "tagline": "NASA-Grade Celestial Mechanics",
        "icon": "🌍",
        "description": "Real-time Earth visualization with eclipse predictions",
        "features": ["IAU 2000/2006 Transforms", "Eclipse Predictions", "3D Globe"],
        "cta": "View Earth",
        "cta_link": "#"
    },

    # Authentication & Security
    "pitstop.blackroad.io": {
        "title": "BlackRoad Pitstop — Secure Portal",
        "tagline": "Secure Access to BlackRoad OS",
        "icon": "🔐",
        "description": "Authentication portal for all BlackRoad systems",
        "features": ["Secure Login", "File Dashboard", "Session Management"],
        "cta": "Login",
        "cta_link": "/index.html"
    },

    # Creator & Studio
    "creator.blackroad.io": {
        "title": "BlackRoad Creator — Build Your Universe",
        "tagline": "Create • Design • Publish",
        "icon": "🎨",
        "description": "Advanced creator tools for universe building",
        "features": ["3D Modeling", "Universe Editor", "Asset Management"],
        "cta": "Start Creating",
        "cta_link": "#"
    },

    "creator-studio.blackroad.io": {
        "title": "BlackRoad Creator Studio — Professional Tools",
        "tagline": "Professional Content Creation",
        "icon": "🎬",
        "description": "Advanced studio for professional creators",
        "features": ["Video Production", "3D Animation", "Rendering"],
        "cta": "Open Studio",
        "cta_link": "#"
    },

    "studio.blackroad.io": {
        "title": "BlackRoad Studio — Production Platform",
        "tagline": "Produce • Collaborate • Deliver",
        "icon": "🎥",
        "description": "Full production platform for teams",
        "features": ["Team Collaboration", "Project Management", "Asset Pipeline"],
        "cta": "Launch Studio",
        "cta_link": "#"
    },

    # Business & Operations
    "finance.blackroad.io": {
        "title": "BlackRoad Finance — Financial Management",
        "tagline": "Manage • Analyze • Grow",
        "icon": "💰",
        "description": "Financial analytics and management platform",
        "features": ["Revenue Analytics", "Expense Tracking", "Forecasting"],
        "cta": "View Dashboard",
        "cta_link": "#"
    },

    "legal.blackroad.io": {
        "title": "BlackRoad Legal — Compliance & Documents",
        "tagline": "Compliant • Secure • Organized",
        "icon": "⚖️",
        "description": "Legal document management and compliance",
        "features": ["Document Library", "Compliance Tools", "Contract Management"],
        "cta": "Access Legal",
        "cta_link": "#"
    },

    "education.blackroad.io": {
        "title": "BlackRoad Education — Learning Platform",
        "tagline": "Learn • Grow • Master",
        "icon": "📚",
        "description": "Educational platform for BlackRoad OS",
        "features": ["Courses", "Tutorials", "Certification"],
        "cta": "Start Learning",
        "cta_link": "#"
    },

    # Research & Development
    "research-lab.blackroad.io": {
        "title": "BlackRoad Research Lab — Scientific Innovation",
        "tagline": "Research • Experiment • Discover",
        "icon": "🔬",
        "description": "Quantum computing and AI research platform",
        "features": ["Quantum Computing", "AI Research", "Experiments"],
        "cta": "Enter Lab",
        "cta_link": "#"
    },

    "ideas.blackroad.io": {
        "title": "BlackRoad Ideas — Innovation Hub",
        "tagline": "Ideate • Collaborate • Innovate",
        "icon": "💡",
        "description": "Idea management and innovation platform",
        "features": ["Idea Tracking", "Voting System", "Project Planning"],
        "cta": "Share Ideas",
        "cta_link": "#"
    },

    "devops.blackroad.io": {
        "title": "BlackRoad DevOps — Infrastructure Tools",
        "tagline": "Deploy • Monitor • Scale",
        "icon": "⚙️",
        "description": "CI/CD and infrastructure management",
        "features": ["CI/CD Pipelines", "Monitoring", "Deployment"],
        "cta": "Open Console",
        "cta_link": "#"
    },

    # User Spaces
    "home.blackroad.io": {
        "title": "BlackRoad Home — Your Dashboard",
        "tagline": "Your Personal BlackRoad OS Hub",
        "icon": "🏠",
        "description": "Personal dashboard for all services",
        "features": ["Service Access", "Settings", "Notifications"],
        "cta": "Go Home",
        "cta_link": "#"
    },

    "demo.blackroad.io": {
        "title": "BlackRoad Demo — Experience the Future",
        "tagline": "Try • Explore • Experience",
        "icon": "🎯",
        "description": "Interactive demos and showcases",
        "features": ["Live Demos", "Interactive Examples", "Feature Showcase"],
        "cta": "Try Demo",
        "cta_link": "#"
    },
}


HTML_TEMPLATE = """<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{title}</title>
    <meta name="description" content="{description}">

    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800;900&display=swap" rel="stylesheet">

    <style>
        * {{
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }}

        :root {{
            --orange: #FF9D00;
            --red: #FF006B;
            --purple: #7700FF;
            --blue: #0066FF;
            --green: #27AE60;
        }}

        body {{
            font-family: 'Inter', sans-serif;
            background: linear-gradient(135deg, #000 0%, #1a0a2e 50%, #000 100%);
            color: #fff;
            min-height: 100vh;
            display: flex;
            flex-direction: column;
        }}

        .container {{
            flex: 1;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 40px;
        }}

        .content {{
            max-width: 800px;
            text-align: center;
        }}

        .icon {{
            font-size: 120px;
            margin-bottom: 30px;
            animation: float 3s ease-in-out infinite;
        }}

        @keyframes float {{
            0%, 100% {{ transform: translateY(0); }}
            50% {{ transform: translateY(-20px); }}
        }}

        .title {{
            font-size: 48px;
            font-weight: 900;
            background: linear-gradient(45deg, var(--orange), var(--red), var(--purple), var(--blue));
            -webkit-background-clip: text;
            background-clip: text;
            -webkit-text-fill-color: transparent;
            margin-bottom: 20px;
            background-size: 300% 300%;
            animation: gradient 3s ease infinite;
        }}

        @keyframes gradient {{
            0%, 100% {{ background-position: 0% 50%; }}
            50% {{ background-position: 100% 50%; }}
        }}

        .tagline {{
            font-size: 24px;
            font-weight: 300;
            color: #ccc;
            margin-bottom: 30px;
        }}

        .description {{
            font-size: 16px;
            color: #aaa;
            margin-bottom: 40px;
            line-height: 1.6;
        }}

        .features {{
            display: flex;
            gap: 20px;
            justify-content: center;
            flex-wrap: wrap;
            margin-bottom: 40px;
        }}

        .feature {{
            background: rgba(255, 255, 255, 0.05);
            border: 1px solid rgba(255, 255, 255, 0.1);
            padding: 12px 24px;
            border-radius: 8px;
            font-size: 14px;
        }}

        .cta {{
            display: inline-block;
            padding: 16px 40px;
            background: linear-gradient(45deg, var(--orange), var(--red));
            color: #fff;
            text-decoration: none;
            border-radius: 12px;
            font-weight: 600;
            font-size: 18px;
            transition: transform 0.2s ease, box-shadow 0.2s ease;
        }}

        .cta:hover {{
            transform: translateY(-2px);
            box-shadow: 0 10px 30px rgba(255, 157, 0, 0.3);
        }}

        .back-link {{
            margin-top: 40px;
        }}

        .back-link a {{
            color: var(--purple);
            text-decoration: none;
            font-size: 14px;
        }}

        .back-link a:hover {{
            color: var(--orange);
        }}

        .footer {{
            padding: 30px;
            text-align: center;
            font-size: 12px;
            color: #666;
            border-top: 1px solid rgba(255, 255, 255, 0.1);
        }}

        .status {{
            display: inline-block;
            background: rgba(39, 174, 96, 0.2);
            color: var(--green);
            padding: 6px 12px;
            border-radius: 6px;
            font-size: 12px;
            font-weight: 600;
            margin-bottom: 20px;
        }}
    </style>
</head>
<body>
    <div class="container">
        <div class="content">
            <div class="status">✅ LIVE</div>
            <div class="icon">{icon}</div>
            <h1 class="title">{domain_name}</h1>
            <p class="tagline">{tagline}</p>
            <p class="description">{description}</p>
            <div class="features">
{features_html}
            </div>
            <a href="{cta_link}" class="cta">{cta}</a>
            <div class="back-link">
                <a href="https://blackroad.io">← Back to BlackRoad OS</a>
            </div>
        </div>
    </div>
    <footer class="footer">
        © 2025 BlackRoad OS, Inc. • Built with 💚 • <a href="https://pitstop.blackroad.io" style="color: #666;">Portal</a>
    </footer>
</body>
</html>
"""


def generate_html(domain, config):
    """Generate HTML for a domain"""
    features_html = "\\n".join([
        f'                <div class="feature">{feat}</div>'
        for feat in config['features']
    ])

    html = HTML_TEMPLATE.format(
        title=config['title'],
        description=config['description'],
        icon=config['icon'],
        domain_name=domain.replace('.blackroad.io', '').replace('blackroad.io', 'BlackRoad OS').upper(),
        tagline=config['tagline'],
        features_html=features_html,
        cta=config['cta'],
        cta_link=config['cta_link']
    )

    return html


def main():
    """Generate all domain HTML files"""
    import os

    output_dir = "/Users/alexa/blackroad-domains/pages"
    os.makedirs(output_dir, exist_ok=True)

    print("🚀 BlackRoad OS Domain HTML Generator")
    print("=" * 60)

    for domain, config in DOMAINS.items():
        filename = domain.replace('.', '-') + '.html'
        filepath = os.path.join(output_dir, filename)

        html = generate_html(domain, config)

        with open(filepath, 'w') as f:
            f.write(html)

        print(f"✅ Generated: {filename}")

    print("=" * 60)
    print(f"🎉 Generated {len(DOMAINS)} domain pages!")
    print(f"📁 Output: {output_dir}")


if __name__ == "__main__":
    main()
