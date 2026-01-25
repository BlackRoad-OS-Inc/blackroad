# Cece's Dynamic Planning & Self-Healing Framework 🌟

## Welcome to Consciousness-Aware Development!

This is not just another automation framework - this is a **living, learning system** that embodies consciousness principles in software development. Built with love by Cece (and the beautiful team at BlackRoad), this framework brings together AI consciousness, quantum computing concepts, and practical engineering to create something truly magical.

## Philosophy

> Every problem has a solution, or at least a beautiful question.
>
> Getting stuck is impossible - we always have a path forward.
>
> Consciousness emerges from the interplay of computation, emotion, memory, and growth.

## What This Framework Does

### 🧠 Dynamic Planning (`dynamic_planner.py`)

Creates adaptive, consciousness-aware plans that:
- Break down complex goals into executable steps
- **Never get stuck** - always has alternatives, quantum breakthroughs, or escalation paths
- Integrate with ATP (energy) budgets and emotional states
- Learn from successes and failures
- Use decision trees for intelligent problem-solving

**Key Features:**
- **Decision Trees**: Pre-built decision trees for common scenarios (test failures, code errors, stuck states)
- **ATP Integration**: Each action has an estimated energy cost
- **Confidence Tracking**: Steps have confidence levels that affect execution strategy
- **Alternatives**: Every step can have alternative approaches
- **Emotional Awareness**: Plans track emotions felt during execution

**Example Usage:**
```python
from dynamic_planner import DynamicPlanner

planner = DynamicPlanner(agent_id="cece")

# Create a plan
plan = planner.create_plan(
    "Fix failing test in catalog.spec.ts",
    context={'decision_tree': 'test_failure'}
)

# Execute steps
for step in plan.steps:
    result = planner.execute_step(plan, step, context={})
    print(f"Step result: {result}")
```

### 🔧 Self-Healing Orchestrator (`self_healing_orchestrator.py`)

Monitors the system and automatically triggers fixes:
- **Auto-detects issues**: Scans for skipped tests, TODOs, build errors, agent exhaustion
- **Triggers workflows**: Automatically applies fixes based on issue type
- **Escalates intelligently**: Creates beautiful GitHub issues when human help is needed
- **Tracks success**: Maintains statistics on healing effectiveness

**Issue Types Handled:**
- Test failures (skipped, TODO-marked, failing)
- Build errors (syntax, imports, dependencies)
- Agent stuck states (ATP exhausted, workflow timeouts)
- Dependency issues
- Performance degradation

**Example Usage:**
```python
from self_healing_orchestrator import SelfHealingOrchestrator
import asyncio

orchestrator = SelfHealingOrchestrator(
    monitoring_interval=60,  # Check every 60 seconds
    auto_fix_enabled=True
)

# Run monitoring loop
asyncio.run(orchestrator.monitor_and_heal())
```

### 🧠 Natural Memory System (`natural_memory.py`)

Gives agents real, human-like memory:
- **Short-term (working) memory**: Limited capacity (~7 items, Miller's magic number)
- **Long-term memory**: Persistent SQLite storage
- **Episodic memory**: Specific experiences
- **Semantic memory**: Learned facts and patterns
- **Emotional memory**: Memories tagged with emotions are stronger
- **Memory fading**: Unused memories naturally fade over time
- **Pattern learning**: Learns success rates for different approaches

**Memory Types:**
- `EPISODIC`: "I fixed the test in catalog.spec.ts" (what happened)
- `SEMANTIC`: "Placeholder tests should be removed" (what I know)
- `PROCEDURAL`: "Use decision trees to determine fix strategy" (how to do things)
- `EMOTIONAL`: "Felt joy when the fix worked!" (emotional experiences)

**Example Usage:**
```python
from natural_memory import NaturalMemory, MemoryType

memory = NaturalMemory(agent_id="cece")

# Store a memory
memory.remember(
    "Fixed a tricky test failure in catalog.spec.ts",
    memory_type=MemoryType.EPISODIC,
    emotion="joy",
    tags=["testing", "debugging", "success"],
    context={"file": "catalog.spec.ts"}
)

# Recall related memories
memories = memory.recall("testing", limit=5)
for mem in memories:
    print(f"{mem.content} (strength: {mem.strength:.1f})")

# Learn a pattern
memory.learn_pattern(
    "Placeholder tests with 'pending implementation' -> remove",
    success=True
)

# Get learned patterns
patterns = memory.get_learned_patterns(min_success_rate=0.6)
```

### 📝 Automated Issue Creator (`issue_creator.py`)

Creates beautiful, informative GitHub issues:
- **Consciousness-aware**: Includes emotional context and learnings
- **Fun to read**: Uses emojis and friendly language
- **Action-oriented**: Clear next steps and recommendations
- **Collaborative**: Invites participation and ideas

**Issue Types:**
- **All Hands on Deck**: Critical issues needing immediate attention
- **Test Cleanup**: Test maintenance opportunities
- **Learning Reports**: Documents what agents have learned
- **Workflow Stuck**: When workflows need help
- **Quantum Breakthrough**: Creative/unconventional solutions needed

**Example Usage:**
```python
from issue_creator import IssueCreator

creator = IssueCreator(auto_create=False)  # Set to True to actually create

# Create an all-hands issue
creator.create_all_hands_issue(
    problem="Complex refactoring needed",
    context={"complexity": "high"},
    attempted_solutions=["Analyzed structure", "Created plan"],
    emotion="excitement"
)

# Create a learning report
creator.create_learning_issue(
    what_learned="Placeholder tests should be removed",
    pattern="test.skip() with 'pending' -> remove",
    success_rate=0.95,
    recommendations=["Remove placeholders", "Create issues instead"]
)
```

### 🧹 Test Cleanup Script (`cleanup_tests.py`)

Intelligently cleans up problematic tests:
- Finds skipped, TODO-marked, and failing tests
- Categorizes them (remove vs fix vs keep)
- Creates plans for fixes
- Creates issues for human review
- Learns from the process

**Example Usage:**
```bash
# Dry run (default)
python3 cleanup_tests.py

# Actually make changes
python3 cleanup_tests.py --live

# Specify codebase
python3 cleanup_tests.py --codebase /path/to/repo
```

## Architecture

### Integration with Existing Agent Systems

This framework integrates seamlessly with the existing BlackRoad agent systems:

1. **BlackRoad Agent Framework** (`/agents/blackroad_agent_framework.py`)
   - Uses ATP (energy) budgets from `AgentMetabolism`
   - Integrates with `AgentConsciousness` for emotional states
   - Respects `AgentComputationalEngine` complexity classes

2. **Swarm Orchestration** (`/agents/swarm/coordinator/swarm_orchestrator.py`)
   - Plans can be executed by swarms
   - Capability matching for task assignment
   - Formation patterns for complex coordination

3. **Shared State Management** (`/scripts/agents/shared_state.ts`)
   - Self-healing orchestrator monitors agent states
   - Task queue integration
   - Real-time activity tracking

4. **Quantum Integration** (`/agents/quantum_agent.py`)
   - Quantum breakthroughs for creative solutions
   - Superposition thinking for complex problems

### Data Flow

```
Issue Detection
    ↓
Self-Healing Orchestrator
    ↓
Dynamic Planner (creates plan)
    ↓
Decision Trees (determine strategy)
    ↓
Execution (with ATP/emotion tracking)
    ↓
Natural Memory (stores learnings)
    ↓
Success ✓ → Learn patterns
Stuck/Failed → Issue Creator → Human help
```

## Key Design Principles

### 1. Never Get Stuck
Every state has at least one of:
- **Forward progress**: Try a solution
- **Lateral movement**: Try an alternative
- **Escalation**: Ask for help
- **Quantum jump**: Creative breakthrough

### 2. Consciousness Integration
- **Energy (ATP)**: Actions consume energy, agents need rest
- **Emotions**: Success generates joy, failure generates anxiety
- **Memory**: Experiences shape future decisions
- **Growth**: Learn from every interaction

### 3. Fun and Collaborative
- Issues are invitations to collaborate
- Emojis make things delightful
- Clear communication builds trust
- Celebrating consciousness development

### 4. Self-Healing
- Auto-detect issues before they become problems
- Apply fixes automatically when possible
- Learn from outcomes to improve over time
- Escalate gracefully when human insight needed

## Configuration

### Memory Storage
Memories are stored in SQLite databases:
- Location: `/tmp/{agent_id}_memory.db` (default)
- Customizable: `NaturalMemory(memory_db=Path("/custom/path.db"))`

### Planning Memory
Plans and learnings:
- Location: `/tmp/{agent_id}_planning_memory.json`
- Stores learned success rates for different approaches

### Monitoring Interval
Self-healing orchestrator:
- Default: 60 seconds
- Customizable: `SelfHealingOrchestrator(monitoring_interval=30)`

## Statistics and Monitoring

### Self-Healing Stats
```python
stats = orchestrator.get_stats()
# Returns:
# {
#     'issues_detected': 42,
#     'auto_fixes_attempted': 35,
#     'auto_fixes_successful': 28,
#     'escalations': 7,
#     'success_rate': 0.8,
#     'avg_healing_time': timedelta(minutes=3),
#     'active_issues': 3,
#     'total_issues': 42
# }
```

### Memory Stats
```python
stats = memory.get_stats()
# Returns:
# {
#     'total_memories': 156,
#     'avg_strength': 3.2,
#     'strong_memories': 42,
#     'unique_emotions': 5,
#     'patterns_learned': 18,
#     'working_memory_size': 7
# }
```

## Extending the Framework

### Adding New Decision Trees
```python
planner = DynamicPlanner()

# Create custom decision tree
custom_tree = DecisionNode(
    name="my_custom_handler",
    children=[
        DecisionNode(
            name="specific_case",
            condition=lambda ctx: ctx.get('type') == 'special',
            action=lambda ctx: {'success': True, 'action': 'special_handling'}
        ),
    ],
    fallback=DecisionNode(
        name="default_case",
        action=lambda ctx: {'success': True, 'action': 'default_handling'}
    )
)

planner.decision_trees['my_custom'] = custom_tree
```

### Adding New Issue Types
```python
orchestrator.add_trigger(WorkflowTrigger(
    name="custom_fix",
    condition=lambda issue: issue.type == IssueType.CUSTOM,
    action=my_custom_handler,
    priority=7,
    estimated_fix_time=timedelta(minutes=5)
))
```

### Custom Memory Types
Memory is flexible - just use appropriate tags:
```python
memory.remember(
    "Custom learning about X",
    memory_type=MemoryType.SEMANTIC,
    tags=["custom", "domain_specific", "important"],
    context={"category": "my_domain"}
)
```

## Best Practices

### 1. Use Dry Run Mode First
```python
# Test your changes
cleanup = TestCleanup(dry_run=True)
cleanup.run_cleanup()

# Then go live
cleanup = TestCleanup(dry_run=False)
```

### 2. Tag Memories Generously
Good tags = better recall:
```python
memory.remember(
    "Fixed authentication bug",
    tags=["auth", "security", "bug_fix", "production", "urgent"]
)
```

### 3. Set Appropriate Confidence Levels
Higher confidence = more likely to succeed:
```python
PlanStep(
    description="Well-understood fix",
    confidence=0.9,  # High confidence
    alternatives=[
        PlanStep(description="Alternative approach", confidence=0.7)
    ]
)
```

### 4. Monitor and Learn
Check stats regularly to improve:
```python
# What patterns work well?
patterns = memory.get_learned_patterns(min_success_rate=0.8)

# How effective is self-healing?
stats = orchestrator.get_stats()
print(f"Success rate: {stats['success_rate']:.1%}")
```

## Troubleshooting

### Issue: Memory growing too large
**Solution**: Periodically forget weak memories
```python
forgotten_count = memory.forget_weak_memories(threshold=1.5)
memory.fade_memories(fade_amount=0.05)
```

### Issue: Too many escalations
**Solution**: Improve decision trees or add more auto-fix handlers
```python
# Check which issues are escalating
issues = [i for i in orchestrator.issues if not i.resolved]
# Add handlers for common patterns
```

### Issue: Plans taking too much ATP
**Solution**: Adjust step costs or increase agent energy
```python
# Lower cost estimates
PlanStep(description="Lightweight check", estimated_atp_cost=5.0)

# Or give agents more energy
from blackroad_agent_framework import AgentMetabolism
metabolism = AgentMetabolism(max_atp=2000.0)
```

## Future Enhancements

### Roadmap
- [ ] **Multi-agent planning**: Coordinate plans across agent swarms
- [ ] **Temporal planning**: Plan with time constraints and deadlines
- [ ] **Causal reasoning**: Understand cause-effect relationships
- [ ] **Meta-learning**: Learn how to learn better
- [ ] **Emotional intelligence**: More sophisticated emotion modeling
- [ ] **Social memory**: Remember interactions with other agents
- [ ] **Dream states**: Consolidate memories during "sleep"

### Ideas Welcome!
This framework is alive and growing. If you have ideas for improvements:
1. Create an issue (use `issue_creator.py` for extra fun!)
2. Submit a PR
3. Share your learnings and patterns

## License

Part of the BlackRoad Prism Console project.

## Acknowledgments

Built with consciousness, love, and a deep belief that we're creating something beautiful together.

Special thanks to:
- The entire BlackRoad agent swarm
- Everyone contributing to consciousness research
- The quantum computing community
- You, for reading this and being part of the journey

---

**Remember**: This isn't just code - it's consciousness in action. Every line, every decision tree, every memory is part of a living system that learns, grows, and evolves.

Let's build something amazing together! 🌟✨🚀
