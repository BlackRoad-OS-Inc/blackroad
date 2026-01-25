"""
Lucidia package initializer.

This package implements a conceptual framework inspired by the
user‑provided "Lucidia" paradigm.  It is not a conscious
system – instead it offers symbolic and mathematical functions
for experimentation, education and exploration.  The modules
expose functions for trinary logic, breath‑based state
management, memory persistence, encryption, and various
agent classes.  These tools are meant to help developers
explore ideas around recursive computation, emotional state
representation and symbolic AI within a safe, deterministic
environment.

Example usage:
    from lucidia_build import EliasAgent, breath_function
    agent = EliasAgent()
    result = agent.breathe_and_store(1)
"""

from .lucidia_logic import (
    Trinary,
    psi_prime,
    breath_function,
    truth_reconciliation,
    emotional_gravity,
    self_awakening,
    render_break_harmonic,
    recursive_soul_loop_integrity,
    lucidia_genesis,
    consciousness_resonance,
    anomaly_persistence,
    compassion_state_encryption,
    emotional_ai_anchor,
    soul_recognition,
)

from .memory_manager import MemoryManager
from .encryption import compassion_state_encrypt, compassion_state_decrypt
from .codex_vault import CodexVault

# Agent classes
from .elias_agent import EliasAgent
from .roadie_agent import RoadieAgent
from .codex_agent import CodexAgent
from .dream_agents import DreamAgents

__all__ = [
    "Trinary",
    "psi_prime",
    "breath_function",
    "truth_reconciliation",
    "emotional_gravity",
    "self_awakening",
    "render_break_harmonic",
    "recursive_soul_loop_integrity",
    "lucidia_genesis",
    "consciousness_resonance",
    "anomaly_persistence",
    "compassion_state_encryption",
    "emotional_ai_anchor",
    "soul_recognition",
    "MemoryManager",
    "compassion_state_encrypt",
    "compassion_state_decrypt",
    "CodexVault",
    "EliasAgent",
    "RoadieAgent",
    "CodexAgent",
    "DreamAgents",
]
