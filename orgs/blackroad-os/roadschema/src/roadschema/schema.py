"""
RoadSchema - Schema Validation for BlackRoad
JSON Schema validation, type coercion, and data normalization.
"""

from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum
from typing import Any, Callable, Dict, List, Optional, Set, Type, Union
import json
import logging
import re
import threading
import uuid

logger = logging.getLogger(__name__)


class SchemaType(str, Enum):
    """Schema types."""
    STRING = "string"
    INTEGER = "integer"
    NUMBER = "number"
    BOOLEAN = "boolean"
    ARRAY = "array"
    OBJECT = "object"
    NULL = "null"
    ANY = "any"


class ValidationError:
    """Validation error."""

    def __init__(self, path: str, message: str, value: Any = None):
        self.path = path
        self.message = message
        self.value = value

    def __str__(self):
        return f"{self.path}: {self.message}"

    def to_dict(self) -> Dict[str, Any]:
        return {
            "path": self.path,
            "message": self.message,
            "value": self.value
        }


@dataclass
class ValidationResult:
    """Validation result."""
    valid: bool
    errors: List[ValidationError] = field(default_factory=list)
    value: Any = None  # Coerced/normalized value

    def add_error(self, path: str, message: str, value: Any = None) -> None:
        self.errors.append(ValidationError(path, message, value))
        self.valid = False


class SchemaField:
    """A schema field definition."""

    def __init__(
        self,
        field_type: SchemaType,
        required: bool = False,
        default: Any = None,
        nullable: bool = False,
        validators: List[Callable[[Any], bool]] = None,
        coerce: bool = False,
        **constraints
    ):
        self.field_type = field_type
        self.required = required
        self.default = default
        self.nullable = nullable
        self.validators = validators or []
        self.coerce = coerce
        self.constraints = constraints

    def validate(self, value: Any, path: str = "") -> ValidationResult:
        """Validate a value against this field."""
        result = ValidationResult(valid=True)

        # Handle None
        if value is None:
            if self.nullable:
                result.value = None
                return result
            elif self.required:
                result.add_error(path, "Required field is null")
                return result
            elif self.default is not None:
                result.value = self.default
                return result

        # Type coercion
        if self.coerce:
            value = self._coerce(value)

        # Type validation
        if not self._check_type(value):
            result.add_error(
                path,
                f"Expected {self.field_type.value}, got {type(value).__name__}",
                value
            )
            return result

        # Constraint validation
        constraint_errors = self._check_constraints(value, path)
        for error in constraint_errors:
            result.add_error(error.path, error.message, error.value)

        # Custom validators
        for validator in self.validators:
            try:
                if not validator(value):
                    result.add_error(path, "Custom validation failed", value)
            except Exception as e:
                result.add_error(path, f"Validator error: {e}", value)

        if result.valid:
            result.value = value

        return result

    def _coerce(self, value: Any) -> Any:
        """Coerce value to target type."""
        if value is None:
            return None

        try:
            if self.field_type == SchemaType.STRING:
                return str(value)
            elif self.field_type == SchemaType.INTEGER:
                return int(value)
            elif self.field_type == SchemaType.NUMBER:
                return float(value)
            elif self.field_type == SchemaType.BOOLEAN:
                if isinstance(value, str):
                    return value.lower() in ('true', '1', 'yes')
                return bool(value)
        except (ValueError, TypeError):
            pass

        return value

    def _check_type(self, value: Any) -> bool:
        """Check if value matches type."""
        type_map = {
            SchemaType.STRING: str,
            SchemaType.INTEGER: int,
            SchemaType.NUMBER: (int, float),
            SchemaType.BOOLEAN: bool,
            SchemaType.ARRAY: list,
            SchemaType.OBJECT: dict,
            SchemaType.NULL: type(None),
            SchemaType.ANY: object
        }

        expected = type_map.get(self.field_type)
        if expected:
            return isinstance(value, expected)
        return True

    def _check_constraints(self, value: Any, path: str) -> List[ValidationError]:
        """Check constraints."""
        errors = []

        # String constraints
        if self.field_type == SchemaType.STRING:
            if "min_length" in self.constraints:
                if len(value) < self.constraints["min_length"]:
                    errors.append(ValidationError(path, f"Min length is {self.constraints['min_length']}"))
            if "max_length" in self.constraints:
                if len(value) > self.constraints["max_length"]:
                    errors.append(ValidationError(path, f"Max length is {self.constraints['max_length']}"))
            if "pattern" in self.constraints:
                if not re.match(self.constraints["pattern"], value):
                    errors.append(ValidationError(path, f"Does not match pattern"))
            if "enum" in self.constraints:
                if value not in self.constraints["enum"]:
                    errors.append(ValidationError(path, f"Must be one of: {self.constraints['enum']}"))

        # Number constraints
        elif self.field_type in (SchemaType.INTEGER, SchemaType.NUMBER):
            if "minimum" in self.constraints:
                if value < self.constraints["minimum"]:
                    errors.append(ValidationError(path, f"Minimum is {self.constraints['minimum']}"))
            if "maximum" in self.constraints:
                if value > self.constraints["maximum"]:
                    errors.append(ValidationError(path, f"Maximum is {self.constraints['maximum']}"))

        # Array constraints
        elif self.field_type == SchemaType.ARRAY:
            if "min_items" in self.constraints:
                if len(value) < self.constraints["min_items"]:
                    errors.append(ValidationError(path, f"Min items is {self.constraints['min_items']}"))
            if "max_items" in self.constraints:
                if len(value) > self.constraints["max_items"]:
                    errors.append(ValidationError(path, f"Max items is {self.constraints['max_items']}"))
            if "unique_items" in self.constraints and self.constraints["unique_items"]:
                # Check for duplicates
                try:
                    if len(value) != len(set(map(str, value))):
                        errors.append(ValidationError(path, "Array must have unique items"))
                except TypeError:
                    pass

        return errors


class ObjectSchema:
    """Object schema definition."""

    def __init__(
        self,
        fields: Dict[str, SchemaField] = None,
        additional_properties: bool = True,
        strict: bool = False
    ):
        self.fields = fields or {}
        self.additional_properties = additional_properties
        self.strict = strict

    def add_field(self, name: str, field: SchemaField) -> "ObjectSchema":
        """Add a field to the schema."""
        self.fields[name] = field
        return self

    def validate(self, data: Dict[str, Any], path: str = "") -> ValidationResult:
        """Validate data against schema."""
        result = ValidationResult(valid=True, value={})

        if not isinstance(data, dict):
            result.add_error(path, "Expected object", data)
            return result

        # Validate each defined field
        for name, field in self.fields.items():
            field_path = f"{path}.{name}" if path else name
            value = data.get(name)

            if value is None and name not in data:
                if field.required:
                    result.add_error(field_path, "Required field is missing")
                elif field.default is not None:
                    result.value[name] = field.default
                continue

            field_result = field.validate(value, field_path)

            if not field_result.valid:
                for error in field_result.errors:
                    result.add_error(error.path, error.message, error.value)
            else:
                result.value[name] = field_result.value

        # Check additional properties
        if not self.additional_properties:
            extra_keys = set(data.keys()) - set(self.fields.keys())
            if extra_keys:
                result.add_error(path, f"Additional properties not allowed: {extra_keys}")
        elif not self.strict:
            # Include additional properties
            for key in data.keys():
                if key not in self.fields:
                    result.value[key] = data[key]

        return result


class ArraySchema:
    """Array schema definition."""

    def __init__(
        self,
        items: Union[SchemaField, ObjectSchema] = None,
        min_items: int = None,
        max_items: int = None,
        unique_items: bool = False
    ):
        self.items = items
        self.min_items = min_items
        self.max_items = max_items
        self.unique_items = unique_items

    def validate(self, data: List[Any], path: str = "") -> ValidationResult:
        """Validate array against schema."""
        result = ValidationResult(valid=True, value=[])

        if not isinstance(data, list):
            result.add_error(path, "Expected array", data)
            return result

        # Length constraints
        if self.min_items is not None and len(data) < self.min_items:
            result.add_error(path, f"Array must have at least {self.min_items} items")

        if self.max_items is not None and len(data) > self.max_items:
            result.add_error(path, f"Array must have at most {self.max_items} items")

        # Validate items
        if self.items:
            for i, item in enumerate(data):
                item_path = f"{path}[{i}]"

                if isinstance(self.items, ObjectSchema):
                    item_result = self.items.validate(item, item_path)
                else:
                    item_result = self.items.validate(item, item_path)

                if not item_result.valid:
                    for error in item_result.errors:
                        result.add_error(error.path, error.message, error.value)
                else:
                    result.value.append(item_result.value)
        else:
            result.value = data.copy()

        # Unique items
        if self.unique_items:
            try:
                seen = set()
                for item in data:
                    key = json.dumps(item, sort_keys=True)
                    if key in seen:
                        result.add_error(path, "Array must have unique items")
                        break
                    seen.add(key)
            except TypeError:
                pass

        return result


class SchemaBuilder:
    """Fluent schema builder."""

    @staticmethod
    def string(
        required: bool = False,
        min_length: int = None,
        max_length: int = None,
        pattern: str = None,
        enum: List[str] = None,
        **kwargs
    ) -> SchemaField:
        constraints = {}
        if min_length: constraints["min_length"] = min_length
        if max_length: constraints["max_length"] = max_length
        if pattern: constraints["pattern"] = pattern
        if enum: constraints["enum"] = enum
        return SchemaField(SchemaType.STRING, required=required, **constraints, **kwargs)

    @staticmethod
    def integer(
        required: bool = False,
        minimum: int = None,
        maximum: int = None,
        **kwargs
    ) -> SchemaField:
        constraints = {}
        if minimum is not None: constraints["minimum"] = minimum
        if maximum is not None: constraints["maximum"] = maximum
        return SchemaField(SchemaType.INTEGER, required=required, **constraints, **kwargs)

    @staticmethod
    def number(
        required: bool = False,
        minimum: float = None,
        maximum: float = None,
        **kwargs
    ) -> SchemaField:
        constraints = {}
        if minimum is not None: constraints["minimum"] = minimum
        if maximum is not None: constraints["maximum"] = maximum
        return SchemaField(SchemaType.NUMBER, required=required, **constraints, **kwargs)

    @staticmethod
    def boolean(required: bool = False, **kwargs) -> SchemaField:
        return SchemaField(SchemaType.BOOLEAN, required=required, **kwargs)

    @staticmethod
    def array(
        items: Union[SchemaField, ObjectSchema] = None,
        min_items: int = None,
        max_items: int = None,
        unique: bool = False
    ) -> ArraySchema:
        return ArraySchema(items, min_items, max_items, unique)

    @staticmethod
    def object(
        fields: Dict[str, SchemaField] = None,
        additional: bool = True
    ) -> ObjectSchema:
        return ObjectSchema(fields, additional)


class SchemaRegistry:
    """Registry for reusable schemas."""

    def __init__(self):
        self.schemas: Dict[str, ObjectSchema] = {}
        self._lock = threading.Lock()

    def register(self, name: str, schema: ObjectSchema) -> None:
        """Register a schema."""
        with self._lock:
            self.schemas[name] = schema

    def get(self, name: str) -> Optional[ObjectSchema]:
        """Get a schema by name."""
        return self.schemas.get(name)

    def unregister(self, name: str) -> bool:
        """Unregister a schema."""
        with self._lock:
            if name in self.schemas:
                del self.schemas[name]
                return True
            return False

    def validate(self, name: str, data: Dict[str, Any]) -> ValidationResult:
        """Validate data against a named schema."""
        schema = self.get(name)
        if not schema:
            result = ValidationResult(valid=False)
            result.add_error("", f"Schema '{name}' not found")
            return result
        return schema.validate(data)


class SchemaManager:
    """High-level schema management."""

    def __init__(self):
        self.registry = SchemaRegistry()
        self.builder = SchemaBuilder()

    def define(
        self,
        name: str,
        fields: Dict[str, SchemaField],
        additional_properties: bool = True
    ) -> ObjectSchema:
        """Define and register a schema."""
        schema = ObjectSchema(fields, additional_properties)
        self.registry.register(name, schema)
        return schema

    def validate(
        self,
        data: Dict[str, Any],
        schema: Union[str, ObjectSchema]
    ) -> ValidationResult:
        """Validate data."""
        if isinstance(schema, str):
            return self.registry.validate(schema, data)
        return schema.validate(data)

    def is_valid(
        self,
        data: Dict[str, Any],
        schema: Union[str, ObjectSchema]
    ) -> bool:
        """Check if data is valid."""
        return self.validate(data, schema).valid

    def get_errors(
        self,
        data: Dict[str, Any],
        schema: Union[str, ObjectSchema]
    ) -> List[Dict[str, Any]]:
        """Get validation errors."""
        result = self.validate(data, schema)
        return [e.to_dict() for e in result.errors]


# Common validators
def email_validator(value: str) -> bool:
    """Validate email format."""
    return bool(re.match(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$', value))


def url_validator(value: str) -> bool:
    """Validate URL format."""
    return bool(re.match(r'^https?://[^\s/$.?#].[^\s]*$', value))


def uuid_validator(value: str) -> bool:
    """Validate UUID format."""
    try:
        uuid.UUID(value)
        return True
    except ValueError:
        return False


# Example usage
def example_usage():
    """Example schema validation usage."""
    manager = SchemaManager()

    # Define a user schema
    user_schema = manager.define(
        "user",
        {
            "id": SchemaBuilder.string(required=True, validators=[uuid_validator]),
            "email": SchemaBuilder.string(required=True, validators=[email_validator]),
            "name": SchemaBuilder.string(required=True, min_length=1, max_length=100),
            "age": SchemaBuilder.integer(minimum=0, maximum=150),
            "role": SchemaBuilder.string(enum=["admin", "user", "guest"], default="user"),
            "active": SchemaBuilder.boolean(default=True)
        },
        additional_properties=False
    )

    # Valid data
    valid_data = {
        "id": str(uuid.uuid4()),
        "email": "user@example.com",
        "name": "John Doe",
        "age": 30,
        "role": "admin"
    }

    result = manager.validate(valid_data, "user")
    print(f"Valid: {result.valid}")
    print(f"Value: {result.value}")

    # Invalid data
    invalid_data = {
        "id": "not-a-uuid",
        "email": "invalid-email",
        "name": "",
        "age": 200
    }

    result = manager.validate(invalid_data, "user")
    print(f"\nInvalid: {result.valid}")
    for error in result.errors:
        print(f"  - {error}")

    # Array schema
    tags_schema = SchemaBuilder.array(
        items=SchemaBuilder.string(min_length=1),
        min_items=1,
        max_items=5,
        unique=True
    )

    tags_result = tags_schema.validate(["python", "javascript", "python"])
    print(f"\nTags valid: {tags_result.valid}")

