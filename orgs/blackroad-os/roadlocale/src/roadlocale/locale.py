"""
RoadLocale - i18n/l10n for BlackRoad
Internationalization with message catalogs, pluralization, and formatting.
"""

from dataclasses import dataclass, field
from datetime import datetime, date
from decimal import Decimal
from enum import Enum
from typing import Any, Callable, Dict, List, Optional, Union
import json
import logging
import os
import re
import threading

logger = logging.getLogger(__name__)


class PluralRule(str, Enum):
    """Plural rule categories."""
    ZERO = "zero"
    ONE = "one"
    TWO = "two"
    FEW = "few"
    MANY = "many"
    OTHER = "other"


@dataclass
class Message:
    """A translatable message."""
    key: str
    value: str
    plural_forms: Dict[str, str] = field(default_factory=dict)
    context: str = ""
    description: str = ""


@dataclass
class Locale:
    """Locale configuration."""
    code: str  # e.g., "en-US"
    language: str  # e.g., "en"
    region: Optional[str] = None  # e.g., "US"
    name: str = ""
    direction: str = "ltr"  # ltr or rtl
    date_format: str = "%Y-%m-%d"
    time_format: str = "%H:%M:%S"
    datetime_format: str = "%Y-%m-%d %H:%M:%S"
    decimal_separator: str = "."
    thousands_separator: str = ","
    currency_symbol: str = "$"
    currency_format: str = "{symbol}{amount}"


class MessageCatalog:
    """Catalog of messages for a locale."""

    def __init__(self, locale: Locale):
        self.locale = locale
        self.messages: Dict[str, Message] = {}
        self._lock = threading.Lock()

    def add(self, message: Message) -> None:
        """Add a message to the catalog."""
        with self._lock:
            key = f"{message.context}:{message.key}" if message.context else message.key
            self.messages[key] = message

    def get(self, key: str, context: str = "") -> Optional[Message]:
        """Get a message by key."""
        full_key = f"{context}:{key}" if context else key
        return self.messages.get(full_key) or self.messages.get(key)

    def add_messages(self, messages: Dict[str, str]) -> None:
        """Add multiple messages from a dict."""
        for key, value in messages.items():
            self.add(Message(key=key, value=value))

    def load_json(self, path: str) -> int:
        """Load messages from JSON file."""
        with open(path, "r", encoding="utf-8") as f:
            data = json.load(f)

        count = 0
        for key, value in data.items():
            if isinstance(value, str):
                self.add(Message(key=key, value=value))
            elif isinstance(value, dict):
                # Has plural forms or metadata
                msg = Message(
                    key=key,
                    value=value.get("value", value.get("one", "")),
                    plural_forms=value.get("plural", {}),
                    context=value.get("context", ""),
                    description=value.get("description", "")
                )
                self.add(msg)
            count += 1

        return count

    def to_dict(self) -> Dict[str, Any]:
        """Export catalog to dict."""
        result = {}
        for key, msg in self.messages.items():
            if msg.plural_forms:
                result[key] = {
                    "value": msg.value,
                    "plural": msg.plural_forms
                }
            else:
                result[key] = msg.value
        return result


class PluralRules:
    """Plural rules for different languages."""

    @staticmethod
    def get_rule(language: str, n: float) -> PluralRule:
        """Get plural rule for a number in a language."""
        n = abs(n)

        # English-like: 1 is singular, rest is plural
        if language in ["en", "de", "es", "it", "pt", "nl"]:
            return PluralRule.ONE if n == 1 else PluralRule.OTHER

        # French: 0 and 1 are singular
        if language == "fr":
            return PluralRule.ONE if n < 2 else PluralRule.OTHER

        # Russian/Polish complex rules
        if language in ["ru", "pl", "uk"]:
            n_mod_10 = n % 10
            n_mod_100 = n % 100

            if n_mod_10 == 1 and n_mod_100 != 11:
                return PluralRule.ONE
            elif n_mod_10 in [2, 3, 4] and n_mod_100 not in [12, 13, 14]:
                return PluralRule.FEW
            else:
                return PluralRule.MANY

        # Arabic
        if language == "ar":
            if n == 0:
                return PluralRule.ZERO
            elif n == 1:
                return PluralRule.ONE
            elif n == 2:
                return PluralRule.TWO
            elif 3 <= n % 100 <= 10:
                return PluralRule.FEW
            elif 11 <= n % 100 <= 99:
                return PluralRule.MANY
            else:
                return PluralRule.OTHER

        # Default
        return PluralRule.ONE if n == 1 else PluralRule.OTHER


class MessageFormatter:
    """Format messages with interpolation."""

    # Pattern for {variable} placeholders
    PLACEHOLDER_PATTERN = re.compile(r"\{(\w+)(?::([^}]+))?\}")

    def __init__(self, locale: Locale):
        self.locale = locale

    def format(self, template: str, **kwargs) -> str:
        """Format a message template with values."""
        def replace(match):
            name = match.group(1)
            format_spec = match.group(2)

            if name not in kwargs:
                return match.group(0)

            value = kwargs[name]

            if format_spec:
                return self._apply_format(value, format_spec)

            return str(value)

        return self.PLACEHOLDER_PATTERN.sub(replace, template)

    def _apply_format(self, value: Any, spec: str) -> str:
        """Apply format specification."""
        if spec == "number":
            return self.format_number(value)
        elif spec == "currency":
            return self.format_currency(value)
        elif spec == "date":
            return self.format_date(value)
        elif spec == "time":
            return self.format_time(value)
        elif spec == "datetime":
            return self.format_datetime(value)
        elif spec.startswith("decimal:"):
            places = int(spec.split(":")[1])
            return self.format_decimal(value, places)
        else:
            return str(value)

    def format_number(self, value: Union[int, float], decimals: int = 0) -> str:
        """Format a number with locale separators."""
        if isinstance(value, float):
            formatted = f"{value:,.{decimals}f}"
        else:
            formatted = f"{value:,}"

        # Replace with locale separators
        formatted = formatted.replace(",", "__THOUSANDS__")
        formatted = formatted.replace(".", self.locale.decimal_separator)
        formatted = formatted.replace("__THOUSANDS__", self.locale.thousands_separator)

        return formatted

    def format_decimal(self, value: float, places: int = 2) -> str:
        """Format a decimal number."""
        return self.format_number(value, places)

    def format_currency(self, value: float, symbol: str = None) -> str:
        """Format a currency value."""
        symbol = symbol or self.locale.currency_symbol
        amount = self.format_decimal(abs(value), 2)

        formatted = self.locale.currency_format.format(
            symbol=symbol,
            amount=amount
        )

        if value < 0:
            formatted = "-" + formatted

        return formatted

    def format_date(self, value: Union[datetime, date]) -> str:
        """Format a date."""
        if isinstance(value, datetime):
            value = value.date()
        return value.strftime(self.locale.date_format)

    def format_time(self, value: datetime) -> str:
        """Format a time."""
        return value.strftime(self.locale.time_format)

    def format_datetime(self, value: datetime) -> str:
        """Format a datetime."""
        return value.strftime(self.locale.datetime_format)


class Translator:
    """Main translation interface."""

    def __init__(self, default_locale: str = "en"):
        self.default_locale = default_locale
        self.current_locale = default_locale
        self.locales: Dict[str, Locale] = {}
        self.catalogs: Dict[str, MessageCatalog] = {}
        self.formatters: Dict[str, MessageFormatter] = {}
        self._fallback_chain: Dict[str, List[str]] = {}
        self._lock = threading.Lock()

        # Add default English locale
        self.add_locale(Locale(
            code="en",
            language="en",
            name="English"
        ))

    def add_locale(self, locale: Locale) -> None:
        """Add a locale configuration."""
        with self._lock:
            self.locales[locale.code] = locale
            self.catalogs[locale.code] = MessageCatalog(locale)
            self.formatters[locale.code] = MessageFormatter(locale)

    def set_locale(self, code: str) -> bool:
        """Set the current locale."""
        if code in self.locales:
            self.current_locale = code
            return True
        return False

    def set_fallback_chain(self, locale: str, fallbacks: List[str]) -> None:
        """Set fallback locales for a locale."""
        self._fallback_chain[locale] = fallbacks

    def get_catalog(self, locale: str = None) -> Optional[MessageCatalog]:
        """Get message catalog for locale."""
        locale = locale or self.current_locale
        return self.catalogs.get(locale)

    def t(
        self,
        key: str,
        locale: str = None,
        context: str = "",
        **kwargs
    ) -> str:
        """Translate a message key."""
        locale = locale or self.current_locale

        # Try to find message in locale chain
        message = self._find_message(key, locale, context)

        if not message:
            logger.warning(f"Missing translation: {key} ({locale})")
            return key

        # Format the message
        formatter = self.formatters.get(locale) or self.formatters[self.default_locale]
        return formatter.format(message.value, **kwargs)

    def tn(
        self,
        key: str,
        count: int,
        locale: str = None,
        context: str = "",
        **kwargs
    ) -> str:
        """Translate with pluralization."""
        locale = locale or self.current_locale
        locale_obj = self.locales.get(locale)

        if not locale_obj:
            return key

        message = self._find_message(key, locale, context)
        if not message:
            return key

        # Get plural form
        rule = PluralRules.get_rule(locale_obj.language, count)
        template = message.plural_forms.get(rule.value, message.value)

        # Format with count
        kwargs["count"] = count
        formatter = self.formatters.get(locale) or self.formatters[self.default_locale]
        return formatter.format(template, **kwargs)

    def _find_message(
        self,
        key: str,
        locale: str,
        context: str
    ) -> Optional[Message]:
        """Find message in locale with fallback."""
        # Try current locale
        catalog = self.catalogs.get(locale)
        if catalog:
            message = catalog.get(key, context)
            if message:
                return message

        # Try fallback chain
        fallbacks = self._fallback_chain.get(locale, [])
        for fallback in fallbacks:
            catalog = self.catalogs.get(fallback)
            if catalog:
                message = catalog.get(key, context)
                if message:
                    return message

        # Try default locale
        if locale != self.default_locale:
            catalog = self.catalogs.get(self.default_locale)
            if catalog:
                return catalog.get(key, context)

        return None

    def load_messages(self, locale: str, messages: Dict[str, str]) -> None:
        """Load messages for a locale."""
        catalog = self.catalogs.get(locale)
        if catalog:
            catalog.add_messages(messages)

    def load_json(self, locale: str, path: str) -> int:
        """Load messages from JSON file."""
        catalog = self.catalogs.get(locale)
        if catalog:
            return catalog.load_json(path)
        return 0


class LocaleManager:
    """High-level locale management."""

    def __init__(self, locales_dir: str = None):
        self.translator = Translator()
        self.locales_dir = locales_dir

    def add_locale(
        self,
        code: str,
        language: str,
        name: str = "",
        **kwargs
    ) -> None:
        """Add a new locale."""
        locale = Locale(
            code=code,
            language=language,
            name=name or code,
            **kwargs
        )
        self.translator.add_locale(locale)

    def set_locale(self, code: str) -> bool:
        """Set current locale."""
        return self.translator.set_locale(code)

    def get_locale(self) -> str:
        """Get current locale code."""
        return self.translator.current_locale

    def t(self, key: str, **kwargs) -> str:
        """Translate a key."""
        return self.translator.t(key, **kwargs)

    def tn(self, key: str, count: int, **kwargs) -> str:
        """Translate with pluralization."""
        return self.translator.tn(key, count, **kwargs)

    def load_all(self) -> int:
        """Load all locale files from directory."""
        if not self.locales_dir or not os.path.exists(self.locales_dir):
            return 0

        count = 0
        for filename in os.listdir(self.locales_dir):
            if filename.endswith(".json"):
                locale_code = filename[:-5]
                path = os.path.join(self.locales_dir, filename)

                # Create locale if not exists
                if locale_code not in self.translator.locales:
                    self.add_locale(locale_code, locale_code.split("-")[0])

                count += self.translator.load_json(locale_code, path)

        return count

    def format_number(self, value: Union[int, float], decimals: int = 0) -> str:
        """Format number for current locale."""
        formatter = self.translator.formatters.get(self.translator.current_locale)
        if formatter:
            return formatter.format_number(value, decimals)
        return str(value)

    def format_currency(self, value: float, symbol: str = None) -> str:
        """Format currency for current locale."""
        formatter = self.translator.formatters.get(self.translator.current_locale)
        if formatter:
            return formatter.format_currency(value, symbol)
        return str(value)

    def format_date(self, value: Union[datetime, date]) -> str:
        """Format date for current locale."""
        formatter = self.translator.formatters.get(self.translator.current_locale)
        if formatter:
            return formatter.format_date(value)
        return str(value)

    def list_locales(self) -> List[Dict[str, str]]:
        """List available locales."""
        return [
            {"code": loc.code, "name": loc.name, "language": loc.language}
            for loc in self.translator.locales.values()
        ]


# Convenience functions
_manager: Optional[LocaleManager] = None


def init(locales_dir: str = None) -> LocaleManager:
    """Initialize the locale system."""
    global _manager
    _manager = LocaleManager(locales_dir)
    return _manager


def t(key: str, **kwargs) -> str:
    """Translate a key."""
    if _manager:
        return _manager.t(key, **kwargs)
    return key


def tn(key: str, count: int, **kwargs) -> str:
    """Translate with pluralization."""
    if _manager:
        return _manager.tn(key, count, **kwargs)
    return key


# Example usage
def example_usage():
    """Example locale usage."""
    manager = LocaleManager()

    # Add locales
    manager.add_locale("en", "en", "English")
    manager.add_locale("es", "es", "Spanish",
                       currency_symbol="€",
                       decimal_separator=",",
                       thousands_separator=".")
    manager.add_locale("fr", "fr", "French")

    # Load messages
    manager.translator.load_messages("en", {
        "welcome": "Welcome, {name}!",
        "items": "You have {count} item",
        "price": "Total: {amount:currency}"
    })

    manager.translator.load_messages("es", {
        "welcome": "¡Bienvenido, {name}!",
        "items": "Tienes {count} artículo",
        "price": "Total: {amount:currency}"
    })

    # Add plural forms
    catalog = manager.translator.get_catalog("en")
    catalog.add(Message(
        key="items",
        value="You have {count} item",
        plural_forms={
            "one": "You have {count} item",
            "other": "You have {count} items"
        }
    ))

    # Translate
    print(manager.t("welcome", name="Alice"))

    # With pluralization
    print(manager.tn("items", 1))
    print(manager.tn("items", 5))

    # Change locale
    manager.set_locale("es")
    print(manager.t("welcome", name="Alice"))

    # Format numbers
    print(manager.format_currency(1234.56))
    print(manager.format_number(1000000))

    # List locales
    print(f"Available: {manager.list_locales()}")

