"""
RoadValidate - Data Validation for BlackRoad
Fluent validation with rules, messages, and transformations.
"""

from dataclasses import dataclass, field
from datetime import datetime, date
from decimal import Decimal
from enum import Enum
from typing import Any, Callable, Dict, List, Optional, Pattern, Type, Union
import re
import logging

logger = logging.getLogger(__name__)


@dataclass
class ValidationError:
    field: str
    rule: str
    message: str
    value: Any = None


@dataclass
class ValidationResult:
    valid: bool
    errors: List[ValidationError] = field(default_factory=list)
    data: Any = None


class Rule:
    def __init__(self, name: str, fn: Callable[[Any], bool], message: str = "Validation failed"):
        self.name = name
        self.fn = fn
        self.message = message

    def validate(self, value: Any) -> bool:
        return self.fn(value)


class Rules:
    @staticmethod
    def required(message: str = "This field is required") -> Rule:
        def check(value):
            if value is None:
                return False
            if isinstance(value, str) and not value.strip():
                return False
            return True
        return Rule("required", check, message)

    @staticmethod
    def string(message: str = "Must be a string") -> Rule:
        return Rule("string", lambda v: isinstance(v, str), message)

    @staticmethod
    def integer(message: str = "Must be an integer") -> Rule:
        return Rule("integer", lambda v: isinstance(v, int) and not isinstance(v, bool), message)

    @staticmethod
    def number(message: str = "Must be a number") -> Rule:
        return Rule("number", lambda v: isinstance(v, (int, float, Decimal)) and not isinstance(v, bool), message)

    @staticmethod
    def boolean(message: str = "Must be a boolean") -> Rule:
        return Rule("boolean", lambda v: isinstance(v, bool), message)

    @staticmethod
    def email(message: str = "Invalid email address") -> Rule:
        pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
        return Rule("email", lambda v: bool(re.match(pattern, str(v))) if v else True, message)

    @staticmethod
    def url(message: str = "Invalid URL") -> Rule:
        pattern = r'^https?://[^\s/$.?#].[^\s]*$'
        return Rule("url", lambda v: bool(re.match(pattern, str(v))) if v else True, message)

    @staticmethod
    def min_length(length: int, message: str = None) -> Rule:
        return Rule("min_length", lambda v: len(str(v)) >= length if v else True, message or f"Minimum length is {length}")

    @staticmethod
    def max_length(length: int, message: str = None) -> Rule:
        return Rule("max_length", lambda v: len(str(v)) <= length if v else True, message or f"Maximum length is {length}")

    @staticmethod
    def length(exact: int = None, min_len: int = None, max_len: int = None, message: str = None) -> Rule:
        def check(v):
            if not v:
                return True
            l = len(v)
            if exact is not None and l != exact:
                return False
            if min_len is not None and l < min_len:
                return False
            if max_len is not None and l > max_len:
                return False
            return True
        return Rule("length", check, message or "Invalid length")

    @staticmethod
    def min_value(value: float, message: str = None) -> Rule:
        return Rule("min_value", lambda v: float(v) >= value if v is not None else True, message or f"Minimum value is {value}")

    @staticmethod
    def max_value(value: float, message: str = None) -> Rule:
        return Rule("max_value", lambda v: float(v) <= value if v is not None else True, message or f"Maximum value is {value}")

    @staticmethod
    def between(min_val: float, max_val: float, message: str = None) -> Rule:
        return Rule("between", lambda v: min_val <= float(v) <= max_val if v is not None else True, message or f"Must be between {min_val} and {max_val}")

    @staticmethod
    def in_list(options: List[Any], message: str = None) -> Rule:
        return Rule("in_list", lambda v: v in options if v else True, message or f"Must be one of {options}")

    @staticmethod
    def not_in_list(options: List[Any], message: str = None) -> Rule:
        return Rule("not_in_list", lambda v: v not in options if v else True, message or f"Cannot be one of {options}")

    @staticmethod
    def pattern(regex: str, message: str = "Invalid format") -> Rule:
        return Rule("pattern", lambda v: bool(re.match(regex, str(v))) if v else True, message)

    @staticmethod
    def alpha(message: str = "Must contain only letters") -> Rule:
        return Rule("alpha", lambda v: str(v).isalpha() if v else True, message)

    @staticmethod
    def alphanumeric(message: str = "Must contain only letters and numbers") -> Rule:
        return Rule("alphanumeric", lambda v: str(v).isalnum() if v else True, message)

    @staticmethod
    def uuid(message: str = "Invalid UUID") -> Rule:
        pattern = r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
        return Rule("uuid", lambda v: bool(re.match(pattern, str(v).lower())) if v else True, message)

    @staticmethod
    def date_format(fmt: str = "%Y-%m-%d", message: str = None) -> Rule:
        def check(v):
            if not v:
                return True
            try:
                datetime.strptime(str(v), fmt)
                return True
            except ValueError:
                return False
        return Rule("date_format", check, message or f"Date must match format {fmt}")

    @staticmethod
    def custom(fn: Callable[[Any], bool], message: str = "Validation failed") -> Rule:
        return Rule("custom", fn, message)


class FieldValidator:
    def __init__(self, field_name: str):
        self.field_name = field_name
        self.rules: List[Rule] = []
        self.transform: Optional[Callable] = None
        self.optional = False

    def add(self, rule: Rule) -> "FieldValidator":
        self.rules.append(rule)
        return self

    def required(self, message: str = None) -> "FieldValidator":
        return self.add(Rules.required(message or f"{self.field_name} is required"))

    def string(self) -> "FieldValidator":
        return self.add(Rules.string())

    def integer(self) -> "FieldValidator":
        return self.add(Rules.integer())

    def number(self) -> "FieldValidator":
        return self.add(Rules.number())

    def boolean(self) -> "FieldValidator":
        return self.add(Rules.boolean())

    def email(self) -> "FieldValidator":
        return self.add(Rules.email())

    def url(self) -> "FieldValidator":
        return self.add(Rules.url())

    def min_length(self, length: int) -> "FieldValidator":
        return self.add(Rules.min_length(length))

    def max_length(self, length: int) -> "FieldValidator":
        return self.add(Rules.max_length(length))

    def min_value(self, value: float) -> "FieldValidator":
        return self.add(Rules.min_value(value))

    def max_value(self, value: float) -> "FieldValidator":
        return self.add(Rules.max_value(value))

    def between(self, min_val: float, max_val: float) -> "FieldValidator":
        return self.add(Rules.between(min_val, max_val))

    def in_list(self, options: List[Any]) -> "FieldValidator":
        return self.add(Rules.in_list(options))

    def pattern(self, regex: str, message: str = None) -> "FieldValidator":
        return self.add(Rules.pattern(regex, message or "Invalid format"))

    def uuid(self) -> "FieldValidator":
        return self.add(Rules.uuid())

    def custom(self, fn: Callable, message: str = None) -> "FieldValidator":
        return self.add(Rules.custom(fn, message or "Validation failed"))

    def nullable(self) -> "FieldValidator":
        self.optional = True
        return self

    def transform_with(self, fn: Callable) -> "FieldValidator":
        self.transform = fn
        return self

    def validate(self, value: Any) -> tuple:
        errors = []
        
        if self.optional and (value is None or value == ""):
            return [], self.transform(value) if self.transform else value

        for rule in self.rules:
            if not rule.validate(value):
                errors.append(ValidationError(self.field_name, rule.name, rule.message, value))

        transformed = self.transform(value) if self.transform and not errors else value
        return errors, transformed


class Validator:
    def __init__(self):
        self.fields: Dict[str, FieldValidator] = {}

    def field(self, name: str) -> FieldValidator:
        validator = FieldValidator(name)
        self.fields[name] = validator
        return validator

    def validate(self, data: Dict[str, Any]) -> ValidationResult:
        errors = []
        validated = {}

        for name, validator in self.fields.items():
            value = data.get(name)
            field_errors, transformed = validator.validate(value)
            errors.extend(field_errors)
            validated[name] = transformed

        return ValidationResult(valid=len(errors) == 0, errors=errors, data=validated)


def validate(data: Dict[str, Any], rules: Dict[str, List[Rule]]) -> ValidationResult:
    errors = []
    for field_name, field_rules in rules.items():
        value = data.get(field_name)
        for rule in field_rules:
            if not rule.validate(value):
                errors.append(ValidationError(field_name, rule.name, rule.message, value))
    return ValidationResult(valid=len(errors) == 0, errors=errors, data=data)


def example_usage():
    validator = Validator()
    
    (validator.field("username")
        .required()
        .string()
        .min_length(3)
        .max_length(20)
        .pattern(r'^[a-zA-Z0-9_]+$', "Username can only contain letters, numbers, and underscores"))
    
    (validator.field("email")
        .required()
        .email())
    
    (validator.field("age")
        .required()
        .integer()
        .between(18, 120))
    
    (validator.field("role")
        .required()
        .in_list(["admin", "user", "guest"]))
    
    (validator.field("bio")
        .nullable()
        .max_length(500))
    
    valid_data = {
        "username": "john_doe",
        "email": "john@example.com",
        "age": 25,
        "role": "user",
        "bio": "Hello world"
    }
    
    result = validator.validate(valid_data)
    print(f"Valid: {result.valid}")
    
    invalid_data = {
        "username": "ab",
        "email": "invalid-email",
        "age": 15,
        "role": "superuser"
    }
    
    result = validator.validate(invalid_data)
    print(f"\nInvalid: {not result.valid}")
    for error in result.errors:
        print(f"  {error.field}: {error.message}")

