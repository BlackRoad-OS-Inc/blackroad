"""
RoadRegex - Regular Expression Utilities for BlackRoad
Pattern matching, extraction, and manipulation.
"""

from dataclasses import dataclass, field
from typing import Any, Callable, Dict, Generator, List, Optional, Pattern, Tuple, Union
import re
import logging

logger = logging.getLogger(__name__)


@dataclass
class Match:
    text: str
    start: int
    end: int
    groups: Tuple[str, ...] = field(default_factory=tuple)
    groupdict: Dict[str, str] = field(default_factory=dict)


@dataclass
class PatternInfo:
    pattern: str
    compiled: Pattern
    description: str = ""
    examples: List[str] = field(default_factory=list)


class RegexBuilder:
    def __init__(self):
        self._parts: List[str] = []
        self._flags = 0

    def literal(self, text: str) -> "RegexBuilder":
        self._parts.append(re.escape(text))
        return self

    def any_char(self) -> "RegexBuilder":
        self._parts.append(".")
        return self

    def digit(self) -> "RegexBuilder":
        self._parts.append(r"\d")
        return self

    def digits(self, min_count: int = 1, max_count: int = None) -> "RegexBuilder":
        if max_count is None:
            self._parts.append(rf"\d{{{min_count},}}")
        else:
            self._parts.append(rf"\d{{{min_count},{max_count}}}")
        return self

    def word(self) -> "RegexBuilder":
        self._parts.append(r"\w+")
        return self

    def word_char(self) -> "RegexBuilder":
        self._parts.append(r"\w")
        return self

    def whitespace(self) -> "RegexBuilder":
        self._parts.append(r"\s")
        return self

    def optional(self, pattern: str) -> "RegexBuilder":
        self._parts.append(f"(?:{pattern})?")
        return self

    def group(self, pattern: str, name: str = None) -> "RegexBuilder":
        if name:
            self._parts.append(f"(?P<{name}>{pattern})")
        else:
            self._parts.append(f"({pattern})")
        return self

    def one_of(self, *options: str) -> "RegexBuilder":
        escaped = [re.escape(opt) for opt in options]
        self._parts.append(f"(?:{'|'.join(escaped)})")
        return self

    def char_class(self, chars: str) -> "RegexBuilder":
        self._parts.append(f"[{chars}]")
        return self

    def repeat(self, min_count: int = 0, max_count: int = None) -> "RegexBuilder":
        if max_count is None:
            self._parts.append(f"{{{min_count},}}")
        else:
            self._parts.append(f"{{{min_count},{max_count}}}")
        return self

    def start(self) -> "RegexBuilder":
        self._parts.append("^")
        return self

    def end(self) -> "RegexBuilder":
        self._parts.append("$")
        return self

    def case_insensitive(self) -> "RegexBuilder":
        self._flags |= re.IGNORECASE
        return self

    def multiline(self) -> "RegexBuilder":
        self._flags |= re.MULTILINE
        return self

    def build(self) -> Pattern:
        return re.compile("".join(self._parts), self._flags)

    def pattern(self) -> str:
        return "".join(self._parts)


class CommonPatterns:
    EMAIL = r"[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}"
    URL = r"https?://[^\s/$.?#].[^\s]*"
    PHONE_US = r"\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}"
    DATE_ISO = r"\d{4}-\d{2}-\d{2}"
    DATE_US = r"\d{1,2}/\d{1,2}/\d{2,4}"
    TIME_24H = r"\d{2}:\d{2}(:\d{2})?"
    IPv4 = r"\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}"
    MAC_ADDRESS = r"([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}"
    HEX_COLOR = r"#[0-9A-Fa-f]{3,6}"
    UUID = r"[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}"
    ZIP_US = r"\d{5}(-\d{4})?"
    CREDIT_CARD = r"\d{4}[- ]?\d{4}[- ]?\d{4}[- ]?\d{4}"
    SSN = r"\d{3}-\d{2}-\d{4}"
    USERNAME = r"[a-zA-Z][a-zA-Z0-9_]{2,19}"
    SLUG = r"[a-z0-9]+(?:-[a-z0-9]+)*"


class Regex:
    def __init__(self, pattern: Union[str, Pattern], flags: int = 0):
        if isinstance(pattern, str):
            self.compiled = re.compile(pattern, flags)
        else:
            self.compiled = pattern
        self.pattern = self.compiled.pattern

    def match(self, text: str) -> Optional[Match]:
        m = self.compiled.match(text)
        if m:
            return Match(
                text=m.group(0),
                start=m.start(),
                end=m.end(),
                groups=m.groups(),
                groupdict=m.groupdict()
            )
        return None

    def search(self, text: str) -> Optional[Match]:
        m = self.compiled.search(text)
        if m:
            return Match(
                text=m.group(0),
                start=m.start(),
                end=m.end(),
                groups=m.groups(),
                groupdict=m.groupdict()
            )
        return None

    def find_all(self, text: str) -> List[str]:
        return self.compiled.findall(text)

    def find_iter(self, text: str) -> Generator[Match, None, None]:
        for m in self.compiled.finditer(text):
            yield Match(
                text=m.group(0),
                start=m.start(),
                end=m.end(),
                groups=m.groups(),
                groupdict=m.groupdict()
            )

    def replace(self, text: str, replacement: Union[str, Callable]) -> str:
        return self.compiled.sub(replacement, text)

    def split(self, text: str, maxsplit: int = 0) -> List[str]:
        return self.compiled.split(text, maxsplit)

    def is_match(self, text: str) -> bool:
        return self.compiled.match(text) is not None

    def is_full_match(self, text: str) -> bool:
        return self.compiled.fullmatch(text) is not None


class RegexExtractor:
    def __init__(self):
        self.patterns: Dict[str, Regex] = {}
        self._register_common_patterns()

    def _register_common_patterns(self) -> None:
        for name in dir(CommonPatterns):
            if not name.startswith("_"):
                pattern = getattr(CommonPatterns, name)
                self.patterns[name.lower()] = Regex(pattern, re.IGNORECASE)

    def register(self, name: str, pattern: str, flags: int = 0) -> None:
        self.patterns[name] = Regex(pattern, flags)

    def extract(self, name: str, text: str) -> List[str]:
        regex = self.patterns.get(name)
        if regex:
            return regex.find_all(text)
        return []

    def extract_all(self, text: str) -> Dict[str, List[str]]:
        results = {}
        for name, regex in self.patterns.items():
            matches = regex.find_all(text)
            if matches:
                results[name] = matches
        return results

    def validate(self, name: str, text: str) -> bool:
        regex = self.patterns.get(name)
        if regex:
            return regex.is_full_match(text)
        return False


def example_usage():
    regex = Regex(r"(\w+)@(\w+)\.(\w+)")
    text = "Contact us at info@example.com or support@company.org"
    
    print("Email pattern matches:")
    for match in regex.find_iter(text):
        print(f"  {match.text} at {match.start}-{match.end}")
        print(f"    Groups: {match.groups}")
    
    builder = (RegexBuilder()
        .start()
        .group(r"\d{3}", "area")
        .literal("-")
        .group(r"\d{4}", "number")
        .end())
    
    phone_regex = Regex(builder.build())
    print(f"\nPhone pattern: {builder.pattern()}")
    
    match = phone_regex.match("555-1234")
    if match:
        print(f"Matched: {match.groupdict}")
    
    extractor = RegexExtractor()
    sample = """
    Contact: john@example.com
    Phone: (555) 123-4567
    Website: https://example.com
    Date: 2024-01-15
    IP: 192.168.1.1
    """
    
    print("\nExtracted data:")
    results = extractor.extract_all(sample)
    for name, matches in results.items():
        print(f"  {name}: {matches}")
    
    print(f"\nValidation:")
    print(f"  'test@test.com' is email: {extractor.validate('email', 'test@test.com')}")
    print(f"  '192.168.1.1' is ipv4: {extractor.validate('ipv4', '192.168.1.1')}")

