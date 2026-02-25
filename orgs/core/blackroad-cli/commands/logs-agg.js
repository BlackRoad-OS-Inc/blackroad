import chalk from 'chalk';
import blessed from 'blessed';
import { spawn } from 'child_process';
import fs from 'fs/promises';
import path from 'path';

const LOG_SOURCES = {
  aria: { name: 'ARIA', host: '192.168.4.64', user: 'alexa', logPath: '/var/log/syslog', color: '#FF9D00' },
  codex: { name: 'CODEX', host: '159.65.43.12', user: 'root', logPath: '/var/log/syslog', color: '#FF6B00' },
  shellfish: { name: 'SHELLFISH', host: '174.138.44.45', user: 'root', logPath: '/var/log/syslog', color: '#FF0066' },
  lucidia: { name: 'LUCIDIA', host: '192.168.4.38', user: 'lucidia', logPath: '/var/log/syslog', color: '#7700FF' }
};

class LogAggregator {
  constructor() {
    this.screen = null;
    this.logBoxes = {};
    this.logStreams = {};
    this.filters = {
      level: null,
      search: null
    };
  }

  createScreen() {
    this.screen = blessed.screen({
      smartCSR: true,
      title: 'BlackRoad Log Aggregator',
      fullUnicode: true
    });

    this.screen.key(['escape', 'q', 'C-c'], () => {
      this.cleanup();
      process.exit(0);
    });

    // Filter shortcuts
    this.screen.key(['e'], () => this.setFilter('ERROR'));
    this.screen.key(['w'], () => this.setFilter('WARN'));
    this.screen.key(['i'], () => this.setFilter('INFO'));
    this.screen.key(['c'], () => this.clearFilter());
    this.screen.key(['/'], () => this.searchPrompt());

    return this.screen;
  }

  createLayout() {
    // Title
    this.titleBox = blessed.box({
      parent: this.screen,
      top: 0,
      left: 0,
      width: '100%',
      height: 3,
      content: '{center}{bold}📊 LOG AGGREGATOR - Press E=Error W=Warn I=Info C=Clear /=Search Q=Quit{/bold}{/center}',
      tags: true,
      style: {
        fg: 'white',
        bg: '#FF6B00'
      }
    });

    // Create 4-panel grid for log sources
    const sources = Object.entries(LOG_SOURCES);
    const positions = [
      { top: '10%', left: '0%', width: '50%', height: '43%' },
      { top: '10%', left: '50%', width: '50%', height: '43%' },
      { top: '53%', left: '0%', width: '50%', height: '43%' },
      { top: '53%', left: '50%', width: '50%', height: '43%' }
    ];

    sources.forEach(([key, source], idx) => {
      this.createLogBox(key, source, positions[idx]);
    });

    // Filter status bar
    this.filterBox = blessed.box({
      parent: this.screen,
      bottom: 0,
      left: 0,
      width: '100%',
      height: 1,
      content: '',
      tags: true,
      style: {
        bg: 'black',
        fg: 'white'
      }
    });

    this.updateFilterBox();
  }

  createLogBox(key, source, position) {
    const box = blessed.box({
      parent: this.screen,
      ...position,
      label: ` ${source.name} (${source.host}) `,
      border: {
        type: 'line'
      },
      style: {
        border: {
          fg: source.color
        }
      },
      scrollable: true,
      alwaysScroll: true,
      scrollbar: {
        ch: '█',
        style: {
          fg: source.color
        }
      },
      mouse: true,
      keys: true,
      vi: true,
      tags: true
    });

    // Scrolling
    box.key(['up', 'k'], () => {
      box.scroll(-1);
      this.screen.render();
    });

    box.key(['down', 'j'], () => {
      box.scroll(1);
      this.screen.render();
    });

    this.logBoxes[key] = box;
  }

  startLogStream(key, source) {
    const command = `tail -f ${source.logPath}`;

    const proc = spawn('ssh', [
      '-o', 'ConnectTimeout=5',
      `${source.user}@${source.host}`,
      command
    ], {
      stdio: 'pipe'
    });

    let buffer = [];

    proc.stdout.on('data', (data) => {
      const lines = data.toString().split('\n');

      lines.forEach(line => {
        if (!line.trim()) return;

        // Apply filters
        if (this.filters.level) {
          if (!line.includes(this.filters.level)) return;
        }

        if (this.filters.search) {
          if (!line.toLowerCase().includes(this.filters.search.toLowerCase())) return;
        }

        // Color code log levels
        let coloredLine = line;
        if (line.includes('ERROR') || line.includes('error')) {
          coloredLine = `{red-fg}${line}{/red-fg}`;
        } else if (line.includes('WARN') || line.includes('warning')) {
          coloredLine = `{yellow-fg}${line}{/yellow-fg}`;
        } else if (line.includes('INFO') || line.includes('info')) {
          coloredLine = `{green-fg}${line}{/green-fg}`;
        }

        buffer.push(coloredLine);

        // Keep last 100 lines
        if (buffer.length > 100) {
          buffer.shift();
        }

        const box = this.logBoxes[key];
        box.setContent(buffer.join('\n'));
        box.setScrollPerc(100);
        this.screen.render();
      });
    });

    proc.on('error', (err) => {
      const box = this.logBoxes[key];
      box.setContent(`{red-fg}Connection error: ${err.message}{/red-fg}`);
      this.screen.render();
    });

    this.logStreams[key] = { proc, buffer };
  }

  setFilter(level) {
    this.filters.level = level;
    this.updateFilterBox();
    this.refreshAllLogs();
  }

  clearFilter() {
    this.filters.level = null;
    this.filters.search = null;
    this.updateFilterBox();
    this.refreshAllLogs();
  }

  searchPrompt() {
    const input = blessed.textbox({
      parent: this.screen,
      top: 'center',
      left: 'center',
      width: 40,
      height: 3,
      label: ' Search ',
      border: {
        type: 'line'
      },
      style: {
        border: {
          fg: '#FF6B00'
        }
      },
      inputOnFocus: true
    });

    input.focus();
    this.screen.render();

    input.on('submit', (value) => {
      this.filters.search = value || null;
      this.updateFilterBox();
      this.refreshAllLogs();
      input.destroy();
      this.screen.render();
    });

    input.on('cancel', () => {
      input.destroy();
      this.screen.render();
    });
  }

  updateFilterBox() {
    let content = '{bold}Filters:{/bold} ';

    if (this.filters.level) {
      content += `Level: {yellow-fg}${this.filters.level}{/yellow-fg} `;
    }

    if (this.filters.search) {
      content += `Search: {cyan-fg}${this.filters.search}{/cyan-fg} `;
    }

    if (!this.filters.level && !this.filters.search) {
      content += '{gray-fg}None (showing all logs){/gray-fg}';
    }

    this.filterBox.setContent(content);
    this.screen.render();
  }

  refreshAllLogs() {
    // Clear all buffers and restart streams
    Object.keys(this.logStreams).forEach(key => {
      this.logStreams[key].buffer = [];
      this.logBoxes[key].setContent('');
    });
    this.screen.render();
  }

  cleanup() {
    Object.values(this.logStreams).forEach(stream => {
      if (stream.proc) {
        stream.proc.kill();
      }
    });

    if (this.screen) {
      this.screen.destroy();
    }
  }

  async start() {
    console.log(chalk.hex('#FF6B00').bold('\n  📊 Starting Log Aggregator...\n'));

    this.createScreen();
    this.createLayout();

    // Show connecting message
    Object.values(this.logBoxes).forEach(box => {
      box.setContent('{center}{yellow-fg}Connecting...{/yellow-fg}{/center}');
    });

    this.screen.render();

    // Start log streams
    Object.entries(LOG_SOURCES).forEach(([key, source]) => {
      this.startLogStream(key, source);
    });

    this.screen.render();
  }
}

export async function logsAggCommand(options) {
  const aggregator = new LogAggregator();

  try {
    await aggregator.start();
  } catch (e) {
    console.log(chalk.red(`\n  ❌ Failed to start log aggregator: ${e.message}\n`));
    process.exit(1);
  }
}
