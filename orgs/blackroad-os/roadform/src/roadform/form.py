"""
RoadForm - Form Handling for BlackRoad
Build and validate forms with fields, rules, and rendering.
"""

from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum
from typing import Any, Callable, Dict, List, Optional, Type
import html
import json
import logging
import re

logger = logging.getLogger(__name__)


class FieldType(str, Enum):
    TEXT = "text"
    EMAIL = "email"
    PASSWORD = "password"
    NUMBER = "number"
    DATE = "date"
    DATETIME = "datetime"
    SELECT = "select"
    CHECKBOX = "checkbox"
    RADIO = "radio"
    TEXTAREA = "textarea"
    FILE = "file"
    HIDDEN = "hidden"


class ValidationRule(str, Enum):
    REQUIRED = "required"
    EMAIL = "email"
    URL = "url"
    MIN_LENGTH = "min_length"
    MAX_LENGTH = "max_length"
    MIN_VALUE = "min_value"
    MAX_VALUE = "max_value"
    PATTERN = "pattern"
    CUSTOM = "custom"


@dataclass
class ValidationError:
    field: str
    rule: str
    message: str


@dataclass
class FieldOption:
    value: str
    label: str
    selected: bool = False
    disabled: bool = False


@dataclass
class FormField:
    name: str
    type: FieldType = FieldType.TEXT
    label: str = ""
    placeholder: str = ""
    default: Any = None
    required: bool = False
    disabled: bool = False
    readonly: bool = False
    options: List[FieldOption] = field(default_factory=list)
    validators: List[tuple] = field(default_factory=list)
    attributes: Dict[str, str] = field(default_factory=dict)
    help_text: str = ""

    def add_validator(self, rule: ValidationRule, value: Any = None, message: str = None) -> "FormField":
        self.validators.append((rule, value, message))
        return self


@dataclass
class FormData:
    fields: Dict[str, Any]
    valid: bool = True
    errors: List[ValidationError] = field(default_factory=list)


class FieldValidator:
    @staticmethod
    def required(value: Any) -> bool:
        if value is None:
            return False
        if isinstance(value, str) and not value.strip():
            return False
        return True

    @staticmethod
    def email(value: str) -> bool:
        if not value:
            return True
        pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
        return bool(re.match(pattern, str(value)))

    @staticmethod
    def url(value: str) -> bool:
        if not value:
            return True
        pattern = r'^https?://[^\s/$.?#].[^\s]*$'
        return bool(re.match(pattern, str(value)))

    @staticmethod
    def min_length(value: str, min_len: int) -> bool:
        if not value:
            return True
        return len(str(value)) >= min_len

    @staticmethod
    def max_length(value: str, max_len: int) -> bool:
        if not value:
            return True
        return len(str(value)) <= max_len

    @staticmethod
    def min_value(value: float, min_val: float) -> bool:
        if value is None:
            return True
        return float(value) >= min_val

    @staticmethod
    def max_value(value: float, max_val: float) -> bool:
        if value is None:
            return True
        return float(value) <= max_val

    @staticmethod
    def pattern(value: str, regex: str) -> bool:
        if not value:
            return True
        return bool(re.match(regex, str(value)))


class Form:
    def __init__(self, name: str = "form"):
        self.name = name
        self.fields: Dict[str, FormField] = {}
        self.method = "POST"
        self.action = ""
        self.enctype = "application/x-www-form-urlencoded"
        self.attributes: Dict[str, str] = {}

    def add_field(self, field: FormField) -> "Form":
        self.fields[field.name] = field
        return self

    def text(self, name: str, label: str = "", **kwargs) -> "Form":
        return self.add_field(FormField(name=name, type=FieldType.TEXT, label=label or name.title(), **kwargs))

    def email(self, name: str, label: str = "", **kwargs) -> "Form":
        field = FormField(name=name, type=FieldType.EMAIL, label=label or "Email", **kwargs)
        field.add_validator(ValidationRule.EMAIL, message="Invalid email address")
        return self.add_field(field)

    def password(self, name: str, label: str = "", **kwargs) -> "Form":
        return self.add_field(FormField(name=name, type=FieldType.PASSWORD, label=label or "Password", **kwargs))

    def number(self, name: str, label: str = "", **kwargs) -> "Form":
        return self.add_field(FormField(name=name, type=FieldType.NUMBER, label=label or name.title(), **kwargs))

    def date(self, name: str, label: str = "", **kwargs) -> "Form":
        return self.add_field(FormField(name=name, type=FieldType.DATE, label=label or name.title(), **kwargs))

    def select(self, name: str, options: List[tuple], label: str = "", **kwargs) -> "Form":
        field_options = [FieldOption(value=str(v), label=l) for v, l in options]
        return self.add_field(FormField(name=name, type=FieldType.SELECT, label=label or name.title(), options=field_options, **kwargs))

    def checkbox(self, name: str, label: str = "", **kwargs) -> "Form":
        return self.add_field(FormField(name=name, type=FieldType.CHECKBOX, label=label or name.title(), **kwargs))

    def textarea(self, name: str, label: str = "", **kwargs) -> "Form":
        return self.add_field(FormField(name=name, type=FieldType.TEXTAREA, label=label or name.title(), **kwargs))

    def hidden(self, name: str, value: Any = None) -> "Form":
        return self.add_field(FormField(name=name, type=FieldType.HIDDEN, default=value))

    def validate(self, data: Dict[str, Any]) -> FormData:
        errors = []
        validated = {}

        for name, field in self.fields.items():
            value = data.get(name, field.default)

            if field.required and not FieldValidator.required(value):
                errors.append(ValidationError(name, "required", f"{field.label or name} is required"))
                continue

            for rule, param, message in field.validators:
                valid = True
                default_msg = f"{field.label or name} validation failed"

                if rule == ValidationRule.REQUIRED:
                    valid = FieldValidator.required(value)
                    default_msg = f"{field.label or name} is required"
                elif rule == ValidationRule.EMAIL:
                    valid = FieldValidator.email(value)
                    default_msg = "Invalid email address"
                elif rule == ValidationRule.URL:
                    valid = FieldValidator.url(value)
                    default_msg = "Invalid URL"
                elif rule == ValidationRule.MIN_LENGTH:
                    valid = FieldValidator.min_length(value, param)
                    default_msg = f"Minimum length is {param}"
                elif rule == ValidationRule.MAX_LENGTH:
                    valid = FieldValidator.max_length(value, param)
                    default_msg = f"Maximum length is {param}"
                elif rule == ValidationRule.MIN_VALUE:
                    valid = FieldValidator.min_value(value, param)
                    default_msg = f"Minimum value is {param}"
                elif rule == ValidationRule.MAX_VALUE:
                    valid = FieldValidator.max_value(value, param)
                    default_msg = f"Maximum value is {param}"
                elif rule == ValidationRule.PATTERN:
                    valid = FieldValidator.pattern(value, param)
                    default_msg = "Invalid format"
                elif rule == ValidationRule.CUSTOM and callable(param):
                    valid = param(value)

                if not valid:
                    errors.append(ValidationError(name, rule.value, message or default_msg))

            validated[name] = value

        return FormData(fields=validated, valid=len(errors) == 0, errors=errors)

    def render_html(self, data: Dict[str, Any] = None) -> str:
        data = data or {}
        parts = [f'<form name="{self.name}" method="{self.method}" action="{self.action}" enctype="{self.enctype}">']

        for name, field in self.fields.items():
            value = data.get(name, field.default) or ""
            parts.append(self._render_field(field, value))

        parts.append('<button type="submit">Submit</button>')
        parts.append('</form>')
        return "\n".join(parts)

    def _render_field(self, field: FormField, value: Any) -> str:
        escaped_value = html.escape(str(value)) if value else ""
        attrs = " ".join(f'{k}="{v}"' for k, v in field.attributes.items())
        required = " required" if field.required else ""
        disabled = " disabled" if field.disabled else ""
        readonly = " readonly" if field.readonly else ""

        if field.type == FieldType.HIDDEN:
            return f'<input type="hidden" name="{field.name}" value="{escaped_value}">'

        parts = ['<div class="form-group">']

        if field.label and field.type != FieldType.CHECKBOX:
            parts.append(f'<label for="{field.name}">{field.label}</label>')

        if field.type == FieldType.TEXTAREA:
            parts.append(f'<textarea name="{field.name}" id="{field.name}" placeholder="{field.placeholder}"{required}{disabled}{readonly} {attrs}>{escaped_value}</textarea>')
        elif field.type == FieldType.SELECT:
            parts.append(f'<select name="{field.name}" id="{field.name}"{required}{disabled} {attrs}>')
            for opt in field.options:
                selected = " selected" if str(opt.value) == str(value) else ""
                parts.append(f'<option value="{opt.value}"{selected}>{opt.label}</option>')
            parts.append('</select>')
        elif field.type == FieldType.CHECKBOX:
            checked = " checked" if value else ""
            parts.append(f'<label><input type="checkbox" name="{field.name}" id="{field.name}" value="1"{checked}{disabled} {attrs}> {field.label}</label>')
        else:
            parts.append(f'<input type="{field.type.value}" name="{field.name}" id="{field.name}" value="{escaped_value}" placeholder="{field.placeholder}"{required}{disabled}{readonly} {attrs}>')

        if field.help_text:
            parts.append(f'<small>{field.help_text}</small>')

        parts.append('</div>')
        return "\n".join(parts)


class FormBuilder:
    @staticmethod
    def create(name: str = "form") -> Form:
        return Form(name)

    @staticmethod
    def login_form() -> Form:
        return (Form("login")
            .email("email", required=True)
            .password("password", required=True)
            .checkbox("remember_me", "Remember me"))

    @staticmethod
    def registration_form() -> Form:
        form = Form("register")
        form.text("name", "Full Name", required=True)
        form.fields["name"].add_validator(ValidationRule.MIN_LENGTH, 2)
        form.email("email", required=True)
        form.password("password", required=True)
        form.fields["password"].add_validator(ValidationRule.MIN_LENGTH, 8)
        form.password("confirm_password", "Confirm Password", required=True)
        return form

    @staticmethod
    def contact_form() -> Form:
        return (Form("contact")
            .text("name", "Your Name", required=True)
            .email("email", "Your Email", required=True)
            .text("subject", required=True)
            .textarea("message", "Your Message", required=True))


def example_usage():
    form = FormBuilder.login_form()
    
    print("Login Form HTML:")
    print(form.render_html())
    
    valid_data = {"email": "user@example.com", "password": "secret123"}
    result = form.validate(valid_data)
    print(f"\nValid data: {result.valid}")
    
    invalid_data = {"email": "not-an-email", "password": ""}
    result = form.validate(invalid_data)
    print(f"Invalid data: {result.valid}")
    for error in result.errors:
        print(f"  {error.field}: {error.message}")
    
    custom_form = (FormBuilder.create("custom")
        .text("username", required=True)
        .email("email", required=True)
        .number("age", required=True)
        .select("country", [("us", "United States"), ("uk", "United Kingdom"), ("ca", "Canada")])
        .textarea("bio", help_text="Tell us about yourself"))
    
    print("\nCustom Form HTML:")
    print(custom_form.render_html({"username": "johndoe", "age": 25}))

