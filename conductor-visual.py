#!/usr/bin/env python3
"""
BlackRoad Conductor v3 - GitHub Command Center

Features:
  - Live GitHub feed (auto-polling events, CI, notifications)
  - Multi-org support with 16 orgs, deep command set
  - Recording & playback of drum sessions
  - Repo constellation map, waveform viz, star field, connection lines
  - Spatial recognition, pattern matching, gesture detection
  - Full drum synthesis with per-hit particle/ripple/trail visuals

Keys:
  R = Start/stop recording    P = Playback last recording
  C = Clear canvas            S = Screenshot (PNG)
  TAB = Cycle org             SPACE = Toggle live feed
  1-4 = Focus zone panel      Q/ESC = Quit
"""

import pygame
import mido
import numpy as np
import sounddevice as sd
import threading
import time
import math
import random
import sys
import os
import subprocess
import json
from collections import deque
from PIL import Image, ImageDraw, ImageFont

# ══════════════════════════════════════════════════════════════
#  CONFIG
# ══════════════════════════════════════════════════════════════
WIDTH, HEIGHT = 1280, 800
FPS = 60
SAMPLE_RATE = 44100
AUDIO_DEVICE = 2

# Colors (BlackRoad brand)
BLACK       = (0, 0, 0)
WHITE       = (255, 255, 255)
HOT_PINK    = (255, 29, 108)
AMBER       = (245, 166, 35)
VIOLET      = (156, 39, 176)
ELEC_BLUE   = (41, 121, 255)
CYAN_GLOW   = (0, 255, 255)
GREEN_GLOW  = (0, 255, 128)
DARK_BG     = (8, 8, 15)
MID_GRAY    = (40, 40, 50)
DIM_GRAY    = (25, 25, 35)
RED_ALERT   = (255, 50, 50)
YELLOW      = (255, 220, 50)
DARK_GREEN  = (0, 80, 40)
SOFT_WHITE  = (180, 180, 200)

FONT_PATH = "/System/Library/Fonts/SFNSMono.ttf"
FONT_FALLBACK = "/System/Library/Fonts/Helvetica.ttc"

# Orgs to cycle through
ORGS = [
    {"name": "BlackRoad-OS",        "color": HOT_PINK,  "repos": "1332+"},
    {"name": "blackboxprogramming", "color": ELEC_BLUE, "repos": "68"},
    {"name": "BlackRoad-AI",        "color": VIOLET,    "repos": "52"},
    {"name": "BlackRoad-Cloud",     "color": CYAN_GLOW, "repos": "30"},
    {"name": "BlackRoad-Security",  "color": RED_ALERT, "repos": "30"},
    {"name": "BlackRoad-Foundation","color": AMBER,     "repos": "30"},
    {"name": "BlackRoad-Hardware",  "color": GREEN_GLOW,"repos": "30"},
    {"name": "BlackRoad-Media",     "color": SOFT_WHITE,"repos": "29"},
    {"name": "BlackRoad-Interactive","color": YELLOW,   "repos": "29"},
    {"name": "Blackbox-Enterprises","color": AMBER,     "repos": "21"},
]

ZONE_COLORS = {36: HOT_PINK, 38: AMBER, 47: VIOLET, 48: ELEC_BLUE, 42: CYAN_GLOW, 49: YELLOW}
ZONE_LABELS = {36: "STATUS", 38: "DEPLOY", 47: "ISSUES", 48: "REPOS", 42: "MONITOR", 49: "BROADCAST"}
ZONE_POSITIONS = {
    36: (0.5, 0.78),    # Kick = bottom center
    38: (0.5, 0.45),    # Snare = center
    47: (0.72, 0.28),   # Tom-R = top right
    48: (0.28, 0.28),   # Tom-L = top left
    42: (0.5, 0.15),    # Hi-Hat = top center
    49: (0.85, 0.12),   # Crash = far top right
}
DRUM_MAP = {
    36: {"zone": "D", "hand": "L"},
    38: {"zone": "X", "hand": "R"},
    47: {"zone": "R", "hand": "R"},
    48: {"zone": "L", "hand": "L"},
    42: {"zone": "C", "hand": "R"},
    49: {"zone": "C", "hand": "L"},
}

AGENT_VELOCITY = 100
PATTERN_TIMEOUT = 2.0
RECORDINGS_DIR = os.path.expanduser("~/.blackroad/conductor-recordings")


# ══════════════════════════════════════════════════════════════
#  GITHUB COMMAND SETS (per org, expanded)
# ══════════════════════════════════════════════════════════════
def gh_cmds(org):
    """Generate command set for a given org."""
    repo = f"{org}/blackroad" if org == "BlackRoad-OS" else f"{org}/.github"
    return {
        48: {  # REPOS
            "soft":  {"label": "List PRs",        "cmd": ["gh", "pr", "list", "--limit", "5", "--repo", repo]},
            "med":   {"label": "Recent Commits",  "cmd": ["gh", "api", f"repos/{repo}/commits", "-q", ".[:5] | .[].commit.message[:60]"]},
            "hard":  {"label": "Branches",        "cmd": ["gh", "api", f"repos/{repo}/branches", "-q", ".[:8] | .[].name"]},
        },
        47: {  # ISSUES
            "soft":  {"label": "Open Issues",     "cmd": ["gh", "issue", "list", "--limit", "5", "--repo", repo]},
            "med":   {"label": "Workflow Runs",   "cmd": ["gh", "run", "list", "--limit", "5", "--repo", repo]},
            "hard":  {"label": "Releases",        "cmd": ["gh", "release", "list", "--limit", "5", "--repo", repo]},
        },
        38: {  # DEPLOY
            "soft":  {"label": "CI Status",       "cmd": ["gh", "run", "list", "--limit", "3", "--repo", repo, "--json", "name,status,conclusion"]},
            "med":   {"label": "Workflows",       "cmd": ["gh", "api", f"repos/{repo}/actions/workflows", "-q", ".workflows[:5] | .[].name"]},
            "hard":  {"label": "Contributors",    "cmd": ["gh", "api", f"repos/{repo}/contributors", "-q", ".[:5] | .[].login"]},
        },
        36: {  # STATUS
            "soft":  {"label": "Repo Stats",      "cmd": ["gh", "api", f"repos/{repo}", "-q", '"{stars: \\(.stargazers_count), forks: \\(.forks_count), issues: \\(.open_issues_count)}"']},
            "med":   {"label": "Org Repos",       "cmd": ["gh", "repo", "list", org, "--limit", "8", "--sort", "updated", "--json", "name,updatedAt"]},
            "hard":  {"label": "Org Events",      "cmd": ["gh", "api", f"orgs/{org}/events", "-q", ".[:6] | .[] | \"\\(.type): \\(.repo.name)\""]},
        },
        42: {  # HI-HAT = MONITOR (your main groove keeper = continuous monitoring)
            "soft":  {"label": "Notifications",   "cmd": ["gh", "api", "notifications", "-q", ".[:5] | .[].subject.title"]},
            "med":   {"label": "Rate Limit",      "cmd": ["gh", "api", "rate_limit", "-q", '"{remaining: \\(.rate.remaining), limit: \\(.rate.limit)}"']},
            "hard":  {"label": "Org Members",     "cmd": ["gh", "api", f"orgs/{org}/members", "-q", ".[:8] | .[].login"]},
        },
        49: {  # CRASH = BROADCAST (dramatic cymbal = big actions)
            "soft":  {"label": "All Orgs",        "cmd": ["gh", "org", "list"]},
            "med":   {"label": "Starred Repos",   "cmd": ["gh", "api", "user/starred", "-q", ".[:5] | .[].full_name"]},
            "hard":  {"label": "Full Org Scan",   "cmd": ["gh", "repo", "list", org, "--limit", "20", "--sort", "updated", "--json", "name,pushedAt"]},
        },
    }


# Patterns (org-independent)
PATTERNS = {
    "paradiddle":    {"seq": [47,48,47,47], "name": "FULL SCAN",    "color": CYAN_GLOW, "effect": "spiral",
                      "action": "Scan org repos", "cmd_tpl": lambda o: ["gh","repo","list",o,"--limit","12","--sort","updated","--json","name,updatedAt"]},
    "double_stroke": {"seq": [47,47,48,48], "name": "DEPLOY ALL",   "color": HOT_PINK,  "effect": "shockwave",
                      "action": "List deployments", "cmd_tpl": lambda o: ["gh","run","list","--limit","10","--repo",f"{o}/blackroad" if o=="BlackRoad-OS" else f"{o}/.github"]},
    "four_floor":    {"seq": [36,38,36,38], "name": "HEALTH CHECK", "color": GREEN_GLOW,"effect": "grid",
                      "action": "CI health", "cmd_tpl": lambda o: ["gh","api",f"repos/{o}/blackroad/actions/runs" if o=="BlackRoad-OS" else f"repos/{o}/.github/actions/runs","-q",".workflow_runs[:5] | .[] | \"\\(.name): \\(.status)\""]},
    "ascending":     {"seq": [36,38,47,48], "name": "SCALE UP",     "color": VIOLET,    "effect": "fountain",
                      "action": "Org events", "cmd_tpl": lambda o: ["gh","api",f"orgs/{o}/events","-q",".[:8] | .[] | \"\\(.type): \\(.repo.name)\""]},
    "descending":    {"seq": [48,47,38,36], "name": "AUDIT",        "color": AMBER,     "effect": "rain",
                      "action": "Security scan", "cmd_tpl": lambda o: ["gh","api",f"repos/{o}/blackroad" if o=="BlackRoad-OS" else f"repos/{o}/.github","-q",'"{archived: \\(.archived), visibility: \\(.visibility)}"']},
    "rock_beat":     {"seq": [42,36,42,38,42,36,42,38], "name": "ROCK BEAT",  "color": WHITE,     "effect": "shockwave",
                      "action": "Full system pulse check", "cmd_tpl": lambda o: ["gh","api",f"orgs/{o}/events","-q",".[:10] | .[] | \"\\(.type): \\(.repo.name)\""]},
    "hihat_rush":    {"seq": [42,42,42,42,42,42], "name": "HAT RUSH",   "color": CYAN_GLOW, "effect": "grid",
                      "action": "Rapid notification scan", "cmd_tpl": lambda o: ["gh","api","notifications","-q",".[:10] | .[].subject.title"]},
    "crash_kick":    {"seq": [49,36], "name": "CRASH KICK",  "color": YELLOW,    "effect": "fountain",
                      "action": "Broadcast to all orgs", "cmd_tpl": lambda o: ["gh","org","list"]},
}


# ══════════════════════════════════════════════════════════════
#  TEXT RENDERER (Pillow → pygame, bypasses broken pygame.font)
# ══════════════════════════════════════════════════════════════
class TextRenderer:
    def __init__(self):
        self._cache = {}
        self._font_cache = {}

    def _get_font(self, size):
        if size not in self._font_cache:
            for path in [FONT_PATH, FONT_FALLBACK]:
                try:
                    self._font_cache[size] = ImageFont.truetype(path, size)
                    break
                except Exception:
                    continue
            else:
                self._font_cache[size] = ImageFont.load_default()
        return self._font_cache[size]

    def render(self, text, size, color):
        key = (text, size, color)
        if key in self._cache:
            return self._cache[key]
        font = self._get_font(size)
        bbox = font.getbbox(text)
        w, h = max(bbox[2]-bbox[0]+4, 1), max(bbox[3]-bbox[1]+4, 1)
        img = Image.new("RGBA", (w, h), (0,0,0,0))
        ImageDraw.Draw(img).text((-bbox[0]+2, -bbox[1]+2), text, fill=(*color, 255), font=font)
        surf = pygame.image.frombuffer(img.tobytes(), img.size, "RGBA").convert_alpha()
        self._cache[key] = surf
        if len(self._cache) > 600:
            for k in list(self._cache)[:250]: del self._cache[k]
        return surf

    def render_alpha(self, text, size, color, alpha):
        a = max(0, min(255, int(alpha * 255)))
        key = (text, size, color, a)
        if key in self._cache:
            return self._cache[key]
        font = self._get_font(size)
        bbox = font.getbbox(text)
        w, h = max(bbox[2]-bbox[0]+4, 1), max(bbox[3]-bbox[1]+4, 1)
        img = Image.new("RGBA", (w, h), (0,0,0,0))
        ImageDraw.Draw(img).text((-bbox[0]+2, -bbox[1]+2), text, fill=(*color, a), font=font)
        surf = pygame.image.frombuffer(img.tobytes(), img.size, "RGBA").convert_alpha()
        self._cache[key] = surf
        if len(self._cache) > 600:
            for k in list(self._cache)[:250]: del self._cache[k]
        return surf

TR = None  # initialized after pygame.init()


# ══════════════════════════════════════════════════════════════
#  AUDIO SYNTHESIS
# ══════════════════════════════════════════════════════════════
def synth_kick(v, dur=0.15):
    t = np.linspace(0, dur, int(SAMPLE_RATE*dur), False); a = (v/127)*0.8
    f = np.linspace(150,40,len(t)); p = np.cumsum(f/SAMPLE_RATE)*2*np.pi
    w = a*np.sin(p)*np.exp(-t*20)
    c = a*0.6*np.random.randn(int(SAMPLE_RATE*0.005))
    w[:len(c)] += c*np.exp(-np.linspace(0,10,len(c)))
    return w.astype(np.float32)

def synth_snare(v, dur=0.12):
    t = np.linspace(0, dur, int(SAMPLE_RATE*dur), False); a = (v/127)*0.7
    return (a*0.5*np.sin(2*np.pi*200*t)*np.exp(-t*30)+a*0.6*np.random.randn(len(t))*np.exp(-t*25)).astype(np.float32)

def synth_tom(v, hz=120, dur=0.18):
    t = np.linspace(0, dur, int(SAMPLE_RATE*dur), False); a = (v/127)*0.7
    f = np.linspace(hz*1.3,hz,len(t)); p = np.cumsum(f/SAMPLE_RATE)*2*np.pi
    return (a*np.sin(p)*np.exp(-t*15)+a*0.1*np.random.randn(len(t))*np.exp(-t*40)).astype(np.float32)

def synth_cymbal(v, dur=0.5):
    t = np.linspace(0, dur, int(SAMPLE_RATE*dur), False); a = (v/127)*0.3
    w = a*np.random.randn(len(t))
    for freq in [3000,4500,6000,8000]: w += a*0.15*np.sin(2*np.pi*freq*t+random.random()*6.28)
    return (w*np.exp(-t*4)).astype(np.float32)

def synth_hihat(v, dur=0.06):
    """Closed hi-hat - short bright noise."""
    t = np.linspace(0, dur, int(SAMPLE_RATE*dur), False); a = (v/127)*0.5
    w = a * np.random.randn(len(t)) * np.exp(-t*60)
    for freq in [6000, 8000, 10000]: w += a*0.1*np.sin(2*np.pi*freq*t)*np.exp(-t*80)
    return w.astype(np.float32)

def synth_crash(v, dur=0.8):
    """Crash cymbal - long shimmering noise."""
    t = np.linspace(0, dur, int(SAMPLE_RATE*dur), False); a = (v/127)*0.4
    w = a * np.random.randn(len(t))
    for freq in [2500, 4000, 5500, 7000, 9000]:
        w += a*0.12*np.sin(2*np.pi*freq*t + random.random()*6.28)
    return (w * np.exp(-t*3)).astype(np.float32)

SYNTHS = {36: lambda v: synth_kick(v), 38: lambda v: synth_snare(v),
          47: lambda v: synth_tom(v,100), 48: lambda v: synth_tom(v,140),
          42: lambda v: synth_hihat(v), 49: lambda v: synth_crash(v)}

def play_sound(note, vel):
    if note in SYNTHS:
        try: sd.play(SYNTHS[note](vel), SAMPLE_RATE, device=AUDIO_DEVICE)
        except: pass

def play_event():
    try: sd.play(synth_cymbal(90), SAMPLE_RATE, device=AUDIO_DEVICE)
    except: pass


# ══════════════════════════════════════════════════════════════
#  VISUAL ELEMENTS
# ══════════════════════════════════════════════════════════════
class Particle:
    def __init__(self, x, y, color, scale=1.0):
        ang = random.uniform(0, 6.283); spd = random.uniform(2,8)*scale
        self.x, self.y = x, y
        self.vx, self.vy = math.cos(ang)*spd, math.sin(ang)*spd
        self.color, self.life = color, 1.0
        self.decay = random.uniform(0.01, 0.03)
        self.size = random.uniform(2, 5)*scale
    def update(self):
        self.x += self.vx; self.y += self.vy; self.vy += 0.05; self.vx *= 0.99
        self.life -= self.decay; self.size *= 0.995
    def draw(self, s):
        if self.life > 0 and self.size > 0.5:
            pygame.draw.circle(s, self.color, (int(self.x), int(self.y)), max(1, int(self.size)))
    @property
    def alive(self): return self.life > 0

class Ripple:
    def __init__(self, x, y, color, max_r=200):
        self.x, self.y, self.color = x, y, color
        self.radius, self.max_r, self.life = 5, max_r, 1.0
    def update(self):
        self.radius += 3; self.life = max(0, 1-self.radius/self.max_r)
    def draw(self, s):
        if self.life > 0:
            pygame.draw.circle(s, self.color, (int(self.x),int(self.y)), int(self.radius), max(1,int(self.life*4)))
    @property
    def alive(self): return self.life > 0

class TextPopup:
    def __init__(self, x, y, text, color, size=24):
        self.x,self.y,self.text,self.color,self.size = x,y,text,color,size; self.life=1.0
    def update(self): self.y -= 1.2; self.life -= 0.015
    def draw(self, s):
        if self.life > 0:
            surf = TR.render_alpha(self.text, self.size, self.color, self.life)
            s.blit(surf, surf.get_rect(center=(int(self.x),int(self.y))))
    @property
    def alive(self): return self.life > 0

class ScreenEffect:
    def __init__(self, etype, color, dur=2.0):
        self.type, self.color = etype, color; self.life = 1.0; self.decay = 1/(dur*FPS); self.t = 0
    def update(self): self.t += 1; self.life -= self.decay
    def draw(self, s):
        if self.life <= 0: return
        r,g,b = self.color; a = self.life
        if self.type == "shockwave":
            pygame.draw.circle(s,(r,g,b),(WIDTH//2,HEIGHT//2),int((1-a)*max(WIDTH,HEIGHT)),max(2,int(a*8)))
        elif self.type == "spiral":
            pts = [(int(WIDTH//2+math.cos((i/100)*18.85+self.t*0.1)*((i/100)*min(WIDTH,HEIGHT)*0.4*(1-a*0.5))),
                    int(HEIGHT//2+math.sin((i/100)*18.85+self.t*0.1)*((i/100)*min(WIDTH,HEIGHT)*0.4*(1-a*0.5)))) for i in range(100)]
            if len(pts)>1: pygame.draw.lines(s,(int(r*a),int(g*a),int(b*a)),False,pts,2)
        elif self.type == "grid":
            c = (int(r*a*0.3),int(g*a*0.3),int(b*a*0.3))
            for x in range(0,WIDTH,40): pygame.draw.line(s,c,(x,0),(x,HEIGHT),1)
            for y in range(0,HEIGHT,40): pygame.draw.line(s,c,(0,y),(WIDTH,y),1)
        elif self.type == "fountain":
            for _ in range(5):
                fx = WIDTH//2+random.randint(-80,80); fy = int(HEIGHT - random.uniform(50,300)*a)
                pygame.draw.circle(s,(int(r*a),int(g*a),int(b*a)),(fx,fy),random.randint(2,6))
        elif self.type == "rain":
            for _ in range(8):
                x=random.randint(0,WIDTH); ys=random.randint(0,int(HEIGHT*(1-self.life)))
                pygame.draw.line(s,(int(r*a*.5),int(g*a*.5),int(b*a*.5)),(x,ys),(x,ys+random.randint(10,30)),1)
    @property
    def alive(self): return self.life > 0


# ══════════════════════════════════════════════════════════════
#  DATA FEED PANEL
# ══════════════════════════════════════════════════════════════
class DataFeed:
    def __init__(self, x, y, w, h, title, color):
        self.x,self.y,self.w,self.h = x,y,w,h
        self.title, self.color = title, color
        self.lines = []; self.max_lines = 30

    def add_line(self, text, color=None):
        self.lines.append((text, color or WHITE, time.time()))
        if len(self.lines) > self.max_lines: self.lines.pop(0)

    def add_output(self, text, color=None):
        for line in text.strip().split("\n")[:12]:
            self.add_line(line.strip()[:65], color or GREEN_GLOW)

    def draw(self, surface):
        panel = pygame.Surface((self.w,self.h), pygame.SRCALPHA)
        panel.fill((*DIM_GRAY, 180)); surface.blit(panel,(self.x,self.y))
        pygame.draw.rect(surface, self.color, (self.x,self.y,self.w,self.h), 1)
        pygame.draw.rect(surface, self.color, (self.x,self.y,self.w,22))
        surface.blit(TR.render(f" {self.title}", 12, BLACK), (self.x+4, self.y+4))
        ly = self.y + 26; lh = 15
        for text, col, ts in self.lines[-(self.h//lh - 2):]:
            age = time.time() - ts
            alpha = max(0.3, min(1.0, 1-(age/30)))
            surface.blit(TR.render_alpha(text, 11, col, alpha), (self.x+6, ly))
            ly += lh
            if ly > self.y + self.h - 8: break


# ══════════════════════════════════════════════════════════════
#  STAR FIELD (background reacts to BPM)
# ══════════════════════════════════════════════════════════════
class StarField:
    def __init__(self, count=120):
        self.stars = [(random.randint(0,WIDTH), random.randint(0,HEIGHT),
                       random.uniform(0.3, 2.0), random.randint(80,200)) for _ in range(count)]
        self.speed_mult = 1.0

    def update(self, bpm):
        self.speed_mult = 1.0 + min(bpm, 200) / 100.0
        new = []
        for x, y, speed, bright in self.stars:
            y += speed * self.speed_mult
            if y > HEIGHT:
                y = 0; x = random.randint(0, WIDTH)
            new.append((x, y, speed, bright))
        self.stars = new

    def draw(self, surface):
        for x, y, speed, bright in self.stars:
            b = min(255, int(bright * (speed / 2.0)))
            sz = 1 if speed < 1.0 else 2
            pygame.draw.circle(surface, (b, b, b+20 if b+20<256 else 255), (int(x), int(y)), sz)


# ══════════════════════════════════════════════════════════════
#  WAVEFORM VISUALIZER (from velocity history)
# ══════════════════════════════════════════════════════════════
class WaveformViz:
    def __init__(self, x, y, w, h):
        self.x,self.y,self.w,self.h = x,y,w,h
        self.samples = deque(maxlen=80)

    def add(self, velocity, note):
        self.samples.append((velocity, ZONE_COLORS.get(note, WHITE)))

    def draw(self, surface):
        if len(self.samples) < 2: return
        # Border
        pygame.draw.rect(surface, MID_GRAY, (self.x,self.y,self.w,self.h), 1)
        # Waveform
        n = len(self.samples)
        step = self.w / max(n-1, 1)
        mid_y = self.y + self.h // 2
        for i in range(n - 1):
            v1, c1 = self.samples[i]
            v2, c2 = self.samples[i+1]
            x1 = int(self.x + i * step)
            x2 = int(self.x + (i+1) * step)
            y1 = int(mid_y - (v1/127) * (self.h//2 - 4))
            y2 = int(mid_y - (v2/127) * (self.h//2 - 4))
            pygame.draw.line(surface, c2, (x1,y1), (x2,y2), 2)
        # Zero line
        pygame.draw.line(surface, (30,30,40), (self.x,mid_y), (self.x+self.w,mid_y), 1)


# ══════════════════════════════════════════════════════════════
#  REPO CONSTELLATION MAP
# ══════════════════════════════════════════════════════════════
class RepoConstellation:
    """Visualizes repos as stars in a constellation. Nodes pulse on activity."""
    def __init__(self, cx, cy, radius):
        self.cx, self.cy, self.radius = cx, cy, radius
        self.nodes = []  # (name, x, y, color, pulse, last_active)
        self.connections = []  # (i, j)

    def set_repos(self, repo_names, color):
        """Arrange repos in a circle/cluster."""
        self.nodes.clear()
        self.connections.clear()
        n = len(repo_names)
        for i, name in enumerate(repo_names):
            angle = (i / max(n, 1)) * 2 * math.pi - math.pi/2
            r = self.radius * (0.6 + random.uniform(0, 0.4))
            x = self.cx + math.cos(angle) * r
            y = self.cy + math.sin(angle) * r
            self.nodes.append([name[:18], x, y, color, 0.0, 0])
            # Connect to neighbors
            if i > 0:
                self.connections.append((i-1, i))
        if n > 2:
            self.connections.append((n-1, 0))  # Close the loop
        # Some cross-connections
        for _ in range(min(n//3, 4)):
            a, b = random.sample(range(n), 2)
            self.connections.append((a, b))

    def pulse_repo(self, name):
        """Pulse a repo node on activity."""
        for node in self.nodes:
            if name.lower() in node[0].lower():
                node[4] = 1.0  # pulse
                node[5] = time.time()

    def update(self):
        for node in self.nodes:
            node[4] *= 0.97  # fade pulse

    def draw(self, surface):
        if not self.nodes: return
        # Connections
        for i, j in self.connections:
            if i < len(self.nodes) and j < len(self.nodes):
                n1, n2 = self.nodes[i], self.nodes[j]
                alpha = max(n1[4], n2[4])
                col = tuple(min(255, int(c * (0.15 + alpha * 0.5))) for c in n1[3])
                pygame.draw.line(surface, col, (int(n1[1]),int(n1[2])), (int(n2[1]),int(n2[2])), 1)
        # Nodes
        for name, x, y, color, pulse, _ in self.nodes:
            sz = int(3 + pulse * 8)
            bright = tuple(min(255, int(c * (0.4 + pulse * 0.6))) for c in color)
            pygame.draw.circle(surface, bright, (int(x), int(y)), sz)
            if pulse > 0.3:
                pygame.draw.circle(surface, bright, (int(x),int(y)), sz+6, 1)
            # Label
            if pulse > 0.1 or random.random() < 0.02:  # Show label on pulse or occasionally
                lbl = TR.render_alpha(name, 9, color, max(0.3, pulse))
                surface.blit(lbl, (int(x) - lbl.get_width()//2, int(y) + sz + 3))


# ══════════════════════════════════════════════════════════════
#  RECORDING & PLAYBACK
# ══════════════════════════════════════════════════════════════
class Recorder:
    def __init__(self):
        self.recording = False
        self.playing = False
        self.events = []       # (relative_time, note, velocity)
        self.rec_start = 0
        self.play_start = 0
        self.play_idx = 0

    def start_recording(self):
        self.recording = True
        self.events = []
        self.rec_start = time.time()

    def stop_recording(self):
        self.recording = False
        # Save to disk
        if self.events:
            os.makedirs(RECORDINGS_DIR, exist_ok=True)
            fname = os.path.join(RECORDINGS_DIR, f"session-{int(time.time())}.json")
            with open(fname, "w") as f:
                json.dump({"events": self.events, "duration": time.time()-self.rec_start}, f)
            return fname
        return None

    def record_hit(self, note, velocity):
        if self.recording:
            self.events.append((time.time() - self.rec_start, note, velocity))

    def start_playback(self):
        if not self.events: return False
        self.playing = True
        self.play_start = time.time()
        self.play_idx = 0
        return True

    def get_playback_events(self):
        """Return any events that should fire now."""
        if not self.playing: return []
        elapsed = time.time() - self.play_start
        fired = []
        while self.play_idx < len(self.events):
            evt_time, note, vel = self.events[self.play_idx]
            if evt_time <= elapsed:
                fired.append((note, vel))
                self.play_idx += 1
            else:
                break
        if self.play_idx >= len(self.events):
            self.playing = False
        return fired


# ══════════════════════════════════════════════════════════════
#  LIVE GITHUB FEED (background polling)
# ══════════════════════════════════════════════════════════════
class LiveFeed:
    def __init__(self):
        self.enabled = True
        self.events = deque(maxlen=30)  # (text, color, time)
        self.last_poll = 0
        self.poll_interval = 30  # seconds
        self.polling = False
        self._org = "BlackRoad-OS"

    def set_org(self, org):
        self._org = org

    def poll(self):
        """Background poll for org events."""
        if self.polling: return
        self.polling = True
        threading.Thread(target=self._do_poll, daemon=True).start()

    def _do_poll(self):
        try:
            # Recent events
            result = subprocess.run(
                ["gh", "api", f"orgs/{self._org}/events", "-q",
                 '.[:5] | .[] | "\\(.type)|\\(.repo.name)|\\(.actor.login)"'],
                capture_output=True, text=True, timeout=15
            )
            if result.returncode == 0 and result.stdout.strip():
                for line in result.stdout.strip().split("\n")[:5]:
                    parts = line.split("|")
                    if len(parts) >= 3:
                        etype, repo, actor = parts[0], parts[1], parts[2]
                        repo_short = repo.split("/")[-1][:25]
                        color = GREEN_GLOW
                        if "Push" in etype: color = ELEC_BLUE
                        elif "Pull" in etype: color = HOT_PINK
                        elif "Issue" in etype: color = AMBER
                        elif "Create" in etype: color = VIOLET
                        elif "Delete" in etype: color = RED_ALERT
                        self.events.append((f"{etype}: {repo_short} ({actor})", color, time.time()))

            # Notification count
            result2 = subprocess.run(
                ["gh", "api", "notifications", "-q", "length"],
                capture_output=True, text=True, timeout=10
            )
            if result2.returncode == 0 and result2.stdout.strip():
                count = result2.stdout.strip()
                if count != "0":
                    self.events.append((f"📬 {count} notifications pending", YELLOW, time.time()))
        except Exception:
            pass
        finally:
            self.polling = False
            self.last_poll = time.time()

    def update(self):
        if self.enabled and (time.time() - self.last_poll) > self.poll_interval:
            self.poll()

    def draw(self, surface, x, y, w):
        if not self.enabled: return
        # Ticker bar
        pygame.draw.rect(surface, (15,15,25), (x, y, w, 18))
        pygame.draw.line(surface, MID_GRAY, (x,y), (x+w,y), 1)
        pygame.draw.line(surface, MID_GRAY, (x,y+18), (x+w,y+18), 1)

        dot_col = GREEN_GLOW if not self.polling else AMBER
        pygame.draw.circle(surface, dot_col, (x+8, y+9), 3)
        lbl = TR.render("LIVE", 9, dot_col)
        surface.blit(lbl, (x+14, y+3))

        # Scroll most recent events
        tx = x + 55
        now = time.time()
        for text, color, ts in list(self.events)[-6:]:
            age = now - ts
            if age > 60: continue
            alpha = max(0.3, 1 - age/60)
            surf = TR.render_alpha(text, 10, color, alpha)
            if tx + surf.get_width() < x + w:
                surface.blit(surf, (tx, y+3))
                tx += surf.get_width() + 20


# ══════════════════════════════════════════════════════════════
#  GITHUB COMMAND RUNNER
# ══════════════════════════════════════════════════════════════
def run_gh_command(cmd, feed, label):
    feed.add_line(f"$ {label}", AMBER)
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=12)
        output = result.stdout.strip() or result.stderr.strip() or "(no output)"
        feed.add_output(output, GREEN_GLOW if result.returncode == 0 else RED_ALERT)
    except subprocess.TimeoutExpired:
        feed.add_line("(timeout)", RED_ALERT)
    except Exception as e:
        feed.add_line(f"(err: {e})", RED_ALERT)


# ══════════════════════════════════════════════════════════════
#  STATE
# ══════════════════════════════════════════════════════════════
class State:
    def __init__(self):
        self.beat_times = deque(maxlen=16)
        self.pattern_buffer = deque(maxlen=12)
        self.velocity_history = deque(maxlen=10)
        self.intensity_window = deque(maxlen=20)
        self.roll_hits = deque(maxlen=20)
        self.last_hit_time = 0.0
        self.last_gesture_time = 0.0
        self.last_gesture_key = ""
        self.total_hits = 0
        self.agent_dispatches = 0
        self.patterns_matched = 0
        self.gestures_triggered = 0
        self.bpm = 0.0
        self.zone_counts = {"L":0,"R":0,"D":0,"X":0,"C":0}
        self.current_org_idx = 0
        self.session_start = time.time()

    @property
    def org(self): return ORGS[self.current_org_idx]
    @property
    def org_name(self): return self.org["name"]

    def next_org(self):
        self.current_org_idx = (self.current_org_idx + 1) % len(ORGS)

    def update_bpm(self, now):
        self.beat_times.append(now)
        if len(self.beat_times) >= 4:
            times = list(self.beat_times)
            intervals = [times[i+1]-times[i] for i in range(len(times)-1)]
            avg = sum(intervals)/len(intervals)
            self.bpm = 60/avg if avg > 0 else 0

    @property
    def intensity(self):
        if not self.intensity_window: return 0
        avg_vel = sum(v for _,v in self.intensity_window)/len(self.intensity_window)
        if len(self.intensity_window) >= 2:
            span = self.intensity_window[-1][0]-self.intensity_window[0][0]
            ff = min(len(self.intensity_window)/max(span,0.01)/8, 1.0)
        else: ff = 0.3
        return min(100, int((avg_vel/127)*60 + ff*40))


# ══════════════════════════════════════════════════════════════
#  PROCESS A HIT (shared by live + playback)
# ══════════════════════════════════════════════════════════════
def process_hit(note, vel, now, state, particles, ripples, popups, screen_effects,
                activity, feeds, canvas, waveform, constellation, recorder, bg_pulse_ref):
    """Process a single MIDI hit - updates all state, visuals, commands."""
    state.total_hits += 1
    state.pattern_buffer.append((note, vel, now))
    state.velocity_history.append(vel)
    state.intensity_window.append((now, vel))
    state.update_bpm(now)

    drum = DRUM_MAP.get(note, {})
    zone = drum.get("zone", "?")
    if zone in state.zone_counts: state.zone_counts[zone] += 1

    recorder.record_hit(note, vel)
    waveform.add(vel, note)

    # Audio
    threading.Thread(target=play_sound, args=(note, vel), daemon=True).start()

    # Visuals
    if note in ZONE_POSITIONS:
        rx, ry = ZONE_POSITIONS[note]
        jitter = (vel/127) * 30
        cx = int(rx*WIDTH + random.uniform(-jitter, jitter))
        cy = int(ry*HEIGHT + random.uniform(-jitter, jitter))
        color = ZONE_COLORS.get(note, WHITE)
        vscale = vel / 80

        for _ in range(int(8+(vel/127)*30)):
            particles.append(Particle(cx, cy, color, vscale))
        ripples.append(Ripple(cx, cy, color, int(60+(vel/127)*150)))

        # Canvas paint
        trail_size = int(3+(vel/127)*15)
        pygame.draw.circle(canvas, color, (cx, cy), trail_size)
        for _ in range(int(vel/25)):
            sx, sy = cx+random.randint(-25,25), cy+random.randint(-25,25)
            pygame.draw.circle(canvas, color, (sx,sy), max(1, trail_size//3))

        bg_pulse_ref[0] = min(1.0, bg_pulse_ref[0] + vel/400)

        # GitHub command
        zone_label = ZONE_LABELS.get(note, "?")
        feed = feeds.get(note)
        cmds = gh_cmds(state.org_name)
        cmd_set = cmds.get(note)

        if cmd_set:
            if vel >= AGENT_VELOCITY:
                action = cmd_set["hard"]
                state.agent_dispatches += 1
                popups.append(TextPopup(cx, cy-20, f"⚡ {action['label']}", color, 24))
                activity.add_line(f"⚡ [{zone_label}] {action['label']}", color)
            elif vel >= 60:
                action = cmd_set["med"]
                popups.append(TextPopup(cx, cy-20, action['label'], color, 18))
                activity.add_line(f"▶ [{zone_label}] {action['label']}", color)
            else:
                action = cmd_set["soft"]
                popups.append(TextPopup(cx, cy-20, action['label'], color, 16))
                activity.add_line(f"♪ [{zone_label}] {action['label']}", color)

            if feed:
                threading.Thread(target=run_gh_command, args=(action["cmd"], feed, action['label']), daemon=True).start()

    # Gestures
    gap = now - state.last_hit_time if state.last_hit_time > 0 else 0
    if len(state.pattern_buffer) >= 2:
        prev = state.pattern_buffer[-2]
        if (now-prev[2]) < 0.04 and prev[0] != note:
            if state.last_gesture_key != "flam" or (now-state.last_gesture_time) > 1.0:
                state.gestures_triggered += 1; state.last_gesture_key = "flam"; state.last_gesture_time = now
                popups.append(TextPopup(WIDTH//2, HEIGHT//2, "📸 SNAPSHOT", CYAN_GLOW, 32))
                activity.add_line("📸 FLAM → System snapshot", CYAN_GLOW)

    if gap > 3.0 and vel >= 80:
        state.gestures_triggered += 1
        popups.append(TextPopup(WIDTH//2, HEIGHT//3, "⚡ WAKE ALL", WHITE, 36))
        screen_effects.append(ScreenEffect("shockwave", WHITE, 1.5))
        activity.add_line("⚡ SILENCE BREAK → Wake all agents", WHITE)
        play_event()

    state.roll_hits.append(now)
    while state.roll_hits and (now-state.roll_hits[0]) > 1.0: state.roll_hits.popleft()
    if len(state.roll_hits) >= 8:
        if state.last_gesture_key != "buzz_roll" or (now-state.last_gesture_time) > 2.0:
            state.gestures_triggered += 1; state.last_gesture_key = "buzz_roll"; state.last_gesture_time = now
            popups.append(TextPopup(WIDTH//2, HEIGHT//2, "📊 MONITORING", GREEN_GLOW, 28))
            activity.add_line("📊 BUZZ ROLL → Continuous monitoring", GREEN_GLOW)

    if len(state.velocity_history) >= 5:
        rv = list(state.velocity_history)[-5:]
        diffs = [rv[i+1]-rv[i] for i in range(len(rv)-1)]
        if all(d > 3 for d in diffs):
            popups.append(TextPopup(WIDTH//2, HEIGHT//2, "📈 SCALE UP", GREEN_GLOW, 30))
            activity.add_line("📈 CRESCENDO → Scale UP", GREEN_GLOW)
        elif all(d < -3 for d in diffs):
            popups.append(TextPopup(WIDTH//2, HEIGHT//2, "📉 SCALE DOWN", AMBER, 30))
            activity.add_line("📉 DECRESCENDO → Scale DOWN", AMBER)

    # Pattern matching
    while state.pattern_buffer and (now-state.pattern_buffer[0][2]) > PATTERN_TIMEOUT:
        state.pattern_buffer.popleft()
    if len(state.pattern_buffer) >= 4:
        recent = [h[0] for h in state.pattern_buffer]
        for key, pat in PATTERNS.items():
            seq = pat["seq"]
            if len(recent) >= len(seq) and recent[-len(seq):] == seq:
                state.patterns_matched += 1
                screen_effects.append(ScreenEffect(pat["effect"], pat["color"], 2.5))
                popups.append(TextPopup(WIDTH//2, HEIGHT//2-80, f"🌀 {pat['name']}", pat["color"], 36))
                activity.add_line(f"🌀 PATTERN: {pat['name']} → {pat['action']}", pat["color"])
                play_event()
                cmd = pat["cmd_tpl"](state.org_name)
                target_feed = feeds.get(47)
                if target_feed:
                    threading.Thread(target=run_gh_command, args=(cmd, target_feed, pat["name"]), daemon=True).start()
                state.pattern_buffer.clear()
                break

    state.last_hit_time = now


# ══════════════════════════════════════════════════════════════
#  MAIN
# ══════════════════════════════════════════════════════════════
def main():
    global TR
    pygame.init()
    screen = pygame.display.set_mode((WIDTH, HEIGHT))
    pygame.display.set_caption("BlackRoad Conductor v3 - GitHub Command Center")
    clock = pygame.time.Clock()
    TR = TextRenderer()

    try:
        midi_port = mido.open_input("USB MIDI")
    except Exception as e:
        print(f"Error: Could not open USB MIDI: {e}")
        sys.exit(1)

    # Scene objects
    particles, ripples, popups, screen_effects = [], [], [], []
    state = State()
    bg_pulse = [0.0]  # mutable ref

    # Panels
    feeds = {
        48: DataFeed(10, 55, 320, 280, "REPOS & PRs", ELEC_BLUE),
        47: DataFeed(WIDTH-330, 55, 320, 280, "ISSUES & ACTIONS", VIOLET),
        38: DataFeed(10, HEIGHT-295, 320, 260, "DEPLOY & CI", AMBER),
        36: DataFeed(WIDTH-330, HEIGHT-295, 320, 260, "STATUS & MONITOR", HOT_PINK),
    }
    activity = DataFeed(345, HEIGHT-165, WIDTH-690, 155, "ACTIVITY LOG", CYAN_GLOW)

    # New systems
    starfield = StarField(150)
    waveform = WaveformViz(345, HEIGHT-335, WIDTH-690, 55)
    constellation = RepoConstellation(WIDTH//2, HEIGHT//2 - 30, 120)
    recorder = Recorder()
    live_feed = LiveFeed()

    # Canvas
    canvas = pygame.Surface((WIDTH, HEIGHT)); canvas.fill(BLACK)
    fade_surf = pygame.Surface((WIDTH, HEIGHT)); fade_surf.fill((1,1,1))

    # Load initial constellation
    def load_constellation(org_name, color):
        def _load():
            try:
                result = subprocess.run(
                    ["gh", "repo", "list", org_name, "--limit", "15", "--sort", "updated", "--json", "name"],
                    capture_output=True, text=True, timeout=10)
                if result.returncode == 0:
                    repos = json.loads(result.stdout)
                    constellation.set_repos([r["name"] for r in repos], color)
            except Exception:
                constellation.set_repos([f"repo-{i}" for i in range(10)], color)
        threading.Thread(target=_load, daemon=True).start()

    load_constellation(state.org_name, state.org["color"])
    live_feed.set_org(state.org_name)
    live_feed.poll()  # Initial poll

    running = True
    while running:
        clock.tick(FPS)

        # ── Events ──
        for event in pygame.event.get():
            if event.type == pygame.QUIT: running = False
            if event.type == pygame.KEYDOWN:
                if event.key in (pygame.K_ESCAPE, pygame.K_q): running = False
                elif event.key == pygame.K_c: canvas.fill(BLACK)
                elif event.key == pygame.K_TAB:
                    state.next_org()
                    org = state.org
                    activity.add_line(f"🔄 Switched to {org['name']} ({org['repos']} repos)", org["color"])
                    popups.append(TextPopup(WIDTH//2, HEIGHT//2, org["name"], org["color"], 36))
                    load_constellation(org["name"], org["color"])
                    live_feed.set_org(org["name"])
                    live_feed.poll()
                elif event.key == pygame.K_r:
                    if recorder.recording:
                        fname = recorder.stop_recording()
                        activity.add_line(f"⏹ Recording saved ({len(recorder.events)} events)", RED_ALERT)
                        popups.append(TextPopup(WIDTH//2, HEIGHT//2, "⏹ SAVED", RED_ALERT, 30))
                    else:
                        recorder.start_recording()
                        activity.add_line("🔴 Recording started...", RED_ALERT)
                        popups.append(TextPopup(WIDTH//2, HEIGHT//2, "🔴 REC", RED_ALERT, 30))
                elif event.key == pygame.K_p:
                    if recorder.start_playback():
                        activity.add_line(f"▶ Playback ({len(recorder.events)} events)", GREEN_GLOW)
                        popups.append(TextPopup(WIDTH//2, HEIGHT//2, "▶ PLAY", GREEN_GLOW, 30))
                    else:
                        activity.add_line("(no recording to play)", MID_GRAY)
                elif event.key == pygame.K_SPACE:
                    live_feed.enabled = not live_feed.enabled
                    status = "ON" if live_feed.enabled else "OFF"
                    activity.add_line(f"📡 Live feed: {status}", CYAN_GLOW)
                elif event.key == pygame.K_s:
                    # Screenshot
                    os.makedirs(RECORDINGS_DIR, exist_ok=True)
                    fname = os.path.join(RECORDINGS_DIR, f"screenshot-{int(time.time())}.png")
                    pygame.image.save(screen, fname)
                    activity.add_line(f"📷 Screenshot saved", GREEN_GLOW)
                    popups.append(TextPopup(WIDTH//2, HEIGHT//2, "📷 SAVED", GREEN_GLOW, 24))

        # ── MIDI ──
        now = time.time()
        for msg in midi_port.iter_pending():
            if msg.type != "note_on" or msg.velocity == 0: continue
            process_hit(msg.note, msg.velocity, now, state, particles, ripples, popups,
                       screen_effects, activity, feeds, canvas, waveform, constellation, recorder, bg_pulse)

        # ── Playback ──
        for note, vel in recorder.get_playback_events():
            process_hit(note, vel, time.time(), state, particles, ripples, popups,
                       screen_effects, activity, feeds, canvas, waveform, constellation, recorder, bg_pulse)

        # ── Update ──
        bg_pulse[0] *= 0.97
        starfield.update(state.bpm)
        constellation.update()
        live_feed.update()
        for p in particles: p.update()
        particles = [p for p in particles if p.alive]
        for r in ripples: r.update()
        ripples = [r for r in ripples if r.alive]
        for p in popups: p.update()
        popups = [p for p in popups if p.alive]
        for e in screen_effects: e.update()
        screen_effects = [e for e in screen_effects if e.alive]

        # ── Draw ──
        pv = int(bg_pulse[0] * 15)
        screen.fill((pv, pv//3, pv//2))

        # Star field
        starfield.draw(screen)

        # Canvas trails
        canvas.blit(fade_surf, (0,0), special_flags=pygame.BLEND_RGB_SUB)
        screen.blit(canvas, (0,0), special_flags=pygame.BLEND_RGB_ADD)

        # Screen effects
        for e in screen_effects: e.draw(screen)

        # Constellation (center)
        constellation.draw(screen)

        # Connection lines between active zones
        active_zones = [(n, ZONE_POSITIONS[n]) for n in ZONE_POSITIONS
                        if state.zone_counts.get(DRUM_MAP.get(n,{}).get("zone",""), 0) > 0]
        if len(active_zones) >= 2:
            for i in range(len(active_zones)-1):
                n1, (rx1, ry1) = active_zones[i]
                n2, (rx2, ry2) = active_zones[i+1]
                c1, c2 = ZONE_COLORS[n1], ZONE_COLORS[n2]
                avg_c = tuple((a+b)//2 for a,b in zip(c1,c2))
                dim_c = tuple(c//5 for c in avg_c)
                pygame.draw.line(screen, dim_c,
                               (int(rx1*WIDTH), int(ry1*HEIGHT)),
                               (int(rx2*WIDTH), int(ry2*HEIGHT)), 1)

        # Ripples & particles
        for r in ripples: r.draw(screen)
        for p in particles: p.draw(screen)

        # Zone crosshairs
        for note, (rx, ry) in ZONE_POSITIONS.items():
            x, y = int(rx*WIDTH), int(ry*HEIGHT)
            col = ZONE_COLORS[note]
            dim = tuple(c//6 for c in col)
            pygame.draw.circle(screen, dim, (x,y), 25, 1)
            pygame.draw.line(screen, dim, (x-12,y),(x+12,y), 1)
            pygame.draw.line(screen, dim, (x,y-12),(x,y+12), 1)
            screen.blit(TR.render(ZONE_LABELS[note], 10, dim), (x-15, y+28))

        # Data feeds
        for feed in feeds.values(): feed.draw(screen)
        activity.draw(screen)

        # Waveform
        waveform.draw(screen)

        # Live feed ticker
        live_feed.draw(screen, 0, HEIGHT-18, WIDTH)

        # Popups
        for p in popups: p.draw(screen)

        # ── HUD ──
        title = TR.render("BLACKROAD CONDUCTOR", 20, HOT_PINK)
        screen.blit(title, (WIDTH//2 - title.get_width()//2, 6))

        # Org name
        org = state.org
        org_label = TR.render(f"ORG: {org['name']} ({org['repos']} repos)", 12, org["color"])
        screen.blit(org_label, (WIDTH//2 - org_label.get_width()//2, 30))

        # Stats
        sx = 345
        for label, val, col in [
            ("HITS", str(state.total_hits), WHITE),
            ("BPM", f"{state.bpm:.0f}" if state.bpm > 0 else "---", AMBER),
            ("CMD", str(state.agent_dispatches), HOT_PINK),
            ("PAT", str(state.patterns_matched), CYAN_GLOW),
            ("GEST", str(state.gestures_triggered), GREEN_GLOW),
        ]:
            s = TR.render(f"{label}:{val}", 11, col)
            screen.blit(s, (sx, 44))
            sx += s.get_width() + 12

        # Intensity bar
        bw, bh = 150, 8
        bx, by = WIDTH//2-bw//2, HEIGHT-28
        pygame.draw.rect(screen, MID_GRAY, (bx,by,bw,bh))
        intensity = state.intensity
        icol = RED_ALERT if intensity >= 80 else AMBER if intensity >= 50 else GREEN_GLOW
        pygame.draw.rect(screen, icol, (bx,by,int(intensity/100*bw),bh))

        # Recording indicator
        if recorder.recording:
            if int(time.time()*2) % 2:
                pygame.draw.circle(screen, RED_ALERT, (WIDTH-20, 15), 6)
            screen.blit(TR.render("REC", 10, RED_ALERT), (WIDTH-45, 10))
        if recorder.playing:
            screen.blit(TR.render("▶ PLAY", 10, GREEN_GLOW), (WIDTH-60, 10))

        # Key hints
        hints = "TAB=Org  R=Rec  P=Play  S=Shot  C=Clear  SPACE=Feed  Q=Quit"
        screen.blit(TR.render(hints, 9, MID_GRAY), (5, HEIGHT-15))

        pygame.display.flip()

    midi_port.close()

    # Session summary
    dur = time.time() - state.session_start
    print(f"\n{'='*50}")
    print(f"  CONDUCTOR SESSION COMPLETE")
    print(f"  Duration: {int(dur//60)}m {int(dur%60)}s")
    print(f"  Hits: {state.total_hits}  Commands: {state.agent_dispatches}")
    print(f"  Patterns: {state.patterns_matched}  Gestures: {state.gestures_triggered}")
    print(f"  Peak BPM: {state.bpm:.0f}")
    print(f"{'='*50}\n")

    pygame.quit()


if __name__ == "__main__":
    main()
