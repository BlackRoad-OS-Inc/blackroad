"""
Lucidia Memory Engine - 2048-Style Knowledge Grid
The core game engine for the memory system

Like 2048, but for your brain:
- Swipe to move knowledge tiles
- Matching concepts merge and level up
- Reach 2048 to achieve mastery!
- Keep learning to avoid game over
"""

import uuid
import random
from typing import Dict, List, Optional, Tuple
from datetime import datetime
from copy import deepcopy

from models.memory import (
    MemoryTile, MemoryGrid, MergeEvent, MoveDirection, LearnEvent,
    MemoryStats, KnowledgeDomain, MasteryLevel,
    get_merged_concept, generate_merge_insight,
    TILE_TO_MASTERY, MASTERY_DESCRIPTIONS,
)


class MemoryEngine:
    """
    The 2048-style memory game engine.
    Manages knowledge grids, tile movements, and merges.
    """

    def __init__(self):
        # In-memory storage (replace with database in production)
        self.grids: Dict[str, Dict[KnowledgeDomain, MemoryGrid]] = {}
        self.stats: Dict[str, MemoryStats] = {}
        self.merge_history: List[MergeEvent] = []

    def _get_grid_key(self, user_id: str, domain: KnowledgeDomain) -> str:
        """Generate a unique key for a user's domain grid"""
        return f"{user_id}:{domain.value}"

    def get_or_create_grid(
        self,
        user_id: str,
        domain: KnowledgeDomain,
        size: int = 4
    ) -> MemoryGrid:
        """Get existing grid or create a new one"""
        if user_id not in self.grids:
            self.grids[user_id] = {}

        if domain not in self.grids[user_id]:
            # Create new grid with 2 starting tiles
            grid = MemoryGrid(
                user_id=user_id,
                domain=domain,
                size=size,
                tiles=[],
                score=0,
            )
            # Add 2 initial tiles
            self._add_random_tile(grid)
            self._add_random_tile(grid)
            self.grids[user_id][domain] = grid

        return self.grids[user_id][domain]

    def _add_random_tile(
        self,
        grid: MemoryGrid,
        concept: Optional[str] = None,
        value: Optional[int] = None
    ) -> Optional[MemoryTile]:
        """Add a random tile to an empty cell"""
        empty_cells = grid.empty_cells
        if not empty_cells:
            return None

        position = random.choice(empty_cells)

        # Value: 90% chance of 2, 10% chance of 4
        if value is None:
            value = 2 if random.random() < 0.9 else 4

        # Generate concept name if not provided
        if concept is None:
            concept = self._generate_concept_name(grid.domain, value)

        tile = MemoryTile(
            id=str(uuid.uuid4()),
            value=value,
            concept=concept,
            domain=grid.domain,
            position=position,
        )

        grid.tiles.append(tile)

        # Update highest tile
        if value > grid.highest_tile:
            grid.highest_tile = value

        return tile

    def _generate_concept_name(self, domain: KnowledgeDomain, value: int) -> str:
        """Generate a concept name based on domain and value"""
        concepts = {
            KnowledgeDomain.PYTHON: [
                "variables", "strings", "lists", "dicts", "loops", "functions",
                "classes", "imports", "exceptions", "decorators", "generators",
                "comprehensions", "lambda", "async", "typing", "dataclasses"
            ],
            KnowledgeDomain.JAVASCRIPT: [
                "variables", "functions", "objects", "arrays", "promises",
                "async-await", "dom", "events", "classes", "modules",
                "closures", "prototypes", "this", "arrow-functions", "spread"
            ],
            KnowledgeDomain.ALGORITHMS: [
                "big-o", "arrays", "sorting", "searching", "recursion",
                "trees", "graphs", "dp", "greedy", "backtracking",
                "binary-search", "two-pointers", "sliding-window", "hash-maps"
            ],
            KnowledgeDomain.MATHEMATICS: [
                "algebra", "equations", "functions", "graphs", "calculus",
                "derivatives", "integrals", "limits", "geometry", "trigonometry",
                "statistics", "probability", "matrices", "vectors"
            ],
            KnowledgeDomain.DATA_STRUCTURES: [
                "arrays", "linked-lists", "stacks", "queues", "trees",
                "heaps", "hash-tables", "graphs", "tries", "sets"
            ],
        }

        domain_concepts = concepts.get(domain, ["concept"])
        base_concept = random.choice(domain_concepts)

        # Add level indicator based on value
        if value <= 4:
            return f"{base_concept}:basics"
        elif value <= 16:
            return f"{base_concept}:intermediate"
        elif value <= 64:
            return f"{base_concept}:advanced"
        else:
            return f"{base_concept}:expert"

    def move(
        self,
        user_id: str,
        domain: KnowledgeDomain,
        direction: MoveDirection
    ) -> Tuple[MemoryGrid, List[MergeEvent], Optional[MemoryTile]]:
        """
        Move all tiles in the specified direction.
        Returns: (updated_grid, merge_events, new_tile)
        """
        grid = self.get_or_create_grid(user_id, domain)

        if grid.game_over:
            return grid, [], None

        # Store original state to check if anything moved
        original_positions = {tile.id: tile.position for tile in grid.tiles}
        original_values = {tile.id: tile.value for tile in grid.tiles}

        merge_events = []

        # Process movement based on direction
        if direction == MoveDirection.LEFT:
            merge_events = self._move_left(grid)
        elif direction == MoveDirection.RIGHT:
            merge_events = self._move_right(grid)
        elif direction == MoveDirection.UP:
            merge_events = self._move_up(grid)
        elif direction == MoveDirection.DOWN:
            merge_events = self._move_down(grid)

        # Check if anything actually moved or merged
        moved = False
        for tile in grid.tiles:
            if tile.id in original_positions:
                if tile.position != original_positions[tile.id]:
                    moved = True
                    break
                if tile.value != original_values.get(tile.id, tile.value):
                    moved = True
                    break

        # Add new tile if something moved
        new_tile = None
        if moved or merge_events:
            grid.moves += 1
            grid.last_move = datetime.utcnow()
            new_tile = self._add_random_tile(grid)

        # Check for 2048 win
        if any(tile.value >= 2048 for tile in grid.tiles):
            grid.won = True

        # Check for game over (no valid moves)
        if not self._has_valid_moves(grid):
            grid.game_over = True

        # Update stats
        self._update_stats(user_id, grid, merge_events)

        return grid, merge_events, new_tile

    def _move_left(self, grid: MemoryGrid) -> List[MergeEvent]:
        """Move all tiles left and merge"""
        merge_events = []

        for row in range(grid.size):
            # Get tiles in this row, sorted by column
            row_tiles = sorted(
                [t for t in grid.tiles if t.position[0] == row],
                key=lambda t: t.position[1]
            )

            # Process tiles from left to right
            target_col = 0
            merged_this_move = set()

            for tile in row_tiles:
                # Find the leftmost position this tile can move to
                while target_col < tile.position[1]:
                    # Check if there's a tile at target position
                    existing = self._get_tile_at(grid, row, target_col)

                    if existing is None:
                        # Empty cell - move here
                        tile.position = (row, target_col)
                        break
                    elif (existing.value == tile.value and
                          existing.id not in merged_this_move and
                          tile.id not in merged_this_move):
                        # Can merge!
                        merge_event = self._merge_tiles(grid, existing, tile)
                        merge_events.append(merge_event)
                        merged_this_move.add(existing.id)
                        break
                    else:
                        # Can't merge - try next column
                        target_col += 1

                if target_col >= grid.size:
                    break

                target_col += 1

        return merge_events

    def _move_right(self, grid: MemoryGrid) -> List[MergeEvent]:
        """Move all tiles right and merge"""
        merge_events = []

        for row in range(grid.size):
            # Get tiles in this row, sorted by column (reverse)
            row_tiles = sorted(
                [t for t in grid.tiles if t.position[0] == row],
                key=lambda t: t.position[1],
                reverse=True
            )

            target_col = grid.size - 1
            merged_this_move = set()

            for tile in row_tiles:
                while target_col > tile.position[1]:
                    existing = self._get_tile_at(grid, row, target_col)

                    if existing is None:
                        tile.position = (row, target_col)
                        break
                    elif (existing.value == tile.value and
                          existing.id not in merged_this_move and
                          tile.id not in merged_this_move):
                        merge_event = self._merge_tiles(grid, existing, tile)
                        merge_events.append(merge_event)
                        merged_this_move.add(existing.id)
                        break
                    else:
                        target_col -= 1

                if target_col < 0:
                    break

                target_col -= 1

        return merge_events

    def _move_up(self, grid: MemoryGrid) -> List[MergeEvent]:
        """Move all tiles up and merge"""
        merge_events = []

        for col in range(grid.size):
            col_tiles = sorted(
                [t for t in grid.tiles if t.position[1] == col],
                key=lambda t: t.position[0]
            )

            target_row = 0
            merged_this_move = set()

            for tile in col_tiles:
                while target_row < tile.position[0]:
                    existing = self._get_tile_at(grid, target_row, col)

                    if existing is None:
                        tile.position = (target_row, col)
                        break
                    elif (existing.value == tile.value and
                          existing.id not in merged_this_move and
                          tile.id not in merged_this_move):
                        merge_event = self._merge_tiles(grid, existing, tile)
                        merge_events.append(merge_event)
                        merged_this_move.add(existing.id)
                        break
                    else:
                        target_row += 1

                if target_row >= grid.size:
                    break

                target_row += 1

        return merge_events

    def _move_down(self, grid: MemoryGrid) -> List[MergeEvent]:
        """Move all tiles down and merge"""
        merge_events = []

        for col in range(grid.size):
            col_tiles = sorted(
                [t for t in grid.tiles if t.position[1] == col],
                key=lambda t: t.position[0],
                reverse=True
            )

            target_row = grid.size - 1
            merged_this_move = set()

            for tile in col_tiles:
                while target_row > tile.position[0]:
                    existing = self._get_tile_at(grid, target_row, col)

                    if existing is None:
                        tile.position = (target_row, col)
                        break
                    elif (existing.value == tile.value and
                          existing.id not in merged_this_move and
                          tile.id not in merged_this_move):
                        merge_event = self._merge_tiles(grid, existing, tile)
                        merge_events.append(merge_event)
                        merged_this_move.add(existing.id)
                        break
                    else:
                        target_row -= 1

                if target_row < 0:
                    break

                target_row -= 1

        return merge_events

    def _get_tile_at(
        self,
        grid: MemoryGrid,
        row: int,
        col: int
    ) -> Optional[MemoryTile]:
        """Get tile at specific position"""
        for tile in grid.tiles:
            if tile.position == (row, col):
                return tile
        return None

    def _merge_tiles(
        self,
        grid: MemoryGrid,
        tile1: MemoryTile,
        tile2: MemoryTile
    ) -> MergeEvent:
        """Merge two tiles into one"""
        new_value = tile1.value + tile2.value
        new_concept = get_merged_concept(tile1.concept, tile2.concept, grid.domain)

        # Update tile1 with merged values
        tile1.value = new_value
        tile1.concept = new_concept
        tile1.last_merged = datetime.utcnow()
        tile1.merge_count += 1
        tile1.source_concepts.extend([tile2.concept] + tile2.source_concepts)

        # Remove tile2 from grid
        grid.tiles = [t for t in grid.tiles if t.id != tile2.id]

        # Update score
        grid.score += new_value

        # Update highest tile
        if new_value > grid.highest_tile:
            grid.highest_tile = new_value

        # Create merge event
        event = MergeEvent(
            id=str(uuid.uuid4()),
            user_id=grid.user_id,
            domain=grid.domain,
            tile1_concept=tile1.concept,
            tile2_concept=tile2.concept,
            tile1_value=tile1.value // 2,  # Original value
            tile2_value=tile2.value,
            result_concept=new_concept,
            result_value=new_value,
            position=tile1.position,
            insight=generate_merge_insight(tile1, tile2, tile1),
        )

        self.merge_history.append(event)
        return event

    def _has_valid_moves(self, grid: MemoryGrid) -> bool:
        """Check if any valid moves remain"""
        # If there are empty cells, moves are possible
        if grid.empty_cells:
            return True

        # Check for possible merges
        for tile in grid.tiles:
            row, col = tile.position

            # Check adjacent tiles for possible merges
            for dr, dc in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
                adj_row, adj_col = row + dr, col + dc
                if 0 <= adj_row < grid.size and 0 <= adj_col < grid.size:
                    adj_tile = self._get_tile_at(grid, adj_row, adj_col)
                    if adj_tile and adj_tile.value == tile.value:
                        return True

        return False

    def learn(
        self,
        user_id: str,
        concept: str,
        domain: KnowledgeDomain,
        value: int = 2
    ) -> Tuple[MemoryGrid, MemoryTile]:
        """Add a new piece of knowledge to the grid"""
        grid = self.get_or_create_grid(user_id, domain)

        if grid.game_over:
            # Reset grid if game over
            grid = MemoryGrid(
                user_id=user_id,
                domain=domain,
                size=grid.size,
                tiles=[],
                score=0,
            )
            self.grids[user_id][domain] = grid

        # Add the new knowledge tile
        tile = self._add_random_tile(grid, concept=concept, value=value)

        return grid, tile

    def _update_stats(
        self,
        user_id: str,
        grid: MemoryGrid,
        merge_events: List[MergeEvent]
    ):
        """Update user statistics"""
        if user_id not in self.stats:
            self.stats[user_id] = MemoryStats(
                user_id=user_id,
                total_domains=0,
                total_tiles=0,
                total_score=0,
                highest_tile_ever=0,
                total_merges=0,
            )

        stats = self.stats[user_id]
        stats.total_merges += len(merge_events)
        stats.last_learned = datetime.utcnow()

        if grid.highest_tile > stats.highest_tile_ever:
            stats.highest_tile_ever = grid.highest_tile
            stats.highest_tile_domain = grid.domain

        if grid.won and grid.domain not in stats.domains_with_2048:
            stats.domains_with_2048.append(grid.domain)

    def get_stats(self, user_id: str) -> MemoryStats:
        """Get user's memory statistics"""
        if user_id not in self.stats:
            return MemoryStats(
                user_id=user_id,
                total_domains=0,
                total_tiles=0,
                total_score=0,
                highest_tile_ever=0,
                total_merges=0,
            )

        stats = self.stats[user_id]

        # Calculate totals across all domains
        if user_id in self.grids:
            stats.total_domains = len(self.grids[user_id])
            stats.total_tiles = sum(
                len(grid.tiles) for grid in self.grids[user_id].values()
            )
            stats.total_score = sum(
                grid.score for grid in self.grids[user_id].values()
            )

            # Find strongest and weakest domains
            if self.grids[user_id]:
                domain_scores = {
                    domain: grid.highest_tile
                    for domain, grid in self.grids[user_id].items()
                }
                stats.strongest_domain = max(domain_scores, key=domain_scores.get)
                stats.weakest_domain = min(domain_scores, key=domain_scores.get)

        return stats

    def get_all_grids(self, user_id: str) -> Dict[KnowledgeDomain, MemoryGrid]:
        """Get all grids for a user"""
        return self.grids.get(user_id, {})

    def reset_grid(self, user_id: str, domain: KnowledgeDomain) -> MemoryGrid:
        """Reset a specific grid"""
        if user_id in self.grids and domain in self.grids[user_id]:
            del self.grids[user_id][domain]
        return self.get_or_create_grid(user_id, domain)

    def render_grid_ascii(self, grid: MemoryGrid) -> str:
        """Render the grid as ASCII art"""
        grid_array = grid.grid_array
        cell_width = 8

        lines = []
        lines.append("┌" + ("─" * cell_width + "┬") * (grid.size - 1) + "─" * cell_width + "┐")

        for row_idx, row in enumerate(grid_array):
            row_str = "│"
            for tile in row:
                if tile:
                    val_str = str(tile.value).center(cell_width)
                else:
                    val_str = " " * cell_width
                row_str += val_str + "│"
            lines.append(row_str)

            if row_idx < grid.size - 1:
                lines.append("├" + ("─" * cell_width + "┼") * (grid.size - 1) + "─" * cell_width + "┤")

        lines.append("└" + ("─" * cell_width + "┴") * (grid.size - 1) + "─" * cell_width + "┘")

        return "\n".join(lines)


# Create singleton instance
memory_engine = MemoryEngine()
