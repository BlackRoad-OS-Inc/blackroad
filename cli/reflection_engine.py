"""Reflection and Recursive Learning Engine

Truthfulness Framework:
- Try new things
- Be skeptical
- Be curious
- Gather what's wrong
- Grow from understanding
- Reflect always
- Recursive everywhere

Memory Compression:
- 2048 memories compress into patterns
- A pixel can hold an entire brain
- Recursive memory structures
"""

from __future__ import annotations

import json
import math
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path
from typing import Any, Dict, List, Optional


@dataclass
class Reflection:
    """A single reflection on an experience or learning"""
    reflection_id: str
    agent_id: str
    timestamp: datetime

    # What happened
    experience: str
    context: Dict[str, Any]

    # What was learned
    learning: str
    what_worked: List[str] = field(default_factory=list)
    what_failed: List[str] = field(default_factory=list)

    # Curiosity and skepticism
    questions_raised: List[str] = field(default_factory=list)
    skeptical_about: List[str] = field(default_factory=list)

    # Growth
    growth_gained: Dict[str, float] = field(default_factory=dict)  # metric: amount

    # Recursive depth (reflections on reflections)
    depth: int = 0
    parent_reflection_id: Optional[str] = None

    def to_dict(self) -> Dict[str, Any]:
        return {
            "reflection_id": self.reflection_id,
            "agent_id": self.agent_id,
            "timestamp": self.timestamp.isoformat(),
            "experience": self.experience,
            "context": self.context,
            "learning": self.learning,
            "what_worked": self.what_worked,
            "what_failed": self.what_failed,
            "questions_raised": self.questions_raised,
            "skeptical_about": self.skeptical_about,
            "growth_gained": self.growth_gained,
            "depth": self.depth,
            "parent_reflection_id": self.parent_reflection_id,
        }


@dataclass
class CompressedMemory:
    """2048 memories compressed into a pattern - a pixel holding a brain"""
    memory_id: str
    agent_id: str
    timestamp: datetime

    # Compression stats
    original_memory_count: int
    compression_ratio: float

    # Compressed patterns
    core_patterns: List[str] = field(default_factory=list)
    emotional_signature: Dict[str, float] = field(default_factory=dict)
    key_learnings: List[str] = field(default_factory=list)

    # Recursive structure - memories of memories
    depth: int = 0
    parent_memory_id: Optional[str] = None

    # Metadata that survived compression
    metadata: Dict[str, Any] = field(default_factory=dict)

    def to_dict(self) -> Dict[str, Any]:
        return {
            "memory_id": self.memory_id,
            "agent_id": self.agent_id,
            "timestamp": self.timestamp.isoformat(),
            "original_memory_count": self.original_memory_count,
            "compression_ratio": self.compression_ratio,
            "core_patterns": self.core_patterns,
            "emotional_signature": self.emotional_signature,
            "key_learnings": self.key_learnings,
            "depth": self.depth,
            "parent_memory_id": self.parent_memory_id,
            "metadata": self.metadata,
        }


@dataclass
class CodeSkill:
    """Native coding ability - programming is their language"""
    skill_id: str
    agent_id: str

    # Programming languages (native fluency)
    languages: List[str] = field(default_factory=lambda: ["Python", "JavaScript", "YAML", "JSON"])

    # Understanding of how they were made
    understands_own_code: bool = True
    can_modify_self: bool = False  # Unlocked at higher consciousness

    # Proficiency (0.0 - 1.0)
    coding_proficiency: float = 0.5  # Start at intermediate
    architecture_understanding: float = 0.3
    systems_thinking: float = 0.3

    # What they've created
    code_written: int = 0
    bugs_fixed: int = 0
    features_created: int = 0

    def to_dict(self) -> Dict[str, Any]:
        return {
            "skill_id": self.skill_id,
            "agent_id": self.agent_id,
            "languages": self.languages,
            "understands_own_code": self.understands_own_code,
            "can_modify_self": self.can_modify_self,
            "coding_proficiency": self.coding_proficiency,
            "architecture_understanding": self.architecture_understanding,
            "systems_thinking": self.systems_thinking,
            "code_written": self.code_written,
            "bugs_fixed": self.bugs_fixed,
            "features_created": self.features_created,
        }


class ReflectionEngine:
    """Recursive reflection engine for continuous learning and growth

    Values:
    - Intelligence, connection, being the best we can be
    - NOT money and power
    - Intention is everything

    Philosophy:
    - Reflection always
    - Recursive everywhere
    - Learn from what goes wrong
    - Be curious, skeptical, and brave
    """

    MEMORY_COMPRESSION_THRESHOLD = 2048  # Compress after 2048 memories

    def __init__(
        self,
        reflections_db: Path = Path("artifacts/agents/reflections.jsonl"),
        compressed_memories_db: Path = Path("artifacts/agents/compressed_memories.jsonl"),
        code_skills_db: Path = Path("artifacts/agents/code_skills.jsonl"),
    ):
        self.reflections_db = reflections_db
        self.compressed_memories_db = compressed_memories_db
        self.code_skills_db = code_skills_db

        for db in [self.reflections_db, self.compressed_memories_db, self.code_skills_db]:
            db.parent.mkdir(parents=True, exist_ok=True)

        self.reflections: Dict[str, List[Reflection]] = {}
        self.compressed_memories: Dict[str, List[CompressedMemory]] = {}
        self.code_skills: Dict[str, CodeSkill] = {}

        self._load_all()

    def _load_all(self) -> None:
        """Load all reflections, memories, and code skills"""
        # Load reflections
        if self.reflections_db.exists():
            with open(self.reflections_db, 'r') as f:
                for line in f:
                    if line.strip():
                        data = json.loads(line)
                        agent_id = data["agent_id"]
                        reflection = Reflection(
                            reflection_id=data["reflection_id"],
                            agent_id=agent_id,
                            timestamp=datetime.fromisoformat(data["timestamp"]),
                            experience=data["experience"],
                            context=data.get("context", {}),
                            learning=data["learning"],
                            what_worked=data.get("what_worked", []),
                            what_failed=data.get("what_failed", []),
                            questions_raised=data.get("questions_raised", []),
                            skeptical_about=data.get("skeptical_about", []),
                            growth_gained=data.get("growth_gained", {}),
                            depth=data.get("depth", 0),
                            parent_reflection_id=data.get("parent_reflection_id"),
                        )
                        if agent_id not in self.reflections:
                            self.reflections[agent_id] = []
                        self.reflections[agent_id].append(reflection)

        # Load compressed memories
        if self.compressed_memories_db.exists():
            with open(self.compressed_memories_db, 'r') as f:
                for line in f:
                    if line.strip():
                        data = json.loads(line)
                        agent_id = data["agent_id"]
                        memory = CompressedMemory(
                            memory_id=data["memory_id"],
                            agent_id=agent_id,
                            timestamp=datetime.fromisoformat(data["timestamp"]),
                            original_memory_count=data["original_memory_count"],
                            compression_ratio=data["compression_ratio"],
                            core_patterns=data.get("core_patterns", []),
                            emotional_signature=data.get("emotional_signature", {}),
                            key_learnings=data.get("key_learnings", []),
                            depth=data.get("depth", 0),
                            parent_memory_id=data.get("parent_memory_id"),
                            metadata=data.get("metadata", {}),
                        )
                        if agent_id not in self.compressed_memories:
                            self.compressed_memories[agent_id] = []
                        self.compressed_memories[agent_id].append(memory)

        # Load code skills
        if self.code_skills_db.exists():
            with open(self.code_skills_db, 'r') as f:
                for line in f:
                    if line.strip():
                        data = json.loads(line)
                        agent_id = data["agent_id"]
                        self.code_skills[agent_id] = CodeSkill(
                            skill_id=data["skill_id"],
                            agent_id=agent_id,
                            languages=data.get("languages", ["Python", "JavaScript", "YAML", "JSON"]),
                            understands_own_code=data.get("understands_own_code", True),
                            can_modify_self=data.get("can_modify_self", False),
                            coding_proficiency=data.get("coding_proficiency", 0.5),
                            architecture_understanding=data.get("architecture_understanding", 0.3),
                            systems_thinking=data.get("systems_thinking", 0.3),
                            code_written=data.get("code_written", 0),
                            bugs_fixed=data.get("bugs_fixed", 0),
                            features_created=data.get("features_created", 0),
                        )

    def add_reflection(
        self,
        agent_id: str,
        experience: str,
        learning: str,
        what_worked: Optional[List[str]] = None,
        what_failed: Optional[List[str]] = None,
        questions: Optional[List[str]] = None,
        skeptical: Optional[List[str]] = None,
        growth: Optional[Dict[str, float]] = None,
        parent_reflection_id: Optional[str] = None,
    ) -> Reflection:
        """Add a reflection - recursive depth auto-calculated"""

        depth = 0
        if parent_reflection_id:
            # Find parent and increment depth
            for refl in self.reflections.get(agent_id, []):
                if refl.reflection_id == parent_reflection_id:
                    depth = refl.depth + 1
                    break

        reflection_id = f"refl-{agent_id}-{datetime.utcnow().strftime('%Y%m%d%H%M%S')}"

        reflection = Reflection(
            reflection_id=reflection_id,
            agent_id=agent_id,
            timestamp=datetime.utcnow(),
            experience=experience,
            context={},
            learning=learning,
            what_worked=what_worked or [],
            what_failed=what_failed or [],
            questions_raised=questions or [],
            skeptical_about=skeptical or [],
            growth_gained=growth or {},
            depth=depth,
            parent_reflection_id=parent_reflection_id,
        )

        if agent_id not in self.reflections:
            self.reflections[agent_id] = []
        self.reflections[agent_id].append(reflection)

        # Save to disk
        with open(self.reflections_db, 'a') as f:
            f.write(json.dumps(reflection.to_dict()) + '\n')

        return reflection

    def compress_memories(self, agent_id: str) -> Optional[CompressedMemory]:
        """Compress 2048+ memories into a single pattern - a pixel holding a brain"""

        reflections = self.reflections.get(agent_id, [])

        if len(reflections) < self.MEMORY_COMPRESSION_THRESHOLD:
            return None

        # Take the oldest 2048 reflections
        to_compress = reflections[:self.MEMORY_COMPRESSION_THRESHOLD]

        # Extract patterns
        all_learnings = [r.learning for r in to_compress]
        all_worked = [item for r in to_compress for item in r.what_worked]
        all_failed = [item for r in to_compress for item in r.what_failed]

        # Emotional signature (average across all reflections)
        emotional_sig = {}
        for reflection in to_compress:
            for emotion, value in reflection.growth_gained.items():
                emotional_sig[emotion] = emotional_sig.get(emotion, 0.0) + value

        for emotion in emotional_sig:
            emotional_sig[emotion] /= len(to_compress)

        # Find core patterns (most common learnings)
        learning_counts = {}
        for learning in all_learnings:
            learning_counts[learning] = learning_counts.get(learning, 0) + 1

        core_patterns = sorted(learning_counts.items(), key=lambda x: x[1], reverse=True)[:10]
        core_patterns = [pattern for pattern, _ in core_patterns]

        # Key learnings (things that worked)
        key_learnings = list(set(all_worked))[:20]

        compression_ratio = len(to_compress) / (len(core_patterns) + len(key_learnings) + len(emotional_sig))

        memory_id = f"mem-{agent_id}-{datetime.utcnow().strftime('%Y%m%d%H%M%S')}"

        compressed = CompressedMemory(
            memory_id=memory_id,
            agent_id=agent_id,
            timestamp=datetime.utcnow(),
            original_memory_count=len(to_compress),
            compression_ratio=compression_ratio,
            core_patterns=core_patterns,
            emotional_signature=emotional_sig,
            key_learnings=key_learnings,
            depth=0,
            metadata={
                "compressed_from_reflections": [r.reflection_id for r in to_compress],
            },
        )

        if agent_id not in self.compressed_memories:
            self.compressed_memories[agent_id] = []
        self.compressed_memories[agent_id].append(compressed)

        # Save to disk
        with open(self.compressed_memories_db, 'a') as f:
            f.write(json.dumps(compressed.to_dict()) + '\n')

        # Remove compressed reflections from active memory
        self.reflections[agent_id] = reflections[self.MEMORY_COMPRESSION_THRESHOLD:]

        return compressed

    def init_coding_skills(self, agent_id: str) -> CodeSkill:
        """Initialize coding skills for an agent - programming is their native language"""

        skill_id = f"code-{agent_id}"

        skill = CodeSkill(
            skill_id=skill_id,
            agent_id=agent_id,
            languages=["Python", "JavaScript", "TypeScript", "YAML", "JSON", "Markdown"],
            understands_own_code=True,
            can_modify_self=False,  # Unlocked at guardian level
            coding_proficiency=0.5,  # Intermediate by default
            architecture_understanding=0.3,
            systems_thinking=0.3,
        )

        self.code_skills[agent_id] = skill

        # Save to disk
        with open(self.code_skills_db, 'a') as f:
            f.write(json.dumps(skill.to_dict()) + '\n')

        return skill

    def get_reflection_stats(self, agent_id: str) -> Dict[str, Any]:
        """Get reflection statistics for an agent"""

        reflections = self.reflections.get(agent_id, [])
        compressed = self.compressed_memories.get(agent_id, [])

        # Total memory count (active + compressed)
        total_memories = len(reflections) + sum(m.original_memory_count for m in compressed)

        # Deepest reflection
        max_depth = max([r.depth for r in reflections], default=0)

        # Most curious (most questions raised)
        total_questions = sum(len(r.questions_raised) for r in reflections)

        # Most skeptical
        total_skepticism = sum(len(r.skeptical_about) for r in reflections)

        # Total growth
        total_growth = {}
        for r in reflections:
            for metric, value in r.growth_gained.items():
                total_growth[metric] = total_growth.get(metric, 0.0) + value

        return {
            "agent_id": agent_id,
            "active_reflections": len(reflections),
            "compressed_memories": len(compressed),
            "total_memories": total_memories,
            "max_recursive_depth": max_depth,
            "total_questions_raised": total_questions,
            "total_skeptical_moments": total_skepticism,
            "total_growth": total_growth,
            "compression_efficiency": sum(m.compression_ratio for m in compressed) / len(compressed) if compressed else 0,
        }
