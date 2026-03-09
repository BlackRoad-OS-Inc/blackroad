#!/bin/bash
# Quick deploy starter content

REPO="blackroad-monitoring"
GITHUB_ORG="BlackRoad-OS"

echo "📤 Deploying starter to $REPO"

cd /tmp
rm -rf "$REPO"

gh repo clone "$GITHUB_ORG/$REPO" || {
    mkdir "$REPO"
    cd "$REPO"
    git init
    git remote add origin "https://github.com/$GITHUB_ORG/$REPO.git"
}

cd "$REPO" 2>/dev/null || cd /tmp/"$REPO"

# Create index.html
cat > index.html << 'EOFHTML'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>BlackRoad Monitoring - BlackRoad OS</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
            background: linear-gradient(135deg, #0a0a0a 0%, #1a1a2e 100%);
            color: #fff;
            display: flex;
            align-items: center;
            justify-content: center;
            min-height: 100vh;
        }
        .container { text-align: center; max-width: 800px; padding: 40px; }
        h1 {
            font-size: 3em;
            margin-bottom: 20px;
            background: linear-gradient(135deg, #FF9D00, #FF0066, #7700FF);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
        }
        .status {
            display: inline-block;
            padding: 15px 30px;
            background: rgba(0,255,136,0.2);
            border: 2px solid #00ff88;
            border-radius: 30px;
            color: #00ff88;
            font-size: 1.2em;
            margin-top: 30px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 BlackRoad Monitoring</h1>
        <p style="font-size: 1.5em; opacity: 0.8;">Deployment Dashboard</p>
        <div class="status">✅ Connected to GitHub</div>
    </div>
</body>
</html>
EOFHTML

cat > README.md << 'EOFREADME'
# BlackRoad Monitoring

Real-time deployment monitoring dashboard for BlackRoad OS.

## Auto-Deployment
✅ Connects to Cloudflare Pages automatically

---
BlackRoad OS © 2025
EOFREADME

git add .
git commit -m "Add starter content for Cloudflare Pages connection

🤖 Generated with Claude Code" || true

git push -u origin main 2>/dev/null || git push -u origin master 2>/dev/null

echo "✅ Done! Check: https://github.com/$GITHUB_ORG/$REPO"
