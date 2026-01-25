"""Minimal deterministic bot implementations used in tests."""
from __future__ import annotations

from dataclasses import dataclass
from typing import Any, Dict

from orchestrator.cache import Cache
from orchestrator.logging import logger


@dataclass
class Bot:
    name: str
    cache: Cache

    def run(self, intent: str, inputs: Dict[str, Any]) -> Dict[str, Any]:
        params = {"bot": self.name, "intent": intent, "inputs": inputs}
        cached = self.cache.get(params)
        if cached is not None:
            logger.log("cache hit")
            return cached
        if self.name == "RevOps-BOT" and intent == "forecast":
            value = {"forecast": sum(inputs.get("pipeline", []))}
        elif self.name == "SRE-BOT" and intent == "error-budget":
            total = inputs.get("total", 1)
            errors = inputs.get("errors", 0)
            value = {"error_budget": max(total - errors, 0)}
        elif self.name == "Treasury-BOT" and intent == "cash-view":
            value = {"cash": sum(inputs.get("accounts", []))}
        else:
            value = {"echo": inputs}
        self.cache.set(params, value)
        logger.log("cache write")
        return value


def get_default_bots(ttl: int = 60) -> Dict[str, Bot]:
    def key_fn(d: dict) -> str:
        return f"{d['bot']}::{d['intent']}::{sorted(d['inputs'].items())}"

    bots = {}
    for name in ["RevOps-BOT", "SRE-BOT", "Treasury-BOT"]:
        bots[name] = Bot(name=name, cache=Cache(get_key=key_fn, ttl_seconds=ttl))
    return bots
