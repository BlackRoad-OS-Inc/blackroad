"""
RoadREPL - Interactive Shell Framework for BlackRoad OS

Build custom REPLs with history, completions, commands, and scripting.

Example:
    >>> from roadrepl import REPL, CommandResult
    >>>
    >>> repl = REPL(prompt="myshell> ")
    >>>
    >>> @repl.command("greet", "Greet someone")
    ... def greet(args):
    ...     return CommandResult(success=True, output=f"Hello, {args[0]}!")
    >>>
    >>> repl.run()
"""

from .repl import (
    REPL,
    Command,
    CommandResult,
    CommandType,
    Context,
    History,
    HistoryEntry,
    Completer,
    ScriptRunner,
    REPLBuilder,
    REPLManager,
)

__version__ = "0.1.0"
__author__ = "BlackRoad OS"
__all__ = [
    # Core
    "REPL",
    "Command",
    "CommandResult",
    "CommandType",
    # Context
    "Context",
    # History
    "History",
    "HistoryEntry",
    # Completion
    "Completer",
    # Scripting
    "ScriptRunner",
    # Builder
    "REPLBuilder",
    "REPLManager",
]
