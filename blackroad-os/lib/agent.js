// BLACKROAD OS - AGENT SPRITES
// 16x32 base sprite size

const AGENT = {
  palette: {
    skin: {
      light: '#ffdbac',
      lightShade: '#e8c090',
      medium: '#c68642',
      mediumShade: '#a06830',
      dark: '#8d5524',
      darkShade: '#704018'
    },
    hair: {
      black: '#1a1a1a',
      brown: '#5a3a1a',
      blonde: '#d4a840',
      red: '#8b3a1a',
      gray: '#808080',
      white: '#e0e0e0'
    },
    eyes: {
      blue: '#4a8fea',
      green: '#4a9a5a',
      brown: '#6a4a2a',
      gray: '#606060'
    }
  },

  // Draw agent sprite
  // facing: 'down', 'up', 'left', 'right'
  // frame: 0-3 for walk cycle, 0 for idle
  draw: function(ctx, x, y, config, frame, time) {
    const skin = this.palette.skin[config.skin] || this.palette.skin.light;
    const skinShade = this.palette.skin[config.skin + 'Shade'] || this.palette.skin.lightShade;
    const hair = this.palette.hair[config.hair] || this.palette.hair.black;
    const shirt = config.shirt || '#4a6fa5';
    const shirtDark = config.shirtDark || '#3a5580';
    const eyes = this.palette.eyes[config.eyes] || this.palette.eyes.blue;
    
    const bounce = Math.sin(time / 8) * 1.5;
    const breathe = Math.sin(time / 20) * 0.5;
    const yy = y + (frame === 0 ? bounce : 0);
    
    // Shadow
    ctx.fillStyle = 'rgba(0,0,0,0.2)';
    ctx.fillRect(x + 2, y + 30, 14, 4);
    
    // Feet
    ctx.fillStyle = '#2a2a2a';
    ctx.fillRect(x + 2, yy + 26, 5, 4);
    ctx.fillRect(x + 10, yy + 26, 5, 4);
    
    // Legs
    ctx.fillStyle = '#3a3a50';
    if (frame === 1) {
      ctx.fillRect(x + 3, yy + 20, 4, 8);
      ctx.fillRect(x + 10, yy + 18, 4, 10);
    } else if (frame === 3) {
      ctx.fillRect(x + 3, yy + 18, 4, 10);
      ctx.fillRect(x + 10, yy + 20, 4, 8);
    } else {
      ctx.fillRect(x + 3, yy + 18, 4, 10);
      ctx.fillRect(x + 10, yy + 18, 4, 10);
    }
    
    // Body
    ctx.fillStyle = shirt;
    ctx.fillRect(x + 1, yy + 8 + breathe, 15, 12);
    ctx.fillStyle = shirtDark;
    ctx.fillRect(x + 3, yy + 10 + breathe, 11, 8);
    
    // Arms
    ctx.fillStyle = shirt;
    if (frame === 1) {
      ctx.fillRect(x - 2, yy + 8 + breathe, 4, 10);
      ctx.fillRect(x + 15, yy + 10 + breathe, 4, 8);
    } else if (frame === 3) {
      ctx.fillRect(x - 2, yy + 10 + breathe, 4, 8);
      ctx.fillRect(x + 15, yy + 8 + breathe, 4, 10);
    } else {
      ctx.fillRect(x - 2, yy + 9 + breathe, 4, 9);
      ctx.fillRect(x + 15, yy + 9 + breathe, 4, 9);
    }
    
    // Hands
    ctx.fillStyle = skin;
    ctx.fillRect(x - 1, yy + 17, 3, 3);
    ctx.fillRect(x + 15, yy + 17, 3, 3);
    
    // Head
    ctx.fillStyle = skin;
    ctx.fillRect(x + 3, yy, 11, 10);
    ctx.fillStyle = skinShade;
    ctx.fillRect(x + 4, yy + 2, 9, 6);
    
    // Hair
    ctx.fillStyle = hair;
    ctx.fillRect(x + 2, yy - 3, 13, 5);
    ctx.fillRect(x + 2, yy, 3, 4);
    ctx.fillRect(x + 12, yy, 3, 4);
    if (config.hairLong) {
      ctx.fillRect(x, yy - 2, 3, 14);
      ctx.fillRect(x + 14, yy - 2, 3, 14);
    }
    
    // Face
    const blink = Math.floor(time / 25) % 30 === 0;
    if (!blink) {
      // Eyes
      ctx.fillStyle = '#fff';
      ctx.fillRect(x + 5, yy + 3, 3, 3);
      ctx.fillRect(x + 10, yy + 3, 3, 3);
      ctx.fillStyle = eyes;
      ctx.fillRect(x + 6, yy + 4, 2, 2);
      ctx.fillRect(x + 11, yy + 4, 2, 2);
    } else {
      ctx.fillStyle = skinShade;
      ctx.fillRect(x + 5, yy + 5, 3, 1);
      ctx.fillRect(x + 10, yy + 5, 3, 1);
    }
    
    // Mouth
    ctx.fillStyle = skinShade;
    ctx.fillRect(x + 7, yy + 8, 3, 1);
  },

  // Draw name badge below agent
  nameBadge: function(ctx, x, y, name, color) {
    ctx.font = '6px "Press Start 2P", monospace';
    const width = ctx.measureText(name).width + 6;
    
    ctx.fillStyle = 'rgba(0,0,0,0.8)';
    ctx.fillRect(x + 8 - width/2, y + 32, width, 10);
    ctx.fillStyle = color || '#4a6fa5';
    ctx.fillRect(x + 8 - width/2, y + 32, width, 2);
    ctx.fillStyle = '#fff';
    ctx.fillText(name, x + 11 - width/2, y + 39);
  },

  // Predefined agents
  presets: {
    LUCIDIA: { skin: 'light', hair: 'black', hairLong: true, eyes: 'blue', shirt: '#e94560', shirtDark: '#c73050' },
    ALICE: { skin: 'light', hair: 'blonde', eyes: 'green', shirt: '#00d9ff', shirtDark: '#00a8cc' },
    OCTAVIA: { skin: 'dark', hair: 'black', eyes: 'brown', shirt: '#00cc66', shirtDark: '#00994d' },
    PRISM: { skin: 'light', hair: 'brown', eyes: 'blue', shirt: '#ff8c00', shirtDark: '#cc7000' },
    ECHO: { skin: 'light', hair: 'red', hairLong: true, eyes: 'gray', shirt: '#cc44cc', shirtDark: '#993399' },
    CIPHER: { skin: 'medium', hair: 'black', eyes: 'brown', shirt: '#aaaa00', shirtDark: '#888800' }
  }
};

if (typeof module !== 'undefined') module.exports = AGENT;
