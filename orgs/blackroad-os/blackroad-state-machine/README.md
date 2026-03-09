# blackroad-state-machine

> Finite state machine engine with persistence, guards, actions, and visualization — part of the BlackRoad OS developer platform.

## Features

- 🔄 **FSM Engine** — Define machines with states and transitions
- 🛡️ **Guards** — Conditional transitions with safe expression evaluation  
- ⚡ **Actions** — State entry/exit hooks and transition side effects
- 💾 **Persistence** — SQLite-backed machine and instance storage
- 📊 **Visualization** — DOT graph export and ASCII diagrams
- 📜 **History** — Full transition audit trail per instance
- 🔍 **Introspection** — Query available events and current state

## Quick Start

```python
from state_machine import StateMachineEngine

engine = StateMachineEngine()

# Define a traffic light machine
machine = engine.define_machine(
    name="traffic_light",
    states=[
        {"name": "red"},
        {"name": "green"},
        {"name": "yellow"},
    ],
    transitions=[
        {"from": "red", "to": "green", "event": "go"},
        {"from": "green", "to": "yellow", "event": "slow"},
        {"from": "yellow", "to": "red", "event": "stop"},
    ],
    initial="red",
)

# Create an instance
instance = engine.create_instance(machine.id)
print(instance.current_state)  # "red"

# Trigger events
result = engine.trigger(instance.id, "go")
print(result)  # {"success": True, "from": "red", "to": "green", ...}

# Visualize
print(engine.export_dot(machine.id))
print(engine.visualize_ascii(machine.id))
```

## Running Tests

```bash
pip install pytest pytest-cov
pytest tests/ -v --cov=state_machine
```

## License

Proprietary — © BlackRoad OS, Inc.
