import chalk from 'chalk';
import { spawn } from 'child_process';
import blessed from 'blessed';
import ora from 'ora';
import { ClaudeProvider, OllamaProvider, InternetProvider } from '../lib/ai-providers.js';

// Window configurations
const WINDOWS = {
  aria: {
    name: 'ARIA',
    host: '192.168.4.64',
    user: 'alexa',
    color: '#FF9D00',
    type: 'ssh'
  },
  codex: {
    name: 'CODEX',
    host: '159.65.43.12',
    user: 'root',
    color: '#FF6B00',
    type: 'ssh'
  },
  shellfish: {
    name: 'SHELLFISH',
    host: '174.138.44.45',
    user: 'root',
    color: '#FF0066',
    type: 'ssh'
  },
  alice: {
    name: 'ALICE',
    host: '192.168.4.49',
    user: 'alice',
    color: '#D600AA',
    type: 'ssh'
  },
  lucidia: {
    name: 'LUCIDIA',
    host: '192.168.4.38',
    user: 'lucidia',
    color: '#7700FF',
    type: 'ssh'
  },
  claude: {
    name: 'CLAUDE',
    color: '#0066FF',
    type: 'ai',
    provider: 'anthropic'
  },
  ollama: {
    name: 'OLLAMA',
    color: '#00FFAA',
    type: 'ai',
    provider: 'local'
  }
};

class WindowManager {
  constructor() {
    this.screen = null;
    this.windows = {};
    this.processes = {};
    this.outputs = {};
    this.focusedWindow = null;
    this.clipboardData = '';
    this.updateInterval = null;
    this.inputBuffers = {};
    this.aiProviders = {
      claude: new ClaudeProvider(),
      ollama: new OllamaProvider()
    };
    this.internetProvider = new InternetProvider();
  }

  createScreen() {
    this.screen = blessed.screen({
      smartCSR: true,
      title: 'BlackRoad OS - Multi-Window Terminal',
      fullUnicode: true,
      dockBorders: true
    });

    // Global key bindings
    this.screen.key(['escape', 'q', 'C-c'], () => {
      this.cleanup();
      return process.exit(0);
    });

    // Tab to switch windows
    this.screen.key(['tab'], () => {
      this.switchToNextWindow();
    });

    // Copy/paste bindings
    this.screen.key(['C-y'], () => {
      this.copyFromFocusedWindow();
    });

    this.screen.key(['C-p'], () => {
      this.pasteToFocusedWindow();
    });

    return this.screen;
  }

  createWindow(windowId, config, layout) {
    const box = blessed.box({
      parent: this.screen,
      ...layout,
      label: ` ${config.name} `,
      border: {
        type: 'line'
      },
      style: {
        border: {
          fg: config.color
        },
        focus: {
          border: {
            fg: 'white'
          }
        }
      },
      scrollable: true,
      alwaysScroll: true,
      scrollbar: {
        ch: '█',
        style: {
          fg: config.color
        }
      },
      mouse: true,
      keys: true,
      vi: true,
      tags: true
    });

    // Enable scrolling
    box.key(['up', 'k'], () => {
      box.scroll(-1);
      this.screen.render();
    });

    box.key(['down', 'j'], () => {
      box.scroll(1);
      this.screen.render();
    });

    box.key(['pageup'], () => {
      box.scroll(-box.height);
      this.screen.render();
    });

    box.key(['pagedown'], () => {
      box.scroll(box.height);
      this.screen.render();
    });

    // Focus on click
    box.on('click', () => {
      this.focusWindow(windowId);
    });

    this.windows[windowId] = box;
    this.outputs[windowId] = [];

    return box;
  }

  createLayout() {
    // 3x3 grid layout (7 windows total)
    const layouts = {
      aria: { top: '0%', left: '0%', width: '33%', height: '33%' },
      codex: { top: '0%', left: '33%', width: '34%', height: '33%' },
      shellfish: { top: '0%', left: '67%', width: '33%', height: '33%' },
      alice: { top: '33%', left: '0%', width: '33%', height: '34%' },
      lucidia: { top: '33%', left: '33%', width: '34%', height: '34%' },
      claude: { top: '33%', left: '67%', width: '33%', height: '34%' },
      ollama: { top: '67%', left: '0%', width: '100%', height: '33%' }
    };

    Object.entries(WINDOWS).forEach(([id, config]) => {
      this.createWindow(id, config, layouts[id]);
    });
  }

  startSSHProcess(windowId, config) {
    const proc = spawn('ssh', [
      '-o', 'ConnectTimeout=5',
      '-o', 'ServerAliveInterval=5',
      `${config.user}@${config.host}`
    ], {
      stdio: ['pipe', 'pipe', 'pipe'],
      shell: false
    });

    this.processes[windowId] = proc;

    proc.stdout.on('data', (data) => {
      this.appendOutput(windowId, data.toString());
    });

    proc.stderr.on('data', (data) => {
      this.appendOutput(windowId, chalk.red(data.toString()));
    });

    proc.on('close', (code) => {
      this.appendOutput(windowId, chalk.yellow(`\n[Connection closed with code ${code}]`));
    });

    proc.on('error', (err) => {
      this.appendOutput(windowId, chalk.red(`\n[Error: ${err.message}]`));
    });

    // Initial connection message
    this.appendOutput(windowId, chalk.green(`Connecting to ${config.user}@${config.host}...\n`));
  }

  startClaudeWindow(windowId) {
    const content = `{#${WINDOWS[windowId].color}-fg}╔═══════════════════════════════╗
║   CLAUDE AI INTERFACE         ║
║   Anthropic Claude 3.5        ║
╚═══════════════════════════════╝{/#${WINDOWS[windowId].color}-fg}

{cyan-fg}Type your message and press Enter to chat.
Commands:
  /clear  - Clear conversation
  /help   - Show help
  /web <url> - Fetch web content{/cyan-fg}

{yellow-fg}Ready to assist!{/yellow-fg}

> `;

    this.appendOutput(windowId, content);
    this.inputBuffers[windowId] = '';
    this.setupAIInput(windowId, 'claude');
  }

  startOllamaWindow(windowId) {
    const content = `{#${WINDOWS[windowId].color}-fg}╔═══════════════════════════════════════════════════════════╗
║   OLLAMA LOCAL AI                                         ║
║   Running: llama3.2, codellama, mistral                   ║
╚═══════════════════════════════════════════════════════════╝{/#${WINDOWS[windowId].color}-fg}

{cyan-fg}Commands:
  /model <name> - Switch model
  /models       - List available models
  /clear        - Clear conversation
  /ping <host>  - Ping a host
  /curl <url>   - Fetch URL{/cyan-fg}

{yellow-fg}Current model: llama3.2
Ready!{/yellow-fg}

> `;

    this.appendOutput(windowId, content);
    this.inputBuffers[windowId] = '';
    this.setupAIInput(windowId, 'ollama');
  }

  setupAIInput(windowId, providerType) {
    const box = this.windows[windowId];
    const provider = this.aiProviders[providerType];

    box.on('keypress', async (ch, key) => {
      if (key.name === 'return') {
        const input = this.inputBuffers[windowId].trim();
        if (!input) return;

        this.inputBuffers[windowId] = '';

        // Handle commands
        if (input.startsWith('/')) {
          const [cmd, ...args] = input.slice(1).split(' ');

          if (cmd === 'clear') {
            const msg = provider.clear();
            this.appendOutput(windowId, msg + '\n> ');
          } else if (cmd === 'help') {
            this.appendOutput(windowId, '{cyan-fg}Available commands:{/cyan-fg}\n' +
              '/clear - Clear conversation\n' +
              '/help - Show this message\n\n> ');
          } else if (cmd === 'model' && providerType === 'ollama') {
            const modelName = args.join(' ');
            const msg = await provider.switchModel(modelName);
            this.appendOutput(windowId, msg + '\n> ');
          } else if (cmd === 'models' && providerType === 'ollama') {
            const msg = await provider.listModels();
            this.appendOutput(windowId, msg + '\n> ');
          } else if (cmd === 'web') {
            const url = args.join(' ');
            const msg = await this.internetProvider.fetch(url);
            this.appendOutput(windowId, msg + '\n> ');
          } else if (cmd === 'ping') {
            const host = args.join(' ');
            const msg = await this.internetProvider.ping(host);
            this.appendOutput(windowId, msg + '\n> ');
          } else if (cmd === 'curl') {
            const url = args.join(' ');
            const msg = await this.internetProvider.curl(url);
            this.appendOutput(windowId, msg + '\n> ');
          }
        } else {
          // Regular chat
          this.appendOutput(windowId, '{green-fg}[Processing...]{/green-fg}\n');
          const response = await provider.chat(input);
          this.appendOutput(windowId, response + '\n> ');
        }

      } else if (key.name === 'backspace') {
        this.inputBuffers[windowId] = this.inputBuffers[windowId].slice(0, -1);
        this.updateInputLine(windowId);
      } else if (ch && !key.ctrl && !key.meta) {
        this.inputBuffers[windowId] += ch;
        this.updateInputLine(windowId);
      }
    });
  }

  updateInputLine(windowId) {
    // Update the last line to show current input
    const currentOutput = this.outputs[windowId].join('');
    const lastPromptIndex = currentOutput.lastIndexOf('> ');

    if (lastPromptIndex !== -1) {
      const beforePrompt = currentOutput.substring(0, lastPromptIndex + 2);
      this.outputs[windowId] = [beforePrompt + this.inputBuffers[windowId]];
      this.updateWindow(windowId);
    }
  }

  appendOutput(windowId, text) {
    this.outputs[windowId].push(text);

    // Keep last 1000 lines
    if (this.outputs[windowId].length > 1000) {
      this.outputs[windowId].shift();
    }

    this.updateWindow(windowId);
  }

  updateWindow(windowId) {
    const box = this.windows[windowId];
    if (box) {
      const content = this.outputs[windowId].join('');
      box.setContent(content);
      box.setScrollPerc(100); // Auto-scroll to bottom
      this.screen.render();
    }
  }

  focusWindow(windowId) {
    if (this.focusedWindow) {
      this.windows[this.focusedWindow].style.border.fg = WINDOWS[this.focusedWindow].color;
    }

    this.focusedWindow = windowId;
    this.windows[windowId].focus();
    this.windows[windowId].style.border.fg = 'white';
    this.screen.render();
  }

  switchToNextWindow() {
    const ids = Object.keys(WINDOWS);
    const currentIndex = ids.indexOf(this.focusedWindow);
    const nextIndex = (currentIndex + 1) % ids.length;
    this.focusWindow(ids[nextIndex]);
  }

  copyFromFocusedWindow() {
    if (this.focusedWindow) {
      const content = this.outputs[this.focusedWindow].join('');
      this.clipboardData = content;

      // Show notification
      const notification = blessed.box({
        parent: this.screen,
        top: 'center',
        left: 'center',
        width: 30,
        height: 3,
        content: '{center}{green-fg}Copied to clipboard!{/green-fg}{/center}',
        tags: true,
        border: {
          type: 'line'
        },
        style: {
          border: {
            fg: 'green'
          }
        }
      });

      this.screen.render();

      setTimeout(() => {
        notification.destroy();
        this.screen.render();
      }, 1000);
    }
  }

  pasteToFocusedWindow() {
    if (this.focusedWindow && this.clipboardData) {
      const proc = this.processes[this.focusedWindow];
      if (proc && proc.stdin) {
        proc.stdin.write(this.clipboardData);
      }
    }
  }

  startAutoUpdate() {
    // Update all windows every second
    this.updateInterval = setInterval(() => {
      // Ping all SSH connections to keep them alive
      Object.entries(this.processes).forEach(([windowId, proc]) => {
        if (proc && proc.stdin && WINDOWS[windowId].type === 'ssh') {
          // Send keepalive (empty command)
          proc.stdin.write('echo -n ""\n');
        }
      });

      // Update status bar
      this.updateStatusBar();

      this.screen.render();
    }, 1000);
  }

  updateStatusBar() {
    // Create status bar at bottom
    if (!this.statusBar) {
      this.statusBar = blessed.box({
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
    }

    const now = new Date().toLocaleTimeString();
    const activeConnections = Object.keys(this.processes).length;

    const status = `{bold}BlackRoad OS Multi-Window{/bold} | ` +
      `{green-fg}${activeConnections} active{/green-fg} | ` +
      `{cyan-fg}Tab{/cyan-fg}=Switch {cyan-fg}C-y{/cyan-fg}=Copy {cyan-fg}C-p{/cyan-fg}=Paste {cyan-fg}Q{/cyan-fg}=Quit | ` +
      `{yellow-fg}${now}{/yellow-fg}`;

    this.statusBar.setContent(status);
  }

  cleanup() {
    if (this.updateInterval) {
      clearInterval(this.updateInterval);
    }

    Object.values(this.processes).forEach(proc => {
      if (proc && proc.kill) {
        proc.kill();
      }
    });

    if (this.screen) {
      this.screen.destroy();
    }
  }

  async start() {
    console.log(chalk.hex('#FF6B00').bold('\n  🪟  Starting BlackRoad Multi-Window Terminal...\n'));

    const spinner = ora('Initializing windows...').start();

    this.createScreen();
    this.createLayout();

    // Start SSH processes
    Object.entries(WINDOWS).forEach(([id, config]) => {
      if (config.type === 'ssh') {
        this.startSSHProcess(id, config);
      } else if (config.type === 'ai') {
        if (id === 'claude') {
          this.startClaudeWindow(id);
        } else if (id === 'ollama') {
          this.startOllamaWindow(id);
        }
      }
    });

    spinner.succeed('Windows initialized!');

    // Focus first window
    this.focusWindow('aria');

    // Start auto-updates
    this.startAutoUpdate();

    // Initial render
    this.screen.render();

    // Show welcome message
    setTimeout(() => {
      const welcome = blessed.box({
        parent: this.screen,
        top: 'center',
        left: 'center',
        width: 60,
        height: 12,
        content: `{center}{bold}Welcome to BlackRoad Multi-Window Terminal!{/bold}{/center}

{cyan-fg}Controls:{/cyan-fg}
  {yellow-fg}Tab{/yellow-fg}        - Switch between windows
  {yellow-fg}↑/↓ or j/k{/yellow-fg} - Scroll in focused window
  {yellow-fg}Ctrl+Y{/yellow-fg}     - Copy from focused window
  {yellow-fg}Ctrl+P{/yellow-fg}     - Paste to focused window
  {yellow-fg}Mouse{/yellow-fg}      - Click to focus/scroll
  {yellow-fg}Q or Esc{/yellow-fg}   - Quit

{green-fg}All windows update every second and have internet access!{/green-fg}`,
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

      setTimeout(() => {
        welcome.destroy();
        this.screen.render();
      }, 5000);
    }, 500);
  }
}

export async function windowsCommand(options) {
  const manager = new WindowManager();

  try {
    await manager.start();
  } catch (e) {
    console.log(chalk.red(`\n  ❌ Failed to start windows: ${e.message}\n`));
    process.exit(1);
  }
}
