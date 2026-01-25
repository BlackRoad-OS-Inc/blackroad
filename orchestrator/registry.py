import importlib
import pkgutil
from pathlib import Path
from typing import Optional, Type

from sdk import plugin_api

BOT_REGISTRY = plugin_api.BOT_REGISTRY


def _load_modules_from(path: Path, package: str) -> None:
    if not path.exists():
        return
    for module in pkgutil.iter_modules([str(path)]):
        importlib.import_module(f"{package}.{module.name}")


def load_all() -> None:
    base = Path(__file__).resolve().parent.parent
    _load_modules_from(base / "bots", "bots")
    _load_modules_from(base / "plugins", "plugins")


load_all()


def get_bot(name: str) -> Optional[Type[plugin_api.BaseBot]]:
    return BOT_REGISTRY.get(name)
from __future__ import annotations

import builtins
from importlib import import_module
from pathlib import Path
from typing import Dict, List

from .base import BaseBot

_registry: Dict[str, BaseBot] = {}


def register(bot: BaseBot) -> None:
    _registry[bot.NAME] = bot


def get(name: str) -> BaseBot:
    return _registry[name]


def list() -> List[BaseBot]:
    return builtins.list(_registry.values())


def _discover(path: Path) -> None:
    if not path.exists():
        return
    for file in path.glob("*_bot.py"):
        module_name = f"{path.name}.{file.stem}"
        import_module(module_name)


_repo_root = Path(__file__).resolve().parent.parent
_discover(_repo_root / "bots")
_plugins = _repo_root / "plugins"
if _plugins.exists():
    _discover(_plugins)
