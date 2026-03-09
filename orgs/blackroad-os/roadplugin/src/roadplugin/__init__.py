"""
RoadPlugin - Plugin System for BlackRoad OS

Extensible architecture for building modular applications with plugin discovery,
lifecycle management, and a priority-based hook system.

Example:
    >>> from roadplugin import Plugin, PluginInfo, PluginManager
    >>>
    >>> class MyPlugin(Plugin):
    ...     info = PluginInfo(name="my_plugin", version="1.0.0")
    ...     async def on_load(self):
    ...         self.register_hook("my.hook", self.handler)
    ...     def handler(self, data):
    ...         return data
    >>>
    >>> manager = PluginManager()
    >>> await manager.load("my_plugin")
"""

from .plugin import (
    Plugin,
    PluginInfo,
    PluginContext,
    PluginState,
    PluginManager,
    PluginLoader,
    PluginRegistry,
    HookManager,
    HookRegistration,
    HookPriority,
    plugin,
)

__version__ = "0.1.0"
__author__ = "BlackRoad OS"
__all__ = [
    # Core classes
    "Plugin",
    "PluginInfo",
    "PluginContext",
    "PluginState",
    # Management
    "PluginManager",
    "PluginLoader",
    "PluginRegistry",
    # Hooks
    "HookManager",
    "HookRegistration",
    "HookPriority",
    # Decorators
    "plugin",
]
