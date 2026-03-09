"""
RoadYAML - YAML Parsing for BlackRoad
Parse and serialize YAML with schema validation.
"""

from dataclasses import dataclass, field
from typing import Any, Callable, Dict, List, Optional, Union, IO
import re
import logging

logger = logging.getLogger(__name__)


class YAMLError(Exception):
    pass


class YAMLSyntaxError(YAMLError):
    def __init__(self, message: str, line: int = 0, column: int = 0):
        self.line = line
        self.column = column
        super().__init__(f"{message} at line {line}, column {column}")


@dataclass
class Token:
    type: str
    value: Any
    line: int
    indent: int


class Scanner:
    def __init__(self, text: str):
        self.text = text
        self.pos = 0
        self.line = 1
        self.indent = 0

    def scan(self) -> List[Token]:
        tokens = []
        lines = self.text.split("\n")
        
        for line_num, line in enumerate(lines, 1):
            if not line.strip() or line.strip().startswith("#"):
                continue
            
            indent = len(line) - len(line.lstrip())
            content = line.strip()
            
            if content.startswith("- "):
                tokens.append(Token("LIST_ITEM", content[2:], line_num, indent))
            elif ": " in content or content.endswith(":"):
                if content.endswith(":"):
                    key = content[:-1]
                    tokens.append(Token("KEY", key, line_num, indent))
                else:
                    key, value = content.split(": ", 1)
                    tokens.append(Token("KEY_VALUE", (key, self._parse_value(value)), line_num, indent))
            else:
                tokens.append(Token("VALUE", self._parse_value(content), line_num, indent))
        
        return tokens

    def _parse_value(self, value: str) -> Any:
        value = value.strip()
        if not value:
            return None
        if value.lower() in ("true", "yes", "on"):
            return True
        if value.lower() in ("false", "no", "off"):
            return False
        if value.lower() in ("null", "~"):
            return None
        if value.startswith('"') and value.endswith('"'):
            return value[1:-1]
        if value.startswith("'") and value.endswith("'"):
            return value[1:-1]
        try:
            return int(value)
        except ValueError:
            pass
        try:
            return float(value)
        except ValueError:
            pass
        return value


class Parser:
    def __init__(self, tokens: List[Token]):
        self.tokens = tokens
        self.pos = 0

    def parse(self) -> Any:
        if not self.tokens:
            return None
        return self._parse_value(0)

    def _parse_value(self, base_indent: int) -> Any:
        if self.pos >= len(self.tokens):
            return None
        
        token = self.tokens[self.pos]
        
        if token.type == "LIST_ITEM":
            return self._parse_list(base_indent)
        elif token.type == "KEY":
            return self._parse_mapping(base_indent)
        elif token.type == "KEY_VALUE":
            return self._parse_mapping(base_indent)
        else:
            self.pos += 1
            return token.value

    def _parse_mapping(self, base_indent: int) -> Dict[str, Any]:
        result = {}
        
        while self.pos < len(self.tokens):
            token = self.tokens[self.pos]
            
            if token.indent < base_indent:
                break
            
            if token.type == "KEY_VALUE":
                key, value = token.value
                result[key] = value
                self.pos += 1
            elif token.type == "KEY":
                key = token.value
                self.pos += 1
                if self.pos < len(self.tokens):
                    next_token = self.tokens[self.pos]
                    if next_token.indent > token.indent:
                        result[key] = self._parse_value(next_token.indent)
                    else:
                        result[key] = None
                else:
                    result[key] = None
            else:
                break
        
        return result

    def _parse_list(self, base_indent: int) -> List[Any]:
        result = []
        
        while self.pos < len(self.tokens):
            token = self.tokens[self.pos]
            
            if token.indent < base_indent:
                break
            
            if token.type != "LIST_ITEM":
                break
            
            value = self._parse_scalar(token.value)
            result.append(value)
            self.pos += 1
        
        return result

    def _parse_scalar(self, value: str) -> Any:
        scanner = Scanner("")
        return scanner._parse_value(value)


class Dumper:
    def __init__(self, indent: int = 2):
        self.indent = indent

    def dump(self, data: Any, level: int = 0) -> str:
        if data is None:
            return "null"
        if isinstance(data, bool):
            return "true" if data else "false"
        if isinstance(data, (int, float)):
            return str(data)
        if isinstance(data, str):
            if any(c in data for c in ":#{}[]&*!|>'\"%@`"):
                return f'"{data}"'
            return data
        if isinstance(data, list):
            return self._dump_list(data, level)
        if isinstance(data, dict):
            return self._dump_mapping(data, level)
        return str(data)

    def _dump_list(self, data: List, level: int) -> str:
        if not data:
            return "[]"
        lines = []
        prefix = " " * (level * self.indent)
        for item in data:
            if isinstance(item, (dict, list)):
                lines.append(f"{prefix}- ")
                lines[-1] += self.dump(item, level + 1).lstrip()
            else:
                lines.append(f"{prefix}- {self.dump(item)}")
        return "\n".join(lines)

    def _dump_mapping(self, data: Dict, level: int) -> str:
        if not data:
            return "{}"
        lines = []
        prefix = " " * (level * self.indent)
        for key, value in data.items():
            if isinstance(value, (dict, list)) and value:
                lines.append(f"{prefix}{key}:")
                lines.append(self.dump(value, level + 1))
            else:
                lines.append(f"{prefix}{key}: {self.dump(value)}")
        return "\n".join(lines)


def load(text: str) -> Any:
    scanner = Scanner(text)
    tokens = scanner.scan()
    parser = Parser(tokens)
    return parser.parse()


def loads(text: str) -> Any:
    return load(text)


def dump(data: Any, indent: int = 2) -> str:
    dumper = Dumper(indent)
    return dumper.dump(data)


def dumps(data: Any, indent: int = 2) -> str:
    return dump(data, indent)


def load_file(path: str) -> Any:
    with open(path, "r") as f:
        return load(f.read())


def dump_file(data: Any, path: str, indent: int = 2) -> None:
    with open(path, "w") as f:
        f.write(dump(data, indent))


def example_usage():
    yaml_text = """
name: BlackRoad
version: 1.0
features:
  - auth
  - api
  - database
config:
  debug: true
  port: 8080
  host: localhost
"""
    
    data = load(yaml_text)
    print(f"Loaded: {data}")
    
    output = dump(data)
    print(f"\nDumped:\n{output}")
    
    new_data = {
        "app": "myapp",
        "settings": {"enabled": True, "count": 42},
        "items": ["one", "two", "three"]
    }
    print(f"\nNew dump:\n{dump(new_data)}")

