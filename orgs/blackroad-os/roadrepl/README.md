# RoadREPL

> Interactive shell framework for BlackRoad OS - Build custom REPLs with history, completions, and scripting

[![Python 3.10+](https://img.shields.io/badge/python-3.10+-blue.svg)](https://www.python.org/downloads/)
[![License](https://img.shields.io/badge/license-Proprietary-red.svg)](LICENSE)
[![BlackRoad OS](https://img.shields.io/badge/BlackRoad-OS-FF1D6C.svg)](https://github.com/BlackRoad-OS)

## Overview

RoadREPL provides a powerful framework for building interactive command-line shells with:

- **Command Registration** - Decorator-based command registration with metadata
- **Tab Completion** - Smart completion for commands, files, and custom completers
- **Command History** - Persistent history with search and navigation
- **Variable System** - Built-in get/set for REPL variables
- **Aliases** - Create command shortcuts
- **Script Runner** - Execute scripts from files or strings
- **Builder Pattern** - Fluent API for REPL configuration

## Installation

```bash
pip install roadrepl
```

Or from source:

```bash
git clone https://github.com/BlackRoad-OS/roadrepl.git
cd roadrepl
pip install -e .
```

## Quick Start

### Basic REPL

```python
from roadrepl import REPL, CommandResult

# Create REPL
repl = REPL(
    prompt="myshell> ",
    history_file="~/.myshell_history",
    startup_message="Welcome to MyShell!"
)

# Add commands using decorator
@repl.command("greet", "Greet someone", usage="greet <name>")
def greet(args):
    if not args:
        return CommandResult(success=False, error="Please provide a name")
    return CommandResult(success=True, output=f"Hello, {args[0]}!")

@repl.command("add", "Add numbers", usage="add <n1> <n2>")
def add(args):
    try:
        result = sum(int(a) for a in args)
        return CommandResult(success=True, output=str(result))
    except ValueError:
        return CommandResult(success=False, error="Invalid numbers")

# Run the REPL
repl.run()
```

### Using the Builder Pattern

```python
from roadrepl import REPLBuilder, CommandResult

repl = (
    REPLBuilder()
    .prompt("road> ")
    .history_file("~/.road_history")
    .startup_message("Welcome to RoadREPL!")
    .add_command("echo", lambda args: CommandResult(True, " ".join(args)), "Echo args")
    .add_command("upper", lambda args: CommandResult(True, " ".join(args).upper()), "Uppercase")
    .build()
)

repl.run()
```

### Custom Completers

```python
import glob
from roadrepl import REPL

repl = REPL(prompt="> ")

# File completer
def file_completer(text: str, line: str) -> list[str]:
    return glob.glob(text + "*")

repl.completer.add_completer(file_completer)

# Custom argument completer
def service_completer(text: str, line: str) -> list[str]:
    services = ["api", "worker", "scheduler", "web"]
    return [s for s in services if s.startswith(text)]

repl.completer.add_completer(service_completer)
```

### Script Execution

```python
from roadrepl import REPL, ScriptRunner

repl = REPL()

# ... register commands ...

runner = ScriptRunner(repl)

# Run from file
results = runner.run_file("setup.script")

# Run from string
results = runner.run_string("""
set env production
deploy api
deploy worker
status
""")

for result in results:
    if result.output:
        print(result.output)
```

## Built-in Commands

| Command | Description |
|---------|-------------|
| `help [cmd]` | Show help for all or specific command |
| `exit` / `quit` / `q` | Exit the REPL |
| `history` | Show command history |
| `clear` | Clear the screen |
| `set <name> <value>` | Set a variable |
| `get [name]` | Get variable(s) |
| `alias <name> <cmd>` | Create command alias |

## API Reference

### Classes

#### REPL

Main REPL class:

```python
repl = REPL(
    prompt="> ",           # Input prompt
    history_file=None,     # Path to history file
    startup_message=None   # Message shown on start
)

# Methods
repl.command(name, description, usage, aliases)  # Decorator
repl.register_command(command)                    # Register Command object
repl.execute(line)                                # Execute command string
repl.run()                                        # Start REPL loop
repl.stop()                                       # Stop REPL
```

#### CommandResult

```python
result = CommandResult(
    success=True,          # Whether command succeeded
    output="result",       # Output to display
    error=None,           # Error message if failed
    exit_code=0           # Exit code
)
```

#### Command

```python
cmd = Command(
    name="mycommand",
    handler=my_handler,
    description="Does something",
    usage="mycommand <arg>",
    command_type=CommandType.USER,
    aliases=["mc", "mycmd"]
)
```

### Enums

- `CommandType`: BUILTIN, USER, ALIAS, SCRIPT

## Advanced Usage

### Variables and Context

```python
@repl.command("deploy", "Deploy service")
def deploy(args):
    # Access REPL context
    env = repl.context.get("env", "development")
    last = repl.context.last_result

    # Set variables
    repl.context.set("last_deploy", args[0] if args else None)

    return CommandResult(True, f"Deployed to {env}")
```

### Async Commands

For async operations, wrap with asyncio:

```python
import asyncio

@repl.command("fetch", "Fetch data from API")
def fetch(args):
    async def _fetch():
        # async operations here
        return await some_api.get(args[0])

    result = asyncio.run(_fetch())
    return CommandResult(True, result)
```

### REPL Manager

Manage multiple REPLs:

```python
from roadrepl import REPLManager

manager = REPLManager()

# Create and configure REPLs
main_repl = manager.create().prompt("main> ").build()
debug_repl = manager.create().prompt("debug> ").build()

manager.register("main", main_repl)
manager.register("debug", debug_repl)

# Run specific REPL
manager.run("main")
```

## License

Proprietary - BlackRoad OS, Inc. All rights reserved.

## Related

- [roadplugin](https://github.com/BlackRoad-OS/roadplugin) - Plugin system
- [roadhttp](https://github.com/BlackRoad-OS/roadhttp) - HTTP client/server
- [roadrpc](https://github.com/BlackRoad-OS/roadrpc) - RPC framework
