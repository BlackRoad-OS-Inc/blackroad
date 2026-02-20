// BLACKROAD OS - SERVER RACK
// 40x80 footprint

const SERVER = {
  palette: {
    case: {
      outer: '#0a0a18',
      inner: '#14142a',
      unit: '#1a1a32',
      unitInner: '#101028',
      vent: '#0a0a1a'
    },
    lights: {
      green: '#00ff00',
      greenOff: '#002200',
      orange: '#ff8800',
      orangeOff: '#221100',
      blue: '#00ffff',
      blueOff: '#002222',
      red: '#ff0000',
      redOff: '#220000'
    }
  },

  // Single server unit (32x13)
  unit: function(ctx, x, y, time, index) {
    const c = this.palette.case;
    const l = this.palette.lights;
    
    // Unit chassis
    ctx.fillStyle = c.unit;
    ctx.fillRect(x, y, 32, 13);
    ctx.fillStyle = c.unitInner;
    ctx.fillRect(x + 1, y + 1, 30, 11);
    
    // Vents
    for (let v = 0; v < 5; v++) {
      ctx.fillStyle = c.vent;
      ctx.fillRect(x + 3 + v * 5, y + 2, 3, 9);
    }
    
    // Status lights
    const phase = time / 5 + index * 1.7;
    const g = Math.sin(phase) > 0;
    const o = Math.cos(phase * 0.7) > 0;
    const b = Math.sin(phase * 1.3) > -0.7;
    
    ctx.fillStyle = g ? l.green : l.greenOff;
    ctx.fillRect(x + 26, y + 2, 4, 3);
    ctx.fillStyle = o ? l.orange : l.orangeOff;
    ctx.fillRect(x + 26, y + 6, 4, 3);
    ctx.fillStyle = b ? l.blue : l.blueOff;
    ctx.fillRect(x + 26, y + 10, 4, 2);
  },

  // Full rack (40x80)
  rack: function(ctx, x, y, time) {
    const c = this.palette.case;
    
    // Shadow
    ctx.fillStyle = 'rgba(0,0,0,0.3)';
    ctx.fillRect(x + 4, y + 78, 36, 6);
    
    // Cabinet
    ctx.fillStyle = c.outer;
    ctx.fillRect(x, y, 40, 80);
    ctx.fillStyle = c.inner;
    ctx.fillRect(x + 2, y + 2, 36, 76);
    
    // Server units
    for (let i = 0; i < 5; i++) {
      this.unit(ctx, x + 4, y + 4 + i * 15, time, i);
    }
    
    // Top vent
    ctx.fillStyle = c.vent;
    for (let v = 0; v < 4; v++) {
      ctx.fillRect(x + 8 + v * 8, y + 76, 6, 2);
    }
  },

  // Mini rack (24x48) for smaller spaces
  miniRack: function(ctx, x, y, time) {
    const c = this.palette.case;
    
    ctx.fillStyle = 'rgba(0,0,0,0.3)';
    ctx.fillRect(x + 3, y + 46, 20, 4);
    
    ctx.fillStyle = c.outer;
    ctx.fillRect(x, y, 24, 48);
    ctx.fillStyle = c.inner;
    ctx.fillRect(x + 2, y + 2, 20, 44);
    
    // Smaller units
    for (let i = 0; i < 3; i++) {
      ctx.fillStyle = c.unit;
      ctx.fillRect(x + 3, y + 4 + i * 14, 18, 12);
      ctx.fillStyle = c.unitInner;
      ctx.fillRect(x + 4, y + 5 + i * 14, 16, 10);
      
      // Lights
      const l = this.palette.lights;
      const on = Math.sin(time / 4 + i * 2) > 0;
      ctx.fillStyle = on ? l.green : l.greenOff;
      ctx.fillRect(x + 17, y + 7 + i * 14, 3, 3);
    }
  },

  // Network switch (40x12)
  networkSwitch: function(ctx, x, y, time) {
    ctx.fillStyle = '#1a1a2a';
    ctx.fillRect(x, y, 40, 12);
    ctx.fillStyle = '#14142a';
    ctx.fillRect(x + 1, y + 1, 38, 10);
    
    // Ports with blinking lights
    for (let i = 0; i < 8; i++) {
      ctx.fillStyle = '#0a0a1a';
      ctx.fillRect(x + 3 + i * 4, y + 3, 3, 6);
      
      const on = Math.random() > 0.3;
      ctx.fillStyle = on ? '#00ff00' : '#002200';
      ctx.fillRect(x + 3 + i * 4, y + 2, 2, 1);
    }
  }
};

if (typeof module !== 'undefined') module.exports = SERVER;
