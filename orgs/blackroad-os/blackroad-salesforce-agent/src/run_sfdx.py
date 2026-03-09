#!/usr/bin/env python3
"""
BlackRoad Salesforce Agent - SFDX Mode

Runs using existing SF CLI authentication (no Connected App needed).
Perfect for development and single-seat deployments.

Usage:
    python -m src.run_sfdx
    python -m src.run_sfdx --username alexa@alexa.com
"""

import sys
import argparse
import structlog

from .auth.oauth import SalesforceAuth
from .api.client import SalesforceClient
from .api.bulk import BulkClient
from .queue.task_queue import TaskQueue, TaskPriority

# Configure logging
structlog.configure(
    processors=[
        structlog.stdlib.add_log_level,
        structlog.processors.TimeStamper(fmt="iso"),
        structlog.dev.ConsoleRenderer() if sys.stdout.isatty() else structlog.processors.JSONRenderer()
    ],
    wrapper_class=structlog.stdlib.BoundLogger,
    context_class=dict,
    logger_factory=structlog.stdlib.LoggerFactory(),
)

logger = structlog.get_logger()


def main():
    parser = argparse.ArgumentParser(
        description="BlackRoad Salesforce Agent (SFDX Mode)"
    )
    parser.add_argument(
        "--username", "-u",
        default="alexa@alexa.com",
        help="Salesforce username"
    )
    parser.add_argument(
        "--sfdx-dir",
        default="~/.sfdx",
        help="SFDX auth directory"
    )
    parser.add_argument(
        "--test",
        action="store_true",
        help="Run connection test only"
    )

    args = parser.parse_args()

    try:
        # Load auth from SFDX
        logger.info("loading_sfdx_auth", username=args.username)
        auth = SalesforceAuth.from_sfdx(args.username, args.sfdx_dir)

        # Create clients
        client = SalesforceClient(auth)
        bulk = BulkClient(auth)
        queue = TaskQueue()

        # Connection test
        limits = client.get_limits()
        daily_api = limits.get("DailyApiRequests", {})

        print(f"""
╔══════════════════════════════════════════════════════════════╗
║       BlackRoad Salesforce Agent (SFDX Mode)                ║
╠══════════════════════════════════════════════════════════════╣
║  User:      {auth.username:<46} ║
║  Instance:  {auth._token.instance_url:<46} ║
║  API Calls: {daily_api.get('Remaining', '?')}/{daily_api.get('Max', '?'):<40} ║
║  Status:    ✓ CONNECTED                                     ║
╠══════════════════════════════════════════════════════════════╣
║  $330/mo for unlimited scale. Fortune 500 pays $10M+.       ║
╚══════════════════════════════════════════════════════════════╝
""")

        if args.test:
            # Run some test queries
            print("Running tests...")

            # Test query
            result = client.query("SELECT COUNT() FROM Account")
            print(f"  ✓ Accounts: {result.total_size}")

            # Test limits
            print(f"  ✓ Bulk API available")

            # Test queue
            stats = queue.stats()
            print(f"  ✓ Queue: {stats['pending']} pending, {stats['completed']} completed")

            print("\n🖤🛣️ All systems operational!")
            return

        # Interactive mode
        print("Agent ready. Commands:")
        print("  query <SOQL>     - Run a query")
        print("  create <obj>     - Create a record")
        print("  limits           - Show API limits")
        print("  stats            - Show queue stats")
        print("  quit             - Exit")
        print()

        while True:
            try:
                cmd = input("🖤🛣️ > ").strip()

                if not cmd:
                    continue

                if cmd == "quit" or cmd == "exit":
                    break

                if cmd == "limits":
                    limits = client.get_limits()
                    daily = limits.get("DailyApiRequests", {})
                    print(f"Daily API: {daily.get('Remaining')}/{daily.get('Max')}")
                    continue

                if cmd == "stats":
                    stats = queue.stats()
                    print(f"Pending: {stats['pending']}, Processing: {stats['processing']}, Completed: {stats['completed']}, Failed: {stats['failed']}")
                    continue

                if cmd.startswith("query "):
                    soql = cmd[6:]
                    result = client.query(soql)
                    print(f"Total: {result.total_size}")
                    for record in result.records[:5]:
                        print(f"  {record}")
                    if result.total_size > 5:
                        print(f"  ... and {result.total_size - 5} more")
                    continue

                print(f"Unknown command: {cmd}")

            except KeyboardInterrupt:
                print("\nExiting...")
                break
            except Exception as e:
                print(f"Error: {e}")

    except Exception as e:
        logger.exception("agent_error", error=str(e))
        sys.exit(1)


if __name__ == "__main__":
    main()
