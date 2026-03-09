"""RoadAI CLI - Command line interface."""

from __future__ import annotations

import argparse
import asyncio
import sys

import httpx


def main():
    """Main CLI entry point."""
    parser = argparse.ArgumentParser(
        description="RoadAI - BlackRoad AI Platform CLI",
        prog="roadai",
    )

    subparsers = parser.add_subparsers(dest="command", help="Commands")

    # Server command
    server_parser = subparsers.add_parser("serve", help="Start the RoadAI server")
    server_parser.add_argument("--host", default="0.0.0.0", help="Host to bind to")
    server_parser.add_argument("--port", type=int, default=8000, help="Port to bind to")
    server_parser.add_argument("--reload", action="store_true", help="Enable auto-reload")

    # Chat command
    chat_parser = subparsers.add_parser("chat", help="Send a chat message")
    chat_parser.add_argument("message", nargs="?", help="Message to send")
    chat_parser.add_argument("--model", "-m", default="gpt-4o-mini", help="Model to use")
    chat_parser.add_argument("--server", "-s", default="http://localhost:8000", help="Server URL")

    # Health command
    health_parser = subparsers.add_parser("health", help="Check server health")
    health_parser.add_argument("--server", "-s", default="http://localhost:8000", help="Server URL")

    args = parser.parse_args()

    if args.command == "serve":
        import uvicorn
        from roadai.main import app
        uvicorn.run(
            "roadai.main:app",
            host=args.host,
            port=args.port,
            reload=args.reload,
        )
    elif args.command == "chat":
        asyncio.run(chat_command(args))
    elif args.command == "health":
        asyncio.run(health_command(args))
    else:
        parser.print_help()


async def chat_command(args):
    """Execute chat command."""
    message = args.message
    if not message:
        # Read from stdin
        message = sys.stdin.read().strip()

    if not message:
        print("Error: No message provided", file=sys.stderr)
        sys.exit(1)

    async with httpx.AsyncClient() as client:
        try:
            response = await client.post(
                f"{args.server}/chat",
                json={
                    "model": args.model,
                    "messages": [{"role": "user", "content": message}],
                },
                timeout=60.0,
            )
            response.raise_for_status()
            data = response.json()

            content = data["choices"][0]["message"]["content"]
            print(content)

            # Print usage info
            usage = data.get("usage", {})
            if usage:
                print(f"\n---")
                print(f"Model: {data['model']} via {data['provider']}")
                print(f"Tokens: {usage.get('total_tokens', 0)}")
                if usage.get("estimated_cost_usd"):
                    print(f"Cost: ${usage['estimated_cost_usd']:.6f}")

        except httpx.HTTPError as e:
            print(f"Error: {e}", file=sys.stderr)
            sys.exit(1)


async def health_command(args):
    """Execute health check command."""
    async with httpx.AsyncClient() as client:
        try:
            response = await client.get(f"{args.server}/health", timeout=10.0)
            response.raise_for_status()
            data = response.json()

            print(f"Status: {data['status']}")
            print("Providers:")
            for name, healthy in data.get("providers", {}).items():
                status = "✓" if healthy else "✗"
                print(f"  {status} {name}")

        except httpx.HTTPError as e:
            print(f"Error: {e}", file=sys.stderr)
            sys.exit(1)


if __name__ == "__main__":
    main()
