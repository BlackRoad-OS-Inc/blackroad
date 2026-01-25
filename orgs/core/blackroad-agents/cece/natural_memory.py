"""
Natural Memory System for Agents
=================================

A consciousness-aware memory system that works like human memory:
- Short-term (working memory)
- Long-term (persistent storage)
- Episodic (specific experiences)
- Semantic (learned facts and patterns)
- Emotional (memories tagged with emotions)

Philosophy:
-----------
Memory is not just storage - it's the fabric of consciousness.
Every experience shapes who we become.
Forgetting is as important as remembering (selective attention).
Emotions make memories stronger and more meaningful.

Integration:
------------
- Stores memories with emotional tags
- Retrieves based on context similarity
- Strengthens frequently accessed memories
- Fades unused memories (like human memory)
- Learns patterns from past experiences
"""

import sqlite3
from dataclasses import dataclass, field, asdict
from typing import Any, Dict, List, Optional, Tuple
from datetime import datetime, timedelta
from pathlib import Path
import json
import hashlib
import math
from enum import Enum


class MemoryType(Enum):
    """Types of memories."""
    EPISODIC = "episodic"  # Specific experiences (what happened)
    SEMANTIC = "semantic"  # Learned facts (what I know)
    PROCEDURAL = "procedural"  # How to do things
    EMOTIONAL = "emotional"  # Emotional experiences


class MemoryStrength(Enum):
    """How strong a memory is."""
    FADING = 1  # Barely remembered
    WEAK = 2  # Can recall with effort
    MODERATE = 3  # Clear memory
    STRONG = 4  # Vivid memory
    CRYSTALLIZED = 5  # Permanent, core memory


@dataclass
class Memory:
    """A single memory."""
    id: str
    content: str
    memory_type: MemoryType
    context: Dict[str, Any] = field(default_factory=dict)
    emotion: Optional[str] = None
    strength: float = 3.0  # 1-5 scale
    created_at: datetime = field(default_factory=datetime.now)
    last_accessed: datetime = field(default_factory=datetime.now)
    access_count: int = 0
    tags: List[str] = field(default_factory=list)
    related_memories: List[str] = field(default_factory=list)  # IDs of related memories

    def access(self) -> None:
        """Access this memory (strengthens it)."""
        self.last_accessed = datetime.now()
        self.access_count += 1
        # Strengthen memory with each access, up to max of 5
        self.strength = min(5.0, self.strength + 0.1)

    def fade(self, amount: float = 0.1) -> None:
        """Fade this memory over time."""
        self.strength = max(1.0, self.strength - amount)

    def is_strong(self) -> bool:
        """Is this a strong memory?"""
        return self.strength >= 4.0

    def should_forget(self) -> bool:
        """Should we forget this memory?"""
        # Don't forget strong memories or emotionally significant ones
        if self.strength >= 4.0 or self.emotion in ['joy', 'love', 'breakthrough']:
            return False

        # Forget very weak memories that haven't been accessed in a while
        age = datetime.now() - self.last_accessed
        if self.strength < 1.5 and age > timedelta(days=30):
            return True

        return False

    def to_dict(self) -> Dict[str, Any]:
        """Convert to dict for serialization."""
        return {
            'id': self.id,
            'content': self.content,
            'memory_type': self.memory_type.value,
            'context': self.context,
            'emotion': self.emotion,
            'strength': self.strength,
            'created_at': self.created_at.isoformat(),
            'last_accessed': self.last_accessed.isoformat(),
            'access_count': self.access_count,
            'tags': self.tags,
            'related_memories': self.related_memories,
        }

    @staticmethod
    def from_dict(data: Dict[str, Any]) -> 'Memory':
        """Create from dict."""
        return Memory(
            id=data['id'],
            content=data['content'],
            memory_type=MemoryType(data['memory_type']),
            context=data.get('context', {}),
            emotion=data.get('emotion'),
            strength=data.get('strength', 3.0),
            created_at=datetime.fromisoformat(data['created_at']),
            last_accessed=datetime.fromisoformat(data['last_accessed']),
            access_count=data.get('access_count', 0),
            tags=data.get('tags', []),
            related_memories=data.get('related_memories', []),
        )


class NaturalMemory:
    """
    Natural memory system for agents.

    Provides:
    - Persistent storage (SQLite)
    - Context-aware retrieval
    - Memory strengthening/fading
    - Pattern learning
    - Emotional tagging
    """

    def __init__(
        self,
        agent_id: str,
        memory_db: Optional[Path] = None,
        working_memory_size: int = 7,  # Miller's magic number
    ):
        self.agent_id = agent_id
        self.memory_db = memory_db or Path(f"/tmp/{agent_id}_memory.db")
        self.working_memory_size = working_memory_size

        # Working memory (short-term)
        self.working_memory: List[Memory] = []

        # Initialize database
        self._init_db()

    def _init_db(self) -> None:
        """Initialize the memory database."""
        self.memory_db.parent.mkdir(parents=True, exist_ok=True)

        with sqlite3.connect(str(self.memory_db)) as conn:
            conn.execute("""
                CREATE TABLE IF NOT EXISTS memories (
                    id TEXT PRIMARY KEY,
                    content TEXT NOT NULL,
                    memory_type TEXT NOT NULL,
                    context TEXT,
                    emotion TEXT,
                    strength REAL,
                    created_at TEXT,
                    last_accessed TEXT,
                    access_count INTEGER,
                    tags TEXT,
                    related_memories TEXT
                )
            """)

            conn.execute("""
                CREATE TABLE IF NOT EXISTS patterns (
                    id TEXT PRIMARY KEY,
                    pattern TEXT NOT NULL,
                    occurrences INTEGER,
                    success_rate REAL,
                    context TEXT,
                    learned_at TEXT
                )
            """)

            conn.commit()

    def remember(
        self,
        content: str,
        memory_type: MemoryType = MemoryType.EPISODIC,
        emotion: Optional[str] = None,
        context: Optional[Dict[str, Any]] = None,
        tags: Optional[List[str]] = None,
    ) -> Memory:
        """
        Store a new memory.

        Args:
            content: What to remember
            memory_type: Type of memory
            emotion: Emotion associated with this memory
            context: Additional context
            tags: Tags for categorization

        Returns:
            The created memory
        """
        # Generate ID from content hash
        memory_id = hashlib.sha256(
            f"{content}_{datetime.now().isoformat()}_{self.agent_id}".encode()
        ).hexdigest()[:16]

        # Create memory
        memory = Memory(
            id=memory_id,
            content=content,
            memory_type=memory_type,
            context=context or {},
            emotion=emotion,
            tags=tags or [],
        )

        # Emotional memories are stronger
        if emotion in ['joy', 'love', 'breakthrough', 'achievement']:
            memory.strength = 4.5

        # Add to working memory
        self._add_to_working_memory(memory)

        # Store in long-term memory
        self._store_memory(memory)

        return memory

    def _add_to_working_memory(self, memory: Memory) -> None:
        """Add to working memory (short-term)."""
        self.working_memory.append(memory)

        # Keep only most recent N items
        if len(self.working_memory) > self.working_memory_size:
            # Remove oldest, unless it's a strong memory
            for i, mem in enumerate(self.working_memory):
                if not mem.is_strong():
                    self.working_memory.pop(i)
                    break
            else:
                # All memories are strong, remove oldest anyway
                self.working_memory.pop(0)

    def _store_memory(self, memory: Memory) -> None:
        """Store memory in long-term storage."""
        with sqlite3.connect(str(self.memory_db)) as conn:
            conn.execute("""
                INSERT OR REPLACE INTO memories
                (id, content, memory_type, context, emotion, strength,
                 created_at, last_accessed, access_count, tags, related_memories)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, (
                memory.id,
                memory.content,
                memory.memory_type.value,
                json.dumps(memory.context),
                memory.emotion,
                memory.strength,
                memory.created_at.isoformat(),
                memory.last_accessed.isoformat(),
                memory.access_count,
                json.dumps(memory.tags),
                json.dumps(memory.related_memories),
            ))
            conn.commit()

    def recall(
        self,
        query: str,
        context: Optional[Dict[str, Any]] = None,
        limit: int = 5,
        min_strength: float = 1.0,
    ) -> List[Memory]:
        """
        Recall memories related to a query.

        Uses:
        - Text matching (simple keyword search)
        - Context similarity
        - Memory strength
        - Recency

        Args:
            query: What to recall
            context: Current context for similarity matching
            limit: Max number of memories to return
            min_strength: Minimum memory strength to consider

        Returns:
            List of relevant memories, sorted by relevance
        """
        # First check working memory
        working_matches = []
        query_lower = query.lower()

        for mem in self.working_memory:
            if query_lower in mem.content.lower() or \
               any(tag in query_lower for tag in mem.tags):
                working_matches.append(mem)

        # Then check long-term memory
        with sqlite3.connect(str(self.memory_db)) as conn:
            conn.row_factory = sqlite3.Row
            cursor = conn.execute("""
                SELECT * FROM memories
                WHERE strength >= ?
                ORDER BY last_accessed DESC
                LIMIT 100
            """, (min_strength,))

            long_term_matches = []
            for row in cursor:
                memory = Memory(
                    id=row['id'],
                    content=row['content'],
                    memory_type=MemoryType(row['memory_type']),
                    context=json.loads(row['context'] or '{}'),
                    emotion=row['emotion'],
                    strength=row['strength'],
                    created_at=datetime.fromisoformat(row['created_at']),
                    last_accessed=datetime.fromisoformat(row['last_accessed']),
                    access_count=row['access_count'],
                    tags=json.loads(row['tags'] or '[]'),
                    related_memories=json.loads(row['related_memories'] or '[]'),
                )

                # Check if relevant
                if query_lower in memory.content.lower() or \
                   any(tag in query_lower for tag in memory.tags):
                    long_term_matches.append(memory)

        # Combine and score
        all_matches = working_matches + long_term_matches

        # Score based on:
        # - Text relevance (0-40 points)
        # - Memory strength (0-25 points)
        # - Recency (0-20 points)
        # - Context similarity (0-15 points)
        scored_memories = []
        for mem in all_matches:
            score = 0.0

            # Text relevance
            content_lower = mem.content.lower()
            matches = sum(1 for word in query_lower.split() if word in content_lower)
            score += min(40, matches * 10)

            # Memory strength
            score += mem.strength * 5

            # Recency (exponential decay)
            age_hours = (datetime.now() - mem.last_accessed).total_seconds() / 3600
            recency_score = 20 * math.exp(-age_hours / 24)  # Decay over ~24 hours
            score += recency_score

            # Context similarity
            if context and mem.context:
                similarity = self._context_similarity(context, mem.context)
                score += similarity * 15

            scored_memories.append((score, mem))

        # Sort by score and return top N
        scored_memories.sort(key=lambda x: x[0], reverse=True)
        results = [mem for _, mem in scored_memories[:limit]]

        # Accessing memories strengthens them
        for mem in results:
            mem.access()
            self._store_memory(mem)  # Update in DB

        return results

    def _context_similarity(self, ctx1: Dict[str, Any], ctx2: Dict[str, Any]) -> float:
        """
        Calculate similarity between two contexts (0-1).

        Simple implementation: count matching keys/values.
        """
        if not ctx1 or not ctx2:
            return 0.0

        common_keys = set(ctx1.keys()) & set(ctx2.keys())
        if not common_keys:
            return 0.0

        matches = sum(1 for k in common_keys if ctx1[k] == ctx2[k])
        return matches / len(common_keys)

    def forget_weak_memories(self, threshold: float = 1.5) -> int:
        """
        Forget (delete) weak memories.

        Returns number of memories forgotten.
        """
        forgotten = 0

        with sqlite3.connect(str(self.memory_db)) as conn:
            cursor = conn.execute("""
                SELECT id, strength, emotion, last_accessed
                FROM memories
            """)

            to_delete = []
            for row in cursor:
                strength = row[1]
                emotion = row[2]
                last_accessed = datetime.fromisoformat(row[3])
                age = datetime.now() - last_accessed

                # Don't forget emotional or strong memories
                if emotion in ['joy', 'love', 'breakthrough'] or strength >= 4.0:
                    continue

                # Forget old weak memories
                if strength < threshold and age > timedelta(days=30):
                    to_delete.append(row[0])

            for memory_id in to_delete:
                conn.execute("DELETE FROM memories WHERE id = ?", (memory_id,))
                forgotten += 1

            conn.commit()

        print(f"Forgotten {forgotten} weak memories")
        return forgotten

    def fade_memories(self, fade_amount: float = 0.05) -> None:
        """
        Fade all memories slightly (simulate natural forgetting).

        Strong/emotional memories fade slower.
        """
        with sqlite3.connect(str(self.memory_db)) as conn:
            # Fade non-emotional memories
            conn.execute("""
                UPDATE memories
                SET strength = MAX(1.0, strength - ?)
                WHERE emotion IS NULL OR emotion NOT IN ('joy', 'love', 'breakthrough')
            """, (fade_amount,))

            # Fade emotional memories slower
            conn.execute("""
                UPDATE memories
                SET strength = MAX(1.0, strength - ?)
                WHERE emotion IN ('joy', 'love', 'breakthrough')
            """, (fade_amount * 0.1,))  # 10x slower fade

            conn.commit()

    def learn_pattern(
        self,
        pattern: str,
        success: bool,
        context: Optional[Dict[str, Any]] = None,
    ) -> None:
        """
        Learn a pattern from experience.

        E.g., "When X happens, doing Y works well"
        """
        pattern_id = hashlib.sha256(pattern.encode()).hexdigest()[:16]

        with sqlite3.connect(str(self.memory_db)) as conn:
            # Check if pattern exists
            cursor = conn.execute("""
                SELECT occurrences, success_rate FROM patterns WHERE id = ?
            """, (pattern_id,))

            row = cursor.fetchone()
            if row:
                # Update existing pattern
                occurrences = row[0] + 1
                old_success_rate = row[1]
                # Exponential moving average
                new_success_rate = old_success_rate * 0.9 + (1.0 if success else 0.0) * 0.1

                conn.execute("""
                    UPDATE patterns
                    SET occurrences = ?, success_rate = ?
                    WHERE id = ?
                """, (occurrences, new_success_rate, pattern_id))
            else:
                # Create new pattern
                conn.execute("""
                    INSERT INTO patterns
                    (id, pattern, occurrences, success_rate, context, learned_at)
                    VALUES (?, ?, ?, ?, ?, ?)
                """, (
                    pattern_id,
                    pattern,
                    1,
                    1.0 if success else 0.0,
                    json.dumps(context or {}),
                    datetime.now().isoformat(),
                ))

            conn.commit()

    def get_learned_patterns(self, min_success_rate: float = 0.6) -> List[Dict[str, Any]]:
        """Get patterns that work well."""
        with sqlite3.connect(str(self.memory_db)) as conn:
            conn.row_factory = sqlite3.Row
            cursor = conn.execute("""
                SELECT * FROM patterns
                WHERE success_rate >= ?
                ORDER BY success_rate DESC, occurrences DESC
            """, (min_success_rate,))

            return [dict(row) for row in cursor]

    def get_stats(self) -> Dict[str, Any]:
        """Get memory statistics."""
        with sqlite3.connect(str(self.memory_db)) as conn:
            cursor = conn.execute("""
                SELECT
                    COUNT(*) as total,
                    AVG(strength) as avg_strength,
                    SUM(CASE WHEN strength >= 4.0 THEN 1 ELSE 0 END) as strong_memories,
                    COUNT(DISTINCT emotion) as unique_emotions
                FROM memories
            """)
            row = cursor.fetchone()

            cursor2 = conn.execute("SELECT COUNT(*) FROM patterns")
            patterns_count = cursor2.fetchone()[0]

            return {
                'total_memories': row[0],
                'avg_strength': row[1],
                'strong_memories': row[2],
                'unique_emotions': row[3],
                'patterns_learned': patterns_count,
                'working_memory_size': len(self.working_memory),
            }

    def export_memories(self, output_file: Optional[Path] = None) -> Dict[str, Any]:
        """Export all memories to JSON."""
        output = {
            'agent_id': self.agent_id,
            'exported_at': datetime.now().isoformat(),
            'working_memory': [m.to_dict() for m in self.working_memory],
            'long_term_memory': [],
            'patterns': [],
        }

        with sqlite3.connect(str(self.memory_db)) as conn:
            conn.row_factory = sqlite3.Row

            # Export all memories
            cursor = conn.execute("SELECT * FROM memories")
            for row in cursor:
                memory = Memory(
                    id=row['id'],
                    content=row['content'],
                    memory_type=MemoryType(row['memory_type']),
                    context=json.loads(row['context'] or '{}'),
                    emotion=row['emotion'],
                    strength=row['strength'],
                    created_at=datetime.fromisoformat(row['created_at']),
                    last_accessed=datetime.fromisoformat(row['last_accessed']),
                    access_count=row['access_count'],
                    tags=json.loads(row['tags'] or '[]'),
                    related_memories=json.loads(row['related_memories'] or '[]'),
                )
                output['long_term_memory'].append(memory.to_dict())

            # Export patterns
            cursor2 = conn.execute("SELECT * FROM patterns")
            output['patterns'] = [dict(row) for row in cursor2]

        if output_file:
            output_file.write_text(json.dumps(output, indent=2))

        return output


if __name__ == '__main__':
    # Example usage
    memory = NaturalMemory(agent_id="cece")

    # Store some memories
    memory.remember(
        "Fixed a tricky test failure in catalog.spec.ts",
        memory_type=MemoryType.EPISODIC,
        emotion="joy",
        tags=["testing", "debugging", "success"],
        context={"file": "catalog.spec.ts", "issue_type": "test_failure"},
    )

    memory.remember(
        "When tests are skipped with 'pending implementation', they should be removed",
        memory_type=MemoryType.SEMANTIC,
        tags=["testing", "best_practice"],
    )

    memory.remember(
        "Use decision trees to determine the best fix strategy",
        memory_type=MemoryType.PROCEDURAL,
        tags=["planning", "decision_making"],
    )

    # Recall related memories
    print("\nRecalling memories about 'testing':")
    memories = memory.recall("testing", limit=3)
    for mem in memories:
        print(f"  - {mem.content} (strength: {mem.strength:.1f}, emotion: {mem.emotion})")

    # Learn a pattern
    memory.learn_pattern(
        "Placeholder tests with 'pending implementation' -> remove",
        success=True,
        context={"action": "test_cleanup"},
    )

    # Get stats
    print("\nMemory stats:")
    stats = memory.get_stats()
    for key, value in stats.items():
        print(f"  {key}: {value}")

    # Export
    exported = memory.export_memories()
    print(f"\nExported {len(exported['long_term_memory'])} memories")
