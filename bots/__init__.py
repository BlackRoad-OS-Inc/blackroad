"""Bot discovery helpers used by integration tests."""

from __future__ import annotations

from importlib import import_module
from pathlib import Path
from typing import Dict, Iterable, Iterator, Sequence, Tuple

from orchestrator import BaseBot, BotRegistry

BotLike = BaseBot | object
BOT_REGISTRY: Dict[str, BotLike] = {}


def _iter_bot_modules() -> Iterable[str]:
    """Yield module names for concrete bot implementations."""

    package_path = Path(__file__).resolve().parent
    for module_path in package_path.glob("*_bot.py"):
        if module_path.stem == "simple":
            # ``simple.py`` contains fixtures used only in tests.
            continue
        yield module_path.stem


def _instantiate_bots(module_name: str) -> Iterator[Tuple[str, BotLike]]:
    """Instantiate bots exposed by ``module_name``."""

    module = import_module(f"bots.{module_name}")

    bot_cls = getattr(module, "Bot", None)
    if bot_cls is not None:
        bot = bot_cls()
        name = getattr(bot, "NAME", getattr(bot_cls, "NAME", bot_cls.__name__))
        yield name, bot

    for attr_name in dir(module):
        attr = getattr(module, attr_name)
        if not isinstance(attr, type):
            continue
        if not issubclass(attr, BaseBot) or attr is BaseBot:
            continue
        bot_instance = attr()
        yield bot_instance.metadata.name, bot_instance


def _discover() -> None:
    """Populate :data:`BOT_REGISTRY` with discovered bot instances."""

    BOT_REGISTRY.clear()
    for module_name in _iter_bot_modules():
        for name, bot in _instantiate_bots(module_name):
            BOT_REGISTRY[name] = bot


_discover()


def build_registry() -> BotRegistry:
    """Instantiate a :class:`BotRegistry` populated with discovered bots."""

    registry = BotRegistry()
    for bot in BOT_REGISTRY.values():
        if isinstance(bot, BaseBot):
            registry.register(bot)
    return registry


def list_bots() -> Sequence[str]:
    """Return the sorted list of discovered bot names."""

    return tuple(sorted(BOT_REGISTRY))


__all__ = ["BOT_REGISTRY", "build_registry", "list_bots"]
"""Bot registry and utilities."""
import importlib
import pkgutil
from typing import Dict, Type

from orchestrator.base import BaseBot


def available_bots() -> Dict[str, Type[BaseBot]]:
    """Discover available bots in this package."""
    bots: Dict[str, Type[BaseBot]] = {}
    package_path = __path__  # type: ignore[name-defined]
    for module in pkgutil.iter_modules(package_path):
        mod = importlib.import_module(f"{__name__}.{module.name}")
        for attr in dir(mod):
            obj = getattr(mod, attr)
            if isinstance(obj, type) and issubclass(obj, BaseBot) and obj is not BaseBot:
                bots[obj.name] = obj
    return bots
from .comms import CommsBot
from .finance import FinanceBot
from .grc import GRCBot
from .gtm import GTMBot
from .industry import IndustryBot
from .it import ITBot
from .ops import OpsBot
from .people import PeopleBot
from .product_eng_data import ProductEngDataBot
from .regional import RegionalBot

BOT_REGISTRY = {
    "finance": FinanceBot,
    "grc": GRCBot,
    "people": PeopleBot,
    "gtm": GTMBot,
    "product_eng_data": ProductEngDataBot,
    "ops": OpsBot,
    "it": ITBot,
    "comms": CommsBot,
    "regional": RegionalBot,
    "industry": IndustryBot,
}

__all__ = ["BOT_REGISTRY", "FinanceBot", "GRCBot", "PeopleBot", "GTMBot", "ProductEngDataBot", "OpsBot", "ITBot", "CommsBot", "RegionalBot", "IndustryBot"]
