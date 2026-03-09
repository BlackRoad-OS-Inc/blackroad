"""
RoadParser - Data Parsing for BlackRoad
Parse JSON, YAML, CSV, XML, and custom formats.
"""

from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum
from typing import Any, Callable, Dict, Generator, List, Optional, TextIO, Tuple, Union
import csv
import io
import json
import logging
import re
import threading
from xml.etree import ElementTree

logger = logging.getLogger(__name__)


class ParseFormat(str, Enum):
    """Parse formats."""
    JSON = "json"
    CSV = "csv"
    XML = "xml"
    INI = "ini"
    QUERY_STRING = "query_string"
    KEY_VALUE = "key_value"


class ParseError(Exception):
    """Parse error with location info."""

    def __init__(self, message: str, line: int = None, column: int = None):
        self.message = message
        self.line = line
        self.column = column
        super().__init__(f"{message} at line {line}, column {column}" if line else message)


@dataclass
class ParseResult:
    """Result of parsing."""
    data: Any
    format: ParseFormat
    errors: List[ParseError] = field(default_factory=list)
    warnings: List[str] = field(default_factory=list)
    metadata: Dict[str, Any] = field(default_factory=dict)

    @property
    def success(self) -> bool:
        return len(self.errors) == 0


@dataclass
class SchemaField:
    """Schema field definition."""
    name: str
    field_type: str  # string, int, float, bool, list, dict
    required: bool = False
    default: Any = None
    validators: List[Callable[[Any], bool]] = field(default_factory=list)


class Parser:
    """Base parser class."""

    def parse(self, content: str) -> ParseResult:
        raise NotImplementedError

    def serialize(self, data: Any) -> str:
        raise NotImplementedError


class JSONParser(Parser):
    """JSON parser with error handling."""

    def __init__(self, strict: bool = True):
        self.strict = strict

    def parse(self, content: str) -> ParseResult:
        """Parse JSON string."""
        errors = []
        warnings = []
        data = None

        try:
            data = json.loads(content)
        except json.JSONDecodeError as e:
            errors.append(ParseError(str(e), e.lineno, e.colno))

            if not self.strict:
                # Try to fix common issues
                try:
                    # Remove trailing commas
                    fixed = re.sub(r',\s*([}\]])', r'\1', content)
                    data = json.loads(fixed)
                    warnings.append("Fixed trailing comma")
                except Exception:
                    pass

        return ParseResult(data=data, format=ParseFormat.JSON, errors=errors, warnings=warnings)

    def serialize(self, data: Any, indent: int = 2) -> str:
        """Serialize to JSON string."""
        return json.dumps(data, indent=indent, default=str)


class CSVParser(Parser):
    """CSV parser."""

    def __init__(
        self,
        delimiter: str = ",",
        has_header: bool = True,
        skip_blank_lines: bool = True
    ):
        self.delimiter = delimiter
        self.has_header = has_header
        self.skip_blank_lines = skip_blank_lines

    def parse(self, content: str) -> ParseResult:
        """Parse CSV string."""
        errors = []
        warnings = []
        data = []

        try:
            reader = csv.reader(io.StringIO(content), delimiter=self.delimiter)
            rows = list(reader)

            if self.has_header and rows:
                headers = rows[0]
                for i, row in enumerate(rows[1:], start=2):
                    if self.skip_blank_lines and not any(row):
                        continue

                    if len(row) != len(headers):
                        warnings.append(f"Row {i} has {len(row)} columns, expected {len(headers)}")

                    data.append(dict(zip(headers, row)))
            else:
                data = rows

        except csv.Error as e:
            errors.append(ParseError(str(e)))

        return ParseResult(
            data=data,
            format=ParseFormat.CSV,
            errors=errors,
            warnings=warnings,
            metadata={"row_count": len(data)}
        )

    def serialize(self, data: List[Dict], headers: List[str] = None) -> str:
        """Serialize to CSV string."""
        if not data:
            return ""

        output = io.StringIO()
        headers = headers or list(data[0].keys())

        writer = csv.DictWriter(output, fieldnames=headers, delimiter=self.delimiter)
        writer.writeheader()
        writer.writerows(data)

        return output.getvalue()


class XMLParser(Parser):
    """XML parser."""

    def __init__(self, strip_namespaces: bool = False):
        self.strip_namespaces = strip_namespaces

    def parse(self, content: str) -> ParseResult:
        """Parse XML string."""
        errors = []

        try:
            root = ElementTree.fromstring(content)
            data = self._element_to_dict(root)
        except ElementTree.ParseError as e:
            errors.append(ParseError(str(e)))
            data = None

        return ParseResult(data=data, format=ParseFormat.XML, errors=errors)

    def _element_to_dict(self, element) -> Dict[str, Any]:
        """Convert XML element to dictionary."""
        result = {}

        # Handle attributes
        if element.attrib:
            result["@attributes"] = dict(element.attrib)

        # Handle text content
        if element.text and element.text.strip():
            if len(element) == 0:
                return element.text.strip()
            result["#text"] = element.text.strip()

        # Handle children
        for child in element:
            tag = child.tag
            if self.strip_namespaces:
                tag = tag.split('}')[-1] if '}' in tag else tag

            child_data = self._element_to_dict(child)

            if tag in result:
                if not isinstance(result[tag], list):
                    result[tag] = [result[tag]]
                result[tag].append(child_data)
            else:
                result[tag] = child_data

        return result

    def serialize(self, data: Dict, root_tag: str = "root") -> str:
        """Serialize to XML string."""
        root = self._dict_to_element(data, root_tag)
        return ElementTree.tostring(root, encoding="unicode")

    def _dict_to_element(self, data: Any, tag: str) -> ElementTree.Element:
        """Convert dictionary to XML element."""
        element = ElementTree.Element(tag)

        if isinstance(data, dict):
            for key, value in data.items():
                if key == "@attributes":
                    element.attrib.update(value)
                elif key == "#text":
                    element.text = str(value)
                elif isinstance(value, list):
                    for item in value:
                        element.append(self._dict_to_element(item, key))
                else:
                    element.append(self._dict_to_element(value, key))
        else:
            element.text = str(data)

        return element


class INIParser(Parser):
    """INI file parser."""

    def __init__(self, allow_no_value: bool = True):
        self.allow_no_value = allow_no_value

    def parse(self, content: str) -> ParseResult:
        """Parse INI string."""
        errors = []
        data = {}
        current_section = None

        for line_num, line in enumerate(content.split('\n'), start=1):
            line = line.strip()

            # Skip empty lines and comments
            if not line or line.startswith(('#', ';')):
                continue

            # Section header
            if line.startswith('[') and line.endswith(']'):
                current_section = line[1:-1].strip()
                if current_section not in data:
                    data[current_section] = {}
                continue

            # Key-value pair
            if '=' in line:
                key, value = line.split('=', 1)
                key = key.strip()
                value = value.strip()

                # Type conversion
                value = self._convert_value(value)

                if current_section:
                    data[current_section][key] = value
                else:
                    data[key] = value
            elif self.allow_no_value:
                if current_section:
                    data[current_section][line] = None
                else:
                    data[line] = None
            else:
                errors.append(ParseError(f"Invalid line: {line}", line_num))

        return ParseResult(data=data, format=ParseFormat.INI, errors=errors)

    def _convert_value(self, value: str) -> Any:
        """Convert string value to appropriate type."""
        if value.lower() in ('true', 'yes', 'on'):
            return True
        if value.lower() in ('false', 'no', 'off'):
            return False
        try:
            return int(value)
        except ValueError:
            pass
        try:
            return float(value)
        except ValueError:
            pass
        return value

    def serialize(self, data: Dict) -> str:
        """Serialize to INI string."""
        lines = []

        for key, value in data.items():
            if isinstance(value, dict):
                lines.append(f"[{key}]")
                for k, v in value.items():
                    if v is None:
                        lines.append(k)
                    else:
                        lines.append(f"{k} = {v}")
                lines.append("")
            else:
                if value is None:
                    lines.append(key)
                else:
                    lines.append(f"{key} = {value}")

        return "\n".join(lines)


class QueryStringParser(Parser):
    """URL query string parser."""

    def __init__(self, decode: bool = True):
        self.decode = decode

    def parse(self, content: str) -> ParseResult:
        """Parse query string."""
        from urllib.parse import parse_qs, unquote

        # Remove leading ? if present
        if content.startswith('?'):
            content = content[1:]

        data = {}
        for pair in content.split('&'):
            if '=' in pair:
                key, value = pair.split('=', 1)
                if self.decode:
                    key = unquote(key)
                    value = unquote(value)

                if key in data:
                    if isinstance(data[key], list):
                        data[key].append(value)
                    else:
                        data[key] = [data[key], value]
                else:
                    data[key] = value

        return ParseResult(data=data, format=ParseFormat.QUERY_STRING)

    def serialize(self, data: Dict) -> str:
        """Serialize to query string."""
        from urllib.parse import quote

        pairs = []
        for key, value in data.items():
            if isinstance(value, list):
                for v in value:
                    pairs.append(f"{quote(str(key))}={quote(str(v))}")
            else:
                pairs.append(f"{quote(str(key))}={quote(str(value))}")

        return "&".join(pairs)


class SchemaValidator:
    """Validate data against schema."""

    def __init__(self, schema: List[SchemaField]):
        self.schema = {f.name: f for f in schema}

    def validate(self, data: Dict) -> Tuple[bool, List[str]]:
        """Validate data against schema."""
        errors = []

        # Check required fields
        for name, field in self.schema.items():
            if field.required and name not in data:
                errors.append(f"Missing required field: {name}")

        # Validate field types and values
        for key, value in data.items():
            if key in self.schema:
                field = self.schema[key]

                # Type check
                if not self._check_type(value, field.field_type):
                    errors.append(f"Invalid type for {key}: expected {field.field_type}")

                # Custom validators
                for validator in field.validators:
                    if not validator(value):
                        errors.append(f"Validation failed for {key}")

        return len(errors) == 0, errors

    def _check_type(self, value: Any, expected: str) -> bool:
        type_map = {
            "string": str,
            "int": int,
            "float": (int, float),
            "bool": bool,
            "list": list,
            "dict": dict
        }
        expected_type = type_map.get(expected)
        if expected_type:
            return isinstance(value, expected_type)
        return True


class DataTransformer:
    """Transform parsed data."""

    def __init__(self):
        self.transforms: List[Callable[[Any], Any]] = []

    def add_transform(self, transform: Callable[[Any], Any]) -> "DataTransformer":
        """Add a transform function."""
        self.transforms.append(transform)
        return self

    def transform(self, data: Any) -> Any:
        """Apply all transforms."""
        result = data
        for transform in self.transforms:
            result = transform(result)
        return result

    @staticmethod
    def flatten(data: Dict, separator: str = ".") -> Dict:
        """Flatten nested dictionary."""
        result = {}

        def _flatten(obj, prefix=""):
            if isinstance(obj, dict):
                for k, v in obj.items():
                    new_key = f"{prefix}{separator}{k}" if prefix else k
                    _flatten(v, new_key)
            elif isinstance(obj, list):
                for i, v in enumerate(obj):
                    _flatten(v, f"{prefix}[{i}]")
            else:
                result[prefix] = obj

        _flatten(data)
        return result

    @staticmethod
    def unflatten(data: Dict, separator: str = ".") -> Dict:
        """Unflatten dictionary."""
        result = {}

        for key, value in data.items():
            parts = key.split(separator)
            current = result

            for i, part in enumerate(parts[:-1]):
                if part not in current:
                    current[part] = {}
                current = current[part]

            current[parts[-1]] = value

        return result


class ParserManager:
    """Manage multiple parsers."""

    def __init__(self):
        self.parsers: Dict[ParseFormat, Parser] = {
            ParseFormat.JSON: JSONParser(),
            ParseFormat.CSV: CSVParser(),
            ParseFormat.XML: XMLParser(),
            ParseFormat.INI: INIParser(),
            ParseFormat.QUERY_STRING: QueryStringParser()
        }

    def parse(
        self,
        content: str,
        format: ParseFormat = None,
        **kwargs
    ) -> ParseResult:
        """Parse content with auto-detection or specified format."""
        if format is None:
            format = self.detect_format(content)

        parser = self.parsers.get(format)
        if not parser:
            return ParseResult(
                data=None,
                format=format,
                errors=[ParseError(f"Unsupported format: {format}")]
            )

        return parser.parse(content)

    def detect_format(self, content: str) -> ParseFormat:
        """Auto-detect content format."""
        content = content.strip()

        if content.startswith('{') or content.startswith('['):
            return ParseFormat.JSON
        if content.startswith('<?xml') or content.startswith('<'):
            return ParseFormat.XML
        if '[' in content and ']' in content and '=' in content:
            return ParseFormat.INI
        if '&' in content or content.startswith('?'):
            return ParseFormat.QUERY_STRING
        if ',' in content or '\t' in content:
            return ParseFormat.CSV

        return ParseFormat.JSON  # Default

    def serialize(self, data: Any, format: ParseFormat) -> str:
        """Serialize data to specified format."""
        parser = self.parsers.get(format)
        if not parser:
            raise ValueError(f"Unsupported format: {format}")
        return parser.serialize(data)

    def convert(
        self,
        content: str,
        from_format: ParseFormat,
        to_format: ParseFormat
    ) -> str:
        """Convert between formats."""
        result = self.parse(content, from_format)
        if not result.success:
            raise ValueError(f"Parse errors: {result.errors}")
        return self.serialize(result.data, to_format)


# Example usage
def example_usage():
    """Example parser usage."""
    manager = ParserManager()

    # Parse JSON
    json_result = manager.parse('{"name": "Alice", "age": 30}')
    print(f"JSON: {json_result.data}")

    # Parse CSV
    csv_content = "name,age\nAlice,30\nBob,25"
    csv_result = manager.parse(csv_content, ParseFormat.CSV)
    print(f"CSV: {csv_result.data}")

    # Parse XML
    xml_content = "<user><name>Alice</name><age>30</age></user>"
    xml_result = manager.parse(xml_content, ParseFormat.XML)
    print(f"XML: {xml_result.data}")

    # Parse INI
    ini_content = "[database]\nhost = localhost\nport = 5432"
    ini_result = manager.parse(ini_content, ParseFormat.INI)
    print(f"INI: {ini_result.data}")

    # Convert JSON to CSV
    json_data = '[{"name": "Alice", "age": 30}, {"name": "Bob", "age": 25}]'
    csv_output = manager.convert(json_data, ParseFormat.JSON, ParseFormat.CSV)
    print(f"Converted CSV:\n{csv_output}")

    # Transform data
    transformer = DataTransformer()
    nested = {"user": {"name": "Alice", "address": {"city": "NYC"}}}
    flat = DataTransformer.flatten(nested)
    print(f"Flattened: {flat}")

