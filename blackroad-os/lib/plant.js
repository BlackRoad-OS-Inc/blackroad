// BLACKROAD OS - PLANTS & DECORATIONS
// Various sizes

const PLANT = {
  palette: {
    leaf: {
      green: '#5a9c5a',
      greenLight: '#7abc6a',
      greenDark: '#3a6c3a',
      fern: '#4a8c4a',
      fernLight: '#6aac5a'
    },
    pot: {
      terra: '#cd853f',
      terraDark: '#a0522d',
      terraLight: '#d88050',
      white: '#e8e8e8',
      whiteDark: '#c8c8c8',
      blue: '#4a6a8c',
      blueDark: '#3a5070'
    },
    soil: '#4a3020'
  },

  // Small potted plant (16x24)
  small: function(ctx, x, y, time, potColor) {
    const l = this.palette.leaf;
    const p = this.palette.pot;
    const pot = p[potColor] || p.terra;
    const potDark = p[potColor + 'Dark'] || p.terraDark;
    
    const sway = Math.sin(time / 25 + x * 0.1) * 1;
    
    // Shadow
    ctx.fillStyle = 'rgba(0,0,0,0.2)';
    ctx.fillRect(x + 2, y + 22, 14, 3);
    
    // Pot
    ctx.fillStyle = pot;
    ctx.fillRect(x + 2, y + 14, 14, 10);
    ctx.fillStyle = potDark;
    ctx.fillRect(x + 4, y + 16, 10, 6);
    ctx.fillStyle = pot;
    ctx.fillRect(x, y + 12, 18, 4);
    
    // Soil
    ctx.fillStyle = this.palette.soil;
    ctx.fillRect(x + 4, y + 13, 10, 3);
    
    // Stem
    ctx.fillStyle = l.greenDark;
    ctx.fillRect(x + 7 + sway, y + 4, 3, 10);
    
    // Leaves
    ctx.fillStyle = l.green;
    ctx.fillRect(x + 2 + sway, y + 2, 6, 6);
    ctx.fillRect(x + 10 + sway, y, 6, 7);
    ctx.fillRect(x + 5 + sway, y - 4, 5, 5);
    ctx.fillStyle = l.greenLight;
    ctx.fillRect(x + 3 + sway, y + 3, 3, 3);
    ctx.fillRect(x + 11 + sway, y + 1, 3, 3);
  },

  // Large floor plant (24x40)
  large: function(ctx, x, y, time) {
    const l = this.palette.leaf;
    const p = this.palette.pot;
    const sway = Math.sin(time / 30 + x * 0.05) * 2;
    
    // Shadow
    ctx.fillStyle = 'rgba(0,0,0,0.25)';
    ctx.fillRect(x + 2, y + 38, 22, 4);
    
    // Pot
    ctx.fillStyle = p.terra;
    ctx.fillRect(x + 2, y + 24, 22, 16);
    ctx.fillStyle = p.terraDark;
    ctx.fillRect(x + 4, y + 28, 18, 10);
    ctx.fillStyle = p.terraLight;
    ctx.fillRect(x, y + 20, 26, 6);
    
    // Soil
    ctx.fillStyle = this.palette.soil;
    ctx.fillRect(x + 4, y + 22, 18, 4);
    
    // Main stems
    ctx.fillStyle = l.greenDark;
    ctx.fillRect(x + 10 + sway, y + 4, 4, 20);
    ctx.fillRect(x + 6 + sway, y + 8, 3, 14);
    ctx.fillRect(x + 15 + sway, y + 6, 3, 16);
    
    // Leaves - multiple layers
    ctx.fillStyle = l.greenDark;
    ctx.fillRect(x + sway, y + 4, 10, 8);
    ctx.fillRect(x + 16 + sway, y + 2, 10, 10);
    
    ctx.fillStyle = l.green;
    ctx.fillRect(x + 4 + sway, y - 2, 8, 10);
    ctx.fillRect(x + 12 + sway, y - 4, 10, 12);
    ctx.fillRect(x + 2 + sway, y + 6, 6, 6);
    ctx.fillRect(x + 18 + sway, y + 4, 6, 8);
    
    ctx.fillStyle = l.greenLight;
    ctx.fillRect(x + 6 + sway, y, 5, 6);
    ctx.fillRect(x + 14 + sway, y - 2, 6, 6);
    ctx.fillRect(x + 8 + sway, y - 6, 6, 5);
  },

  // Hanging plant (20x32)
  hanging: function(ctx, x, y, time) {
    const l = this.palette.leaf;
    const sway = Math.sin(time / 20) * 2;
    
    // Hanger chain
    ctx.fillStyle = '#888';
    ctx.fillRect(x + 9, y, 2, 8);
    
    // Pot (smaller, white)
    ctx.fillStyle = '#e8e8e8';
    ctx.fillRect(x + 4, y + 8, 12, 8);
    ctx.fillStyle = '#c8c8c8';
    ctx.fillRect(x + 5, y + 10, 10, 4);
    
    // Trailing vines
    ctx.fillStyle = l.greenDark;
    ctx.fillRect(x + 6 + sway, y + 14, 2, 12);
    ctx.fillRect(x + 12 - sway, y + 14, 2, 16);
    ctx.fillRect(x + 2 + sway * 0.5, y + 16, 2, 10);
    
    // Leaves on vines
    ctx.fillStyle = l.green;
    ctx.fillRect(x + 4 + sway, y + 18, 4, 3);
    ctx.fillRect(x + 10 - sway, y + 22, 4, 3);
    ctx.fillRect(x + sway * 0.5, y + 20, 4, 3);
    ctx.fillRect(x + 12 - sway, y + 28, 4, 3);
    ctx.fillStyle = l.greenLight;
    ctx.fillRect(x + 5 + sway, y + 16, 2, 2);
    ctx.fillRect(x + 11 - sway, y + 20, 2, 2);
  },

  // Cactus (12x20)
  cactus: function(ctx, x, y) {
    const p = this.palette.pot;
    
    // Shadow
    ctx.fillStyle = 'rgba(0,0,0,0.2)';
    ctx.fillRect(x + 1, y + 18, 10, 3);
    
    // Pot
    ctx.fillStyle = p.terra;
    ctx.fillRect(x + 1, y + 12, 10, 8);
    ctx.fillStyle = p.terraDark;
    ctx.fillRect(x + 2, y + 14, 8, 4);
    
    // Cactus body
    ctx.fillStyle = '#5a8a5a';
    ctx.fillRect(x + 4, y + 2, 6, 12);
    ctx.fillStyle = '#4a7a4a';
    ctx.fillRect(x + 5, y + 4, 4, 8);
    
    // Arms
    ctx.fillStyle = '#5a8a5a';
    ctx.fillRect(x + 1, y + 4, 4, 4);
    ctx.fillRect(x + 1, y + 2, 2, 4);
    ctx.fillRect(x + 9, y + 6, 3, 4);
    ctx.fillRect(x + 10, y + 4, 2, 4);
    
    // Spines (dots)
    ctx.fillStyle = '#7aba7a';
    ctx.fillRect(x + 5, y + 3, 1, 1);
    ctx.fillRect(x + 8, y + 5, 1, 1);
    ctx.fillRect(x + 6, y + 8, 1, 1);
    ctx.fillRect(x + 2, y + 3, 1, 1);
  }
};

if (typeof module !== 'undefined') module.exports = PLANT;
