"""
Lucidia Memory Router - 2048-Style Knowledge Grid API
Endpoints for the gamified memory system

Play 2048 with your knowledge!
- Swipe to move tiles
- Merge matching concepts
- Level up your understanding
- Reach 2048 for mastery!
"""

from fastapi import APIRouter, HTTPException
from typing import List, Dict, Any, Optional

from models.memory import (
    MemoryGrid, MemoryTile, MergeEvent, MemoryStats,
    KnowledgeDomain, MoveDirection, MasteryLevel,
    MemoryGridRequest, MoveRequest, LearnRequest, MemoryResponse,
    TILE_TO_MASTERY, MASTERY_DESCRIPTIONS,
)
from services.memory_engine import memory_engine

router = APIRouter(prefix="/api/v1/memory", tags=["memory"])


# ═══════════════════════════════════════════════════════════════════════════════
# GRID MANAGEMENT
# ═══════════════════════════════════════════════════════════════════════════════

@router.get("/grid/{user_id}/{domain}", response_model=Dict[str, Any])
async def get_memory_grid(user_id: str, domain: KnowledgeDomain):
    """
    Get the user's memory grid for a specific domain.
    Creates a new grid if one doesn't exist.

    The grid is a 4x4 board (like 2048) where:
    - Each tile represents knowledge of a concept
    - Tile values: 2, 4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048+
    - Higher values = deeper understanding
    """
    grid = memory_engine.get_or_create_grid(user_id, domain)

    return {
        "grid": _serialize_grid(grid),
        "ascii_view": memory_engine.render_grid_ascii(grid),
        "stats": {
            "score": grid.score,
            "highest_tile": grid.highest_tile,
            "moves": grid.moves,
            "tile_count": len(grid.tiles),
            "total_knowledge": grid.total_knowledge,
            "average_mastery": grid.average_mastery,
        },
        "status": {
            "game_over": grid.game_over,
            "won": grid.won,
            "can_move": not grid.game_over,
        }
    }


@router.get("/grids/{user_id}", response_model=Dict[str, Any])
async def get_all_grids(user_id: str):
    """Get all memory grids for a user across all domains"""
    grids = memory_engine.get_all_grids(user_id)

    return {
        "user_id": user_id,
        "total_domains": len(grids),
        "grids": {
            domain.value: _serialize_grid(grid)
            for domain, grid in grids.items()
        },
        "summary": {
            "total_score": sum(g.score for g in grids.values()),
            "highest_tile": max((g.highest_tile for g in grids.values()), default=0),
            "total_tiles": sum(len(g.tiles) for g in grids.values()),
            "domains_mastered": [
                domain.value for domain, grid in grids.items()
                if grid.won
            ],
        }
    }


@router.post("/grid/reset/{user_id}/{domain}", response_model=Dict[str, Any])
async def reset_grid(user_id: str, domain: KnowledgeDomain):
    """Reset a memory grid (start fresh)"""
    grid = memory_engine.reset_grid(user_id, domain)

    return {
        "message": f"Grid reset for {domain.value}",
        "grid": _serialize_grid(grid),
        "ascii_view": memory_engine.render_grid_ascii(grid),
    }


# ═══════════════════════════════════════════════════════════════════════════════
# GAME MOVES
# ═══════════════════════════════════════════════════════════════════════════════

@router.post("/move", response_model=Dict[str, Any])
async def move_tiles(request: MoveRequest):
    """
    Move all tiles in a direction (like swiping in 2048).

    Directions: up, down, left, right

    When tiles of the same value collide, they merge!
    - 2 + 2 = 4 (Basic awareness)
    - 4 + 4 = 8 (Familiarity)
    - 8 + 8 = 16 (Comprehension)
    - ... up to 2048 (Genius level!)
    """
    grid, merge_events, new_tile = memory_engine.move(
        request.user_id,
        request.domain,
        request.direction
    )

    response = {
        "grid": _serialize_grid(grid),
        "ascii_view": memory_engine.render_grid_ascii(grid),
        "move": {
            "direction": request.direction.value,
            "merged_count": len(merge_events),
        },
        "merges": [
            {
                "from": [e.tile1_concept, e.tile2_concept],
                "to": e.result_concept,
                "value": e.result_value,
                "insight": e.insight,
            }
            for e in merge_events
        ],
        "new_tile": _serialize_tile(new_tile) if new_tile else None,
        "stats": {
            "score": grid.score,
            "highest_tile": grid.highest_tile,
            "moves": grid.moves,
        },
        "status": {
            "game_over": grid.game_over,
            "won": grid.won,
        }
    }

    # Add celebration messages
    if grid.won and not any(t.value >= 4096 for t in grid.tiles):
        response["celebration"] = "🎉 CONGRATULATIONS! You reached 2048 - GENIUS LEVEL! 🧠✨"
    elif merge_events:
        highest_merge = max(e.result_value for e in merge_events)
        if highest_merge >= 512:
            response["celebration"] = f"🔥 MASTERY MERGE! {highest_merge} points!"
        elif highest_merge >= 128:
            response["celebration"] = f"⚡ Great merge! {highest_merge} knowledge combined!"

    if grid.game_over:
        response["message"] = "Game Over! No more moves available. Reset to try again."

    return response


@router.post("/move/{user_id}/{domain}/{direction}", response_model=Dict[str, Any])
async def move_tiles_simple(
    user_id: str,
    domain: KnowledgeDomain,
    direction: MoveDirection
):
    """Simple path-based move endpoint"""
    request = MoveRequest(user_id=user_id, domain=domain, direction=direction)
    return await move_tiles(request)


# ═══════════════════════════════════════════════════════════════════════════════
# LEARNING (Adding Knowledge)
# ═══════════════════════════════════════════════════════════════════════════════

@router.post("/learn", response_model=Dict[str, Any])
async def learn_concept(request: LearnRequest):
    """
    Learn a new concept! Adds a knowledge tile to your grid.

    When you learn something new, a tile appears on your grid.
    Study and practice to merge tiles and level up your understanding!
    """
    grid, tile = memory_engine.learn(
        request.user_id,
        request.concept,
        request.domain,
        value=2  # New knowledge starts at level 2
    )

    return {
        "message": f"New knowledge acquired: {request.concept}!",
        "new_tile": _serialize_tile(tile),
        "grid": _serialize_grid(grid),
        "ascii_view": memory_engine.render_grid_ascii(grid),
        "tip": "Swipe to move tiles. Match concepts to merge and level up!",
    }


@router.post("/study/{user_id}/{domain}/{concept}", response_model=Dict[str, Any])
async def study_concept(user_id: str, domain: KnowledgeDomain, concept: str):
    """
    Study a concept to add it to your knowledge grid.
    Alias for /learn endpoint with simpler path.
    """
    request = LearnRequest(user_id=user_id, concept=concept, domain=domain)
    return await learn_concept(request)


# ═══════════════════════════════════════════════════════════════════════════════
# STATISTICS & PROGRESS
# ═══════════════════════════════════════════════════════════════════════════════

@router.get("/stats/{user_id}", response_model=Dict[str, Any])
async def get_memory_stats(user_id: str):
    """
    Get comprehensive statistics about a user's memory/learning.

    Tracks:
    - Total knowledge across all domains
    - Highest tiles achieved
    - Domains mastered (reached 2048)
    - Learning streaks
    """
    stats = memory_engine.get_stats(user_id)
    grids = memory_engine.get_all_grids(user_id)

    # Calculate domain-specific progress
    domain_progress = {}
    for domain, grid in grids.items():
        mastery = _get_mastery_level(grid.highest_tile)
        domain_progress[domain.value] = {
            "highest_tile": grid.highest_tile,
            "mastery_level": mastery.value,
            "mastery_description": MASTERY_DESCRIPTIONS.get(mastery, ""),
            "score": grid.score,
            "tiles": len(grid.tiles),
            "won": grid.won,
        }

    return {
        "user_id": user_id,
        "overview": {
            "total_domains": stats.total_domains,
            "total_tiles": stats.total_tiles,
            "total_score": stats.total_score,
            "total_merges": stats.total_merges,
            "highest_tile_ever": stats.highest_tile_ever,
            "highest_tile_domain": stats.highest_tile_domain.value if stats.highest_tile_domain else None,
            "domains_mastered": [d.value for d in stats.domains_with_2048],
        },
        "domains": domain_progress,
        "achievements": _get_achievements(stats, grids),
        "next_goals": _get_next_goals(stats, grids),
    }


@router.get("/leaderboard/{domain}", response_model=List[Dict[str, Any]])
async def get_leaderboard(domain: KnowledgeDomain, limit: int = 10):
    """
    Get the leaderboard for a specific domain.
    Shows top players by highest tile and score.
    """
    # In production, query database
    # For now, return sample data
    return [
        {
            "rank": 1,
            "user_id": "sample_user",
            "highest_tile": 2048,
            "score": 50000,
            "mastery_level": "genius",
        }
    ]


# ═══════════════════════════════════════════════════════════════════════════════
# REFERENCE DATA
# ═══════════════════════════════════════════════════════════════════════════════

@router.get("/domains", response_model=List[Dict[str, str]])
async def get_knowledge_domains():
    """Get all available knowledge domains"""
    return [
        {"value": domain.value, "name": domain.value.replace("-", " ").title()}
        for domain in KnowledgeDomain
    ]


@router.get("/mastery-levels", response_model=List[Dict[str, Any]])
async def get_mastery_levels():
    """
    Get all mastery levels and their meanings.

    Tile Value -> Mastery Level:
    - 2: Exposure (heard of it)
    - 4: Awareness (can recognize)
    - 8: Familiarity (understand basics)
    - 16: Comprehension (can explain)
    - 32: Understanding (can apply)
    - 64: Proficiency (solve problems)
    - 128: Competence (teach others)
    - 256: Expertise (deep knowledge)
    - 512: Mastery (can innovate)
    - 1024: Excellence (field expert)
    - 2048: Genius (pioneering)
    - 4096+: Transcendence (creating new knowledge)
    """
    return [
        {
            "tile_value": value,
            "level": level.value,
            "description": MASTERY_DESCRIPTIONS.get(level, ""),
            "color": _get_tile_color(value),
        }
        for value, level in sorted(TILE_TO_MASTERY.items())
    ]


@router.get("/how-to-play", response_model=Dict[str, Any])
async def get_how_to_play():
    """Get instructions for the 2048 memory game"""
    return {
        "title": "Lucidia Memory - 2048 for Your Brain! 🧠",
        "description": "A gamified way to track and grow your knowledge",
        "rules": [
            "1. Learn new concepts to add tiles to your grid",
            "2. Swipe (up/down/left/right) to move all tiles",
            "3. When two tiles of the same value touch, they MERGE!",
            "4. Merged tiles double in value (2+2=4, 4+4=8, etc.)",
            "5. Reach 2048 to achieve GENIUS level mastery!",
            "6. Don't let the grid fill up - keep merging!",
        ],
        "tile_meanings": {
            "2": "First Exposure - You've heard of this",
            "4": "Awareness - You can recognize it",
            "8": "Familiarity - You understand the basics",
            "16": "Comprehension - You can explain it",
            "32": "Understanding - You can apply it",
            "64": "Proficiency - You can solve problems",
            "128": "Competence - You can teach others",
            "256": "Expertise - Deep, nuanced knowledge",
            "512": "Mastery - You can innovate",
            "1024": "Excellence - Recognized expert",
            "2048": "GENIUS - Pioneering understanding!",
        },
        "tips": [
            "🎯 Focus on one domain at a time",
            "🔄 Practice regularly to generate new tiles",
            "🧩 Related concepts merge more easily",
            "📈 Build towards corners for bigger merges",
            "🏆 Track your progress across all domains",
        ],
        "endpoints": {
            "get_grid": "GET /api/v1/memory/grid/{user_id}/{domain}",
            "move": "POST /api/v1/memory/move/{user_id}/{domain}/{direction}",
            "learn": "POST /api/v1/memory/study/{user_id}/{domain}/{concept}",
            "stats": "GET /api/v1/memory/stats/{user_id}",
        }
    }


# ═══════════════════════════════════════════════════════════════════════════════
# HELPER FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════════

def _serialize_grid(grid: MemoryGrid) -> Dict[str, Any]:
    """Convert grid to JSON-serializable dict"""
    return {
        "user_id": grid.user_id,
        "domain": grid.domain.value,
        "size": grid.size,
        "tiles": [_serialize_tile(t) for t in grid.tiles],
        "score": grid.score,
        "highest_tile": grid.highest_tile,
        "moves": grid.moves,
        "game_over": grid.game_over,
        "won": grid.won,
        "created_at": grid.created_at.isoformat(),
        "last_move": grid.last_move.isoformat() if grid.last_move else None,
    }


def _serialize_tile(tile: Optional[MemoryTile]) -> Optional[Dict[str, Any]]:
    """Convert tile to JSON-serializable dict"""
    if not tile:
        return None

    return {
        "id": tile.id,
        "value": tile.value,
        "concept": tile.concept,
        "position": {"row": tile.position[0], "col": tile.position[1]},
        "mastery_level": tile.mastery_level.value,
        "color": tile.color,
        "merge_count": tile.merge_count,
    }


def _get_mastery_level(value: int) -> MasteryLevel:
    """Get mastery level for a tile value"""
    for val, level in sorted(TILE_TO_MASTERY.items(), reverse=True):
        if value >= val:
            return level
    return MasteryLevel.EXPOSURE


def _get_tile_color(value: int) -> str:
    """Get tile color for a value"""
    colors = {
        2: "#eee4da", 4: "#ede0c8", 8: "#f2b179", 16: "#f59563",
        32: "#f67c5f", 64: "#f65e3b", 128: "#edcf72", 256: "#edcc61",
        512: "#edc850", 1024: "#edc53f", 2048: "#edc22e", 4096: "#3c3a32",
    }
    return colors.get(value, "#3c3a32")


def _get_achievements(stats: MemoryStats, grids: Dict) -> List[Dict[str, Any]]:
    """Calculate achievements based on stats"""
    achievements = []

    if stats.total_merges >= 1:
        achievements.append({"name": "First Merge", "emoji": "🔗", "description": "Merged your first tiles!"})
    if stats.total_merges >= 100:
        achievements.append({"name": "Merger Master", "emoji": "⚡", "description": "100 total merges!"})
    if stats.highest_tile_ever >= 128:
        achievements.append({"name": "Competent", "emoji": "📚", "description": "Reached 128 tile!"})
    if stats.highest_tile_ever >= 512:
        achievements.append({"name": "Master", "emoji": "🎓", "description": "Reached 512 tile!"})
    if stats.highest_tile_ever >= 2048:
        achievements.append({"name": "Genius", "emoji": "🧠", "description": "Reached 2048 - GENIUS LEVEL!"})
    if len(stats.domains_with_2048) >= 3:
        achievements.append({"name": "Polymath", "emoji": "🌟", "description": "Mastered 3+ domains!"})
    if stats.total_domains >= 5:
        achievements.append({"name": "Explorer", "emoji": "🗺️", "description": "Learning in 5+ domains!"})

    return achievements


def _get_next_goals(stats: MemoryStats, grids: Dict) -> List[Dict[str, Any]]:
    """Calculate next goals for the user"""
    goals = []

    if stats.highest_tile_ever < 2048:
        next_tile = 2048
        for val in [128, 256, 512, 1024, 2048]:
            if stats.highest_tile_ever < val:
                next_tile = val
                break
        goals.append({
            "goal": f"Reach {next_tile} tile",
            "current": stats.highest_tile_ever,
            "target": next_tile,
            "progress": round(stats.highest_tile_ever / next_tile * 100),
        })

    if len(stats.domains_with_2048) < 3:
        goals.append({
            "goal": "Master 3 domains (reach 2048)",
            "current": len(stats.domains_with_2048),
            "target": 3,
            "progress": round(len(stats.domains_with_2048) / 3 * 100),
        })

    return goals
