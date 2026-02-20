// BLACKROAD OS - FLOOR TILES
// 16x16 base tile size

const FLOOR = {
  // Color palettes
  palette: {
    wood: {
      light: '#c9a66b',
      mid: '#a68550', 
      dark: '#8b6914',
      grain: '#7a5a30',
      knot: '#5a4020'
    },
    tile: {
      white: '#e8e8e8',
      cream: '#f5f0e0',
      gray: '#a8a8a8',
      grout: '#888888'
    },
    carpet: {
      red: '#8b3a5a',
      redDark: '#6a2a4a',
      blue: '#3a5a8b',
      blueDark: '#2a4a6a'
    },
    concrete: {
      light: '#909090',
      dark: '#707070',
      crack: '#505050'
    }
  },

  // Draw single 16x16 wood plank
  woodPlank: function(ctx, x, y, variant) {
    const p = this.palette.wood;
    const colors = [p.light, p.mid, p.dark];
    const base = colors[variant % 3];
    
    ctx.fillStyle = base;
    ctx.fillRect(x, y, 16, 16);
    
    // Grain lines
    ctx.fillStyle = p.grain;
    if (variant % 2 === 0) {
      ctx.fillRect(x + 2, y + 4, 10, 1);
      ctx.fillRect(x + 4, y + 11, 8, 1);
    } else {
      ctx.fillRect(x + 3, y + 6, 9, 1);
      ctx.fillRect(x + 1, y + 13, 7, 1);
    }
    
    // Wood knot (rare)
    if (variant % 7 === 0) {
      ctx.fillStyle = p.knot;
      ctx.fillRect(x + 6, y + 6, 4, 4);
      ctx.fillStyle = p.grain;
      ctx.fillRect(x + 7, y + 7, 2, 2);
    }
    
    // Board edge
    ctx.fillStyle = p.grain;
    ctx.fillRect(x, y, 1, 16);
  },

  // Draw 16x16 tile floor piece
  tilePiece: function(ctx, x, y, variant) {
    const p = this.palette.tile;
    const isWhite = variant % 2 === 0;
    
    ctx.fillStyle = isWhite ? p.white : p.cream;
    ctx.fillRect(x, y, 16, 16);
    
    // Grout lines
    ctx.fillStyle = p.grout;
    ctx.fillRect(x, y, 16, 1);
    ctx.fillRect(x, y, 1, 16);
    
    // Subtle shine
    if (isWhite) {
      ctx.fillStyle = '#ffffff';
      ctx.fillRect(x + 3, y + 3, 2, 1);
    }
  },

  // Draw 16x16 carpet piece
  carpetPiece: function(ctx, x, y, variant, colorScheme) {
    const p = this.palette.carpet;
    const isRed = colorScheme === 'red';
    const main = isRed ? p.red : p.blue;
    const dark = isRed ? p.redDark : p.blueDark;
    
    ctx.fillStyle = main;
    ctx.fillRect(x, y, 16, 16);
    
    // Pattern
    if ((variant % 4) < 2) {
      ctx.fillStyle = dark;
      ctx.fillRect(x + 4, y + 4, 8, 8);
      ctx.fillStyle = main;
      ctx.fillRect(x + 6, y + 6, 4, 4);
    }
  },

  // Draw 16x16 concrete piece
  concretePiece: function(ctx, x, y, variant) {
    const p = this.palette.concrete;
    
    ctx.fillStyle = variant % 2 ? p.light : p.dark;
    ctx.fillRect(x, y, 16, 16);
    
    // Cracks
    if (variant % 5 === 0) {
      ctx.fillStyle = p.crack;
      ctx.fillRect(x + 2, y + 8, 6, 1);
      ctx.fillRect(x + 7, y + 8, 1, 4);
    }
    
    // Speckles
    ctx.fillStyle = p.crack;
    ctx.fillRect(x + 3, y + 3, 1, 1);
    ctx.fillRect(x + 10, y + 7, 1, 1);
    ctx.fillRect(x + 6, y + 12, 1, 1);
  },

  // Fill area with wood floor
  fillWood: function(ctx, startX, startY, tilesWide, tilesHigh) {
    for (let y = 0; y < tilesHigh; y++) {
      for (let x = 0; x < tilesWide; x++) {
        const variant = (x + y * 3) % 7;
        this.woodPlank(ctx, startX + x * 16, startY + y * 16, variant);
      }
    }
  },

  // Fill area with tile floor
  fillTile: function(ctx, startX, startY, tilesWide, tilesHigh) {
    for (let y = 0; y < tilesHigh; y++) {
      for (let x = 0; x < tilesWide; x++) {
        this.tilePiece(ctx, startX + x * 16, startY + y * 16, x + y);
      }
    }
  },

  // Fill area with carpet
  fillCarpet: function(ctx, startX, startY, tilesWide, tilesHigh, colorScheme) {
    for (let y = 0; y < tilesHigh; y++) {
      for (let x = 0; x < tilesWide; x++) {
        this.carpetPiece(ctx, startX + x * 16, startY + y * 16, x + y, colorScheme || 'red');
      }
    }
    // Border fringe
    ctx.fillStyle = this.palette.carpet[colorScheme === 'blue' ? 'blueDark' : 'redDark'];
    for (let x = 0; x < tilesWide * 16; x += 4) {
      ctx.fillRect(startX + x, startY - 2, 3, 2);
      ctx.fillRect(startX + x, startY + tilesHigh * 16, 3, 2);
    }
  },

  // Fill area with concrete
  fillConcrete: function(ctx, startX, startY, tilesWide, tilesHigh) {
    for (let y = 0; y < tilesHigh; y++) {
      for (let x = 0; x < tilesWide; x++) {
        this.concretePiece(ctx, startX + x * 16, startY + y * 16, x * 3 + y * 7);
      }
    }
  }
};

if (typeof module !== 'undefined') module.exports = FLOOR;
