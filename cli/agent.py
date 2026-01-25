"""Command line entrypoint for running the BlackRoad personal agent locally."""

from __future__ import annotations

import argparse
from pathlib import Path

from agent import AgentConfig, AgentRuntime
from agent.config import PluginMount
from plugins.base import BasePlugin


class EchoPlugin(BasePlugin):
    """Default plugin placeholder that simply echoes the user input."""

    name = "echo"

    def handle(self, message: str, context):  # type: ignore[override]
        return message


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Run the BlackRoad personal agent")
    parser.add_argument("message", nargs="?", default="hello", help="Seed message to send to the agent")
    parser.add_argument(
        "--workspace",
        type=Path,
        default=Path.cwd() / "workspace",
        help="Location for the agent's persistent workspace",
    )
    return parser


def main(argv: list[str] | None = None) -> str:
    parser = build_parser()
    args = parser.parse_args(argv)

    config = AgentConfig(
        name="blackroad-bff",
        persona="north star navigator",
        workspace_root=args.workspace,
        mounts=[PluginMount(name="echo", module="plugins.base", enabled=True)],
        notes="Seed runtime wiring the real agent will extend.",
    )
    runtime = AgentRuntime(config, plugins=[EchoPlugin()])
    runtime.bootstrap()
    return runtime.dispatch(args.message, {"workspace": str(args.workspace)})


if __name__ == "__main__":
    print(main())
