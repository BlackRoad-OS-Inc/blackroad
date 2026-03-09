"""
RoadExport - Data Export for BlackRoad
Export data to CSV, JSON, Excel-like formats with streaming.
"""

from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum
from typing import Any, Callable, Dict, Generator, List, Optional, IO
import csv
import io
import json
import logging

logger = logging.getLogger(__name__)


class ExportFormat(str, Enum):
    CSV = "csv"
    JSON = "json"
    JSONL = "jsonl"
    TSV = "tsv"
    XML = "xml"


@dataclass
class ExportConfig:
    format: ExportFormat = ExportFormat.CSV
    columns: Optional[List[str]] = None
    column_labels: Optional[Dict[str, str]] = None
    delimiter: str = ","
    include_header: bool = True
    date_format: str = "%Y-%m-%d %H:%M:%S"
    null_value: str = ""
    encoding: str = "utf-8"
    batch_size: int = 1000


@dataclass
class ExportResult:
    success: bool
    row_count: int = 0
    byte_count: int = 0
    duration_ms: float = 0
    error: Optional[str] = None


class DataFormatter:
    def __init__(self, config: ExportConfig):
        self.config = config

    def format_value(self, value: Any) -> str:
        if value is None:
            return self.config.null_value
        if isinstance(value, datetime):
            return value.strftime(self.config.date_format)
        if isinstance(value, bool):
            return "true" if value else "false"
        if isinstance(value, (list, dict)):
            return json.dumps(value)
        return str(value)

    def format_row(self, row: Dict[str, Any], columns: List[str]) -> List[str]:
        return [self.format_value(row.get(col)) for col in columns]


class CSVExporter:
    def __init__(self, config: ExportConfig):
        self.config = config
        self.formatter = DataFormatter(config)

    def export(self, data: List[Dict], output: IO) -> ExportResult:
        if not data:
            return ExportResult(success=True, row_count=0)
        
        columns = self.config.columns or list(data[0].keys())
        labels = [self.config.column_labels.get(c, c) if self.config.column_labels else c for c in columns]
        
        writer = csv.writer(output, delimiter=self.config.delimiter)
        
        if self.config.include_header:
            writer.writerow(labels)
        
        row_count = 0
        for row in data:
            formatted = self.formatter.format_row(row, columns)
            writer.writerow(formatted)
            row_count += 1
        
        return ExportResult(success=True, row_count=row_count)

    def export_stream(self, data_generator: Generator, output: IO, columns: List[str]) -> ExportResult:
        writer = csv.writer(output, delimiter=self.config.delimiter)
        labels = [self.config.column_labels.get(c, c) if self.config.column_labels else c for c in columns]
        
        if self.config.include_header:
            writer.writerow(labels)
        
        row_count = 0
        for row in data_generator:
            formatted = self.formatter.format_row(row, columns)
            writer.writerow(formatted)
            row_count += 1
        
        return ExportResult(success=True, row_count=row_count)


class JSONExporter:
    def __init__(self, config: ExportConfig):
        self.config = config

    def export(self, data: List[Dict], output: IO, pretty: bool = False) -> ExportResult:
        indent = 2 if pretty else None
        
        if self.config.columns:
            filtered = [{k: v for k, v in row.items() if k in self.config.columns} for row in data]
        else:
            filtered = data
        
        output.write(json.dumps(filtered, indent=indent, default=str))
        return ExportResult(success=True, row_count=len(data))

    def export_jsonl(self, data: List[Dict], output: IO) -> ExportResult:
        row_count = 0
        for row in data:
            if self.config.columns:
                row = {k: v for k, v in row.items() if k in self.config.columns}
            output.write(json.dumps(row, default=str) + "\n")
            row_count += 1
        return ExportResult(success=True, row_count=row_count)


class XMLExporter:
    def __init__(self, config: ExportConfig, root_element: str = "data", row_element: str = "row"):
        self.config = config
        self.root_element = root_element
        self.row_element = row_element
        self.formatter = DataFormatter(config)

    def export(self, data: List[Dict], output: IO) -> ExportResult:
        output.write(f'<?xml version="1.0" encoding="{self.config.encoding}"?>\n')
        output.write(f"<{self.root_element}>\n")
        
        columns = self.config.columns or (list(data[0].keys()) if data else [])
        row_count = 0
        
        for row in data:
            output.write(f"  <{self.row_element}>\n")
            for col in columns:
                value = self.formatter.format_value(row.get(col))
                escaped = value.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
                output.write(f"    <{col}>{escaped}</{col}>\n")
            output.write(f"  </{self.row_element}>\n")
            row_count += 1
        
        output.write(f"</{self.root_element}>")
        return ExportResult(success=True, row_count=row_count)


class ExportManager:
    def __init__(self):
        self.transformers: List[Callable[[Dict], Dict]] = []

    def add_transformer(self, fn: Callable[[Dict], Dict]) -> None:
        self.transformers.append(fn)

    def _transform(self, data: List[Dict]) -> List[Dict]:
        if not self.transformers:
            return data
        result = []
        for row in data:
            for transformer in self.transformers:
                row = transformer(row)
            result.append(row)
        return result

    def export_csv(self, data: List[Dict], config: ExportConfig = None) -> str:
        config = config or ExportConfig()
        output = io.StringIO()
        exporter = CSVExporter(config)
        exporter.export(self._transform(data), output)
        return output.getvalue()

    def export_json(self, data: List[Dict], config: ExportConfig = None, pretty: bool = False) -> str:
        config = config or ExportConfig(format=ExportFormat.JSON)
        output = io.StringIO()
        exporter = JSONExporter(config)
        exporter.export(self._transform(data), output, pretty)
        return output.getvalue()

    def export_jsonl(self, data: List[Dict], config: ExportConfig = None) -> str:
        config = config or ExportConfig(format=ExportFormat.JSONL)
        output = io.StringIO()
        exporter = JSONExporter(config)
        exporter.export_jsonl(self._transform(data), output)
        return output.getvalue()

    def export_xml(self, data: List[Dict], config: ExportConfig = None) -> str:
        config = config or ExportConfig(format=ExportFormat.XML)
        output = io.StringIO()
        exporter = XMLExporter(config)
        exporter.export(self._transform(data), output)
        return output.getvalue()

    def export_to_file(self, data: List[Dict], filepath: str, config: ExportConfig = None) -> ExportResult:
        config = config or ExportConfig()
        with open(filepath, "w", encoding=config.encoding) as f:
            if config.format == ExportFormat.CSV:
                return CSVExporter(config).export(self._transform(data), f)
            elif config.format == ExportFormat.JSON:
                return JSONExporter(config).export(self._transform(data), f, pretty=True)
            elif config.format == ExportFormat.JSONL:
                return JSONExporter(config).export_jsonl(self._transform(data), f)
            elif config.format == ExportFormat.XML:
                return XMLExporter(config).export(self._transform(data), f)
        return ExportResult(success=False, error="Unknown format")


def example_usage():
    manager = ExportManager()
    data = [
        {"id": 1, "name": "Alice", "age": 30, "created": datetime.now()},
        {"id": 2, "name": "Bob", "age": 25, "created": datetime.now()},
        {"id": 3, "name": "Charlie", "age": 35, "created": datetime.now()},
    ]
    
    # CSV export
    csv_output = manager.export_csv(data)
    print("CSV Output:")
    print(csv_output)
    
    # JSON export
    json_output = manager.export_json(data, pretty=True)
    print("\nJSON Output:")
    print(json_output)
    
    # JSONL export
    jsonl_output = manager.export_jsonl(data)
    print("\nJSONL Output:")
    print(jsonl_output)
    
    # With config
    config = ExportConfig(columns=["id", "name"], column_labels={"id": "ID", "name": "Name"})
    filtered_csv = manager.export_csv(data, config)
    print("\nFiltered CSV:")
    print(filtered_csv)
