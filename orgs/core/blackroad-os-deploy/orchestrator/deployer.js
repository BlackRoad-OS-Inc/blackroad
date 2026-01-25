/**
 * Deployment Router
 *
 * Deploys Docker containers to target servers (Droplet or Pis)
 */

const { execSync } = require('child_process');

class Deployer {
  constructor(config) {
    this.config = config;
    this.targets = {
      droplet: {
        host: '159.65.43.12',
        user: 'root',
      },
      'pi-lucidia': {
        host: '192.168.4.38',
        user: 'pi',
      },
      'pi-blackroad': {
        host: '192.168.4.64',
        user: 'pi',
      },
      'pi-lucidia-alt': {
        host: '192.168.4.99',
        user: 'pi',
      },
    };
  }

  async deploy(imageName) {
    const target = this.targets[this.config.target];

    if (!target) {
      throw new Error('Unknown target: ' + this.config.target);
    }

    console.log('   Target: ' + this.config.target + ' (' + target.host + ')');

    // Save Docker image to tar
    const imageFile = '/tmp/' + this.config.name + '.tar';
    console.log('   Saving image...');
    execSync(`docker save ${imageName} -o ${imageFile}`);

    // Copy image to target
    console.log('   Copying to target...');
    execSync(`scp ${imageFile} ${target.user}@${target.host}:/tmp/`);

    // Load and run on target
    console.log('   Loading and starting container...');
    const commands = [
      `docker load -i /tmp/${this.config.name}.tar`,
      `docker stop ${this.config.name} || true`,
      `docker rm ${this.config.name} || true`,
      `docker run -d --name ${this.config.name} --restart unless-stopped -p ${this.config.port}:${this.config.port} ${this.buildEnvFlags()} ${imageName}`,
      `rm /tmp/${this.config.name}.tar`,
    ];

    execSync(`ssh ${target.user}@${target.host} '${commands.join(' && ')}'`);

    // Clean up local tar file
    execSync(`rm ${imageFile}`);

    console.log('   Container started on port ' + this.config.port);
  }

  buildEnvFlags() {
    const envVars = this.config.env || {};
    return Object.entries(envVars)
      .map(([key, value]) => `-e ${key}="${value}"`)
      .join(' ');
  }
}

module.exports = Deployer;
