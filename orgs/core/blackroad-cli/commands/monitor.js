import chalk from 'chalk';
import blessed from 'blessed';
import { spawn } from 'child_process';

class SystemMonitor {
  constructor() {
    this.screen = null;
    this.widgets = {};
    this.updateInterval = null;
    this.hosts = [
      { name: 'ARIA', host: '192.168.4.64', user: 'alexa', color: '#FF9D00' },
      { name: 'CODEX', host: '159.65.43.12', user: 'root', color: '#FF6B00' },
      { name: 'SHELLFISH', host: '174.138.44.45', user: 'root', color: '#FF0066' },
      { name: 'ALICE', host: '192.168.4.49', user: 'alice', color: '#D600AA' },
      { name: 'LUCIDIA', host: '192.168.4.38', user: 'lucidia', color: '#7700FF' }
    ];
    this.systemStats = {};
  }

  createScreen() {
    this.screen = blessed.screen({
      smartCSR: true,
      title: 'BlackRoad OS - System Monitor',
      fullUnicode: true
    });

    this.screen.key(['escape', 'q', 'C-c'], () => {
      this.cleanup();
      process.exit(0);
    });

    // Refresh on 'r'
    this.screen.key(['r'], () => {
      this.refreshAll();
    });

    return this.screen;
  }

  createLayout() {
    // Title bar
    this.widgets.title = blessed.box({
      parent: this.screen,
      top: 0,
      left: 0,
      width: '100%',
      height: 3,
      content: '{center}{bold}🖥️  BLACKROAD OS SYSTEM MONITOR{/bold}{/center}',
      tags: true,
      style: {
        fg: 'white',
        bg: '#FF6B00',
        bold: true
      }
    });

    // Host grid (2 columns, 3 rows for 5 hosts + 1 summary)
    const hostWidth = '50%';
    const hostHeight = '24%';
    const positions = [
      { top: '10%', left: '0%' },
      { top: '10%', left: '50%' },
      { top: '34%', left: '0%' },
      { top: '34%', left: '50%' },
      { top: '58%', left: '0%' }
    ];

    this.hosts.forEach((host, idx) => {
      this.createHostWidget(host, positions[idx], hostWidth, hostHeight);
    });

    // Summary panel (bottom right)
    this.createSummaryWidget({ top: '58%', left: '50%' }, hostWidth, hostHeight);

    // Footer with stats
    this.widgets.footer = blessed.box({
      parent: this.screen,
      bottom: 0,
      left: 0,
      width: '100%',
      height: 3,
      content: '',
      tags: true,
      style: {
        bg: 'black',
        fg: 'white'
      }
    });

    // Network traffic gauge
    this.widgets.networkGauge = blessed.box({
      parent: this.screen,
      top: '82%',
      left: '0%',
      width: '100%',
      height: '8%',
      label: ' Network Traffic ',
      border: {
        type: 'line'
      },
      style: {
        border: {
          fg: '#0066FF'
        }
      },
      tags: true
    });
  }

  createHostWidget(host, position, width, height) {
    const widget = blessed.box({
      parent: this.screen,
      ...position,
      width,
      height,
      label: ` ${host.name} (${host.host}) `,
      border: {
        type: 'line'
      },
      style: {
        border: {
          fg: host.color
        }
      },
      scrollable: true,
      tags: true
    });

    this.widgets[host.name] = widget;
    this.systemStats[host.name] = {
      cpu: 0,
      memory: 0,
      disk: 0,
      uptime: 0,
      processes: 0,
      load: [0, 0, 0],
      status: 'connecting'
    };
  }

  createSummaryWidget(position, width, height) {
    const widget = blessed.box({
      parent: this.screen,
      ...position,
      width,
      height,
      label: ' 📊 INFRASTRUCTURE SUMMARY ',
      border: {
        type: 'line'
      },
      style: {
        border: {
          fg: '#00FFAA'
        }
      },
      tags: true
    });

    this.widgets.SUMMARY = widget;
  }

  async getHostStats(host) {
    return new Promise((resolve) => {
      const commands = `
        echo "CPU:\$(top -bn1 | grep 'Cpu(s)' | sed 's/.*, *\\([0-9.]*\\)%* id.*/\\1/' | awk '{print 100 - \$1}')";
        echo "MEM:\$(free -m | awk 'NR==2{printf "%.1f", \$3*100/\$2}')";
        echo "DISK:\$(df -h / | awk 'NR==2{print \$5}' | sed 's/%//')";
        echo "UPTIME:\$(uptime -p)";
        echo "PROCS:\$(ps aux | wc -l)";
        echo "LOAD:\$(uptime | awk -F'load average:' '{print \$2}')";
      `;

      const proc = spawn('ssh', [
        '-o', 'ConnectTimeout=3',
        '-o', 'BatchMode=yes',
        `${host.user}@${host.host}`,
        commands
      ], {
        stdio: 'pipe'
      });

      let output = '';
      proc.stdout.on('data', (data) => output += data.toString());

      const timeout = setTimeout(() => {
        proc.kill();
        resolve({
          status: 'timeout',
          cpu: 0,
          memory: 0,
          disk: 0,
          uptime: 'timeout',
          processes: 0,
          load: [0, 0, 0]
        });
      }, 5000);

      proc.on('close', (code) => {
        clearTimeout(timeout);
        if (code !== 0) {
          resolve({
            status: 'error',
            cpu: 0,
            memory: 0,
            disk: 0,
            uptime: 'offline',
            processes: 0,
            load: [0, 0, 0]
          });
          return;
        }

        const lines = output.split('\n');
        const stats = {};

        lines.forEach(line => {
          if (line.startsWith('CPU:')) stats.cpu = parseFloat(line.split(':')[1]) || 0;
          if (line.startsWith('MEM:')) stats.memory = parseFloat(line.split(':')[1]) || 0;
          if (line.startsWith('DISK:')) stats.disk = parseFloat(line.split(':')[1]) || 0;
          if (line.startsWith('UPTIME:')) stats.uptime = line.split(':').slice(1).join(':').trim();
          if (line.startsWith('PROCS:')) stats.processes = parseInt(line.split(':')[1]) || 0;
          if (line.startsWith('LOAD:')) {
            const loads = line.split(':')[1].trim().split(',').map(l => parseFloat(l.trim()));
            stats.load = loads.length === 3 ? loads : [0, 0, 0];
          }
        });

        resolve({
          status: 'online',
          ...stats
        });
      });

      proc.on('error', () => {
        clearTimeout(timeout);
        resolve({
          status: 'error',
          cpu: 0,
          memory: 0,
          disk: 0,
          uptime: 'error',
          processes: 0,
          load: [0, 0, 0]
        });
      });
    });
  }

  renderHostStats(hostName) {
    const stats = this.systemStats[hostName];
    const widget = this.widgets[hostName];

    if (!widget) return;

    let content = '';

    if (stats.status === 'connecting') {
      content = '{center}{yellow-fg}Connecting...{/yellow-fg}{/center}';
    } else if (stats.status === 'error' || stats.status === 'timeout') {
      content = '{center}{red-fg}● OFFLINE{/red-fg}{/center}\n\n';
      content += `{gray-fg}Status: ${stats.status}{/gray-fg}`;
    } else {
      const cpuColor = stats.cpu > 80 ? 'red' : stats.cpu > 50 ? 'yellow' : 'green';
      const memColor = stats.memory > 80 ? 'red' : stats.memory > 50 ? 'yellow' : 'green';
      const diskColor = stats.disk > 80 ? 'red' : stats.disk > 50 ? 'yellow' : 'green';

      content = `{center}{green-fg}● ONLINE{/green-fg}{/center}\n\n`;
      content += `{bold}CPU:{/bold} {${cpuColor}-fg}${stats.cpu.toFixed(1)}%{/${cpuColor}-fg} ${this.getBar(stats.cpu)}\n`;
      content += `{bold}RAM:{/bold} {${memColor}-fg}${stats.memory.toFixed(1)}%{/${memColor}-fg} ${this.getBar(stats.memory)}\n`;
      content += `{bold}DISK:{/bold} {${diskColor}-fg}${stats.disk.toFixed(0)}%{/${diskColor}-fg} ${this.getBar(stats.disk)}\n\n`;
      content += `{gray-fg}Load: ${stats.load.map(l => l.toFixed(2)).join(', ')}{/gray-fg}\n`;
      content += `{gray-fg}Procs: ${stats.processes}{/gray-fg}\n`;
      content += `{gray-fg}Uptime: ${stats.uptime}{/gray-fg}`;
    }

    widget.setContent(content);
  }

  getBar(percentage) {
    const width = 10;
    const filled = Math.round((percentage / 100) * width);
    const bar = '█'.repeat(filled) + '░'.repeat(width - filled);
    return `[${bar}]`;
  }

  renderSummary() {
    const hosts = Object.values(this.systemStats);
    const online = hosts.filter(h => h.status === 'online').length;
    const offline = hosts.length - online;

    const avgCpu = hosts.reduce((sum, h) => sum + h.cpu, 0) / hosts.length;
    const avgMem = hosts.reduce((sum, h) => sum + h.memory, 0) / hosts.length;
    const totalProcs = hosts.reduce((sum, h) => sum + h.processes, 0);

    let content = `{center}{bold}FLEET STATUS{/bold}{/center}\n\n`;
    content += `{green-fg}● Online:{/green-fg}  ${online}/${hosts.length}\n`;
    if (offline > 0) {
      content += `{red-fg}● Offline:{/red-fg} ${offline}/${hosts.length}\n`;
    }
    content += `\n{bold}Average Metrics:{/bold}\n`;
    content += `CPU:  ${avgCpu.toFixed(1)}%\n`;
    content += `RAM:  ${avgMem.toFixed(1)}%\n`;
    content += `Procs: ${totalProcs}\n`;
    content += `\n{cyan-fg}Press 'r' to refresh{/cyan-fg}`;

    this.widgets.SUMMARY.setContent(content);
  }

  updateFooter() {
    const now = new Date();
    const timeStr = now.toLocaleTimeString();
    const dateStr = now.toLocaleDateString();

    const online = Object.values(this.systemStats).filter(s => s.status === 'online').length;

    const footer = `{bold}BlackRoad Monitor{/bold} | ` +
      `{green-fg}${online}/${this.hosts.length} online{/green-fg} | ` +
      `{cyan-fg}R{/cyan-fg}=Refresh {cyan-fg}Q{/cyan-fg}=Quit | ` +
      `{yellow-fg}${timeStr} ${dateStr}{/yellow-fg}`;

    this.widgets.footer.setContent(footer);
  }

  updateNetworkGauge() {
    // Simulate network traffic visualization
    const width = this.widgets.networkGauge.width - 4;
    const bars = [];

    for (let i = 0; i < 20; i++) {
      const height = Math.random() * 10;
      const bar = Math.round(height);
      const barChar = bar > 7 ? '{red-fg}█{/red-fg}' :
                      bar > 4 ? '{yellow-fg}█{/yellow-fg}' :
                      '{green-fg}█{/green-fg}';
      bars.push(barChar.repeat(bar));
    }

    const content = bars.join(' ');
    this.widgets.networkGauge.setContent(content);
  }

  async refreshAll() {
    // Update all host stats in parallel
    const updates = this.hosts.map(async (host) => {
      this.systemStats[host.name] = { ...this.systemStats[host.name], status: 'connecting' };
      this.renderHostStats(host.name);
      this.screen.render();

      const stats = await this.getHostStats(host);
      this.systemStats[host.name] = stats;
      this.renderHostStats(host.name);
    });

    await Promise.all(updates);

    this.renderSummary();
    this.updateFooter();
    this.updateNetworkGauge();
    this.screen.render();
  }

  startAutoUpdate(interval = 5000) {
    this.updateInterval = setInterval(() => {
      this.refreshAll();
    }, interval);
  }

  cleanup() {
    if (this.updateInterval) {
      clearInterval(this.updateInterval);
    }
    if (this.screen) {
      this.screen.destroy();
    }
  }

  async start() {
    console.log(chalk.hex('#FF6B00').bold('\n  🖥️  Starting BlackRoad System Monitor...\n'));

    this.createScreen();
    this.createLayout();

    // Initial render
    this.screen.render();

    // Show loading message
    const loading = blessed.box({
      parent: this.screen,
      top: 'center',
      left: 'center',
      width: 40,
      height: 5,
      content: '{center}{yellow-fg}Loading system stats...{/yellow-fg}{/center}',
      tags: true,
      border: {
        type: 'line'
      },
      style: {
        border: {
          fg: '#FF6B00'
        }
      }
    });

    this.screen.render();

    // Initial data fetch
    await this.refreshAll();

    // Remove loading message
    loading.destroy();

    // Start auto-updates every 5 seconds
    this.startAutoUpdate(5000);

    this.screen.render();
  }
}

export async function monitorCommand(options) {
  const monitor = new SystemMonitor();

  try {
    await monitor.start();
  } catch (e) {
    console.log(chalk.red(`\n  ❌ Failed to start monitor: ${e.message}\n`));
    process.exit(1);
  }
}
