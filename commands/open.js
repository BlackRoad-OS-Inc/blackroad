import chalk from 'chalk';
import { exec } from 'child_process';
import { getServiceBySlug, getAllServices, dashboards } from '../lib/services.js';

const targets = {
  // Dashboards
  railway: { url: dashboards.railway, desc: 'Railway Dashboard' },
  cloudflare: { url: dashboards.cloudflare, desc: 'Cloudflare Dashboard' },
  cf: { url: dashboards.cloudflare, desc: 'Cloudflare Dashboard' },
  github: { url: dashboards.github, desc: 'GitHub Organization' },
  gh: { url: dashboards.github, desc: 'GitHub Organization' },
  status: { url: dashboards.status, desc: 'Status Page' },
  actions: { url: dashboards.actions, desc: 'GitHub Actions' },

  // Quick links
  docs: { url: 'https://docs.blackroad.io', desc: 'Documentation' },
  api: { url: 'https://api.blackroad.io', desc: 'API' },
  app: { url: 'https://app.blackroad.io', desc: 'App Console' },
  home: { url: 'https://blackroad.io', desc: 'Homepage' }
};

function openUrl(url) {
  const cmd = process.platform === 'darwin'
    ? `open "${url}"`
    : process.platform === 'win32'
      ? `start "${url}"`
      : `xdg-open "${url}"`;

  exec(cmd, (err) => {
    if (err) {
      console.log(chalk.red(`\n  Could not open browser: ${err.message}\n`));
    }
  });
}

export async function openCommand(target) {
  // Check if it's a known target
  if (targets[target.toLowerCase()]) {
    const t = targets[target.toLowerCase()];
    console.log(chalk.gray(`\n  Opening ${t.desc}...`));
    openUrl(t.url);
    return;
  }

  // Check if it's a service slug
  const service = getServiceBySlug(target);
  if (service) {
    console.log(chalk.gray(`\n  Opening ${service.name}...`));
    openUrl(`https://${service.url}`);
    return;
  }

  // Check if it looks like a URL
  if (target.includes('.') || target.startsWith('http')) {
    const url = target.startsWith('http') ? target : `https://${target}`;
    console.log(chalk.gray(`\n  Opening ${url}...`));
    openUrl(url);
    return;
  }

  // Unknown target
  console.log(chalk.red(`\n  Unknown target: "${target}"\n`));
  console.log(chalk.white.bold('  Available targets:\n'));

  console.log(chalk.gray('  Dashboards:'));
  console.log(chalk.cyan('    railway') + chalk.gray(' - Railway Dashboard'));
  console.log(chalk.cyan('    cloudflare') + chalk.gray(' (or cf) - Cloudflare Dashboard'));
  console.log(chalk.cyan('    github') + chalk.gray(' (or gh) - GitHub Organization'));
  console.log(chalk.cyan('    actions') + chalk.gray(' - GitHub Actions'));
  console.log(chalk.cyan('    status') + chalk.gray(' - Status Page'));

  console.log(chalk.gray('\n  Services:'));
  getAllServices().slice(0, 5).forEach(s => {
    console.log(chalk.cyan(`    ${s.slug}`) + chalk.gray(` - ${s.url}`));
  });
  console.log(chalk.gray('    ... and more'));

  console.log();
}
