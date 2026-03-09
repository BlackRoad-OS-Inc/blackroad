"""
RoadINI - INI File Parsing for BlackRoad
Parse and serialize INI configuration files.
"""

from dataclasses import dataclass, field
from typing import Any, Callable, Dict, List, Optional, Union
import re
import logging

logger = logging.getLogger(__name__)


class INIError(Exception):
    pass


@dataclass
class Section:
    name: str
    items: Dict[str, str] = field(default_factory=dict)
    comments: Dict[str, str] = field(default_factory=dict)

    def get(self, key: str, default: str = None) -> Optional[str]:
        return self.items.get(key, default)

    def get_int(self, key: str, default: int = 0) -> int:
        value = self.items.get(key)
        if value is None:
            return default
        try:
            return int(value)
        except ValueError:
            return default

    def get_float(self, key: str, default: float = 0.0) -> float:
        value = self.items.get(key)
        if value is None:
            return default
        try:
            return float(value)
        except ValueError:
            return default

    def get_bool(self, key: str, default: bool = False) -> bool:
        value = self.items.get(key)
        if value is None:
            return default
        return value.lower() in ("true", "yes", "on", "1")

    def get_list(self, key: str, separator: str = ",") -> List[str]:
        value = self.items.get(key, "")
        if not value:
            return []
        return [item.strip() for item in value.split(separator)]

    def set(self, key: str, value: Any, comment: str = None) -> None:
        self.items[key] = str(value)
        if comment:
            self.comments[key] = comment

    def __getitem__(self, key: str) -> str:
        return self.items[key]

    def __setitem__(self, key: str, value: Any) -> None:
        self.items[key] = str(value)

    def __contains__(self, key: str) -> bool:
        return key in self.items


class INIFile:
    def __init__(self, allow_no_value: bool = False, interpolation: bool = True):
        self.sections: Dict[str, Section] = {}
        self.global_section = Section("")
        self.allow_no_value = allow_no_value
        self.interpolation = interpolation
        self._comments: List[str] = []

    def read(self, text: str) -> "INIFile":
        current_section = self.global_section
        pending_comment = None
        
        for line_num, line in enumerate(text.split("\n"), 1):
            line = line.strip()
            
            if not line:
                continue
            
            if line.startswith(";") or line.startswith("#"):
                pending_comment = line[1:].strip()
                continue
            
            if line.startswith("[") and line.endswith("]"):
                section_name = line[1:-1].strip()
                if section_name not in self.sections:
                    self.sections[section_name] = Section(section_name)
                current_section = self.sections[section_name]
                pending_comment = None
                continue
            
            if "=" in line:
                key, value = line.split("=", 1)
                key = key.strip()
                value = value.strip()
                
                if value.startswith('"') and value.endswith('"'):
                    value = value[1:-1]
                elif value.startswith("'") and value.endswith("'"):
                    value = value[1:-1]
                
                inline_comment = None
                if ";" in value or "#" in value:
                    for sep in [" ;", " #", ";", "#"]:
                        if sep in value:
                            value, inline_comment = value.split(sep, 1)
                            value = value.strip()
                            break
                
                current_section.items[key] = value
                if pending_comment:
                    current_section.comments[key] = pending_comment
                    pending_comment = None
            elif self.allow_no_value:
                current_section.items[line] = ""
        
        return self

    def read_file(self, path: str) -> "INIFile":
        with open(path, "r") as f:
            return self.read(f.read())

    def write(self) -> str:
        lines = []
        
        if self.global_section.items:
            for key, value in self.global_section.items.items():
                if key in self.global_section.comments:
                    lines.append(f"; {self.global_section.comments[key]}")
                lines.append(f"{key} = {value}")
            lines.append("")
        
        for name, section in self.sections.items():
            lines.append(f"[{name}]")
            for key, value in section.items.items():
                if key in section.comments:
                    lines.append(f"; {section.comments[key]}")
                lines.append(f"{key} = {value}")
            lines.append("")
        
        return "\n".join(lines).rstrip() + "\n"

    def write_file(self, path: str) -> None:
        with open(path, "w") as f:
            f.write(self.write())

    def get(self, section: str, key: str, default: str = None) -> Optional[str]:
        if section not in self.sections:
            return default
        value = self.sections[section].get(key, default)
        if self.interpolation and value:
            return self._interpolate(value)
        return value

    def _interpolate(self, value: str) -> str:
        pattern = r"\$\{([^}]+)\}"
        
        def replace(match):
            ref = match.group(1)
            if ":" in ref:
                section, key = ref.split(":", 1)
                return self.sections.get(section, Section("")).get(key, match.group(0))
            return self.global_section.get(ref, match.group(0))
        
        return re.sub(pattern, replace, value)

    def set(self, section: str, key: str, value: Any) -> None:
        if section not in self.sections:
            self.sections[section] = Section(section)
        self.sections[section][key] = value

    def has_section(self, section: str) -> bool:
        return section in self.sections

    def has_option(self, section: str, key: str) -> bool:
        return section in self.sections and key in self.sections[section]

    def add_section(self, section: str) -> Section:
        if section not in self.sections:
            self.sections[section] = Section(section)
        return self.sections[section]

    def remove_section(self, section: str) -> bool:
        if section in self.sections:
            del self.sections[section]
            return True
        return False

    def remove_option(self, section: str, key: str) -> bool:
        if section in self.sections and key in self.sections[section].items:
            del self.sections[section].items[key]
            return True
        return False

    def items(self, section: str) -> List[tuple]:
        if section not in self.sections:
            return []
        return list(self.sections[section].items.items())

    def to_dict(self) -> Dict[str, Dict[str, str]]:
        result = {}
        if self.global_section.items:
            result[""] = dict(self.global_section.items)
        for name, section in self.sections.items():
            result[name] = dict(section.items)
        return result

    def __getitem__(self, section: str) -> Section:
        return self.sections[section]

    def __contains__(self, section: str) -> bool:
        return section in self.sections


def load(text: str) -> INIFile:
    return INIFile().read(text)


def load_file(path: str) -> INIFile:
    return INIFile().read_file(path)


def dump(ini: INIFile) -> str:
    return ini.write()


def dump_file(ini: INIFile, path: str) -> None:
    ini.write_file(path)


def example_usage():
    ini_text = """
; Database configuration
[database]
host = localhost
port = 5432
name = myapp
user = admin

[server]
; Web server settings
host = 0.0.0.0
port = 8080
debug = true
workers = 4

[logging]
level = INFO
file = /var/log/app.log
"""
    
    ini = load(ini_text)
    print(f"Sections: {list(ini.sections.keys())}")
    print(f"DB Host: {ini.get('database', 'host')}")
    print(f"Server Port: {ini['server'].get_int('port')}")
    print(f"Debug: {ini['server'].get_bool('debug')}")
    
    ini.set("cache", "enabled", "true")
    ini.set("cache", "ttl", "3600")
    
    print(f"\nOutput:\n{ini.write()}")

