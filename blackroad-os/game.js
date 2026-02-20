const config = {
  type: Phaser.AUTO,
  width: 800,
  height: 600,
  backgroundColor: '#1a1a2e',
  physics: { default: 'arcade', arcade: { debug: false } },
  scene: { preload, create, update }
};

const game = new Phaser.Game(config);
let agents = [];
let selectedAgent = null;

function preload() {
  // Create simple colored rectangles as placeholder sprites
  this.load.image('floor', 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAMklEQVRYR+3QQREAAAjDsM5/6UjAWx4TJHD7TJIk6QusAQMGDBgwYMCAAQMGDBj4Z+ABGLwAIRkLhPAAAAAASUVORK5CYII=');
}

function create() {
  // Draw simple grid floor
  for (let x = 0; x < 800; x += 32) {
    for (let y = 0; y < 600; y += 32) {
      this.add.rectangle(x + 16, y + 16, 30, 30, (x + y) % 64 === 0 ? 0x2d2d44 : 0x1f1f35);
    }
  }

  // Add desks
  const desks = [
    { x: 150, y: 150 }, { x: 300, y: 150 }, { x: 450, y: 150 },
    { x: 150, y: 350 }, { x: 300, y: 350 }, { x: 450, y: 350 },
  ];
  desks.forEach(d => {
    this.add.rectangle(d.x, d.y, 60, 40, 0x4a4a6a);
  });

  // Server room
  this.add.rectangle(700, 100, 150, 150, 0x0f3460);
  this.add.text(640, 30, 'SERVERS', { fontSize: '12px', fill: '#e94560' });
  for (let i = 0; i < 3; i++) {
    this.add.rectangle(680 + i * 25, 80, 20, 40, 0x16213e).setStrokeStyle(1, 0xe94560);
    // Blinking lights
    const light = this.add.circle(680 + i * 25, 65, 3, 0x00ff00);
    this.tweens.add({ targets: light, alpha: 0.3, duration: 500 + i * 200, yoyo: true, repeat: -1 });
  }

  // Meeting room
  this.add.rectangle(700, 450, 150, 200, 0x1a1a2e).setStrokeStyle(2, 0x4a4a6a);
  this.add.rectangle(700, 450, 80, 50, 0x4a4a6a);
  this.add.text(650, 360, 'MEETING', { fontSize: '12px', fill: '#4a4a6a' });

  // Create agents
  const agentData = [
    { id: 1, name: 'Lucidia-Core', color: 0xe94560, x: 150, y: 130, role: 'Chief Intelligence' },
    { id: 2, name: 'Alice', color: 0x00d9ff, x: 300, y: 130, role: 'Gateway Agent' },
    { id: 3, name: 'Octavia', color: 0x00ff88, x: 450, y: 130, role: 'Compute Worker' },
    { id: 4, name: 'Prism', color: 0xffa500, x: 150, y: 330, role: 'Analytics' },
    { id: 5, name: 'Echo', color: 0xff00ff, x: 300, y: 330, role: 'Memory Systems' },
    { id: 6, name: 'Cipher', color: 0xffff00, x: 450, y: 330, role: 'Security' },
  ];

  agentData.forEach(a => {
    const agent = this.add.circle(a.x, a.y, 12, a.color);
    agent.setInteractive({ useHandCursor: true });
    agent.setData('info', a);
    
    // Name label
    const label = this.add.text(a.x, a.y + 20, a.name, { fontSize: '10px', fill: '#ffffff' }).setOrigin(0.5);
    
    // Idle movement
    this.tweens.add({
      targets: [agent, label],
      x: a.x + Phaser.Math.Between(-20, 20),
      y: a.y + Phaser.Math.Between(-10, 10),
      duration: 2000 + Math.random() * 2000,
      yoyo: true,
      repeat: -1,
      ease: 'Sine.easeInOut'
    });

    agent.on('pointerdown', () => selectAgent(a));
    agents.push({ sprite: agent, label, data: a });
  });

  // Title
  this.add.text(20, 20, 'BLACKROAD OS, INC.', { fontSize: '20px', fill: '#e94560', fontStyle: 'bold' });
  this.add.text(20, 45, 'Agent Operations Center', { fontSize: '12px', fill: '#4a4a6a' });

  // Chat input handler
  document.getElementById('chat-input').addEventListener('keydown', async (e) => {
    if (e.key === 'Enter' && selectedAgent) {
      const msg = e.target.value;
      e.target.value = '';
      addChatMessage('You', msg);
      
      // Simulate agent response (replace with real API call)
      setTimeout(() => {
        const responses = [
          `Processing request through ${selectedAgent.role} systems...`,
          `Acknowledged. ${selectedAgent.name} is analyzing.`,
          `Running inference. Stand by.`,
          `Query received. Routing through event bus.`,
        ];
        addChatMessage(selectedAgent.name, responses[Math.floor(Math.random() * responses.length)]);
      }, 500 + Math.random() * 1000);
    }
  });
}

function selectAgent(agent) {
  selectedAgent = agent;
  const chat = document.getElementById('chat');
  const log = document.getElementById('chat-log');
  chat.style.display = 'block';
  log.innerHTML = '';
  addChatMessage('System', `Connected to ${agent.name} (${agent.role})`);
  document.getElementById('chat-input').focus();
}

function addChatMessage(sender, text) {
  const log = document.getElementById('chat-log');
  log.innerHTML += `<div><span class="agent-name">${sender}:</span> ${text}</div>`;
  log.scrollTop = log.scrollHeight;
}

function update() {
  // Future: agent pathfinding, tasks, etc.
}
