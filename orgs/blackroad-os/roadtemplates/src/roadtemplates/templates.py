"""
RoadTemplates - Email and Document Template System for BlackRoad
Jinja2-based templating with email, PDF, and multi-language support.
"""

from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum
from typing import Any, Callable, Dict, List, Optional, Set, Tuple, Union
import hashlib
import html
import json
import logging
import os
import re

logger = logging.getLogger(__name__)


class TemplateType(str, Enum):
    """Types of templates."""
    EMAIL = "email"
    SMS = "sms"
    PUSH = "push"
    PDF = "pdf"
    HTML = "html"
    TEXT = "text"
    MARKDOWN = "markdown"


class TemplateFormat(str, Enum):
    """Template format/engine."""
    JINJA2 = "jinja2"
    MUSTACHE = "mustache"
    PLAIN = "plain"


@dataclass
class TemplateVariable:
    """Definition of a template variable."""
    name: str
    var_type: str = "string"
    required: bool = True
    default: Any = None
    description: str = ""
    example: Any = None


@dataclass
class Template:
    """A template definition."""
    id: str
    name: str
    template_type: TemplateType
    format: TemplateFormat = TemplateFormat.JINJA2
    subject: Optional[str] = None  # For emails
    body: str = ""
    html_body: Optional[str] = None  # For emails with HTML
    variables: List[TemplateVariable] = field(default_factory=list)
    locale: str = "en"
    version: int = 1
    created_at: datetime = field(default_factory=datetime.now)
    updated_at: datetime = field(default_factory=datetime.now)
    metadata: Dict[str, Any] = field(default_factory=dict)

    def get_required_variables(self) -> Set[str]:
        """Get names of required variables."""
        return {v.name for v in self.variables if v.required}

    def get_variable_defaults(self) -> Dict[str, Any]:
        """Get default values for variables."""
        return {v.name: v.default for v in self.variables if v.default is not None}


@dataclass
class RenderedTemplate:
    """Result of template rendering."""
    template_id: str
    subject: Optional[str] = None
    body: str = ""
    html_body: Optional[str] = None
    locale: str = "en"
    rendered_at: datetime = field(default_factory=datetime.now)
    variables_used: Dict[str, Any] = field(default_factory=dict)


class TemplateEngine:
    """Template rendering engine."""

    def __init__(self):
        self.filters: Dict[str, Callable] = {}
        self.globals: Dict[str, Any] = {}
        self._register_default_filters()

    def _register_default_filters(self) -> None:
        """Register default template filters."""
        self.filters["upper"] = str.upper
        self.filters["lower"] = str.lower
        self.filters["title"] = str.title
        self.filters["strip"] = str.strip
        self.filters["escape"] = html.escape
        self.filters["default"] = lambda v, d: v if v else d
        self.filters["date"] = lambda d, fmt="%Y-%m-%d": d.strftime(fmt) if d else ""
        self.filters["datetime"] = lambda d, fmt="%Y-%m-%d %H:%M": d.strftime(fmt) if d else ""
        self.filters["currency"] = lambda v, sym="$": f"{sym}{v:,.2f}"
        self.filters["number"] = lambda v: f"{v:,}"
        self.filters["truncate"] = lambda s, n=50: s[:n] + "..." if len(s) > n else s
        self.filters["json"] = lambda v: json.dumps(v)
        self.filters["nl2br"] = lambda s: s.replace("\n", "<br>")
        self.filters["slugify"] = lambda s: re.sub(r"[^a-z0-9]+", "-", s.lower()).strip("-")

    def add_filter(self, name: str, fn: Callable) -> None:
        """Add a custom filter."""
        self.filters[name] = fn

    def add_global(self, name: str, value: Any) -> None:
        """Add a global template variable."""
        self.globals[name] = value

    def _apply_filter(self, value: Any, filter_expr: str) -> Any:
        """Apply a filter expression to a value."""
        parts = filter_expr.split("(", 1)
        filter_name = parts[0].strip()

        if filter_name not in self.filters:
            return value

        filter_fn = self.filters[filter_name]

        if len(parts) > 1:
            # Parse arguments
            args_str = parts[1].rstrip(")")
            try:
                args = eval(f"[{args_str}]")
                return filter_fn(value, *args)
            except:
                return filter_fn(value)
        else:
            return filter_fn(value)

    def _render_variable(self, var_expr: str, context: Dict[str, Any]) -> str:
        """Render a single variable expression."""
        # Split by | for filters
        parts = var_expr.split("|")
        var_name = parts[0].strip()

        # Handle nested access (e.g., user.name)
        value = context
        for key in var_name.split("."):
            if isinstance(value, dict):
                value = value.get(key, "")
            else:
                value = getattr(value, key, "")

        # Apply filters
        for filter_expr in parts[1:]:
            value = self._apply_filter(value, filter_expr.strip())

        return str(value) if value is not None else ""

    def _evaluate_condition(self, condition: str, context: Dict[str, Any]) -> bool:
        """Evaluate a condition expression."""
        condition = condition.strip()

        # Handle not
        if condition.startswith("not "):
            return not self._evaluate_condition(condition[4:], context)

        # Handle and/or
        if " and " in condition:
            parts = condition.split(" and ", 1)
            return self._evaluate_condition(parts[0], context) and self._evaluate_condition(parts[1], context)

        if " or " in condition:
            parts = condition.split(" or ", 1)
            return self._evaluate_condition(parts[0], context) or self._evaluate_condition(parts[1], context)

        # Handle comparison operators
        for op in ["==", "!=", ">=", "<=", ">", "<"]:
            if op in condition:
                parts = condition.split(op)
                left = self._render_variable(parts[0], context)
                right = parts[1].strip().strip("'\"")
                if op == "==":
                    return left == right
                elif op == "!=":
                    return left != right
                elif op == ">=":
                    return float(left) >= float(right)
                elif op == "<=":
                    return float(left) <= float(right)
                elif op == ">":
                    return float(left) > float(right)
                elif op == "<":
                    return float(left) < float(right)

        # Simple truthiness check
        value = self._render_variable(condition, context)
        return bool(value) and value != "None" and value != "0" and value != "False"

    def render_jinja2(self, template_str: str, context: Dict[str, Any]) -> str:
        """Render Jinja2-style template."""
        result = template_str
        full_context = {**self.globals, **context}

        # Process for loops {% for item in items %}...{% endfor %}
        for_pattern = r"{%\s*for\s+(\w+)\s+in\s+(\w+(?:\.\w+)*)\s*%}(.*?){%\s*endfor\s*%}"
        for match in re.finditer(for_pattern, result, re.DOTALL):
            var_name = match.group(1)
            items_expr = match.group(2)
            loop_body = match.group(3)

            # Get items
            items = full_context
            for key in items_expr.split("."):
                items = items.get(key, []) if isinstance(items, dict) else getattr(items, key, [])

            # Render loop
            rendered_loops = []
            for i, item in enumerate(items or []):
                loop_context = {
                    **full_context,
                    var_name: item,
                    "loop": {
                        "index": i + 1,
                        "index0": i,
                        "first": i == 0,
                        "last": i == len(items) - 1,
                        "length": len(items)
                    }
                }
                rendered_loops.append(self.render_jinja2(loop_body, loop_context))

            result = result.replace(match.group(0), "".join(rendered_loops))

        # Process if/else {% if condition %}...{% else %}...{% endif %}
        if_pattern = r"{%\s*if\s+(.+?)\s*%}(.*?)(?:{%\s*else\s*%}(.*?))?{%\s*endif\s*%}"
        for match in re.finditer(if_pattern, result, re.DOTALL):
            condition = match.group(1)
            if_body = match.group(2)
            else_body = match.group(3) or ""

            if self._evaluate_condition(condition, full_context):
                rendered = self.render_jinja2(if_body, full_context)
            else:
                rendered = self.render_jinja2(else_body, full_context)

            result = result.replace(match.group(0), rendered)

        # Process variables {{ variable }}
        var_pattern = r"{{\s*(.+?)\s*}}"
        for match in re.finditer(var_pattern, result):
            var_expr = match.group(1)
            rendered = self._render_variable(var_expr, full_context)
            result = result.replace(match.group(0), rendered)

        return result

    def render_mustache(self, template_str: str, context: Dict[str, Any]) -> str:
        """Render Mustache-style template."""
        result = template_str
        full_context = {**self.globals, **context}

        # Process sections {{#section}}...{{/section}}
        section_pattern = r"{{#(\w+)}}(.*?){{/\1}}"
        for match in re.finditer(section_pattern, result, re.DOTALL):
            var_name = match.group(1)
            section_body = match.group(2)
            value = full_context.get(var_name)

            if isinstance(value, list):
                rendered_sections = []
                for item in value:
                    section_context = {**full_context, **item} if isinstance(item, dict) else {**full_context, ".": item}
                    rendered_sections.append(self.render_mustache(section_body, section_context))
                result = result.replace(match.group(0), "".join(rendered_sections))
            elif value:
                result = result.replace(match.group(0), self.render_mustache(section_body, full_context))
            else:
                result = result.replace(match.group(0), "")

        # Process inverted sections {{^section}}...{{/section}}
        inv_pattern = r"{{\^(\w+)}}(.*?){{/\1}}"
        for match in re.finditer(inv_pattern, result, re.DOTALL):
            var_name = match.group(1)
            section_body = match.group(2)
            value = full_context.get(var_name)

            if not value or (isinstance(value, list) and len(value) == 0):
                result = result.replace(match.group(0), self.render_mustache(section_body, full_context))
            else:
                result = result.replace(match.group(0), "")

        # Process variables {{variable}}
        var_pattern = r"{{(\w+(?:\.\w+)*)}}"
        for match in re.finditer(var_pattern, result):
            var_expr = match.group(1)
            rendered = self._render_variable(var_expr, full_context)
            result = result.replace(match.group(0), html.escape(rendered))

        # Process unescaped variables {{{variable}}}
        raw_pattern = r"{{{(\w+(?:\.\w+)*)}}}"
        for match in re.finditer(raw_pattern, result):
            var_expr = match.group(1)
            rendered = self._render_variable(var_expr, full_context)
            result = result.replace(match.group(0), rendered)

        return result

    def render(self, template: Template, context: Dict[str, Any]) -> RenderedTemplate:
        """Render a template with context."""
        # Merge defaults
        full_context = {**template.get_variable_defaults(), **context}

        # Validate required variables
        missing = template.get_required_variables() - set(full_context.keys())
        if missing:
            raise ValueError(f"Missing required variables: {missing}")

        # Choose rendering method
        if template.format == TemplateFormat.JINJA2:
            render_fn = self.render_jinja2
        elif template.format == TemplateFormat.MUSTACHE:
            render_fn = self.render_mustache
        else:
            render_fn = lambda t, c: t  # Plain text, no rendering

        rendered = RenderedTemplate(
            template_id=template.id,
            locale=template.locale,
            variables_used=full_context
        )

        if template.subject:
            rendered.subject = render_fn(template.subject, full_context)

        rendered.body = render_fn(template.body, full_context)

        if template.html_body:
            rendered.html_body = render_fn(template.html_body, full_context)

        return rendered


class TemplateStore:
    """Store and manage templates."""

    def __init__(self):
        self.templates: Dict[str, Dict[str, Template]] = {}  # id -> locale -> template
        self.categories: Dict[str, Set[str]] = {}  # category -> template_ids

    def save(self, template: Template) -> None:
        """Save a template."""
        if template.id not in self.templates:
            self.templates[template.id] = {}

        template.updated_at = datetime.now()
        self.templates[template.id][template.locale] = template

        # Update categories
        category = template.metadata.get("category", "default")
        if category not in self.categories:
            self.categories[category] = set()
        self.categories[category].add(template.id)

        logger.info(f"Saved template: {template.id} ({template.locale})")

    def get(self, template_id: str, locale: str = "en") -> Optional[Template]:
        """Get a template by ID and locale."""
        locales = self.templates.get(template_id, {})
        return locales.get(locale) or locales.get("en")

    def delete(self, template_id: str, locale: Optional[str] = None) -> bool:
        """Delete a template."""
        if template_id not in self.templates:
            return False

        if locale:
            self.templates[template_id].pop(locale, None)
            if not self.templates[template_id]:
                del self.templates[template_id]
        else:
            del self.templates[template_id]

        return True

    def list_by_type(self, template_type: TemplateType) -> List[Template]:
        """List templates by type."""
        result = []
        for locales in self.templates.values():
            for template in locales.values():
                if template.template_type == template_type:
                    result.append(template)
        return result

    def list_by_category(self, category: str) -> List[Template]:
        """List templates by category."""
        template_ids = self.categories.get(category, set())
        result = []
        for tid in template_ids:
            template = self.get(tid)
            if template:
                result.append(template)
        return result


class TemplateManager:
    """High-level template management."""

    def __init__(self):
        self.store = TemplateStore()
        self.engine = TemplateEngine()
        self.locale_fallbacks: Dict[str, str] = {}

    def register_template(
        self,
        template_id: str,
        name: str,
        template_type: TemplateType,
        body: str,
        subject: Optional[str] = None,
        html_body: Optional[str] = None,
        locale: str = "en",
        variables: Optional[List[Dict[str, Any]]] = None,
        **metadata
    ) -> Template:
        """Register a new template."""
        template = Template(
            id=template_id,
            name=name,
            template_type=template_type,
            subject=subject,
            body=body,
            html_body=html_body,
            locale=locale,
            variables=[TemplateVariable(**v) for v in (variables or [])],
            metadata=metadata
        )
        self.store.save(template)
        return template

    def render(
        self,
        template_id: str,
        context: Dict[str, Any],
        locale: Optional[str] = None
    ) -> RenderedTemplate:
        """Render a template."""
        # Determine locale with fallback
        if locale and locale in self.locale_fallbacks:
            locale = self.locale_fallbacks[locale]

        template = self.store.get(template_id, locale or "en")
        if not template:
            raise ValueError(f"Template not found: {template_id}")

        return self.engine.render(template, context)

    def preview(
        self,
        template_id: str,
        locale: Optional[str] = None
    ) -> RenderedTemplate:
        """Preview template with example data."""
        template = self.store.get(template_id, locale or "en")
        if not template:
            raise ValueError(f"Template not found: {template_id}")

        # Build example context from variable definitions
        context = {}
        for var in template.variables:
            if var.example is not None:
                context[var.name] = var.example
            elif var.default is not None:
                context[var.name] = var.default
            else:
                context[var.name] = f"[{var.name}]"

        return self.engine.render(template, context)

    def add_filter(self, name: str, fn: Callable) -> None:
        """Add custom template filter."""
        self.engine.add_filter(name, fn)

    def set_global(self, name: str, value: Any) -> None:
        """Set global template variable."""
        self.engine.add_global(name, value)

    def set_locale_fallback(self, locale: str, fallback: str) -> None:
        """Set locale fallback chain."""
        self.locale_fallbacks[locale] = fallback


# Email-specific templates
class EmailTemplates:
    """Pre-built email templates."""

    @staticmethod
    def welcome(manager: TemplateManager) -> Template:
        """Register welcome email template."""
        return manager.register_template(
            template_id="email.welcome",
            name="Welcome Email",
            template_type=TemplateType.EMAIL,
            subject="Welcome to {{ app_name }}, {{ user.name }}!",
            body="""
Hi {{ user.name }},

Welcome to {{ app_name }}! We're excited to have you on board.

Your account has been created with the email: {{ user.email }}

{% if verification_link %}
Please verify your email by clicking the link below:
{{ verification_link }}
{% endif %}

Best regards,
The {{ app_name }} Team
            """.strip(),
            html_body="""
<!DOCTYPE html>
<html>
<head><style>body{font-family:Arial,sans-serif;}</style></head>
<body>
<h1>Welcome to {{ app_name }}!</h1>
<p>Hi {{ user.name }},</p>
<p>We're excited to have you on board.</p>
{% if verification_link %}
<p><a href="{{ verification_link }}">Verify your email</a></p>
{% endif %}
<p>Best regards,<br>The {{ app_name }} Team</p>
</body>
</html>
            """.strip(),
            variables=[
                {"name": "user", "var_type": "object", "required": True},
                {"name": "app_name", "var_type": "string", "default": "BlackRoad"},
                {"name": "verification_link", "var_type": "string", "required": False}
            ],
            category="onboarding"
        )

    @staticmethod
    def password_reset(manager: TemplateManager) -> Template:
        """Register password reset email template."""
        return manager.register_template(
            template_id="email.password_reset",
            name="Password Reset Email",
            template_type=TemplateType.EMAIL,
            subject="Reset your {{ app_name }} password",
            body="""
Hi {{ user.name }},

We received a request to reset your password.

Click the link below to reset your password:
{{ reset_link }}

This link will expire in {{ expiry_hours }} hours.

If you didn't request this, please ignore this email.

Best regards,
The {{ app_name }} Team
            """.strip(),
            variables=[
                {"name": "user", "var_type": "object", "required": True},
                {"name": "reset_link", "var_type": "string", "required": True},
                {"name": "expiry_hours", "var_type": "number", "default": 24},
                {"name": "app_name", "var_type": "string", "default": "BlackRoad"}
            ],
            category="auth"
        )


# Example usage
def example_usage():
    """Example template usage."""
    manager = TemplateManager()

    # Set global variables
    manager.set_global("app_name", "BlackRoad")
    manager.set_global("support_email", "support@blackroad.io")

    # Register welcome template
    EmailTemplates.welcome(manager)

    # Render template
    rendered = manager.render("email.welcome", {
        "user": {
            "name": "Alice",
            "email": "alice@example.com"
        },
        "verification_link": "https://blackroad.io/verify?token=abc123"
    })

    print(f"Subject: {rendered.subject}")
    print(f"Body:\n{rendered.body}")
