"""
RoadTerm - Terminal Utilities for BlackRoad
Terminal detection, cursor control, and screen management.
"""

from dataclasses import dataclass
from enum import Enum
from typing import Optional, Tuple
import os
import sys
import logging

logger = logging.getLogger(__name__)


class Color(str, Enum):
    BLACK = "30"
    RED = "31"
    GREEN = "32"
    YELLOW = "33"
    BLUE = "34"
    MAGENTA = "35"
    CYAN = "36"
    WHITE = "37"
    DEFAULT = "39"
    BRIGHT_BLACK = "90"
    BRIGHT_RED = "91"
    BRIGHT_GREEN = "92"
    BRIGHT_YELLOW = "93"
    BRIGHT_BLUE = "94"
    BRIGHT_MAGENTA = "95"
    BRIGHT_CYAN = "96"
    BRIGHT_WHITE = "97"


class Style(str, Enum):
    RESET = "0"
    BOLD = "1"
    DIM = "2"
    ITALIC = "3"
    UNDERLINE = "4"
    BLINK = "5"
    REVERSE = "7"
    HIDDEN = "8"
    STRIKETHROUGH = "9"


@dataclass
class TermSize:
    columns: int
    rows: int


class Terminal:
    ESC = "\033"
    CSI = f"{ESC}["

    def __init__(self, stream=None):
        self.stream = stream or sys.stdout
        self._is_tty = self.stream.isatty()

    @property
    def is_tty(self) -> bool:
        return self._is_tty

    def size(self) -> TermSize:
        try:
            size = os.get_terminal_size()
            return TermSize(columns=size.columns, rows=size.lines)
        except OSError:
            return TermSize(columns=80, rows=24)

    def write(self, text: str) -> None:
        self.stream.write(text)
        self.stream.flush()

    def writeln(self, text: str = "") -> None:
        self.write(text + "\n")

    def _escape(self, code: str) -> str:
        if self._is_tty:
            return f"{self.CSI}{code}"
        return ""

    def clear(self) -> None:
        self.write(self._escape("2J"))
        self.move(0, 0)

    def clear_line(self) -> None:
        self.write(self._escape("2K"))

    def clear_to_end(self) -> None:
        self.write(self._escape("0J"))

    def move(self, row: int, col: int) -> None:
        self.write(self._escape(f"{row + 1};{col + 1}H"))

    def move_up(self, n: int = 1) -> None:
        self.write(self._escape(f"{n}A"))

    def move_down(self, n: int = 1) -> None:
        self.write(self._escape(f"{n}B"))

    def move_right(self, n: int = 1) -> None:
        self.write(self._escape(f"{n}C"))

    def move_left(self, n: int = 1) -> None:
        self.write(self._escape(f"{n}D"))

    def move_to_column(self, col: int) -> None:
        self.write(self._escape(f"{col + 1}G"))

    def save_cursor(self) -> None:
        self.write(self._escape("s"))

    def restore_cursor(self) -> None:
        self.write(self._escape("u"))

    def hide_cursor(self) -> None:
        self.write(self._escape("?25l"))

    def show_cursor(self) -> None:
        self.write(self._escape("?25h"))

    def set_title(self, title: str) -> None:
        self.write(f"{self.ESC}]0;{title}\007")

    def bell(self) -> None:
        self.write("\007")

    def style(self, *styles: Style) -> str:
        if not self._is_tty:
            return ""
        codes = ";".join(s.value for s in styles)
        return f"{self.CSI}{codes}m"

    def fg(self, color: Color) -> str:
        if not self._is_tty:
            return ""
        return f"{self.CSI}{color.value}m"

    def bg(self, color: Color) -> str:
        if not self._is_tty:
            return ""
        code = str(int(color.value) + 10)
        return f"{self.CSI}{code}m"

    def rgb_fg(self, r: int, g: int, b: int) -> str:
        if not self._is_tty:
            return ""
        return f"{self.CSI}38;2;{r};{g};{b}m"

    def rgb_bg(self, r: int, g: int, b: int) -> str:
        if not self._is_tty:
            return ""
        return f"{self.CSI}48;2;{r};{g};{b}m"

    def reset(self) -> str:
        if not self._is_tty:
            return ""
        return f"{self.CSI}0m"

    def colored(self, text: str, fg: Color = None, bg: Color = None, *styles: Style) -> str:
        if not self._is_tty:
            return text
        prefix = ""
        if styles:
            prefix += self.style(*styles)
        if fg:
            prefix += self.fg(fg)
        if bg:
            prefix += self.bg(bg)
        return f"{prefix}{text}{self.reset()}"


class ProgressBar:
    def __init__(self, total: int, width: int = 40, term: Terminal = None):
        self.total = total
        self.width = width
        self.term = term or Terminal()
        self.current = 0
        self._started = False

    def update(self, current: int = None, message: str = "") -> None:
        if current is not None:
            self.current = current
        else:
            self.current += 1
        
        if self._started:
            self.term.move_up(1)
            self.term.clear_line()
        
        self._started = True
        
        pct = self.current / self.total if self.total > 0 else 0
        filled = int(self.width * pct)
        bar = "█" * filled + "░" * (self.width - filled)
        
        line = f"[{bar}] {pct * 100:5.1f}%"
        if message:
            line += f" {message}"
        
        self.term.writeln(line)

    def finish(self, message: str = "Done!") -> None:
        self.update(self.total, message)


class Spinner:
    FRAMES = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"]

    def __init__(self, message: str = "Loading...", term: Terminal = None):
        self.message = message
        self.term = term or Terminal()
        self._frame = 0
        self._running = False

    def spin(self) -> None:
        self.term.move_to_column(0)
        self.term.clear_line()
        frame = self.FRAMES[self._frame % len(self.FRAMES)]
        self.term.write(f"{frame} {self.message}")
        self._frame += 1

    def stop(self, message: str = None) -> None:
        self.term.move_to_column(0)
        self.term.clear_line()
        if message:
            self.term.writeln(f"✓ {message}")


class Box:
    STYLES = {
        "single": ("┌", "┐", "└", "┘", "─", "│"),
        "double": ("╔", "╗", "╚", "╝", "═", "║"),
        "rounded": ("╭", "╮", "╰", "╯", "─", "│"),
        "heavy": ("┏", "┓", "┗", "┛", "━", "┃"),
    }

    @staticmethod
    def draw(content: str, width: int = None, style: str = "single", term: Terminal = None) -> str:
        term = term or Terminal()
        tl, tr, bl, br, h, v = Box.STYLES.get(style, Box.STYLES["single"])
        
        lines = content.split("\n")
        max_len = max(len(line) for line in lines)
        width = width or max_len + 4
        inner_width = width - 2
        
        result = []
        result.append(tl + h * inner_width + tr)
        for line in lines:
            padded = line.ljust(inner_width)
            result.append(f"{v}{padded}{v}")
        result.append(bl + h * inner_width + br)
        
        return "\n".join(result)


def example_usage():
    term = Terminal()
    
    print(f"Terminal size: {term.size()}")
    print(f"Is TTY: {term.is_tty}")
    
    print(term.colored("Red text", fg=Color.RED))
    print(term.colored("Bold green", fg=Color.GREEN, styles=[Style.BOLD]))
    print(term.colored("Underlined blue", fg=Color.BLUE, styles=[Style.UNDERLINE]))
    
    box = Box.draw("Hello, World!\nThis is a box.", style="rounded")
    print(f"\n{box}")
    
    import time
    
    print("\nProgress bar:")
    progress = ProgressBar(10, term=term)
    for i in range(11):
        progress.update(i, f"Step {i}/10")
        time.sleep(0.1)
    
    print("\nSpinner:")
    spinner = Spinner("Processing...", term=term)
    for _ in range(10):
        spinner.spin()
        time.sleep(0.1)
    spinner.stop("Complete!")

