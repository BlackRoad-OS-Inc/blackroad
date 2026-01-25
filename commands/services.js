import chalk from 'chalk';
import Table from 'cli-table3';
import { services, getAllServices } from '../lib/services.js';

export async function servicesCommand(options) {
  console.log(chalk.hex('#FF6B00').bold('\n  BlackRoad OS Services\n'));

  const categories = {
    core: { title: 'Core', data: services.core },
    infrastructure: { title: 'Infrastructure', data: services.infrastructure },
    services: { title: 'Services', data: services.services },
    web: { title: 'Web Properties', data: services.web }
  };

  // Filter by category if specified
  if (options.category) {
    const cat = options.category.toLowerCase();
    if (!categories[cat]) {
      console.log(chalk.red(`  Unknown category: ${cat}\n`));
      console.log(chalk.gray('  Available categories: core, infrastructure, services, web'));
      return;
    }

    printCategory(categories[cat].title, categories[cat].data);
    return;
  }

  // Print all categories
  for (const [key, cat] of Object.entries(categories)) {
    printCategory(cat.title, cat.data);
  }

  // Summary
  const all = getAllServices();
  const railwayCount = all.filter(s => s.railway).length;
  const cloudflareCount = all.filter(s => !s.railway).length;

  console.log(chalk.gray(`  Total: ${all.length} services`));
  console.log(chalk.gray(`  Railway: ${railwayCount} | Cloudflare: ${cloudflareCount}\n`));
}

function printCategory(title, serviceList) {
  console.log(chalk.white.bold(`  ${title}`));
  console.log(chalk.gray('  ' + '─'.repeat(50)));

  const table = new Table({
    chars: {
      'top': '', 'top-mid': '', 'top-left': '', 'top-right': '',
      'bottom': '', 'bottom-mid': '', 'bottom-left': '', 'bottom-right': '',
      'left': '  ', 'left-mid': '', 'mid': '', 'mid-mid': '',
      'right': '', 'right-mid': '', 'middle': ' '
    },
    style: { 'padding-left': 0, 'padding-right': 2 }
  });

  for (const service of serviceList) {
    const platform = service.railway
      ? chalk.hex('#7B2CBF')('Railway')
      : chalk.hex('#F48120')('CF Pages');

    table.push([
      chalk.white(service.name),
      chalk.cyan(`https://${service.url}`),
      platform
    ]);
  }

  console.log(table.toString());
  console.log();
}
