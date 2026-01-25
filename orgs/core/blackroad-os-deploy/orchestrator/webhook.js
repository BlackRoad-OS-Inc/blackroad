/**
 * GitHub Webhook Receiver
 *
 * Receives GitHub push webhooks and triggers deployments
 */

const express = require('express');
const crypto = require('crypto');
const { execSync } = require('child_process');
const LanguageDetector = require('./detector');
const Builder = require('./builder');
const Deployer = require('./deployer');

const app = express();
app.use(express.json());

// Configuration
const WEBHOOK_SECRET = process.env.GITHUB_WEBHOOK_SECRET || 'your-secret-here';
const BUILD_DIR = process.env.BUILD_DIR || '/opt/blackroad/builds';
const PORT = process.env.WEBHOOK_PORT || 8080;

// Verify GitHub webhook signature
function verifySignature(req) {
  const signature = req.headers['x-hub-signature-256'];
  if (!signature) return false;

  const hmac = crypto.createHmac('sha256', WEBHOOK_SECRET);
  const digest = 'sha256=' + hmac.update(JSON.stringify(req.body)).digest('hex');

  return crypto.timingSafeEqual(Buffer.from(signature), Buffer.from(digest));
}

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// GitHub webhook endpoint
app.post('/webhook', async (req, res) => {
  console.log('Received webhook');

  // Verify signature
  if (!verifySignature(req)) {
    console.error('Invalid signature');
    return res.status(401).json({ error: 'Invalid signature' });
  }

  const event = req.headers['x-github-event'];

  // Only handle push events
  if (event !== 'push') {
    console.log(`Ignoring ${event} event`);
    return res.json({ message: 'Event ignored' });
  }

  const { repository, ref, after: commitSha } = req.body;
  const repoName = repository.name;
  const repoUrl = repository.clone_url;
  const branch = ref.split('/').pop();

  console.log(`Processing push to ${repoName}:${branch}`);

  // Respond quickly to GitHub
  res.json({ message: 'Deployment started', repository: repoName, branch });

  // Process deployment asynchronously
  try {
    await processDeployment(repoName, repoUrl, branch, commitSha);
  } catch (error) {
    console.error(`Deployment failed: ${error.message}`);
  }
});

async function processDeployment(repoName, repoUrl, branch, commitSha) {
  const projectDir = BUILD_DIR + '/' + repoName;

  console.log('\nDEPLOYING: ' + repoName + '\n');

  // Step 1: Clone or pull repository
  console.log('1. Cloning repository...');
  try {
    execSync(`rm -rf ${projectDir} && git clone ${repoUrl} ${projectDir}`, { stdio: 'inherit' });
  } catch (error) {
    throw new Error('Failed to clone repository: ' + error.message);
  }

  // Step 2: Detect language
  console.log('\n2. Detecting language...');
  const detector = new LanguageDetector(projectDir);
  const detection = detector.detect();
  console.log('   Language: ' + detection.language);
  console.log('   Framework: ' + detection.framework);
  console.log('   Port: ' + detector.getPort());

  // Step 3: Read deploy config
  console.log('\n3. Reading deploy config...');
  const config = readDeployConfig(projectDir);
  const deployConfig = {
    name: repoName,
    domain: config.domain || (repoName + '.blackroad.io'),
    target: config.target || 'droplet',
    port: config.port || detector.getPort(),
    env: config.env || {},
    ...detection,
  };
  console.log('   Domain: ' + deployConfig.domain);
  console.log('   Target: ' + deployConfig.target);

  // Step 4: Build Docker image
  console.log('\n4. Building Docker image...');
  const builder = new Builder(projectDir, deployConfig);
  const imageName = await builder.build();
  console.log('   Built: ' + imageName);

  // Step 5: Deploy to target
  console.log('\n5. Deploying to target...');
  const deployer = new Deployer(deployConfig);
  await deployer.deploy(imageName);
  console.log('   Deployed successfully');

  console.log('\nDEPLOYMENT COMPLETE');
  console.log('Live at: https://' + deployConfig.domain + '\n');
}

function readDeployConfig(projectDir) {
  const fs = require('fs');
  const yaml = require('js-yaml');
  const configPath = projectDir + '/deploy.yaml';

  try {
    if (fs.existsSync(configPath)) {
      return yaml.load(fs.readFileSync(configPath, 'utf8'));
    }
  } catch (error) {
    console.warn('Could not read deploy.yaml: ' + error.message);
  }

  return {};
}

// Start server
app.listen(PORT, () => {
  console.log('\nBlackRoad Deploy Orchestrator');
  console.log('Webhook endpoint: http://localhost:' + PORT + '/webhook');
  console.log('Health check: http://localhost:' + PORT + '/health');
  console.log('Build directory: ' + BUILD_DIR + '\n');
});

module.exports = app;
