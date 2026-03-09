"""
RoadREPL - Interactive Shell for BlackRoad
REPL with history, completions, commands, and scripting.
"""

from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum
from typing import Any, Callable, Dict, List, Optional, Tuple
import asyncio
import json
import logging
import os
import readline
import shlex
import sys
import threading

logger = logging.getLogger(__name__)


class CommandType(str, Enum):
    """Command types."""
    BUILTIN = "builtin"
    USER = "user"
    ALIAS = "alias"
    SCRIPT = "script"


@dataclass
class Command:
    """A REPL command."""
    name: str
    handler: Callable
    description: str = ""
    usage: str = ""
    command_type: CommandType = CommandType.USER
    aliases: List[str] = field(default_factory=list)


@dataclass
class CommandResult:
    """Result of command execution."""
    success: bool
    output: Any = None
    error: Optional[str] = None
    exit_code: int = 0


@dataclass
class HistoryEntry:
    """History entry."""
    command: str
    timestamp: datetime = field(default_factory=datetime.now)
    result: Optional[CommandResult] = None


class History:
    """Command history manager."""

    def __init__(self, max_size: int = 1000, file_path: str = None):
        self.max_size = max_size
        self.file_path = file_path
        self.entries: List[HistoryEntry] = []
        self._position = 0

    def add(self, command: str, result: CommandResult = None) -> None:
        """Add command to history."""
        if not command.strip():
            return

        entry = HistoryEntry(command=command, result=result)
        self.entries.append(entry)

        if len(self.entries) > self.max_size:
            self.entries = self.entries[-self.max_size:]

        self._position = len(self.entries)

    def get_previous(self) -> Optional[str]:
        """Get previous command."""
        if self._position > 0:
            self._position -= 1
            return self.entries[self._position].command
        return None

    def get_next(self) -> Optional[str]:
        """Get next command."""
        if self._position < len(self.entries) - 1:
            self._position += 1
            return self.entries[self._position].command
        self._position = len(self.entries)
        return ""

    def search(self, prefix: str) -> List[str]:
        """Search history by prefix."""
        return [
            e.command for e in self.entries
            if e.command.startswith(prefix)
        ]

    def save(self) -> None:
        """Save history to file."""
        if not self.file_path:
            return

        with open(self.file_path, "w") as f:
            for entry in self.entries:
                f.write(f"{entry.command}\n")

    def load(self) -> None:
        """Load history from file."""
        if not self.file_path or not os.path.exists(self.file_path):
            return

        with open(self.file_path, "r") as f:
            for line in f:
                self.add(line.strip())


class Completer:
    """Tab completion handler."""

    def __init__(self):
        self.commands: Dict[str, Command] = {}
        self.completers: List[Callable[[str, str], List[str]]] = []

    def register_command(self, command: Command) -> None:
        """Register command for completion."""
        self.commands[command.name] = command
        for alias in command.aliases:
            self.commands[alias] = command

    def add_completer(self, fn: Callable[[str, str], List[str]]) -> None:
        """Add custom completer function."""
        self.completers.append(fn)

    def complete(self, text: str, state: int) -> Optional[str]:
        """Get completion for readline."""
        if state == 0:
            line = readline.get_line_buffer()
            self._matches = self._get_matches(text, line)

        if state < len(self._matches):
            return self._matches[state]
        return None

    def _get_matches(self, text: str, line: str) -> List[str]:
        """Get all matches."""
        matches = []

        # Command name completion
        if " " not in line:
            matches.extend([
                cmd + " " for cmd in self.commands
                if cmd.startswith(text)
            ])

        # Custom completers
        for completer in self.completers:
            try:
                results = completer(text, line)
                matches.extend(results)
            except Exception:
                pass

        return sorted(set(matches))


class Context:
    """REPL execution context."""

    def __init__(self):
        self.variables: Dict[str, Any] = {}
        self.last_result: Any = None
        self.exit_requested = False
        self.cwd = os.getcwd()

    def set(self, name: str, value: Any) -> None:
        self.variables[name] = value

    def get(self, name: str, default: Any = None) -> Any:
        return self.variables.get(name, default)

    def update(self, **kwargs) -> None:
        self.variables.update(kwargs)


class REPL:
    """Interactive REPL shell."""

    def __init__(
        self,
        prompt: str = "> ",
        history_file: str = None,
        startup_message: str = None
    ):
        self.prompt = prompt
        self.startup_message = startup_message
        self.history = History(file_path=history_file)
        self.completer = Completer()
        self.context = Context()
        self.commands: Dict[str, Command] = {}
        self.aliases: Dict[str, str] = {}
        self._running = False

        # Register builtins
        self._register_builtins()

    def _register_builtins(self) -> None:
        """Register built-in commands."""

        @self.command("help", "Show help for commands")
        def cmd_help(args: List[str]) -> CommandResult:
            if args:
                cmd = self.commands.get(args[0])
                if cmd:
                    output = f"{cmd.name}: {cmd.description}\n"
                    if cmd.usage:
                        output += f"Usage: {cmd.usage}\n"
                    if cmd.aliases:
                        output += f"Aliases: {', '.join(cmd.aliases)}\n"
                    return CommandResult(success=True, output=output)
                return CommandResult(success=False, error=f"Unknown command: {args[0]}")

            output = "Available commands:\n"
            for name, cmd in sorted(self.commands.items()):
                output += f"  {name:15} {cmd.description}\n"
            return CommandResult(success=True, output=output)

        @self.command("exit", "Exit the REPL", aliases=["quit", "q"])
        def cmd_exit(args: List[str]) -> CommandResult:
            self.context.exit_requested = True
            return CommandResult(success=True, output="Goodbye!")

        @self.command("history", "Show command history")
        def cmd_history(args: List[str]) -> CommandResult:
            output = ""
            for i, entry in enumerate(self.history.entries[-20:], 1):
                output += f"{i:4}  {entry.command}\n"
            return CommandResult(success=True, output=output)

        @self.command("clear", "Clear the screen")
        def cmd_clear(args: List[str]) -> CommandResult:
            os.system("clear" if os.name == "posix" else "cls")
            return CommandResult(success=True)

        @self.command("set", "Set a variable", usage="set <name> <value>")
        def cmd_set(args: List[str]) -> CommandResult:
            if len(args) < 2:
                return CommandResult(success=False, error="Usage: set <name> <value>")
            name = args[0]
            value = " ".join(args[1:])
            self.context.set(name, value)
            return CommandResult(success=True, output=f"{name} = {value}")

        @self.command("get", "Get a variable value", usage="get <name>")
        def cmd_get(args: List[str]) -> CommandResult:
            if not args:
                # Show all variables
                output = "Variables:\n"
                for name, value in self.context.variables.items():
                    output += f"  {name} = {value}\n"
                return CommandResult(success=True, output=output)

            name = args[0]
            value = self.context.get(name)
            if value is None:
                return CommandResult(success=False, error=f"Variable not found: {name}")
            return CommandResult(success=True, output=str(value))

        @self.command("alias", "Create an alias", usage="alias <name> <command>")
        def cmd_alias(args: List[str]) -> CommandResult:
            if len(args) < 2:
                # Show all aliases
                output = "Aliases:\n"
                for name, cmd in self.aliases.items():
                    output += f"  {name} = {cmd}\n"
                return CommandResult(success=True, output=output)

            name = args[0]
            command = " ".join(args[1:])
            self.aliases[name] = command
            return CommandResult(success=True, output=f"Alias created: {name}")

    def command(
        self,
        name: str,
        description: str = "",
        usage: str = "",
        aliases: List[str] = None
    ):
        """Decorator to register a command."""
        def decorator(fn: Callable) -> Callable:
            cmd = Command(
                name=name,
                handler=fn,
                description=description,
                usage=usage,
                command_type=CommandType.USER,
                aliases=aliases or []
            )
            self.register_command(cmd)
            return fn
        return decorator

    def register_command(self, command: Command) -> None:
        """Register a command."""
        self.commands[command.name] = command
        self.completer.register_command(command)

        for alias in command.aliases:
            self.commands[alias] = command

    def parse_line(self, line: str) -> Tuple[str, List[str]]:
        """Parse input line into command and args."""
        line = line.strip()
        if not line:
            return "", []

        # Check for alias
        first_word = line.split()[0]
        if first_word in self.aliases:
            line = self.aliases[first_word] + line[len(first_word):]

        try:
            parts = shlex.split(line)
        except ValueError:
            parts = line.split()

        if not parts:
            return "", []

        return parts[0], parts[1:]

    def execute(self, line: str) -> CommandResult:
        """Execute a command line."""
        cmd_name, args = self.parse_line(line)
        if not cmd_name:
            return CommandResult(success=True)

        # Find command
        command = self.commands.get(cmd_name)
        if not command:
            return CommandResult(
                success=False,
                error=f"Unknown command: {cmd_name}",
                exit_code=1
            )

        # Execute
        try:
            result = command.handler(args)
            self.context.last_result = result.output
            return result
        except Exception as e:
            return CommandResult(
                success=False,
                error=str(e),
                exit_code=1
            )

    def run(self) -> None:
        """Run the REPL loop."""
        self._running = True
        self.history.load()

        # Setup readline
        readline.set_completer(self.completer.complete)
        readline.parse_and_bind("tab: complete")

        if self.startup_message:
            print(self.startup_message)

        try:
            while self._running and not self.context.exit_requested:
                try:
                    line = input(self.prompt)
                except EOFError:
                    print()
                    break
                except KeyboardInterrupt:
                    print("^C")
                    continue

                result = self.execute(line)
                self.history.add(line, result)

                if result.output:
                    print(result.output)
                if result.error:
                    print(f"Error: {result.error}")

        finally:
            self._running = False
            self.history.save()

    def stop(self) -> None:
        """Stop the REPL."""
        self._running = False
        self.context.exit_requested = True


class ScriptRunner:
    """Run REPL scripts."""

    def __init__(self, repl: REPL):
        self.repl = repl

    def run_file(self, path: str) -> List[CommandResult]:
        """Run commands from a file."""
        results = []

        with open(path, "r") as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith("#"):
                    continue

                result = self.repl.execute(line)
                results.append(result)

                if not result.success:
                    break

        return results

    def run_string(self, script: str) -> List[CommandResult]:
        """Run commands from a string."""
        results = []

        for line in script.strip().split("\n"):
            line = line.strip()
            if not line or line.startswith("#"):
                continue

            result = self.repl.execute(line)
            results.append(result)

        return results


class REPLBuilder:
    """Builder for REPL configuration."""

    def __init__(self):
        self._prompt = "> "
        self._history_file = None
        self._startup_message = None
        self._commands: List[Command] = []
        self._completers: List[Callable] = []

    def prompt(self, prompt: str) -> "REPLBuilder":
        self._prompt = prompt
        return self

    def history_file(self, path: str) -> "REPLBuilder":
        self._history_file = path
        return self

    def startup_message(self, message: str) -> "REPLBuilder":
        self._startup_message = message
        return self

    def add_command(
        self,
        name: str,
        handler: Callable,
        description: str = "",
        **kwargs
    ) -> "REPLBuilder":
        cmd = Command(
            name=name,
            handler=handler,
            description=description,
            **kwargs
        )
        self._commands.append(cmd)
        return self

    def add_completer(self, fn: Callable) -> "REPLBuilder":
        self._completers.append(fn)
        return self

    def build(self) -> REPL:
        repl = REPL(
            prompt=self._prompt,
            history_file=self._history_file,
            startup_message=self._startup_message
        )

        for cmd in self._commands:
            repl.register_command(cmd)

        for completer in self._completers:
            repl.completer.add_completer(completer)

        return repl


class REPLManager:
    """High-level REPL management."""

    def __init__(self):
        self.repls: Dict[str, REPL] = {}

    def create(self, name: str = "default") -> REPLBuilder:
        """Create a new REPL builder."""
        return REPLBuilder()

    def register(self, name: str, repl: REPL) -> None:
        """Register a REPL."""
        self.repls[name] = repl

    def get(self, name: str) -> Optional[REPL]:
        """Get a REPL by name."""
        return self.repls.get(name)

    def run(self, name: str = "default") -> None:
        """Run a REPL."""
        repl = self.repls.get(name)
        if repl:
            repl.run()


# Example usage
def example_usage():
    """Example REPL usage."""
    manager = REPLManager()

    # Build REPL
    builder = manager.create()
    repl = (
        builder
        .prompt("road> ")
        .startup_message("Welcome to RoadREPL!")
        .add_command(
            "echo",
            lambda args: CommandResult(True, " ".join(args)),
            "Echo arguments"
        )
        .add_command(
            "upper",
            lambda args: CommandResult(True, " ".join(args).upper()),
            "Convert to uppercase"
        )
        .build()
    )

    # Add custom command with decorator
    @repl.command("greet", "Greet someone", usage="greet <name>")
    def greet(args: List[str]) -> CommandResult:
        if not args:
            return CommandResult(False, error="Please provide a name")
        return CommandResult(True, f"Hello, {args[0]}!")

    # File completer
    def file_completer(text: str, line: str) -> List[str]:
        import glob
        return glob.glob(text + "*")

    repl.completer.add_completer(file_completer)

    manager.register("main", repl)

    print("REPL configured. Run with manager.run('main')")

