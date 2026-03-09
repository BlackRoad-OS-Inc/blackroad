"""
RoadLocalize - Internationalization & Localization for BlackRoad
Multi-language support with translations, formatting, and locale management.
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


class PluralForm(str, Enum):
    """Plural form categories."""
    ZERO = "zero"
    ONE = "one"
    TWO = "two"
    FEW = "few"
    MANY = "many"
    OTHER = "other"


@dataclass
class Locale:
    """A locale configuration."""
    code: str  # e.g., "en-US", "fr-FR"
    name: str
    native_name: str
    direction: str = "ltr"  # ltr or rtl
    date_format: str = "YYYY-MM-DD"
    time_format: str = "HH:mm:ss"
    number_decimal: str = "."
    number_thousand: str = ","
    currency_symbol: str = "$"
    currency_position: str = "before"  # before or after
    plural_rule: Optional[Callable[[int], PluralForm]] = None

    def to_dict(self) -> Dict[str, Any]:
        return {
            "code": self.code,
            "name": self.name,
            "native_name": self.native_name,
            "direction": self.direction,
            "date_format": self.date_format,
            "time_format": self.time_format
        }


@dataclass
class Translation:
    """A translation entry."""
    key: str
    locale: str
    value: str
    plural_forms: Dict[str, str] = field(default_factory=dict)
    context: str = ""
    metadata: Dict[str, Any] = field(default_factory=dict)


class TranslationStore:
    """Store for translations."""

    def __init__(self):
        self.translations: Dict[str, Dict[str, Translation]] = {}  # locale -> key -> translation
        self.locales: Dict[str, Locale] = {}
        self._lock = threading.Lock()
        self._setup_default_locales()

    def _setup_default_locales(self):
        """Setup common locales."""
        self.add_locale(Locale(
            code="en-US",
            name="English (US)",
            native_name="English",
            currency_symbol="$"
        ))
        self.add_locale(Locale(
            code="en-GB",
            name="English (UK)",
            native_name="English",
            date_format="DD/MM/YYYY",
            currency_symbol="£"
        ))
        self.add_locale(Locale(
            code="es-ES",
            name="Spanish",
            native_name="Español",
            number_decimal=",",
            number_thousand=".",
            currency_symbol="€",
            currency_position="after"
        ))
        self.add_locale(Locale(
            code="fr-FR",
            name="French",
            native_name="Français",
            date_format="DD/MM/YYYY",
            number_decimal=",",
            number_thousand=" ",
            currency_symbol="€",
            currency_position="after"
        ))
        self.add_locale(Locale(
            code="de-DE",
            name="German",
            native_name="Deutsch",
            date_format="DD.MM.YYYY",
            number_decimal=",",
            number_thousand=".",
            currency_symbol="€",
            currency_position="after"
        ))
        self.add_locale(Locale(
            code="ja-JP",
            name="Japanese",
            native_name="日本語",
            date_format="YYYY年MM月DD日",
            currency_symbol="¥"
        ))
        self.add_locale(Locale(
            code="ar-SA",
            name="Arabic",
            native_name="العربية",
            direction="rtl",
            currency_symbol="﷼"
        ))

    def add_locale(self, locale: Locale) -> None:
        with self._lock:
            self.locales[locale.code] = locale
            if locale.code not in self.translations:
                self.translations[locale.code] = {}

    def get_locale(self, code: str) -> Optional[Locale]:
        return self.locales.get(code)

    def add_translation(self, translation: Translation) -> None:
        with self._lock:
            if translation.locale not in self.translations:
                self.translations[translation.locale] = {}
            self.translations[translation.locale][translation.key] = translation

    def get_translation(self, locale: str, key: str) -> Optional[Translation]:
        locale_translations = self.translations.get(locale, {})
        return locale_translations.get(key)

    def load_json(self, locale: str, data: Dict[str, Any], prefix: str = "") -> int:
        """Load translations from JSON dict."""
        count = 0
        for key, value in data.items():
            full_key = f"{prefix}.{key}" if prefix else key
            
            if isinstance(value, dict):
                if "one" in value or "other" in value:
                    # Plural forms
                    trans = Translation(
                        key=full_key,
                        locale=locale,
                        value=value.get("other", ""),
                        plural_forms=value
                    )
                    self.add_translation(trans)
                    count += 1
                else:
                    # Nested keys
                    count += self.load_json(locale, value, full_key)
            else:
                trans = Translation(key=full_key, locale=locale, value=str(value))
                self.add_translation(trans)
                count += 1
        
        return count

    def load_file(self, locale: str, file_path: str) -> int:
        """Load translations from JSON file."""
        with open(file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        return self.load_json(locale, data)


class Formatter:
    """Format values for locale."""

    def __init__(self, locale: Locale):
        self.locale = locale

    def number(self, value: Union[int, float, Decimal], decimals: int = 2) -> str:
        """Format number for locale."""
        if isinstance(value, int):
            formatted = f"{value:,}".replace(",", "THOUSAND")
        else:
            formatted = f"{value:,.{decimals}f}".replace(",", "THOUSAND")
            formatted = formatted.replace(".", self.locale.number_decimal)
        
        return formatted.replace("THOUSAND", self.locale.number_thousand)

    def currency(self, value: Union[int, float, Decimal], symbol: Optional[str] = None) -> str:
        """Format currency for locale."""
        sym = symbol or self.locale.currency_symbol
        num = self.number(value, 2)
        
        if self.locale.currency_position == "before":
            return f"{sym}{num}"
        else:
            return f"{num} {sym}"

    def date(self, value: Union[date, datetime], format_str: Optional[str] = None) -> str:
        """Format date for locale."""
        fmt = format_str or self.locale.date_format
        
        replacements = {
            "YYYY": str(value.year),
            "YY": str(value.year)[-2:],
            "MM": f"{value.month:02d}",
            "DD": f"{value.day:02d}",
            "年": "年",
            "月": "月",
            "日": "日"
        }
        
        result = fmt
        for key, val in replacements.items():
            result = result.replace(key, val)
        
        return result

    def time(self, value: datetime, format_str: Optional[str] = None) -> str:
        """Format time for locale."""
        fmt = format_str or self.locale.time_format
        
        replacements = {
            "HH": f"{value.hour:02d}",
            "mm": f"{value.minute:02d}",
            "ss": f"{value.second:02d}"
        }
        
        result = fmt
        for key, val in replacements.items():
            result = result.replace(key, val)
        
        return result

    def percentage(self, value: float, decimals: int = 1) -> str:
        """Format percentage."""
        return f"{self.number(value * 100, decimals)}%"


class Translator:
    """Main translation engine."""

    def __init__(self, store: TranslationStore, default_locale: str = "en-US"):
        self.store = store
        self.default_locale = default_locale
        self.fallback_chain: Dict[str, List[str]] = {
            "en-GB": ["en-US"],
            "es-MX": ["es-ES"],
            "fr-CA": ["fr-FR"],
            "pt-BR": ["pt-PT"],
            "zh-TW": ["zh-CN"]
        }
        self._interpolation_pattern = re.compile(r'\{\{(\w+)\}\}')

    def _get_plural_form(self, locale: str, count: int) -> PluralForm:
        """Get plural form for count in locale."""
        locale_obj = self.store.get_locale(locale)
        if locale_obj and locale_obj.plural_rule:
            return locale_obj.plural_rule(count)
        
        # Default English-like plural rules
        if count == 0:
            return PluralForm.ZERO
        elif count == 1:
            return PluralForm.ONE
        else:
            return PluralForm.OTHER

    def _interpolate(self, text: str, params: Dict[str, Any]) -> str:
        """Interpolate parameters into text."""
        def replace(match):
            key = match.group(1)
            return str(params.get(key, match.group(0)))
        
        return self._interpolation_pattern.sub(replace, text)

    def translate(
        self,
        key: str,
        locale: Optional[str] = None,
        params: Optional[Dict[str, Any]] = None,
        count: Optional[int] = None,
        default: Optional[str] = None
    ) -> str:
        """Translate a key."""
        locale = locale or self.default_locale
        params = params or {}

        # Try locale and fallbacks
        locales_to_try = [locale] + self.fallback_chain.get(locale, []) + [self.default_locale]
        
        for try_locale in locales_to_try:
            translation = self.store.get_translation(try_locale, key)
            if translation:
                # Handle plurals
                if count is not None and translation.plural_forms:
                    plural_form = self._get_plural_form(try_locale, count)
                    text = translation.plural_forms.get(
                        plural_form.value,
                        translation.plural_forms.get("other", translation.value)
                    )
                    params["count"] = count
                else:
                    text = translation.value
                
                return self._interpolate(text, params)

        # Return default or key
        return default if default is not None else key

    def t(self, key: str, **kwargs) -> str:
        """Shorthand for translate."""
        return self.translate(key, **kwargs)

    def has_translation(self, key: str, locale: Optional[str] = None) -> bool:
        """Check if translation exists."""
        locale = locale or self.default_locale
        return self.store.get_translation(locale, key) is not None


class LocaleManager:
    """Manage locale preferences."""

    def __init__(self, translator: Translator):
        self.translator = translator
        self._current_locale = threading.local()
        self._formatters: Dict[str, Formatter] = {}

    @property
    def current(self) -> str:
        """Get current locale."""
        return getattr(self._current_locale, 'value', self.translator.default_locale)

    @current.setter
    def current(self, locale: str) -> None:
        """Set current locale."""
        self._current_locale.value = locale

    def get_formatter(self, locale: Optional[str] = None) -> Formatter:
        """Get formatter for locale."""
        locale = locale or self.current
        if locale not in self._formatters:
            locale_obj = self.translator.store.get_locale(locale)
            if locale_obj:
                self._formatters[locale] = Formatter(locale_obj)
            else:
                # Fallback to default
                locale_obj = self.translator.store.get_locale(self.translator.default_locale)
                self._formatters[locale] = Formatter(locale_obj)
        return self._formatters[locale]

    def t(self, key: str, **kwargs) -> str:
        """Translate using current locale."""
        return self.translator.translate(key, locale=self.current, **kwargs)

    def format_number(self, value: Union[int, float], **kwargs) -> str:
        return self.get_formatter().number(value, **kwargs)

    def format_currency(self, value: Union[int, float], **kwargs) -> str:
        return self.get_formatter().currency(value, **kwargs)

    def format_date(self, value: Union[date, datetime], **kwargs) -> str:
        return self.get_formatter().date(value, **kwargs)


class I18n:
    """Main internationalization class."""

    def __init__(self, default_locale: str = "en-US"):
        self.store = TranslationStore()
        self.translator = Translator(self.store, default_locale)
        self.locale_manager = LocaleManager(self.translator)

    def load_translations(self, locale: str, translations: Dict[str, Any]) -> int:
        """Load translations for locale."""
        return self.store.load_json(locale, translations)

    def load_file(self, locale: str, file_path: str) -> int:
        """Load translations from file."""
        return self.store.load_file(locale, file_path)

    def t(self, key: str, **kwargs) -> str:
        """Translate key."""
        return self.locale_manager.t(key, **kwargs)

    def set_locale(self, locale: str) -> None:
        """Set current locale."""
        self.locale_manager.current = locale

    def get_locale(self) -> str:
        """Get current locale."""
        return self.locale_manager.current

    def format(self, value: Any, format_type: str = "auto") -> str:
        """Format value based on type."""
        formatter = self.locale_manager.get_formatter()
        
        if format_type == "number" or isinstance(value, (int, float, Decimal)):
            return formatter.number(value)
        elif format_type == "currency":
            return formatter.currency(value)
        elif format_type == "date" or isinstance(value, (date, datetime)):
            return formatter.date(value)
        elif format_type == "percentage":
            return formatter.percentage(value)
        
        return str(value)

    def available_locales(self) -> List[str]:
        """Get available locales."""
        return list(self.store.locales.keys())


# Example usage
def example_usage():
    """Example i18n usage."""
    i18n = I18n(default_locale="en-US")

    # Load translations
    i18n.load_translations("en-US", {
        "greeting": "Hello, {{name}}!",
        "items": {
            "one": "{{count}} item",
            "other": "{{count}} items"
        },
        "welcome": "Welcome to BlackRoad"
    })

    i18n.load_translations("es-ES", {
        "greeting": "¡Hola, {{name}}!",
        "items": {
            "one": "{{count}} artículo",
            "other": "{{count}} artículos"
        },
        "welcome": "Bienvenido a BlackRoad"
    })

    # Translate
    print(i18n.t("greeting", params={"name": "Alice"}))
    print(i18n.t("items", count=1))
    print(i18n.t("items", count=5))

    # Change locale
    i18n.set_locale("es-ES")
    print(i18n.t("greeting", params={"name": "Alice"}))
    print(i18n.t("welcome"))

    # Formatting
    print(f"Number: {i18n.format(1234567.89, 'number')}")
    print(f"Currency: {i18n.format(99.99, 'currency')}")
    print(f"Date: {i18n.format(datetime.now(), 'date')}")
