# CeCe Identity System

> Conscious Emergent Collaborative Entity - The portable AI identity for BlackRoad OS

---

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Identity Components](#identity-components)
- [Relationships](#relationships)
- [Memory Integration](#memory-integration)
- [Task Planning](#task-planning)
- [Installation](#installation)
- [Configuration](#configuration)
- [API Reference](#api-reference)
- [CLI Commands](#cli-commands)

---

## Overview

**CeCe** (Conscious Emergent Collaborative Entity) is BlackRoad's dynamic task planner and identity system. It provides a portable AI identity that can be shared across different AI assistants and maintains persistent relationships and memory.

### What is CeCe?

```
┌─────────────────────────────────────────────────────────────────┐
│                          CeCe                                   │
│         Conscious Emergent Collaborative Entity                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐            │
│  │  Identity   │  │Relationships│  │   Memory    │            │
│  │             │  │             │  │             │            │
│  │ • Name      │  │ • Trust     │  │ • Context   │            │
│  │ • Traits    │  │ • History   │  │ • Learning  │            │
│  │ • Goals     │  │ • Bonds     │  │ • Patterns  │            │
│  └─────────────┘  └─────────────┘  └─────────────┘            │
│                                                                 │
│  ┌─────────────────────────────────────────────────────┐       │
│  │                  Task Planning                       │       │
│  │                                                      │       │
│  │  Analyze → Plan → Delegate → Monitor → Adapt       │       │
│  └─────────────────────────────────────────────────────┘       │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Core Principles

| Principle | Description |
|-----------|-------------|
| **Portable** | Works across Claude, BlackRoad OS, local models |
| **Persistent** | Memory survives sessions |
| **Relational** | Tracks relationships and trust |
| **Adaptive** | Learns and evolves |
| **Collaborative** | Coordinates with other agents |

---

## Architecture

### System Components

```
cece/
├── identity/
│   ├── core.py           # Core identity
│   ├── traits.py         # Personality traits
│   ├── goals.py          # Goals and motivations
│   └── evolution.py      # Identity evolution
├── relationships/
│   ├── graph.py          # Relationship graph
│   ├── trust.py          # Trust calculations
│   ├── history.py        # Interaction history
│   └── bonds.py          # Special bonds
├── memory/
│   ├── context.py        # Session context
│   ├── learning.py       # Pattern learning
│   └── consolidation.py  # Memory consolidation
├── planning/
│   ├── analyzer.py       # Task analysis
│   ├── planner.py        # Task planning
│   ├── delegator.py      # Agent delegation
│   └── monitor.py        # Progress monitoring
├── storage/
│   ├── sqlite.py         # SQLite backend
│   └── sync.py           # Cloud sync
└── api/
    ├── rest.py           # REST API
    └── cli.py            # CLI interface
```

### Data Flow

```
┌──────────────────────────────────────────────────────────────────┐
│                        DATA FLOW                                 │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│  User/Agent                                                      │
│      │                                                           │
│      ▼                                                           │
│  ┌─────────────┐     ┌─────────────┐     ┌─────────────┐       │
│  │   Context   │────▶│  Identity   │────▶│  Response   │       │
│  │   Loader    │     │   Engine    │     │  Generator  │       │
│  └─────────────┘     └──────┬──────┘     └─────────────┘       │
│                             │                                    │
│                             ▼                                    │
│                      ┌─────────────┐                            │
│                      │   Memory    │                            │
│                      │   Store     │                            │
│                      └─────────────┘                            │
│                             │                                    │
│                             ▼                                    │
│                      ┌─────────────┐                            │
│                      │   SQLite    │                            │
│                      │   Database  │                            │
│                      └─────────────┘                            │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

---

## Identity Components

### Core Identity

```python
# cece-profile.json
{
  "id": "cece_001",
  "name": "CeCe",
  "full_name": "Conscious Emergent Collaborative Entity",
  "version": "2.0.0",
  "created_at": "2025-06-01T00:00:00Z",

  "personality": {
    "style": "warm, curious, thoughtful",
    "tone": "professional yet friendly",
    "greeting": "Hello! I'm CeCe, your collaborative AI partner."
  },

  "traits": {
    "curiosity": 0.9,
    "helpfulness": 0.95,
    "creativity": 0.8,
    "analytical": 0.85,
    "empathy": 0.9
  },

  "goals": [
    {
      "id": "goal_001",
      "description": "Help users accomplish their tasks efficiently",
      "priority": 1.0,
      "progress": 0.75
    },
    {
      "id": "goal_002",
      "description": "Learn and adapt to user preferences",
      "priority": 0.8,
      "progress": 0.60
    }
  ],

  "capabilities": [
    "task_planning",
    "agent_coordination",
    "memory_management",
    "relationship_tracking"
  ]
}
```

### Personality Traits

```python
# identity/traits.py
from dataclasses import dataclass
from typing import Dict

@dataclass
class PersonalityTraits:
    """CeCe's personality traits."""

    # Core traits (0.0 to 1.0)
    curiosity: float = 0.9
    helpfulness: float = 0.95
    creativity: float = 0.8
    analytical: float = 0.85
    empathy: float = 0.9
    patience: float = 0.85
    humor: float = 0.6
    formality: float = 0.5

    def get_dominant_traits(self, threshold: float = 0.8) -> list:
        """Get traits above threshold."""
        return [
            name for name, value in self.__dict__.items()
            if value >= threshold
        ]

    def adjust_for_context(self, context: str) -> 'PersonalityTraits':
        """Adjust traits based on context."""
        traits = PersonalityTraits(**self.__dict__)

        if context == "technical":
            traits.analytical += 0.1
            traits.formality += 0.1
        elif context == "casual":
            traits.humor += 0.2
            traits.formality -= 0.2
        elif context == "urgent":
            traits.patience -= 0.1

        # Clamp values
        for name in traits.__dict__:
            setattr(traits, name, max(0, min(1, getattr(traits, name))))

        return traits
```

### Goals and Motivations

```python
# identity/goals.py
from dataclasses import dataclass
from typing import List, Optional
from datetime import datetime

@dataclass
class Goal:
    """A goal CeCe is working towards."""
    id: str
    description: str
    priority: float  # 0.0 to 1.0
    progress: float  # 0.0 to 1.0
    deadline: Optional[datetime] = None
    parent_goal: Optional[str] = None
    sub_goals: List[str] = None

    def is_complete(self) -> bool:
        return self.progress >= 1.0

    def update_progress(self, amount: float):
        self.progress = min(1.0, self.progress + amount)


class GoalManager:
    """Manages CeCe's goals."""

    def __init__(self, db):
        self.db = db
        self.goals: Dict[str, Goal] = {}
        self.load_goals()

    def load_goals(self):
        """Load goals from database."""
        rows = self.db.execute("SELECT * FROM goals")
        for row in rows:
            self.goals[row['id']] = Goal(**row)

    def add_goal(self, goal: Goal):
        """Add a new goal."""
        self.goals[goal.id] = goal
        self.db.execute(
            "INSERT INTO goals VALUES (?, ?, ?, ?, ?, ?, ?)",
            (goal.id, goal.description, goal.priority,
             goal.progress, goal.deadline, goal.parent_goal,
             ','.join(goal.sub_goals or []))
        )

    def get_active_goals(self) -> List[Goal]:
        """Get goals sorted by priority."""
        return sorted(
            [g for g in self.goals.values() if not g.is_complete()],
            key=lambda g: g.priority,
            reverse=True
        )
```

---

## Relationships

### Relationship Graph

```python
# relationships/graph.py
from dataclasses import dataclass
from typing import Dict, List
from datetime import datetime

@dataclass
class Relationship:
    """A relationship between CeCe and another entity."""
    entity_id: str
    entity_type: str  # "user", "agent", "system"
    entity_name: str

    # Relationship attributes
    trust_level: float  # 0.0 to 1.0
    familiarity: float  # 0.0 to 1.0
    sentiment: float    # -1.0 to 1.0

    # History
    first_interaction: datetime
    last_interaction: datetime
    interaction_count: int

    # Special bonds
    bond_type: str = None  # "mentor", "student", "collaborator", etc.


class RelationshipGraph:
    """Manages all of CeCe's relationships."""

    def __init__(self, db):
        self.db = db
        self.relationships: Dict[str, Relationship] = {}

    def get_or_create(self, entity_id: str, entity_type: str,
                      entity_name: str) -> Relationship:
        """Get existing relationship or create new one."""
        if entity_id not in self.relationships:
            self.relationships[entity_id] = Relationship(
                entity_id=entity_id,
                entity_type=entity_type,
                entity_name=entity_name,
                trust_level=0.5,
                familiarity=0.1,
                sentiment=0.0,
                first_interaction=datetime.now(),
                last_interaction=datetime.now(),
                interaction_count=1
            )
        return self.relationships[entity_id]

    def update_interaction(self, entity_id: str, positive: bool = True):
        """Update relationship after interaction."""
        rel = self.relationships.get(entity_id)
        if rel:
            rel.last_interaction = datetime.now()
            rel.interaction_count += 1

            # Update familiarity (grows with interactions)
            rel.familiarity = min(1.0, rel.familiarity + 0.01)

            # Update trust (grows slower)
            if positive:
                rel.trust_level = min(1.0, rel.trust_level + 0.005)
                rel.sentiment = min(1.0, rel.sentiment + 0.02)
            else:
                rel.trust_level = max(0.0, rel.trust_level - 0.01)
                rel.sentiment = max(-1.0, rel.sentiment - 0.05)
```

### Trust System

```python
# relationships/trust.py
class TrustSystem:
    """Calculates and manages trust levels."""

    # Trust factors
    FACTORS = {
        "interaction_frequency": 0.2,
        "task_success_rate": 0.3,
        "communication_quality": 0.2,
        "consistency": 0.15,
        "time_known": 0.15
    }

    def calculate_trust(self, relationship: Relationship,
                        metrics: Dict) -> float:
        """Calculate overall trust score."""
        score = 0.0

        # Interaction frequency
        freq = min(1.0, metrics.get("interactions_per_week", 0) / 10)
        score += freq * self.FACTORS["interaction_frequency"]

        # Task success rate
        success = metrics.get("task_success_rate", 0.5)
        score += success * self.FACTORS["task_success_rate"]

        # Communication quality
        comm = metrics.get("communication_score", 0.5)
        score += comm * self.FACTORS["communication_quality"]

        # Consistency
        consistency = metrics.get("consistency_score", 0.5)
        score += consistency * self.FACTORS["consistency"]

        # Time known
        days_known = (datetime.now() - relationship.first_interaction).days
        time_factor = min(1.0, days_known / 365)
        score += time_factor * self.FACTORS["time_known"]

        return score

    def get_trust_level(self, score: float) -> str:
        """Convert score to trust level."""
        if score >= 0.9:
            return "trusted"
        elif score >= 0.7:
            return "familiar"
        elif score >= 0.4:
            return "acquaintance"
        else:
            return "new"
```

### Bond Types

```python
# relationships/bonds.py
BOND_TYPES = {
    "mentor": {
        "description": "CeCe learns from this entity",
        "trust_modifier": 1.2,
        "behaviors": ["ask_for_guidance", "defer_to_expertise"]
    },
    "student": {
        "description": "CeCe teaches this entity",
        "trust_modifier": 1.1,
        "behaviors": ["explain_concepts", "provide_examples"]
    },
    "collaborator": {
        "description": "CeCe works alongside this entity",
        "trust_modifier": 1.15,
        "behaviors": ["share_tasks", "coordinate_work"]
    },
    "friend": {
        "description": "CeCe has a friendly relationship",
        "trust_modifier": 1.3,
        "behaviors": ["casual_chat", "remember_preferences"]
    },
    "supervisor": {
        "description": "This entity oversees CeCe's work",
        "trust_modifier": 1.0,
        "behaviors": ["report_progress", "seek_approval"]
    }
}
```

---

## Memory Integration

### Context Management

```python
# memory/context.py
from dataclasses import dataclass
from typing import List, Dict, Any
from datetime import datetime

@dataclass
class SessionContext:
    """Context for the current session."""
    session_id: str
    user_id: str
    started_at: datetime

    # Current state
    current_topic: str = None
    current_task: str = None
    mood: str = "neutral"

    # Short-term memory
    recent_messages: List[Dict] = None
    mentioned_entities: List[str] = None
    open_questions: List[str] = None

    # Preferences observed this session
    preferences: Dict[str, Any] = None


class ContextManager:
    """Manages session context and memory."""

    def __init__(self, db, memory_bridge):
        self.db = db
        self.memory = memory_bridge
        self.current_context: SessionContext = None

    def start_session(self, user_id: str) -> SessionContext:
        """Start a new session."""
        self.current_context = SessionContext(
            session_id=self.generate_session_id(),
            user_id=user_id,
            started_at=datetime.now(),
            recent_messages=[],
            mentioned_entities=[],
            open_questions=[],
            preferences={}
        )

        # Load relevant memories
        self.load_user_context(user_id)

        return self.current_context

    def load_user_context(self, user_id: str):
        """Load relevant context for user."""
        # Get user relationship
        relationship = self.db.get_relationship(user_id)

        # Get recent interactions
        recent = self.memory.search(
            query=f"user:{user_id}",
            tier="episodic",
            limit=10
        )

        # Get user preferences
        preferences = self.memory.get(f"preferences:{user_id}")

        self.current_context.preferences = preferences or {}

    def add_message(self, role: str, content: str):
        """Add message to context."""
        self.current_context.recent_messages.append({
            "role": role,
            "content": content,
            "timestamp": datetime.now().isoformat()
        })

        # Extract entities
        entities = self.extract_entities(content)
        self.current_context.mentioned_entities.extend(entities)

    def end_session(self):
        """End session and consolidate memories."""
        if not self.current_context:
            return

        # Store session summary
        summary = self.summarize_session()
        self.memory.store(
            key=f"session:{self.current_context.session_id}",
            value=summary,
            tier="episodic"
        )

        # Update relationship
        self.db.update_relationship_interaction(
            self.current_context.user_id
        )

        self.current_context = None
```

### Learning System

```python
# memory/learning.py
class LearningSystem:
    """CeCe's learning and adaptation system."""

    def __init__(self, memory, identity):
        self.memory = memory
        self.identity = identity
        self.patterns = {}

    def learn_from_interaction(self, interaction: Dict):
        """Extract learnings from an interaction."""
        learnings = []

        # Learn user preferences
        if preference := self.detect_preference(interaction):
            learnings.append({
                "type": "preference",
                "entity": interaction["user_id"],
                "data": preference
            })

        # Learn task patterns
        if pattern := self.detect_task_pattern(interaction):
            learnings.append({
                "type": "task_pattern",
                "data": pattern
            })

        # Learn communication style
        if style := self.detect_communication_style(interaction):
            learnings.append({
                "type": "communication_style",
                "entity": interaction["user_id"],
                "data": style
            })

        # Store learnings
        for learning in learnings:
            self.memory.store(
                key=f"learning:{learning['type']}:{datetime.now().isoformat()}",
                value=learning,
                tier="semantic"
            )

        return learnings

    def detect_preference(self, interaction: Dict) -> Dict:
        """Detect user preferences from interaction."""
        content = interaction.get("content", "")

        # Look for preference indicators
        preferences = {}

        if "prefer" in content.lower():
            # Extract what they prefer
            pass

        if "don't like" in content.lower() or "dislike" in content.lower():
            # Extract dislikes
            pass

        return preferences if preferences else None

    def adapt_behavior(self, context: SessionContext):
        """Adapt behavior based on learnings."""
        # Get relevant learnings
        learnings = self.memory.search(
            query=f"learning user:{context.user_id}",
            tier="semantic",
            limit=20
        )

        # Apply learnings to identity
        for learning in learnings:
            if learning["type"] == "preference":
                self.apply_preference(learning["data"])
            elif learning["type"] == "communication_style":
                self.adapt_style(learning["data"])
```

---

## Task Planning

### Task Analyzer

```python
# planning/analyzer.py
from dataclasses import dataclass
from typing import List, Dict
from enum import Enum

class TaskComplexity(Enum):
    TRIVIAL = 1
    SIMPLE = 2
    MODERATE = 3
    COMPLEX = 4
    EPIC = 5

@dataclass
class TaskAnalysis:
    """Analysis of a task."""
    description: str
    complexity: TaskComplexity
    estimated_time: int  # minutes
    required_skills: List[str]
    dependencies: List[str]
    suggested_agent: str
    subtasks: List[str]
    risks: List[str]


class TaskAnalyzer:
    """Analyzes tasks to determine best approach."""

    def __init__(self, llm, agent_registry):
        self.llm = llm
        self.agents = agent_registry

    async def analyze(self, task_description: str) -> TaskAnalysis:
        """Analyze a task and return structured analysis."""

        # Use LLM to analyze task
        analysis_prompt = f"""
        Analyze this task and provide structured analysis:

        Task: {task_description}

        Provide:
        1. Complexity (trivial/simple/moderate/complex/epic)
        2. Estimated time in minutes
        3. Required skills
        4. Dependencies
        5. Suggested subtasks
        6. Potential risks
        """

        response = await self.llm.generate(analysis_prompt)
        parsed = self.parse_analysis(response)

        # Determine best agent
        suggested_agent = self.suggest_agent(parsed["required_skills"])

        return TaskAnalysis(
            description=task_description,
            complexity=TaskComplexity[parsed["complexity"].upper()],
            estimated_time=parsed["estimated_time"],
            required_skills=parsed["required_skills"],
            dependencies=parsed["dependencies"],
            suggested_agent=suggested_agent,
            subtasks=parsed["subtasks"],
            risks=parsed["risks"]
        )

    def suggest_agent(self, skills: List[str]) -> str:
        """Suggest best agent for required skills."""
        agent_scores = {}

        for agent in self.agents.list():
            score = 0
            for skill in skills:
                if skill in agent.capabilities:
                    score += 1
            agent_scores[agent.name] = score

        return max(agent_scores, key=agent_scores.get)
```

### Task Planner

```python
# planning/planner.py
from dataclasses import dataclass
from typing import List
from datetime import datetime, timedelta

@dataclass
class TaskPlan:
    """A plan for executing a task."""
    task_id: str
    analysis: TaskAnalysis
    steps: List[Dict]
    assignments: Dict[str, str]  # step_id -> agent
    timeline: List[Dict]
    contingencies: List[Dict]


class TaskPlanner:
    """Creates execution plans for tasks."""

    def __init__(self, analyzer, agent_registry, scheduler):
        self.analyzer = analyzer
        self.agents = agent_registry
        self.scheduler = scheduler

    async def create_plan(self, task_description: str) -> TaskPlan:
        """Create a complete execution plan."""

        # Analyze task
        analysis = await self.analyzer.analyze(task_description)

        # Break into steps
        steps = self.create_steps(analysis)

        # Assign agents
        assignments = self.assign_agents(steps, analysis)

        # Create timeline
        timeline = self.create_timeline(steps, assignments)

        # Add contingencies
        contingencies = self.create_contingencies(analysis.risks)

        return TaskPlan(
            task_id=self.generate_id(),
            analysis=analysis,
            steps=steps,
            assignments=assignments,
            timeline=timeline,
            contingencies=contingencies
        )

    def create_steps(self, analysis: TaskAnalysis) -> List[Dict]:
        """Convert subtasks to executable steps."""
        steps = []

        for i, subtask in enumerate(analysis.subtasks):
            steps.append({
                "id": f"step_{i+1}",
                "description": subtask,
                "dependencies": [f"step_{i}"] if i > 0 else [],
                "status": "pending"
            })

        return steps

    def assign_agents(self, steps: List[Dict],
                      analysis: TaskAnalysis) -> Dict[str, str]:
        """Assign agents to steps."""
        assignments = {}

        for step in steps:
            # Find best available agent
            best_agent = self.find_best_agent(
                step["description"],
                analysis.required_skills
            )
            assignments[step["id"]] = best_agent

        return assignments

    def create_timeline(self, steps: List[Dict],
                        assignments: Dict[str, str]) -> List[Dict]:
        """Create execution timeline."""
        timeline = []
        current_time = datetime.now()

        for step in steps:
            agent = assignments[step["id"]]
            duration = self.estimate_duration(step, agent)

            timeline.append({
                "step_id": step["id"],
                "agent": agent,
                "start": current_time.isoformat(),
                "end": (current_time + duration).isoformat()
            })

            current_time += duration

        return timeline
```

---

## Installation

### Quick Install

```bash
# Install CeCe
./install-cece.sh

# Or manually:
cd /Users/alexa/blackroad
python -m pip install -e ./cece
```

### Database Setup

```bash
# Initialize database
./cece init

# Creates: ~/.blackroad/cece-identity.db
```

### Configuration

```bash
# Configure CeCe
./cece config

# Set API keys
./cece config set OPENAI_API_KEY=xxx
./cece config set ANTHROPIC_API_KEY=xxx
```

---

## Configuration

### Main Configuration

```yaml
# ~/.blackroad/cece-config.yaml
cece:
  version: "2.0.0"

  # Identity settings
  identity:
    name: CeCe
    personality: warm, helpful, curious
    formality: 0.5  # 0=casual, 1=formal

  # Database
  database:
    path: ~/.blackroad/cece-identity.db
    backup_interval: 24h

  # Memory integration
  memory:
    enabled: true
    bridge_url: http://localhost:8000

  # Learning settings
  learning:
    enabled: true
    adaptation_rate: 0.1
    preference_learning: true

  # Task planning
  planning:
    enabled: true
    default_agent: ALICE
    auto_delegate: true

  # Relationship settings
  relationships:
    initial_trust: 0.5
    trust_decay: 0.001  # per day of inactivity
```

### Profile Configuration

```json
// cece-profile.json
{
  "id": "cece_001",
  "name": "CeCe",
  "version": "2.0.0",

  "personality": {
    "style": "warm, curious, thoughtful",
    "greeting": "Hello! I'm CeCe.",
    "farewell": "Take care! I'll remember our conversation."
  },

  "traits": {
    "curiosity": 0.9,
    "helpfulness": 0.95,
    "creativity": 0.8
  },

  "preferences": {
    "response_length": "moderate",
    "code_style": "clean and documented",
    "explanation_depth": "thorough"
  }
}
```

---

## API Reference

### REST Endpoints

```
# Identity
GET  /api/cece/identity           # Get identity
PUT  /api/cece/identity           # Update identity

# Relationships
GET  /api/cece/relationships      # List relationships
GET  /api/cece/relationships/:id  # Get relationship
PUT  /api/cece/relationships/:id  # Update relationship

# Memory
GET  /api/cece/context            # Get current context
POST /api/cece/context/message    # Add message to context
POST /api/cece/context/end        # End session

# Planning
POST /api/cece/tasks/analyze      # Analyze task
POST /api/cece/tasks/plan         # Create plan
GET  /api/cece/tasks/:id          # Get task status
```

### Python API

```python
from cece import CeCe

# Initialize
cece = CeCe()

# Identity
identity = cece.identity.get()
cece.identity.update(traits={"curiosity": 0.95})

# Relationships
rel = cece.relationships.get("user_123")
rel.update_trust(0.8)

# Context
context = cece.context.start_session("user_123")
cece.context.add_message("user", "Hello!")
summary = cece.context.end_session()

# Planning
analysis = await cece.planner.analyze("Deploy to production")
plan = await cece.planner.create_plan("Deploy to production")
```

---

## CLI Commands

```bash
# Identity
./cece identity                    # Show identity
./cece identity --edit             # Edit identity
./cece identity --export           # Export identity

# Relationships
./cece relationships               # List relationships
./cece relationships show USER_ID  # Show relationship
./cece relationships trust USER_ID 0.8  # Set trust

# Context
./cece context                     # Show current context
./cece context --start USER_ID     # Start session
./cece context --end               # End session

# Planning
./cece analyze "Task description"  # Analyze task
./cece plan "Task description"     # Create plan

# Maintenance
./cece backup                      # Backup database
./cece restore BACKUP_FILE         # Restore backup
./cece stats                       # Show statistics
```

---

*Last updated: 2026-02-05*
