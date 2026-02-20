// BLACKROAD OS - DESK & WORKSTATION
// 16x16 grid aligned

const DESK = {
  palette: {
    surface: {
      light: '#deb887',
      mid: '#c4a060',
      dark: '#a08050'
    },
    metal: {
      light: '#c0c0c0',
      mid: '#a0a0a0',
      dark: '#707070'
    },
    screen: {
      off: '#1a2a1a',
      on: '#0a3a2a',
      text: '#4aea8b',
      cursor: '#7affa8'
    }
  },

  // Basic desk (80x48 footprint)
  basic: function(ctx, x, y) {
    const s = this.palette.surface;
    
    // Shadow
    ctx.fillStyle = 'rgba(0,0,0,0.25)';
    ctx.fillRect(x + 4, y + 44, 80, 6);
    
    // Desktop surface
    ctx.fillStyle = s.light;
    ctx.fillRect(x, y, 80, 8);
    ctx.fillStyle = s.mid;
    ctx.fillRect(x, y + 6, 80, 36);
    ctx.fillStyle = s.dark;
    ctx.fillRect(x + 2, y + 40, 76, 4);
    
    // Legs
    ctx.fillStyle = s.dark;
    ctx.fillRect(x + 4, y + 42, 10, 12);
    ctx.fillRect(x + 66, y + 42, 10, 12);
    
    // Drawer unit
    ctx.fillRect(x + 52, y + 10, 24, 28);
    ctx.fillStyle = s.mid;
    ctx.fillRect(x + 54, y + 12, 20, 11);
    ctx.fillRect(x + 54, y + 25, 20, 11);
    // Handles
    ctx.fillStyle = this.palette.metal.mid;
    ctx.fillRect(x + 62, y + 16, 4, 3);
    ctx.fillRect(x + 62, y + 29, 4, 3);
  },

  // Monitor (32x28)
  monitor: function(ctx, x, y, screenContent, time) {
    const m = this.palette.metal;
    const s = this.palette.screen;
    
    // Bezel
    ctx.fillStyle = '#1a1a1a';
    ctx.fillRect(x, y, 32, 24);
    ctx.fillStyle = '#222';
    ctx.fillRect(x + 2, y + 2, 28, 18);
    
    // Screen
    ctx.fillStyle = s.on;
    ctx.fillRect(x + 3, y + 3, 26, 16);
    
    // Content
    ctx.fillStyle = s.text;
    if (screenContent === 'code') {
      ctx.fillRect(x + 5, y + 5, 14, 2);
      ctx.fillRect(x + 5, y + 9, 20, 2);
      ctx.fillRect(x + 5, y + 13, 10, 2);
      // Cursor blink
      if (Math.floor(time / 15) % 2) {
        ctx.fillStyle = s.cursor;
        ctx.fillRect(x + 16, y + 13, 2, 2);
      }
    } else if (screenContent === 'terminal') {
      ctx.fillRect(x + 5, y + 5, 6, 2);
      ctx.fillStyle = '#fff';
      ctx.fillRect(x + 12, y + 5, 8, 2);
      ctx.fillStyle = s.text;
      ctx.fillRect(x + 5, y + 9, 18, 2);
      ctx.fillRect(x + 5, y + 13, 4, 2);
    }
    
    // Stand
    ctx.fillStyle = '#222';
    ctx.fillRect(x + 12, y + 24, 8, 4);
    ctx.fillRect(x + 8, y + 26, 16, 3);
  },

  // Keyboard (24x10)
  keyboard: function(ctx, x, y) {
    ctx.fillStyle = '#2a2a2a';
    ctx.fillRect(x, y, 24, 10);
    ctx.fillStyle = '#3a3a3a';
    ctx.fillRect(x + 1, y + 1, 22, 8);
    
    // Keys
    ctx.fillStyle = '#4a4a4a';
    for (let row = 0; row < 3; row++) {
      for (let key = 0; key < 7; key++) {
        ctx.fillRect(x + 2 + key * 3, y + 2 + row * 3, 2, 2);
      }
    }
  },

  // Mouse (6x10)
  mouse: function(ctx, x, y) {
    ctx.fillStyle = '#2a2a2a';
    ctx.fillRect(x, y, 6, 10);
    ctx.fillStyle = '#3a3a3a';
    ctx.fillRect(x + 1, y + 1, 4, 3);
    ctx.fillStyle = '#222';
    ctx.fillRect(x + 2, y + 4, 2, 2);
  },

  // Coffee mug (10x14)
  mug: function(ctx, x, y, hasSteam, time) {
    // Mug body
    ctx.fillStyle = '#fff';
    ctx.fillRect(x, y + 4, 8, 10);
    // Handle
    ctx.fillRect(x + 7, y + 6, 3, 6);
    ctx.fillStyle = '#e8e8e8';
    ctx.fillRect(x + 8, y + 8, 2, 2);
    // Coffee
    ctx.fillStyle = '#3c2415';
    ctx.fillRect(x + 1, y + 5, 6, 3);
    
    // Steam
    if (hasSteam && Math.floor(time / 10) % 3 !== 0) {
      ctx.fillStyle = 'rgba(255,255,255,0.5)';
      ctx.fillRect(x + 2, y + 2 - (time % 4), 1, 2);
      ctx.fillRect(x + 5, y + 1 - (time % 3), 1, 2);
    }
  },

  // Complete workstation
  workstation: function(ctx, x, y, time) {
    this.basic(ctx, x, y);
    this.monitor(ctx, x + 8, y - 26, 'code', time);
    this.keyboard(ctx, x + 10, y + 6);
    this.mouse(ctx, x + 38, y + 8);
    this.mug(ctx, x + 2, y - 4, true, time);
  }
};

if (typeof module !== 'undefined') module.exports = DESK;
