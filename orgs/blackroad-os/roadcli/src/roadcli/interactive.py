"""
RoadCLI Interactive Mode

Rich interactive CLI with prompts and live updates.

Features:
- Interactive prompts
- Live data display
- Progress bars
- Spinners
- Tables
- Auto-completion
"""

from typing import Optional, Dict, Any, List, Callable, TypeVar
from dataclasses import dataclass
from enum import Enum
import sys
import time
import asyncio
from abc import ABC, abstractmethod

try:
    from rich.console import Console
    from rich.table import Table
    from rich.progress import Progress, SpinnerColumn, TextColumn, BarColumn, TaskProgressColumn
    from rich.prompt import Prompt, Confirm, IntPrompt
    from rich.panel import Panel
    from rich.live import Live
    from rich.layout import Layout
    from rich.text import Text
    from rich.markdown import Markdown
    RICH_AVAILABLE = True
except ImportError:
    RICH_AVAILABLE = False

T = TypeVar('T')


class Theme(str, Enum):
    DEFAULT = "default"
    DARK = "dark"
    LIGHT = "light"


@dataclass
class CLIConfig:
    theme: Theme = Theme.DEFAULT
    color: bool = True
    unicode: bool = True
    interactive: bool = True


class BaseDisplay(ABC):
    """Base class for display components."""

    @abstractmethod
    def render(self) -> str:
        pass


class SimpleConsole:
    """Fallback console when Rich is not available."""

    def print(self, *args, **kwargs):
        print(*args)

    def input(self, prompt: str = "") -> str:
        return input(prompt)


def get_console() -> 'Console':
    """Get console instance."""
    if RICH_AVAILABLE:
        return Console()
    return SimpleConsole()


console = get_console()


class InteractivePrompts:
    """Interactive prompt utilities."""

    def __init__(self, console: 'Console' = None):
        self.console = console or get_console()

    def text(
        self,
        message: str,
        default: str = None,
        password: bool = False,
    ) -> str:
        """Prompt for text input."""
        if RICH_AVAILABLE:
            return Prompt.ask(message, default=default, password=password)
        prompt = f"{message}"
        if default:
            prompt += f" [{default}]"
        prompt += ": "
        result = input(prompt)
        return result if result else default or ""

    def confirm(
        self,
        message: str,
        default: bool = False,
    ) -> bool:
        """Prompt for confirmation."""
        if RICH_AVAILABLE:
            return Confirm.ask(message, default=default)
        yn = " [Y/n]" if default else " [y/N]"
        result = input(f"{message}{yn}: ").lower()
        if not result:
            return default
        return result in ('y', 'yes', 'true', '1')

    def number(
        self,
        message: str,
        default: int = None,
        min_value: int = None,
        max_value: int = None,
    ) -> int:
        """Prompt for number input."""
        if RICH_AVAILABLE:
            while True:
                result = IntPrompt.ask(message, default=default)
                if min_value is not None and result < min_value:
                    self.console.print(f"[red]Value must be at least {min_value}[/red]")
                    continue
                if max_value is not None and result > max_value:
                    self.console.print(f"[red]Value must be at most {max_value}[/red]")
                    continue
                return result
        return int(input(f"{message}: ") or default or 0)

    def select(
        self,
        message: str,
        choices: List[str],
        default: int = 0,
    ) -> str:
        """Prompt for selection from list."""
        self.console.print(f"\n{message}")
        for i, choice in enumerate(choices):
            marker = ">" if i == default else " "
            self.console.print(f"  {marker} {i + 1}. {choice}")

        while True:
            selection = self.text("Enter number", str(default + 1))
            try:
                idx = int(selection) - 1
                if 0 <= idx < len(choices):
                    return choices[idx]
            except ValueError:
                pass
            self.console.print("[red]Invalid selection[/red]")

    def multi_select(
        self,
        message: str,
        choices: List[str],
        defaults: List[int] = None,
    ) -> List[str]:
        """Prompt for multiple selections."""
        defaults = defaults or []
        selected = set(defaults)

        self.console.print(f"\n{message}")
        self.console.print("  (Enter numbers separated by commas, or 'all'/'none')")

        for i, choice in enumerate(choices):
            marker = "[x]" if i in selected else "[ ]"
            self.console.print(f"  {marker} {i + 1}. {choice}")

        selection = self.text("Selection", ",".join(str(i + 1) for i in defaults))

        if selection.lower() == 'all':
            return choices
        if selection.lower() == 'none':
            return []

        indices = []
        for part in selection.split(','):
            try:
                idx = int(part.strip()) - 1
                if 0 <= idx < len(choices):
                    indices.append(idx)
            except ValueError:
                pass

        return [choices[i] for i in indices]

    def password(self, message: str = "Password") -> str:
        """Prompt for password (hidden input)."""
        return self.text(message, password=True)


class ProgressDisplay:
    """Progress indicators."""

    def __init__(self, console: 'Console' = None):
        self.console = console or get_console()

    def spinner(self, message: str) -> 'SpinnerContext':
        """Show spinner during operation."""
        return SpinnerContext(self.console, message)

    def progress_bar(
        self,
        total: int,
        description: str = "Progress",
    ) -> 'ProgressBarContext':
        """Show progress bar."""
        return ProgressBarContext(self.console, total, description)

    def multi_progress(self) -> 'MultiProgressContext':
        """Show multiple progress bars."""
        return MultiProgressContext(self.console)


class SpinnerContext:
    """Context manager for spinner."""

    def __init__(self, console: 'Console', message: str):
        self.console = console
        self.message = message
        self._progress = None
        self._task = None

    def __enter__(self):
        if RICH_AVAILABLE:
            self._progress = Progress(
                SpinnerColumn(),
                TextColumn("[progress.description]{task.description}"),
                console=self.console,
            )
            self._progress.start()
            self._task = self._progress.add_task(self.message, total=None)
        else:
            print(f"{self.message}...", end="", flush=True)
        return self

    def __exit__(self, *args):
        if self._progress:
            self._progress.stop()
        else:
            print(" done")

    def update(self, message: str):
        """Update spinner message."""
        if self._progress and self._task is not None:
            self._progress.update(self._task, description=message)


class ProgressBarContext:
    """Context manager for progress bar."""

    def __init__(self, console: 'Console', total: int, description: str):
        self.console = console
        self.total = total
        self.description = description
        self._progress = None
        self._task = None
        self._current = 0

    def __enter__(self):
        if RICH_AVAILABLE:
            self._progress = Progress(
                TextColumn("[progress.description]{task.description}"),
                BarColumn(),
                TaskProgressColumn(),
                console=self.console,
            )
            self._progress.start()
            self._task = self._progress.add_task(self.description, total=self.total)
        return self

    def __exit__(self, *args):
        if self._progress:
            self._progress.stop()
        else:
            print()

    def advance(self, amount: int = 1):
        """Advance progress."""
        self._current += amount
        if self._progress and self._task is not None:
            self._progress.advance(self._task, amount)
        else:
            pct = int(self._current / self.total * 100)
            print(f"\r{self.description}: {pct}%", end="", flush=True)

    def update(self, completed: int):
        """Set completed amount."""
        delta = completed - self._current
        self.advance(delta)


class MultiProgressContext:
    """Context manager for multiple progress bars."""

    def __init__(self, console: 'Console'):
        self.console = console
        self._progress = None
        self._tasks: Dict[str, Any] = {}

    def __enter__(self):
        if RICH_AVAILABLE:
            self._progress = Progress(
                TextColumn("[progress.description]{task.description}"),
                BarColumn(),
                TaskProgressColumn(),
                console=self.console,
            )
            self._progress.start()
        return self

    def __exit__(self, *args):
        if self._progress:
            self._progress.stop()

    def add_task(self, name: str, total: int = 100) -> str:
        """Add a task."""
        if self._progress:
            task_id = self._progress.add_task(name, total=total)
            self._tasks[name] = task_id
        return name

    def advance(self, name: str, amount: int = 1):
        """Advance a task."""
        if self._progress and name in self._tasks:
            self._progress.advance(self._tasks[name], amount)


class TableDisplay:
    """Table display utilities."""

    def __init__(self, console: 'Console' = None):
        self.console = console or get_console()

    def create(
        self,
        title: str = None,
        columns: List[str] = None,
    ) -> 'TableBuilder':
        """Create a table builder."""
        return TableBuilder(self.console, title, columns)

    def show(
        self,
        data: List[Dict[str, Any]],
        title: str = None,
        columns: List[str] = None,
    ):
        """Show data as a table."""
        if not data:
            self.console.print("[dim]No data[/dim]")
            return

        cols = columns or list(data[0].keys())
        builder = self.create(title, cols)

        for row in data:
            builder.add_row([str(row.get(col, "")) for col in cols])

        builder.show()


class TableBuilder:
    """Build and display tables."""

    def __init__(self, console: 'Console', title: str = None, columns: List[str] = None):
        self.console = console
        self._title = title
        self._columns = columns or []
        self._rows: List[List[str]] = []
        self._styles: Dict[int, str] = {}

    def add_column(self, name: str, style: str = None) -> 'TableBuilder':
        """Add a column."""
        self._columns.append(name)
        if style:
            self._styles[len(self._columns) - 1] = style
        return self

    def add_row(self, values: List[str]) -> 'TableBuilder':
        """Add a row."""
        self._rows.append(values)
        return self

    def show(self):
        """Display the table."""
        if RICH_AVAILABLE:
            table = Table(title=self._title)
            for i, col in enumerate(self._columns):
                style = self._styles.get(i)
                table.add_column(col, style=style)

            for row in self._rows:
                table.add_row(*row)

            self.console.print(table)
        else:
            # Simple ASCII table
            if self._title:
                print(f"\n{self._title}")
                print("=" * len(self._title))

            # Header
            print(" | ".join(self._columns))
            print("-" * (sum(len(c) for c in self._columns) + 3 * (len(self._columns) - 1)))

            # Rows
            for row in self._rows:
                print(" | ".join(row))


class LiveDisplay:
    """Live updating display."""

    def __init__(self, console: 'Console' = None):
        self.console = console or get_console()

    def live_table(
        self,
        update_fn: Callable[[], List[Dict[str, Any]]],
        columns: List[str],
        title: str = None,
        refresh_rate: float = 1.0,
    ):
        """Show live-updating table."""
        if not RICH_AVAILABLE:
            # Fallback: just show once
            data = update_fn()
            TableDisplay(self.console).show(data, title, columns)
            return

        def generate_table() -> Table:
            data = update_fn()
            table = Table(title=title)
            for col in columns:
                table.add_column(col)
            for row in data:
                table.add_row(*[str(row.get(col, "")) for col in columns])
            return table

        with Live(generate_table(), console=self.console, refresh_per_second=1/refresh_rate) as live:
            try:
                while True:
                    time.sleep(refresh_rate)
                    live.update(generate_table())
            except KeyboardInterrupt:
                pass

    def dashboard(
        self,
        panels: Dict[str, Callable[[], str]],
        refresh_rate: float = 1.0,
    ):
        """Show dashboard with multiple panels."""
        if not RICH_AVAILABLE:
            for name, fn in panels.items():
                print(f"\n{name}:")
                print(fn())
            return

        def generate_layout() -> Layout:
            layout = Layout()
            panel_layouts = []

            for name, fn in panels.items():
                panel = Panel(fn(), title=name)
                panel_layouts.append(Layout(panel, name=name))

            if len(panel_layouts) <= 2:
                layout.split_row(*panel_layouts)
            else:
                # Split into rows of 2
                rows = []
                for i in range(0, len(panel_layouts), 2):
                    row = Layout()
                    row.split_row(*panel_layouts[i:i+2])
                    rows.append(row)
                layout.split_column(*rows)

            return layout

        with Live(generate_layout(), console=self.console, refresh_per_second=1/refresh_rate) as live:
            try:
                while True:
                    time.sleep(refresh_rate)
                    live.update(generate_layout())
            except KeyboardInterrupt:
                pass


class OutputFormatter:
    """Format output in various styles."""

    def __init__(self, console: 'Console' = None):
        self.console = console or get_console()

    def success(self, message: str):
        """Show success message."""
        if RICH_AVAILABLE:
            self.console.print(f"[green]✓[/green] {message}")
        else:
            print(f"✓ {message}")

    def error(self, message: str):
        """Show error message."""
        if RICH_AVAILABLE:
            self.console.print(f"[red]✗[/red] {message}")
        else:
            print(f"✗ {message}")

    def warning(self, message: str):
        """Show warning message."""
        if RICH_AVAILABLE:
            self.console.print(f"[yellow]⚠[/yellow] {message}")
        else:
            print(f"⚠ {message}")

    def info(self, message: str):
        """Show info message."""
        if RICH_AVAILABLE:
            self.console.print(f"[blue]ℹ[/blue] {message}")
        else:
            print(f"ℹ {message}")

    def header(self, message: str):
        """Show header."""
        if RICH_AVAILABLE:
            self.console.print(Panel(message, style="bold"))
        else:
            print(f"\n{'=' * len(message)}")
            print(message)
            print('=' * len(message))

    def json(self, data: Any):
        """Show formatted JSON."""
        import json as json_module
        if RICH_AVAILABLE:
            from rich.json import JSON
            self.console.print(JSON(json_module.dumps(data)))
        else:
            print(json_module.dumps(data, indent=2))

    def markdown(self, content: str):
        """Render markdown."""
        if RICH_AVAILABLE:
            self.console.print(Markdown(content))
        else:
            print(content)

    def code(self, code: str, language: str = "python"):
        """Show syntax-highlighted code."""
        if RICH_AVAILABLE:
            from rich.syntax import Syntax
            syntax = Syntax(code, language, theme="monokai", line_numbers=True)
            self.console.print(syntax)
        else:
            print(code)


class InteractiveCLI:
    """Main interactive CLI interface."""

    def __init__(self, config: CLIConfig = None):
        self.config = config or CLIConfig()
        self.console = get_console()
        self.prompts = InteractivePrompts(self.console)
        self.progress = ProgressDisplay(self.console)
        self.tables = TableDisplay(self.console)
        self.live = LiveDisplay(self.console)
        self.output = OutputFormatter(self.console)

    def run_wizard(
        self,
        steps: List[Dict[str, Any]],
        on_complete: Callable[[Dict[str, Any]], None] = None,
    ) -> Dict[str, Any]:
        """Run a multi-step wizard."""
        results: Dict[str, Any] = {}

        for i, step in enumerate(steps):
            self.output.header(f"Step {i + 1}/{len(steps)}: {step.get('title', 'Input')}")

            if step.get('description'):
                self.console.print(step['description'])
                self.console.print()

            step_type = step.get('type', 'text')
            name = step['name']

            if step_type == 'text':
                results[name] = self.prompts.text(
                    step.get('message', name),
                    default=step.get('default'),
                )
            elif step_type == 'confirm':
                results[name] = self.prompts.confirm(
                    step.get('message', name),
                    default=step.get('default', False),
                )
            elif step_type == 'select':
                results[name] = self.prompts.select(
                    step.get('message', name),
                    step['choices'],
                    default=step.get('default', 0),
                )
            elif step_type == 'multi_select':
                results[name] = self.prompts.multi_select(
                    step.get('message', name),
                    step['choices'],
                    defaults=step.get('defaults', []),
                )
            elif step_type == 'password':
                results[name] = self.prompts.password(step.get('message', name))
            elif step_type == 'number':
                results[name] = self.prompts.number(
                    step.get('message', name),
                    default=step.get('default'),
                    min_value=step.get('min'),
                    max_value=step.get('max'),
                )

            self.console.print()

        if on_complete:
            on_complete(results)

        return results


# Create global instance
cli = InteractiveCLI()
