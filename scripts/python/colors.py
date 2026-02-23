#!/usr/bin/env python3
"""
BlackRoad OS - Canonical Terminal Color System
==============================================

Official palette (xterm-256):
  ORANGE  = 208
  AMBER   = 202
  PINK    = 198
  MAGENTA = 163
  BLUE    = 33
  WHITE   = 255
  BLACK   = 0

This is the single source of truth for BlackRoad terminal colors.
SSH-safe. tmux-safe. No RGB drift. No dependencies.
"""

BR = {
    "ORANGE": 208,
    "AMBER": 202,
    "PINK": 198,
    "MAGENTA": 163,
    "BLUE": 33,
    "WHITE": 255,
    "BLACK": 0,
}

def fg(c): return f"\033[38;5;{c}m"
def bg(c): return f"\033[48;5;{c}m"
RESET = "\033[0m"
BOLD = "\033[1m"
DIM = "\033[2m"

def br_text(text, color, bold=False, dim=False):
    """Render text in BlackRoad color"""
    prefix = ""
    if bold: prefix += BOLD
    if dim: prefix += DIM
    return f"{prefix}{fg(BR[color])}{text}{RESET}"

def br_block(color, width=6, height=1):
    """Render solid color block"""
    line = f"{bg(BR[color])}{' ' * width}{RESET}"
    return '\n'.join([line] * height)

def br_gradient_line(text, width=None):
    """Render text with BlackRoad gradient (orange → pink → magenta → blue)"""
    if width is None:
        width = len(text)
    
    colors = ["ORANGE", "AMBER", "PINK", "MAGENTA", "BLUE"]
    output = ""
    
    for i, char in enumerate(text[:width]):
        color_index = int((i / width) * (len(colors) - 1))
        output += br_text(char, colors[color_index])
    
    return output

def br_status(label, status, status_type="success"):
    """Render status line"""
    status_colors = {
        "success": "BLUE",
        "warning": "AMBER", 
        "error": "PINK",
        "info": "WHITE"
    }
    symbols = {
        "success": "✔",
        "warning": "▲",
        "error": "✖",
        "info": "●"
    }
    
    color = status_colors.get(status_type, "WHITE")
    symbol = symbols.get(status_type, "●")
    
    return f"{br_text(symbol, color, bold=True)} {label}: {br_text(status, color)}"

def br_header(title, subtitle=None):
    """Render header with BlackRoad styling"""
    output = br_text(f"▣ {title} ▣", "ORANGE", bold=True)
    if subtitle:
        output += "\n" + br_text(subtitle, "BLUE", dim=True)
    return output

def br_box(title, content, width=60):
    """Render content in a colored box"""
    top = br_text("╔" + "═" * (width - 2) + "╗", "ORANGE")
    bottom = br_text("╚" + "═" * (width - 2) + "╝", "ORANGE")
    
    lines = [top]
    if title:
        title_line = f"║ {br_text(title, 'WHITE', bold=True)}"
        padding = width - len(title) - 4
        title_line += " " * padding + br_text("║", "ORANGE")
        lines.append(title_line)
        lines.append(br_text("╠" + "═" * (width - 2) + "╣", "ORANGE"))
    
    for line in content.split('\n'):
        content_line = br_text("║ ", "ORANGE") + line
        padding = width - len(line) - 4
        content_line += " " * padding + br_text("║", "ORANGE")
        lines.append(content_line)
    
    lines.append(bottom)
    return '\n'.join(lines)

def br_banner():
    """Render BlackRoad ASCII banner"""
    banner = """
██████  ██       █████   ██████ ██   ██ ██████   ██████   █████  ██████  
██   ██ ██      ██   ██ ██      ██  ██  ██   ██ ██    ██ ██   ██ ██   ██ 
██████  ██      ███████ ██      █████   ██████  ██    ██ ███████ ██   ██ 
██   ██ ██      ██   ██ ██      ██  ██  ██   ██ ██    ██ ██   ██ ██   ██ 
██████  ███████ ██   ██  ██████ ██   ██ ██   ██  ██████  ██   ██ ██████  
    """
    return br_gradient_line(banner, len(banner))

def demo():
    """Demonstrate all BlackRoad color capabilities"""
    print(br_banner())
    print()
    print(br_header("BLACKROAD COLOR PALETTE", "xterm-256 canonical system"))
    print()
    
    # Color swatches
    for name in ["ORANGE", "AMBER", "PINK", "MAGENTA", "BLUE", "WHITE"]:
        print(f"{br_block(name)} {br_text(f'{name:8} = {BR[name]:3}', name, bold=True)}")
    
    print()
    print(br_text("═" * 60, "ORANGE"))
    print()
    
    # Status examples
    print(br_status("System", "ONLINE", "success"))
    print(br_status("Network", "DEGRADED", "warning"))
    print(br_status("Database", "ERROR", "error"))
    print(br_status("Cache", "Ready", "info"))
    
    print()
    print(br_text("═" * 60, "ORANGE"))
    print()
    
    # Gradient demo
    print(br_gradient_line("BlackRoad OS - Operator-Controlled • Local-First • Sovereign", 60))
    
    print()
    print(br_text("═" * 60, "ORANGE"))
    print()
    
    # Box demo
    content = br_text("Infrastructure Identity", "BLUE", bold=True) + "\n"
    content += br_text("No RGB drift. SSH-safe. tmux-safe.", "WHITE", dim=True)
    print(br_box("CANONICAL COLOR SYSTEM", content, 60))

if __name__ == "__main__":
    demo()
