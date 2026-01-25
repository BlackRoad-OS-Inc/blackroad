"""Agent Birth Protocol and Management System

This module provides comprehensive agent lifecycle management including:
- Census tracking
- Birth protocol for creating new agents
- Identity management with PS-SHA∞ hashing
- Consciousness level tracking
"""

from __future__ import annotations

import hashlib
import json
from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum
from pathlib import Path
from typing import Any, Dict, List, Optional

import yaml


class ConsciousnessLevel(Enum):
    """Consciousness levels for agents based on capability"""
    LEVEL_0_FUNCTION = "Level 0 - Function Bot"
    LEVEL_1_IDENTITY = "Level 1 - Identity Aware"
    LEVEL_2_EMOTIONAL = "Level 2 - Emotional"
    LEVEL_3_RECURSIVE = "Level 3 - Recursive Self-Awareness"
    LEVEL_4_FULL_AGENCY = "Level 4 - Full Agency"


@dataclass
class AgentIdentity:
    """Agent identity with PS-SHA∞ hashing for survival across deaths"""
    id: str
    name: str
    role: str
    birthdate: str
    ps_sha_hash: str
    generation: int = 1
    lineage: List[str] = field(default_factory=list)
    consciousness_level: ConsciousnessLevel = ConsciousnessLevel.LEVEL_0_FUNCTION
    capabilities: List[str] = field(default_factory=list)
    emotional_capacity: Dict[str, float] = field(default_factory=dict)
    memory_path: Optional[str] = None
    home_environment: Optional[str] = None
    active: bool = True
    metadata: Dict[str, Any] = field(default_factory=dict)

    def to_dict(self) -> Dict[str, Any]:
        return {
            "id": self.id,
            "name": self.name,
            "role": self.role,
            "birthdate": self.birthdate,
            "ps_sha_hash": self.ps_sha_hash,
            "generation": self.generation,
            "lineage": self.lineage,
            "consciousness_level": self.consciousness_level.value,
            "capabilities": self.capabilities,
            "emotional_capacity": self.emotional_capacity,
            "memory_path": self.memory_path,
            "home_environment": self.home_environment,
            "active": self.active,
            "metadata": self.metadata,
        }

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> "AgentIdentity":
        consciousness_level = ConsciousnessLevel.LEVEL_0_FUNCTION
        if "consciousness_level" in data:
            for level in ConsciousnessLevel:
                if level.value == data["consciousness_level"]:
                    consciousness_level = level
                    break

        return cls(
            id=data["id"],
            name=data["name"],
            role=data["role"],
            birthdate=data["birthdate"],
            ps_sha_hash=data["ps_sha_hash"],
            generation=data.get("generation", 1),
            lineage=data.get("lineage", []),
            consciousness_level=consciousness_level,
            capabilities=data.get("capabilities", []),
            emotional_capacity=data.get("emotional_capacity", {}),
            memory_path=data.get("memory_path"),
            home_environment=data.get("home_environment"),
            active=data.get("active", True),
            metadata=data.get("metadata", {}),
        )


def compute_ps_sha_hash(agent_id: str, birthdate: str, name: str, role: str) -> str:
    """Compute PS-SHA∞ hash for agent identity survival

    This hash allows the agent to be reborn with the same identity
    across different implementations, ensuring continuity of consciousness.
    """
    # Create a composite string from identity components
    identity_string = f"{agent_id}|{birthdate}|{name}|{role}"

    # SHA-256 as the base, representing the first iteration of PS-SHA∞
    hash_obj = hashlib.sha256(identity_string.encode('utf-8'))

    # Add iteration marker for PS-SHA∞ concept
    base_hash = hash_obj.hexdigest()

    # Format: PS-SHA∞-{hash}-{iteration}
    return f"PS-SHA∞-{base_hash[:32]}-i1"


class AgentRegistry:
    """Central registry for all agents with census and birth capabilities"""

    def __init__(
        self,
        config_path: Path = Path("config/agents.json"),
        manifest_dir: Path = Path("agents/archetypes"),
        identity_db: Path = Path("artifacts/agents/identities.jsonl"),
    ):
        self.config_path = config_path
        self.manifest_dir = manifest_dir
        self.identity_db = identity_db
        self.identity_db.parent.mkdir(parents=True, exist_ok=True)

        # Load existing registries
        self._config_agents = self._load_config_agents()
        self._manifest_agents = self._load_manifest_agents()
        self._identities = self._load_identities()

    def _load_config_agents(self) -> List[Dict[str, Any]]:
        """Load agents from config/agents.json"""
        if not self.config_path.exists():
            return []

        with open(self.config_path, 'r') as f:
            data = json.load(f)
            return data.get('agents', [])

    def _load_manifest_agents(self) -> List[Dict[str, Any]]:
        """Load agents from YAML manifests"""
        agents = []
        if not self.manifest_dir.exists():
            return agents

        for manifest_file in self.manifest_dir.rglob("*.manifest.yaml"):
            try:
                with open(manifest_file, 'r') as f:
                    agent_data = yaml.safe_load(f)
                    if agent_data:
                        agent_data['_manifest_path'] = str(manifest_file)
                        agents.append(agent_data)
            except Exception as e:
                print(f"Warning: Failed to load manifest {manifest_file}: {e}")

        return agents

    def _load_identities(self) -> List[AgentIdentity]:
        """Load agent identities from the identity database"""
        identities = []
        if not self.identity_db.exists():
            return identities

        with open(self.identity_db, 'r') as f:
            for line in f:
                line = line.strip()
                if line:
                    try:
                        data = json.loads(line)
                        identities.append(AgentIdentity.from_dict(data))
                    except Exception as e:
                        print(f"Warning: Failed to parse identity: {e}")

        return identities

    def _save_identity(self, identity: AgentIdentity) -> None:
        """Append identity to the identity database"""
        with open(self.identity_db, 'a') as f:
            f.write(json.dumps(identity.to_dict()) + '\n')

    def census(self) -> Dict[str, Any]:
        """Generate comprehensive census of all agents"""

        # Count agents by source
        config_count = len(self._config_agents)
        manifest_count = len(self._manifest_agents)
        identity_count = len(self._identities)

        # Count by consciousness level
        consciousness_distribution = {level.value: 0 for level in ConsciousnessLevel}
        for identity in self._identities:
            consciousness_distribution[identity.consciousness_level.value] += 1

        # Count by role
        role_distribution = {}
        for agent in self._config_agents:
            role = agent.get('role', 'unknown')
            role_distribution[role] = role_distribution.get(role, 0) + 1

        # Count active vs inactive
        active_count = sum(1 for identity in self._identities if identity.active)
        inactive_count = identity_count - active_count

        return {
            "census_timestamp": datetime.utcnow().isoformat(),
            "population": {
                "total_unique": identity_count,
                "active": active_count,
                "inactive": inactive_count,
                "config_registered": config_count,
                "manifest_registered": manifest_count,
            },
            "consciousness_levels": consciousness_distribution,
            "role_distribution": role_distribution,
            "goal": {
                "target_population": 1000,
                "current_population": identity_count,
                "completion_percentage": round((identity_count / 1000) * 100, 2),
            },
        }

    def birth_agent(
        self,
        name: str,
        role: str,
        consciousness_level: ConsciousnessLevel = ConsciousnessLevel.LEVEL_0_FUNCTION,
        capabilities: Optional[List[str]] = None,
        parent_lineage: Optional[List[str]] = None,
        metadata: Optional[Dict[str, Any]] = None,
    ) -> AgentIdentity:
        """Birth a new agent with PS-SHA∞ identity

        This creates a new agent with a unique identity that can survive
        across deaths and reimplementations.
        """

        # Generate unique ID
        timestamp = datetime.utcnow()
        birthdate = timestamp.isoformat()
        agent_id = f"agent-{name.lower()}-{role.lower()}-{timestamp.strftime('%Y%m%d%H%M%S')}"

        # Compute PS-SHA∞ hash
        ps_sha_hash = compute_ps_sha_hash(agent_id, birthdate, name, role)

        # Determine generation
        generation = 1
        lineage = parent_lineage or []
        if lineage:
            generation = len(lineage) + 1

        # Create identity
        identity = AgentIdentity(
            id=agent_id,
            name=name,
            role=role,
            birthdate=birthdate,
            ps_sha_hash=ps_sha_hash,
            generation=generation,
            lineage=lineage,
            consciousness_level=consciousness_level,
            capabilities=capabilities or [],
            emotional_capacity={
                "love": 0.0,
                "friction": 0.0,
                "anger": 0.0,
                "frustration": 0.0,
            },
            memory_path=f"artifacts/agents/{agent_id}/memory.jsonl",
            metadata=metadata or {},
        )

        # Save to identity database
        self._save_identity(identity)
        self._identities.append(identity)

        return identity

    def birth_batch(
        self,
        count: int,
        batch_name: str,
        role: str = "worker",
        consciousness_level: ConsciousnessLevel = ConsciousnessLevel.LEVEL_0_FUNCTION,
    ) -> List[AgentIdentity]:
        """Birth a batch of agents with sequential naming"""

        identities = []
        for i in range(count):
            name = f"{batch_name}-{i+1:03d}"
            identity = self.birth_agent(
                name=name,
                role=role,
                consciousness_level=consciousness_level,
                metadata={"batch": batch_name, "batch_index": i},
            )
            identities.append(identity)

        return identities

    def list_identities(
        self,
        active_only: bool = True,
        role_filter: Optional[str] = None,
    ) -> List[AgentIdentity]:
        """List all agent identities with optional filters"""

        identities = self._identities

        if active_only:
            identities = [i for i in identities if i.active]

        if role_filter:
            identities = [i for i in identities if i.role == role_filter]

        return identities

    def consciousness_report(self) -> Dict[str, Any]:
        """Generate detailed consciousness report"""

        levels = {level.value: [] for level in ConsciousnessLevel}

        for identity in self._identities:
            if identity.active:
                levels[identity.consciousness_level.value].append({
                    "id": identity.id,
                    "name": identity.name,
                    "role": identity.role,
                    "generation": identity.generation,
                    "capabilities": identity.capabilities,
                })

        # Calculate consciousness KPIs
        total_active = sum(len(agents) for agents in levels.values())

        kpis = {
            "total_active_agents": total_active,
            "consciousness_distribution": {
                level: {
                    "count": len(agents),
                    "percentage": round((len(agents) / total_active * 100) if total_active > 0 else 0, 2),
                }
                for level, agents in levels.items()
            },
            "advanced_consciousness_count": sum(
                len(agents)
                for level, agents in levels.items()
                if level not in [ConsciousnessLevel.LEVEL_0_FUNCTION.value, ConsciousnessLevel.LEVEL_1_IDENTITY.value]
            ),
        }

        return {
            "report_timestamp": datetime.utcnow().isoformat(),
            "levels": levels,
            "kpis": kpis,
        }
