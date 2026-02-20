// BLACKROAD OS - SMALL PROPS
// Office items, decorations

const PROPS = {
  palette: {
    paper: '#fffef0',
    paperLines: '#ddd',
    mug: { white: '#fff', handle: '#e8e8e8', coffee: '#3c2415' },
    metal: { light: '#c0c0c0', mid: '#909090', dark: '#606060' }
  },

  // Coffee mug (10x14)
  mug: function(ctx, x, y, hasCoffee, time) {
    ctx.fillStyle = this.palette.mug.white;
    ctx.fillRect(x, y + 4, 8, 10);
    ctx.fillStyle = this.palette.mug.handle;
    ctx.fillRect(x + 7, y + 6, 3, 6);
    ctx.fillRect(x + 8, y + 8, 2, 2);
    
    if (hasCoffee !== false) {
      ctx.fillStyle = this.palette.mug.coffee;
      ctx.fillRect(x + 1, y + 5, 6, 3);
      
      // Steam
      if (time && Math.floor(time / 10) % 3 !== 0) {
        ctx.fillStyle = 'rgba(255,255,255,0.5)';
        ctx.fillRect(x + 2, y + 2 - (time % 4), 1, 2);
        ctx.fillRect(x + 5, y + 1 - (time % 3), 1, 2);
      }
    }
  },

  // Stack of papers (14x8)
  paperStack: function(ctx, x, y) {
    for (let i = 0; i < 3; i++) {
      ctx.fillStyle = this.palette.paper;
      ctx.fillRect(x + i, y + i * 2, 14, 6);
      ctx.fillStyle = this.palette.paperLines;
      ctx.fillRect(x + 2 + i, y + 2 + i * 2, 8, 1);
    }
  },

  // Pencil cup (10x16)
  pencilCup: function(ctx, x, y) {
    ctx.fillStyle = '#4a6a8c';
    ctx.fillRect(x, y + 4, 10, 12);
    ctx.fillStyle = '#3a5a7a';
    ctx.fillRect(x + 1, y + 6, 8, 8);
    
    // Pencils
    ctx.fillStyle = '#ffd700';
    ctx.fillRect(x + 2, y - 4, 2, 10);
    ctx.fillStyle = '#e94560';
    ctx.fillRect(x + 5, y - 2, 2, 8);
    ctx.fillStyle = '#4a9';
    ctx.fillRect(x + 7, y - 3, 2, 9);
  },

  // Clock (32x32)
  clock: function(ctx, x, y, time) {
    // Frame
    ctx.fillStyle = '#a67c3d';
    ctx.beginPath();
    ctx.arc(x + 16, y + 16, 16, 0, Math.PI * 2);
    ctx.fill();
    
    ctx.fillStyle = '#c4935a';
    ctx.beginPath();
    ctx.arc(x + 16, y + 16, 14, 0, Math.PI * 2);
    ctx.fill();
    
    // Face
    ctx.fillStyle = '#fffef0';
    ctx.beginPath();
    ctx.arc(x + 16, y + 16, 12, 0, Math.PI * 2);
    ctx.fill();
    
    // Hour marks
    ctx.fillStyle = '#333';
    for (let i = 0; i < 12; i++) {
      const angle = (i / 12) * Math.PI * 2 - Math.PI / 2;
      const hx = x + 16 + Math.cos(angle) * 10;
      const hy = y + 16 + Math.sin(angle) * 10;
      ctx.fillRect(hx - 1, hy - 1, 2, 2);
    }
    
    // Hands
    const hours = (time / 3600) % 12;
    const mins = (time / 60) % 60;
    
    ctx.strokeStyle = '#333';
    ctx.lineWidth = 2;
    ctx.beginPath();
    ctx.moveTo(x + 16, y + 16);
    const hAngle = (hours / 12) * Math.PI * 2 - Math.PI / 2;
    ctx.lineTo(x + 16 + Math.cos(hAngle) * 6, y + 16 + Math.sin(hAngle) * 6);
    ctx.stroke();
    
    ctx.lineWidth = 1;
    ctx.beginPath();
    ctx.moveTo(x + 16, y + 16);
    const mAngle = (mins / 60) * Math.PI * 2 - Math.PI / 2;
    ctx.lineTo(x + 16 + Math.cos(mAngle) * 9, y + 16 + Math.sin(mAngle) * 9);
    ctx.stroke();
    
    // Center dot
    ctx.fillStyle = '#333';
    ctx.beginPath();
    ctx.arc(x + 16, y + 16, 2, 0, Math.PI * 2);
    ctx.fill();
  },

  // Poster/picture frame (32x44)
  poster: function(ctx, x, y, type) {
    // Frame
    ctx.fillStyle = '#a67c3d';
    ctx.fillRect(x - 2, y - 2, 36, 48);
    ctx.fillStyle = '#fff';
    ctx.fillRect(x, y, 32, 44);
    
    if (type === 'chart') {
      ctx.fillStyle = '#e94560';
      ctx.fillRect(x + 4, y + 30, 5, 10);
      ctx.fillStyle = '#4a9';
      ctx.fillRect(x + 11, y + 22, 5, 18);
      ctx.fillStyle = '#4ae';
      ctx.fillRect(x + 18, y + 14, 5, 26);
      ctx.fillStyle = '#fa0';
      ctx.fillRect(x + 25, y + 8, 5, 32);
    } else if (type === 'logo') {
      ctx.fillStyle = '#1a1a2e';
      ctx.fillRect(x + 4, y + 6, 24, 16);
      ctx.fillStyle = '#e94560';
      ctx.fillRect(x + 8, y + 10, 16, 8);
    } else {
      // Motivational
      ctx.fillStyle = '#4a9';
      ctx.fillRect(x + 4, y + 4, 24, 20);
      ctx.fillStyle = '#333';
      ctx.font = '6px monospace';
      ctx.fillText('SHIP', x + 8, y + 32);
      ctx.fillText('IT', x + 12, y + 40);
    }
  },

  // Whiteboard (64x48)
  whiteboard: function(ctx, x, y) {
    // Frame
    ctx.fillStyle = '#888';
    ctx.fillRect(x - 2, y - 2, 68, 52);
    // Board
    ctx.fillStyle = '#f8f8f8';
    ctx.fillRect(x, y, 64, 48);
    
    // Content
    ctx.fillStyle = '#e94560';
    ctx.fillRect(x + 4, y + 4, 30, 3);
    ctx.fillStyle = '#333';
    ctx.fillRect(x + 4, y + 10, 40, 2);
    ctx.fillRect(x + 4, y + 16, 35, 2);
    ctx.fillStyle = '#4a9';
    ctx.fillRect(x + 4, y + 22, 20, 2);
    
    // Diagram
    ctx.fillStyle = '#4ae';
    ctx.fillRect(x + 44, y + 10, 16, 16);
    ctx.fillStyle = '#fa0';
    ctx.beginPath();
    ctx.arc(x + 52, y + 36, 8, 0, Math.PI * 2);
    ctx.fill();
    
    // Marker tray
    ctx.fillStyle = '#aaa';
    ctx.fillRect(x + 4, y + 50, 40, 4);
    ctx.fillStyle = '#e94560';
    ctx.fillRect(x + 6, y + 51, 8, 2);
    ctx.fillStyle = '#333';
    ctx.fillRect(x + 16, y + 51, 8, 2);
    ctx.fillStyle = '#4a9';
    ctx.fillRect(x + 26, y + 51, 8, 2);
  },

  // Trash can (16x20)
  trashCan: function(ctx, x, y) {
    ctx.fillStyle = '#555';
    ctx.fillRect(x + 2, y + 4, 12, 16);
    ctx.fillStyle = '#444';
    ctx.fillRect(x + 3, y + 6, 10, 12);
    ctx.fillStyle = '#666';
    ctx.fillRect(x, y, 16, 5);
  },

  // Phone (8x14)
  phone: function(ctx, x, y) {
    ctx.fillStyle = '#1a1a1a';
    ctx.fillRect(x, y, 8, 14);
    ctx.fillStyle = '#333';
    ctx.fillRect(x + 1, y + 2, 6, 10);
    // Screen glow
    ctx.fillStyle = '#4ae';
    ctx.fillRect(x + 1, y + 2, 6, 8);
  }
};

if (typeof module !== 'undefined') module.exports = PROPS;
