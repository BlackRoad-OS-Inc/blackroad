// BLACKROAD OS - FURNITURE
// Couch, tables, shelves

const FURNITURE = {
  palette: {
    couch: {
      blue: '#5a5a8a',
      blueDark: '#4a4a7a',
      blueLight: '#6a6a9a',
      gray: '#6a6a6a',
      grayDark: '#5a5a5a'
    },
    wood: {
      light: '#daa86a',
      mid: '#c4935a',
      dark: '#a67c3d'
    },
    metal: {
      light: '#c0c0c0',
      mid: '#a0a0a0',
      dark: '#707070'
    }
  },

  // Couch (72x44)
  couch: function(ctx, x, y, color) {
    const c = this.palette.couch;
    const main = c[color] || c.blue;
    const dark = c[color + 'Dark'] || c.blueDark;
    const light = c[color + 'Light'] || c.blueLight;
    
    // Shadow
    ctx.fillStyle = 'rgba(0,0,0,0.25)';
    ctx.fillRect(x + 2, y + 42, 70, 5);
    
    // Base
    ctx.fillStyle = main;
    ctx.fillRect(x, y + 12, 72, 32);
    ctx.fillStyle = dark;
    ctx.fillRect(x + 4, y + 16, 64, 24);
    
    // Back
    ctx.fillStyle = main;
    ctx.fillRect(x, y, 72, 16);
    ctx.fillStyle = dark;
    ctx.fillRect(x + 4, y + 4, 64, 8);
    
    // Arms
    ctx.fillStyle = main;
    ctx.fillRect(x - 4, y + 4, 8, 40);
    ctx.fillRect(x + 68, y + 4, 8, 40);
    
    // Cushion divisions
    ctx.fillStyle = dark;
    ctx.fillRect(x + 24, y + 16, 2, 24);
    ctx.fillRect(x + 46, y + 16, 2, 24);
    
    // Highlights
    ctx.fillStyle = light;
    ctx.fillRect(x + 6, y + 18, 16, 4);
    ctx.fillRect(x + 28, y + 18, 16, 4);
    ctx.fillRect(x + 50, y + 18, 16, 4);
  },

  // Coffee table (56x28)
  coffeeTable: function(ctx, x, y) {
    const w = this.palette.wood;
    
    // Shadow
    ctx.fillStyle = 'rgba(0,0,0,0.2)';
    ctx.fillRect(x + 3, y + 26, 52, 4);
    
    // Top
    ctx.fillStyle = w.light;
    ctx.fillRect(x, y, 56, 8);
    ctx.fillStyle = w.mid;
    ctx.fillRect(x, y + 6, 56, 18);
    
    // Legs
    ctx.fillStyle = w.dark;
    ctx.fillRect(x + 4, y + 22, 8, 8);
    ctx.fillRect(x + 44, y + 22, 8, 8);
    
    // Shelf
    ctx.fillStyle = w.mid;
    ctx.fillRect(x + 6, y + 16, 44, 4);
  },

  // Bookshelf (36x72)
  bookshelf: function(ctx, x, y) {
    const w = this.palette.wood;
    const bookColors = ['#e94560', '#4a9fea', '#4a9a5a', '#ffa500', '#aa5aaa', '#ea4a4a'];
    
    // Shadow
    ctx.fillStyle = 'rgba(0,0,0,0.25)';
    ctx.fillRect(x + 3, y + 70, 34, 5);
    
    // Frame
    ctx.fillStyle = w.dark;
    ctx.fillRect(x, y, 36, 72);
    
    // Shelves
    for (let s = 0; s < 4; s++) {
      // Shelf back
      ctx.fillStyle = w.mid;
      ctx.fillRect(x + 2, y + 2 + s * 18, 32, 16);
      // Shelf board
      ctx.fillStyle = w.dark;
      ctx.fillRect(x + 2, y + 16 + s * 18, 32, 3);
      
      // Books
      let bx = x + 4;
      for (let b = 0; b < 5; b++) {
        if ((s * 5 + b) % 6 !== 0) {
          const bw = 4 + (b % 3);
          const bh = 10 + (s + b) % 5;
          ctx.fillStyle = bookColors[(s + b) % 6];
          ctx.fillRect(bx, y + 4 + s * 18 + (14 - bh), bw, bh);
          bx += bw + 1;
        }
      }
    }
  },

  // Filing cabinet (32x64)
  filingCabinet: function(ctx, x, y) {
    const m = this.palette.metal;
    
    // Shadow
    ctx.fillStyle = 'rgba(0,0,0,0.2)';
    ctx.fillRect(x + 3, y + 62, 28, 4);
    
    // Body
    ctx.fillStyle = m.dark;
    ctx.fillRect(x, y, 32, 64);
    ctx.fillStyle = m.mid;
    ctx.fillRect(x + 2, y + 2, 28, 60);
    
    // Drawers
    for (let i = 0; i < 3; i++) {
      ctx.fillStyle = m.dark;
      ctx.fillRect(x + 4, y + 4 + i * 20, 24, 18);
      ctx.fillStyle = m.mid;
      ctx.fillRect(x + 5, y + 5 + i * 20, 22, 16);
      // Handle
      ctx.fillStyle = m.dark;
      ctx.fillRect(x + 12, y + 11 + i * 20, 8, 4);
    }
    
    // Label
    ctx.fillStyle = '#fffef0';
    ctx.fillRect(x + 8, y + 6, 10, 6);
  },

  // Water cooler (28x56)
  waterCooler: function(ctx, x, y, time) {
    const m = this.palette.metal;
    
    // Shadow
    ctx.fillStyle = 'rgba(0,0,0,0.2)';
    ctx.fillRect(x + 3, y + 54, 24, 4);
    
    // Base
    ctx.fillStyle = m.dark;
    ctx.fillRect(x + 4, y + 44, 20, 12);
    ctx.fillStyle = m.mid;
    ctx.fillRect(x + 6, y + 46, 16, 8);
    
    // Body
    ctx.fillStyle = m.mid;
    ctx.fillRect(x + 2, y + 16, 24, 30);
    ctx.fillStyle = m.light;
    ctx.fillRect(x + 4, y + 18, 20, 26);
    
    // Water jug
    ctx.fillStyle = '#a8d8ea';
    ctx.fillRect(x + 6, y - 8, 16, 26);
    ctx.fillStyle = '#88b8ca';
    ctx.fillRect(x + 8, y - 6, 12, 22);
    
    // Water level
    const level = 16 + Math.sin(time / 30) * 2;
    ctx.fillStyle = '#4a9cdc';
    ctx.fillRect(x + 8, y + 16 - level, 12, level - 4);
    
    // Tap
    ctx.fillStyle = '#666';
    ctx.fillRect(x + 12, y + 34, 6, 4);
    ctx.fillRect(x + 14, y + 38, 2, 4);
    
    // Cup holder
    ctx.fillStyle = m.mid;
    ctx.fillRect(x + 22, y + 20, 6, 12);
    ctx.fillStyle = '#fff';
    ctx.fillRect(x + 23, y + 28, 4, 5);
  },

  // Vending machine (40x72)
  vendingMachine: function(ctx, x, y) {
    // Shadow
    ctx.fillStyle = 'rgba(0,0,0,0.25)';
    ctx.fillRect(x + 3, y + 70, 38, 5);
    
    // Body
    ctx.fillStyle = '#2a4a6a';
    ctx.fillRect(x, y, 40, 72);
    ctx.fillStyle = '#1a3050';
    ctx.fillRect(x + 2, y + 2, 36, 50);
    
    // Glass front
    ctx.fillStyle = '#3a5a7a';
    ctx.fillRect(x + 4, y + 4, 32, 46);
    
    // Items
    const colors = ['#e94560', '#4a9', '#fa0', '#4ae', '#a4e', '#f80'];
    for (let row = 0; row < 3; row++) {
      // Shelf
      ctx.fillStyle = this.palette.metal.mid;
      ctx.fillRect(x + 4, y + 6 + row * 15, 32, 2);
      for (let col = 0; col < 4; col++) {
        ctx.fillStyle = colors[(row * 4 + col) % 6];
        ctx.fillRect(x + 6 + col * 8, y + 8 + row * 15, 6, 12);
      }
    }
    
    // Coin slot
    ctx.fillStyle = this.palette.metal.dark;
    ctx.fillRect(x + 30, y + 54, 6, 8);
    ctx.fillStyle = '#111';
    ctx.fillRect(x + 32, y + 56, 2, 4);
    
    // Dispenser
    ctx.fillStyle = '#111';
    ctx.fillRect(x + 4, y + 54, 24, 16);
  }
};

if (typeof module !== 'undefined') module.exports = FURNITURE;
