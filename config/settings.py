"""Centralised runtime configuration for the console."""

from __future__ import annotations

from dataclasses import dataclass


@dataclass(slots=True)
class Settings:
    """Basic settings container used across the console."""

    CACHE_TTL_SECONDS: int = 60
    CACHE_BACKEND: str = "memory"
    RANDOM_SEED: int = 1
    LOG_LEVEL: str = "INFO"


settings = Settings()
ENCRYPT_DATA_AT_REST = False
DATA_RETENTION_DAYS = 30
from __future__ import annotations

# mypy: ignore-errors
try:
    from pydantic_settings import BaseSettings
except Exception:  # pragma: no cover - fallback
    try:
        from pydantic import BaseSettings  # type: ignore[attr-defined]
    except Exception:
        from pydantic import BaseModel as BaseSettings
from pydantic import Field


class Settings(BaseSettings):
    """Application configuration loaded via pydantic."""

    APP_NAME: str = Field(default="PrismConsole")
    ARTIFACTS_DIR: str = Field(default="artifacts")
    READ_ONLY: bool = Field(default=False)
    RANDOM_SEED: int = Field(default=42)
    LOG_LEVEL: str = Field(default="INFO")


settings = Settings()
