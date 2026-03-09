"""
RoadReport - Report Generation for BlackRoad
Generate reports with sections, charts, and multiple formats.
"""

from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum
from typing import Any, Callable, Dict, List, Optional, Union
import json
import logging

logger = logging.getLogger(__name__)


class ReportFormat(str, Enum):
    HTML = "html"
    JSON = "json"
    TEXT = "text"
    MARKDOWN = "markdown"


class ChartType(str, Enum):
    BAR = "bar"
    LINE = "line"
    PIE = "pie"
    TABLE = "table"


@dataclass
class ChartData:
    type: ChartType
    title: str
    labels: List[str]
    datasets: List[Dict[str, Any]]
    options: Dict[str, Any] = field(default_factory=dict)


@dataclass
class ReportSection:
    title: str
    content: str = ""
    data: Optional[Any] = None
    chart: Optional[ChartData] = None
    subsections: List["ReportSection"] = field(default_factory=list)
    metadata: Dict[str, Any] = field(default_factory=dict)


@dataclass
class ReportConfig:
    title: str
    subtitle: str = ""
    author: str = ""
    date: datetime = field(default_factory=datetime.now)
    format: ReportFormat = ReportFormat.HTML
    header: str = ""
    footer: str = ""
    styles: Dict[str, str] = field(default_factory=dict)


class HTMLRenderer:
    def __init__(self, config: ReportConfig):
        self.config = config

    def render(self, sections: List[ReportSection]) -> str:
        parts = [
            "<!DOCTYPE html>",
            "<html>",
            "<head>",
            f"<title>{self.config.title}</title>",
            "<style>",
            "body { font-family: Arial, sans-serif; margin: 40px; }",
            "h1 { color: #333; }",
            "h2 { color: #666; border-bottom: 1px solid #eee; }",
            "table { border-collapse: collapse; width: 100%; }",
            "th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }",
            "th { background-color: #f4f4f4; }",
            "</style>",
            "</head>",
            "<body>",
            f"<h1>{self.config.title}</h1>",
        ]
        
        if self.config.subtitle:
            parts.append(f"<p><em>{self.config.subtitle}</em></p>")
        
        if self.config.author:
            parts.append(f"<p>Author: {self.config.author} | Date: {self.config.date.strftime('%Y-%m-%d')}</p>")
        
        for section in sections:
            parts.append(self._render_section(section, level=2))
        
        if self.config.footer:
            parts.append(f"<footer>{self.config.footer}</footer>")
        
        parts.extend(["</body>", "</html>"])
        return "\n".join(parts)

    def _render_section(self, section: ReportSection, level: int) -> str:
        parts = [f"<h{level}>{section.title}</h{level}>"]
        
        if section.content:
            parts.append(f"<p>{section.content}</p>")
        
        if section.data:
            parts.append(self._render_data(section.data))
        
        if section.chart:
            parts.append(self._render_chart(section.chart))
        
        for subsection in section.subsections:
            parts.append(self._render_section(subsection, level + 1))
        
        return "\n".join(parts)

    def _render_data(self, data: Any) -> str:
        if isinstance(data, list) and data and isinstance(data[0], dict):
            return self._render_table(data)
        return f"<pre>{json.dumps(data, indent=2, default=str)}</pre>"

    def _render_table(self, data: List[Dict]) -> str:
        if not data:
            return ""
        headers = list(data[0].keys())
        parts = ["<table>", "<thead><tr>"]
        for header in headers:
            parts.append(f"<th>{header}</th>")
        parts.append("</tr></thead><tbody>")
        for row in data:
            parts.append("<tr>")
            for header in headers:
                parts.append(f"<td>{row.get(header, '')}</td>")
            parts.append("</tr>")
        parts.append("</tbody></table>")
        return "\n".join(parts)

    def _render_chart(self, chart: ChartData) -> str:
        if chart.type == ChartType.TABLE:
            return self._render_table(chart.datasets[0].get("data", []))
        return f"<div class='chart'><strong>{chart.title}</strong><pre>{json.dumps(chart.datasets, indent=2)}</pre></div>"


class MarkdownRenderer:
    def __init__(self, config: ReportConfig):
        self.config = config

    def render(self, sections: List[ReportSection]) -> str:
        parts = [f"# {self.config.title}", ""]
        
        if self.config.subtitle:
            parts.append(f"*{self.config.subtitle}*\n")
        
        if self.config.author:
            parts.append(f"**Author:** {self.config.author} | **Date:** {self.config.date.strftime('%Y-%m-%d')}\n")
        
        for section in sections:
            parts.append(self._render_section(section, level=2))
        
        return "\n".join(parts)

    def _render_section(self, section: ReportSection, level: int) -> str:
        parts = [f"{'#' * level} {section.title}", ""]
        
        if section.content:
            parts.append(section.content + "\n")
        
        if section.data:
            parts.append(self._render_data(section.data))
        
        for subsection in section.subsections:
            parts.append(self._render_section(subsection, level + 1))
        
        return "\n".join(parts)

    def _render_data(self, data: Any) -> str:
        if isinstance(data, list) and data and isinstance(data[0], dict):
            return self._render_table(data)
        return f"```json\n{json.dumps(data, indent=2, default=str)}\n```\n"

    def _render_table(self, data: List[Dict]) -> str:
        if not data:
            return ""
        headers = list(data[0].keys())
        parts = ["| " + " | ".join(headers) + " |"]
        parts.append("| " + " | ".join(["---"] * len(headers)) + " |")
        for row in data:
            values = [str(row.get(h, "")) for h in headers]
            parts.append("| " + " | ".join(values) + " |")
        return "\n".join(parts) + "\n"


class ReportBuilder:
    def __init__(self, config: ReportConfig = None):
        self.config = config or ReportConfig(title="Report")
        self.sections: List[ReportSection] = []
        self._current_section: Optional[ReportSection] = None

    def title(self, title: str) -> "ReportBuilder":
        self.config.title = title
        return self

    def subtitle(self, subtitle: str) -> "ReportBuilder":
        self.config.subtitle = subtitle
        return self

    def author(self, author: str) -> "ReportBuilder":
        self.config.author = author
        return self

    def section(self, title: str, content: str = "") -> "ReportBuilder":
        section = ReportSection(title=title, content=content)
        self.sections.append(section)
        self._current_section = section
        return self

    def subsection(self, title: str, content: str = "") -> "ReportBuilder":
        if self._current_section:
            subsection = ReportSection(title=title, content=content)
            self._current_section.subsections.append(subsection)
        return self

    def data(self, data: Any) -> "ReportBuilder":
        if self._current_section:
            self._current_section.data = data
        return self

    def table(self, data: List[Dict]) -> "ReportBuilder":
        return self.data(data)

    def chart(self, chart_type: ChartType, title: str, labels: List[str], values: List[float]) -> "ReportBuilder":
        if self._current_section:
            self._current_section.chart = ChartData(
                type=chart_type,
                title=title,
                labels=labels,
                datasets=[{"data": values}]
            )
        return self

    def build(self) -> "Report":
        return Report(self.config, self.sections)


class Report:
    def __init__(self, config: ReportConfig, sections: List[ReportSection]):
        self.config = config
        self.sections = sections

    def render(self, format: ReportFormat = None) -> str:
        format = format or self.config.format
        
        if format == ReportFormat.HTML:
            return HTMLRenderer(self.config).render(self.sections)
        elif format == ReportFormat.MARKDOWN:
            return MarkdownRenderer(self.config).render(self.sections)
        elif format == ReportFormat.JSON:
            return json.dumps({
                "config": {"title": self.config.title, "subtitle": self.config.subtitle},
                "sections": [self._section_to_dict(s) for s in self.sections]
            }, indent=2, default=str)
        else:
            return self._render_text()

    def _section_to_dict(self, section: ReportSection) -> Dict:
        return {
            "title": section.title,
            "content": section.content,
            "data": section.data,
            "subsections": [self._section_to_dict(s) for s in section.subsections]
        }

    def _render_text(self) -> str:
        parts = [self.config.title, "=" * len(self.config.title), ""]
        for section in self.sections:
            parts.append(section.title)
            parts.append("-" * len(section.title))
            if section.content:
                parts.append(section.content)
            parts.append("")
        return "\n".join(parts)

    def save(self, filepath: str, format: ReportFormat = None) -> None:
        content = self.render(format)
        with open(filepath, "w") as f:
            f.write(content)


class ReportManager:
    def __init__(self):
        self.templates: Dict[str, ReportConfig] = {}

    def register_template(self, name: str, config: ReportConfig) -> None:
        self.templates[name] = config

    def create(self, title: str = "Report", template: str = None) -> ReportBuilder:
        if template and template in self.templates:
            config = self.templates[template]
            config.title = title
            return ReportBuilder(config)
        return ReportBuilder(ReportConfig(title=title))


def example_usage():
    manager = ReportManager()
    
    report = (
        manager.create("Monthly Sales Report")
        .subtitle("January 2024")
        .author("Analytics Team")
        .section("Executive Summary", "This report summarizes sales performance for January 2024.")
        .section("Sales by Region")
        .table([
            {"Region": "North", "Sales": 150000, "Growth": "12%"},
            {"Region": "South", "Sales": 120000, "Growth": "8%"},
            {"Region": "East", "Sales": 180000, "Growth": "15%"},
            {"Region": "West", "Sales": 90000, "Growth": "5%"},
        ])
        .section("Trends")
        .chart(ChartType.BAR, "Sales by Quarter", ["Q1", "Q2", "Q3", "Q4"], [100, 150, 130, 180])
        .section("Recommendations", "Based on the data, we recommend focusing on the West region.")
        .build()
    )
    
    print("HTML Report:")
    print(report.render(ReportFormat.HTML)[:500])
    print("\n\nMarkdown Report:")
    print(report.render(ReportFormat.MARKDOWN))
