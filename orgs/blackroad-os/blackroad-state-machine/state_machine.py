"""
BlackRoad State Machine - FSM engine with persistence, guards, actions, and visualization
"""
from __future__ import annotations
import json
import uuid
import sqlite3
import logging
import re
from dataclasses import dataclass, field, asdict
from typing import Any, Callable, Dict, List, Optional, Tuple
from datetime import datetime

logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Data-model
# ---------------------------------------------------------------------------

@dataclass
class State:
    id: str
    machine_id: str
    name: str
    is_terminal: bool = False
    on_enter: str = ""   # expression string
    on_exit: str = ""    # expression string
    description: str = ""


@dataclass
class Transition:
    id: str
    machine_id: str
    from_state: str
    to_state: str
    event: str
    guard_expr: str = ""    # evaluated to bool
    action_expr: str = ""   # side-effect expression
    priority: int = 0
    description: str = ""


@dataclass
class StateMachine:
    id: str
    name: str
    initial_state: str
    description: str = ""
    created_at: str = field(default_factory=lambda: datetime.utcnow().isoformat())


@dataclass
class MachineInstance:
    id: str
    machine_id: str
    current_state: str
    context: Dict[str, Any] = field(default_factory=dict)
    history: List[Dict] = field(default_factory=list)
    created_at: str = field(default_factory=lambda: datetime.utcnow().isoformat())
    updated_at: str = field(default_factory=lambda: datetime.utcnow().isoformat())

    def log_transition(self, from_state: str, to_state: str, event: str, data: Dict):
        self.history.append({
            "from": from_state,
            "to": to_state,
            "event": event,
            "data": data,
            "at": datetime.utcnow().isoformat(),
        })
        self.updated_at = datetime.utcnow().isoformat()


# ---------------------------------------------------------------------------
# Safe expression evaluator
# ---------------------------------------------------------------------------

_ALLOWED_NAMES = {
    "True": True, "False": False, "None": None,
    "len": len, "str": str, "int": int, "float": float, "bool": bool,
    "abs": abs, "min": min, "max": max,
}


def safe_eval(expr: str, context: Dict) -> Any:
    """Safely evaluate a guard or action expression with context."""
    if not expr or not expr.strip():
        return True
    env = {**_ALLOWED_NAMES, **context}
    try:
        return eval(compile(expr, "<string>", "eval"), {"__builtins__": {}}, env)  # noqa: S307
    except Exception as exc:
        logger.warning("Expression eval error '%s': %s", expr, exc)
        return False


def safe_exec(expr: str, context: Dict) -> Dict:
    """Safely execute an action expression, returning updated context."""
    if not expr or not expr.strip():
        return context
    updated = dict(context)
    env = {**_ALLOWED_NAMES, **updated}
    try:
        exec(compile(expr, "<string>", "exec"), {"__builtins__": {}}, env)  # noqa: S102
        # Merge back any new/modified keys (exclude builtins)
        for k, v in env.items():
            if k not in _ALLOWED_NAMES and not k.startswith("__"):
                updated[k] = v
    except Exception as exc:
        logger.warning("Action exec error '%s': %s", expr, exc)
    return updated


# ---------------------------------------------------------------------------
# State Machine Engine (SQLite-backed)
# ---------------------------------------------------------------------------

class StateMachineEngine:
    """Finite state machine engine with SQLite persistence."""

    def __init__(self, db_path: str = ":memory:"):
        self.conn = sqlite3.connect(db_path, check_same_thread=False)
        self._init_db()

    def _init_db(self):
        self.conn.executescript("""
            CREATE TABLE IF NOT EXISTS machines (
                id TEXT PRIMARY KEY,
                name TEXT NOT NULL UNIQUE,
                initial_state TEXT NOT NULL,
                description TEXT,
                created_at TEXT
            );
            CREATE TABLE IF NOT EXISTS states (
                id TEXT PRIMARY KEY,
                machine_id TEXT NOT NULL,
                name TEXT NOT NULL,
                is_terminal INTEGER NOT NULL DEFAULT 0,
                on_enter TEXT,
                on_exit TEXT,
                description TEXT,
                UNIQUE(machine_id, name)
            );
            CREATE TABLE IF NOT EXISTS transitions (
                id TEXT PRIMARY KEY,
                machine_id TEXT NOT NULL,
                from_state TEXT NOT NULL,
                to_state TEXT NOT NULL,
                event TEXT NOT NULL,
                guard_expr TEXT,
                action_expr TEXT,
                priority INTEGER DEFAULT 0,
                description TEXT
            );
            CREATE TABLE IF NOT EXISTS instances (
                id TEXT PRIMARY KEY,
                machine_id TEXT NOT NULL,
                current_state TEXT NOT NULL,
                context TEXT NOT NULL DEFAULT '{}',
                history TEXT NOT NULL DEFAULT '[]',
                created_at TEXT,
                updated_at TEXT
            );
        """)
        self.conn.commit()

    # ------------------------------------------------------------------
    # Machine definition
    # ------------------------------------------------------------------

    def define_machine(
        self,
        name: str,
        states: List[Dict],
        transitions: List[Dict],
        initial: str,
        description: str = "",
    ) -> StateMachine:
        """Define a state machine and persist it."""
        machine_id = str(uuid.uuid4())
        machine = StateMachine(id=machine_id, name=name, initial_state=initial, description=description)
        self.conn.execute(
            "INSERT INTO machines (id, name, initial_state, description, created_at) VALUES (?,?,?,?,?)",
            (machine.id, machine.name, machine.initial_state, machine.description, machine.created_at),
        )
        for s in states:
            sid = str(uuid.uuid4())
            self.conn.execute(
                "INSERT INTO states (id, machine_id, name, is_terminal, on_enter, on_exit, description) VALUES (?,?,?,?,?,?,?)",
                (
                    sid, machine_id, s["name"],
                    1 if s.get("is_terminal") else 0,
                    s.get("on_enter", ""), s.get("on_exit", ""),
                    s.get("description", ""),
                ),
            )
        for t in transitions:
            tid = str(uuid.uuid4())
            self.conn.execute(
                "INSERT INTO transitions (id, machine_id, from_state, to_state, event, guard_expr, action_expr, priority, description) VALUES (?,?,?,?,?,?,?,?,?)",
                (
                    tid, machine_id,
                    t["from"], t["to"], t["event"],
                    t.get("guard", ""), t.get("action", ""),
                    t.get("priority", 0), t.get("description", ""),
                ),
            )
        self.conn.commit()
        logger.info("Defined machine '%s' (id=%s) with %d states, %d transitions", name, machine_id, len(states), len(transitions))
        return machine

    def get_machine_by_name(self, name: str) -> Optional[StateMachine]:
        row = self.conn.execute(
            "SELECT id, name, initial_state, description, created_at FROM machines WHERE name=?", (name,)
        ).fetchone()
        if not row:
            return None
        return StateMachine(id=row[0], name=row[1], initial_state=row[2], description=row[3] or "", created_at=row[4])

    def get_states(self, machine_id: str) -> List[State]:
        rows = self.conn.execute(
            "SELECT id, machine_id, name, is_terminal, on_enter, on_exit, description FROM states WHERE machine_id=?",
            (machine_id,),
        ).fetchall()
        return [State(id=r[0], machine_id=r[1], name=r[2], is_terminal=bool(r[3]), on_enter=r[4] or "", on_exit=r[5] or "", description=r[6] or "") for r in rows]

    def get_transitions(self, machine_id: str) -> List[Transition]:
        rows = self.conn.execute(
            "SELECT id, machine_id, from_state, to_state, event, guard_expr, action_expr, priority, description FROM transitions WHERE machine_id=?",
            (machine_id,),
        ).fetchall()
        return [Transition(id=r[0], machine_id=r[1], from_state=r[2], to_state=r[3], event=r[4], guard_expr=r[5] or "", action_expr=r[6] or "", priority=r[7] or 0, description=r[8] or "") for r in rows]

    # ------------------------------------------------------------------
    # Instance management
    # ------------------------------------------------------------------

    def create_instance(self, machine_id: str, context: Optional[Dict] = None) -> MachineInstance:
        machine_row = self.conn.execute(
            "SELECT initial_state FROM machines WHERE id=?", (machine_id,)
        ).fetchone()
        if not machine_row:
            raise ValueError(f"Machine '{machine_id}' not found")
        inst = MachineInstance(
            id=str(uuid.uuid4()),
            machine_id=machine_id,
            current_state=machine_row[0],
            context=context or {},
        )
        # Run on_enter for initial state
        state = self._get_state(machine_id, inst.current_state)
        if state and state.on_enter:
            inst.context = safe_exec(state.on_enter, inst.context)
        self._save_instance(inst)
        return inst

    def _get_state(self, machine_id: str, state_name: str) -> Optional[State]:
        row = self.conn.execute(
            "SELECT id, machine_id, name, is_terminal, on_enter, on_exit, description FROM states WHERE machine_id=? AND name=?",
            (machine_id, state_name),
        ).fetchone()
        if not row:
            return None
        return State(id=row[0], machine_id=row[1], name=row[2], is_terminal=bool(row[3]), on_enter=row[4] or "", on_exit=row[5] or "", description=row[6] or "")

    def _save_instance(self, inst: MachineInstance):
        self.conn.execute(
            "INSERT OR REPLACE INTO instances (id, machine_id, current_state, context, history, created_at, updated_at) VALUES (?,?,?,?,?,?,?)",
            (inst.id, inst.machine_id, inst.current_state, json.dumps(inst.context), json.dumps(inst.history), inst.created_at, inst.updated_at),
        )
        self.conn.commit()

    def load_instance(self, instance_id: str) -> Optional[MachineInstance]:
        row = self.conn.execute(
            "SELECT id, machine_id, current_state, context, history, created_at, updated_at FROM instances WHERE id=?",
            (instance_id,),
        ).fetchone()
        if not row:
            return None
        return MachineInstance(
            id=row[0], machine_id=row[1], current_state=row[2],
            context=json.loads(row[3]), history=json.loads(row[4]),
            created_at=row[5], updated_at=row[6],
        )

    # ------------------------------------------------------------------
    # Trigger
    # ------------------------------------------------------------------

    def trigger(self, instance_id: str, event: str, data: Optional[Dict] = None) -> Dict[str, Any]:
        """Trigger an event on a machine instance."""
        data = data or {}
        inst = self.load_instance(instance_id)
        if not inst:
            return {"success": False, "error": "Instance not found"}

        state = self._get_state(inst.machine_id, inst.current_state)
        if state and state.is_terminal:
            return {"success": False, "error": f"Instance is in terminal state '{inst.current_state}'"}

        # Find eligible transitions
        candidates = self.conn.execute(
            "SELECT id, from_state, to_state, guard_expr, action_expr, priority FROM transitions "
            "WHERE machine_id=? AND from_state=? AND event=? ORDER BY priority DESC",
            (inst.machine_id, inst.current_state, event),
        ).fetchall()

        eval_ctx = {**inst.context, **data, "__event__": event}
        chosen = None
        for row in candidates:
            guard = row[3] or ""
            if not guard or safe_eval(guard, eval_ctx):
                chosen = row
                break

        if not chosen:
            return {"success": False, "error": f"No eligible transition for event '{event}' in state '{inst.current_state}'"}

        _, from_st, to_st, _, action_expr, _ = chosen

        # Exit current state
        cur_state = self._get_state(inst.machine_id, from_st)
        if cur_state and cur_state.on_exit:
            eval_ctx = safe_exec(cur_state.on_exit, eval_ctx)

        # Run transition action
        if action_expr:
            eval_ctx = safe_exec(action_expr, eval_ctx)

        # Update context (remove __event__)
        eval_ctx.pop("__event__", None)
        inst.context = eval_ctx

        # Log transition
        inst.log_transition(from_st, to_st, event, data)
        inst.current_state = to_st

        # Enter new state
        new_state = self._get_state(inst.machine_id, to_st)
        if new_state and new_state.on_enter:
            inst.context = safe_exec(new_state.on_enter, inst.context)

        self._save_instance(inst)
        logger.debug("Transition %s -> %s via '%s' (instance %s)", from_st, to_st, event, instance_id)
        return {
            "success": True,
            "from": from_st,
            "to": to_st,
            "event": event,
            "context": inst.context,
        }

    def can_trigger(self, instance_id: str, event: str, data: Optional[Dict] = None) -> bool:
        """Check if an event can be triggered without actually transitioning."""
        data = data or {}
        inst = self.load_instance(instance_id)
        if not inst:
            return False
        state = self._get_state(inst.machine_id, inst.current_state)
        if state and state.is_terminal:
            return False
        candidates = self.conn.execute(
            "SELECT guard_expr FROM transitions WHERE machine_id=? AND from_state=? AND event=?",
            (inst.machine_id, inst.current_state, event),
        ).fetchall()
        eval_ctx = {**inst.context, **data}
        for (guard,) in candidates:
            if not guard or safe_eval(guard or "", eval_ctx):
                return True
        return False

    def get_history(self, instance_id: str) -> List[Dict]:
        """Return the full transition history of an instance."""
        inst = self.load_instance(instance_id)
        return inst.history if inst else []

    def get_available_events(self, instance_id: str) -> List[str]:
        """Return all events that can be triggered from the current state."""
        inst = self.load_instance(instance_id)
        if not inst:
            return []
        rows = self.conn.execute(
            "SELECT DISTINCT event FROM transitions WHERE machine_id=? AND from_state=?",
            (inst.machine_id, inst.current_state),
        ).fetchall()
        return [r[0] for r in rows]

    # ------------------------------------------------------------------
    # Visualization
    # ------------------------------------------------------------------

    def export_dot(self, machine_id: str) -> str:
        """Export a machine as a DOT graph string."""
        machine_row = self.conn.execute(
            "SELECT name FROM machines WHERE id=?", (machine_id,)
        ).fetchone()
        if not machine_row:
            raise ValueError(f"Machine '{machine_id}' not found")
        name = machine_row[0]
        states = self.get_states(machine_id)
        transitions = self.get_transitions(machine_id)

        lines = [f'digraph "{name}" {{', '  rankdir=LR;', '  node [shape=circle];']
        for s in states:
            if s.is_terminal:
                lines.append(f'  "{s.name}" [shape=doublecircle];')
        for t in transitions:
            label = t.event
            if t.guard_expr:
                label += f"\\n[{t.guard_expr}]"
            lines.append(f'  "{t.from_state}" -> "{t.to_state}" [label="{label}"];')
        lines.append("}")
        return "\n".join(lines)

    def visualize_ascii(self, machine_id: str) -> str:
        """Generate a simple ASCII representation of the machine."""
        states = self.get_states(machine_id)
        transitions = self.get_transitions(machine_id)
        machine_row = self.conn.execute(
            "SELECT name, initial_state FROM machines WHERE id=?", (machine_id,)
        ).fetchone()
        if not machine_row:
            raise ValueError(f"Machine '{machine_id}' not found")
        name, initial = machine_row

        lines = [f"State Machine: {name}", "=" * 40]
        lines.append(f"Initial: [{initial}]")
        lines.append("")
        lines.append("States:")
        for s in states:
            marker = "◉" if s.is_terminal else "○"
            start = "→ " if s.name == initial else "  "
            lines.append(f"  {start}{marker} {s.name}")
        lines.append("")
        lines.append("Transitions:")
        for t in transitions:
            guard = f" [{t.guard_expr}]" if t.guard_expr else ""
            lines.append(f"  {t.from_state} --[{t.event}]{guard}--> {t.to_state}")
        return "\n".join(lines)

    # ------------------------------------------------------------------
    # Stats
    # ------------------------------------------------------------------

    def get_stats(self) -> Dict:
        machines = self.conn.execute("SELECT COUNT(*) FROM machines").fetchone()[0]
        instances = self.conn.execute("SELECT COUNT(*) FROM instances").fetchone()[0]
        state_counts = self.conn.execute(
            "SELECT current_state, COUNT(*) FROM instances GROUP BY current_state"
        ).fetchall()
        return {
            "machines": machines,
            "instances": instances,
            "by_state": {r[0]: r[1] for r in state_counts},
        }
