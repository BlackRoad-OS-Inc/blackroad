"""
RoadEnv - Environment Variable Management for BlackRoad
Load, validate, and manage environment variables.
"""

from dataclasses import dataclass, field
from typing import Any, Callable, Dict, List, Optional, Type, Union
import os
import re
import logging

logger = logging.getLogger(__name__)


class EnvError(Exception):
    pass


class EnvValidationError(EnvError):
    def __init__(self, var: str, message: str):
        self.var = var
        super().__init__(f"Invalid {var}: {message}")


@dataclass
class EnvVar:
    name: str
    type: Type = str
    default: Any = None
    required: bool = False
    description: str = ""
    choices: List[Any] = field(default_factory=list)
    validator: Callable = None
    prefix: str = ""

    @property
    def full_name(self) -> str:
        if self.prefix:
            return f"{self.prefix}_{self.name}"
        return self.name


class EnvParser:
    def __init__(self):
        self.vars: Dict[str, EnvVar] = {}
        self.values: Dict[str, Any] = {}
        self.prefix = ""

    def add(self, name: str, type: Type = str, default: Any = None, required: bool = False,
            description: str = "", choices: List[Any] = None, validator: Callable = None) -> "EnvParser":
        var = EnvVar(
            name=name,
            type=type,
            default=default,
            required=required,
            description=description,
            choices=choices or [],
            validator=validator,
            prefix=self.prefix
        )
        self.vars[var.full_name] = var
        return self

    def set_prefix(self, prefix: str) -> "EnvParser":
        self.prefix = prefix.upper()
        return self

    def parse(self, env: Dict[str, str] = None) -> Dict[str, Any]:
        env = env or os.environ
        result = {}
        errors = []

        for full_name, var in self.vars.items():
            raw_value = env.get(full_name)

            if raw_value is None:
                if var.required:
                    errors.append(f"{full_name} is required")
                    continue
                result[var.name] = var.default
                continue

            try:
                value = self._convert(raw_value, var.type)
                
                if var.choices and value not in var.choices:
                    errors.append(f"{full_name} must be one of {var.choices}")
                    continue
                
                if var.validator and not var.validator(value):
                    errors.append(f"{full_name} failed validation")
                    continue
                
                result[var.name] = value
            except ValueError as e:
                errors.append(f"{full_name}: {e}")

        if errors:
            raise EnvValidationError("ENV", "; ".join(errors))

        self.values = result
        return result

    def _convert(self, value: str, typ: Type) -> Any:
        if typ == bool:
            return value.lower() in ("true", "1", "yes", "on")
        if typ == list:
            return [v.strip() for v in value.split(",")]
        if typ == dict:
            result = {}
            for pair in value.split(","):
                if "=" in pair:
                    k, v = pair.split("=", 1)
                    result[k.strip()] = v.strip()
            return result
        return typ(value)

    def get(self, name: str, default: Any = None) -> Any:
        return self.values.get(name, default)

    def __getattr__(self, name: str) -> Any:
        if name in ("vars", "values", "prefix"):
            return super().__getattribute__(name)
        return self.values.get(name)


class DotEnv:
    def __init__(self, path: str = ".env"):
        self.path = path
        self.vars: Dict[str, str] = {}

    def load(self, override: bool = False) -> Dict[str, str]:
        if not os.path.exists(self.path):
            return {}

        with open(self.path, "r") as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith("#"):
                    continue
                
                if "=" not in line:
                    continue
                
                key, value = line.split("=", 1)
                key = key.strip()
                value = value.strip()

                if value.startswith('"') and value.endswith('"'):
                    value = value[1:-1]
                elif value.startswith("'") and value.endswith("'"):
                    value = value[1:-1]

                value = self._interpolate(value)

                self.vars[key] = value
                if override or key not in os.environ:
                    os.environ[key] = value

        return self.vars

    def _interpolate(self, value: str) -> str:
        def replace(match):
            var_name = match.group(1) or match.group(2)
            return os.environ.get(var_name, self.vars.get(var_name, ""))
        
        pattern = r"\$\{([^}]+)\}|\$([A-Za-z_][A-Za-z0-9_]*)"
        return re.sub(pattern, replace, value)

    def get(self, key: str, default: str = None) -> Optional[str]:
        return self.vars.get(key, os.environ.get(key, default))

    def set(self, key: str, value: str) -> None:
        self.vars[key] = value
        os.environ[key] = value

    def save(self) -> None:
        lines = []
        for key, value in self.vars.items():
            if " " in value or "=" in value:
                lines.append(f'{key}="{value}"')
            else:
                lines.append(f"{key}={value}")
        
        with open(self.path, "w") as f:
            f.write("\n".join(lines) + "\n")


class EnvManager:
    def __init__(self):
        self.dotenv = DotEnv()
        self.parser = EnvParser()

    def load_dotenv(self, path: str = ".env", override: bool = False) -> Dict[str, str]:
        self.dotenv.path = path
        return self.dotenv.load(override)

    def define(self, name: str, **kwargs) -> "EnvManager":
        self.parser.add(name, **kwargs)
        return self

    def parse(self) -> Dict[str, Any]:
        return self.parser.parse()

    def get(self, name: str, default: Any = None) -> Any:
        return os.environ.get(name, default)

    def set(self, name: str, value: str) -> None:
        os.environ[name] = value

    def require(self, *names: str) -> Dict[str, str]:
        result = {}
        missing = []
        for name in names:
            value = os.environ.get(name)
            if value is None:
                missing.append(name)
            else:
                result[name] = value
        if missing:
            raise EnvError(f"Missing required env vars: {', '.join(missing)}")
        return result

    def dump(self, pattern: str = None) -> Dict[str, str]:
        result = {}
        regex = re.compile(pattern) if pattern else None
        for key, value in os.environ.items():
            if regex is None or regex.match(key):
                result[key] = value
        return result


def load_dotenv(path: str = ".env", override: bool = False) -> Dict[str, str]:
    return DotEnv(path).load(override)


def get(name: str, default: str = None) -> Optional[str]:
    return os.environ.get(name, default)


def require(*names: str) -> Dict[str, str]:
    return EnvManager().require(*names)


def example_usage():
    os.environ["APP_DEBUG"] = "true"
    os.environ["APP_PORT"] = "8080"
    os.environ["APP_NAME"] = "myapp"
    
    parser = EnvParser()
    parser.set_prefix("APP")
    parser.add("DEBUG", type=bool, default=False)
    parser.add("PORT", type=int, default=3000)
    parser.add("NAME", type=str, required=True)
    parser.add("LOG_LEVEL", type=str, default="INFO", choices=["DEBUG", "INFO", "WARN", "ERROR"])
    
    config = parser.parse()
    print(f"Config: {config}")
    print(f"Debug: {parser.DEBUG}")
    print(f"Port: {parser.PORT}")
    
    manager = EnvManager()
    print(f"\nAll APP_* vars: {manager.dump('APP_.*')}")

