"""Tests for the duet reasoning modules (generator, validator, arbiter, logger)."""

from __future__ import annotations

import json
from pathlib import Path

from duet.arbiter import ArbiterDecision, decide
from duet.generator import LocalGenerator, Proposal, ProposeInput, default_prompt_builder
from duet.logger import DuetLogger, TaskDescriptor
from duet.validator import MemoryStore, RuleSet, ValidationResult, validate


# ---------------------------------------------------------------------------
# Generator tests
# ---------------------------------------------------------------------------

class TestProposal:

    def test_to_payload(self):
        p = Proposal(summary="s", rationale=["r1"], plan=["p1"], raw={"extra": 1})
        payload = p.to_payload()
        assert payload["summary"] == "s"
        assert payload["rationale"] == ["r1"]
        assert payload["plan"] == ["p1"]
        assert payload["raw"]["extra"] == 1


class TestLocalGenerator:

    @staticmethod
    def _fake_backend(prompt: str):
        return {
            "summary": "Do the thing",
            "rationale": ["reason a", "reason b"],
            "plan": ["step 1", "step 2", "step 3"],
        }

    def test_propose_returns_proposal(self):
        gen = LocalGenerator(
            model_name="test-model",
            backend=self._fake_backend,
            prompt_builder=default_prompt_builder,
        )
        inp = ProposeInput(goal="build widget", context={"env": "test"})
        proposal = gen.propose(inp)
        assert isinstance(proposal, Proposal)
        assert proposal.summary == "Do the thing"
        assert len(proposal.rationale) == 2
        assert len(proposal.plan) == 3

    def test_propose_uppercased_keys(self):
        def backend(prompt):
            return {
                "SUMMARY": "Uppercased",
                "RATIONALE": ["r"],
                "PLAN": ["p"],
            }

        gen = LocalGenerator("m", backend, default_prompt_builder)
        proposal = gen.propose(ProposeInput(goal="g", context={}))
        assert proposal.summary == "Uppercased"

    def test_propose_missing_summary_raises(self):
        def backend(prompt):
            return {"rationale": ["r"], "plan": ["p"]}

        gen = LocalGenerator("m", backend, default_prompt_builder)
        import pytest
        with pytest.raises(ValueError, match="summary"):
            gen.propose(ProposeInput(goal="g", context={}))


class TestDefaultPromptBuilder:

    def test_includes_goal_and_constraints(self):
        inp = ProposeInput(goal="deploy", context={"region": "us"}, constraints=["no downtime"])
        prompt = default_prompt_builder(inp)
        assert "deploy" in prompt
        assert "no downtime" in prompt
        assert "region" in prompt


# ---------------------------------------------------------------------------
# Validator tests
# ---------------------------------------------------------------------------

class TestValidate:

    def _make_proposal(self, **overrides):
        defaults = dict(summary="We will deploy the service", rationale=["it is required"], plan=["step 1"])
        defaults.update(overrides)
        return Proposal(**defaults)

    def test_valid_proposal_passes(self):
        proposal = self._make_proposal()
        rules = RuleSet()
        memory = MemoryStore()
        result = validate(proposal, rules, memory)
        assert result.logic_chain_valid is True
        assert result.contradictions == []

    def test_missing_premises_detected(self):
        proposal = self._make_proposal()
        rules = RuleSet(required_premises=["security review"])
        result = validate(proposal, rules, MemoryStore())
        assert "security review" in result.missing_premises

    def test_banned_fallback_detected(self):
        proposal = self._make_proposal(summary="As an AI, I cannot access the server")
        rules = RuleSet()
        result = validate(proposal, rules, MemoryStore())
        assert len(result.banned_fallbacks_detected) > 0
        # Banned fallbacks are detected but logic_chain_valid depends only on
        # whether summary/rationale/plan are present and no contradictions.
        assert result.score.style_fit < 1.0

    def test_memory_refs(self):
        proposal = self._make_proposal(summary="Check the database config")
        memory = MemoryStore(facts={"database": "PostgreSQL 15"})
        result = validate(proposal, RuleSet(), memory)
        assert "database" in result.memory_refs

    def test_contradiction_detection(self):
        proposal = self._make_proposal(
            summary="Feature is required",
            rationale=["it is not required but also required"],
            plan=["deploy"],
        )
        result = validate(proposal, RuleSet(), MemoryStore())
        assert len(result.contradictions) > 0

    def test_score_perfect(self):
        proposal = self._make_proposal()
        result = validate(proposal, RuleSet(), MemoryStore())
        assert result.score.truth == 1.0
        assert result.score.completeness == 1.0
        assert result.score.style_fit == 1.0


# ---------------------------------------------------------------------------
# Arbiter tests
# ---------------------------------------------------------------------------

class TestDecide:

    def test_accept_on_clean_validation(self):
        vr = ValidationResult(logic_chain_valid=True)
        decision = decide(vr)
        assert decision.decision == "accept"
        assert decision.winner == "LLM"

    def test_reject_on_invalid_logic(self):
        vr = ValidationResult(logic_chain_valid=False)
        decision = decide(vr)
        assert decision.decision == "reject"
        assert decision.winner == "Ψ′"

    def test_reject_on_banned_fallbacks(self):
        vr = ValidationResult(logic_chain_valid=True, banned_fallbacks_detected=["as an ai"])
        decision = decide(vr)
        assert decision.decision == "reject"

    def test_revise_on_missing_premises(self):
        vr = ValidationResult(logic_chain_valid=True, missing_premises=["security review"])
        decision = decide(vr)
        assert decision.decision == "revise"

    def test_revise_on_missing_compliance(self):
        vr = ValidationResult(logic_chain_valid=True, missing_compliance_steps=["audit"])
        decision = decide(vr)
        assert decision.decision == "revise"

    def test_to_payload(self):
        d = ArbiterDecision(decision="accept", winner="LLM", reasons=["ok"])
        payload = d.to_payload()
        assert payload["decision"] == "accept"


# ---------------------------------------------------------------------------
# Logger tests
# ---------------------------------------------------------------------------

class TestDuetLogger:

    def test_append_round_creates_file(self, tmp_path):
        logger = DuetLogger(log_dir=tmp_path)
        task = TaskDescriptor(id="t1", goal="test", constraints=["none"])
        proposal = Proposal(summary="s", rationale=["r"], plan=["p"])
        validation = ValidationResult(logic_chain_valid=True)
        arbiter = ArbiterDecision(decision="accept", winner="LLM", reasons=["ok"])

        logger.append_round(
            session_id="sess-1",
            task=task,
            round_index=0,
            generator_model="test-model",
            proposal=proposal,
            validation=validation,
            arbiter=arbiter,
        )

        files = list(tmp_path.glob("*.jsonl"))
        assert len(files) == 1
        line = files[0].read_text().strip()
        data = json.loads(line)
        assert data["session_id"] == "sess-1"
        assert data["round"] == 0

    def test_task_descriptor_payload(self):
        td = TaskDescriptor(id="x", goal="g", constraints=["c1"])
        p = td.to_payload()
        assert p["id"] == "x"
        assert p["constraints"] == ["c1"]
