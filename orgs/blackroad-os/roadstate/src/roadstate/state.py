"""
RoadState - State Machines for BlackRoad
Finite state machines, transitions, guards, and actions.
"""

from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum
from typing import Any, Callable, Dict, List, Optional, Set, Tuple, Union
import asyncio
import json
import logging
import threading
import uuid

logger = logging.getLogger(__name__)


class TransitionResult(str, Enum):
    """Transition result."""
    SUCCESS = "success"
    FAILED = "failed"
    BLOCKED = "blocked"
    INVALID = "invalid"


@dataclass
class StateData:
    """Data associated with a state."""
    state_id: str
    data: Dict[str, Any] = field(default_factory=dict)
    entered_at: datetime = field(default_factory=datetime.now)
    metadata: Dict[str, Any] = field(default_factory=dict)


@dataclass
class TransitionEvent:
    """A state transition event."""
    id: str
    from_state: str
    to_state: str
    trigger: str
    timestamp: datetime = field(default_factory=datetime.now)
    data: Dict[str, Any] = field(default_factory=dict)
    result: TransitionResult = TransitionResult.SUCCESS


@dataclass
class State:
    """A state in the state machine."""
    name: str
    is_initial: bool = False
    is_final: bool = False
    on_enter: Optional[Callable[["StateContext"], None]] = None
    on_exit: Optional[Callable[["StateContext"], None]] = None
    metadata: Dict[str, Any] = field(default_factory=dict)

    def __hash__(self):
        return hash(self.name)


@dataclass
class Transition:
    """A state transition."""
    name: str
    source: str
    target: str
    trigger: Optional[str] = None
    guards: List[Callable[["StateContext"], bool]] = field(default_factory=list)
    actions: List[Callable[["StateContext"], None]] = field(default_factory=list)
    metadata: Dict[str, Any] = field(default_factory=dict)

    def check_guards(self, context: "StateContext") -> bool:
        """Check if all guards pass."""
        return all(guard(context) for guard in self.guards)


@dataclass
class StateContext:
    """Context passed to state callbacks."""
    machine: "StateMachine"
    current_state: str
    previous_state: Optional[str] = None
    trigger: Optional[str] = None
    data: Dict[str, Any] = field(default_factory=dict)

    def get(self, key: str, default: Any = None) -> Any:
        return self.data.get(key, default)

    def set(self, key: str, value: Any) -> None:
        self.data[key] = value


class StateMachine:
    """Finite state machine."""

    def __init__(self, name: str = "default"):
        self.name = name
        self.states: Dict[str, State] = {}
        self.transitions: Dict[str, Transition] = {}
        self._current_state: Optional[str] = None
        self._context_data: Dict[str, Any] = {}
        self._history: List[TransitionEvent] = []
        self._lock = threading.Lock()
        self._listeners: List[Callable[[TransitionEvent], None]] = []

    @property
    def current_state(self) -> Optional[str]:
        return self._current_state

    @property
    def is_running(self) -> bool:
        return self._current_state is not None

    def add_state(
        self,
        name: str,
        is_initial: bool = False,
        is_final: bool = False,
        on_enter: Callable = None,
        on_exit: Callable = None,
        **metadata
    ) -> "StateMachine":
        """Add a state to the machine."""
        state = State(
            name=name,
            is_initial=is_initial,
            is_final=is_final,
            on_enter=on_enter,
            on_exit=on_exit,
            metadata=metadata
        )
        self.states[name] = state
        return self

    def add_transition(
        self,
        name: str,
        source: str,
        target: str,
        trigger: str = None,
        guards: List[Callable] = None,
        actions: List[Callable] = None,
        **metadata
    ) -> "StateMachine":
        """Add a transition."""
        transition = Transition(
            name=name,
            source=source,
            target=target,
            trigger=trigger,
            guards=guards or [],
            actions=actions or [],
            metadata=metadata
        )
        self.transitions[name] = transition
        return self

    def start(self, data: Dict[str, Any] = None) -> bool:
        """Start the state machine."""
        initial = next(
            (s for s in self.states.values() if s.is_initial),
            None
        )

        if not initial:
            logger.error("No initial state defined")
            return False

        self._context_data = data or {}
        self._enter_state(initial.name)
        return True

    def _enter_state(self, state_name: str) -> None:
        """Enter a state."""
        state = self.states.get(state_name)
        if not state:
            return

        self._current_state = state_name

        context = StateContext(
            machine=self,
            current_state=state_name,
            data=self._context_data
        )

        if state.on_enter:
            try:
                state.on_enter(context)
            except Exception as e:
                logger.error(f"Error in on_enter for {state_name}: {e}")

    def _exit_state(self, state_name: str) -> None:
        """Exit a state."""
        state = self.states.get(state_name)
        if not state:
            return

        context = StateContext(
            machine=self,
            current_state=state_name,
            data=self._context_data
        )

        if state.on_exit:
            try:
                state.on_exit(context)
            except Exception as e:
                logger.error(f"Error in on_exit for {state_name}: {e}")

    def trigger(
        self,
        trigger_name: str,
        data: Dict[str, Any] = None
    ) -> TransitionResult:
        """Trigger a transition."""
        with self._lock:
            if not self._current_state:
                return TransitionResult.INVALID

            # Find matching transition
            transition = next(
                (t for t in self.transitions.values()
                 if t.source == self._current_state and t.trigger == trigger_name),
                None
            )

            if not transition:
                return TransitionResult.INVALID

            return self._execute_transition(transition, trigger_name, data)

    def transition_to(
        self,
        target_state: str,
        data: Dict[str, Any] = None
    ) -> TransitionResult:
        """Directly transition to a state."""
        with self._lock:
            if not self._current_state:
                return TransitionResult.INVALID

            # Find transition to target
            transition = next(
                (t for t in self.transitions.values()
                 if t.source == self._current_state and t.target == target_state),
                None
            )

            if not transition:
                return TransitionResult.INVALID

            return self._execute_transition(transition, None, data)

    def _execute_transition(
        self,
        transition: Transition,
        trigger: str,
        data: Dict[str, Any]
    ) -> TransitionResult:
        """Execute a transition."""
        if data:
            self._context_data.update(data)

        context = StateContext(
            machine=self,
            current_state=self._current_state,
            previous_state=self._current_state,
            trigger=trigger,
            data=self._context_data
        )

        # Check guards
        if not transition.check_guards(context):
            event = TransitionEvent(
                id=str(uuid.uuid4())[:8],
                from_state=self._current_state,
                to_state=transition.target,
                trigger=trigger or transition.name,
                result=TransitionResult.BLOCKED
            )
            self._history.append(event)
            return TransitionResult.BLOCKED

        try:
            # Exit current state
            self._exit_state(self._current_state)

            # Execute actions
            for action in transition.actions:
                action(context)

            # Enter new state
            previous = self._current_state
            self._enter_state(transition.target)

            # Record event
            event = TransitionEvent(
                id=str(uuid.uuid4())[:8],
                from_state=previous,
                to_state=transition.target,
                trigger=trigger or transition.name,
                data=data or {},
                result=TransitionResult.SUCCESS
            )
            self._history.append(event)
            self._notify_listeners(event)

            return TransitionResult.SUCCESS

        except Exception as e:
            logger.error(f"Transition failed: {e}")
            return TransitionResult.FAILED

    def can_trigger(self, trigger_name: str) -> bool:
        """Check if a trigger is valid in current state."""
        if not self._current_state:
            return False

        return any(
            t.source == self._current_state and t.trigger == trigger_name
            for t in self.transitions.values()
        )

    def available_triggers(self) -> List[str]:
        """Get available triggers in current state."""
        if not self._current_state:
            return []

        return [
            t.trigger for t in self.transitions.values()
            if t.source == self._current_state and t.trigger
        ]

    def add_listener(self, listener: Callable[[TransitionEvent], None]) -> None:
        """Add a transition listener."""
        self._listeners.append(listener)

    def _notify_listeners(self, event: TransitionEvent) -> None:
        """Notify all listeners of a transition."""
        for listener in self._listeners:
            try:
                listener(event)
            except Exception as e:
                logger.error(f"Listener error: {e}")

    def get_history(self) -> List[Dict[str, Any]]:
        """Get transition history."""
        return [
            {
                "id": e.id,
                "from": e.from_state,
                "to": e.to_state,
                "trigger": e.trigger,
                "timestamp": e.timestamp.isoformat(),
                "result": e.result.value
            }
            for e in self._history
        ]

    def to_dict(self) -> Dict[str, Any]:
        """Export machine definition."""
        return {
            "name": self.name,
            "current_state": self._current_state,
            "states": [
                {
                    "name": s.name,
                    "initial": s.is_initial,
                    "final": s.is_final
                }
                for s in self.states.values()
            ],
            "transitions": [
                {
                    "name": t.name,
                    "source": t.source,
                    "target": t.target,
                    "trigger": t.trigger
                }
                for t in self.transitions.values()
            ]
        }


class HierarchicalStateMachine(StateMachine):
    """State machine with nested states."""

    def __init__(self, name: str = "default"):
        super().__init__(name)
        self.parent_states: Dict[str, str] = {}  # child -> parent
        self.child_states: Dict[str, Set[str]] = {}  # parent -> children

    def add_child_state(
        self,
        parent: str,
        child: str,
        **kwargs
    ) -> "HierarchicalStateMachine":
        """Add a child state to a parent."""
        self.add_state(child, **kwargs)

        self.parent_states[child] = parent

        if parent not in self.child_states:
            self.child_states[parent] = set()
        self.child_states[parent].add(child)

        return self

    def is_in_state(self, state_name: str) -> bool:
        """Check if currently in a state (or child of that state)."""
        if self._current_state == state_name:
            return True

        # Check if current state is a child
        current = self._current_state
        while current in self.parent_states:
            current = self.parent_states[current]
            if current == state_name:
                return True

        return False


class AsyncStateMachine:
    """Async state machine."""

    def __init__(self, name: str = "default"):
        self.machine = StateMachine(name)
        self._async_actions: Dict[str, Callable] = {}

    def add_state(self, *args, **kwargs) -> "AsyncStateMachine":
        self.machine.add_state(*args, **kwargs)
        return self

    def add_transition(self, *args, **kwargs) -> "AsyncStateMachine":
        self.machine.add_transition(*args, **kwargs)
        return self

    def add_async_action(
        self,
        transition_name: str,
        action: Callable
    ) -> "AsyncStateMachine":
        """Add an async action to a transition."""
        self._async_actions[transition_name] = action
        return self

    async def start(self, data: Dict[str, Any] = None) -> bool:
        return self.machine.start(data)

    async def trigger(
        self,
        trigger_name: str,
        data: Dict[str, Any] = None
    ) -> TransitionResult:
        """Async trigger."""
        # Find transition
        transition = next(
            (t for t in self.machine.transitions.values()
             if t.source == self.machine._current_state and t.trigger == trigger_name),
            None
        )

        if transition and transition.name in self._async_actions:
            # Execute async action
            action = self._async_actions[transition.name]
            context = StateContext(
                machine=self.machine,
                current_state=self.machine._current_state,
                trigger=trigger_name,
                data=self.machine._context_data
            )
            await action(context)

        return self.machine.trigger(trigger_name, data)


class StateMachineBuilder:
    """Builder for creating state machines."""

    def __init__(self, name: str = "default"):
        self.machine = StateMachine(name)
        self._current_state: Optional[str] = None

    def state(
        self,
        name: str,
        initial: bool = False,
        final: bool = False
    ) -> "StateMachineBuilder":
        """Define a state."""
        self.machine.add_state(name, is_initial=initial, is_final=final)
        self._current_state = name
        return self

    def on_enter(self, callback: Callable) -> "StateMachineBuilder":
        """Set on_enter callback for current state."""
        if self._current_state:
            self.machine.states[self._current_state].on_enter = callback
        return self

    def on_exit(self, callback: Callable) -> "StateMachineBuilder":
        """Set on_exit callback for current state."""
        if self._current_state:
            self.machine.states[self._current_state].on_exit = callback
        return self

    def transition(
        self,
        name: str,
        source: str,
        target: str,
        trigger: str = None
    ) -> "StateMachineBuilder":
        """Define a transition."""
        self.machine.add_transition(name, source, target, trigger)
        return self

    def permit(
        self,
        trigger: str,
        target: str
    ) -> "StateMachineBuilder":
        """Add permitted transition from current state."""
        if self._current_state:
            name = f"{self._current_state}_to_{target}"
            self.machine.add_transition(name, self._current_state, target, trigger)
        return self

    def build(self) -> StateMachine:
        """Build the state machine."""
        return self.machine


class StateManager:
    """Manage multiple state machines."""

    def __init__(self):
        self.machines: Dict[str, StateMachine] = {}
        self._lock = threading.Lock()

    def create(self, name: str) -> StateMachine:
        """Create a new state machine."""
        machine = StateMachine(name)
        with self._lock:
            self.machines[name] = machine
        return machine

    def get(self, name: str) -> Optional[StateMachine]:
        """Get a state machine by name."""
        return self.machines.get(name)

    def delete(self, name: str) -> bool:
        """Delete a state machine."""
        with self._lock:
            if name in self.machines:
                del self.machines[name]
                return True
            return False

    def list(self) -> List[Dict[str, Any]]:
        """List all state machines."""
        return [
            {
                "name": m.name,
                "current_state": m.current_state,
                "is_running": m.is_running
            }
            for m in self.machines.values()
        ]


# Example usage
def example_usage():
    """Example state machine usage."""
    # Build a simple order state machine
    machine = (
        StateMachineBuilder("order")
        .state("created", initial=True)
        .permit("submit", "pending")
        .state("pending")
        .permit("approve", "approved")
        .permit("reject", "rejected")
        .state("approved")
        .permit("ship", "shipped")
        .state("shipped")
        .permit("deliver", "delivered")
        .state("delivered", final=True)
        .state("rejected", final=True)
        .build()
    )

    # Add listener
    def on_transition(event: TransitionEvent):
        print(f"Transition: {event.from_state} -> {event.to_state}")

    machine.add_listener(on_transition)

    # Start machine
    machine.start({"order_id": "12345"})
    print(f"Current state: {machine.current_state}")

    # Execute transitions
    machine.trigger("submit")
    print(f"After submit: {machine.current_state}")

    machine.trigger("approve")
    print(f"After approve: {machine.current_state}")

    machine.trigger("ship")
    print(f"After ship: {machine.current_state}")

    machine.trigger("deliver")
    print(f"After deliver: {machine.current_state}")

    # Check history
    print(f"\nHistory:")
    for event in machine.get_history():
        print(f"  {event['from']} -> {event['to']} ({event['trigger']})")

    # Export definition
    print(f"\nDefinition: {json.dumps(machine.to_dict(), indent=2)}")

