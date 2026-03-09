#!/usr/bin/env python3
"""
BlackRoad Salesforce Agent - Entry Point

Runs autonomous Salesforce agents on the Pi cluster.
Deploy 500+ instances on Octavia for maximum throughput.

Usage:
    python -m src.main --config config/config.yaml
    python -m src.main --config config/config.yaml --workers 8
"""

import os
import sys
import argparse
import yaml
from pathlib import Path
import structlog

from .agents import SalesforceAgent
from .agents.salesforce_agent import AgentConfig

# Configure structured logging
structlog.configure(
    processors=[
        structlog.stdlib.filter_by_level,
        structlog.stdlib.add_logger_name,
        structlog.stdlib.add_log_level,
        structlog.stdlib.PositionalArgumentsFormatter(),
        structlog.processors.TimeStamper(fmt="iso"),
        structlog.processors.StackInfoRenderer(),
        structlog.processors.format_exc_info,
        structlog.processors.UnicodeDecoder(),
        structlog.dev.ConsoleRenderer() if sys.stdout.isatty() else structlog.processors.JSONRenderer()
    ],
    wrapper_class=structlog.stdlib.BoundLogger,
    context_class=dict,
    logger_factory=structlog.stdlib.LoggerFactory(),
    cache_logger_on_first_use=True,
)

logger = structlog.get_logger()


def load_config(config_path: str) -> dict:
    """Load configuration from YAML file"""
    path = Path(config_path).expanduser()

    if not path.exists():
        raise FileNotFoundError(f"Config file not found: {path}")

    with open(path) as f:
        config = yaml.safe_load(f)

    # Override with environment variables
    env_overrides = {
        "SF_CLIENT_ID": ("salesforce", "client_id"),
        "SF_CLIENT_SECRET": ("salesforce", "client_secret"),
        "SF_USERNAME": ("salesforce", "username"),
        "SF_PASSWORD": ("salesforce", "password"),
        "SF_SECURITY_TOKEN": ("salesforce", "security_token"),
        "SF_DOMAIN": ("salesforce", "domain"),
    }

    for env_var, (section, key) in env_overrides.items():
        value = os.environ.get(env_var)
        if value:
            if section not in config:
                config[section] = {}
            config[section][key] = value

    return config


def create_agent_config(config: dict, workers: int = None) -> AgentConfig:
    """Create AgentConfig from loaded configuration"""
    sf = config.get("salesforce", {})
    agent = config.get("agent", {})
    queue = config.get("queue", {})

    return AgentConfig(
        # Salesforce auth
        client_id=sf.get("client_id", ""),
        client_secret=sf.get("client_secret", ""),
        username=sf.get("username", ""),
        password=sf.get("password", ""),
        security_token=sf.get("security_token", ""),
        domain=sf.get("domain", "login"),

        # Agent settings
        agent_id=agent.get("id"),
        max_workers=workers or agent.get("max_workers", 4),
        poll_interval=agent.get("poll_interval", 1.0),
        batch_size=agent.get("batch_size", 200),

        # Queue settings
        queue_backend=queue.get("backend", "sqlite"),
        queue_db_path=queue.get("db_path", "~/.blackroad/task_queue.db"),
    )


def main():
    parser = argparse.ArgumentParser(
        description="BlackRoad Salesforce Agent - Autonomous CRM operations"
    )
    parser.add_argument(
        "--config", "-c",
        default="config/config.yaml",
        help="Path to configuration file"
    )
    parser.add_argument(
        "--workers", "-w",
        type=int,
        help="Number of worker threads (overrides config)"
    )
    parser.add_argument(
        "--agent-id",
        help="Custom agent ID (default: auto-generated)"
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Validate config without starting agent"
    )

    args = parser.parse_args()

    try:
        # Load configuration
        logger.info("loading_config", path=args.config)
        config = load_config(args.config)

        # Create agent config
        agent_config = create_agent_config(config, args.workers)

        if args.agent_id:
            agent_config.agent_id = args.agent_id

        if args.dry_run:
            logger.info("config_validated", agent_id=agent_config.agent_id)
            print("Configuration valid. Ready to start.")
            return

        # Create and start agent
        agent = SalesforceAgent(agent_config)

        logger.info("starting_agent",
                   agent_id=agent.agent_id,
                   workers=agent_config.max_workers,
                   queue_backend=agent_config.queue_backend)

        print(f"""
╔══════════════════════════════════════════════════════════════╗
║           BlackRoad Salesforce Agent v1.0                   ║
╠══════════════════════════════════════════════════════════════╣
║  Agent ID:  {agent.agent_id:<46} ║
║  Workers:   {agent_config.max_workers:<46} ║
║  Queue:     {agent_config.queue_backend:<46} ║
║  Domain:    {agent_config.domain:<46} ║
╠══════════════════════════════════════════════════════════════╣
║  $330/mo for unlimited scale. Fortune 500 pays $10M+.       ║
╚══════════════════════════════════════════════════════════════╝
""")

        agent.start()

    except FileNotFoundError as e:
        logger.error("config_not_found", error=str(e))
        sys.exit(1)
    except KeyboardInterrupt:
        logger.info("interrupted")
    except Exception as e:
        logger.exception("agent_error", error=str(e))
        sys.exit(1)


if __name__ == "__main__":
    main()
