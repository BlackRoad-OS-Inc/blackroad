// BLACKROAD OS - LIGHTING
// Ceiling lights, lamps, windows

const LIGHTING = {
  palette: {
    fixture: {
      white: '#e8e8e8',
      cream: '#f0e8d8',
      metal: '#a0a0a0',
      metalDark: '#707070',
      chain: '#888888'
    },
    glow: {
      warm: 'rgba(255,240,200,',
      cool: 'rgba(200,240,255,',
      white: 'rgba(255,255,255,'
    },
    window: {
      frame: '#c4935a',
      frameDark: '#a67c3d',
      glass: '#87ceeb',
      sky: '#6cacdc',
      skyLight: '#a0d8f0'
    },
    curtain: {
      red: '#a05050',
      redDark: '#803838',
      blue: '#5050a0',
      blueDark: '#383880'
    }
  },

  // Ceiling light (32x20)
  ceilingLight: function(ctx, x, y, time, on) {
    const f = this.palette.fixture;
    
    // Chain
    ctx.fillStyle = f.chain;
    ctx.fillRect(x + 14, y, 4, 8);
    
    // Fixture
    ctx.fillStyle = f.metalDark;
    ctx.fillRect(x, y + 8, 32, 6);
    ctx.fillStyle = f.metal;
    ctx.fillRect(x + 2, y + 10, 28, 2);
    
    // Shade
    ctx.fillStyle = f.cream;
    ctx.fillRect(x + 4, y + 14, 24, 4);
    
    if (on !== false) {
      // Bulbs
      ctx.fillStyle = '#fffde0';
      ctx.fillRect(x + 8, y + 16, 6, 4);
      ctx.fillRect(x + 18, y + 16, 6, 4);
      
      // Glow
      const pulse = 0.1 + Math.sin(time / 20) * 0.02;
      ctx.fillStyle = this.palette.glow.warm + pulse + ')';
      ctx.beginPath();
      ctx.arc(x + 16, y + 40, 50, 0, Math.PI * 2);
      ctx.fill();
    }
  },

  // Desk lamp (16x24)
  deskLamp: function(ctx, x, y, on) {
    const f = this.palette.fixture;
    
    // Base
    ctx.fillStyle = f.metalDark;
    ctx.fillRect(x + 2, y + 20, 12, 4);
    
    // Stem
    ctx.fillStyle = f.metal;
    ctx.fillRect(x + 6, y + 8, 4, 14);
    
    // Shade
    ctx.fillStyle = f.metalDark;
    ctx.fillRect(x, y, 16, 10);
    ctx.fillStyle = f.metal;
    ctx.fillRect(x + 1, y + 1, 14, 8);
    
    if (on !== false) {
      ctx.fillStyle = '#fffde0';
      ctx.fillRect(x + 2, y + 8, 12, 3);
      
      // Small glow
      ctx.fillStyle = this.palette.glow.warm + '0.15)';
      ctx.fillRect(x - 8, y + 10, 32, 20);
    }
  },

  // Window (64x48)
  window: function(ctx, x, y, time, hasCurtains) {
    const w = this.palette.window;
    const c = this.palette.curtain;
    
    // Frame shadow
    ctx.fillStyle = w.frameDark;
    ctx.fillRect(x - 6, y - 6, 76, 60);
    
    // Frame
    ctx.fillStyle = w.frame;
    ctx.fillRect(x - 4, y - 4, 72, 56);
    
    // Glass/sky
    ctx.fillStyle = w.sky;
    ctx.fillRect(x, y, 64, 48);
    
    // Sky gradient
    for (let i = 0; i < 48; i += 8) {
      const alpha = 0.3 - (i / 48) * 0.2;
      ctx.fillStyle = 'rgba(255,255,255,' + alpha + ')';
      ctx.fillRect(x, y + i, 64, 8);
    }
    
    // Clouds
    const cloudX = ((time / 2) % 84) - 20;
    ctx.fillStyle = 'rgba(255,255,255,0.8)';
    ctx.beginPath();
    ctx.arc(x + cloudX, y + 14, 8, 0, Math.PI * 2);
    ctx.arc(x + cloudX + 10, y + 12, 10, 0, Math.PI * 2);
    ctx.arc(x + cloudX + 20, y + 14, 7, 0, Math.PI * 2);
    ctx.fill();
    
    // Window cross frame
    ctx.fillStyle = w.frame;
    ctx.fillRect(x + 30, y, 4, 48);
    ctx.fillRect(x, y + 22, 64, 4);
    
    // Shine
    ctx.fillStyle = 'rgba(255,255,255,0.4)';
    ctx.fillRect(x + 4, y + 4, 10, 3);
    
    // Curtains
    if (hasCurtains !== false) {
      ctx.fillStyle = c.red;
      ctx.fillRect(x - 8, y - 6, 10, 58);
      ctx.fillRect(x + 62, y - 6, 10, 58);
      
      // Folds
      for (let i = 0; i < 8; i++) {
        ctx.fillStyle = c.redDark;
        ctx.fillRect(x - 8, y - 6 + i * 7, 10, 2);
        ctx.fillRect(x + 62, y - 6 + i * 7, 10, 2);
      }
      
      // Ties
      ctx.fillStyle = '#d4aa00';
      ctx.fillRect(x - 6, y + 20, 6, 8);
      ctx.fillRect(x + 64, y + 20, 6, 8);
    }
    
    // Light beam effect
    ctx.fillStyle = this.palette.glow.warm + '0.05)';
    ctx.beginPath();
    ctx.moveTo(x, y + 48);
    ctx.lineTo(x + 64, y + 48);
    ctx.lineTo(x + 100, y + 120);
    ctx.lineTo(x - 36, y + 120);
    ctx.fill();
  },

  // Wall sconce (12x20)
  sconce: function(ctx, x, y, on) {
    const f = this.palette.fixture;
    
    // Mount
    ctx.fillStyle = f.metalDark;
    ctx.fillRect(x + 2, y, 8, 6);
    
    // Arm
    ctx.fillStyle = f.metal;
    ctx.fillRect(x + 4, y + 4, 4, 8);
    
    // Shade
    ctx.fillStyle = f.cream;
    ctx.fillRect(x, y + 10, 12, 10);
    ctx.fillStyle = '#d8d0c0';
    ctx.fillRect(x + 1, y + 11, 10, 8);
    
    if (on !== false) {
      ctx.fillStyle = '#fffde0';
      ctx.fillRect(x + 3, y + 18, 6, 3);
      
      ctx.fillStyle = this.palette.glow.warm + '0.1)';
      ctx.beginPath();
      ctx.arc(x + 6, y + 24, 20, 0, Math.PI * 2);
      ctx.fill();
    }
  }
};

if (typeof module !== 'undefined') module.exports = LIGHTING;
