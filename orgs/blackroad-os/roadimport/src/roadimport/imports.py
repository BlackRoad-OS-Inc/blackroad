"""
RoadImport - Data Import for BlackRoad
Import and validate data from various formats.
"""

from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum
from typing import Any, Callable, Dict, Generator, List, Optional, Type, Union
import csv
import io
import json
import logging
import re

logger = logging.getLogger(__name__)


class ImportFormat(str, Enum):
    CSV = "csv"
    JSON = "json"
    JSONL = "jsonl"


class ValidationLevel(str, Enum):
    STRICT = "strict"
    LENIENT = "lenient"
    SKIP_ERRORS = "skip_errors"


@dataclass
class FieldSpec:
    name: str
    type: Type = str
    required: bool = False
    default: Any = None
    validator: Optional[Callable[[Any], bool]] = None
    transformer: Optional[Callable[[Any], Any]] = None
    alias: Optional[str] = None


@dataclass
class ImportError:
    row: int
    field: str
    value: Any
    error: str


@dataclass
class ImportResult:
    success: bool
    rows_imported: int = 0
    rows_skipped: int = 0
    errors: List[ImportError] = field(default_factory=list)
    data: List[Dict] = field(default_factory=list)
    duration_ms: float = 0


class FieldValidator:
    @staticmethod
    def email(value: str) -> bool:
        pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
        return bool(re.match(pattern, str(value)))

    @staticmethod
    def url(value: str) -> bool:
        pattern = r'^https?://[^\s/$.?#].[^\s]*$'
        return bool(re.match(pattern, str(value)))

    @staticmethod
    def phone(value: str) -> bool:
        cleaned = re.sub(r'[\s\-\(\)]', '', str(value))
        return bool(re.match(r'^\+?\d{10,15}$', cleaned))

    @staticmethod
    def in_range(min_val: float, max_val: float) -> Callable:
        def validator(value: float) -> bool:
            return min_val <= float(value) <= max_val
        return validator

    @staticmethod
    def one_of(options: List[Any]) -> Callable:
        def validator(value: Any) -> bool:
            return value in options
        return validator

    @staticmethod
    def min_length(length: int) -> Callable:
        def validator(value: str) -> bool:
            return len(str(value)) >= length
        return validator


class TypeConverter:
    @staticmethod
    def to_int(value: Any) -> int:
        if value is None or value == "":
            return 0
        return int(float(str(value)))

    @staticmethod
    def to_float(value: Any) -> float:
        if value is None or value == "":
            return 0.0
        return float(str(value))

    @staticmethod
    def to_bool(value: Any) -> bool:
        if isinstance(value, bool):
            return value
        if isinstance(value, str):
            return value.lower() in ("true", "1", "yes", "y")
        return bool(value)

    @staticmethod
    def to_datetime(value: Any, format: str = "%Y-%m-%d") -> Optional[datetime]:
        if value is None or value == "":
            return None
        if isinstance(value, datetime):
            return value
        return datetime.strptime(str(value), format)

    @staticmethod
    def to_list(value: Any, separator: str = ",") -> List[str]:
        if isinstance(value, list):
            return value
        if value is None or value == "":
            return []
        return [item.strip() for item in str(value).split(separator)]


class CSVImporter:
    def __init__(self, fields: List[FieldSpec] = None, delimiter: str = ","):
        self.fields = fields or []
        self.delimiter = delimiter
        self.field_map = {f.name: f for f in self.fields}
        self.alias_map = {f.alias: f for f in self.fields if f.alias}

    def import_data(self, content: str, validation: ValidationLevel = ValidationLevel.STRICT) -> ImportResult:
        reader = csv.DictReader(io.StringIO(content), delimiter=self.delimiter)
        rows = []
        errors = []
        skipped = 0

        for row_num, row in enumerate(reader, 1):
            processed, row_errors = self._process_row(row, row_num)
            
            if row_errors:
                if validation == ValidationLevel.STRICT:
                    errors.extend(row_errors)
                    return ImportResult(success=False, rows_imported=0, errors=errors)
                elif validation == ValidationLevel.LENIENT:
                    errors.extend(row_errors)
                    rows.append(processed)
                else:  # SKIP_ERRORS
                    errors.extend(row_errors)
                    skipped += 1
                    continue
            else:
                rows.append(processed)

        return ImportResult(success=True, rows_imported=len(rows), rows_skipped=skipped, errors=errors, data=rows)

    def _process_row(self, row: Dict, row_num: int) -> tuple:
        processed = {}
        errors = []

        for field in self.fields:
            raw_value = row.get(field.name) or row.get(field.alias) if field.alias else row.get(field.name)
            
            if raw_value is None or raw_value == "":
                if field.required:
                    errors.append(ImportError(row_num, field.name, raw_value, "Required field missing"))
                    continue
                processed[field.name] = field.default
                continue

            try:
                value = raw_value
                if field.type == int:
                    value = TypeConverter.to_int(raw_value)
                elif field.type == float:
                    value = TypeConverter.to_float(raw_value)
                elif field.type == bool:
                    value = TypeConverter.to_bool(raw_value)
                elif field.type == datetime:
                    value = TypeConverter.to_datetime(raw_value)
                elif field.type == list:
                    value = TypeConverter.to_list(raw_value)
                
                if field.transformer:
                    value = field.transformer(value)
                
                if field.validator and not field.validator(value):
                    errors.append(ImportError(row_num, field.name, raw_value, "Validation failed"))
                    continue
                
                processed[field.name] = value
            except Exception as e:
                errors.append(ImportError(row_num, field.name, raw_value, str(e)))

        # Include unmapped fields
        for key, value in row.items():
            if key not in self.field_map and key not in processed:
                processed[key] = value

        return processed, errors


class JSONImporter:
    def __init__(self, fields: List[FieldSpec] = None):
        self.fields = fields or []
        self.field_map = {f.name: f for f in self.fields}

    def import_data(self, content: str, validation: ValidationLevel = ValidationLevel.STRICT) -> ImportResult:
        try:
            data = json.loads(content)
        except json.JSONDecodeError as e:
            return ImportResult(success=False, errors=[ImportError(0, "", content, f"JSON parse error: {e}")])

        if not isinstance(data, list):
            data = [data]

        rows = []
        errors = []
        skipped = 0

        for row_num, row in enumerate(data, 1):
            if not isinstance(row, dict):
                errors.append(ImportError(row_num, "", row, "Expected object"))
                continue
            
            processed = self._process_row(row)
            rows.append(processed)

        return ImportResult(success=True, rows_imported=len(rows), rows_skipped=skipped, errors=errors, data=rows)

    def _process_row(self, row: Dict) -> Dict:
        processed = dict(row)
        for field in self.fields:
            if field.name in processed and field.transformer:
                processed[field.name] = field.transformer(processed[field.name])
        return processed


class ImportManager:
    def __init__(self):
        self.pre_processors: List[Callable[[str], str]] = []
        self.post_processors: List[Callable[[List[Dict]], List[Dict]]] = []

    def add_pre_processor(self, fn: Callable[[str], str]) -> None:
        self.pre_processors.append(fn)

    def add_post_processor(self, fn: Callable[[List[Dict]], List[Dict]]) -> None:
        self.post_processors.append(fn)

    def import_csv(self, content: str, fields: List[FieldSpec] = None, validation: ValidationLevel = ValidationLevel.STRICT, **kwargs) -> ImportResult:
        for processor in self.pre_processors:
            content = processor(content)
        importer = CSVImporter(fields, **kwargs)
        result = importer.import_data(content, validation)
        if result.success:
            for processor in self.post_processors:
                result.data = processor(result.data)
        return result

    def import_json(self, content: str, fields: List[FieldSpec] = None, validation: ValidationLevel = ValidationLevel.STRICT) -> ImportResult:
        for processor in self.pre_processors:
            content = processor(content)
        importer = JSONImporter(fields)
        result = importer.import_data(content, validation)
        if result.success:
            for processor in self.post_processors:
                result.data = processor(result.data)
        return result

    def import_file(self, filepath: str, format: ImportFormat = None, **kwargs) -> ImportResult:
        if format is None:
            if filepath.endswith(".csv"):
                format = ImportFormat.CSV
            elif filepath.endswith(".json"):
                format = ImportFormat.JSON
            else:
                return ImportResult(success=False, errors=[ImportError(0, "", filepath, "Unknown format")])
        
        with open(filepath, "r") as f:
            content = f.read()
        
        if format == ImportFormat.CSV:
            return self.import_csv(content, **kwargs)
        elif format == ImportFormat.JSON:
            return self.import_json(content, **kwargs)
        return ImportResult(success=False, errors=[ImportError(0, "", filepath, "Unsupported format")])


def example_usage():
    manager = ImportManager()
    
    fields = [
        FieldSpec("id", type=int, required=True),
        FieldSpec("name", required=True, validator=FieldValidator.min_length(2)),
        FieldSpec("email", required=True, validator=FieldValidator.email),
        FieldSpec("age", type=int, default=0),
        FieldSpec("active", type=bool, default=True),
    ]
    
    csv_content = """id,name,email,age,active
1,Alice,alice@example.com,30,true
2,Bob,bob@example.com,25,false
3,Charlie,charlie@example.com,35,true"""
    
    result = manager.import_csv(csv_content, fields, ValidationLevel.LENIENT)
    print(f"Imported {result.rows_imported} rows")
    print(f"Errors: {len(result.errors)}")
    for row in result.data:
        print(f"  {row}")
    
    json_content = '[{"id": 1, "name": "Alice"}, {"id": 2, "name": "Bob"}]'
    json_result = manager.import_json(json_content)
    print(f"\nJSON imported {json_result.rows_imported} rows")
