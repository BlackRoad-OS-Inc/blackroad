"""
RoadValidate - Schema Validation Library for BlackRoad
Type-safe validation with JSON Schema, Pydantic-style, and custom rules.
"""

from dataclasses import dataclass, field
from datetime import datetime, date
from decimal import Decimal
from enum import Enum
from typing import Any, Callable, Dict, Generic, List, Optional, Pattern, Set, Type, TypeVar, Union
import re
import json

T = TypeVar("T")


class ValidationError(Exception):
    """Validation error with detailed context."""

    def __init__(self, message: str, path: List[str] = None, value: Any = None):
        self.message = message
        self.path = path or []
        self.value = value
        super().__init__(self.format_message())

    def format_message(self) -> str:
        if self.path:
            return f"{'.'.join(self.path)}: {self.message}"
        return self.message


@dataclass
class ValidationResult:
    """Result of validation operation."""
    valid: bool
    errors: List[ValidationError] = field(default_factory=list)
    value: Any = None

    @property
    def error_messages(self) -> List[str]:
        return [e.format_message() for e in self.errors]

    def raise_if_invalid(self) -> None:
        if not self.valid:
            raise ValidationError("; ".join(self.error_messages))


class Validator:
    """Base validator class."""

    def validate(self, value: Any, path: List[str] = None) -> ValidationResult:
        raise NotImplementedError

    def __or__(self, other: "Validator") -> "UnionValidator":
        return UnionValidator([self, other])

    def __and__(self, other: "Validator") -> "IntersectionValidator":
        return IntersectionValidator([self, other])

    def optional(self) -> "OptionalValidator":
        return OptionalValidator(self)

    def nullable(self) -> "NullableValidator":
        return NullableValidator(self)

    def default(self, default_value: Any) -> "DefaultValidator":
        return DefaultValidator(self, default_value)

    def transform(self, fn: Callable[[Any], Any]) -> "TransformValidator":
        return TransformValidator(self, fn)


class StringValidator(Validator):
    """String validation with constraints."""

    def __init__(
        self,
        min_length: Optional[int] = None,
        max_length: Optional[int] = None,
        pattern: Optional[str] = None,
        enum: Optional[List[str]] = None,
        strip: bool = False,
        lowercase: bool = False,
        uppercase: bool = False
    ):
        self.min_length = min_length
        self.max_length = max_length
        self.pattern = re.compile(pattern) if pattern else None
        self.enum = set(enum) if enum else None
        self.strip = strip
        self.lowercase = lowercase
        self.uppercase = uppercase

    def validate(self, value: Any, path: List[str] = None) -> ValidationResult:
        path = path or []
        errors = []

        if not isinstance(value, str):
            return ValidationResult(False, [ValidationError("Must be a string", path, value)])

        # Transformations
        if self.strip:
            value = value.strip()
        if self.lowercase:
            value = value.lower()
        if self.uppercase:
            value = value.upper()

        # Length checks
        if self.min_length is not None and len(value) < self.min_length:
            errors.append(ValidationError(f"Must be at least {self.min_length} characters", path, value))

        if self.max_length is not None and len(value) > self.max_length:
            errors.append(ValidationError(f"Must be at most {self.max_length} characters", path, value))

        # Pattern check
        if self.pattern and not self.pattern.match(value):
            errors.append(ValidationError(f"Must match pattern {self.pattern.pattern}", path, value))

        # Enum check
        if self.enum and value not in self.enum:
            errors.append(ValidationError(f"Must be one of: {', '.join(self.enum)}", path, value))

        return ValidationResult(len(errors) == 0, errors, value)

    def email(self) -> "StringValidator":
        """Add email validation."""
        self.pattern = re.compile(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        return self

    def url(self) -> "StringValidator":
        """Add URL validation."""
        self.pattern = re.compile(r'^https?://[^\s/$.?#].[^\s]*$')
        return self

    def uuid(self) -> "StringValidator":
        """Add UUID validation."""
        self.pattern = re.compile(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$', re.I)
        return self


class NumberValidator(Validator):
    """Number validation (int/float) with constraints."""

    def __init__(
        self,
        min_value: Optional[float] = None,
        max_value: Optional[float] = None,
        exclusive_min: Optional[float] = None,
        exclusive_max: Optional[float] = None,
        multiple_of: Optional[float] = None,
        integer: bool = False,
        positive: bool = False,
        negative: bool = False
    ):
        self.min_value = min_value
        self.max_value = max_value
        self.exclusive_min = exclusive_min
        self.exclusive_max = exclusive_max
        self.multiple_of = multiple_of
        self.integer = integer
        self.positive = positive
        self.negative = negative

    def validate(self, value: Any, path: List[str] = None) -> ValidationResult:
        path = path or []
        errors = []

        if not isinstance(value, (int, float)) or isinstance(value, bool):
            return ValidationResult(False, [ValidationError("Must be a number", path, value)])

        if self.integer and not isinstance(value, int):
            errors.append(ValidationError("Must be an integer", path, value))

        if self.positive and value <= 0:
            errors.append(ValidationError("Must be positive", path, value))

        if self.negative and value >= 0:
            errors.append(ValidationError("Must be negative", path, value))

        if self.min_value is not None and value < self.min_value:
            errors.append(ValidationError(f"Must be >= {self.min_value}", path, value))

        if self.max_value is not None and value > self.max_value:
            errors.append(ValidationError(f"Must be <= {self.max_value}", path, value))

        if self.exclusive_min is not None and value <= self.exclusive_min:
            errors.append(ValidationError(f"Must be > {self.exclusive_min}", path, value))

        if self.exclusive_max is not None and value >= self.exclusive_max:
            errors.append(ValidationError(f"Must be < {self.exclusive_max}", path, value))

        if self.multiple_of is not None and value % self.multiple_of != 0:
            errors.append(ValidationError(f"Must be multiple of {self.multiple_of}", path, value))

        return ValidationResult(len(errors) == 0, errors, value)


class BooleanValidator(Validator):
    """Boolean validation."""

    def validate(self, value: Any, path: List[str] = None) -> ValidationResult:
        path = path or []

        if not isinstance(value, bool):
            return ValidationResult(False, [ValidationError("Must be a boolean", path, value)])

        return ValidationResult(True, [], value)


class ArrayValidator(Validator):
    """Array/list validation with item validation."""

    def __init__(
        self,
        items: Optional[Validator] = None,
        min_items: Optional[int] = None,
        max_items: Optional[int] = None,
        unique: bool = False
    ):
        self.items = items
        self.min_items = min_items
        self.max_items = max_items
        self.unique = unique

    def validate(self, value: Any, path: List[str] = None) -> ValidationResult:
        path = path or []
        errors = []

        if not isinstance(value, list):
            return ValidationResult(False, [ValidationError("Must be an array", path, value)])

        if self.min_items is not None and len(value) < self.min_items:
            errors.append(ValidationError(f"Must have at least {self.min_items} items", path, value))

        if self.max_items is not None and len(value) > self.max_items:
            errors.append(ValidationError(f"Must have at most {self.max_items} items", path, value))

        if self.unique:
            seen = set()
            for i, item in enumerate(value):
                item_hash = json.dumps(item, sort_keys=True, default=str)
                if item_hash in seen:
                    errors.append(ValidationError(f"Duplicate item at index {i}", path, value))
                seen.add(item_hash)

        validated_items = []
        if self.items:
            for i, item in enumerate(value):
                item_path = path + [str(i)]
                result = self.items.validate(item, item_path)
                if not result.valid:
                    errors.extend(result.errors)
                validated_items.append(result.value)
        else:
            validated_items = value

        return ValidationResult(len(errors) == 0, errors, validated_items)


class ObjectValidator(Validator):
    """Object/dict validation with schema."""

    def __init__(
        self,
        schema: Dict[str, Validator] = None,
        required: Optional[List[str]] = None,
        additional_properties: bool = True,
        strict: bool = False
    ):
        self.schema = schema or {}
        self.required = set(required) if required else set(self.schema.keys())
        self.additional_properties = additional_properties
        self.strict = strict

    def validate(self, value: Any, path: List[str] = None) -> ValidationResult:
        path = path or []
        errors = []

        if not isinstance(value, dict):
            return ValidationResult(False, [ValidationError("Must be an object", path, value)])

        validated = {}

        # Check required fields
        for field_name in self.required:
            if field_name not in value:
                errors.append(ValidationError(f"Required field missing", path + [field_name], None))

        # Validate schema fields
        for field_name, validator in self.schema.items():
            if field_name in value:
                field_path = path + [field_name]
                result = validator.validate(value[field_name], field_path)
                if not result.valid:
                    errors.extend(result.errors)
                validated[field_name] = result.value
            elif field_name not in self.required:
                # Optional field not provided
                pass

        # Handle additional properties
        extra_keys = set(value.keys()) - set(self.schema.keys())
        if extra_keys:
            if not self.additional_properties:
                for key in extra_keys:
                    errors.append(ValidationError(f"Unknown field", path + [key], value[key]))
            elif not self.strict:
                for key in extra_keys:
                    validated[key] = value[key]

        return ValidationResult(len(errors) == 0, errors, validated)


class OptionalValidator(Validator):
    """Makes a validator optional (allows undefined)."""

    def __init__(self, validator: Validator):
        self.validator = validator

    def validate(self, value: Any, path: List[str] = None) -> ValidationResult:
        if value is None:
            return ValidationResult(True, [], None)
        return self.validator.validate(value, path)


class NullableValidator(Validator):
    """Makes a validator nullable (allows null)."""

    def __init__(self, validator: Validator):
        self.validator = validator

    def validate(self, value: Any, path: List[str] = None) -> ValidationResult:
        if value is None:
            return ValidationResult(True, [], None)
        return self.validator.validate(value, path)


class DefaultValidator(Validator):
    """Provides default value if missing."""

    def __init__(self, validator: Validator, default_value: Any):
        self.validator = validator
        self.default_value = default_value

    def validate(self, value: Any, path: List[str] = None) -> ValidationResult:
        if value is None:
            value = self.default_value() if callable(self.default_value) else self.default_value
        return self.validator.validate(value, path)


class UnionValidator(Validator):
    """Union of multiple validators (any must pass)."""

    def __init__(self, validators: List[Validator]):
        self.validators = validators

    def validate(self, value: Any, path: List[str] = None) -> ValidationResult:
        all_errors = []

        for validator in self.validators:
            result = validator.validate(value, path)
            if result.valid:
                return result
            all_errors.extend(result.errors)

        return ValidationResult(False, all_errors, value)


class IntersectionValidator(Validator):
    """Intersection of validators (all must pass)."""

    def __init__(self, validators: List[Validator]):
        self.validators = validators

    def validate(self, value: Any, path: List[str] = None) -> ValidationResult:
        errors = []
        validated_value = value

        for validator in self.validators:
            result = validator.validate(validated_value, path)
            if not result.valid:
                errors.extend(result.errors)
            validated_value = result.value

        return ValidationResult(len(errors) == 0, errors, validated_value)


class TransformValidator(Validator):
    """Transform value after validation."""

    def __init__(self, validator: Validator, transform: Callable[[Any], Any]):
        self.validator = validator
        self.transform = transform

    def validate(self, value: Any, path: List[str] = None) -> ValidationResult:
        result = self.validator.validate(value, path)
        if result.valid:
            try:
                result.value = self.transform(result.value)
            except Exception as e:
                return ValidationResult(False, [ValidationError(str(e), path, value)])
        return result


class DateValidator(Validator):
    """Date validation."""

    def __init__(
        self,
        min_date: Optional[date] = None,
        max_date: Optional[date] = None,
        format: str = "%Y-%m-%d"
    ):
        self.min_date = min_date
        self.max_date = max_date
        self.format = format

    def validate(self, value: Any, path: List[str] = None) -> ValidationResult:
        path = path or []
        errors = []

        if isinstance(value, str):
            try:
                value = datetime.strptime(value, self.format).date()
            except ValueError:
                return ValidationResult(False, [ValidationError(f"Invalid date format, expected {self.format}", path, value)])
        elif isinstance(value, datetime):
            value = value.date()
        elif not isinstance(value, date):
            return ValidationResult(False, [ValidationError("Must be a date", path, value)])

        if self.min_date and value < self.min_date:
            errors.append(ValidationError(f"Must be >= {self.min_date}", path, value))

        if self.max_date and value > self.max_date:
            errors.append(ValidationError(f"Must be <= {self.max_date}", path, value))

        return ValidationResult(len(errors) == 0, errors, value)


class EnumValidator(Validator):
    """Enum validation."""

    def __init__(self, enum_class: Type[Enum]):
        self.enum_class = enum_class
        self.valid_values = {e.value for e in enum_class}

    def validate(self, value: Any, path: List[str] = None) -> ValidationResult:
        path = path or []

        if isinstance(value, self.enum_class):
            return ValidationResult(True, [], value)

        if value in self.valid_values:
            return ValidationResult(True, [], self.enum_class(value))

        valid_str = ", ".join(str(v) for v in self.valid_values)
        return ValidationResult(False, [ValidationError(f"Must be one of: {valid_str}", path, value)])


class CustomValidator(Validator):
    """Custom validation function."""

    def __init__(self, fn: Callable[[Any], Union[bool, str]], message: str = "Validation failed"):
        self.fn = fn
        self.message = message

    def validate(self, value: Any, path: List[str] = None) -> ValidationResult:
        path = path or []
        result = self.fn(value)

        if result is True:
            return ValidationResult(True, [], value)
        elif isinstance(result, str):
            return ValidationResult(False, [ValidationError(result, path, value)])
        else:
            return ValidationResult(False, [ValidationError(self.message, path, value)])


# Schema builder shortcuts
def string(**kwargs) -> StringValidator:
    return StringValidator(**kwargs)


def number(**kwargs) -> NumberValidator:
    return NumberValidator(**kwargs)


def integer(**kwargs) -> NumberValidator:
    return NumberValidator(integer=True, **kwargs)


def boolean() -> BooleanValidator:
    return BooleanValidator()


def array(items: Optional[Validator] = None, **kwargs) -> ArrayValidator:
    return ArrayValidator(items=items, **kwargs)


def obj(schema: Dict[str, Validator] = None, **kwargs) -> ObjectValidator:
    return ObjectValidator(schema=schema, **kwargs)


def date_val(**kwargs) -> DateValidator:
    return DateValidator(**kwargs)


def enum_val(enum_class: Type[Enum]) -> EnumValidator:
    return EnumValidator(enum_class)


def custom(fn: Callable, message: str = "Validation failed") -> CustomValidator:
    return CustomValidator(fn, message)


# Common patterns
email = string().email()
url = string().url()
uuid_str = string().uuid()
positive_int = integer(positive=True)
non_empty_string = string(min_length=1)


# Schema class for defining data models
class Schema:
    """Declarative schema definition."""

    _validators: Dict[str, Validator] = {}

    @classmethod
    def validate(cls, data: Dict[str, Any]) -> ValidationResult:
        """Validate data against schema."""
        validator = ObjectValidator(
            schema=cls._validators,
            required=[k for k, v in cls._validators.items() if not isinstance(v, (OptionalValidator, DefaultValidator))]
        )
        return validator.validate(data)

    @classmethod
    def parse(cls, data: Dict[str, Any]) -> Dict[str, Any]:
        """Validate and return parsed data or raise."""
        result = cls.validate(data)
        result.raise_if_invalid()
        return result.value


# Example usage
def example_usage():
    """Example schema validation usage."""
    # Define a user schema
    user_schema = obj({
        "id": uuid_str,
        "email": email,
        "name": string(min_length=1, max_length=100),
        "age": integer(min_value=0, max_value=150).optional(),
        "roles": array(string(enum=["admin", "user", "guest"]), min_items=1),
        "settings": obj({
            "notifications": boolean(),
            "theme": string(enum=["light", "dark"]).default("light")
        }).optional()
    })

    # Validate data
    data = {
        "id": "550e8400-e29b-41d4-a716-446655440000",
        "email": "alice@example.com",
        "name": "Alice",
        "age": 25,
        "roles": ["admin", "user"],
        "settings": {
            "notifications": True
        }
    }

    result = user_schema.validate(data)
    print(f"Valid: {result.valid}")
    print(f"Value: {result.value}")

    # Invalid data
    invalid_data = {
        "id": "not-a-uuid",
        "email": "not-an-email",
        "name": "",
        "roles": []
    }

    result = user_schema.validate(invalid_data)
    print(f"Valid: {result.valid}")
    print(f"Errors: {result.error_messages}")
