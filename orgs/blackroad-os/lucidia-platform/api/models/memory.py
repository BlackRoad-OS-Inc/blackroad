"""
Lucidia Memory System - 2048-Style Knowledge Grid
Knowledge tiles combine and merge to form deeper understanding!

The memory works like 2048:
- New knowledge enters as small tiles (2, 4)
- Related concepts merge when they collide (2+2=4, 4+4=8...)
- Higher tiles = deeper mastery of concepts
- Grid fills up = time to consolidate knowledge
- Goal: reach 2048 (full mastery) in different subjects!

Tile Values & Meanings:
- 2: First exposure (heard of it)
- 4: Basic awareness (can recognize)
- 8: Familiarity (understand basics)
- 16: Comprehension (can explain simply)
- 32: Understanding (can apply)
- 64: Proficiency (can solve problems)
- 128: Competence (can teach others)
- 256: Expertise (deep knowledge)
- 512: Mastery (can innovate)
- 1024: Excellence (field expert)
- 2048: Genius (pioneering understanding)
- 4096+: Transcendence (creating new knowledge)
"""

from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any, Tuple
from enum import Enum
from datetime import datetime
import random


class KnowledgeDomain(str, Enum):
    """Major knowledge domains"""
    # STEM
    MATHEMATICS = "mathematics"
    PHYSICS = "physics"
    CHEMISTRY = "chemistry"
    BIOLOGY = "biology"
    COMPUTER_SCIENCE = "computer-science"
    ENGINEERING = "engineering"

    # Programming
    PYTHON = "python"
    JAVASCRIPT = "javascript"
    RUST = "rust"
    GO = "go"
    JAVA = "java"
    CPP = "cpp"

    # Concepts
    ALGORITHMS = "algorithms"
    DATA_STRUCTURES = "data-structures"
    DESIGN_PATTERNS = "design-patterns"
    SYSTEM_DESIGN = "system-design"
    DATABASES = "databases"
    NETWORKING = "networking"
    SECURITY = "security"

    # Soft Skills
    PROBLEM_SOLVING = "problem-solving"
    COMMUNICATION = "communication"
    CRITICAL_THINKING = "critical-thinking"

    # Arts & Humanities
    WRITING = "writing"
    MUSIC = "music"
    ART = "art"
    HISTORY = "history"
    PHILOSOPHY = "philosophy"
    LANGUAGES = "languages"


class MasteryLevel(str, Enum):
    """Mastery levels corresponding to tile values"""
    EXPOSURE = "exposure"           # 2
    AWARENESS = "awareness"         # 4
    FAMILIARITY = "familiarity"     # 8
    COMPREHENSION = "comprehension" # 16
    UNDERSTANDING = "understanding" # 32
    PROFICIENCY = "proficiency"     # 64
    COMPETENCE = "competence"       # 128
    EXPERTISE = "expertise"         # 256
    MASTERY = "mastery"             # 512
    EXCELLENCE = "excellence"       # 1024
    GENIUS = "genius"               # 2048
    TRANSCENDENCE = "transcendence" # 4096+


# Tile value to mastery level mapping
TILE_TO_MASTERY = {
    2: MasteryLevel.EXPOSURE,
    4: MasteryLevel.AWARENESS,
    8: MasteryLevel.FAMILIARITY,
    16: MasteryLevel.COMPREHENSION,
    32: MasteryLevel.UNDERSTANDING,
    64: MasteryLevel.PROFICIENCY,
    128: MasteryLevel.COMPETENCE,
    256: MasteryLevel.EXPERTISE,
    512: MasteryLevel.MASTERY,
    1024: MasteryLevel.EXCELLENCE,
    2048: MasteryLevel.GENIUS,
    4096: MasteryLevel.TRANSCENDENCE,
}

MASTERY_DESCRIPTIONS = {
    MasteryLevel.EXPOSURE: "You've heard of this concept",
    MasteryLevel.AWARENESS: "You can recognize it when you see it",
    MasteryLevel.FAMILIARITY: "You understand the basics",
    MasteryLevel.COMPREHENSION: "You can explain it simply",
    MasteryLevel.UNDERSTANDING: "You can apply it to problems",
    MasteryLevel.PROFICIENCY: "You can solve complex problems",
    MasteryLevel.COMPETENCE: "You can teach this to others",
    MasteryLevel.EXPERTISE: "You have deep, nuanced knowledge",
    MasteryLevel.MASTERY: "You can innovate and create",
    MasteryLevel.EXCELLENCE: "You're a recognized expert",
    MasteryLevel.GENIUS: "You're pushing the boundaries",
    MasteryLevel.TRANSCENDENCE: "You're creating new knowledge",
}


class MemoryTile(BaseModel):
    """A single knowledge tile in the memory grid"""
    id: str
    value: int  # 2, 4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048, 4096...
    concept: str  # What this tile represents
    domain: KnowledgeDomain
    position: Tuple[int, int]  # (row, col) in grid
    created_at: datetime = Field(default_factory=datetime.utcnow)
    last_merged: Optional[datetime] = None
    merge_count: int = 0  # How many times this tile has been merged
    source_concepts: List[str] = []  # Concepts that merged into this

    @property
    def mastery_level(self) -> MasteryLevel:
        """Get the mastery level for this tile's value"""
        for val, level in sorted(TILE_TO_MASTERY.items(), reverse=True):
            if self.value >= val:
                return level
        return MasteryLevel.EXPOSURE

    @property
    def color(self) -> str:
        """Get the tile color based on value"""
        colors = {
            2: "#eee4da",      # Cream
            4: "#ede0c8",      # Light tan
            8: "#f2b179",      # Orange
            16: "#f59563",     # Dark orange
            32: "#f67c5f",     # Red-orange
            64: "#f65e3b",     # Red
            128: "#edcf72",    # Yellow
            256: "#edcc61",    # Gold
            512: "#edc850",    # Bright gold
            1024: "#edc53f",   # Golden
            2048: "#edc22e",   # Pure gold
            4096: "#3c3a32",   # Dark (transcendence)
        }
        return colors.get(self.value, "#3c3a32")


class MemoryGrid(BaseModel):
    """The 2048-style memory grid"""
    user_id: str
    domain: KnowledgeDomain
    size: int = 4  # 4x4 grid by default
    tiles: List[MemoryTile] = []
    score: int = 0
    highest_tile: int = 0
    moves: int = 0
    created_at: datetime = Field(default_factory=datetime.utcnow)
    last_move: Optional[datetime] = None
    game_over: bool = False
    won: bool = False  # True when 2048 tile is reached

    @property
    def grid_array(self) -> List[List[Optional[MemoryTile]]]:
        """Get the grid as a 2D array"""
        grid = [[None for _ in range(self.size)] for _ in range(self.size)]
        for tile in self.tiles:
            row, col = tile.position
            if 0 <= row < self.size and 0 <= col < self.size:
                grid[row][col] = tile
        return grid

    @property
    def empty_cells(self) -> List[Tuple[int, int]]:
        """Get list of empty cell positions"""
        occupied = {tile.position for tile in self.tiles}
        empty = []
        for r in range(self.size):
            for c in range(self.size):
                if (r, c) not in occupied:
                    empty.append((r, c))
        return empty

    @property
    def is_full(self) -> bool:
        """Check if grid is full"""
        return len(self.tiles) >= self.size * self.size

    @property
    def total_knowledge(self) -> int:
        """Sum of all tile values"""
        return sum(tile.value for tile in self.tiles)

    @property
    def average_mastery(self) -> float:
        """Average tile value"""
        if not self.tiles:
            return 0
        return self.total_knowledge / len(self.tiles)


class MergeEvent(BaseModel):
    """Record of a tile merge"""
    id: str
    user_id: str
    domain: KnowledgeDomain
    tile1_concept: str
    tile2_concept: str
    tile1_value: int
    tile2_value: int
    result_concept: str
    result_value: int
    position: Tuple[int, int]
    timestamp: datetime = Field(default_factory=datetime.utcnow)
    insight: Optional[str] = None  # AI-generated insight about the merge


class MoveDirection(str, Enum):
    """Directions for moving tiles"""
    UP = "up"
    DOWN = "down"
    LEFT = "left"
    RIGHT = "right"


class LearnEvent(BaseModel):
    """Event when user learns something new"""
    concept: str
    domain: KnowledgeDomain
    context: Optional[str] = None
    source: Optional[str] = None  # problem, lesson, practice, etc.
    initial_value: int = 2  # Usually starts at 2


class MemoryStats(BaseModel):
    """Statistics about a user's memory"""
    user_id: str
    total_domains: int
    total_tiles: int
    total_score: int
    highest_tile_ever: int
    highest_tile_domain: Optional[KnowledgeDomain] = None
    total_merges: int
    domains_with_2048: List[KnowledgeDomain] = []
    strongest_domain: Optional[KnowledgeDomain] = None
    weakest_domain: Optional[KnowledgeDomain] = None
    learning_streak: int = 0
    last_learned: Optional[datetime] = None


class MemoryGridRequest(BaseModel):
    """Request to get or create a memory grid"""
    user_id: str
    domain: KnowledgeDomain
    grid_size: int = 4


class MoveRequest(BaseModel):
    """Request to move tiles in a direction"""
    user_id: str
    domain: KnowledgeDomain
    direction: MoveDirection


class LearnRequest(BaseModel):
    """Request to add new knowledge"""
    user_id: str
    concept: str
    domain: KnowledgeDomain
    context: Optional[str] = None
    source: Optional[str] = None


class MemoryResponse(BaseModel):
    """Response with memory grid state"""
    grid: MemoryGrid
    merged_tiles: List[MergeEvent] = []
    new_tile: Optional[MemoryTile] = None
    game_over: bool = False
    won: bool = False
    insight: Optional[str] = None  # AI insight about the learning


# ═══════════════════════════════════════════════════════════════════════════════
# CONCEPT RELATIONSHIPS - What concepts can merge
# ═══════════════════════════════════════════════════════════════════════════════

CONCEPT_FAMILIES = {
    KnowledgeDomain.PYTHON: {
        "variables": ["types", "assignment", "scope", "naming"],
        "functions": ["parameters", "return", "lambda", "decorators", "generators"],
        "classes": ["objects", "inheritance", "methods", "properties", "magic-methods"],
        "data-structures": ["lists", "dicts", "sets", "tuples", "collections"],
        "control-flow": ["if-else", "loops", "comprehensions", "exceptions"],
        "modules": ["imports", "packages", "pip", "virtual-environments"],
        "async": ["coroutines", "await", "asyncio", "concurrency"],
    },
    KnowledgeDomain.JAVASCRIPT: {
        "variables": ["let", "const", "var", "hoisting", "scope"],
        "functions": ["arrow-functions", "callbacks", "closures", "this"],
        "objects": ["prototypes", "classes", "destructuring", "spread"],
        "async": ["promises", "async-await", "fetch", "event-loop"],
        "dom": ["selectors", "events", "manipulation", "forms"],
        "modern": ["modules", "es6+", "typescript", "jsx"],
    },
    KnowledgeDomain.ALGORITHMS: {
        "sorting": ["bubble", "merge", "quick", "heap", "radix"],
        "searching": ["binary", "linear", "dfs", "bfs", "dijkstra"],
        "dynamic-programming": ["memoization", "tabulation", "optimal-substructure"],
        "graphs": ["traversal", "shortest-path", "spanning-tree", "topological"],
        "trees": ["binary-tree", "bst", "avl", "red-black", "trie"],
    },
    KnowledgeDomain.MATHEMATICS: {
        "algebra": ["equations", "inequalities", "polynomials", "factoring"],
        "calculus": ["derivatives", "integrals", "limits", "series"],
        "geometry": ["shapes", "angles", "area", "volume", "trigonometry"],
        "statistics": ["mean", "median", "variance", "probability", "distributions"],
        "linear-algebra": ["vectors", "matrices", "eigenvalues", "transformations"],
    },
}


def get_merged_concept(concept1: str, concept2: str, domain: KnowledgeDomain) -> str:
    """
    Generate a merged concept name when two tiles combine.
    Returns a higher-level concept that encompasses both.
    """
    families = CONCEPT_FAMILIES.get(domain, {})

    # Find if concepts belong to same family
    for family_name, concepts in families.items():
        if concept1 in concepts and concept2 in concepts:
            # Same family - create combined concept
            return f"{family_name}:{concept1}+{concept2}"
        if concept1 == family_name or concept2 == family_name:
            # Merging with family root
            return f"{family_name}:advanced"

    # Different families or unknown - create synthesis
    return f"{concept1}↔{concept2}"


def generate_merge_insight(tile1: MemoryTile, tile2: MemoryTile, result: MemoryTile) -> str:
    """Generate an AI insight about the merge"""
    insights = [
        f"🧠 {tile1.concept} + {tile2.concept} = deeper understanding of {result.concept}!",
        f"⚡ Knowledge fusion! Your {tile1.concept} skills combined with {tile2.concept}.",
        f"🎯 Level up! You now have {result.mastery_level.value} in {result.concept}.",
        f"🔥 Nice merge! {result.value} points of knowledge in {result.domain.value}.",
        f"✨ Synthesis complete: {result.concept} ({MASTERY_DESCRIPTIONS[result.mastery_level]})",
    ]
    return random.choice(insights)
