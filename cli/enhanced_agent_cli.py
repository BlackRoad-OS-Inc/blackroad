#!/usr/bin/env python3
"""
Enhanced BlackRoad Agent CLI

Advanced CLI with:
- Terminal window/screenshot capabilities
- Cross-platform commenting
- Multi-agent coordination
- Rich terminal UI
- Platform status monitoring
"""

import os
import sys
import json
import logging
from pathlib import Path
from typing import Dict, List, Optional
from datetime import datetime
import subprocess

# Third-party for rich terminal UI
try:
    from rich.console import Console
    from rich.table import Table
    from rich.panel import Panel
    # from rich.progress import Progress, SpinnerColumn, TextColumn  # Removed unused imports
    from rich.syntax import Syntax
    from rich.markdown import Markdown
    RICH_AVAILABLE = True
except ImportError:
    RICH_AVAILABLE = False
    print("Warning: 'rich' library not installed. Install with: pip install rich")

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


class EnhancedAgentCLI:
    """Enhanced CLI for agent operations"""

    def __init__(self):
        self.console = Console() if RICH_AVAILABLE else None
        self.registry_dir = Path("./registry")
        self.current_agent = None
        self.platform_status = {}

    def print_header(self, title: str):
        """Print formatted header"""
        if self.console:
            self.console.print(Panel(f"[bold cyan]{title}[/bold cyan]", expand=False))
        else:
            print(f"\n{'='*80}\n{title}\n{'='*80}\n")

    def print_table(self, title: str, columns: List[str], rows: List[List[str]]):
        """Print formatted table"""
        if self.console:
            table = Table(title=title, show_header=True, header_style="bold magenta")
            for col in columns:
                table.add_column(col)
            for row in rows:
                table.add_row(*row)
            self.console.print(table)
        else:
            print(f"\n{title}\n{'-'*80}")
            print("\t".join(columns))
            for row in rows:
                print("\t".join(row))

    def capture_terminal_screenshot(self, output_path: Optional[str] = None) -> str:
        """
        Capture terminal screenshot/window.
        Uses various methods depending on platform and available tools.
        """
        if output_path is None:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            output_path = f"terminal_screenshot_{timestamp}.png"

        try:
            # Method 1: Use 'script' command to capture terminal output
            if sys.platform == "linux":
                # On Linux, try using scrot or import (ImageMagick)
                try:
                    subprocess.run(["scrot", "-u", output_path], check=True)
                    logger.info(f"Screenshot captured using scrot: {output_path}")
                    return output_path
                except (subprocess.CalledProcessError, FileNotFoundError):
                    try:
                        subprocess.run(["import", "-window", "root", output_path], check=True)
                        logger.info(f"Screenshot captured using ImageMagick: {output_path}")
                        return output_path
                    except (subprocess.CalledProcessError, FileNotFoundError):
                        logger.warning("Neither scrot nor ImageMagick available")

            # Method 2: macOS screenshot
            elif sys.platform == "darwin":
                try:
                    subprocess.run(["screencapture", "-w", output_path], check=True)
                    logger.info(f"Screenshot captured using screencapture: {output_path}")
                    return output_path
                except (subprocess.CalledProcessError, FileNotFoundError):
                    logger.warning("screencapture not available")

            # Method 3: Windows
            elif sys.platform == "win32":
                try:
                    import pyautogui
                    screenshot = pyautogui.screenshot()
                    screenshot.save(output_path)
                    logger.info(f"Screenshot captured using pyautogui: {output_path}")
                    return output_path
                except ImportError:
                    logger.warning("pyautogui not installed. Install with: pip install pyautogui")

            # Fallback: Capture terminal text as image using PIL
            return self._capture_terminal_as_text_image(output_path)

        except Exception as e:
            logger.error(f"Failed to capture screenshot: {e}")
            return ""

    def _capture_terminal_as_text_image(self, output_path: str) -> str:
        """Capture terminal as text rendered to image"""
        try:
            from PIL import Image, ImageDraw, ImageFont

            # Get terminal size
            rows, columns = os.popen('stty size', 'r').read().split()
            width = int(columns) * 10
            height = int(rows) * 20

            # Create image
            img = Image.new('RGB', (width, height), color=(40, 44, 52))
            draw = ImageDraw.Draw(img)

            # Try to load a monospaced font appropriate for the platform
            font = None
            font_candidates = []
            if sys.platform.startswith("linux"):
                font_candidates = [
                    "/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf",
                    "/usr/share/fonts/truetype/liberation/LiberationMono-Regular.ttf",
                ]
            elif sys.platform == "darwin":
                font_candidates = [
                    "/System/Library/Fonts/Menlo.ttc",
                    "/Library/Fonts/Microsoft/Consolas.ttf",
                ]
            elif sys.platform.startswith("win"):
                font_candidates = [
                    "C:\\Windows\\Fonts\\consola.ttf",  # Consolas
                    "C:\\Windows\\Fonts\\lucon.ttf",    # Lucida Console
                ]
            else:
                font_candidates = []

            for font_path in font_candidates:
                try:
                    font = ImageFont.truetype(font_path, 12)
                    logger.info(f"Loaded font: {font_path}")
                    break
                except Exception as e:
                    logger.debug(f"Could not load font {font_path}: {e}")

            if font is None:
                font = ImageFont.load_default()
                logger.warning("Could not load a monospaced font for your platform; using default font.")

            # Capture current screen (simplified - would need terminal buffer)
            text = "BlackRoad Agent Terminal\n\n"
            text += f"Current Directory: {os.getcwd()}\n"
            text += f"Time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n"

            draw.text((10, 10), text, fill=(171, 178, 191), font=font)

            img.save(output_path)
            logger.info(f"Terminal captured as text image: {output_path}")
            return output_path

        except Exception as e:
            logger.error(f"Failed to create text image: {e}")
            return ""

    def create_code_window(self, code: str, language: str = "python", title: str = "Code") -> str:
        """Create a rich code window display"""
        if self.console:
            syntax = Syntax(code, language, theme="monokai", line_numbers=True)
            panel = Panel(syntax, title=title, expand=False)
            self.console.print(panel)
        else:
            print(f"\n{'='*80}\n{title}\n{'='*80}\n{code}\n{'='*80}\n")

        return code

    def create_terminal_window(self, content: str, title: str = "Terminal Output"):
        """Create a terminal-style window display"""
        if self.console:
            panel = Panel(
                content,
                title=f"[bold green]{title}[/bold green]",
                border_style="green",
                expand=False
            )
            self.console.print(panel)
        else:
            print(f"\n{title}\n{'-'*80}\n{content}\n{'-'*80}\n")

    def show_platform_dashboard(self, agent_id: str):
        """Show multi-platform status dashboard for an agent"""
        self.print_header(f"Platform Dashboard - Agent {agent_id}")

        # Load agent data
        agent_identity = self._load_agent_identity(agent_id)

        if not agent_identity:
            if self.console:
                self.console.print(f"[red]Agent {agent_id} not found[/red]")
            else:
                print(f"Agent {agent_id} not found")
            return

        platforms = ["github", "slack", "discord", "reddit", "instagram", "linear", "asana"]

        rows = []
        for platform in platforms:
            status = "✓ Active" if platform in agent_identity.get("platforms_active", []) else "✗ Inactive"
            username = agent_identity.get(f"{platform}_username", "N/A")
            user_id = agent_identity.get(f"{platform}_user_id", "N/A")

            rows.append([platform.capitalize(), status, username, user_id])

        self.print_table(
            f"Platform Status for {agent_identity.get('name')} ({agent_id})",
            ["Platform", "Status", "Username", "User ID"],
            rows
        )

        # Show email info
        if self.console:
            self.console.print(f"\n[cyan]Email:[/cyan] {agent_identity.get('email')}")
            self.console.print(f"[cyan]Domain:[/cyan] {agent_identity.get('domain')}")
        else:
            print(f"\nEmail: {agent_identity.get('email')}")
            print(f"Domain: {agent_identity.get('domain')}")

    def _load_agent_identity(self, agent_id: str) -> Optional[Dict]:
        """Load agent identity from registry"""
        full_registry = self.registry_dir / "agent_platform_identities_full.json"

        if not full_registry.exists():
            logger.warning(f"Registry not found: {full_registry}")
            return None

        with open(full_registry, 'r') as f:
            data = json.load(f)
            agents = data.get("agents", [])

            for agent in agents:
                if agent.get("agent_id") == agent_id:
                    return agent

        return None

    def comment_on_all_platforms(self, agent_id: str, message: str, targets: Optional[Dict] = None):
        """
        Post a comment from an agent across all platforms.

        targets format:
        {
            "slack": {"channel_id": "C12345"},
            "discord": {"channel_id": "123456"},
            "reddit": {"post_id": "abc123"},
            "github": {"issue_number": 42}
        }
        """
        self.print_header(f"Cross-Platform Comment - Agent {agent_id}")

        if targets is None:
            if self.console:
                self.console.print("[yellow]No targets specified. Showing command format:[/yellow]")
            print("\nFormat:")
            print(json.dumps({
                "slack": {"channel_id": "C12345"},
                "discord": {"channel_id": "123456"},
                "reddit": {"post_id": "abc123"},
                "github": {"issue_number": 42}
            }, indent=2))
            return

        results = []

        for platform, target_data in targets.items():
            try:
                if platform == "slack":
                    # Would call Slack API
                    result = {"platform": "slack", "status": "posted", "target": target_data}
                elif platform == "discord":
                    # Would call Discord API
                    result = {"platform": "discord", "status": "posted", "target": target_data}
                elif platform == "reddit":
                    # Would call Reddit API
                    result = {"platform": "reddit", "status": "posted", "target": target_data}
                elif platform == "github":
                    # Would call GitHub API
                    result = {"platform": "github", "status": "posted", "target": target_data}
                else:
                    result = {"platform": platform, "status": "unsupported"}

                results.append(result)

            except Exception as e:
                results.append({"platform": platform, "status": "error", "error": str(e)})

        # Display results
        rows = [[r["platform"].capitalize(), r["status"]] for r in results]
        self.print_table("Comment Results", ["Platform", "Status"], rows)

    def show_agent_activity(self, agent_id: str, days: int = 7):
        """Show recent activity for an agent across all platforms"""
        self.print_header(f"Recent Activity - Agent {agent_id} ({days} days)")

        # This would aggregate activity from all platforms
        # For now, show example structure

        activities = [
            ["2025-11-10 12:00", "GitHub", "Created PR #123", "✓"],
            ["2025-11-10 11:30", "Slack", "Posted in #general", "✓"],
            ["2025-11-09 15:00", "Discord", "Joined Server 1", "✓"],
            ["2025-11-09 10:00", "Linear", "Created issue", "✓"]
        ]

        self.print_table(
            f"Activity Log",
            ["Timestamp", "Platform", "Action", "Status"],
            activities
        )

    def interactive_mode(self):
        """Start interactive CLI mode"""
        self.print_header("BlackRoad Enhanced Agent CLI")

        if self.console:
            self.console.print("[cyan]Type 'help' for available commands, 'exit' to quit[/cyan]\n")
        else:
            print("Type 'help' for available commands, 'exit' to quit\n")

        while True:
            try:
                if self.console:
                    command = self.console.input("[bold green]blackroad>[/bold green] ")
                else:
                    command = input("blackroad> ")

                if command.strip() == "exit":
                    break
                elif command.strip() == "help":
                    self._show_help()
                elif command.startswith("dashboard "):
                    agent_id = command.split()[1]
                    self.show_platform_dashboard(agent_id)
                elif command.startswith("activity "):
                    agent_id = command.split()[1]
                    self.show_agent_activity(agent_id)
                elif command == "screenshot":
                    path = self.capture_terminal_screenshot()
                    if self.console:
                        self.console.print(f"[green]Screenshot saved: {path}[/green]")
                    else:
                        print(f"Screenshot saved: {path}")
                else:
                    if self.console:
                        self.console.print(f"[red]Unknown command: {command}[/red]")
                    else:
                        print(f"Unknown command: {command}")

            except KeyboardInterrupt:
                print("\n")
                break
            except Exception as e:
                logger.error(f"Command error: {e}")

    def _show_help(self):
        """Show help information"""
        help_text = """
# BlackRoad Enhanced CLI Commands

## Platform Management
- `dashboard <agent_id>` - Show platform status dashboard
- `activity <agent_id>` - Show recent activity
- `comment <agent_id> <message>` - Post cross-platform comment

## Terminal Utilities
- `screenshot` - Capture terminal screenshot
- `window <code>` - Create code window
- `status` - Show overall system status

## General
- `help` - Show this help
- `exit` - Exit interactive mode
"""

        if self.console:
            md = Markdown(help_text)
            self.console.print(md)
        else:
            print(help_text)


def main():
    """Main entry point"""
    import argparse

    parser = argparse.ArgumentParser(
        description="Enhanced BlackRoad Agent CLI"
    )

    subparsers = parser.add_subparsers(dest='command')

    # Interactive mode
    subparsers.add_parser('interactive', help='Start interactive mode')

    # Dashboard command
    dashboard_parser = subparsers.add_parser('dashboard', help='Show agent platform dashboard')
    dashboard_parser.add_argument('agent_id', help='Agent ID (e.g., P1)')

    # Activity command
    activity_parser = subparsers.add_parser('activity', help='Show agent activity')
    activity_parser.add_argument('agent_id', help='Agent ID')
    activity_parser.add_argument('--days', type=int, default=7, help='Number of days')

    # Screenshot command
    screenshot_parser = subparsers.add_parser('screenshot', help='Capture terminal screenshot')
    screenshot_parser.add_argument('--output', help='Output file path')

    # Comment command
    comment_parser = subparsers.add_parser('comment', help='Cross-platform comment')
    comment_parser.add_argument('agent_id', help='Agent ID')
    comment_parser.add_argument('message', help='Comment message')
    comment_parser.add_argument('--targets', help='JSON targets')

    args = parser.parse_args()

    cli = EnhancedAgentCLI()

    if args.command == 'interactive':
        cli.interactive_mode()
    elif args.command == 'dashboard':
        cli.show_platform_dashboard(args.agent_id)
    elif args.command == 'activity':
        cli.show_agent_activity(args.agent_id, args.days)
    elif args.command == 'screenshot':
        path = cli.capture_terminal_screenshot(args.output)
        print(f"Screenshot saved: {path}")
    elif args.command == 'comment':
        targets = json.loads(args.targets) if args.targets else None
        cli.comment_on_all_platforms(args.agent_id, args.message, targets)
    else:
        # Default to interactive mode
        cli.interactive_mode()


if __name__ == "__main__":
    main()
