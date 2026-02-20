#!/usr/bin/env python3
# BlackRoad Visual Engine — Python side

BR = {
    "ORANGE": 208,
    "AMBER": 202,
    "PINK": 198,
    "MAGENTA": 163,
    "PURPLE": 135,
    "BLUE": 33,
    "CYAN": 39,
    "GREEN": 82,
    "RED": 196,
    "WHITE": 255,
}

GRADIENT_CORE = [
    BR["ORANGE"],
    BR["AMBER"],
    BR["PINK"],
    BR["MAGENTA"],
    BR["BLUE"],
]

def fg(c, s):
    return f"\033[38;5;{c}m{s}\033[0m"

def bold(c, s):
    return f"\033[1;38;5;{c}m{s}\033[0m"

def gradient(colors, steps):
    out = []
    segments = len(colors) - 1
    for i in range(steps):
        t = i / max(steps - 1, 1)
        seg = min(int(t * segments), segments - 1)
        local = (t - seg / segments) * segments
        c0, c1 = colors[seg], colors[seg + 1]
        out.append(round(c0 + (c1 - c0) * local))
    return out

def diamond():
    shape = [
        "    ▲    ",
        "   ╱ ╲   ",
        "  ╱   ╲  ",
        " ◇   ●   ◇ ",
        "  ╲   ╱  ",
        "   ╲ ╱   ",
        "    ▼    ",
    ]
    cols = gradient(GRADIENT_CORE, len(shape))
    for c, line in zip(cols, shape):
        print(fg(c, line.replace("●", fg(BR["WHITE"], "●"))))

def road():
    widths = [20, 16, 12, 8, 5, 3, 1]
    cols = gradient(GRADIENT_CORE, len(widths))
    for w, c in zip(widths, cols):
        pad = " " * (12 - w // 2)
        if w == 1:
            print(pad + fg(BR["WHITE"], "◉"))
        else:
            print(pad + fg(c, "▌") + " " * (w - 2) + fg(c, "▐"))

ICONS = ["◆","◇","●","○","■","□","▲","△","▼","▽","▶","▷","◀","◁","★","☆"]

def icon_atlas():
    cols = gradient(GRADIENT_CORE, 256)
    i = 0
    for r in range(16):
        row = ""
        for c in range(16):
            row += fg(cols[i], ICONS[i % len(ICONS)] + " ")
            i += 1
        print(row)

if __name__ == "__main__":
    print(bold(BR["MAGENTA"], "\n◆ BLACKROAD VISUAL SYSTEM ◆\n"))
    diamond()
    print()
    road()
    print("\n◆ ICON ATLAS ◆\n")
    icon_atlas()

