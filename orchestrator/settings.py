"""Load basic settings."""
from __future__ import annotations

from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[1]
SETTINGS_FILE = ROOT / "config" / "settings.yaml"
_data = yaml.safe_load(SETTINGS_FILE.read_text()) if SETTINGS_FILE.exists() else {}

MULTI_TENANT: bool = bool(_data.get("MULTI_TENANT", False))
