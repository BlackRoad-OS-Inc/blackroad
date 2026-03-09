#!/usr/bin/env node
/**
 * 🚀 BlackRoad Deployment Engine
 * Git-based deployment system for Pi cluster
 */

const express = require('express');
const { exec } = require('child_process');
const fs = require('fs').promises;
const path = require('path');
const axios = require('axios');
const { v4: uuidv4 } = require('uuid');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 9000;

// Configuration
const DEPLOY_BASE_DIR = process.env.DEPLOY_BASE_DIR || '/tmp/road-deploys';
const TARGET_HOST = process.env.TARGET_HOST || 'aria'; // Default deploy target
const TARGET_IP = process.env.TARGET_IP || '192.168.4.82';
const REGISTRY_API = process.env.REGISTRY_API || 'http://lucidia:8080';

app.use(express.json());

// Health check
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    service: 'road-deploy',
    version: '1.0.0',
    timestamp: new Date().toISOString()
  });
});

// ========================================
// DEPLOYMENT ENDPOINTS
// ========================================

// Trigger deployment
app.post('/api/deploy', async (req, res) => {
  const {
    domain,
    repo_url,
    branch = 'main',
    build_command = 'npm run build',
    deploy_path = 'dist'
  } = req.body;

  if (!domain || !repo_url) {
    return res.status(400).json({
      success: false,
      error: 'domain and repo_url are required'
    });
  }

  const deploymentId = uuidv4();
  const workdir = path.join(DEPLOY_BASE_DIR, deploymentId);

  try {
    // Step 1: Clone repository
    console.log(`[${deploymentId}] Cloning ${repo_url}...`);
    await execAsync(`git clone -b ${branch} ${repo_url} ${workdir}`);

    // Step 2: Run build command
    console.log(`[${deploymentId}] Building project...`);
    const buildOutput = await execAsync(build_command, { cwd: workdir });

    // Step 3: Sync to aria Pi
    console.log(`[${deploymentId}] Deploying to ${TARGET_HOST}...`);
    const deployDir = `/home/pi/static-sites/${domain}`;

    // Create deploy directory on aria
    await execAsync(`ssh pi@${TARGET_HOST} "mkdir -p ${deployDir}"`);

    // Rsync built files
    const sourceDir = path.join(workdir, deploy_path);
    await execAsync(`rsync -avz --delete ${sourceDir}/ pi@${TARGET_HOST}:${deployDir}/`);

    // Step 4: Configure nginx on aria
    await configureNginx(domain, deployDir);

    // Step 5: Generate SSL certificate
    await generateSSL(domain);

    // Step 6: Reload nginx
    await execAsync(`ssh pi@${TARGET_HOST} "sudo nginx -s reload"`);

    // Step 7: Cleanup
    await execAsync(`rm -rf ${workdir}`);

    // Step 8: Log to registry
    await axios.post(`${REGISTRY_API}/api/deployments`, {
      domain,
      repo_url,
      branch,
      build_command,
      deploy_path,
      status: 'deployed'
    });

    res.json({
      success: true,
      deployment_id: deploymentId,
      domain,
      url: `https://${domain}`,
      message: 'Deployment successful'
    });

  } catch (error) {
    console.error(`[${deploymentId}] Deployment failed:`, error.message);

    // Cleanup on failure
    try {
      await execAsync(`rm -rf ${workdir}`);
    } catch {}

    res.status(500).json({
      success: false,
      deployment_id: deploymentId,
      error: error.message
    });
  }
});

// Get deployment status
app.get('/api/deploy/:deploymentId', async (req, res) => {
  const { deploymentId } = req.params;

  // Check if deployment directory exists
  const workdir = path.join(DEPLOY_BASE_DIR, deploymentId);

  try {
    await fs.access(workdir);
    res.json({
      success: true,
      deployment_id: deploymentId,
      status: 'in_progress'
    });
  } catch {
    res.json({
      success: true,
      deployment_id: deploymentId,
      status: 'completed_or_failed'
    });
  }
});

// List active domains on aria
app.get('/api/domains', async (req, res) => {
  try {
    const output = await execAsync(`ssh pi@${TARGET_HOST} "ls -1 /home/pi/static-sites"`);
    const domains = output.trim().split('\n').filter(d => d.length > 0);

    res.json({
      success: true,
      count: domains.length,
      domains
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// ========================================
// HELPER FUNCTIONS
// ========================================

function execAsync(command, options = {}) {
  return new Promise((resolve, reject) => {
    exec(command, options, (error, stdout, stderr) => {
      if (error) {
        reject(new Error(stderr || error.message));
      } else {
        resolve(stdout);
      }
    });
  });
}

async function configureNginx(domain, deployDir) {
  const nginxConfig = `
server {
    listen 80;
    server_name ${domain};

    root ${deployDir};
    index index.html index.htm;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # Gzip compression
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;

    location / {
        try_files $uri $uri/ /index.html;
    }

    # Cache static assets
    location ~* \\.(jpg|jpeg|png|gif|ico|css|js|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
`;

  // Write nginx config
  const configFile = `/tmp/nginx-${domain}.conf`;
  await fs.writeFile(configFile, nginxConfig);

  // Copy to aria
  await execAsync(`scp ${configFile} pi@${TARGET_HOST}:/tmp/`);
  await execAsync(`ssh pi@${TARGET_HOST} "sudo mv /tmp/nginx-${domain}.conf /etc/nginx/sites-available/${domain}"`);
  await execAsync(`ssh pi@${TARGET_HOST} "sudo ln -sf /etc/nginx/sites-available/${domain} /etc/nginx/sites-enabled/${domain}"`);

  // Test nginx config
  await execAsync(`ssh pi@${TARGET_HOST} "sudo nginx -t"`);
}

async function generateSSL(domain) {
  // Use certbot to generate Let's Encrypt certificate
  try {
    await execAsync(`ssh pi@${TARGET_HOST} "sudo certbot --nginx -d ${domain} --non-interactive --agree-tos --email admin@blackroad.io"`);
    console.log(`✅ SSL certificate generated for ${domain}`);
  } catch (error) {
    console.warn(`⚠️  SSL generation failed for ${domain}: ${error.message}`);
    // Continue anyway - cert can be generated manually
  }
}

// ========================================
// GITHUB WEBHOOK
// ========================================

app.post('/api/webhook/github', async (req, res) => {
  const { repository, ref } = req.body;

  if (!repository || !ref) {
    return res.status(400).json({ success: false, error: 'Invalid webhook payload' });
  }

  const repo_url = repository.clone_url;
  const branch = ref.replace('refs/heads/', '');

  console.log(`🔔 GitHub webhook received: ${repo_url} (${branch})`);

  // Trigger deployment (async, don't wait)
  setTimeout(async () => {
    try {
      // Look up domain from repository name or metadata
      const domain = repository.name + '.blackroad.io'; // Simple mapping

      await axios.post('http://localhost:9000/api/deploy', {
        domain,
        repo_url,
        branch
      });
    } catch (error) {
      console.error('Webhook deployment failed:', error.message);
    }
  }, 100);

  res.json({ success: true, message: 'Webhook received' });
});

// ========================================
// START SERVER
// ========================================

// Ensure deploy directory exists
(async () => {
  try {
    await fs.mkdir(DEPLOY_BASE_DIR, { recursive: true });
  } catch {}
})();

app.listen(PORT, () => {
  console.log('🚀 BlackRoad Deployment Engine');
  console.log('===============================');
  console.log(`🌐 Server running on port ${PORT}`);
  console.log(`📂 Deploy directory: ${DEPLOY_BASE_DIR}`);
  console.log(`🎯 Target host: ${TARGET_HOST} (${TARGET_IP})`);
  console.log(`📡 Registry API: ${REGISTRY_API}`);
  console.log('');
  console.log('Endpoints:');
  console.log(`  POST /api/deploy - Trigger deployment`);
  console.log(`  GET  /api/deploy/:id - Check deployment status`);
  console.log(`  GET  /api/domains - List deployed domains`);
  console.log(`  POST /api/webhook/github - GitHub webhook handler`);
  console.log('');
  console.log('🖤🛣️ BlackRoad Deployment System');
});
