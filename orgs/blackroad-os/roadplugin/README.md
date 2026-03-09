# RoadPlugin

> Plugin system for BlackRoad OS - Extensible architecture for building modular applications

[![Python 3.10+](https://img.shields.io/badge/python-3.10+-blue.svg)](https://www.python.org/downloads/)
[![License](https://img.shields.io/badge/license-Proprietary-red.svg)](LICENSE)
[![BlackRoad OS](https://img.shields.io/badge/BlackRoad-OS-FF1D6C.svg)](https://github.com/BlackRoad-OS)

## Overview

RoadPlugin provides a robust plugin architecture for extending BlackRoad applications with:

- **Plugin Discovery** - Automatic detection of plugins in configured directories
- **Lifecycle Management** - Load, enable, disable, unload, and reload plugins
- **Hook System** - Priority-based hook execution with both sync and async handlers
- **Filter Chains** - Pass values through plugin handlers for transformation
- **Dependency Resolution** - Manage plugin dependencies
- **Configuration** - Per-plugin configuration with schema validation

## Installation

```bash
pip install roadplugin
```

Or from source:

```bash
git clone https://github.com/BlackRoad-OS/roadplugin.git
cd roadplugin
pip install -e .
```

## Quick Start

### Creating a Plugin

```python
from roadplugin import Plugin, PluginInfo, PluginContext, HookPriority

class MyPlugin(Plugin):
    info = PluginInfo(
        name="my_plugin",
        version="1.0.0",
        description="My awesome plugin",
        author="Your Name"
    )

    async def on_load(self):
        """Called when plugin is loaded."""
        self.register_hook("request.before", self.before_request)
        self.register_hook("response.after", self.after_response, HookPriority.HIGH)

    async def on_enable(self):
        """Called when plugin is enabled."""
        print(f"{self.info.name} enabled!")

    async def on_disable(self):
        """Called when plugin is disabled."""
        print(f"{self.info.name} disabled!")

    def before_request(self, request):
        """Hook handler for before_request."""
        request["x-plugin"] = self.info.name
        return request

    async def after_response(self, response):
        """Async hook handler for after_response."""
        response["processed_by"] = self.info.name
        return response
```

### Using the Decorator

```python
from roadplugin import plugin, HookPriority

@plugin("auth_plugin", version="1.0.0", description="Authentication plugin")
class AuthPlugin:
    async def on_load(self):
        self.register_hook("auth.validate", self.validate_token)

    async def validate_token(self, token):
        # Validate JWT token
        return {"valid": True, "user_id": "123"}
```

### Plugin Manager

```python
import asyncio
from roadplugin import PluginManager

async def main():
    # Initialize manager with plugin directories
    manager = PluginManager(plugin_dirs=["./plugins", "~/.blackroad/plugins"])

    # Discover and load all plugins
    count = await manager.load_all()
    print(f"Loaded {count} plugins")

    # Load a specific plugin
    plugin = await manager.load("my_plugin", path="./plugins/my_plugin.py")

    # Enable/disable plugins
    await manager.enable("my_plugin")
    await manager.disable("my_plugin")

    # Execute hooks
    results = await manager.execute_hook("request.before", {"url": "/api/users"})

    # Execute filter chain (value passed through each handler)
    response = {"status": 200}
    filtered = await manager.filter("response.after", response)

    # List all plugins
    for info in manager.list_plugins():
        print(f"{info['name']} v{info['version']} - {info['state']}")

    # Reload a plugin
    await manager.reload("my_plugin")

    # Unload a plugin
    await manager.unload("my_plugin")

asyncio.run(main())
```

## CLI Usage

```bash
# Discover plugins
roadplugin discover --dir ./plugins

# List loaded plugins
roadplugin list

# Load a plugin
roadplugin load my_plugin --path ./plugins/my_plugin.py

# Enable/disable
roadplugin enable my_plugin
roadplugin disable my_plugin

# Reload
roadplugin reload my_plugin

# Show plugin info
roadplugin info my_plugin

# List hooks
roadplugin hooks
```

## Plugin Lifecycle

```
DISCOVERED → LOADED → ENABLED ⇄ DISABLED → UNLOADED
                ↓
              ERROR
```

### Lifecycle Events

| Event | Description |
|-------|-------------|
| `on_load()` | Called after plugin class is instantiated |
| `on_enable()` | Called when plugin is activated |
| `on_disable()` | Called when plugin is deactivated |
| `on_unload()` | Called before plugin is removed from memory |

## Hook System

### Priority Levels

| Priority | Value | Use Case |
|----------|-------|----------|
| `HIGHEST` | 0 | Security, authentication |
| `HIGH` | 25 | Validation, preprocessing |
| `NORMAL` | 50 | Standard handlers (default) |
| `LOW` | 75 | Logging, analytics |
| `LOWEST` | 100 | Cleanup, final processing |

### Action Hooks vs Filter Hooks

**Action Hooks** - Execute handlers, collect results:
```python
results = await manager.execute_hook("user.created", user)
```

**Filter Hooks** - Pass value through chain:
```python
content = await manager.filter("content.sanitize", raw_html)
```

## Configuration

Plugins can receive configuration:

```python
from roadplugin import PluginManager

manager = PluginManager()

# Set plugin config before loading
manager.set_config("my_plugin", {
    "api_key": "xxx",
    "timeout": 30,
    "features": ["a", "b"]
})

await manager.load("my_plugin")
```

Access in plugin:
```python
class MyPlugin(Plugin):
    async def on_load(self):
        api_key = self.context.config.get("api_key")
```

## Plugin Directory Structure

```
plugins/
├── my_plugin/
│   ├── __init__.py      # Plugin class
│   ├── handlers.py      # Hook handlers
│   └── config.json      # Default config
├── another_plugin.py    # Single-file plugin
└── shared/
    └── utils.py         # Shared utilities
```

## Advanced Features

### Async Handlers

Both sync and async handlers are supported:

```python
def sync_handler(self, data):
    return process(data)

async def async_handler(self, data):
    result = await fetch_external(data)
    return result
```

### Plugin Dependencies

```python
class MyPlugin(Plugin):
    info = PluginInfo(
        name="my_plugin",
        dependencies=["base_plugin", "auth_plugin>=1.0.0"]
    )
```

### Shared Data

Plugins can share data via context:

```python
# In plugin A
self.context.data["shared_key"] = value

# In plugin B (if manager shares context)
value = self.context.data.get("shared_key")
```

## Best Practices

1. **Idempotent Handlers** - Hooks may be called multiple times
2. **Error Handling** - Wrap handlers in try/except
3. **Async by Default** - Use async for I/O operations
4. **Minimal Dependencies** - Keep plugins lightweight
5. **Version Your Plugins** - Use semantic versioning
6. **Document Hooks** - List hooks your plugin provides/consumes

## API Reference

### Classes

- `Plugin` - Base plugin class
- `PluginInfo` - Plugin metadata dataclass
- `PluginContext` - Runtime context for plugins
- `PluginManager` - High-level plugin management
- `PluginLoader` - Plugin discovery and loading
- `PluginRegistry` - Active plugin registry
- `HookManager` - Hook registration and execution
- `HookRegistration` - Hook handler metadata
- `PluginState` - Plugin lifecycle states enum
- `HookPriority` - Hook execution priority enum

### Decorators

- `@plugin(name, version, description, **kwargs)` - Create plugin class

## License

Proprietary - BlackRoad OS, Inc. All rights reserved.

## Related

- [roadhttp](https://github.com/BlackRoad-OS/roadhttp) - HTTP client/server
- [roadrpc](https://github.com/BlackRoad-OS/roadrpc) - RPC framework
- [roadworkflow](https://github.com/BlackRoad-OS/roadworkflow) - Workflow engine
