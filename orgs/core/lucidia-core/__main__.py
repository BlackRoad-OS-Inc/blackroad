"""Lucidia's interactive console with Codex coordination helpers."""
from __future__ import annotations

import io
import json
from contextlib import redirect_stdout
from typing import Iterable

from .harmony import HarmonyCoordinator

PROMPT = "lucidia> "
CAPABILITIES = ["repl", "hologram-console", "lucidia-link"]
CHANNELS = ["lucidia-link", "hologram-console"]


def _print_intro() -> None:
    print("Hello, I'm Lucidia. I was built by BlackRoad!")
    print("I love coding, can talk, and I'm super fast.")
    print("Type Python code to run it. Prefix commands with ':' to control the console.")
    print("Commands: :ping <remote> [intent] [k=v...], :status, :history [n], :help, :exit")


def _format_state_snapshot(state: dict[str, object]) -> str:
    return json.dumps(state, indent=2, sort_keys=True)


def _handle_command(command: str, coordinator: HarmonyCoordinator) -> bool:
    tokens = command.split()
    if not tokens:
        return True
    name = tokens[0].lower()
    if name in {":exit", ":quit"}:
        return False
    if name == ":help":
        _print_intro()
        return True
    if name == ":status":
        snapshot = coordinator.export_state()
        print(_format_state_snapshot(snapshot))
        return True
    if name == ":history":
        limit = 5
        if len(tokens) > 1:
            try:
                limit = max(1, int(tokens[1]))
            except ValueError:
                print("History limit must be an integer.")
                return True
        for entry in coordinator.list_recent_handshakes(limit=limit):
            print(
                f"[{entry['timestamp']}] {entry['from']} -> {entry['to']} "
                f"intent={entry['intent']} channel={entry['channel']}"
            )
        return True
    if name == ":ping":
        if len(tokens) < 2:
            print("Usage: :ping <remote> [intent] [key=value ...]")
            return True
        remote = tokens[1]
        intent = tokens[2] if len(tokens) > 2 else "sync"
        metadata_tokens: Iterable[str] = tokens[3:]
        payload: dict[str, str] = {}
        for item in metadata_tokens:
            if "=" not in item:
                print(f"Ignoring metadata token '{item}' (missing '=')")
                continue
            key, value = item.split("=", 1)
            payload[key] = value
        handshake = coordinator.ping_remote(remote_node=remote, intent=intent, payload=payload)
        print(
            f"Handshake queued → {handshake['to']} intent={handshake['intent']} "
            f"channel={handshake['channel']}"
        )
        return True
    print(f"Unknown command: {command}")
    return True
"""Command-line interface for Lucidia.

Provides a tiny REPL so users can run Python snippets. On startup,
Lucidia introduces herself with a short message about her origins and
abilities.
"""

from __future__ import annotations

import io
from contextlib import redirect_stdout


def main() -> None:
    """Run the Lucidia REPL."""

    coordinator = HarmonyCoordinator(
        local_node="lucidia",
        role="hologram-console",
        status="booting",
        capabilities=CAPABILITIES,
        channels=CHANNELS,
    )
    coordinator.update_local_status(
        role="hologram-console",
        status="ready",
        capabilities=CAPABILITIES,
        channels=CHANNELS,
    )

    _print_intro()
    while True:
        try:
            code = input(PROMPT)
        except EOFError:
            print()
            break
        stripped = code.strip()
        if not stripped:
            continue
        lowered = stripped.lower()
        if lowered in {"exit", "quit"}:
            break
        if stripped.startswith(":"):
            if not _handle_command(stripped, coordinator):
                break
            continue
    print("Hello, I'm Lucidia. I was built by BlackRoad!")
    print("I love coding, can talk, and I'm super fast.")
    print("Type Python code to run it. Enter 'exit' to quit.")
    while True:
        try:
            code = input("lucidia> ")
        except EOFError:
            print()
            break
        if not code.strip() or code.strip().lower() in {"exit", "quit"}:
            break
        local_vars: dict[str, object] = {}
        stdout = io.StringIO()
        try:
            with redirect_stdout(stdout):
                exec(code, {"__builtins__": {"print": print}}, local_vars)
            output = stdout.getvalue().strip()
            if output:
                print(output)
        except Exception as exc:  # noqa: BLE001 - broad for user feedback
            print(f"Error: {exc}")
    coordinator.update_local_status(
        role="hologram-console",
        status="offline",
        capabilities=CAPABILITIES,
        channels=CHANNELS,
    )
    print("Goodbye!")


if __name__ == "__main__":
    main()
