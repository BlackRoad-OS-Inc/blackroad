"""
RoadColor - Color Manipulation for BlackRoad
Color conversion, blending, and palette generation.
"""

from dataclasses import dataclass
from typing import List, Tuple, Union
import colorsys
import logging
import re

logger = logging.getLogger(__name__)


@dataclass
class RGB:
    r: int
    g: int
    b: int

    def __post_init__(self):
        self.r = max(0, min(255, self.r))
        self.g = max(0, min(255, self.g))
        self.b = max(0, min(255, self.b))

    def to_hex(self) -> str:
        return f"#{self.r:02x}{self.g:02x}{self.b:02x}"

    def to_hsl(self) -> "HSL":
        r, g, b = self.r / 255, self.g / 255, self.b / 255
        h, l, s = colorsys.rgb_to_hls(r, g, b)
        return HSL(int(h * 360), int(s * 100), int(l * 100))

    def to_hsv(self) -> "HSV":
        r, g, b = self.r / 255, self.g / 255, self.b / 255
        h, s, v = colorsys.rgb_to_hsv(r, g, b)
        return HSV(int(h * 360), int(s * 100), int(v * 100))

    def to_tuple(self) -> Tuple[int, int, int]:
        return (self.r, self.g, self.b)

    def luminance(self) -> float:
        r, g, b = self.r / 255, self.g / 255, self.b / 255
        return 0.2126 * r + 0.7152 * g + 0.0722 * b

    def is_light(self) -> bool:
        return self.luminance() > 0.5

    def is_dark(self) -> bool:
        return self.luminance() <= 0.5


@dataclass
class HSL:
    h: int  # 0-360
    s: int  # 0-100
    l: int  # 0-100

    def __post_init__(self):
        self.h = self.h % 360
        self.s = max(0, min(100, self.s))
        self.l = max(0, min(100, self.l))

    def to_rgb(self) -> RGB:
        h, s, l = self.h / 360, self.s / 100, self.l / 100
        r, g, b = colorsys.hls_to_rgb(h, l, s)
        return RGB(int(r * 255), int(g * 255), int(b * 255))

    def to_hex(self) -> str:
        return self.to_rgb().to_hex()

    def to_css(self) -> str:
        return f"hsl({self.h}, {self.s}%, {self.l}%)"


@dataclass
class HSV:
    h: int  # 0-360
    s: int  # 0-100
    v: int  # 0-100

    def __post_init__(self):
        self.h = self.h % 360
        self.s = max(0, min(100, self.s))
        self.v = max(0, min(100, self.v))

    def to_rgb(self) -> RGB:
        h, s, v = self.h / 360, self.s / 100, self.v / 100
        r, g, b = colorsys.hsv_to_rgb(h, s, v)
        return RGB(int(r * 255), int(g * 255), int(b * 255))

    def to_hex(self) -> str:
        return self.to_rgb().to_hex()


class Color:
    def __init__(self, color: Union[str, RGB, HSL, HSV, Tuple[int, int, int]]):
        if isinstance(color, str):
            self.rgb = self._parse_string(color)
        elif isinstance(color, RGB):
            self.rgb = color
        elif isinstance(color, HSL):
            self.rgb = color.to_rgb()
        elif isinstance(color, HSV):
            self.rgb = color.to_rgb()
        elif isinstance(color, tuple):
            self.rgb = RGB(*color)
        else:
            raise ValueError(f"Unknown color format: {type(color)}")

    def _parse_string(self, color: str) -> RGB:
        color = color.strip().lower()
        
        if color.startswith("#"):
            return self._parse_hex(color)
        elif color.startswith("rgb"):
            return self._parse_rgb_string(color)
        elif color.startswith("hsl"):
            return self._parse_hsl_string(color)
        elif color in NAMED_COLORS:
            return self._parse_hex(NAMED_COLORS[color])
        
        raise ValueError(f"Unknown color format: {color}")

    def _parse_hex(self, hex_str: str) -> RGB:
        hex_str = hex_str.lstrip("#")
        if len(hex_str) == 3:
            hex_str = "".join(c * 2 for c in hex_str)
        return RGB(
            int(hex_str[0:2], 16),
            int(hex_str[2:4], 16),
            int(hex_str[4:6], 16)
        )

    def _parse_rgb_string(self, rgb_str: str) -> RGB:
        match = re.match(r"rgba?\((\d+),\s*(\d+),\s*(\d+)", rgb_str)
        if match:
            return RGB(int(match.group(1)), int(match.group(2)), int(match.group(3)))
        raise ValueError(f"Invalid RGB string: {rgb_str}")

    def _parse_hsl_string(self, hsl_str: str) -> RGB:
        match = re.match(r"hsla?\((\d+),\s*(\d+)%?,\s*(\d+)%?", hsl_str)
        if match:
            return HSL(int(match.group(1)), int(match.group(2)), int(match.group(3))).to_rgb()
        raise ValueError(f"Invalid HSL string: {hsl_str}")

    def hex(self) -> str:
        return self.rgb.to_hex()

    def hsl(self) -> HSL:
        return self.rgb.to_hsl()

    def hsv(self) -> HSV:
        return self.rgb.to_hsv()

    def lighten(self, amount: int = 10) -> "Color":
        hsl = self.rgb.to_hsl()
        hsl.l = min(100, hsl.l + amount)
        return Color(hsl)

    def darken(self, amount: int = 10) -> "Color":
        hsl = self.rgb.to_hsl()
        hsl.l = max(0, hsl.l - amount)
        return Color(hsl)

    def saturate(self, amount: int = 10) -> "Color":
        hsl = self.rgb.to_hsl()
        hsl.s = min(100, hsl.s + amount)
        return Color(hsl)

    def desaturate(self, amount: int = 10) -> "Color":
        hsl = self.rgb.to_hsl()
        hsl.s = max(0, hsl.s - amount)
        return Color(hsl)

    def invert(self) -> "Color":
        return Color(RGB(255 - self.rgb.r, 255 - self.rgb.g, 255 - self.rgb.b))

    def grayscale(self) -> "Color":
        gray = int(self.rgb.luminance() * 255)
        return Color(RGB(gray, gray, gray))

    def complement(self) -> "Color":
        hsl = self.rgb.to_hsl()
        hsl.h = (hsl.h + 180) % 360
        return Color(hsl)

    def blend(self, other: "Color", ratio: float = 0.5) -> "Color":
        r = int(self.rgb.r * (1 - ratio) + other.rgb.r * ratio)
        g = int(self.rgb.g * (1 - ratio) + other.rgb.g * ratio)
        b = int(self.rgb.b * (1 - ratio) + other.rgb.b * ratio)
        return Color(RGB(r, g, b))

    def contrast_ratio(self, other: "Color") -> float:
        l1 = self.rgb.luminance() + 0.05
        l2 = other.rgb.luminance() + 0.05
        return max(l1, l2) / min(l1, l2)

    def is_light(self) -> bool:
        return self.rgb.is_light()


class Palette:
    @staticmethod
    def analogous(base: Color, count: int = 5, spread: int = 30) -> List[Color]:
        hsl = base.hsl()
        colors = []
        start = hsl.h - (spread * (count - 1) // 2)
        for i in range(count):
            colors.append(Color(HSL((start + spread * i) % 360, hsl.s, hsl.l)))
        return colors

    @staticmethod
    def complementary(base: Color) -> List[Color]:
        return [base, base.complement()]

    @staticmethod
    def triadic(base: Color) -> List[Color]:
        hsl = base.hsl()
        return [
            base,
            Color(HSL((hsl.h + 120) % 360, hsl.s, hsl.l)),
            Color(HSL((hsl.h + 240) % 360, hsl.s, hsl.l))
        ]

    @staticmethod
    def split_complementary(base: Color, spread: int = 30) -> List[Color]:
        hsl = base.hsl()
        return [
            base,
            Color(HSL((hsl.h + 180 - spread) % 360, hsl.s, hsl.l)),
            Color(HSL((hsl.h + 180 + spread) % 360, hsl.s, hsl.l))
        ]

    @staticmethod
    def monochromatic(base: Color, count: int = 5) -> List[Color]:
        hsl = base.hsl()
        colors = []
        step = 80 // count
        start = max(10, hsl.l - step * count // 2)
        for i in range(count):
            colors.append(Color(HSL(hsl.h, hsl.s, min(90, start + step * i))))
        return colors

    @staticmethod
    def gradient(start: Color, end: Color, steps: int = 5) -> List[Color]:
        colors = []
        for i in range(steps):
            ratio = i / (steps - 1) if steps > 1 else 0
            colors.append(start.blend(end, ratio))
        return colors


NAMED_COLORS = {
    "black": "#000000", "white": "#ffffff", "red": "#ff0000",
    "green": "#00ff00", "blue": "#0000ff", "yellow": "#ffff00",
    "cyan": "#00ffff", "magenta": "#ff00ff", "orange": "#ffa500",
    "purple": "#800080", "pink": "#ffc0cb", "brown": "#a52a2a",
    "gray": "#808080", "grey": "#808080", "navy": "#000080",
    "teal": "#008080", "olive": "#808000", "maroon": "#800000",
    "aqua": "#00ffff", "lime": "#00ff00", "silver": "#c0c0c0",
}


def example_usage():
    c1 = Color("#ff6b6b")
    print(f"Color: {c1.hex()}")
    print(f"HSL: {c1.hsl()}")
    print(f"Is light: {c1.is_light()}")
    
    print(f"\nManipulations:")
    print(f"Lighten: {c1.lighten(20).hex()}")
    print(f"Darken: {c1.darken(20).hex()}")
    print(f"Complement: {c1.complement().hex()}")
    print(f"Grayscale: {c1.grayscale().hex()}")
    
    c2 = Color("blue")
    print(f"\nBlend with blue: {c1.blend(c2, 0.5).hex()}")
    print(f"Contrast ratio: {c1.contrast_ratio(Color('white')):.2f}")
    
    print(f"\nPalettes from {c1.hex()}:")
    print(f"Analogous: {[c.hex() for c in Palette.analogous(c1)]}")
    print(f"Triadic: {[c.hex() for c in Palette.triadic(c1)]}")
    print(f"Monochromatic: {[c.hex() for c in Palette.monochromatic(c1)]}")
    
    print(f"\nGradient red->blue:")
    gradient = Palette.gradient(Color("red"), Color("blue"), 5)
    print(f"{[c.hex() for c in gradient]}")

