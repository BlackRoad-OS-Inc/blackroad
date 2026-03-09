"""
RoadPlugin - Plugin System for BlackRoad
Plugin discovery, loading, hooks, and lifecycle management.
"""

from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum
from typing import Any, Callable, Dict, List, Optional, Set, Type
import asyncio
import importlib
import importlib.util
import inspect
import json
import logging
import os
import sys
import threading

logger = logging.getLogger(__name__)


class PluginState(str, Enum):
    """Plugin lifecycle states."""
    DISCOVERED = "discovered"
    LOADED = "loaded"
    ENABLED = "enabled"
    DISABLED = "disabled"
    ERROR = "error"


class HookPriority(int, Enum):
    """Hook execution priority."""
    HIGHEST = 0
    HIGH = 25
    NORMAL = 50
    LOW = 75
    LOWEST = 100


@dataclass
class PluginInfo:
    """Plugin metadata."""
    name: str
    version: str = "0.1.0"
    description: str = ""
    author: str = ""
    dependencies: List[str] = field(default_factory=list)
    hooks: List[str] = field(default_factory=list)
    config_schema: Dict[str, Any] = field(default_factory=dict)


@dataclass
class HookRegistration:
    """A registered hook handler."""
    name: str
    handler: Callable
    plugin_name: str
    priority: HookPriority = HookPriority.NORMAL
    async_handler: bool = False


@dataclass
class PluginContext:
    """Context passed to plugins."""
    plugin_name: str
    config: Dict[str, Any] = field(default_factory=dict)
    data: Dict[str, Any] = field(default_factory=dict)


class Plugin:
    """Base plugin class."""

    info: PluginInfo = PluginInfo(name="base_plugin")

    def __init__(self, context: PluginContext):
        self.context = context
        self.state = PluginState.LOADED
        self._hooks: List[HookRegistration] = []

    async def on_load(self) -> None:
        """Called when plugin is loaded."""
        pass

    async def on_enable(self) -> None:
        """Called when plugin is enabled."""
        pass

    async def on_disable(self) -> None:
        """Called when plugin is disabled."""
        pass

    async def on_unload(self) -> None:
        """Called when plugin is unloaded."""
        pass

    def register_hook(
        self,
        name: str,
        handler: Callable,
        priority: HookPriority = HookPriority.NORMAL
    ) -> None:
        """Register a hook handler."""
        registration = HookRegistration(
            name=name,
            handler=handler,
            plugin_name=self.info.name,
            priority=priority,
            async_handler=asyncio.iscoroutinefunction(handler)
        )
        self._hooks.append(registration)

    def get_hooks(self) -> List[HookRegistration]:
        """Get all registered hooks."""
        return self._hooks


class HookManager:
    """Manage hook registration and execution."""

    def __init__(self):
        self.hooks: Dict[str, List[HookRegistration]] = {}
        self._lock = threading.Lock()

    def register(self, registration: HookRegistration) -> None:
        """Register a hook handler."""
        with self._lock:
            if registration.name not in self.hooks:
                self.hooks[registration.name] = []

            self.hooks[registration.name].append(registration)
            # Sort by priority
            self.hooks[registration.name].sort(key=lambda h: h.priority.value)

    def unregister(self, plugin_name: str) -> int:
        """Unregister all hooks for a plugin."""
        count = 0
        with self._lock:
            for name in self.hooks:
                original_len = len(self.hooks[name])
                self.hooks[name] = [
                    h for h in self.hooks[name]
                    if h.plugin_name != plugin_name
                ]
                count += original_len - len(self.hooks[name])
        return count

    async def execute(self, name: str, *args, **kwargs) -> List[Any]:
        """Execute all handlers for a hook."""
        handlers = self.hooks.get(name, [])
        results = []

        for registration in handlers:
            try:
                if registration.async_handler:
                    result = await registration.handler(*args, **kwargs)
                else:
                    result = registration.handler(*args, **kwargs)
                results.append(result)
            except Exception as e:
                logger.error(f"Hook {name} handler error: {e}")
                results.append(None)

        return results

    async def execute_filter(self, name: str, value: Any, *args, **kwargs) -> Any:
        """Execute filter hooks, passing value through each handler."""
        handlers = self.hooks.get(name, [])

        for registration in handlers:
            try:
                if registration.async_handler:
                    value = await registration.handler(value, *args, **kwargs)
                else:
                    value = registration.handler(value, *args, **kwargs)
            except Exception as e:
                logger.error(f"Filter hook {name} error: {e}")

        return value

    def list_hooks(self) -> Dict[str, int]:
        """List all hooks with handler counts."""
        return {name: len(handlers) for name, handlers in self.hooks.items()}


class PluginLoader:
    """Load plugins from various sources."""

    def __init__(self, plugin_dirs: List[str] = None):
        self.plugin_dirs = plugin_dirs or []
        self._loaded: Dict[str, Type[Plugin]] = {}

    def discover(self) -> List[str]:
        """Discover plugins in plugin directories."""
        discovered = []

        for plugin_dir in self.plugin_dirs:
            if not os.path.exists(plugin_dir):
                continue

            for item in os.listdir(plugin_dir):
                path = os.path.join(plugin_dir, item)

                # Python package
                if os.path.isdir(path) and os.path.exists(
                    os.path.join(path, "__init__.py")
                ):
                    discovered.append(item)

                # Python module
                elif item.endswith(".py") and not item.startswith("_"):
                    discovered.append(item[:-3])

        return discovered

    def load(self, name: str, path: str = None) -> Optional[Type[Plugin]]:
        """Load a plugin by name."""
        if name in self._loaded:
            return self._loaded[name]

        try:
            if path:
                spec = importlib.util.spec_from_file_location(name, path)
                if spec and spec.loader:
                    module = importlib.util.module_from_spec(spec)
                    sys.modules[name] = module
                    spec.loader.exec_module(module)
            else:
                module = importlib.import_module(name)

            # Find Plugin subclass
            for attr_name in dir(module):
                attr = getattr(module, attr_name)
                if (
                    isinstance(attr, type) and
                    issubclass(attr, Plugin) and
                    attr is not Plugin
                ):
                    self._loaded[name] = attr
                    return attr

            logger.warning(f"No Plugin class found in {name}")
            return None

        except Exception as e:
            logger.error(f"Failed to load plugin {name}: {e}")
            return None

    def unload(self, name: str) -> bool:
        """Unload a plugin."""
        if name in self._loaded:
            del self._loaded[name]
            if name in sys.modules:
                del sys.modules[name]
            return True
        return False


class PluginRegistry:
    """Registry of active plugins."""

    def __init__(self):
        self.plugins: Dict[str, Plugin] = {}
        self._lock = threading.Lock()

    def register(self, plugin: Plugin) -> None:
        """Register a plugin instance."""
        with self._lock:
            self.plugins[plugin.info.name] = plugin

    def unregister(self, name: str) -> Optional[Plugin]:
        """Unregister a plugin."""
        with self._lock:
            return self.plugins.pop(name, None)

    def get(self, name: str) -> Optional[Plugin]:
        """Get a plugin by name."""
        return self.plugins.get(name)

    def list(self) -> List[PluginInfo]:
        """List all registered plugins."""
        return [p.info for p in self.plugins.values()]

    def get_by_state(self, state: PluginState) -> List[Plugin]:
        """Get plugins by state."""
        return [p for p in self.plugins.values() if p.state == state]


class PluginManager:
    """High-level plugin management."""

    def __init__(self, plugin_dirs: List[str] = None):
        self.loader = PluginLoader(plugin_dirs)
        self.registry = PluginRegistry()
        self.hooks = HookManager()
        self._configs: Dict[str, Dict[str, Any]] = {}

    def set_config(self, plugin_name: str, config: Dict[str, Any]) -> None:
        """Set configuration for a plugin."""
        self._configs[plugin_name] = config

    async def load(self, name: str, path: str = None) -> Optional[Plugin]:
        """Load and instantiate a plugin."""
        plugin_class = self.loader.load(name, path)
        if not plugin_class:
            return None

        # Create context
        context = PluginContext(
            plugin_name=name,
            config=self._configs.get(name, {})
        )

        # Instantiate
        try:
            plugin = plugin_class(context)
            await plugin.on_load()

            # Register hooks
            for hook in plugin.get_hooks():
                self.hooks.register(hook)

            self.registry.register(plugin)
            logger.info(f"Loaded plugin: {name}")
            return plugin

        except Exception as e:
            logger.error(f"Failed to instantiate plugin {name}: {e}")
            return None

    async def enable(self, name: str) -> bool:
        """Enable a plugin."""
        plugin = self.registry.get(name)
        if not plugin:
            return False

        if plugin.state == PluginState.ENABLED:
            return True

        try:
            await plugin.on_enable()
            plugin.state = PluginState.ENABLED
            logger.info(f"Enabled plugin: {name}")
            return True
        except Exception as e:
            logger.error(f"Failed to enable plugin {name}: {e}")
            plugin.state = PluginState.ERROR
            return False

    async def disable(self, name: str) -> bool:
        """Disable a plugin."""
        plugin = self.registry.get(name)
        if not plugin:
            return False

        if plugin.state == PluginState.DISABLED:
            return True

        try:
            await plugin.on_disable()
            plugin.state = PluginState.DISABLED
            logger.info(f"Disabled plugin: {name}")
            return True
        except Exception as e:
            logger.error(f"Failed to disable plugin {name}: {e}")
            return False

    async def unload(self, name: str) -> bool:
        """Unload a plugin completely."""
        plugin = self.registry.get(name)
        if not plugin:
            return False

        # Disable first
        if plugin.state == PluginState.ENABLED:
            await self.disable(name)

        try:
            await plugin.on_unload()
            self.hooks.unregister(name)
            self.registry.unregister(name)
            self.loader.unload(name)
            logger.info(f"Unloaded plugin: {name}")
            return True
        except Exception as e:
            logger.error(f"Failed to unload plugin {name}: {e}")
            return False

    async def reload(self, name: str) -> Optional[Plugin]:
        """Reload a plugin."""
        plugin = self.registry.get(name)
        path = None

        if plugin:
            await self.unload(name)

        return await self.load(name, path)

    def discover(self) -> List[str]:
        """Discover available plugins."""
        return self.loader.discover()

    async def load_all(self) -> int:
        """Load all discovered plugins."""
        plugins = self.discover()
        count = 0

        for name in plugins:
            if await self.load(name):
                count += 1

        return count

    async def execute_hook(self, name: str, *args, **kwargs) -> List[Any]:
        """Execute a hook."""
        return await self.hooks.execute(name, *args, **kwargs)

    async def filter(self, name: str, value: Any, *args, **kwargs) -> Any:
        """Execute a filter hook."""
        return await self.hooks.execute_filter(name, value, *args, **kwargs)

    def list_plugins(self) -> List[Dict[str, Any]]:
        """List all plugins with status."""
        return [
            {
                "name": p.info.name,
                "version": p.info.version,
                "description": p.info.description,
                "state": p.state.value
            }
            for p in self.registry.plugins.values()
        ]


def plugin(
    name: str,
    version: str = "0.1.0",
    description: str = "",
    **kwargs
):
    """Decorator to create a plugin class."""
    def decorator(cls: Type) -> Type[Plugin]:
        # Create Plugin subclass
        class DecoratedPlugin(Plugin):
            info = PluginInfo(
                name=name,
                version=version,
                description=description,
                **kwargs
            )

            async def on_load(self):
                if hasattr(cls, "on_load"):
                    await cls.on_load(self)

            async def on_enable(self):
                if hasattr(cls, "on_enable"):
                    await cls.on_enable(self)

            async def on_disable(self):
                if hasattr(cls, "on_disable"):
                    await cls.on_disable(self)

        # Copy methods
        for attr_name in dir(cls):
            if not attr_name.startswith("_") and attr_name not in [
                "on_load", "on_enable", "on_disable", "on_unload"
            ]:
                setattr(DecoratedPlugin, attr_name, getattr(cls, attr_name))

        return DecoratedPlugin

    return decorator


# Example usage
async def example_usage():
    """Example plugin system usage."""
    manager = PluginManager(plugin_dirs=["./plugins"])

    # Create a sample plugin inline
    @plugin("sample_plugin", version="1.0.0", description="A sample plugin")
    class SamplePlugin:
        async def on_load(self):
            print(f"Loading {self.info.name}")
            self.register_hook("before_request", self.before_request)
            self.register_hook("after_response", self.after_response, HookPriority.HIGH)

        async def on_enable(self):
            print(f"Enabling {self.info.name}")

        def before_request(self, request):
            print(f"Before request: {request}")
            return request

        async def after_response(self, response):
            print(f"After response: {response}")
            return response

    # Manual registration (for demo)
    context = PluginContext(plugin_name="sample_plugin")
    sample = SamplePlugin(context)
    await sample.on_load()

    for hook in sample.get_hooks():
        manager.hooks.register(hook)

    manager.registry.register(sample)
    await manager.enable("sample_plugin")

    # Execute hooks
    results = await manager.execute_hook("before_request", {"url": "/api/test"})
    print(f"Hook results: {results}")

    # Filter hook
    response = {"status": 200}
    filtered = await manager.filter("after_response", response)
    print(f"Filtered response: {filtered}")

    # List plugins
    print(f"Plugins: {manager.list_plugins()}")

