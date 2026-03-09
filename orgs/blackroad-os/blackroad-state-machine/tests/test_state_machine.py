"""Tests for BlackRoad State Machine Engine"""
import pytest
from state_machine import StateMachineEngine, safe_eval, safe_exec


TRAFFIC_LIGHT_STATES = [
    {"name": "red", "is_terminal": False, "description": "Stop"},
    {"name": "green", "is_terminal": False, "description": "Go"},
    {"name": "yellow", "is_terminal": False, "description": "Caution"},
]
TRAFFIC_TRANSITIONS = [
    {"from": "red", "to": "green", "event": "go"},
    {"from": "green", "to": "yellow", "event": "slow"},
    {"from": "yellow", "to": "red", "event": "stop"},
]

ORDER_STATES = [
    {"name": "pending"},
    {"name": "paid"},
    {"name": "shipped"},
    {"name": "delivered", "is_terminal": True},
    {"name": "cancelled", "is_terminal": True},
]
ORDER_TRANSITIONS = [
    {"from": "pending", "to": "paid", "event": "pay"},
    {"from": "pending", "to": "cancelled", "event": "cancel"},
    {"from": "paid", "to": "shipped", "event": "ship"},
    {"from": "shipped", "to": "delivered", "event": "deliver"},
    {"from": "paid", "to": "cancelled", "event": "cancel", "guard": "allow_cancel == True"},
]


@pytest.fixture
def engine():
    return StateMachineEngine(":memory:")


@pytest.fixture
def traffic_engine(engine):
    m = engine.define_machine("traffic_light", TRAFFIC_LIGHT_STATES, TRAFFIC_TRANSITIONS, "red")
    return engine, m


@pytest.fixture
def order_engine(engine):
    m = engine.define_machine("order_flow", ORDER_STATES, ORDER_TRANSITIONS, "pending")
    return engine, m


class TestDefineMachine:
    def test_define_machine(self, engine):
        m = engine.define_machine("test", [{"name": "a"}, {"name": "b"}], [{"from": "a", "to": "b", "event": "go"}], "a")
        assert m.name == "test"
        assert m.initial_state == "a"

    def test_get_machine_by_name(self, engine):
        engine.define_machine("my_machine", [{"name": "s1"}], [], "s1")
        m = engine.get_machine_by_name("my_machine")
        assert m is not None
        assert m.name == "my_machine"

    def test_get_states(self, traffic_engine):
        engine, m = traffic_engine
        states = engine.get_states(m.id)
        assert len(states) == 3
        names = {s.name for s in states}
        assert "red" in names and "green" in names

    def test_get_transitions(self, traffic_engine):
        engine, m = traffic_engine
        transitions = engine.get_transitions(m.id)
        assert len(transitions) == 3


class TestCreateInstance:
    def test_create_instance(self, traffic_engine):
        engine, m = traffic_engine
        inst = engine.create_instance(m.id)
        assert inst.current_state == "red"
        assert inst.id is not None

    def test_create_instance_with_context(self, traffic_engine):
        engine, m = traffic_engine
        inst = engine.create_instance(m.id, context={"car_waiting": True})
        assert inst.context["car_waiting"] is True

    def test_load_instance(self, traffic_engine):
        engine, m = traffic_engine
        inst = engine.create_instance(m.id)
        loaded = engine.load_instance(inst.id)
        assert loaded is not None
        assert loaded.id == inst.id


class TestTrigger:
    def test_trigger_valid_event(self, traffic_engine):
        engine, m = traffic_engine
        inst = engine.create_instance(m.id)
        result = engine.trigger(inst.id, "go")
        assert result["success"] is True
        assert result["to"] == "green"

    def test_trigger_multiple_transitions(self, traffic_engine):
        engine, m = traffic_engine
        inst = engine.create_instance(m.id)
        engine.trigger(inst.id, "go")    # red -> green
        engine.trigger(inst.id, "slow")  # green -> yellow
        result = engine.trigger(inst.id, "stop")  # yellow -> red
        assert result["success"] is True
        assert result["to"] == "red"

    def test_trigger_invalid_event(self, traffic_engine):
        engine, m = traffic_engine
        inst = engine.create_instance(m.id)
        result = engine.trigger(inst.id, "nonexistent_event")
        assert result["success"] is False

    def test_trigger_terminal_state(self, order_engine):
        engine, m = order_engine
        inst = engine.create_instance(m.id)
        engine.trigger(inst.id, "cancel")
        result = engine.trigger(inst.id, "pay")
        assert result["success"] is False
        assert "terminal" in result["error"].lower()

    def test_trigger_with_guard_pass(self, order_engine):
        engine, m = order_engine
        inst = engine.create_instance(m.id, context={"allow_cancel": True})
        engine.trigger(inst.id, "pay")
        result = engine.trigger(inst.id, "cancel")
        assert result["success"] is True

    def test_trigger_with_guard_fail(self, order_engine):
        engine, m = order_engine
        inst = engine.create_instance(m.id, context={"allow_cancel": False})
        engine.trigger(inst.id, "pay")
        result = engine.trigger(inst.id, "cancel")
        assert result["success"] is False

    def test_context_updated_after_trigger(self, engine):
        m = engine.define_machine(
            "counter",
            [{"name": "s1"}, {"name": "s2"}],
            [{"from": "s1", "to": "s2", "event": "inc", "action": "count = count + 1"}],
            "s1",
        )
        inst = engine.create_instance(m.id, context={"count": 0})
        engine.trigger(inst.id, "inc")
        loaded = engine.load_instance(inst.id)
        assert loaded.context["count"] == 1


class TestCanTrigger:
    def test_can_trigger_valid(self, traffic_engine):
        engine, m = traffic_engine
        inst = engine.create_instance(m.id)
        assert engine.can_trigger(inst.id, "go") is True

    def test_cannot_trigger_wrong_event(self, traffic_engine):
        engine, m = traffic_engine
        inst = engine.create_instance(m.id)
        assert engine.can_trigger(inst.id, "slow") is False

    def test_available_events(self, traffic_engine):
        engine, m = traffic_engine
        inst = engine.create_instance(m.id)
        events = engine.get_available_events(inst.id)
        assert "go" in events


class TestHistory:
    def test_history_is_empty_initially(self, traffic_engine):
        engine, m = traffic_engine
        inst = engine.create_instance(m.id)
        assert engine.get_history(inst.id) == []

    def test_history_records_transition(self, traffic_engine):
        engine, m = traffic_engine
        inst = engine.create_instance(m.id)
        engine.trigger(inst.id, "go")
        history = engine.get_history(inst.id)
        assert len(history) == 1
        assert history[0]["from"] == "red"
        assert history[0]["to"] == "green"

    def test_history_accumulates(self, traffic_engine):
        engine, m = traffic_engine
        inst = engine.create_instance(m.id)
        engine.trigger(inst.id, "go")
        engine.trigger(inst.id, "slow")
        history = engine.get_history(inst.id)
        assert len(history) == 2


class TestVisualization:
    def test_export_dot(self, traffic_engine):
        engine, m = traffic_engine
        dot = engine.export_dot(m.id)
        assert "digraph" in dot
        assert "red" in dot
        assert "green" in dot
        assert "go" in dot

    def test_visualize_ascii(self, traffic_engine):
        engine, m = traffic_engine
        ascii_viz = engine.visualize_ascii(m.id)
        assert "traffic_light" in ascii_viz
        assert "red" in ascii_viz

    def test_dot_has_transitions(self, traffic_engine):
        engine, m = traffic_engine
        dot = engine.export_dot(m.id)
        assert "->" in dot


class TestSafeEval:
    def test_true_expression(self):
        assert safe_eval("x > 5", {"x": 10}) is True

    def test_false_expression(self):
        assert safe_eval("x > 5", {"x": 3}) is False

    def test_empty_expression_returns_true(self):
        assert safe_eval("", {}) is True

    def test_malicious_expression_returns_false(self):
        result = safe_eval("__import__('os').system('rm -rf /')", {})
        assert result is False


class TestStats:
    def test_stats(self, traffic_engine):
        engine, m = traffic_engine
        engine.create_instance(m.id)
        stats = engine.get_stats()
        assert stats["machines"] >= 1
        assert stats["instances"] >= 1
