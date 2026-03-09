"""
RoadConfig - Configuration Management for BlackRoad
Unified configuration with multiple sources and validation.
"""

from dataclasses import dataclass, field
from enum import Enum
from typing import Any, Callable, Dict, List, Optional, Type, Union
import json
import os
import logging

logger = logging.getLogger(__name__)


class ConfigError(Exception):
    pass


class ConfigSource(str, Enum):
    ENV = "env"
    FILE = "file"
    DEFAULT = "default"
    OVERRIDE = "override"


@dataclass
class ConfigValue:
    key: str
    value: Any
    source: ConfigSource
    type: Type = str


@dataclass
class ConfigSchema:
    key: str
    type: Type = str
    default: Any = None
    required: bool = False
    description: str = ""
    env_var: str = ""
    choices: List[Any] = field(default_factory=list)
    validator: Callable = None
    sensitive: bool = False


class ConfigLoader:
    def load(self, source: str) -> Dict[str, Any]:
        raise NotImplementedError


class JSONLoader(ConfigLoader):
    def load(self, source: str) -> Dict[str, Any]:
        with open(source, "r") as f:
            return json.load(f)


class EnvLoader(ConfigLoader):
    def __init__(self, prefix: str = ""):
        self.prefix = prefix

    def load(self, source: str = None) -> Dict[str, Any]:
        result = {}
        prefix = self.prefix.upper() + "_" if self.prefix else ""
        for key, value in os.environ.items():
            if prefix and key.startswith(prefix):
                clean_key = key[len(prefix):].lower()
                result[clean_key] = value
            elif not prefix:
                result[key.lower()] = value
        return result


class DictLoader(ConfigLoader):
    def __init__(self, data: Dict[str, Any]):
        self.data = data

    def load(self, source: str = None) -> Dict[str, Any]:
        return self.data


class Config:
    def __init__(self):
        self._values: Dict[str, ConfigValue] = {}
        self._schema: Dict[str, ConfigSchema] = {}
        self._loaders: List[tuple] = []
        self._frozen = False

    def add_loader(self, loader: ConfigLoader, source: str = None, priority: int = 0) -> "Config":
        self._loaders.append((priority, loader, source))
        self._loaders.sort(key=lambda x: x[0])
        return self

    def define(self, key: str, type: Type = str, default: Any = None, required: bool = False,
               description: str = "", env_var: str = "", choices: List = None,
               validator: Callable = None, sensitive: bool = False) -> "Config":
        self._schema[key] = ConfigSchema(
            key=key, type=type, default=default, required=required,
            description=description, env_var=env_var or key.upper(),
            choices=choices or [], validator=validator, sensitive=sensitive
        )
        return self

    def load(self) -> "Config":
        raw_values = {}

        for schema in self._schema.values():
            if schema.default is not None:
                raw_values[schema.key] = (schema.default, ConfigSource.DEFAULT)

        for priority, loader, source in self._loaders:
            try:
                data = loader.load(source)
                for key, value in data.items():
                    src = ConfigSource.FILE if isinstance(loader, JSONLoader) else ConfigSource.ENV
                    raw_values[key] = (value, src)
            except Exception as e:
                logger.warning(f"Failed to load config from {source}: {e}")

        for schema in self._schema.values():
            if schema.env_var:
                env_value = os.environ.get(schema.env_var)
                if env_value is not None:
                    raw_values[schema.key] = (env_value, ConfigSource.ENV)

        errors = []
        for key, schema in self._schema.items():
            if key not in raw_values:
                if schema.required:
                    errors.append(f"Required config '{key}' not found")
                continue

            raw_value, source = raw_values[key]

            try:
                value = self._convert(raw_value, schema.type)
            except (ValueError, TypeError) as e:
                errors.append(f"Invalid type for '{key}': {e}")
                continue

            if schema.choices and value not in schema.choices:
                errors.append(f"'{key}' must be one of {schema.choices}")
                continue

            if schema.validator and not schema.validator(value):
                errors.append(f"'{key}' failed validation")
                continue

            self._values[key] = ConfigValue(key=key, value=value, source=source, type=schema.type)

        if errors:
            raise ConfigError("; ".join(errors))

        return self

    def _convert(self, value: Any, typ: Type) -> Any:
        if isinstance(value, typ):
            return value
        if typ == bool:
            if isinstance(value, str):
                return value.lower() in ("true", "1", "yes", "on")
            return bool(value)
        if typ == list:
            if isinstance(value, str):
                return [v.strip() for v in value.split(",")]
            return list(value)
        if typ == dict:
            if isinstance(value, str):
                return json.loads(value)
            return dict(value)
        return typ(value)

    def get(self, key: str, default: Any = None) -> Any:
        if key in self._values:
            return self._values[key].value
        return default

    def set(self, key: str, value: Any) -> None:
        if self._frozen:
            raise ConfigError("Config is frozen")
        if key in self._schema:
            value = self._convert(value, self._schema[key].type)
        self._values[key] = ConfigValue(key=key, value=value, source=ConfigSource.OVERRIDE, type=type(value))

    def freeze(self) -> "Config":
        self._frozen = True
        return self

    def to_dict(self, include_sensitive: bool = False) -> Dict[str, Any]:
        result = {}
        for key, cv in self._values.items():
            if not include_sensitive and key in self._schema and self._schema[key].sensitive:
                result[key] = "***"
            else:
                result[key] = cv.value
        return result

    def __getattr__(self, name: str) -> Any:
        if name.startswith("_"):
            return super().__getattribute__(name)
        return self.get(name)

    def __getitem__(self, key: str) -> Any:
        return self.get(key)

    def __contains__(self, key: str) -> bool:
        return key in self._values


class ConfigBuilder:
    def __init__(self):
        self.config = Config()

    def with_env(self, prefix: str = "") -> "ConfigBuilder":
        self.config.add_loader(EnvLoader(prefix), priority=10)
        return self

    def with_json(self, path: str) -> "ConfigBuilder":
        self.config.add_loader(JSONLoader(), path, priority=5)
        return self

    def with_defaults(self, defaults: Dict[str, Any]) -> "ConfigBuilder":
        self.config.add_loader(DictLoader(defaults), priority=0)
        return self

    def define(self, key: str, **kwargs) -> "ConfigBuilder":
        self.config.define(key, **kwargs)
        return self

    def build(self) -> Config:
        return self.config.load()


def create_config() -> ConfigBuilder:
    return ConfigBuilder()


def example_usage():
    os.environ["APP_DEBUG"] = "true"
    os.environ["APP_PORT"] = "8080"
    os.environ["APP_SECRET"] = "mysecret123"

    config = (create_config()
        .with_defaults({"host": "localhost", "port": 3000})
        .with_env("APP")
        .define("debug", type=bool, default=False, description="Enable debug mode")
        .define("port", type=int, default=3000, description="Server port")
        .define("host", type=str, default="localhost")
        .define("secret", type=str, required=True, sensitive=True)
        .build())

    print(f"Debug: {config.debug}")
    print(f"Port: {config.port}")
    print(f"Host: {config.host}")
    print(f"\nAll config: {config.to_dict()}")
    print(f"With secrets: {config.to_dict(include_sensitive=True)}")

