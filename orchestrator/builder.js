/**
 * Docker Build Engine
 *
 * Builds Docker images for detected languages
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

class Builder {
  constructor(projectDir, config) {
    this.projectDir = projectDir;
    this.config = config;
  }

  async build() {
    const imageName = `blackroad/${this.config.name}:latest`;
    const dockerfilePath = this.getDockerfile();

    console.log(`   Using Dockerfile: ${dockerfilePath}`);

    // Copy appropriate Dockerfile to project
    const targetDockerfile = path.join(this.projectDir, 'Dockerfile');
    fs.copyFileSync(dockerfilePath, targetDockerfile);

    // Build Docker image
    try {
      execSync(
        `docker build -t ${imageName} ${this.projectDir}`,
        { stdio: 'inherit' }
      );
    } catch (error) {
      throw new Error('Docker build failed: ' + error.message);
    }

    return imageName;
  }

  getDockerfile() {
    const dockerfilesDir = path.join(__dirname, '..', 'dockerfiles');
    const dockerfileName = this.config.dockerfile || 'Dockerfile.nodejs';
    const dockerfilePath = path.join(dockerfilesDir, dockerfileName);

    if (!fs.existsSync(dockerfilePath)) {
      throw new Error('Dockerfile not found: ' + dockerfilePath);
    }

    return dockerfilePath;
  }
}

module.exports = Builder;
