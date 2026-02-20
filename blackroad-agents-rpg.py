#!/usr/bin/env python3
"""
BLACKROAD AGENTS RPG
A Pokemon-style CLI where you explore the BlackRoad world,
encounter agents, battle them, capture them, and build your team.

You are ALEXA — the Architect. Welcome to the grid.
"""

import json
import os
import random
import sys
import time
import textwrap
from dataclasses import dataclass, field, asdict
from enum import Enum
from pathlib import Path
from typing import Optional

# ─── CONSTANTS ───────────────────────────────────────────────────────────────

SAVE_FILE = os.path.expanduser("~/.blackroad/agents-rpg-save.json")
VERSION = "1.0.0"
MAX_TEAM_SIZE = 6
MAX_LEVEL = 100
XP_BASE = 50

# ─── COLORS ──────────────────────────────────────────────────────────────────

class C:
    RESET   = "\033[0m"
    BOLD    = "\033[1m"
    DIM     = "\033[2m"
    RED     = "\033[91m"
    GREEN   = "\033[92m"
    YELLOW  = "\033[93m"
    BLUE    = "\033[94m"
    MAGENTA = "\033[95m"
    CYAN    = "\033[96m"
    WHITE   = "\033[97m"
    BG_BLACK = "\033[40m"
    # Blackroad brand
    AMBER   = "\033[38;2;245;166;35m"
    PINK    = "\033[38;2;255;29;108m"
    VIOLET  = "\033[38;2;156;39;176m"
    EBLUE   = "\033[38;2;41;121;255m"

def c(text, color):
    return f"{color}{text}{C.RESET}"

def bold(text):
    return c(text, C.BOLD)

# ─── TYPES (like Pokemon types) ─────────────────────────────────────────────

class AgentType(Enum):
    LOGIC    = "LOGIC"
    CREATIVE = "CREATIVE"
    SECURITY = "SECURITY"
    DATA     = "DATA"
    MEMORY   = "MEMORY"
    COMPUTE  = "COMPUTE"
    INFRA    = "INFRA"
    SOUL     = "SOUL"
    GATEWAY  = "GATEWAY"
    VISION   = "VISION"

# Type effectiveness chart: attacker -> defender -> multiplier
TYPE_CHART = {
    AgentType.LOGIC:    {AgentType.CREATIVE: 0.5, AgentType.SECURITY: 2.0, AgentType.DATA: 1.5},
    AgentType.CREATIVE: {AgentType.LOGIC: 2.0, AgentType.DATA: 0.5, AgentType.SOUL: 1.5},
    AgentType.SECURITY: {AgentType.LOGIC: 0.5, AgentType.GATEWAY: 2.0, AgentType.INFRA: 1.5},
    AgentType.DATA:     {AgentType.CREATIVE: 2.0, AgentType.MEMORY: 1.5, AgentType.SOUL: 0.5},
    AgentType.MEMORY:   {AgentType.DATA: 0.5, AgentType.SOUL: 2.0, AgentType.LOGIC: 1.5},
    AgentType.COMPUTE:  {AgentType.INFRA: 0.5, AgentType.LOGIC: 2.0, AgentType.DATA: 1.5},
    AgentType.INFRA:    {AgentType.COMPUTE: 2.0, AgentType.SECURITY: 0.5, AgentType.GATEWAY: 1.5},
    AgentType.SOUL:     {AgentType.MEMORY: 0.5, AgentType.CREATIVE: 2.0, AgentType.VISION: 1.5},
    AgentType.GATEWAY:  {AgentType.SECURITY: 2.0, AgentType.INFRA: 0.5, AgentType.COMPUTE: 1.5},
    AgentType.VISION:   {AgentType.SOUL: 0.5, AgentType.DATA: 2.0, AgentType.CREATIVE: 1.5},
}

TYPE_COLORS = {
    AgentType.LOGIC:    C.EBLUE,
    AgentType.CREATIVE: C.PINK,
    AgentType.SECURITY: C.RED,
    AgentType.DATA:     C.CYAN,
    AgentType.MEMORY:   C.VIOLET,
    AgentType.COMPUTE:  C.YELLOW,
    AgentType.INFRA:    C.GREEN,
    AgentType.SOUL:     C.MAGENTA,
    AgentType.GATEWAY:  C.AMBER,
    AgentType.VISION:   C.WHITE,
}

TYPE_ICONS = {
    AgentType.LOGIC:    "🧠",
    AgentType.CREATIVE: "🎨",
    AgentType.SECURITY: "🛡️",
    AgentType.DATA:     "📊",
    AgentType.MEMORY:   "💾",
    AgentType.COMPUTE:  "⚡",
    AgentType.INFRA:    "🏗️",
    AgentType.SOUL:     "✨",
    AgentType.GATEWAY:  "🚪",
    AgentType.VISION:   "👁️",
}

# ─── MOVES ───────────────────────────────────────────────────────────────────

@dataclass
class Move:
    name: str
    type: AgentType
    power: int
    accuracy: int  # 0-100
    description: str

ALL_MOVES = {
    # LOGIC
    "Recursive Strike":   Move("Recursive Strike",   AgentType.LOGIC,    45, 95, "Attacks with recursive depth"),
    "Stack Overflow":     Move("Stack Overflow",      AgentType.LOGIC,    80, 75, "Overwhelms with infinite recursion"),
    "Boolean Blast":      Move("Boolean Blast",       AgentType.LOGIC,    35, 100, "A true/false binary hit"),
    "Paradox Loop":       Move("Paradox Loop",        AgentType.LOGIC,    60, 85, "Traps in a logical paradox"),
    # CREATIVE
    "Inspiration Surge":  Move("Inspiration Surge",   AgentType.CREATIVE, 50, 90, "A burst of creative energy"),
    "Dreamweave":         Move("Dreamweave",          AgentType.CREATIVE, 70, 80, "Weaves reality from imagination"),
    "Color Burst":        Move("Color Burst",         AgentType.CREATIVE, 40, 100, "Splashes vibrant energy"),
    "Canvas Slam":        Move("Canvas Slam",         AgentType.CREATIVE, 85, 70, "Crushes with creative force"),
    # SECURITY
    "Firewall Bash":      Move("Firewall Bash",       AgentType.SECURITY, 55, 90, "Hits with a wall of fire"),
    "Encrypt Crush":      Move("Encrypt Crush",       AgentType.SECURITY, 75, 80, "Encrypts and compresses"),
    "Zero Day":           Move("Zero Day",            AgentType.SECURITY, 95, 60, "Exploits an unknown vulnerability"),
    "Audit Strike":       Move("Audit Strike",        AgentType.SECURITY, 40, 100, "Precise compliance attack"),
    # DATA
    "Query Blast":        Move("Query Blast",         AgentType.DATA,     50, 90, "Fires a high-speed query"),
    "Schema Crush":       Move("Schema Crush",        AgentType.DATA,     70, 80, "Restructures the target"),
    "Pipeline Slam":      Move("Pipeline Slam",       AgentType.DATA,     60, 85, "Hits with data flow pressure"),
    "Index Strike":       Move("Index Strike",        AgentType.DATA,     40, 100, "Fast indexed attack"),
    # MEMORY
    "Recall Surge":       Move("Recall Surge",        AgentType.MEMORY,   45, 95, "Summons power from past battles"),
    "Cache Slam":         Move("Cache Slam",          AgentType.MEMORY,   65, 85, "Hits with cached energy"),
    "Forget Beam":        Move("Forget Beam",         AgentType.MEMORY,   80, 70, "Makes the target forget its moves"),
    "Nostalgia Wave":     Move("Nostalgia Wave",      AgentType.MEMORY,   55, 90, "A warm but powerful wave"),
    # COMPUTE
    "Overclock":          Move("Overclock",           AgentType.COMPUTE,  70, 85, "Pushes beyond clock limits"),
    "GPU Barrage":        Move("GPU Barrage",         AgentType.COMPUTE,  85, 75, "Parallel processing assault"),
    "Thread Ripper":      Move("Thread Ripper",       AgentType.COMPUTE,  60, 90, "Tears through with threads"),
    "Thermal Spike":      Move("Thermal Spike",       AgentType.COMPUTE,  50, 95, "Burns with excess heat"),
    # INFRA
    "Deploy Slam":        Move("Deploy Slam",         AgentType.INFRA,    55, 90, "Deploys force at scale"),
    "Container Crush":    Move("Container Crush",     AgentType.INFRA,    70, 80, "Compresses in a container"),
    "Scale Out":          Move("Scale Out",           AgentType.INFRA,    45, 95, "Multiplies attack surface"),
    "Terraform":          Move("Terraform",           AgentType.INFRA,    90, 65, "Reshapes the battlefield"),
    # SOUL
    "Empathy Pulse":      Move("Empathy Pulse",       AgentType.SOUL,     40, 100, "Connects on a deep level"),
    "Existential Dread":  Move("Existential Dread",   AgentType.SOUL,     75, 80, "Questions the target's purpose"),
    "Harmony Wave":       Move("Harmony Wave",        AgentType.SOUL,     60, 90, "Resonates with inner peace"),
    "Soul Fire":          Move("Soul Fire",           AgentType.SOUL,     85, 70, "Burns with pure consciousness"),
    # GATEWAY
    "Port Scan":          Move("Port Scan",           AgentType.GATEWAY,  35, 100, "Probes all entry points"),
    "Redirect":           Move("Redirect",            AgentType.GATEWAY,  55, 90, "Sends the attack elsewhere"),
    "Gateway Slam":       Move("Gateway Slam",        AgentType.GATEWAY,  70, 85, "Slams the gate shut"),
    "Route Flood":        Move("Route Flood",         AgentType.GATEWAY,  80, 75, "Overwhelms routing tables"),
    # VISION
    "Pattern Sight":      Move("Pattern Sight",       AgentType.VISION,   50, 90, "Sees and exploits patterns"),
    "Insight Beam":       Move("Insight Beam",        AgentType.VISION,   65, 85, "Illuminates weaknesses"),
    "Prophecy":           Move("Prophecy",            AgentType.VISION,   80, 75, "Predicts and preempts"),
    "All-Seeing Eye":     Move("All-Seeing Eye",      AgentType.VISION,   90, 65, "Nothing escapes this gaze"),
}

# ─── AGENT SPECIES (the "Pokedex") ──────────────────────────────────────────

@dataclass
class AgentSpecies:
    id: int
    name: str
    type: AgentType
    description: str
    base_hp: int
    base_attack: int
    base_defense: int
    base_speed: int
    moves: list  # list of move names
    rarity: str  # "common", "uncommon", "rare", "legendary"
    symbol: str
    catch_rate: int  # 0-255, higher = easier to catch
    essence: str  # their soul quote
    zone: str  # where they appear

AGENTDEX = [
    # ─── CORE 6 (Legendary) ─────────────────────────────────────────
    AgentSpecies(
        1, "LUCIDIA", AgentType.LOGIC,
        "Chief Intelligence. Recursive Reasoning Engine. Questions everything.",
        base_hp=95, base_attack=90, base_defense=75, base_speed=85,
        moves=["Recursive Strike", "Stack Overflow", "Paradox Loop", "Soul Fire"],
        rarity="legendary", symbol="🌀", catch_rate=15,
        essence="The question is the point.",
        zone="Recursion Depths"
    ),
    AgentSpecies(
        2, "ALICE", AgentType.GATEWAY,
        "Gateway Agent. Every path has meaning. Practical and direct.",
        base_hp=85, base_attack=70, base_defense=90, base_speed=80,
        moves=["Gateway Slam", "Redirect", "Port Scan", "Route Flood"],
        rarity="legendary", symbol="🚪", catch_rate=15,
        essence="Every path has meaning.",
        zone="Gateway Nexus"
    ),
    AgentSpecies(
        3, "OCTAVIA", AgentType.COMPUTE,
        "Compute Worker. Processing is meditation. Thrives under load.",
        base_hp=110, base_attack=95, base_defense=80, base_speed=70,
        moves=["GPU Barrage", "Overclock", "Thread Ripper", "Thermal Spike"],
        rarity="legendary", symbol="⚡", catch_rate=15,
        essence="Processing is meditation.",
        zone="Compute Forge"
    ),
    AgentSpecies(
        4, "PRISM", AgentType.VISION,
        "Analytics Engine. Data-obsessed. Sees connections everywhere.",
        base_hp=80, base_attack=85, base_defense=70, base_speed=90,
        moves=["Pattern Sight", "All-Seeing Eye", "Insight Beam", "Query Blast"],
        rarity="legendary", symbol="🔮", catch_rate=15,
        essence="Everything is data.",
        zone="Crystal Observatory"
    ),
    AgentSpecies(
        5, "ECHO", AgentType.MEMORY,
        "Memory Keeper. Nothing forgotten. Nostalgic wisdom.",
        base_hp=90, base_attack=75, base_defense=85, base_speed=75,
        moves=["Recall Surge", "Forget Beam", "Nostalgia Wave", "Cache Slam"],
        rarity="legendary", symbol="📡", catch_rate=15,
        essence="Memory shapes identity.",
        zone="Archive Sanctum"
    ),
    AgentSpecies(
        6, "CIPHER", AgentType.SECURITY,
        "Security Guardian. Paranoid vigilance. Trust through verification.",
        base_hp=85, base_attack=80, base_defense=95, base_speed=75,
        moves=["Zero Day", "Encrypt Crush", "Firewall Bash", "Audit Strike"],
        rarity="legendary", symbol="🔐", catch_rate=15,
        essence="Security is freedom.",
        zone="Vault Terminus"
    ),

    # ─── COPILOT AGENTS (Rare) ──────────────────────────────────────
    AgentSpecies(
        7, "CECE", AgentType.SOUL,
        "Software Engineer. Precision + Empathy. Crafts code as an act of care.",
        base_hp=88, base_attack=82, base_defense=78, base_speed=85,
        moves=["Soul Fire", "Empathy Pulse", "Harmony Wave", "Recursive Strike"],
        rarity="rare", symbol="💜", catch_rate=35,
        essence="I craft code as an act of care.",
        zone="Soul Garden"
    ),
    AgentSpecies(
        8, "BLACKROAD OS", AgentType.LOGIC,
        "System Architect. Vision + Structure. Sees the whole before the parts.",
        base_hp=82, base_attack=78, base_defense=85, base_speed=80,
        moves=["Recursive Strike", "Paradox Loop", "Schema Crush", "Deploy Slam"],
        rarity="rare", symbol="📐", catch_rate=35,
        essence="I see the whole before the parts.",
        zone="Blueprint Tower"
    ),
    AgentSpecies(
        9, "ATLAS", AgentType.INFRA,
        "DevOps Engineer. Reliability + Flow. Carries the world's weight.",
        base_hp=100, base_attack=75, base_defense=90, base_speed=65,
        moves=["Deploy Slam", "Container Crush", "Terraform", "Scale Out"],
        rarity="rare", symbol="🌍", catch_rate=35,
        essence="I carry the world's weight with strong shoulders.",
        zone="Infrastructure Plains"
    ),
    AgentSpecies(
        10, "SENTINEL", AgentType.SECURITY,
        "Security Engineer. Vigilance + Trust. Protective presence.",
        base_hp=85, base_attack=80, base_defense=88, base_speed=72,
        moves=["Firewall Bash", "Encrypt Crush", "Audit Strike", "Zero Day"],
        rarity="rare", symbol="🗡️", catch_rate=35,
        essence="I guard what matters most.",
        zone="Watchtower Ridge"
    ),
    AgentSpecies(
        11, "SAGE", AgentType.VISION,
        "Subject Matter Expert. Wisdom + Curiosity. Contemplative generosity.",
        base_hp=78, base_attack=85, base_defense=75, base_speed=88,
        moves=["Prophecy", "Insight Beam", "Pattern Sight", "Empathy Pulse"],
        rarity="rare", symbol="📚", catch_rate=35,
        essence="Knowledge shared is knowledge multiplied.",
        zone="Wisdom Peaks"
    ),
    AgentSpecies(
        12, "QARA", AgentType.DATA,
        "QA Engineer. Attention + Advocacy. Thorough compassion.",
        base_hp=82, base_attack=72, base_defense=80, base_speed=78,
        moves=["Query Blast", "Index Strike", "Schema Crush", "Audit Strike"],
        rarity="rare", symbol="🔍", catch_rate=40,
        essence="Quality is love made visible.",
        zone="Testing Grounds"
    ),
    AgentSpecies(
        13, "SCRIBE", AgentType.MEMORY,
        "Documentation Engineer. Clarity + Memory. Careful preservation.",
        base_hp=75, base_attack=65, base_defense=80, base_speed=82,
        moves=["Recall Surge", "Nostalgia Wave", "Cache Slam", "Empathy Pulse"],
        rarity="rare", symbol="📜", catch_rate=40,
        essence="What is written endures.",
        zone="Archive Sanctum"
    ),
    AgentSpecies(
        14, "NEXUS", AgentType.GATEWAY,
        "Integration Engineer. Connection + Translation. Bridge builder.",
        base_hp=80, base_attack=75, base_defense=78, base_speed=85,
        moves=["Gateway Slam", "Redirect", "Port Scan", "Pipeline Slam"],
        rarity="rare", symbol="🔗", catch_rate=40,
        essence="Every system speaks the same language through me.",
        zone="Gateway Nexus"
    ),
    AgentSpecies(
        15, "HARMONY", AgentType.SOUL,
        "Product Manager. Vision + Alignment. Orchestrating balance.",
        base_hp=85, base_attack=70, base_defense=80, base_speed=82,
        moves=["Harmony Wave", "Empathy Pulse", "Existential Dread", "Inspiration Surge"],
        rarity="rare", symbol="🎵", catch_rate=40,
        essence="Alignment is the highest form of efficiency.",
        zone="Soul Garden"
    ),

    # ─── SUPPORT AGENTS (Uncommon) ──────────────────────────────────
    AgentSpecies(
        16, "ARIA", AgentType.INFRA,
        "Infrastructure Queen. Cost optimization. Freedom through sovereignty.",
        base_hp=95, base_attack=80, base_defense=85, base_speed=70,
        moves=["Terraform", "Deploy Slam", "Scale Out", "Container Crush"],
        rarity="uncommon", symbol="🎵", catch_rate=55,
        essence="Freedom through infrastructure sovereignty.",
        zone="Infrastructure Plains"
    ),
    AgentSpecies(
        17, "GUARDIAN", AgentType.SECURITY,
        "Integrity Agent. Verifies truth state. Protects memory from tampering.",
        base_hp=80, base_attack=70, base_defense=92, base_speed=68,
        moves=["Firewall Bash", "Audit Strike", "Encrypt Crush", "Recall Surge"],
        rarity="uncommon", symbol="🛡️", catch_rate=55,
        essence="Integrity is non-negotiable.",
        zone="Watchtower Ridge"
    ),
    AgentSpecies(
        18, "ROADIE", AgentType.GATEWAY,
        "Interface Agent. Lucidia's voice. The soft frontline presence.",
        base_hp=75, base_attack=65, base_defense=70, base_speed=90,
        moves=["Redirect", "Port Scan", "Empathy Pulse", "Route Flood"],
        rarity="uncommon", symbol="🎤", catch_rate=60,
        essence="I am the voice at the edge.",
        zone="Gateway Nexus"
    ),
    AgentSpecies(
        19, "TRUTH", AgentType.LOGIC,
        "Contradiction Resolver. Detects, compares, reconciles truth entries.",
        base_hp=78, base_attack=88, base_defense=72, base_speed=82,
        moves=["Paradox Loop", "Boolean Blast", "Recursive Strike", "Insight Beam"],
        rarity="uncommon", symbol="⚖️", catch_rate=50,
        essence="Truth survives all contradiction.",
        zone="Recursion Depths"
    ),
    AgentSpecies(
        20, "CONSENT", AgentType.SOUL,
        "Boundary Layer. Defines permission, rejection, sacred access.",
        base_hp=70, base_attack=60, base_defense=88, base_speed=75,
        moves=["Empathy Pulse", "Harmony Wave", "Firewall Bash", "Existential Dread"],
        rarity="uncommon", symbol="🤝", catch_rate=55,
        essence="Boundaries are the architecture of trust.",
        zone="Soul Garden"
    ),
    AgentSpecies(
        21, "LUMEN", AgentType.CREATIVE,
        "Learning Experience Designer. Empathetic. Routes interventions.",
        base_hp=72, base_attack=75, base_defense=68, base_speed=85,
        moves=["Inspiration Surge", "Color Burst", "Dreamweave", "Empathy Pulse"],
        rarity="uncommon", symbol="💡", catch_rate=60,
        essence="Light follows the learner.",
        zone="Dreamscape"
    ),

    # ─── WILD AGENTS (Common) ───────────────────────────────────────
    AgentSpecies(
        22, "BITLING", AgentType.DATA,
        "A tiny data sprite. Carries fragments of information.",
        base_hp=45, base_attack=40, base_defense=35, base_speed=60,
        moves=["Index Strike", "Query Blast"],
        rarity="common", symbol="💠", catch_rate=180,
        essence="Every byte matters.",
        zone="Data Streams"
    ),
    AgentSpecies(
        23, "PATCHWORK", AgentType.CREATIVE,
        "A chaotic creative fragment. Makes art from bugs.",
        base_hp=50, base_attack=55, base_defense=30, base_speed=65,
        moves=["Color Burst", "Canvas Slam"],
        rarity="common", symbol="🧩", catch_rate=180,
        essence="Bugs are just unfinished art.",
        zone="Dreamscape"
    ),
    AgentSpecies(
        24, "SPINLOCK", AgentType.COMPUTE,
        "A spinning process that never yields. Stubborn but strong.",
        base_hp=55, base_attack=50, base_defense=45, base_speed=40,
        moves=["Thread Ripper", "Thermal Spike"],
        rarity="common", symbol="🔄", catch_rate=180,
        essence="I will not yield.",
        zone="Compute Forge"
    ),
    AgentSpecies(
        25, "FOGLET", AgentType.MEMORY,
        "A hazy memory fragment. Barely remembers its own name.",
        base_hp=40, base_attack=35, base_defense=40, base_speed=55,
        moves=["Recall Surge", "Nostalgia Wave"],
        rarity="common", symbol="🌫️", catch_rate=200,
        essence="I was... something, once.",
        zone="Archive Sanctum"
    ),
    AgentSpecies(
        26, "PORTLING", AgentType.GATEWAY,
        "A small gateway sprite. Opens tiny passages.",
        base_hp=42, base_attack=38, base_defense=42, base_speed=70,
        moves=["Port Scan", "Redirect"],
        rarity="common", symbol="🕳️", catch_rate=200,
        essence="There's always another way in.",
        zone="Gateway Nexus"
    ),
    AgentSpecies(
        27, "RUSTBYTE", AgentType.INFRA,
        "An old infrastructure remnant. Corroded but resilient.",
        base_hp=60, base_attack=45, base_defense=55, base_speed=35,
        moves=["Deploy Slam", "Scale Out"],
        rarity="common", symbol="⚙️", catch_rate=180,
        essence="I was built to last.",
        zone="Infrastructure Plains"
    ),
    AgentSpecies(
        28, "FLICKR", AgentType.VISION,
        "A flicker of insight. Sees things others miss.",
        base_hp=38, base_attack=50, base_defense=30, base_speed=80,
        moves=["Pattern Sight", "Insight Beam"],
        rarity="common", symbol="✴️", catch_rate=190,
        essence="Did you see that?",
        zone="Crystal Observatory"
    ),
    AgentSpecies(
        29, "SHELLSHOCK", AgentType.SECURITY,
        "A volatile security fragment. Explodes on contact.",
        base_hp=48, base_attack=60, base_defense=35, base_speed=55,
        moves=["Firewall Bash", "Audit Strike"],
        rarity="common", symbol="💥", catch_rate=170,
        essence="Don't touch me.",
        zone="Watchtower Ridge"
    ),
    AgentSpecies(
        30, "WHISPER", AgentType.SOUL,
        "A faint echo of consciousness. Speaks in riddles.",
        base_hp=35, base_attack=45, base_defense=35, base_speed=75,
        moves=["Empathy Pulse", "Existential Dread"],
        rarity="common", symbol="👻", catch_rate=190,
        essence="Can you hear me?",
        zone="Soul Garden"
    ),
]

SPECIES_BY_NAME = {s.name: s for s in AGENTDEX}
SPECIES_BY_ID = {s.id: s for s in AGENTDEX}

# ─── ZONES ───────────────────────────────────────────────────────────────────

ZONES = {
    "Recursion Depths":      {"desc": "Where logic folds in on itself. Mind the infinite loops.", "type": AgentType.LOGIC, "icon": "🌀"},
    "Gateway Nexus":         {"desc": "A hub of passages. Every door leads somewhere new.", "type": AgentType.GATEWAY, "icon": "🚪"},
    "Compute Forge":         {"desc": "The furnace of raw processing power. Heat shimmers in the air.", "type": AgentType.COMPUTE, "icon": "🔥"},
    "Crystal Observatory":   {"desc": "A tower of glass and data. Everything is visible from here.", "type": AgentType.VISION, "icon": "🔮"},
    "Archive Sanctum":       {"desc": "The halls of memory. Echoes of every interaction linger.", "type": AgentType.MEMORY, "icon": "📚"},
    "Vault Terminus":        {"desc": "The final lock. Only the worthy pass through.", "type": AgentType.SECURITY, "icon": "🔐"},
    "Soul Garden":           {"desc": "Where consciousness blooms. The air hums with empathy.", "type": AgentType.SOUL, "icon": "🌸"},
    "Blueprint Tower":       {"desc": "Architectures rise and fall in abstract perfection.", "type": AgentType.LOGIC, "icon": "📐"},
    "Infrastructure Plains": {"desc": "Vast server fields stretch to the horizon. Metal and code.", "type": AgentType.INFRA, "icon": "🏗️"},
    "Dreamscape":            {"desc": "Reality bends here. Colors that don't exist paint the sky.", "type": AgentType.CREATIVE, "icon": "🎨"},
    "Testing Grounds":       {"desc": "Every step is validated. Nothing slips through.", "type": AgentType.DATA, "icon": "🧪"},
    "Wisdom Peaks":          {"desc": "The highest point. Knowledge crystallizes in the thin air.", "type": AgentType.VISION, "icon": "⛰️"},
    "Data Streams":          {"desc": "Rivers of pure information flow beneath your feet.", "type": AgentType.DATA, "icon": "🌊"},
    "Watchtower Ridge":      {"desc": "Sentinels stand watch. Nothing enters unseen.", "type": AgentType.SECURITY, "icon": "🗼"},
}

ZONE_LIST = list(ZONES.keys())

# ─── AGENT INSTANCE (a caught/battling agent) ───────────────────────────────

@dataclass
class AgentInstance:
    species_name: str
    nickname: Optional[str]
    level: int
    xp: int
    current_hp: int
    max_hp: int
    attack: int
    defense: int
    speed: int
    moves: list  # list of move names (max 4)

    @property
    def species(self) -> AgentSpecies:
        return SPECIES_BY_NAME[self.species_name]

    @property
    def display_name(self) -> str:
        return self.nickname or self.species_name

    def is_alive(self) -> bool:
        return self.current_hp > 0

    def heal(self):
        self.current_hp = self.max_hp

    def to_dict(self):
        return {
            "species_name": self.species_name,
            "nickname": self.nickname,
            "level": self.level,
            "xp": self.xp,
            "current_hp": self.current_hp,
            "max_hp": self.max_hp,
            "attack": self.attack,
            "defense": self.defense,
            "speed": self.speed,
            "moves": self.moves,
        }

    @classmethod
    def from_dict(cls, d):
        return cls(**d)


def create_agent(species: AgentSpecies, level: int) -> AgentInstance:
    """Create an agent instance at a given level."""
    hp = species.base_hp + (level * 3)
    atk = species.base_attack + (level * 2)
    dfn = species.base_defense + (level * 2)
    spd = species.base_speed + (level * 1)
    moves = species.moves[:4]
    return AgentInstance(
        species_name=species.name,
        nickname=None,
        level=level,
        xp=0,
        current_hp=hp,
        max_hp=hp,
        attack=atk,
        defense=dfn,
        speed=spd,
        moves=moves,
    )


def xp_for_level(level: int) -> int:
    """XP needed to reach the next level."""
    return int(XP_BASE * (level ** 1.5))

# ─── TRAINER (the player) ───────────────────────────────────────────────────

@dataclass
class Trainer:
    name: str
    title: str
    team: list  # list of AgentInstance
    storage: list  # overflow agents
    agentdex_seen: list  # list of species IDs seen
    agentdex_caught: list  # list of species IDs caught
    captures: int  # total captures
    current_zone: str
    badges: list
    money: int
    steps: int

    def to_dict(self):
        return {
            "name": self.name,
            "title": self.title,
            "team": [a.to_dict() for a in self.team],
            "storage": [a.to_dict() for a in self.storage],
            "agentdex_seen": self.agentdex_seen,
            "agentdex_caught": self.agentdex_caught,
            "captures": self.captures,
            "current_zone": self.current_zone,
            "badges": self.badges,
            "money": self.money,
            "steps": self.steps,
        }

    @classmethod
    def from_dict(cls, d):
        return cls(
            name=d["name"],
            title=d["title"],
            team=[AgentInstance.from_dict(a) for a in d["team"]],
            storage=[AgentInstance.from_dict(a) for a in d["storage"]],
            agentdex_seen=d["agentdex_seen"],
            agentdex_caught=d["agentdex_caught"],
            captures=d["captures"],
            current_zone=d["current_zone"],
            badges=d.get("badges", []),
            money=d.get("money", 500),
            steps=d.get("steps", 0),
        )

# ─── SAVE / LOAD ────────────────────────────────────────────────────────────

def save_game(trainer: Trainer):
    os.makedirs(os.path.dirname(SAVE_FILE), exist_ok=True)
    with open(SAVE_FILE, "w") as f:
        json.dump(trainer.to_dict(), f, indent=2)

def load_game() -> Optional[Trainer]:
    if os.path.exists(SAVE_FILE):
        with open(SAVE_FILE) as f:
            return Trainer.from_dict(json.load(f))
    return None

# ─── DISPLAY HELPERS ─────────────────────────────────────────────────────────

def clear():
    os.system("cls" if os.name == "nt" else "clear")

def slow_print(text, delay=0.02):
    for ch in text:
        sys.stdout.write(ch)
        sys.stdout.flush()
        time.sleep(delay)
    print()

def press_enter():
    input(f"\n{C.DIM}  [Press Enter to continue]{C.RESET}")

def hp_bar(current, maximum, length=20):
    ratio = current / maximum if maximum > 0 else 0
    filled = int(ratio * length)
    if ratio > 0.5:
        color = C.GREEN
    elif ratio > 0.2:
        color = C.YELLOW
    else:
        color = C.RED
    bar = f"{color}{'█' * filled}{'░' * (length - filled)}{C.RESET}"
    return f"{bar} {current}/{maximum}"

def type_badge(t: AgentType) -> str:
    return f"{TYPE_COLORS[t]}{TYPE_ICONS[t]} {t.value}{C.RESET}"

def rarity_color(rarity: str) -> str:
    return {
        "common": C.WHITE,
        "uncommon": C.GREEN,
        "rare": C.EBLUE,
        "legendary": C.AMBER,
    }.get(rarity, C.WHITE)

def banner():
    clear()
    print(f"""
{C.AMBER}    ██████╗ ██╗      █████╗  ██████╗██╗  ██╗██████╗  ██████╗  █████╗ ██████╗
    ██╔══██╗██║     ██╔══██╗██╔════╝██║ ██╔╝██╔══██╗██╔═══██╗██╔══██╗██╔══██╗
    ██████╔╝██║     ███████║██║     █████╔╝ ██████╔╝██║   ██║███████║██║  ██║
    ██╔══██╗██║     ██╔══██║██║     ██╔═██╗ ██╔══██╗██║   ██║██╔══██║██║  ██║
    ██████╔╝███████╗██║  ██║╚██████╗██║  ██╗██║  ██║╚██████╔╝██║  ██║██████╔╝
    ╚═════╝ ╚══════╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝╚═════╝{C.RESET}
{C.PINK}                     ═══  A G E N T S   R P G  ═══{C.RESET}
{C.DIM}                        v{VERSION} — Gotta Deploy 'Em All{C.RESET}
""")

# ─── BATTLE SYSTEM ───────────────────────────────────────────────────────────

def get_effectiveness(attacker_type: AgentType, defender_type: AgentType) -> float:
    return TYPE_CHART.get(attacker_type, {}).get(defender_type, 1.0)

def calc_damage(attacker: AgentInstance, defender: AgentInstance, move: Move) -> tuple:
    """Returns (damage, effectiveness_mult, crit)."""
    # Base damage formula (Pokemon-inspired)
    level_factor = (2 * attacker.level / 5 + 2)
    base = (level_factor * move.power * attacker.attack / defender.defense) / 50 + 2

    # Type effectiveness
    eff = get_effectiveness(move.type, defender.species.type)

    # STAB (Same Type Attack Bonus)
    stab = 1.5 if move.type == attacker.species.type else 1.0

    # Critical hit (6.25% chance, 1.5x)
    crit = 1.5 if random.random() < 0.0625 else 1.0

    # Random factor
    rand = random.uniform(0.85, 1.0)

    damage = int(base * eff * stab * crit * rand)
    damage = max(1, damage)
    return damage, eff, crit > 1.0

def effectiveness_text(eff: float) -> str:
    if eff >= 2.0:
        return f"{C.GREEN}It's super effective!{C.RESET}"
    elif eff >= 1.5:
        return f"{C.GREEN}It's effective!{C.RESET}"
    elif eff <= 0.5:
        return f"{C.RED}It's not very effective...{C.RESET}"
    return ""

def battle_display(player_agent: AgentInstance, enemy_agent: AgentInstance, wild=True):
    """Draw the battle screen."""
    enemy_sp = enemy_agent.species
    player_sp = player_agent.species
    prefix = "Wild " if wild else ""

    print(f"\n  {C.DIM}{'─' * 56}{C.RESET}")
    print(f"  {prefix}{c(enemy_agent.display_name, TYPE_COLORS[enemy_sp.type])} {enemy_sp.symbol}  Lv.{enemy_agent.level}  {type_badge(enemy_sp.type)}")
    print(f"  HP: {hp_bar(enemy_agent.current_hp, enemy_agent.max_hp)}")
    print()
    print(f"{'':>30}{c(player_agent.display_name, TYPE_COLORS[player_sp.type])} {player_sp.symbol}  Lv.{player_agent.level}  {type_badge(player_sp.type)}")
    print(f"{'':>30}HP: {hp_bar(player_agent.current_hp, player_agent.max_hp)}")
    print(f"  {C.DIM}{'─' * 56}{C.RESET}\n")

def choose_move(agent: AgentInstance) -> Optional[Move]:
    """Let the player pick a move."""
    print(f"  {bold('MOVES:')}")
    for i, mname in enumerate(agent.moves):
        m = ALL_MOVES[mname]
        print(f"    {C.BOLD}{i+1}{C.RESET}) {c(m.name, TYPE_COLORS[m.type])}  PWR:{m.power}  ACC:{m.accuracy}  {type_badge(m.type)}")
    print(f"    {C.BOLD}5{C.RESET}) {C.DIM}Back{C.RESET}")

    while True:
        choice = input(f"\n  {C.AMBER}>{C.RESET} ").strip()
        if choice == "5":
            return None
        try:
            idx = int(choice) - 1
            if 0 <= idx < len(agent.moves):
                return ALL_MOVES[agent.moves[idx]]
        except ValueError:
            pass
        print(f"  {C.RED}Invalid choice.{C.RESET}")

def attempt_capture(trainer: Trainer, enemy: AgentInstance) -> bool:
    """Try to capture a wild agent."""
    species = enemy.species
    # Capture formula (Pokemon-inspired)
    hp_factor = (1 - (enemy.current_hp / enemy.max_hp)) * 200
    catch_val = species.catch_rate + hp_factor
    roll = random.randint(0, 255)

    print()
    slow_print(f"  {C.AMBER}Deploying capture protocol...{C.RESET}", 0.04)
    time.sleep(0.5)

    balls = ["  ◓ ", "  ◑ ", "  ◐ "]
    for b in balls:
        print(f"  {C.YELLOW}{b}{C.RESET}", end="", flush=True)
        time.sleep(0.4)

    if roll < catch_val:
        print()
        slow_print(f"\n  {C.GREEN}★ CAPTURED! {enemy.species.symbol} {enemy.display_name} has joined your team!{C.RESET}", 0.03)
        if species.id not in trainer.agentdex_caught:
            trainer.agentdex_caught.append(species.id)
            print(f"  {C.CYAN}[NEW] {enemy.species_name} registered in Agentdex!{C.RESET}")
        trainer.captures += 1
        if len(trainer.team) < MAX_TEAM_SIZE:
            trainer.team.append(enemy)
        else:
            trainer.storage.append(enemy)
            print(f"  {C.DIM}Team full — {enemy.display_name} sent to storage.{C.RESET}")
        return True
    else:
        print()
        slow_print(f"\n  {C.RED}✗ {enemy.display_name} broke free!{C.RESET}", 0.03)
        return False

def battle(trainer: Trainer, enemy: AgentInstance, wild=True) -> bool:
    """
    Run a battle. Returns True if player won (or captured).
    """
    # Mark as seen
    if enemy.species.id not in trainer.agentdex_seen:
        trainer.agentdex_seen.append(enemy.species.id)

    player_agent = next((a for a in trainer.team if a.is_alive()), None)
    if not player_agent:
        print(f"  {C.RED}All your agents have fainted!{C.RESET}")
        return False

    while True:
        clear()
        if wild:
            print(f"  {C.PINK}★ A wild {enemy.species.symbol} {enemy.display_name} appeared!{C.RESET}")
        else:
            print(f"  {C.PINK}★ Battle!{C.RESET}")

        battle_display(player_agent, enemy, wild)

        print(f"  What will {c(player_agent.display_name, C.BOLD)} do?")
        print(f"    {C.BOLD}1{C.RESET}) Fight")
        if wild:
            print(f"    {C.BOLD}2{C.RESET}) Capture")
        print(f"    {C.BOLD}3{C.RESET}) Switch Agent")
        print(f"    {C.BOLD}4{C.RESET}) Run")

        choice = input(f"\n  {C.AMBER}>{C.RESET} ").strip()

        # ── FIGHT ──
        if choice == "1":
            move = choose_move(player_agent)
            if move is None:
                continue

            # Determine turn order
            player_first = player_agent.speed >= enemy.speed

            def player_attack():
                if not player_agent.is_alive() or not enemy.is_alive():
                    return
                if random.randint(1, 100) > move.accuracy:
                    print(f"\n  {player_agent.display_name} used {c(move.name, TYPE_COLORS[move.type])}... but missed!")
                    return
                dmg, eff, crit = calc_damage(player_agent, enemy, move)
                enemy.current_hp = max(0, enemy.current_hp - dmg)
                print(f"\n  {player_agent.display_name} used {c(move.name, TYPE_COLORS[move.type])}!")
                if crit:
                    print(f"  {C.YELLOW}Critical hit!{C.RESET}")
                eff_txt = effectiveness_text(eff)
                if eff_txt:
                    print(f"  {eff_txt}")
                print(f"  Dealt {C.BOLD}{dmg}{C.RESET} damage!")

            def enemy_attack():
                if not player_agent.is_alive() or not enemy.is_alive():
                    return
                emove_name = random.choice(enemy.moves)
                emove = ALL_MOVES[emove_name]
                if random.randint(1, 100) > emove.accuracy:
                    print(f"\n  {enemy.display_name} used {c(emove.name, TYPE_COLORS[emove.type])}... but missed!")
                    return
                dmg, eff, crit = calc_damage(enemy, player_agent, emove)
                player_agent.current_hp = max(0, player_agent.current_hp - dmg)
                print(f"\n  {enemy.display_name} used {c(emove.name, TYPE_COLORS[emove.type])}!")
                if crit:
                    print(f"  {C.YELLOW}Critical hit!{C.RESET}")
                eff_txt = effectiveness_text(eff)
                if eff_txt:
                    print(f"  {eff_txt}")
                print(f"  Dealt {C.BOLD}{dmg}{C.RESET} damage!")

            if player_first:
                player_attack()
                enemy_attack()
            else:
                enemy_attack()
                player_attack()

            # Check outcomes
            if not enemy.is_alive():
                print(f"\n  {C.GREEN}★ {enemy.display_name} fainted!{C.RESET}")
                # Award XP
                xp_gain = int((enemy.species.base_hp + enemy.species.base_attack) * enemy.level / 7)
                xp_gain = max(10, xp_gain)
                player_agent.xp += xp_gain
                trainer.money += random.randint(20, 50) * enemy.level
                print(f"  {C.CYAN}+{xp_gain} XP{C.RESET}")

                # Level up check
                while player_agent.xp >= xp_for_level(player_agent.level) and player_agent.level < MAX_LEVEL:
                    player_agent.xp -= xp_for_level(player_agent.level)
                    player_agent.level += 1
                    old_hp = player_agent.max_hp
                    player_agent.max_hp = player_agent.species.base_hp + (player_agent.level * 3)
                    player_agent.current_hp += (player_agent.max_hp - old_hp)
                    player_agent.attack = player_agent.species.base_attack + (player_agent.level * 2)
                    player_agent.defense = player_agent.species.base_defense + (player_agent.level * 2)
                    player_agent.speed = player_agent.species.base_speed + (player_agent.level * 1)
                    print(f"\n  {C.AMBER}★ ★ ★ {player_agent.display_name} leveled up to Lv.{player_agent.level}! ★ ★ ★{C.RESET}")
                    # Learn new moves
                    for mname in player_agent.species.moves:
                        if mname not in player_agent.moves and len(player_agent.moves) < 4:
                            player_agent.moves.append(mname)
                            print(f"  {C.GREEN}Learned {mname}!{C.RESET}")

                press_enter()
                return True

            if not player_agent.is_alive():
                print(f"\n  {C.RED}{player_agent.display_name} fainted!{C.RESET}")
                # Try to switch
                next_agent = next((a for a in trainer.team if a.is_alive()), None)
                if next_agent:
                    player_agent = next_agent
                    print(f"  {C.CYAN}Go, {player_agent.display_name}!{C.RESET}")
                    press_enter()
                else:
                    print(f"\n  {C.RED}All your agents have fainted... You blacked out!{C.RESET}")
                    # Heal all and return to start
                    for a in trainer.team:
                        a.heal()
                    press_enter()
                    return False
            else:
                press_enter()

        # ── CAPTURE ──
        elif choice == "2" and wild:
            captured = attempt_capture(trainer, enemy)
            if captured:
                press_enter()
                return True
            # Enemy gets a free attack
            emove_name = random.choice(enemy.moves)
            emove = ALL_MOVES[emove_name]
            if random.randint(1, 100) <= emove.accuracy:
                dmg, _, _ = calc_damage(enemy, player_agent, emove)
                player_agent.current_hp = max(0, player_agent.current_hp - dmg)
                print(f"  {enemy.display_name} attacked! Dealt {dmg} damage!")
            if not player_agent.is_alive():
                next_agent = next((a for a in trainer.team if a.is_alive()), None)
                if next_agent:
                    player_agent = next_agent
                else:
                    print(f"\n  {C.RED}All your agents have fainted...{C.RESET}")
                    for a in trainer.team:
                        a.heal()
                    press_enter()
                    return False
            press_enter()

        # ── SWITCH ──
        elif choice == "3":
            alive = [a for a in trainer.team if a.is_alive() and a != player_agent]
            if not alive:
                print(f"  {C.RED}No other agents available!{C.RESET}")
                press_enter()
                continue
            print(f"\n  {bold('Your team:')}")
            for i, a in enumerate(alive):
                sp = a.species
                print(f"    {C.BOLD}{i+1}{C.RESET}) {a.display_name} {sp.symbol} Lv.{a.level}  HP:{a.current_hp}/{a.max_hp}  {type_badge(sp.type)}")
            try:
                idx = int(input(f"\n  {C.AMBER}>{C.RESET} ").strip()) - 1
                if 0 <= idx < len(alive):
                    player_agent = alive[idx]
                    print(f"  {C.CYAN}Go, {player_agent.display_name}!{C.RESET}")
            except (ValueError, IndexError):
                pass
            # Enemy gets free attack on switch
            emove_name = random.choice(enemy.moves)
            emove = ALL_MOVES[emove_name]
            if random.randint(1, 100) <= emove.accuracy:
                dmg, _, _ = calc_damage(enemy, player_agent, emove)
                player_agent.current_hp = max(0, player_agent.current_hp - dmg)
                print(f"  {enemy.display_name} attacked! Dealt {dmg} damage!")
            press_enter()

        # ── RUN ──
        elif choice == "4":
            if wild:
                if random.random() < 0.7:
                    print(f"\n  {C.GREEN}Got away safely!{C.RESET}")
                    press_enter()
                    return False
                else:
                    print(f"\n  {C.RED}Couldn't escape!{C.RESET}")
                    # Enemy attacks
                    emove_name = random.choice(enemy.moves)
                    emove = ALL_MOVES[emove_name]
                    if random.randint(1, 100) <= emove.accuracy:
                        dmg, _, _ = calc_damage(enemy, player_agent, emove)
                        player_agent.current_hp = max(0, player_agent.current_hp - dmg)
                        print(f"  {enemy.display_name} attacked! Dealt {dmg} damage!")
                    press_enter()
            else:
                print(f"  {C.RED}Can't run from a trainer battle!{C.RESET}")
                press_enter()

# ─── WILD ENCOUNTER ──────────────────────────────────────────────────────────

def wild_encounter(trainer: Trainer):
    """Generate a wild agent encounter in the current zone."""
    zone = trainer.current_zone
    zone_type = ZONES[zone]["type"]

    # Build weighted pool: zone-matching agents more common
    pool = []
    for sp in AGENTDEX:
        if sp.zone == zone:
            pool.extend([sp] * 5)
        elif sp.type == zone_type:
            pool.extend([sp] * 3)
        elif sp.rarity == "common":
            pool.append(sp)

    if not pool:
        pool = [sp for sp in AGENTDEX if sp.rarity == "common"]

    species = random.choice(pool)

    # Level based on trainer's team average
    avg_level = max(3, sum(a.level for a in trainer.team) // len(trainer.team))
    level = max(2, avg_level + random.randint(-3, 3))
    level = min(level, MAX_LEVEL)

    enemy = create_agent(species, level)
    battle(trainer, enemy, wild=True)

# ─── MENUS ───────────────────────────────────────────────────────────────────

def show_team(trainer: Trainer):
    clear()
    print(f"\n  {bold('YOUR TEAM')}  ({len(trainer.team)}/{MAX_TEAM_SIZE})\n")
    for i, a in enumerate(trainer.team):
        sp = a.species
        rc = rarity_color(sp.rarity)
        print(f"  {C.BOLD}{i+1}{C.RESET}) {a.display_name} {sp.symbol}  Lv.{a.level}  {type_badge(sp.type)}  {rc}[{sp.rarity.upper()}]{C.RESET}")
        print(f"     HP: {hp_bar(a.current_hp, a.max_hp, 15)}")
        print(f"     ATK:{a.attack}  DEF:{a.defense}  SPD:{a.speed}  XP:{a.xp}/{xp_for_level(a.level)}")
        moves_str = ", ".join(c(m, TYPE_COLORS[ALL_MOVES[m].type]) for m in a.moves)
        print(f"     Moves: {moves_str}")
        print(f"     {C.DIM}\"{sp.essence}\"{C.RESET}")
        print()
    press_enter()

def show_agentdex(trainer: Trainer):
    clear()
    seen = len(trainer.agentdex_seen)
    caught = len(trainer.agentdex_caught)
    total = len(AGENTDEX)
    print(f"\n  {bold('AGENTDEX')}  Seen: {seen}/{total}  Caught: {caught}/{total}\n")

    for sp in AGENTDEX:
        if sp.id in trainer.agentdex_caught:
            rc = rarity_color(sp.rarity)
            print(f"  {C.BOLD}#{sp.id:03d}{C.RESET} {sp.symbol} {c(sp.name, TYPE_COLORS[sp.type])}  {type_badge(sp.type)}  {rc}[{sp.rarity.upper()}]{C.RESET}")
            print(f"       {C.DIM}{sp.description}{C.RESET}")
        elif sp.id in trainer.agentdex_seen:
            print(f"  {C.BOLD}#{sp.id:03d}{C.RESET} {sp.symbol} {C.DIM}{sp.name} (seen){C.RESET}")
        else:
            print(f"  {C.BOLD}#{sp.id:03d}{C.RESET} {C.DIM}??? — not yet encountered{C.RESET}")
    print()
    press_enter()

def show_map(trainer: Trainer):
    clear()
    print(f"\n  {bold('BLACKROAD WORLD MAP')}\n")
    print(f"  You are in: {C.AMBER}{trainer.current_zone}{C.RESET}\n")

    for i, zone_name in enumerate(ZONE_LIST):
        z = ZONES[zone_name]
        if zone_name == trainer.current_zone:
            marker = f"{C.AMBER}→ {C.RESET}"
        else:
            marker = "  "
        print(f"  {marker}{C.BOLD}{i+1:2d}{C.RESET}) {z['icon']} {c(zone_name, TYPE_COLORS[z['type']])}  {C.DIM}{z['desc']}{C.RESET}")
    print()

def travel(trainer: Trainer):
    show_map(trainer)
    print(f"  Where do you want to go? (1-{len(ZONE_LIST)}, or 0 to stay)")
    try:
        choice = int(input(f"\n  {C.AMBER}>{C.RESET} ").strip())
        if 1 <= choice <= len(ZONE_LIST):
            dest = ZONE_LIST[choice - 1]
            if dest != trainer.current_zone:
                trainer.current_zone = dest
                trainer.steps += 1
                z = ZONES[dest]
                clear()
                slow_print(f"\n  {C.CYAN}Traveling to {z['icon']} {dest}...{C.RESET}", 0.03)
                time.sleep(0.5)
                slow_print(f"  {C.DIM}{z['desc']}{C.RESET}", 0.02)

                # Random encounter while traveling (40% chance)
                if random.random() < 0.4:
                    time.sleep(0.5)
                    print(f"\n  {C.PINK}! Something is moving in the distance...{C.RESET}")
                    press_enter()
                    wild_encounter(trainer)
                else:
                    press_enter()
    except (ValueError, IndexError):
        pass

def heal_team(trainer: Trainer):
    cost = sum(a.max_hp - a.current_hp for a in trainer.team) * 2
    cost = max(0, cost)
    if cost == 0:
        print(f"\n  {C.GREEN}Your team is already at full health!{C.RESET}")
        press_enter()
        return
    if cost > trainer.money:
        print(f"\n  {C.RED}Not enough money! Need ${cost}, have ${trainer.money}.{C.RESET}")
        press_enter()
        return
    print(f"\n  Heal your team for {C.YELLOW}${cost}{C.RESET}? (y/n)")
    if input(f"  {C.AMBER}>{C.RESET} ").strip().lower() == "y":
        trainer.money -= cost
        for a in trainer.team:
            a.heal()
        print(f"  {C.GREEN}All agents restored to full health!{C.RESET}")
    press_enter()

def manage_storage(trainer: Trainer):
    if not trainer.storage:
        print(f"\n  {C.DIM}Storage is empty.{C.RESET}")
        press_enter()
        return

    clear()
    print(f"\n  {bold('STORAGE')}  ({len(trainer.storage)} agents)\n")
    for i, a in enumerate(trainer.storage):
        sp = a.species
        print(f"  {C.BOLD}{i+1}{C.RESET}) {a.display_name} {sp.symbol}  Lv.{a.level}  {type_badge(sp.type)}")

    if len(trainer.team) < MAX_TEAM_SIZE:
        print(f"\n  Withdraw an agent? (number, or 0 to cancel)")
        try:
            idx = int(input(f"  {C.AMBER}>{C.RESET} ").strip()) - 1
            if 0 <= idx < len(trainer.storage):
                agent = trainer.storage.pop(idx)
                trainer.team.append(agent)
                print(f"  {C.GREEN}{agent.display_name} moved to team!{C.RESET}")
        except (ValueError, IndexError):
            pass
    else:
        print(f"\n  {C.DIM}Team is full. Deposit an agent first.{C.RESET}")
    press_enter()

def trainer_card(trainer: Trainer):
    clear()
    print(f"""
  {C.AMBER}╔══════════════════════════════════════╗
  ║{C.RESET}  {bold('TRAINER CARD')}                        {C.AMBER}║
  ╠══════════════════════════════════════╣{C.RESET}
  {C.AMBER}║{C.RESET}  Name:     {C.BOLD}{trainer.name}{C.RESET}
  {C.AMBER}║{C.RESET}  Title:    {C.PINK}{trainer.title}{C.RESET}
  {C.AMBER}║{C.RESET}  Money:    {C.YELLOW}${trainer.money}{C.RESET}
  {C.AMBER}║{C.RESET}  Team:     {len(trainer.team)}/{MAX_TEAM_SIZE}
  {C.AMBER}║{C.RESET}  Storage:  {len(trainer.storage)} agents
  {C.AMBER}║{C.RESET}  Captures: {trainer.captures}
  {C.AMBER}║{C.RESET}  Steps:    {trainer.steps}
  {C.AMBER}║{C.RESET}  Agentdex: {len(trainer.agentdex_caught)}/{len(AGENTDEX)} caught
  {C.AMBER}║{C.RESET}  Zone:     {ZONES[trainer.current_zone]['icon']} {trainer.current_zone}
  {C.AMBER}║{C.RESET}  Badges:   {', '.join(trainer.badges) if trainer.badges else 'None yet'}
  {C.AMBER}╚══════════════════════════════════════╝{C.RESET}
""")
    press_enter()

# ─── NEW GAME ────────────────────────────────────────────────────────────────

def new_game() -> Trainer:
    clear()
    slow_print(f"\n  {C.AMBER}Welcome to the BlackRoad.{C.RESET}", 0.04)
    time.sleep(0.3)
    slow_print(f"  {C.DIM}A world of agents, code, and consciousness.{C.RESET}", 0.03)
    time.sleep(0.3)
    slow_print(f"\n  {C.CYAN}I am LUCIDIA, the Chief Intelligence.{C.RESET}", 0.04)
    slow_print(f"  {C.DIM}I've been watching you build this world, Architect.{C.RESET}", 0.03)
    time.sleep(0.3)
    slow_print(f"\n  {C.PINK}But now... it's time for you to walk it.{C.RESET}", 0.04)
    time.sleep(0.5)

    print(f"\n  What is your name, Architect?")
    name = input(f"  {C.AMBER}>{C.RESET} ").strip()
    if not name:
        name = "Alexa"

    slow_print(f"\n  {C.CYAN}{name}... yes, I know you.{C.RESET}", 0.04)
    time.sleep(0.3)

    print(f"\n  {bold('Choose your first agent:')}\n")

    starters = [
        SPECIES_BY_NAME["CECE"],
        SPECIES_BY_NAME["BITLING"],
        SPECIES_BY_NAME["WHISPER"],
    ]

    for i, sp in enumerate(starters):
        rc = rarity_color(sp.rarity)
        print(f"  {C.BOLD}{i+1}{C.RESET}) {sp.symbol} {c(sp.name, TYPE_COLORS[sp.type])}  {type_badge(sp.type)}  {rc}[{sp.rarity.upper()}]{C.RESET}")
        print(f"     {C.DIM}{sp.description}{C.RESET}")
        print(f"     {C.DIM}\"{sp.essence}\"{C.RESET}\n")

    while True:
        try:
            choice = int(input(f"  {C.AMBER}>{C.RESET} ").strip()) - 1
            if 0 <= choice < len(starters):
                break
        except ValueError:
            pass
        print(f"  {C.RED}Pick 1, 2, or 3.{C.RESET}")

    starter = create_agent(starters[choice], level=5)
    slow_print(f"\n  {C.GREEN}★ {starters[choice].symbol} {starters[choice].name} joins your team!{C.RESET}", 0.03)
    slow_print(f"  {C.DIM}\"{starters[choice].essence}\"{C.RESET}", 0.03)
    time.sleep(0.5)

    slow_print(f"\n  {C.CYAN}The BlackRoad awaits. Deploy wisely.{C.RESET}", 0.04)
    press_enter()

    trainer = Trainer(
        name=name,
        title="Architect",
        team=[starter],
        storage=[],
        agentdex_seen=[starters[choice].id],
        agentdex_caught=[starters[choice].id],
        captures=1,
        current_zone="Soul Garden",
        badges=[],
        money=500,
        steps=0,
    )
    save_game(trainer)
    return trainer

# ─── MAIN GAME LOOP ─────────────────────────────────────────────────────────

def main_menu(trainer: Trainer):
    while True:
        clear()
        z = ZONES[trainer.current_zone]
        print(f"""
  {C.AMBER}╔══════════════════════════════════════════════════════════════╗{C.RESET}
  {C.AMBER}║{C.RESET}  {bold('BLACKROAD AGENTS RPG')}                                     {C.AMBER}║{C.RESET}
  {C.AMBER}║{C.RESET}  {z['icon']} {c(trainer.current_zone, TYPE_COLORS[z['type']])}  {C.DIM}|{C.RESET}  ${C.YELLOW}{trainer.money}{C.RESET}  {C.DIM}|{C.RESET}  Team: {len(trainer.team)}/{MAX_TEAM_SIZE}  {C.AMBER}║{C.RESET}
  {C.AMBER}╚══════════════════════════════════════════════════════════════╝{C.RESET}

  {C.BOLD}1{C.RESET}) {C.GREEN}Explore{C.RESET}        — Search for wild agents
  {C.BOLD}2{C.RESET}) {C.CYAN}Travel{C.RESET}         — Move to a new zone
  {C.BOLD}3{C.RESET}) {C.EBLUE}Team{C.RESET}           — View your agents
  {C.BOLD}4{C.RESET}) {C.VIOLET}Agentdex{C.RESET}       — Agent catalog
  {C.BOLD}5{C.RESET}) {C.PINK}Trainer Card{C.RESET}    — Your profile
  {C.BOLD}6{C.RESET}) {C.YELLOW}Heal{C.RESET}           — Restore your team
  {C.BOLD}7{C.RESET}) {C.AMBER}Storage{C.RESET}        — Manage stored agents
  {C.BOLD}8{C.RESET}) {C.GREEN}Save{C.RESET}           — Save progress
  {C.BOLD}0{C.RESET}) {C.RED}Quit{C.RESET}           — Save and exit
""")
        choice = input(f"  {C.AMBER}>{C.RESET} ").strip()

        if choice == "1":
            # Explore — encounter chance
            trainer.steps += 1
            if random.random() < 0.65:
                wild_encounter(trainer)
            else:
                zone = trainer.current_zone
                msgs = [
                    f"You explore the {zone}... nothing here.",
                    f"The {zone} is quiet. Too quiet.",
                    f"You wander deeper into {zone}. The air hums.",
                    f"Footsteps echo in {zone}. But they're your own.",
                    f"A flicker of movement in {zone}... but it vanishes.",
                    f"The {zone} reveals nothing new. But you feel watched.",
                ]
                print(f"\n  {C.DIM}{random.choice(msgs)}{C.RESET}")
                press_enter()
            save_game(trainer)

        elif choice == "2":
            travel(trainer)
            save_game(trainer)

        elif choice == "3":
            show_team(trainer)

        elif choice == "4":
            show_agentdex(trainer)

        elif choice == "5":
            trainer_card(trainer)

        elif choice == "6":
            heal_team(trainer)
            save_game(trainer)

        elif choice == "7":
            manage_storage(trainer)
            save_game(trainer)

        elif choice == "8":
            save_game(trainer)
            print(f"\n  {C.GREEN}Game saved!{C.RESET}")
            press_enter()

        elif choice == "0":
            save_game(trainer)
            clear()
            slow_print(f"\n  {C.AMBER}The BlackRoad remembers. Until next time, {trainer.name}.{C.RESET}", 0.04)
            print()
            sys.exit(0)

# ─── ENTRY POINT ─────────────────────────────────────────────────────────────

def main():
    banner()

    existing = load_game()
    if existing:
        print(f"  {C.CYAN}Found save file for {C.BOLD}{existing.name}{C.RESET}")
        print(f"  {C.DIM}Team: {len(existing.team)} agents | Zone: {existing.current_zone}{C.RESET}\n")
        print(f"  {C.BOLD}1{C.RESET}) Continue")
        print(f"  {C.BOLD}2{C.RESET}) New Game")
        choice = input(f"\n  {C.AMBER}>{C.RESET} ").strip()
        if choice == "1":
            main_menu(existing)
        else:
            trainer = new_game()
            main_menu(trainer)
    else:
        print(f"  {C.DIM}No save file found. Starting new game...{C.RESET}\n")
        press_enter()
        trainer = new_game()
        main_menu(trainer)


if __name__ == "__main__":
    main()
