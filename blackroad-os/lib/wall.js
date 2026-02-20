// BLACKROAD OS - WALL TILES
// 16x16 base tile size

const WALL = {
  palette: {
    wallpaper: {
      cream: '#d4c4a8',
      stripe: '#c8b898',
      blue: '#a8b8c8',
      blueStripe: '#98a8b8'
    },
    trim: {
      light: '#c4935a',
      mid: '#a67c3d',
      dark: '#8b5a2b'
    },
    brick: {
      red: '#9c5040',
      redDark: '#7c3830',
      mortar: '#a0988c'
    },
    panel: {
      light: '#e8e0d0',
      mid: '#d0c8b8',
      dark: '#b0a890'
    }
  },

  // 16x16 wallpaper segment
  wallpaperPiece: function(ctx, x, y, variant, colorScheme) {
    const p = this.palette.wallpaper;
    const isBlue = colorScheme === 'blue';
    const base = isBlue ? p.blue : p.cream;
    const stripe = isBlue ? p.blueStripe : p.stripe;
    
    ctx.fillStyle = base;
    ctx.fillRect(x, y, 16, 16);
    
    // Vertical stripes
    if (variant % 2 === 0) {
      ctx.fillStyle = stripe;
      ctx.fillRect(x + 6, y, 4, 16);
    }
  },

  // 16x16 wainscoting panel
  wainscotPiece: function(ctx, x, y) {
    const p = this.palette.trim;
    
    ctx.fillStyle = p.mid;
    ctx.fillRect(x, y, 16, 16);
    
    // Raised panel
    ctx.fillStyle = p.light;
    ctx.fillRect(x + 2, y + 2, 12, 12);
    ctx.fillStyle = p.dark;
    ctx.fillRect(x + 3, y + 13, 11, 1);
    ctx.fillRect(x + 13, y + 3, 1, 10);
  },

  // 16x16 brick piece
  brickPiece: function(ctx, x, y, variant) {
    const p = this.palette.brick;
    
    ctx.fillStyle = p.mortar;
    ctx.fillRect(x, y, 16, 16);
    
    // Brick pattern
    ctx.fillStyle = variant % 3 === 0 ? p.redDark : p.red;
    
    if (variant % 2 === 0) {
      ctx.fillRect(x + 1, y + 1, 14, 6);
      ctx.fillRect(x + 1, y + 9, 6, 6);
      ctx.fillRect(x + 9, y + 9, 6, 6);
    } else {
      ctx.fillRect(x + 1, y + 1, 6, 6);
      ctx.fillRect(x + 9, y + 1, 6, 6);
      ctx.fillRect(x + 1, y + 9, 14, 6);
    }
  },

  // Horizontal trim piece (chair rail or crown)
  trimPiece: function(ctx, x, y, width, type) {
    const p = this.palette.trim;
    const h = type === 'crown' ? 6 : 4;
    
    ctx.fillStyle = p.dark;
    ctx.fillRect(x, y, width, h);
    ctx.fillStyle = p.mid;
    ctx.fillRect(x, y, width, h - 2);
    ctx.fillStyle = p.light;
    ctx.fillRect(x, y, width, 2);
  },

  // Full wall with wallpaper + wainscoting
  fullWall: function(ctx, startX, startY, tilesWide, colorScheme) {
    // Wallpaper (top 3 tiles)
    for (let x = 0; x < tilesWide; x++) {
      for (let y = 0; y < 3; y++) {
        this.wallpaperPiece(ctx, startX + x * 16, startY + y * 16, x, colorScheme);
      }
    }
    
    // Chair rail
    this.trimPiece(ctx, startX, startY + 48, tilesWide * 16, 'chair');
    
    // Wainscoting (bottom 1 tile)
    for (let x = 0; x < tilesWide; x++) {
      this.wainscotPiece(ctx, startX + x * 16, startY + 52);
    }
    
    // Baseboard
    this.trimPiece(ctx, startX, startY + 68, tilesWide * 16, 'base');
  },

  // Brick wall
  fillBrick: function(ctx, startX, startY, tilesWide, tilesHigh) {
    for (let y = 0; y < tilesHigh; y++) {
      for (let x = 0; x < tilesWide; x++) {
        this.brickPiece(ctx, startX + x * 16, startY + y * 16, x + y);
      }
    }
  }
};

if (typeof module !== 'undefined') module.exports = WALL;
