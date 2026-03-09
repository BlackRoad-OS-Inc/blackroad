"""
RoadTOML - TOML Parsing for BlackRoad
Parse and serialize TOML configuration files.
"""

from dataclasses import dataclass
from datetime import datetime, date, time
from typing import Any, Dict, List, Optional, Union
import re
import logging

logger = logging.getLogger(__name__)


class TOMLError(Exception):
    pass


class TOMLDecodeError(TOMLError):
    def __init__(self, message: str, line: int = 0):
        self.line = line
        super().__init__(f"{message} at line {line}")


class Scanner:
    def __init__(self, text: str):
        self.text = text
        self.lines = text.split("\n")
        self.pos = 0

    def scan(self) -> List[tuple]:
        tokens = []
        current_table = []
        
        for line_num, line in enumerate(self.lines, 1):
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            
            if line.startswith("[[") and line.endswith("]]"):
                table_name = line[2:-2].strip()
                tokens.append(("ARRAY_TABLE", table_name, line_num))
            elif line.startswith("[") and line.endswith("]"):
                table_name = line[1:-1].strip()
                tokens.append(("TABLE", table_name, line_num))
            elif "=" in line:
                key, value = line.split("=", 1)
                key = key.strip()
                value = value.strip()
                tokens.append(("KEY_VALUE", (key, self._parse_value(value)), line_num))
        
        return tokens

    def _parse_value(self, value: str) -> Any:
        value = value.strip()
        
        if value.startswith('"""') or value.startswith("'''"):
            return value[3:-3]
        if value.startswith('"') and value.endswith('"'):
            return self._unescape(value[1:-1])
        if value.startswith("'") and value.endswith("'"):
            return value[1:-1]
        if value.lower() == "true":
            return True
        if value.lower() == "false":
            return False
        if value.startswith("["):
            return self._parse_array(value)
        if value.startswith("{"):
            return self._parse_inline_table(value)
        if re.match(r"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}", value):
            return self._parse_datetime(value)
        if re.match(r"^\d{4}-\d{2}-\d{2}$", value):
            return self._parse_date(value)
        try:
            if "." in value or "e" in value.lower():
                return float(value)
            return int(value)
        except ValueError:
            return value

    def _unescape(self, s: str) -> str:
        replacements = {"\\n": "\n", "\\t": "\t", "\\r": "\r", "\\\\": "\\", '\\"': '"'}
        for old, new in replacements.items():
            s = s.replace(old, new)
        return s

    def _parse_array(self, value: str) -> List:
        content = value[1:-1].strip()
        if not content:
            return []
        items = []
        depth = 0
        current = ""
        for char in content:
            if char in "[{":
                depth += 1
            elif char in "]}":
                depth -= 1
            if char == "," and depth == 0:
                items.append(self._parse_value(current.strip()))
                current = ""
            else:
                current += char
        if current.strip():
            items.append(self._parse_value(current.strip()))
        return items

    def _parse_inline_table(self, value: str) -> Dict:
        content = value[1:-1].strip()
        if not content:
            return {}
        result = {}
        for pair in content.split(","):
            if "=" in pair:
                k, v = pair.split("=", 1)
                result[k.strip()] = self._parse_value(v.strip())
        return result

    def _parse_datetime(self, value: str) -> datetime:
        value = value.replace("Z", "+00:00")
        try:
            return datetime.fromisoformat(value)
        except ValueError:
            return value

    def _parse_date(self, value: str) -> date:
        return date.fromisoformat(value)


class Parser:
    def __init__(self, tokens: List[tuple]):
        self.tokens = tokens

    def parse(self) -> Dict[str, Any]:
        result = {}
        current_table = result
        current_path = []
        array_tables = {}
        
        for token_type, value, line_num in self.tokens:
            if token_type == "TABLE":
                current_path = value.split(".")
                current_table = self._ensure_path(result, current_path)
            elif token_type == "ARRAY_TABLE":
                path = value.split(".")
                parent = self._ensure_path(result, path[:-1]) if len(path) > 1 else result
                key = path[-1]
                if key not in parent:
                    parent[key] = []
                parent[key].append({})
                current_table = parent[key][-1]
            elif token_type == "KEY_VALUE":
                key, val = value
                if "." in key:
                    parts = key.split(".")
                    target = self._ensure_path(current_table, parts[:-1])
                    target[parts[-1]] = val
                else:
                    current_table[key] = val
        
        return result

    def _ensure_path(self, root: Dict, path: List[str]) -> Dict:
        current = root
        for key in path:
            if key not in current:
                current[key] = {}
            current = current[key]
        return current


class Dumper:
    def dump(self, data: Dict[str, Any]) -> str:
        lines = []
        self._dump_table(data, [], lines)
        return "\n".join(lines)

    def _dump_table(self, data: Dict, path: List[str], lines: List[str]) -> None:
        simple_keys = []
        table_keys = []
        array_table_keys = []
        
        for key, value in data.items():
            if isinstance(value, dict):
                table_keys.append(key)
            elif isinstance(value, list) and value and isinstance(value[0], dict):
                array_table_keys.append(key)
            else:
                simple_keys.append(key)
        
        for key in simple_keys:
            lines.append(f"{key} = {self._dump_value(data[key])}")
        
        for key in table_keys:
            new_path = path + [key]
            if lines and lines[-1]:
                lines.append("")
            lines.append(f"[{'.'.join(new_path)}]")
            self._dump_table(data[key], new_path, lines)
        
        for key in array_table_keys:
            new_path = path + [key]
            for item in data[key]:
                if lines and lines[-1]:
                    lines.append("")
                lines.append(f"[[{'.'.join(new_path)}]]")
                self._dump_table(item, new_path, lines)

    def _dump_value(self, value: Any) -> str:
        if value is None:
            return '""'
        if isinstance(value, bool):
            return "true" if value else "false"
        if isinstance(value, str):
            escaped = value.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n")
            return f'"{escaped}"'
        if isinstance(value, (int, float)):
            return str(value)
        if isinstance(value, datetime):
            return value.isoformat()
        if isinstance(value, date):
            return value.isoformat()
        if isinstance(value, list):
            items = [self._dump_value(v) for v in value]
            return f"[{', '.join(items)}]"
        if isinstance(value, dict):
            pairs = [f"{k} = {self._dump_value(v)}" for k, v in value.items()]
            return f"{{ {', '.join(pairs)} }}"
        return str(value)


def load(text: str) -> Dict[str, Any]:
    scanner = Scanner(text)
    tokens = scanner.scan()
    parser = Parser(tokens)
    return parser.parse()


def loads(text: str) -> Dict[str, Any]:
    return load(text)


def dump(data: Dict[str, Any]) -> str:
    dumper = Dumper()
    return dumper.dump(data)


def dumps(data: Dict[str, Any]) -> str:
    return dump(data)


def load_file(path: str) -> Dict[str, Any]:
    with open(path, "r") as f:
        return load(f.read())


def dump_file(data: Dict[str, Any], path: str) -> None:
    with open(path, "w") as f:
        f.write(dump(data))


def example_usage():
    toml_text = """
[package]
name = "blackroad"
version = "1.0.0"
authors = ["BlackRoad Team"]

[dependencies]
requests = "2.28.0"
click = { version = "8.0", optional = true }

[[servers]]
name = "alpha"
ip = "10.0.0.1"

[[servers]]
name = "beta"
ip = "10.0.0.2"
"""
    
    data = load(toml_text)
    print(f"Loaded: {data}")
    
    output = dump(data)
    print(f"\nDumped:\n{output}")

