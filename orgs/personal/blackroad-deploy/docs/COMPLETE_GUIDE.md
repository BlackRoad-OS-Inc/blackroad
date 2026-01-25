# BlackRoad Deploy - Complete Guide

**GitHub → Your Metal in Seconds**

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Quick Start](#quick-start)
4. [Language Support](#language-support)
5. [Deployment Configuration](#deployment-configuration)
6. [CLI Commands](#cli-commands)
7. [GitHub Webhook Setup](#github-webhook-setup)
8. [Server Setup](#server-setup)
9. [Examples](#examples)
10. [Troubleshooting](#troubleshooting)

---

## Overview

BlackRoad Deploy is a self-hosted deployment platform that lets you deploy any application (Node.js, Python, Java, C#, Go, Rust) to your own infrastructure with zero configuration.

### Why BlackRoad Deploy?

- **Auto-Detection**: Automatically detects your language and framework
- **Zero Config**: Works out-of-the-box for most projects
- **Your Infrastructure**: Deploy to DigitalOcean droplets or Raspberry Pis
- **No Vendor Lock-in**: All code runs on machines you control
- **GitHub Native**: Push to GitHub = automatic deployment
- **Multi-Language**: Supports 6+ languages

### Infrastructure

- **Droplet**: 159.65.43.12 (codex-infinity)
- **Pi Lucidia**: 192.168.4.38
- **Pi BlackRoad**: 192.168.4.64
- **Pi Lucidia Alt**: 192.168.4.99

---

## Architecture

```
┌──────────────┐
│   GitHub     │
│   Push       │
└──────┬───────┘
       │
       │ webhook
       ▼
┌──────────────────────┐
│   Orchestrator       │
│   (Droplet)          │
│                      │
│   1. Clone repo      │
│   2. Detect language │
│   3. Build Docker    │
│   4. Deploy to       │
│      target server   │
└──────┬───────────────┘
       │
       ▼
┌────────────────────────┐
│   Target Server        │
│   (Droplet or Pi)      │
│                        │
│   - Run container      │
│   - Expose on port     │
│   - Serve traffic      │
└────────────────────────┘
```

### Components

1. **Orchestrator** (`orchestrator/`)
   - Webhook receiver (receives GitHub pushes)
   - Language detector (auto-detects tech stack)
   - Builder (creates Docker images)
   - Deployer (ships to target servers)

2. **CLI** (`cli/br.js`)
   - Manual deployment tool
   - View logs, list deployments
   - Domain management

3. **Dockerfiles** (`dockerfiles/`)
   - Pre-configured for each language
   - Optimized multi-stage builds
   - Health checks included

---

## Quick Start

### Option 1: Deploy via GitHub Webhook (Automatic)

1. Add `deploy.yaml` to your repo:

```yaml
domain: myapp.blackroad.io
target: droplet
port: 3000
```

2. Push to GitHub:

```bash
git add deploy.yaml
git commit -m "Add deployment config"
git push origin main
```

3. Your app deploys automatically!

### Option 2: Deploy via CLI (Manual)

1. Install CLI globally:

```bash
cd cli
npm install -g .
```

2. Deploy from your project directory:

```bash
cd my-app
br deploy --domain myapp.blackroad.io --target droplet
```

---

## Language Support

### Node.js

**Auto-detected by**: `package.json`

**Frameworks Supported**:
- Express
- Next.js
- NestJS
- Fastify
- Koa

**Example package.json**:

```json
{
  "name": "my-app",
  "scripts": {
    "start": "node server.js"
  },
  "dependencies": {
    "express": "^4.18.0"
  }
}
```

**Default Port**: 3000

---

### Python

**Auto-detected by**: `requirements.txt` or `pyproject.toml`

**Frameworks Supported**:
- Flask
- Django
- FastAPI
- Tornado

**Example requirements.txt**:

```
flask==3.0.0
gunicorn==21.2.0
```

**Example app.py**:

```python
from flask import Flask
app = Flask(__name__)

@app.route('/')
def hello():
    return 'Hello World'

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
```

**Default Port**: 5000

---

### Java

**Auto-detected by**: `pom.xml` (Maven) or `build.gradle` (Gradle)

**Frameworks Supported**:
- Spring Boot
- Micronaut
- Quarkus

**Example pom.xml**:

```xml
<project>
  <groupId>com.example</groupId>
  <artifactId>my-app</artifactId>
  <version>1.0.0</version>
  <dependencies>
    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-web</artifactId>
    </dependency>
  </dependencies>
</project>
```

**Default Port**: 8080

---

### C# / .NET

**Auto-detected by**: `*.csproj` or `*.sln`

**Frameworks Supported**:
- ASP.NET Core

**Example Program.cs**:

```csharp
var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

app.MapGet("/", () => "Hello World");

app.Run();
```

**Default Port**: 5000

---

### Go

**Auto-detected by**: `go.mod`

**Example main.go**:

```go
package main

import (
    "fmt"
    "net/http"
)

func main() {
    http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
        fmt.Fprintf(w, "Hello World")
    })
    http.ListenAndServe(":8080", nil)
}
```

**Default Port**: 8080

---

### Rust

**Auto-detected by**: `Cargo.toml`

**Frameworks Supported**:
- Actix-web
- Rocket

**Example Cargo.toml**:

```toml
[package]
name = "my-app"
version = "0.1.0"

[dependencies]
actix-web = "4.0"
```

**Default Port**: 8080

---

## Deployment Configuration

### deploy.yaml

Place this file in your project root:

```yaml
# Required
domain: api.blackroad.io
target: droplet

# Optional
port: 3000
env:
  NODE_ENV: production
  DATABASE_URL: postgres://user:pass@host/db
  API_KEY: secret-key

# Advanced
build:
  command: npm run build
  output: dist
run:
  command: npm start
health_check: /health
```

### Targets

- `droplet` - DigitalOcean droplet (159.65.43.12)
- `pi-lucidia` - Raspberry Pi at 192.168.4.38
- `pi-blackroad` - Raspberry Pi at 192.168.4.64
- `pi-lucidia-alt` - Raspberry Pi at 192.168.4.99

---

## CLI Commands

### Deploy

```bash
# Deploy current directory
br deploy

# Deploy with options
br deploy --domain api.blackroad.io --target droplet --port 8080

# Deploy to specific server
br deploy --target pi-lucidia
```

### List Deployments

```bash
br list
# or
br ls
```

Output:

```
DROPLET (159.65.43.12)
NAMES           STATUS          PORTS
my-app          Up 2 hours      0.0.0.0:3000->3000/tcp
api-service     Up 5 days       0.0.0.0:8080->8080/tcp

PI-LUCIDIA (192.168.4.38)
NAMES           STATUS          PORTS
test-app        Up 1 hour       0.0.0.0:5000->5000/tcp
```

### View Logs

```bash
# Last 100 lines
br logs my-app

# Follow logs (live)
br logs my-app -f

# Last 500 lines
br logs my-app -n 500
```

### Domain Management

```bash
# Update domain routing
br domain update api.blackroad.io --target droplet
```

### Help

```bash
br help
```

---

## GitHub Webhook Setup

### 1. Set up Orchestrator on Droplet

SSH to your droplet:

```bash
ssh root@159.65.43.12
```

Clone and setup:

```bash
# Clone repository
git clone https://github.com/BlackRoad-OS/blackroad-deploy.git
cd blackroad-deploy/orchestrator

# Install dependencies
npm install

# Create build directory
mkdir -p /opt/blackroad/builds

# Set environment variables
export GITHUB_WEBHOOK_SECRET="your-secret-here"
export BUILD_DIR="/opt/blackroad/builds"
export WEBHOOK_PORT=8080

# Start orchestrator
npm start
```

### 2. Configure GitHub Webhook

In your GitHub repository:

1. Go to **Settings → Webhooks → Add webhook**
2. **Payload URL**: `http://159.65.43.12:8080/webhook`
3. **Content type**: `application/json`
4. **Secret**: Your webhook secret
5. **Events**: Just the push event
6. **Active**: ✓

### 3. Test

Push to your repository and watch the orchestrator logs!

---

## Server Setup

### Install Docker on All Servers

On droplet and each Pi:

```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add user to docker group
sudo usermod -aG docker $USER

# Start Docker
sudo systemctl enable docker
sudo systemctl start docker
```

### SSH Key Setup

Set up passwordless SSH from droplet to all Pis:

```bash
# On droplet
ssh-keygen -t ed25519

# Copy to each Pi
ssh-copy-id pi@192.168.4.38
ssh-copy-id pi@192.168.4.64
ssh-copy-id pi@192.168.4.99
```

Test:

```bash
ssh pi@192.168.4.38 "docker ps"
```

---

## Examples

### Example 1: Node.js Express API

```bash
mkdir my-api
cd my-api
npm init -y
npm install express

# Create server.js
cat > server.js << 'EOF'
const express = require('express');
const app = express();

app.get('/', (req, res) => {
  res.json({ message: 'Hello from BlackRoad Deploy!' });
});

app.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

app.listen(3000, () => {
  console.log('Server running on port 3000');
});
EOF

# Update package.json start script
npm pkg set scripts.start="node server.js"

# Create deploy config
cat > deploy.yaml << 'EOF'
domain: api.blackroad.io
target: droplet
port: 3000
EOF

# Deploy
br deploy
```

### Example 2: Python Flask App

```bash
mkdir my-flask-app
cd my-flask-app

# Create app.py
cat > app.py << 'EOF'
from flask import Flask, jsonify
app = Flask(__name__)

@app.route('/')
def hello():
    return jsonify(message='Hello from Flask!')

@app.route('/health')
def health():
    return jsonify(status='ok')

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
EOF

# Create requirements.txt
echo "flask==3.0.0" > requirements.txt

# Create deploy config
cat > deploy.yaml << 'EOF'
domain: flask.blackroad.io
target: pi-lucidia
port: 5000
EOF

# Deploy
br deploy
```

### Example 3: Go Web Server

```bash
mkdir my-go-app
cd my-go-app

# Initialize Go module
go mod init github.com/yourusername/my-go-app

# Create main.go
cat > main.go << 'EOF'
package main

import (
    "encoding/json"
    "net/http"
)

func main() {
    http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
        json.NewEncoder(w).Encode(map[string]string{
            "message": "Hello from Go!",
        })
    })

    http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
        json.NewEncoder(w).Encode(map[string]string{
            "status": "ok",
        })
    })

    http.ListenAndServe(":8080", nil)
}
EOF

# Create deploy config
cat > deploy.yaml << 'EOF'
domain: go.blackroad.io
target: droplet
port: 8080
EOF

# Deploy
br deploy
```

---

## Troubleshooting

### Deployment Fails

1. Check orchestrator logs:
```bash
ssh root@159.65.43.12
cd blackroad-deploy/orchestrator
npm start
# Watch for errors
```

2. Verify Docker is running on target:
```bash
ssh pi@192.168.4.38 "docker ps"
```

3. Check build directory:
```bash
ssh root@159.65.43.12
ls -la /opt/blackroad/builds/
```

### Container Won't Start

1. Check container logs:
```bash
br logs my-app
```

2. Verify port isn't already in use:
```bash
ssh root@159.65.43.12 "netstat -tulpn | grep :3000"
```

3. Test locally:
```bash
cd /opt/blackroad/builds/my-app
docker build -t test .
docker run -p 3000:3000 test
```

### Can't Connect to Deployed App

1. Verify container is running:
```bash
br list
```

2. Test from server:
```bash
ssh root@159.65.43.12 "curl localhost:3000"
```

3. Check firewall:
```bash
sudo ufw status
sudo ufw allow 3000
```

---

## Advanced Topics

### Custom Dockerfiles

If auto-detection doesn't work, add your own `Dockerfile`:

```dockerfile
FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
EXPOSE 3000
CMD ["npm", "start"]
```

BlackRoad Deploy will use your Dockerfile instead of auto-generating one.

### Environment Variables

Set secrets via `deploy.yaml`:

```yaml
domain: api.blackroad.io
target: droplet
port: 3000
env:
  DATABASE_URL: postgres://user:pass@host/db
  JWT_SECRET: supersecret
  STRIPE_KEY: sk_live_xxx
```

### Multiple Environments

Use different branches:

```yaml
# deploy.yaml on main branch
domain: api.blackroad.io
target: droplet

# deploy.yaml on dev branch
domain: dev.blackroad.io
target: pi-lucidia
```

---

## Contributing

Pull requests welcome!

Repository: https://github.com/BlackRoad-OS/blackroad-deploy

## License

MIT

## Support

- GitHub Issues: https://github.com/BlackRoad-OS/blackroad-deploy/issues
- Email: blackroad.systems@gmail.com

---

**Built by BlackRoad Systems**
