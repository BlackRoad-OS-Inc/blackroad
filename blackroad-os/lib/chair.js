// BLACKROAD OS - OFFICE CHAIR
// 16x16 grid aligned

const CHAIR = {
  palette: {
    fabric: {
      blue: '#4a6fa5',
      blueDark: '#3a5580',
      blueLight: '#6090c0',
      red: '#a54a4a',
      redDark: '#803a3a',
      gray: '#606060',
      grayDark: '#404040'
    },
    frame: {
      black: '#1a1a1a',
      dark: '#2a2a2a',
      metal: '#555555'
    }
  },

  // Office chair facing up (back visible) - 24x36
  facingUp: function(ctx, x, y, color) {
    const f = this.palette.fabric;
    const fr = this.palette.frame;
    const main = f[color] || f.blue;
    const dark = f[color + 'Dark'] || f.blueDark;
    const light = f[color + 'Light'] || f.blueLight;
    
    // Shadow
    ctx.fillStyle = 'rgba(0,0,0,0.2)';
    ctx.fillRect(x + 2, y + 34, 20, 4);
    
    // Wheel base
    ctx.fillStyle = fr.black;
    ctx.fillRect(x + 4, y + 32, 16, 4);
    ctx.fillRect(x + 2, y + 34, 4, 3);
    ctx.fillRect(x + 18, y + 34, 4, 3);
    
    // Stem
    ctx.fillStyle = fr.metal;
    ctx.fillRect(x + 10, y + 26, 4, 8);
    
    // Seat
    ctx.fillStyle = main;
    ctx.fillRect(x + 2, y + 16, 20, 12);
    ctx.fillStyle = dark;
    ctx.fillRect(x + 4, y + 18, 16, 8);
    
    // Back
    ctx.fillStyle = main;
    ctx.fillRect(x + 4, y, 16, 18);
    ctx.fillStyle = dark;
    ctx.fillRect(x + 6, y + 2, 12, 14);
    // Highlight
    ctx.fillStyle = light;
    ctx.fillRect(x + 6, y + 2, 4, 10);
    
    // Armrests
    ctx.fillStyle = fr.dark;
    ctx.fillRect(x, y + 14, 4, 10);
    ctx.fillRect(x + 20, y + 14, 4, 10);
  },

  // Office chair facing down (front visible) - 24x32
  facingDown: function(ctx, x, y, color) {
    const f = this.palette.fabric;
    const fr = this.palette.frame;
    const main = f[color] || f.blue;
    const dark = f[color + 'Dark'] || f.blueDark;
    
    // Shadow
    ctx.fillStyle = 'rgba(0,0,0,0.2)';
    ctx.fillRect(x + 2, y + 30, 20, 4);
    
    // Wheel base
    ctx.fillStyle = fr.black;
    ctx.fillRect(x + 4, y + 28, 16, 4);
    ctx.fillRect(x + 2, y + 30, 4, 3);
    ctx.fillRect(x + 18, y + 30, 4, 3);
    
    // Stem
    ctx.fillStyle = fr.metal;
    ctx.fillRect(x + 10, y + 22, 4, 8);
    
    // Seat (more visible from front)
    ctx.fillStyle = main;
    ctx.fillRect(x + 2, y + 12, 20, 12);
    ctx.fillStyle = dark;
    ctx.fillRect(x + 4, y + 14, 16, 8);
    
    // Armrests
    ctx.fillStyle = fr.dark;
    ctx.fillRect(x, y + 10, 4, 12);
    ctx.fillRect(x + 20, y + 10, 4, 12);
    ctx.fillStyle = fr.metal;
    ctx.fillRect(x, y + 8, 6, 4);
    ctx.fillRect(x + 18, y + 8, 6, 4);
    
    // Back (just top visible)
    ctx.fillStyle = main;
    ctx.fillRect(x + 6, y, 12, 6);
  },

  // Stool (simpler) - 16x24
  stool: function(ctx, x, y) {
    const fr = this.palette.frame;
    
    // Shadow
    ctx.fillStyle = 'rgba(0,0,0,0.2)';
    ctx.fillRect(x + 2, y + 22, 12, 3);
    
    // Legs
    ctx.fillStyle = fr.metal;
    ctx.fillRect(x + 2, y + 12, 2, 12);
    ctx.fillRect(x + 12, y + 12, 2, 12);
    ctx.fillRect(x + 7, y + 16, 2, 8);
    
    // Footrest
    ctx.fillRect(x, y + 18, 16, 2);
    
    // Seat
    ctx.fillStyle = fr.black;
    ctx.fillRect(x, y + 8, 16, 6);
    ctx.fillStyle = fr.dark;
    ctx.fillRect(x + 2, y + 9, 12, 4);
  }
};

if (typeof module !== 'undefined') module.exports = CHAIR;
