"""
RoadConsole - Console Output for BlackRoad
Formatted console output with tables, panels, and syntax highlighting.
"""

from dataclasses import dataclass, field
from typing import Any, Dict, List, Optional, Union
import logging
import sys

logger = logging.getLogger(__name__)


class Align:
    LEFT = "left"
    CENTER = "center"
    RIGHT = "right"


@dataclass
class Column:
    header: str
    key: str = ""
    width: int = 0
    align: str = Align.LEFT
    format_fn: callable = None


class Table:
    def __init__(self, *columns: Union[str, Column]):
        self.columns: List[Column] = []
        for col in columns:
            if isinstance(col, str):
                self.columns.append(Column(header=col, key=col.lower().replace(" ", "_")))
            else:
                self.columns.append(col)
        self.rows: List[Dict[str, Any]] = []

    def add_row(self, *values, **kwargs) -> None:
        if values:
            row = {}
            for i, val in enumerate(values):
                if i < len(self.columns):
                    row[self.columns[i].key] = val
            self.rows.append(row)
        elif kwargs:
            self.rows.append(kwargs)

    def render(self, border: bool = True) -> str:
        widths = self._calculate_widths()
        lines = []
        
        if border:
            lines.append(self._horizontal_line(widths, "top"))
        
        header_cells = []
        for i, col in enumerate(self.columns):
            header_cells.append(self._align_text(col.header, widths[i], col.align))
        lines.append(self._row_line(header_cells, border))
        
        if border:
            lines.append(self._horizontal_line(widths, "middle"))
        
        for row in self.rows:
            cells = []
            for i, col in enumerate(self.columns):
                value = row.get(col.key, "")
                if col.format_fn:
                    value = col.format_fn(value)
                cells.append(self._align_text(str(value), widths[i], col.align))
            lines.append(self._row_line(cells, border))
        
        if border:
            lines.append(self._horizontal_line(widths, "bottom"))
        
        return "\n".join(lines)

    def _calculate_widths(self) -> List[int]:
        widths = []
        for col in self.columns:
            if col.width:
                widths.append(col.width)
            else:
                max_width = len(col.header)
                for row in self.rows:
                    val = str(row.get(col.key, ""))
                    max_width = max(max_width, len(val))
                widths.append(max_width)
        return widths

    def _align_text(self, text: str, width: int, align: str) -> str:
        if align == Align.CENTER:
            return text.center(width)
        elif align == Align.RIGHT:
            return text.rjust(width)
        return text.ljust(width)

    def _horizontal_line(self, widths: List[int], position: str) -> str:
        chars = {"top": ("┌", "┬", "┐"), "middle": ("├", "┼", "┤"), "bottom": ("└", "┴", "┘")}
        left, mid, right = chars[position]
        segments = ["─" * (w + 2) for w in widths]
        return left + mid.join(segments) + right

    def _row_line(self, cells: List[str], border: bool) -> str:
        if border:
            return "│ " + " │ ".join(cells) + " │"
        return "  ".join(cells)


class Panel:
    def __init__(self, content: str, title: str = "", width: int = None, padding: int = 1):
        self.content = content
        self.title = title
        self.width = width
        self.padding = padding

    def render(self) -> str:
        lines = self.content.split("\n")
        max_len = max(len(line) for line in lines)
        width = self.width or max_len + self.padding * 2 + 2
        inner_width = width - 2
        
        result = []
        
        if self.title:
            title_str = f" {self.title} "
            padding = inner_width - len(title_str)
            left_pad = padding // 2
            result.append("╭" + "─" * left_pad + title_str + "─" * (padding - left_pad) + "╮")
        else:
            result.append("╭" + "─" * inner_width + "╮")
        
        for _ in range(self.padding):
            result.append("│" + " " * inner_width + "│")
        
        for line in lines:
            padded = " " * self.padding + line.ljust(inner_width - self.padding * 2) + " " * self.padding
            result.append(f"│{padded}│")
        
        for _ in range(self.padding):
            result.append("│" + " " * inner_width + "│")
        
        result.append("╰" + "─" * inner_width + "╯")
        
        return "\n".join(result)


class Tree:
    def __init__(self, label: str):
        self.label = label
        self.children: List["Tree"] = []

    def add(self, label: str) -> "Tree":
        child = Tree(label)
        self.children.append(child)
        return child

    def render(self, prefix: str = "", is_last: bool = True) -> str:
        connector = "└── " if is_last else "├── "
        lines = [prefix + connector + self.label]
        
        child_prefix = prefix + ("    " if is_last else "│   ")
        for i, child in enumerate(self.children):
            is_last_child = i == len(self.children) - 1
            lines.append(child.render(child_prefix, is_last_child))
        
        return "\n".join(lines)


class Console:
    def __init__(self, stream=None):
        self.stream = stream or sys.stdout

    def print(self, *args, **kwargs) -> None:
        print(*args, file=self.stream, **kwargs)

    def table(self, data: List[Dict], columns: List[str] = None) -> None:
        if not data:
            return
        
        columns = columns or list(data[0].keys())
        table = Table(*columns)
        for row in data:
            table.add_row(**row)
        self.print(table.render())

    def panel(self, content: str, title: str = "", **kwargs) -> None:
        p = Panel(content, title, **kwargs)
        self.print(p.render())

    def tree(self, data: Dict[str, Any], label: str = "root") -> None:
        root = Tree(label)
        self._build_tree(root, data)
        self.print(root.render())

    def _build_tree(self, node: Tree, data: Any) -> None:
        if isinstance(data, dict):
            for key, value in data.items():
                child = node.add(str(key))
                self._build_tree(child, value)
        elif isinstance(data, list):
            for i, item in enumerate(data):
                child = node.add(f"[{i}]")
                self._build_tree(child, item)
        else:
            node.add(str(data))

    def rule(self, title: str = "", char: str = "─", width: int = None) -> None:
        width = width or 80
        if title:
            padding = (width - len(title) - 2) // 2
            self.print(char * padding + f" {title} " + char * padding)
        else:
            self.print(char * width)

    def success(self, message: str) -> None:
        self.print(f"✓ {message}")

    def error(self, message: str) -> None:
        self.print(f"✗ {message}")

    def warning(self, message: str) -> None:
        self.print(f"⚠ {message}")

    def info(self, message: str) -> None:
        self.print(f"ℹ {message}")

    def bullet(self, *items: str, marker: str = "•") -> None:
        for item in items:
            self.print(f"  {marker} {item}")

    def numbered(self, *items: str) -> None:
        for i, item in enumerate(items, 1):
            self.print(f"  {i}. {item}")


def example_usage():
    console = Console()
    
    console.rule("Tables")
    data = [
        {"name": "Alice", "age": 30, "city": "NYC"},
        {"name": "Bob", "age": 25, "city": "LA"},
        {"name": "Charlie", "age": 35, "city": "Chicago"},
    ]
    console.table(data)
    
    console.rule("Panel")
    console.panel("This is a panel with some content.\nIt can have multiple lines.", title="Info")
    
    console.rule("Tree")
    tree_data = {
        "src": {
            "components": ["Button.tsx", "Input.tsx"],
            "utils": ["helpers.ts", "constants.ts"]
        },
        "tests": ["test_main.py"]
    }
    console.tree(tree_data, "project")
    
    console.rule("Messages")
    console.success("Operation completed successfully")
    console.error("Something went wrong")
    console.warning("This might cause issues")
    console.info("Just letting you know")
    
    console.rule("Lists")
    console.bullet("First item", "Second item", "Third item")
    console.numbered("Step one", "Step two", "Step three")

