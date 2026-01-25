"""Lucidia CLI - Command-line interface for reasoning engines."""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

# Add parent to path for agent imports
sys.path.insert(0, str(Path(__file__).parent.parent))


def main():
    """Main CLI entry point."""
    parser = argparse.ArgumentParser(
        prog="lucidia",
        description="Lucidia: AI reasoning engines for specialized domains",
    )

    subparsers = parser.add_subparsers(dest="command", help="Available commands")

    # List agents
    list_parser = subparsers.add_parser("list", help="List available agents")

    # Run agent
    run_parser = subparsers.add_parser("run", help="Run a specific agent")
    run_parser.add_argument("agent", help="Agent name (physicist, mathematician, etc.)")
    run_parser.add_argument("--query", "-q", help="Query to process")
    run_parser.add_argument("--seed", "-s", help="Path to seed YAML file")

    # API server
    api_parser = subparsers.add_parser("api", help="Start the API server")
    api_parser.add_argument("--host", default="0.0.0.0", help="Host to bind")
    api_parser.add_argument("--port", "-p", type=int, default=8000, help="Port to bind")

    args = parser.parse_args()

    if args.command == "list":
        print("Available Lucidia agents:")
        print()
        agents = [
            ("physicist", "Physics simulations, energy modeling, force calculations"),
            ("mathematician", "Mathematical computations, proofs, symbolic math"),
            ("chemist", "Chemical analysis, reactions, molecular structures"),
            ("geologist", "Geological analysis, terrain modeling, stratigraphy"),
            ("analyst", "Data analysis, pattern recognition, insights"),
            ("architect", "System design, blueprints, architecture planning"),
            ("engineer", "Engineering calculations, structural analysis"),
            ("painter", "Visual generation, graphics, artistic rendering"),
            ("poet", "Creative text, poetry, lyrical composition"),
            ("speaker", "Speech synthesis, NLP, communication"),
            ("navigator", "Pathfinding, navigation, route optimization"),
            ("researcher", "Research synthesis, literature review"),
            ("mediator", "Coordination, conflict resolution"),
            ("builder", "Build systems, construction planning"),
        ]
        for name, desc in agents:
            print(f"  {name:15} - {desc}")
        print()

    elif args.command == "run":
        agent_name = args.agent.lower()
        print(f"Loading {agent_name} agent...")

        try:
            if agent_name == "physicist":
                from physicist import main as agent_main
                agent_main()
            elif agent_name == "mathematician":
                from mathematician import main as agent_main
                agent_main()
            else:
                print(f"Agent '{agent_name}' not yet implemented for CLI mode")
                sys.exit(1)
        except ImportError as e:
            print(f"Error loading agent: {e}")
            sys.exit(1)

    elif args.command == "api":
        print(f"Starting Lucidia API on {args.host}:{args.port}")
        import uvicorn
        from lucidia_core.api import app
        uvicorn.run(app, host=args.host, port=args.port)

    else:
        parser.print_help()


if __name__ == "__main__":
    main()
