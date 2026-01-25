"""Minimal agent runtime harness for the BlackRoad personal agent."""

from __future__ import annotations

from collections.abc import Iterable
from typing import Dict, Protocol

from .config import AgentConfig, PluginMount


class AgentPlugin(Protocol):
    """Simple protocol describing a runtime plugin."""

    name: str

    def activate(self, config: PluginMount) -> None:
        """Hook executed when the runtime is starting up."""

    def handle(self, message: str, context: Dict[str, object]) -> str:
        """Process an inbound message and return the agent's reply."""


class AgentRuntime:
    """Coordinator responsible for wiring together the core agent pieces."""

    def __init__(self, config: AgentConfig, plugins: Iterable[AgentPlugin] | None = None) -> None:
        self.config = config
        self._plugins: Dict[str, AgentPlugin] = {}
        if plugins:
            for plugin in plugins:
                self._plugins[plugin.name] = plugin

    def bootstrap(self) -> None:
        """Activate enabled plugins before the runtime begins handling work."""

        for mount in self.config.enabled_mounts():
            plugin = self._plugins.get(mount.name)
            if plugin is None:
                continue
            plugin.activate(mount)

    def dispatch(self, message: str, context: Dict[str, object] | None = None) -> str:
        """Send a message through the plugin chain and collect a response."""

        if context is None:
            context = {}

        response = message
        for mount in self.config.enabled_mounts():
            plugin = self._plugins.get(mount.name)
            if plugin is None:
                continue
            response = plugin.handle(response, context)
        return response
